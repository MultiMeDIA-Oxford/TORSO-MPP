function [TS,H,M] = Align_to_SSM( HF , SSM )

  [Z,iZ] = getPlane( HF{end,1} );
  
  %%
  HF = MaskHeart( HF );
  
   POSES = repmat( {eye(4)} , size(HF,1),1);
  iPOSES = repmat( {eye(4)} , size(HF,1),1);
  for r = 1:size(HF,1)
    I = HF{r,1};
    I = crop( I , 0 , 'mask',I.FIELDS.Hmask );
    c = I.center(:);
    
     POSES{r} = [ I.SpatialTransform(1:3,1:3) , c ; 0 0 0 1 ];
    iPOSES{r} = minv( POSES{r} );
%     r = 6; image3( transform( I.t1 ,iPOSES{r} ) );hplot3d( transform( centerH ,iPOSES{r} ), '*r' ); hplot3d( transform( c.' ,iPOSES{r} ) , '*g' ); axis tight
  end
  
  %%
  
  printf( struct('resetIndentationLevel',0) );printf( struct('setIndentationLevel',0) ); %printf( struct('setIndentationLevel',-1) );
  
  CS = cell( size(HF,1) , 2 );
  for r = 1:size(HF,1)
    CS{r,1} = [ HF{r,2} ; NaN(1,3) ; HF{r,7} ];
%     CS{r,1} = [ HF{r,2} ; NaN(1,3) ; HF{r,6} ; NaN(1,3) ; HF{r,7} ];
    try,   CS{r,1} = double( polylinefun( @(p)resample( p , '+e' , 0.1 )  , polyline( CS{r,1} ) ) );
    catch, CS{r,1} = []; end

    CS{r,2} = [ HF{r,4} ; NaN(1,3) ; HF{r,6} ];
%     CS{r,2} = [ HF{r,4} ];
    try,   CS{r,2} = double( polylinefun( @(p)resample( p , '+e' , 0.1 )  , polyline( CS{r,2} ) ) );
    catch, CS{r,2} = []; end
  end
  
  TS = repmat( {eye(4)} , size(HF,1),1);

  %%
  
%   TMODELfcn = @(varargin)thisTModel_SE( varargin{:} , 10/180*pi , 4 );
  TMODELfcn = @(varargin)thisTModel_SE( varargin{:} , 7 , 4 );
  TRANSFORMfcn = @(x,T)transform(x,T);

  for r = 1:size( CS ,1)
    printf('\|- slice %2d: ', r );

    if all( cellfun('isempty',CS(r,:)) )
      printf(' \b  - (%d) NO DATA\n' , r );
      continue;
    end
    
    C = CS(r,:);
    for c = 1:numel(C)
      if isempty( C{c} ), C{c} = zeros(0,3); continue; end
      thisC = polyline( C{c} );
      for t = 1:thisC.np, thisC(t) = resample( thisC(t) , 'e' , 1 ); end
      thisC = double( thisC );
      thisC( any( isnan( thisC ) ,2) ,:) = [];
      C{c} = thisC;
    end
    
    iZ = iPOSES{r};
    Z  =  POSES{r};
    
    p = TMODELfcn( 'matrix2parameter' , TS{r} , iZ , Z ); p = p(:);
    
    M  = @(p)TMODELfcn( 'parameter2matrix' , p , iZ , Z );
    TR = @(m)cellfun(@(x)TRANSFORMfcn(x,m),C,'UniformOutput',false);

    thisS = SSM;

    
    E = ENERGYfcn( TR(M(p)) , thisS );
    printf(' \bEinit ( %g ) - ' , E );    
    

    for it = 1:10
      pp = p;
      p(1:3)   = ExhaustiveSearch( @(z)ENERGYfcn( TR(M( [ z ; p(4:end) ] )) , thisS ) , p(1:3  ) , 2 , 5 , 'maxITERATIONS', 100 );
      if numel(p) > 3
        p(4:end) = ExhaustiveSearch( @(z)ENERGYfcn( TR(M( [ p(1:3) ; z ] )) , thisS ) , p(4:end) , 2 , 5 , 'maxITERATIONS', 100 );
      end
      E = ENERGYfcn( TR(M(p)) , thisS ); printf(' \b( %g )' , E );
      if isequal( p , pp )
        printf(' \b --- ' , E );
        break;
      end
    end
    
    p = Optimize( @(z)ENERGYfcn( TR(M(z)) , thisS ) , p , 'methods',{'conjugate'},'ls',{'quadratic','golden','quadratic'} ,...
        struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}},'MAX_ITERATIONS',50) , 'verbose' , 0 ,'noplot');

    E = ENERGYfcn( TR(M(p)) , thisS ); %hplot3d( TR(M(p)) , '.k' )
    printf(' \b   Efinal ( %g )\n' , E );

    TS{r} = TMODELfcn( 'parameter2matrix' , p , iZ , Z );
  end
    
end

