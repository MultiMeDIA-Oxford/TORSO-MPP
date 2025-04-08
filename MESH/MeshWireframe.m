function M = MeshWireframe( M )

  M.tri = meshEdges( M.tri );
  M.celltype = 3;

  for f = fieldnames( M ).'
    if strcmp( f{1} , 'tri' ), continue; end
    if ~strncmp( f{1} , 'tri' , 3 ), continue; end
    M = rmfield( M , f{1} );
  end  
  
end
