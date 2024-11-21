function [TS,preCENTER] = SquareHeartSlicesToMesh( HS , TS , S , varargin )


  w = ~cellfun('isempty',HS);
  nRows = size( w , 1 );
  nCols = size( w , 2 );
  
  if nargin < 2 || isempty( TS )
    TS = repmat( {eye(4)} , nRows , 1 );
  end
  if numel( TS ) ~= nRows
    error('%d matrices were expected',nRows);
  end
  TS = TS(:);
  for r = 1:nRows
    if isempty( TS{r} ), TS{r} = eye(4); end;
  end

  VERBOSE = true;
  [varargin,VERBOSE] = parseargs(varargin,'verbose','$FORCE$',{true,VERBOSE});
  [varargin,VERBOSE] = parseargs(varargin,'quiet'  ,'$FORCE$',{false,VERBOSE});
  vprintf = @(varargin)[];
  if VERBOSE
    printf( struct('increaseIndentationLevel',[]) ); CLEANUP = onCleanup( @()printf(struct('decreaseIndentationLevel',[])) );
    vprintf = @(varargin)printf(varargin{:});
  end

  
  Nexhaustive = 0;
  try, [varargin,~,Nexhaustive] = parseargs( varargin , 'Nexhaustive','$DEFS$', Nexhaustive ); end
  
  ENERGYfcn = @(X,S)ENER( X , S );
  try, [varargin,~,ENERGYfcn] = parseargs( varargin , 'energyfcn','$DEFS$', ENERGYfcn ); end
  
  TRANSFORMfcn = [];
  [varargin,~,TRANSFORMfcn] = parseargs(varargin,'Transform','$DEFS$',TRANSFORMfcn);
  if isempty( TRANSFORMfcn )
    error('A TRANSFORM function must be provided.');
  end

  TMODELfcn = [];
  [varargin,~,TMODELfcn] = parseargs(varargin,'TransformationMODEL','$DEFS$',TMODELfcn);
  if isempty( TMODELfcn )
    error('A TransformationMODEL must be provided.');
  end

  FIXED_SLICES = [];
  [varargin,~,FIXED_SLICES] = parseargs(varargin,'FixedSlices','$DEFS$',FIXED_SLICES);
  if islogical( FIXED_SLICES )
    if numel( FIXED_SLICES ) ~= nRows
      error('incorrect FIXED_SLICES specification');
    end
    FIXED_SLICES = find( FIXED_SLICES );
  end
  FIXED_SLICES = FIXED_SLICES(:).';
  if max( FIXED_SLICES ) > nRows
    error('incorrect max FIXED_SLICES specification');
  end
  NODATA_SLICES = find( all(~w,2) );
  
  provided_POSES = [];
  [varargin,~,provided_POSES] = parseargs(varargin,'POSES','$DEFS$',provided_POSES);

  provided_iPOSES = [];
  [varargin,~,provided_iPOSES] = parseargs(varargin,'IPOSES','$DEFS$',provided_iPOSES);

  iPOSES  = repmat( {eye(4)} , nRows,1); POSES  = repmat( {eye(4)} , nRows,1);
  for r = 1:nRows
    if      isempty( provided_iPOSES ) &&  isempty( provided_POSES )
      iPOSES{r} = planeTransform( HS(r,w(r,:)) );
       POSES{r} = minv( iPOSES{r} );
    elseif ~isempty( provided_iPOSES ) &&  isempty( provided_POSES )
      iPOSES{r} = provided_iPOSES{r};
       POSES{r} = minv( iPOSES{r} );
    elseif  isempty( provided_iPOSES ) && ~isempty( provided_POSES )
      iPOSES{r} = minv( provided_POSES{r} );
       POSES{r} = provided_POSES{r};
    elseif ~isempty( provided_iPOSES ) && ~isempty( provided_POSES )
      iPOSES{r} = provided_iPOSES{r};
       POSES{r} = provided_POSES{r};
    end      
    %iPOSE transform the slice to where it is expected to be when
    %transform. That is if it is a contour, after transformed, its center 
    %is at 0,0,0 and lying on the xy plane.
  end

  preCENTER = true;
  [varargin,preCENTER] = parseargs(varargin,'preCENTER'  ,'$FORCE$',{true ,preCENTER});
  [varargin,preCENTER] = parseargs(varargin,'NOPRECENTER','$FORCE$',{false,preCENTER});
  if preCENTER
    vprintf('\|¯PREcentering ... \n');
    preCENTER = TMODELfcn( 'preCENTER' , TS , iPOSES , POSES );
    for r = 1:nRows, TS{r} = preCENTER * TS{r}; end
    S = transform( S , preCENTER );
    vprintf('\|_DONE\n');
  else
    preCENTER = eye(4);
  end
  
  vprintf('\n');
  vprintf('\|¯***** Tranformation parameters (constrained if apply)\n');
  for r = 1:nRows
    p(r,:)  = TMODELfcn( 'matrix2parameter' , TS{r}  , iPOSES{r} , POSES{r} );
    pp(r,:) = TMODELfcn( 'applyconstraints' , p(r,:) , iPOSES{r} , POSES{r} );
  end
  pp(:,all( p == pp ,1)) = NaN;
  for r = 1:nRows
    printf( '\| ' );
    for c = 1:size(p,2)
      vprintf( ' \b%+0.03f ' , p(r,c) );
      if ~isnan( pp(r,c) )
        vprintf( ' \b(%+0.03f)' , pp(r,c) );
      end
      vprintf( ' \b   ' );
    end
    vprintf( ' \b\n' );
    
    T = TMODELfcn( 'parameter2matrix' , p(r,:) , iPOSES{r} , POSES{r} );
    if ~all( isfinite( T(:) ) )
      error('TS{%d} is not finite. Maybe it cannot be parameterized by TMODEL.',r);
    end
    err = maxnorm( iPOSES{r} * ( TS{r} - T ) * POSES{r} );
    if err > 1e-5
      errInP = maxnorm( TMODELfcn( 'matrix2parameter' , TS{r} , iPOSES{r} , POSES{r} ).' - TMODELfcn( 'matrix2parameter' , T , iPOSES{r} , POSES{r} ).' );
      
      warning('TS{%d} cannot be properly parameterized (err: %g with an errorInP: %g). Projecting it to the model space.',r,err,errInP);
    end
    TS{r} = T;
  end
  vprintf('\|_**************\n\n');
  

  %aligned slices
  aHS = cell(nRows,nCols);
  for r = 1:nRows
    C = find( w(r,:) );
    for c = C(:).'
      aHS{r,c} = TRANSFORMfcn( HS{r,c} , TS{r} );
    end
  end
  
  
