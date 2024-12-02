function [TS,M] = AlignHeart_by_SSM( HF , TS , varargin )

  if nargin < 2, TS = []; end

  nITS              = 5;
  [varargin,~,nITS] = parseargs(varargin,'nITS','$DEFS$',nITS);

  Nq = 40;
  [varargin,~,Nq] = parseargs(varargin,'NQ','$DEFS$',Nq);
  
  pFactor           = [2 2 2 2 2 4];
  [varargin,~,pFactor] = parseargs(varargin,'pfactor','$DEFS$',pFactor);
  pFactor( end+1:nITS ) = pFactor(end);
  

  LAMBDAS = [];
  [varargin,~,LAMBDAS] = parseargs(varargin,'LAMBDAS','$DEFS$',LAMBDAS);
  if isempty( LAMBDAS )
    ANNEALING_FACTOR  = 2;
    FINAL_LAMBDA      = 0.01;
    LAMBDAS = fliplr( cumprod( ANNEALING_FACTOR + zeros( 1 , nITS ) ) )/ANNEALING_FACTOR*FINAL_LAMBDA;
  elseif iscell( LAMBDAS )
    LAMBDAS = geospace( LAMBDAS{1} , LAMBDAS{2} , nITS );
  end
  LAMBDAS( end+1:nITS ) = LAMBDAS(end);
  

  qRANGE = 5;
  [varargin,~,qRANGE] = parseargs(varargin,'qRANGE','$DEFS$',qRANGE);
    

  Rrange = 7;
  [varargin,~,Rrange] = parseargs(varargin,'rrange','$DEFS$',Rrange);
  
  TZrange = 4;
  [varargin,~,TZrange] = parseargs(varargin,'tzrange','$DEFS$',TZrange);
  
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

  Mh_     = loadv( 'e:\Dropbox\Vigente\shared\MeshPersonalizationPipeline\HEART\HEART_MODEL.mat' , 'Mh_' );
  sM_     = getv( getv( getv( functions( Mh_ ) , '.workspace' ) , {1} ) , '.sM' );
  sMODES_ = getv( getv( getv( functions( Mh_ ) , '.workspace' ) , {1} ) , '.sMODES_' );

  LV = Mh_(0);
  LVt = LV.tri( all( LV.xyzLABEL( LV.tri ) == 0 ,2) ,:);
  LVt( all( reshape( LV.xyz( LVt ,3) ,[],3) > 40 ,2) ,:) = [];
  [a,~,c] = unique( LVt );
  LVt   = reshape( c , size(LVt) );
  w       = false(size(sM_)); w(a,:) = true;
  LVm     = reshape( sM_( w ) ,[],3);
  LVmodes = sMODES_( w(:) ,:);
  LV = Mesh( LVm , LVt );
  LV   = MeshBoundary( LV );
  LVb  = LV.tri;
  LVbe = find( any( ismember( LVt , LVb ) ,2) );


  RV = Mh_(0);
  RVt = RV.tri( all( RV.xyzLABEL( RV.tri ) == 2 ,2) ,:);
  RVt( all( reshape( RV.xyz( RVt ,3) ,[],3) > 38 ,2) ,:) = [];
  [a,~,c] = unique( RVt );
  RVt = reshape( c , size(RVt) );
  w         = false(size(sM_)); w(a,:) = true;
  RVm   = reshape( sM_( w ) ,[],3);
  RVmodes = sMODES_( w(:) ,:);
  RV = Mesh( RVm , RVt );
  RV   = MeshBoundary( RV );
  RVb  = RV.tri;
  RVbe = find( any( ismember( RVt , RVb ) ,2) );
  
  SSM  = @(q) { struct( 'tri' , LVt , 'xyz' , reshape( LVmodes(:,1:numel(q)+1)*[q(:);0] , size(LVm) ) + LVm , 'BoundaryElements' , LVbe , 'Boundary', LVb , 'percentage_of_points_on_boundary' , 0.1 ) ,...
                struct( 'tri' , RVt , 'xyz' , reshape( RVmodes(:,1:numel(q)+1)*[q(:);0] , size(RVm) ) + RVm , 'BoundaryElements' , RVbe , 'Boundary', RVb , 'percentage_of_points_on_boundary' , 0.1 ) };

%   a = SSM(0); a = a{2};
%    plotMESH( a );
%   hplotMESH( Mesh(a,a.tri(a.BoundaryElements,:)) , 'r' )
%   hplotMESH( Mesh(a,a.Boundary) , 'edgecolor','b','linewidth',2 )
              
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

  if isempty( TS )
    TS = repmat( {eye(4)} , size(HF,1),1);
  end

  T = [];  q = [];  LAMBDA = 0;
  printf('>>>> Initial transformation\n' );
  [q,T] = fitSSM( SSM , 'l_sxyzt' , transform( CS , iZ ) , LAMBDA , q , T ,'energyfcn',@(X,S)ENER(X,S,pFactor(1)) ); T = Z * T;
  %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) );

  T = {T}; q = {Nq}; LAMBDA = LAMBDAS( 1 );
  printf('>>>> Refining transformation and initial shape - LAMBDA: %g\n', LAMBDA );
  [q,T] = fitSSM( SSM , 'l_sxyzt' , CS , LAMBDA , q , T , 'range' , qRANGE , 'energyfcn',@(X,S)ENER(X,S,pFactor(1)) );
  %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) );
  
  %%
  
%   TModel = @(varargin)thisTModel_SE( varargin{:} , 10/180*pi , 4 );
  TModel = @(varargin)thisTModel_SE( varargin{:} , Rrange , TZrange );
  for it = 1:nITS
    if rem(it,2) || it == nITS, T = {T}; end

    LAMBDA = LAMBDAS( it );
    printf('>>>> Fitting shape in iteration %2d - LAMBDA: %g\n', it , LAMBDA );
    [q,T] = fitSSM( SSM , 'l_sxyzt' , transform( CS , TS ) , LAMBDA , q , T , 'range' , qRANGE ,'energyfcn',@(X,S)ENER(X,S,pFactor(it)) );
    %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) );
    
    for iit = 0:0
      printf('>>>> Alignning contours to shape in iteration %2d(%d)\n', it , iit );
      [TS,G] = SquareHeartSlicesToMesh( CS , TS , transform( SSM(q) , T ) , 'Transform' , @(x,T)transform(x,T) , 'POSES' , POSES ,'iPOSES', iPOSES  ,'TransformationMODEL', TModel,'energyfcn',@(X,S)ENER(X,S,pFactor(it)) );
      T = G * T;
      %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) ); set( gcf , 'Name' , sprintf('it: %d    LAMBDA: %g',it,LAMBDA));
    end
    
  end
  M = transform( SSM(q) , T );
    
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


function E = ENER( X , S , p )
  if iscell( X )
    E = 0;
    for c = 1:numel(X)
      E = E + ENER( X{c} , S{c} , p );
    end
    E = sqrt(E);
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

  E = realpow( sum( realpow( abs( d(:) ) ,p) )/numel(d) , 1/p );
end
