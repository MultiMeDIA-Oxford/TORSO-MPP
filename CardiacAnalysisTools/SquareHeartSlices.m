function [TS,preCENTER] = SquareHeartSlices( HS , TS , varargin )

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
  

  FAST = false;
  [varargin,FAST] = parseargs(varargin,'FAST','$FORCE$',{true,FAST});


  TRANSFORMfcn = [];
  [varargin,~,TRANSFORMfcn] = parseargs(varargin,'Transform','$DEFS$',TRANSFORMfcn);
  if isempty( TRANSFORMfcn )
    error('A TRANSFORM function must be provided.');
  end
  
  
  EnergyPerPair = [];
  [varargin,~,EnergyPerPair] = parseargs(varargin,'EnergyperPair','EnergyPerPair','$DEFS$',EnergyPerPair);
  if isempty( EnergyPerPair )
    error('An EnergyPerPair function must be provided.');
  end
  
  
  SummaryPerRow = @(R)sum( nonans(R) );
  %SummaryPerRow = @(R)nanmean( R );
  %SummaryPerRow = @(R)max( R );
  [varargin,~,SummaryPerRow] = parseargs(varargin,'EnergyperRow','EnergyPerRow','SummaryPerRow','$DEFS$',SummaryPerRow);
  

  GlobalEnergy = @(R)sum( R );
  [varargin,~,GlobalEnergy] = parseargs(varargin,'GlobalEnergy','$DEFS$',GlobalEnergy);

  
  [varargin,ONLY_ENERGY] = parseargs(varargin,'onlycomputeenergy','$FORCE$',{true,false});
  if ONLY_ENERGY

    %aligned slices
    aHS = cell(nRows,nCols);
    for r = 1:nRows
      C = find( w(r,:) );
      for c = C(:).'
        aHS{r,c} = TRANSFORMfcn( HS{r,c} , TS{r} );
      end
    end

    
    E = NaN( nRows , nCols ); SUMMARY = NaN( nRows , 1 );
    for r = 1:nRows
      C = find( w(r,:) ); C = C(:).';
      for c = C
        E( w(:,c) , c ) = EnergyPerPair( aHS{ w(:,c) , c } );
      end
      if nargout > 1, SUMMARY(r) = SummaryPerRow( E(r,:) ); end
    end

    
                     TS        = E;
    if nargout > 1,  preCENTER = SUMMARY;                 end
    return;
  end
  
  

  SliceSelector = @(E)argmax( nanmean(E,2) );
  [varargin,~,SliceSelector] = parseargs(varargin,'SliceSelector','$DEFS$',SliceSelector);
  
  
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
    preCENTER = TMODELfcn( 'preCENTER' , TS , iPOSES , POSES );
    for r = 1:nRows, TS{r} = preCENTER * TS{r}; end
  else
    preCENTER = eye(4);
  end
  
  
  SCALE1 = 1; [varargin,~,SCALE1] = parseargs(varargin,'SCALE1','Units1'  ,'$DEFS$',SCALE1);
  SCALE2 = 1; [varargin,~,SCALE2] = parseargs(varargin,'SCALE2','Units2'  ,'$DEFS$',SCALE2);
  ExhaustiveN1 = 2; [varargin,~,ExhaustiveN1] = parseargs(varargin,'EXHaustiven1','$DEFS$',ExhaustiveN1);
  ExhaustiveN2 = 2; [varargin,~,ExhaustiveN2] = parseargs(varargin,'EXHaustiven2','$DEFS$',ExhaustiveN2);
 
  
  vprintf('\n***** Tranformation parameters (constrained if apply)\n');
  for r = 1:nRows
    p(r,:)  = TMODELfcn( 'matrix2parameter' , TS{r}  , iPOSES{r} , POSES{r} );
    pp(r,:) = TMODELfcn( 'applyconstraints' , p(r,:) , iPOSES{r} , POSES{r} );
  end
  pp(:,all( p == pp ,1)) = NaN;
  for r = 1:nRows
    for c = 1:size(p,2)
      vprintf( '%+0.03f ' , p(r,c) );
      if ~isnan( pp(r,c) )
        vprintf( '(%+0.03f)' , pp(r,c) );
      end
      vprintf( '   ' );
    end
    vprintf( '\n' );
    
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
  vprintf('**************\n\n');
  

  %aligned slices
  aHS = cell(nRows,nCols);
  for r = 1:nRows
    C = find( w(r,:) );
    for c = C(:).'
      aHS{r,c} = TRANSFORMfcn( HS{r,c} , TS{r} );
    end
  end
  
  
  E = NaN( nRows , nCols ); SUMMARY = NaN( nRows , 1 );
  for r = 1:nRows
    C = find( w(r,:) ); C = C(:).';
    for c = C
      E( w(:,c) , c ) = EnergyPerPair( aHS{ w(:,c) , c } );   %E( r , c ) = EnergyPerPair( aHS{ [ r , setdiff( find( w(:,c) ) , r ) ] , c } );
    end
    SUMMARY(r) = SummaryPerRow( E(r,:) );
  end
  E0 = GlobalEnergy( SUMMARY );
  
  
  toALIGN = 1:nRows;
  while numel( toALIGN )
    prevE = GlobalEnergy( SUMMARY );
    vprintf('%3d (%.5g):' , nRows - numel(toALIGN) + 1 , prevE );
    vprintf(' %.3g  ', SUMMARY );

    rr = SliceSelector( E(toALIGN,:) );
    
    r = toALIGN( rr ); toALIGN( rr ) = [];
    if ismember( r , FIXED_SLICES )
      vprintf('  - (%d) FIXED\n' , r );
      continue;
    end
    if ismember( r , NODATA_SLICES )
      vprintf('  - (%d) NO DATA\n' , r );
      continue;
    end
    
    C = find( w(r,:) );
    
    vprintf('  - (%d) [%.5g]' , r , SUMMARY(r) );
    prevSUMMARY = SUMMARY(r);

    p = TMODELfcn( 'matrix2parameter' , TS{r} , iPOSES{r} , POSES{r} );
    nP = numel(p);
    idxs1 = 1:ceil( nP / 2 );
    idxs2 = ( idxs1(end) + 1 ):nP;
    
    if FAST