%   figure;
%   plotMESH( S ,'ne','FaceAlpha',0.2); headlight
  
  toALIGN = 1:nRows;
  while numel( toALIGN )
    rr = 1;
    
    r = toALIGN( rr ); toALIGN( rr ) = [];
    vprintf('\|- slice %2d: ', r );
    if ismember( r , FIXED_SLICES )
      vprintf(' \b  - (%d) FIXED\n' , r );
      continue;
    end
    if ismember( r , NODATA_SLICES )
      vprintf(' \b  - (%d) NO DATA\n' , r );
      continue;
    end
    
    
    C = HS(r,:);
%     for c = 1:numel(C)
%       if isempty( C{c} ), C{c} = zeros(0,3); continue; end
%       thisC = polyline( C{c} );
%       for t = 1:thisC.np, thisC(t) = resample( thisC(t) , 'e' , 1 ); end
%       thisC = double( thisC );
%       thisC( any( isnan( thisC ) ,2) ,:) = [];
%       C{c} = thisC;
%     end
    
    iZ = iPOSES{r};
    Z  =  POSES{r};
    
    p = TMODELfcn( 'matrix2parameter' , TS{r} , iZ , Z ); p = p(:);
    
    M  = @(p)TMODELfcn( 'parameter2matrix' , p , iZ , Z );
    TR = @(m)cellfun(@(x)TRANSFORMfcn(x,m),C,'UniformOutput',false);

    thisS = S( min(r,end) ,:); %plotMESH( thisS ); hplot3d( TR(M(p)) , '*r' )

    
    E = ENERGYfcn( TR(M(p)) , thisS );
    vprintf(' \bEinit ( %g ) - ' , E );
%    hplot3d( TR(M(p)) ,'o','Color',colorith(r)); drawnow;
    

    for it = 1:Nexhaustive
      pp = p;
      p(1:3)   = ExhaustiveSearch( @(z)ENERGYfcn( TR(M( [ z ; p(4:end) ] )) , thisS ) , p(1:3  ) , 2 , 5 , 'maxITERATIONS', 50 );
      if numel(p) > 3
        p(4:end) = ExhaustiveSearch( @(z)ENERGYfcn( TR(M( [ p(1:3) ; z ] )) , thisS ) , p(4:end) , 2 , 5 , 'maxITERATIONS', 50 );
      end
      E = ENERGYfcn( TR(M(p)) , thisS ); printf(' \b( %g )' , E );
      if isequal( p , pp )
        printf(' \b --- ' , E );
        break;
      end
    end
    if ~~Nexhaustive
      p = Optimize( @(z)ENERGYfcn( TR(M(z)) , thisS ) , p , 'methods',{'conjugate','coordinate',1},'ls',{'quadratic','golden','quadratic'} ,...
          struct('COMPUTE_NUMERICAL_JACOBIAN',{{'c'}},'MAX_ITERATIONS',100) , 'verbose' , 0 ,'noplot');
    else
      p = Optimize( @(z)ENERGYfcn( TR(M(z)) , thisS ) , p , 'methods',{'conjugate'},'ls',{'quadratic'} ,...
          struct('COMPUTE_NUMERICAL_JACOBIAN',{{'c'}},'MAX_ITERATIONS',100) , 'verbose' , 0 ,'noplot');
    end

    E = ENERGYfcn( TR(M(p)) , thisS );
    vprintf(' \b   Efinal ( %g )\n' , E );
