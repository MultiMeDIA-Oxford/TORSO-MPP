function enableVTK

  try
    evalc( 'vtkPolyDataReader()' );
    return;
  catch
    switch computer
      case 'PCWIN64'

        Ds = { ...
               fullfile( fileparts(which('enableVTK')) , 'vtk' , 'w64' )    ...
               fullfile( fileparts(which('enableVTK')) , 'vtk' , 'w64_mt' ) ...
             };
             
        for d = 1:numel(Ds)
          if isdir( Ds{d} )
            setenv( 'path' , [ getenv('path') , ';' , Ds{d} ] ); 
          end
          try
            evalc( 'vtkPolyDataReader()' );
            break;
          end
        end
      
      case 'PCWIN32'
        setenv( 'path' , [ getenv('path') , ';' , fullfile( fileparts(which('enableVTK')) , 'vtk' , 'w32' ) ] );

       case 'MACI64'
        setenv( 'path' , [ getenv('path') , ';' , fullfile( fileparts(which('enableVTK')) , 'vtk' , 'maci64' ) ] );
        
      otherwise
        error('cannot enable VTK within a matlab runtime.')
    end
  end

  try
    evalc( 'vtkPolyDataReader()' );
  catch
    error('VTK couldn''t be enabled.');
  end
  
end