function OUT = thisTModel_SE( ACTION , IN , iZ , Z , R , TZ )
  switch lower( ACTION )
    case 'applyconstraints'
      OUT = IN(:);

      OUT(3) = BoundsConstraint( OUT(3) , TZ );
      OUT(6) = BoundsConstraint( OUT(6) ,  R );
      
    case 'parameter2matrix'
      IN(3) = BoundsConstraint( IN(3) , TZ );
      IN(6) = BoundsConstraint( IN(6) ,  R );

      t = IN(1:3);
      r = IN(4:6);
      r(3) = r(3) / 180 * pi;
      r = rodrigues( aer2xyz( r ) );
      
      OUT = Z * [ r , t(:) ; 0 , 0 , 0 , 1 ] * iZ;
      
    case 'matrix2parameter'
      H = iZ * IN * Z;
      
      t = H(1:3,4);
      t(3) = iBoundsConstraint( t(3) , TZ );
      if ( BoundsConstraint( t(3) , TZ ) - H(3,4) )^2 > 1e-15
        t(3) = Optimize( @(z)( ( BoundsConstraint( z , TZ ) - H(3,4) ).^2 ) ,...
          t(3) ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden','quadratic'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
      end
      
      r = logmrot( H(1:3,1:3) );
      r = xyz2aer( [ r(3,2) , r(1,3) , r(2,1) ] );
      r(3) = r(3) / pi * 180;
      r(3) = iBoundsConstraint( r(3) , R );
      if fro2( rodrigues( aer2xyz( [ r(1) , r(2) , BoundsConstraint( r(3) , R ) / 180 * pi ] ) ) - H(1:3,1:3)  ) > 1e-15
        r = Optimize( @(r)fro2( rodrigues( aer2xyz( [ r(1) , r(2) , BoundsConstraint( r(3) , R ) / 180 * pi ] ) ) - H(1:3,1:3)  ) ,...
          r ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-15));
        %BoundsConstraint( r(3) ,R ) - acosd( ( trace( H(1:3,1:3) ) - 1 )/2 )
      end

      OUT = [ t(:) ; r(:) ];
    
    case 'precenter'
      n = numel( IN );
      
      W = ones( 1 , n );
      
      G = {};
      
      
      Rs = computeRs( IN , eye(4) , Z , iZ );
      printf('Rs  before precenter: '); printf(' \b %g ' , Rs ); printf(' \b(%g)',max(abs(Rs))); printf(' \b\n');
      for it = 1:5

        g = ExhaustiveSearch( @(r)max( abs( computeRs( IN , maketransform('l_xyz',r ) , Z , iZ ) ) ),[0;0;0] , 1 , 3 ,'maxITERATIONS' , 50 );
        G{end+1,1} = maketransform( 'l_xyz' , g );
        for r = 1:n, IN{r} = G{end} * IN{r}; end

        g = ExhaustiveSearch( @(r)max( abs( computeRs( IN , maketransform('rxyz',r ) , Z , iZ ) ) ),[0;0;0] , 1 , 3 ,'maxITERATIONS' , 50 );
        G{end+1,1} = maketransform( 'rxyz' , g );
        for r = 1:n, IN{r} = G{end} * IN{r}; end

        if maxnorm( G{end-1} - eye(4) ) < 1e-8  &&  maxnorm( G{end} - eye(4) ) < 1e-8 , break; end
      end
      Rs = computeRs( IN , eye(4) , Z , iZ );
      printf('Rs  after  precenter: '); printf(' \b %g ' , Rs ); printf(' \b(%g)',max(abs(Rs))); printf(' \b\n');
      
      
      Ts = computeTs( IN , eye(4) , Z , iZ );
      printf('T   before precenter: '); printf(' \b %g ' , Ts ); printf(' \b(%g)',max(abs(Ts))); printf(' \b\n');
      for it = 1:15
        g = bestT( IN , Z , iZ , it );
        G{end+1,1} = [ eye(3) , g(:) ; 0 , 0 , 0 , 1 ];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      Ts = computeTs( IN , eye(4) , Z , iZ );
      printf('T   after  precenter: '); printf(' \b %g ' , Ts ); printf(' \b(%g)',max(abs(Ts))); printf(' \b\n');


      TZs = computeTZs( IN , eye(4) , Z , iZ );
      printf('TZ  before precenter: '); printf(' \b %g ' , TZs ); printf(' \b(%g)',max(abs(TZs))); printf(' \b\n');
      for it = 1:15
        g = bestTZ( IN , Z , iZ , W , it );
        G{end+1,1} = [ eye(3) , g(:) ; 0 , 0 , 0 , 1 ];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      TZs = computeTZs( IN , eye(4) , Z , iZ );
      printf('TZ  after  precenter: '); printf(' \b %g ' , TZs ); printf(' \b(%g)',max(abs(TZs))); printf(' \b\n');
