function M = ruledSurfaceMesh( C , RES , bLID , uLID )

  if nargin < 2, RES  = []; end, if isempty( RES  ), RES  = 50;  end  
  if nargin < 3, bLID = []; end, if isempty( bLID ), bLID = NaN; end
  if nargin < 4, uLID = []; end, if isempty( uLID ), uLID = NaN; end

  

  C = C(:);
  C( cellfun('isempty',C) ) = [];
  nC = numel(C);
  for c = 1:nC
    C{c} = double( polyline( C{c} ) );
  end
    
  %% get the normals of each contour
  Ns = NaN(nC,3);
  for c = 1:nC
    Ns(c,:) = getPlane( C{c} , '+z' , 'normal' );
  end
  
  %% compute the "mode" of these normals
  dN2N = abs( 2*min( asind( ipd( Ns , Ns )/2 ) , asind( ipd( -Ns , Ns )/2 ) ) );
  
  [~,N] = min( sum( log( 180 + dN2N ) , 1 ) );
  w = dN2N( N ,:) < 20;

  C = C(w);
  Ns = Ns( w ,:);
  
  NZ = meanNormal( Ns ); NZ = NZ(:);
  if NZ(3) < 0, NZ = -NZ; end
  
  %% rotation pointing upwards
  R = [ null( NZ.' ) , NZ ];
  if det( R ) < 0, R(:,1) = -R(:,1); end
  C = transform( C , R.' );
  
  %% sort contours, from bottom to up
  nC = numel( C );
  Zs = NaN(nC,1);
  for c = 1:nC
    Zs(c) = mean( nonans( C{c}(:,3) ) );
%     Zs(c) = mean( range( C{c}(:,3) ) );
  end
  [~,ord] = sort( Zs , 'ascend' );
  C  = C( ord );

  %% bottom lid
  if     isnan( bLID )      %let it open at bottom
  elseif numel( bLID ) == 3                    %use this point as apex
    C = [  bLID(:).' * R  ;  C  ];
  elseif isscalar( bLID )  &&   bLID > 0       %close with an apex
    %a distance bLID from the central point of the most bottom contour
    C = [  nanmean( C{ 1 } , 1 ) - [0,0,bLID]  ;  C  ];
  elseif isscalar( bLID )  &&   bLID < 0       %extent the surface
    %copy the first contour at a distance of -bLID
    C = [ bsxfun( @minus , C{1} , [0,0,-bLID] ) ; C ];
  else
    error('invalid specification of bLID.');
  end
  
  %% upper lid
  if     isnan( uLID )      %let it open at bottom
  elseif numel( uLID ) == 3                    %use this point as apex
    C = [  C  ;  uLID(:).' * R  ];
  elseif isscalar( uLID )  &&   uLID > 0       %close with an apex
    %a distance bLID from the central point of the most bottom contour
    C = [  C  ;  nanmean( C{ end } , 1 ) + [0,0,uLID] ];
  elseif isscalar( uLID )  &&   uLID < 0       %extent the surface
    %copy the first contour at a distance of -uLID
    C = [  C  ;  bsxfun( @plus , C{end} , [0,0,-uLID] ) ];
  else
    error('invalid specification of uLID.');
  end
  
  %% built the mesh
  M = struct( 'xyz',[],'tri',[] );
  lastC = [];
  for c = 1:numel( C )
    xyz = C{c};
    if size( xyz ,1) == 1
      xyz = repmat( xyz , RES , 1 );
    else
      %orient counter-clockwise
      xyz = orientCurve( xyz ); 

      xyz = minTwist( xyz , RES , lastC );
      lastC = xyz;
    end
    M.xyz = [ M.xyz ; xyz ];
    M.tri = [ M.tri ;...
      (c-1)*RES + [ 1:RES-1 ; 2:RES       ; RES+1:2*RES-1 ].' ;...
      (c-1)*RES + [ 2:RES   ; RES+2:2*RES ; RES+1:2*RES-1 ].' ];
  end
  M.tri( any( M.tri > size(M.xyz,1) , 2 ) , : ) = [];
  
  
  M = MeshTidy( M ,0,true);
  M.xyz = M.xyz * R.';
  
  
  
  
end
function Z = meanNormal( N )
  M    = @(ae) [ cos(ae(2)) * cos(ae(1)) , cos(ae(2)) * sin(ae(1)) , sin(ae(2)) ];
  dN2N = @(a,b) 2*min( asin(ipd(a,b)/2) , asin(ipd(a,-b)/2) );
  E    = @(m) sum( abs( dN2N( m , N ) ).^1 );
  
  m = mean(N,1);
  [ m(1),m(2),m(3) ] = cart2sph( m(1),m(2),m(3) );
  m = m([1,2]);
  
  m = Optimize( @(ae)E(M(ae)) , m , 'methods',{'conjugate','coordinate',1},'ls',{'quadratic','golden','quadratic'},struct('COMPUTE_NUMERICAL_JACOBIAN',{{'a'}}),'noplot','verbose',0);
  Z = M(m);
end
function X = orientCurve( X )
  Y = double( resample( polyline( X(:,1:2) ) , 'w',linspace(0,0.99,50) ) );

  o = convhull( Y );
  o(end) = [];
  o = circshift( o , 1-argmin(o) );

  if ~issorted( o )
    X = flip( X , 1);
  end
end
function nX = minTwist( X , RES , Y )
  if isscalar( RES ), RES = linspace( 0 , 1 , RES ); end

  if ~isequal( X(1,:) , X(end,:) )
    X = X([1:end,1],:);
  end
  
  L = [ 0 ; cumsum( sqrt( sum( diff( X , [] , 1 ).^2 , 2 ) ) ) ];
  L = L/L(end);
  w = find( diff(L)==0 ) + 1; X(w,:) = []; L(w,:) = [];
  
  r = 0;
  if ~isempty( Y )
    r = Optimize1D( @(r)fro2(I1d( X , L , mod( RES+r ,1) )-Y) , 0 );
  end
  RES = mod( RES+r ,1);
  nX = I1d( X , L , RES );
  nX([1,end],:) = repmat( mean( nX([1,end],:) ,1) ,2,1);  %eventually merge first and last points

  function yq = I1d( y , x , q )
    try
      yq = Interp1D( y , x , q );
    catch
      yq(:,3) = interp1( x , y(:,3) , q );
      yq(:,2) = interp1( x , y(:,2) , q );
      yq(:,1) = interp1( x , y(:,1) , q );
    end
  end
end
