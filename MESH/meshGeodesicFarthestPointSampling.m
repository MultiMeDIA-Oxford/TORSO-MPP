function IDS = meshGeodesicFarthestPointSampling( M , nn , VERBOSE )
  
  if nargin < 3, VERBOSE = true; end


  if meshCelltype( M ) ~= 5, error('this algorithm is only valid for triangle meshes');   end

  M = Mesh(M,0);
  nV = size( M.xyz ,1);
  D = Inf( nV , 1 );


  t = 0.1;

  A  = meshQuality( M , 'area' );
  Ac = sparse( M.tri , M.tri , A * [1,1,1] , nV , nV );
  G  = meshGradient( M );

  LC = meshLaplaceBeltrami( M );  iLC = inverse( LC );
  U = ( Ac + t * LC );            iU  = inverse( U );

  delta = zeros(nV,1);
  
  IDS = 1;
  while numel(IDS) < nn
    delta( IDS(end) ) = 1;
    u = iU * delta;
    delta( IDS(end) ) = 0;
    
    g = reshape( G * u , [],3);
    h = -normalize(g,2);
    thisD = iLC * ( G.' * vec( bsxfun( @times , A , h ) ) );
    thisD = thisD - min( thisD );
    D = min( D , thisD );
    
    [~,newID] = max( D );
    IDS = [ IDS , newID ];
    if VERBOSE && ~rem( numel(IDS) ,20), fprintf('%d points already computed\n',numel(IDS) );
  end
  
end
