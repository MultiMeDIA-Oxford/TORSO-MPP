function plMESH( I , varargin )

  fn = inputname(1);
  if isempty( fn ), fn = 'mesh'; end
  [fn,CLEANOUT] = tmpname( [ fn , '_???.vtk' ] , 'mkfile' );

  
  write_VTK( I , fn , varargin{:} );

  cmd = getoption( 'PARAVIEW' , 'executable' );
  [a,b] = system( [ '"' , cmd , '" "' , fn , '"' ] );

end