%      p(idxs2) = ExhaustiveSearch( @(z)ENER([ p(idxs1) ; z ]) , p(idxs2) , SCALE1 , 2 , 'maxITERATIONS', 2*numel(C) );
%      p(idxs1) = ExhaustiveSearch( @(z)ENER([ z ; p(idxs2) ]) , p(idxs1) , SCALE2 , 2 , 'maxITERATIONS', 2*numel(C) );
      p = Optimize( @(z)ENERGYfcn(z) , p , 'methods',{'conjugate'},'ls',{'quadratic'} ,...
        struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}},'MAX_ITERATIONS',numel(C)) , 'verbose' , 0 ,'noplot');
    else
%       vprintf(' .%.15g %%. ', ENERGYfcn(p)/prevER*100 );
      p(idxs2) = ExhaustiveSearch( @(z)ENERGYfcn([ p(idxs1) ; z ]) , p(idxs2) , SCALE1 , ExhaustiveN1 , 'maxITERATIONS', 2*numel(C) );
      p(idxs1) = ExhaustiveSearch( @(z)ENERGYfcn([ z ; p(idxs2) ]) , p(idxs1) , SCALE2 , ExhaustiveN2 , 'maxITERATIONS', 2*numel(C) );
%       vprintf(' .%.5g %%. ', ENERGYfcn(p)/prevER*100 );
      p = Optimize( @(z)ENERGYfcn(z) , p , 'methods',{'conjugate'},'ls',{'quadratic','golden','quadratic'} ,...
        struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}},'MAX_ITERATIONS',5*numel(C)) , 'verbose' , 0 ,'noplot');
    end

    TS{r} = TMODELfcn( 'parameter2matrix' , p , iPOSES{r} , POSES{r} );
    
    for c = C(:).'
      aHS{r,c} = TRANSFORMfcn( HS{r,c} , TS{r} );
      E( w(:,c) , c ) = EnergyPerPair( aHS{ w(:,c) , c } );
    end
    
    for r = 1:nRows
      SUMMARY(r) = SummaryPerRow( E(r,:) );
    end
    En = GlobalEnergy( SUMMARY );
    vprintf('-->[%.5g] ... (%g) %g %%\n', SUMMARY(r) , En , En/prevE*100 );
  end
  
  E1 = GlobalEnergy( SUMMARY );
  vprintf('END (%.5g):' , E1 );
  vprintf(' %.3g  ', SUMMARY );
  vprintf(' ---  %g %%', E1/E0*100 );
  vprintf('\n' );
  
  
  
  
  
  
  
  p = []; pp = [];
  vprintf('\n***** Tranformation parameters (constrained if apply)\n');
  for r = 1:nRows
    p(r,:)  = TMODELfcn( 'matrix2parameter' , TS{r}  , iPOSES{r} , POSES{r} );
    pp(r,:) = TMODELfcn( 'applyconstraints' , p(r,:) , iPOSES{r} , POSES{r} );
  end
  pp(:,all( p == pp ,1)) = NaN;
  for r = 1:nRows
    for c = 1:size(p,2)
      vprintf( '%+0.03f ' , p(r,c) );
      if ~isnan( pp(r,c) )
        vprintf( '(%+0.03f)' , pp(r,c) );
      end
      vprintf( '   ' );
    end
    vprintf( '\n' );
    T = TMODELfcn( 'parameter2matrix' , p(r,:) , iPOSES{r} , POSES{r} );
    if ~all( isfinite( T(:) ) )
      error('TS{%d} is not finite. Maybe it cannot be parameterized by TMODEL.',r);
    end
    err = maxnorm( TS{r} , T );
    if err > 1e-5
      warning('TS{%d} cannot be properly parameterized (err: %g). Projecting it to the model space.',r,err);
    end
  end
  vprintf('**************\n\n');  
  
  
  
  
  
  
  
  
  
  
  function J = ENERGYfcn( p )
    T = TMODELfcn( 'parameter2matrix' , p , iPOSES{r} , POSES{r} );
    EE = E;
    
    for j = 1:numel( C )
      r2 = setdiff( find( w(:,C(j)) ) , r );
      A  =  HS{ r  , C(j) }; At = TRANSFORMfcn( A , T );
      B  = aHS{ r2 , C(j) };
      if r < r2, EE( [r,r2]  , C(j) ) = EnergyPerPair( At , B  );
      else,      EE( [r,r2]  , C(j) ) = EnergyPerPair( B  , At );
      end
    end
    
    for rr = 1:nRows
      RR(rr,1) = SummaryPerRow( EE( rr , : ) );
    end
    J = GlobalEnergy( RR );
  end

  function vprintf( varargin ), if VERBOSE, fprintf( varargin{:} ); end; end
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
    %iZ = [ iZ , -iZ * I.XYZ(1).' ; 0 0 0 1 ];

  end
end
