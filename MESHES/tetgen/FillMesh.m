function M = FillMesh( M , connected )

  if nargin < 2, connected = false; end

  
  for it = 1:10
    try
    V = [];
    M = SolveSelfIntersections( M ,'remove' );
    M = FillHoles( M );
    V = tetgen( M );
    break
    end
  end
  if isempty( V ), error('Mesh cannot be resolved.'); end
  
  V = rmfield( V , 'tricell_scalars' );
  V = rmfield( V , 'TETGEN_options' );
  V = rmfield( V , 'DatasetType' );
  M = ExtractSurfaceFromTetras( V );
  
  if connected
    
    V = tetgen( M , 'M' );
    m = accumarray( V.tricell_scalars , 1 )';
    if numel( m ) == 1
      return;
    end
    [~,m] = max( m );
    w = V.tricell_scalars ~= m;
    V.tri( w ,:) = [];
    V.tricell_scalars( w ,:) = [];
    M = ExtractSurfaceFromTetras( V );
    
  end
  

end