%     hplot3d( TR(M(p)) ,'o','Color',colorith(r),'MarkerFaceColor',colorith(r)); drawnow;

    TS{r} = TMODELfcn( 'parameter2matrix' , p , iZ , Z );
  end
  
end
function E = ENER( X , S )
  if iscell( X )
    E = 0;
    for c = 1:numel(X)
      E = E + ENER( X{c} , S{c} );
    end
    return;
  end
  if isempty(X), E = 0; return; end

  [e,~,d] = vtkClosestElement( S , X );
  if isfield( S , 'BoundaryElements' )  &&  ~isempty( S.BoundaryElements )
    w   = ismember( e , S.BoundaryElements );
    d2S  = d( ~w );
    d2Be = d( w );
    X2Be = X( w ,:);
    d2B = ClosestElement( struct('xyz',S.xyz,'tri',S.Boundary) , X2Be , true );
    
    w = abs( d2B - d2Be ) < 1e-8;
    try, if sum(w) > ( numel( d2S ) + sum(~w) ) * S.percentage_of_points_on_boundary
        w = [];
    end; end
    d2Be( w ) = [];
    
    d = [ d2S ; d2Be ];
  end

  p = 2;
  E = realpow( sum( realpow( d(:) ,p) )/numel(d) ,1/p);
end





function iZ = planeTransform( ROW )
  if all( cellfun( @(c)isnumeric(c) , ROW ) )
    tr = @(X,T)bsxfun(@plus,X*T(1:3,1:3).',T(1:3,4).');

    XYZ = cell2mat( ROW(:) );
    XYZ( any( ~isfinite( XYZ ) ,2),: ) = [];

    for it = 1:10
      XYZ = unique( XYZ , 'rows' );
      [~,~,v] = svd( bsxfun(@minus,XYZ,mean( XYZ , 1 )) , 0 );
      cvh = unique( convhull( XYZ * ( v * eye(3,2) )  ) , 'stable' );
      XYZ = XYZ( cvh , : );
      if isempty( setdiff( cvh , 1:size(XYZ,1) ) ), break; end
    end

    M = mean( XYZ , 1 );
    [~,~,v] = svd( bsxfun(@minus,XYZ,M) , 0 );
    iZ = blkdiag(v.',1) * [eye(3),-M(:);0 0 0 1];
    
    xy  = tr( XYZ , iZ ) * eye(3,2);
    cvh = convhull( xy );
    xy  = polygon( xy( cvh(1:end-1) , : ) );

    [a,m] = area( xy );
    M = tr( [ m 0 ] , minv(iZ) );
    
    [a,m,J] = area( xy - m );
    [J,~] = eig(J);
    
    iZ = blkdiag(J.',1) * blkdiag(v.',1) * [eye(3),-M(:);0 0 0 1];

  elseif all( cellfun( @(c)isstruct(c) , ROW ) )
    
    sci = ROW{ 1 };
    [x,y,z] = scimat_ndgrid( sci );
    m = [mean(x(:)),mean(y(:)),mean(z(:))];
    iZ = [ sci.rotmat , -m(:) ; 0 0 0 1 ];
    
  elseif all( cellfun( @(c)isa(c,'I3D') , ROW ) )

    I = ROW{ 1 };
    
    
%     Z = I.SpatialTransform;
%     
%     I = transform( I , minv(Z) );
%     Ic = I.center;
%     
%     Z = minv( Z * [ eye(3) , Ic(:) ; 0 0 0 1 ] );

%     Ic = I.center;
%     It = I.SpatialTransform;
%     Z = [ minv(It(1:3,1:3)) , [0;0;0] ; 0 0 0 1 ] * [ eye(3) , -Ic(:) ; 0 0 0 1 ];
    
    iZ = minv( I.SpatialTransform(1:3,1:3) );
    
    iZ = [ iZ , -iZ * I.center(:) ; 0 0 0 1 ];

  end
end
