function V = gmshfn( S , varargin )

  OPTS = struct();

OPTS.Mesh.ElementOrder = 1;
OPTS.Mesh.Algorithm3D = 2;
OPTS.Mesh.CharacteristicLengthExtendFromBoundary = 1;
OPTS.Mesh.Optimize = 1;
%OPTS.Mesh.OptimizeNetgen = 1;
OPTS.Mesh.CharacteristicLengthFromPoints = 0;
OPTS.Mesh.CharacteristicLengthFromCurvature = 0;
 %OPTS.Mesh.CharacteristicLengthMin = 0.05;
 OPTS.Mesh.CharacteristicLengthMax = 0.3;
% OPTS.Mesh.Algorithm = 6;
OPTS.Mesh.OptimizeThreshold = 0.2;
OPTS.Mesh.Smoothing = 1;

% OPTS.Mesh.RemeshAlgorithm = 1;
% OPTS.Mesh.RemeshParametrization = 7;
  

  VERBOSE = 0;
  while ~isempty( varargin )
    f   = varargin{1}; varargin(1) = [];
    if any( strcmpi( f , {'v','verbose','-v'}) )
      VERBOSE = 5;
      continue;
    end
    
    if ~any( f == '.' ), f = [ 'Mesh.' , f ]; end
      
    val = varargin{1}; varargin(1) = [];
    
    eval( sprintf('OPTS.%s = val;', f ) );
  end



  [ DIR , CLEANUP ] = tmpname( 'gmsh_tmp???\' , 'mkdir' );
  Sname = fullfile( DIR , 'S.vtk' );
  Vname = fullfile( DIR , 'V.vtk' );
  
  write_VTK_UNSTRUCTURED_GRID( S , Sname , 'binary' );

  gmsh_script = fullfile( DIR , 'gmsh.geo' );
  fid = fopen( gmsh_script , 'w' );
  fprintf( fid , 'General.Verbosity = %d;\n', VERBOSE );
  fprintf( fid , 'Merge "%s";\n' , Sname );
  fprintf( fid , 'Surface Loop(1) = {1};\n' );
  fprintf( fid , 'Volume(1) = {1};\n' );

  
  for f = fieldnames( OPTS ).', f = f{1};
    for ff = fieldnames( OPTS.(f) ).', ff = ff{1};
      val = uneval( double( OPTS.(f).(ff) ) );

      fprintf( fid , '%s.%s = %s;\n' , f , ff , val );
    end
  end
  
  
  EL = -1;
  EL = 2;
  if EL > 0
    fprintf( fid , 'Field[1] = MathEval;\n' );
    fprintf( fid , 'Field[1].F = "%g";\n' , EL );
    fprintf( fid , 'Background Field = 1;\n' );    
  end
  
  fprintf( fid , 'Mesh 3;\n' );
  fprintf( fid , 'Mesh.Format = 10;\n' );
  fprintf( fid , 'Mesh.Binary = 1;\n' );
  fprintf( fid , 'Mesh.SaveAll = 1;\n' );
%  fprintf( fid , 'Mesh.SaveElementTagType = 1;\n' );
  fprintf( fid , 'Save "%s";\n' , Vname );

  fclose( fid );
  
  
  gmsh_executable = fileparts( mfilename('fullpath') );
  if ispc, gmsh_executable = fullfile( gmsh_executable , 'gmsh.exe' );
  else,    gmsh_executable = fullfile( gmsh_executable , 'gmsh' );
  end
  cmd = sprintf( '"%s"  "%s" -' , gmsh_executable , gmsh_script );
  
  try
    if VERBOSE
      [status,result] = system( cmd ,'-echo');
    else
      [status,result] = system( cmd );
    end
      

    if isfile( fullfile( DIR , 'S.vtk' ) )
      status = 0;
    end
    if status
      fprintf(2,'************************** error in gmsh\n');
      fprintf(2,'\n%s\n\n',result);
      fprintf(2,'************************** error in gmsh\n');
      error('error in gmsh');
    end

        disp(strcat('need to open ',Vname,'with paraview and save it as ',strcat(Vname(1:end-5),'HV.mat')));
        V= read_VTK(strcat(Vname(1:end-5),'V.vtk'));
    
    if ~isscalar( V.celltype )
      V = MeshRemoveFaces( V , V.celltype ~= 10 );
      V.celltype = meshCelltype( V );
    end

  catch LE
    
%     eDIR = strrep( DIR , 'gmsh_' , 'error_in_gmsh_' );
%     
%     fprintf( 'there was an error... check the tempDir!:   %s\n' , eDIR );
%     
%     movefile( DIR , eDIR );
% 
%     fid = fopen( fullfile( eDIR , 'command' ) , 'w' );
%     fprintf( fid , '%s\n' , cmd );
%     fclose( fid );
%     
%     fid = fopen( fullfile( eDIR , 'outputmsg' ) , 'w' );
%     fprintf( fid , '%s\n' , result );
%     fclose( fid );

    rethrow( LE );
    
  end
  
  V.GMSH_options = OPTS;
  
end
