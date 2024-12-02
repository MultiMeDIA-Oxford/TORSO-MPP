function M = FixMeshForTetgen( M )

  for it = 1:5
    V = tetgen( M , 'M' );
    m = accumarray( V.tricell_scalars , 1 )';
    if numel( m ) == 1
      break;
    end
    [~,m] = max( m );
    V.tri( V.tricell_scalars ~= m ,:) = [];
    M = ExtractSurfaceFromTetras( V );
  end
  
  M = ExtractSurfaceFromTetras( V );
  V = tetgen( M , 'M' );
  M = ExtractSurfaceFromTetras( V );

end
