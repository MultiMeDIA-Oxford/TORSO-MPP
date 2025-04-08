function plMESH( M , celltype )

  fn = inputname(1);
  if isempty( fn ), fn = 'mesh'; end

  [fn,CLEANOUT] = tmpname( [ fn , '_???.vtk' ] , 'mkfile' );

  M.celltype = meshCelltype( M );
  if nargin > 1
    M.celltype = celltype;
  end
  if isscalar(M.celltype) &&  M.celltype == 5
    M = rmfield( M , 'celltype' );
  end
  
  write_VTK( M , fn , 'binary' );

  cmd = getoption( 'PARAVIEW' , 'executable' );
  [a,b] = system( [ '"' , cmd , '" "' , fn , '"' ] );

end