%       if any( TZs < -(1+1e5*eps(1))*TZ ) ||...
%          any( TZs >  (1+1e5*eps(1))*TZ )
%         warning('Current TZs out of TZrange.');
%       end


      SE = @(p)maketransform('rxyz',p(1:3),'t',p(4:6));
      for it = 1:10
        g = Optimize( @(p)abs(max( ...
          [ abs( computeTZs( IN , SE(p) , Z , iZ ) ) / TZ ,...
            abs( computeRs(  IN , SE(p) , Z , iZ ) ) / R ] ...
          )),[0;0;0;0;0;0] ,...
          'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden','quadratic'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150) );

        G{end+1,1} = SE(g);
        for r = 1:n, IN{r} = G{end} * IN{r}; end
      end

      Rs = computeRs( IN , eye(4) , Z , iZ );
      printf('*Rs after  precenter: '); printf(' \b %g ' , Rs ); printf(' \b(%g)',max(abs(Rs))); printf(' \b\n');
      TZs = computeTZs( IN , eye(4) , Z , iZ );
      printf('*TZ after  precenter: '); printf(' \b %g ' , TZs ); printf(' \b(%g)',max(abs(TZs))); printf(' \b\n');

      
      
      
      
      OUT = eye(4);
      for r = 1:numel( G )
        OUT = G{r} * OUT;
      end
  end

end



function z = BoundsConstraint( z , r )
  z = r * tanh( z / r );
end
function z = iBoundsConstraint( z , r )
  z = min( 20 * r , abs( r * atanh( z / r ) ) ) .* sign( z );
end

function g = bestT( IN , Z , iZ , it )
  n = numel( IN );
  T = zeros(3*n,1); R = zeros(3*n,3);
  for r = 1:n
    T( ( 3*(r-1)+1 ):( 3*r ) ,1) = iZ{r}(1:3,1:3) * IN{r}(1:3,1:3) * Z{r}(1:3,4) + iZ{r}(1:3,1:3) * IN{r}(1:3,4) + iZ{r}(1:3,4);
    R( ( 3*(r-1)+1 ):( 3*r ) ,:) = iZ{r}(1:3,1:3);
  end

  if rem(it,2)
    g = Optimize(         @(g)maxnorm( fro2( reshape( T + R*g ,3,[]) ,1) ) ,[0;0;0], 'methods',{'conjugate','coordinate',1},'verbose',0,'noplot' );
  else
    g = ExhaustiveSearch( @(g)maxnorm( fro2( reshape( T + R*g ,3,[]) ,1) ) ,[0;0;0], 1 , 3 ,'maxTIME' , 20 );
  end
end
function g = bestTZ( IN , Z , iZ , W , it )
  n = numel( IN );
  
  T = zeros(n,1); R = zeros(n,3);
  for r = 1:n
    T(r,:) = iZ{r}(3,1:3) * IN{r}(1:3,1:3) * Z{r}(1:3,4) + iZ{r}(3,1:3) * IN{r}(1:3,4) + iZ{r}(3,4);
    R(r,:) = iZ{r}(3,1:3);
  end
  
  w = ~~W;
  T = T(w,:);
  R = R(w,:);
  W = W(w);

  T = diag(W) * T;
  R = diag(W) * R;

  if rem(it,2)
    g = Optimize(         @(g)maxnorm(( R*g + T ))+fro(g)/1e6,[0;0;0],'methods',{'conjugate','coordinate',1},'verbose',0,'noplot');
  else
    g = ExhaustiveSearch( @(g)maxnorm(( R*g + T ))+fro(g)/1e4,[0;0;0], 1 , 3 ,'maxTIME' , 20 );
  end
end
function Ts = computeTs( MS , G , Z , iZ )
  n = numel( MS );
  Ts = zeros( 1 , n );
  for r = 1:n
    H = iZ{r} * G * MS{r} * Z{r};
    Ts(r) = sqrt( H(1,4)^2 + H(2,4)^2 + H(3,4)^2 );
  end
end
function TZs = computeTZs( MS , G , Z , iZ )
  n = numel( MS );
  TZs = zeros( 1 , n );
  for r = 1:n
    H = iZ{r} * G * MS{r} * Z{r};
    TZs(r) = H(3,4);
  end
end
function Rs = computeRs( MS , G , Z , iZ )
  n = numel( MS );
  Rs = zeros( 1 , n );
  for r = 1:n
    H = iZ{r} * G * MS{r} * Z{r};

    p = ( H(1,1) + H(2,2) + H(3,3) - 1 )/2;
    p = real( acosd( max(min(p,1),-1) ) );

    Rs(r) = abs(p);
  end
end
function xyz = aer2xyz( aer )
  z = aer(3) .* sin( aer(2) );
  c = aer(3) .* cos( aer(2) );
  x = c .* cos( aer(1) );
  y = c .* sin( aer(1) );
  xyz = [ x , y , z ];
end
function aer = xyz2aer( xyz )
  h = hypot( xyz(1) , xyz(2) );
  r = hypot( h      , xyz(3) );
  e = atan2( xyz(3) , h      );
  a = atan2( xyz(2) , xyz(1) );
  
  aer = [ a , e , r ];
end



function E = ENERGYfcn( X , S )
  if iscell( X )
    E = 0;
    for c = 1:numel(X)
      E = E + ENERGYfcn( X{c} , S{c} );
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
