function V = tetgen( S , varargin )

  
  defOPTs = '';
  defOPTs = [ defOPTs , 'p' ];  %Tetrahedralizes a piecewise linear complex (PLC).
  defOPTs = [ defOPTs , 'Y' ];  %Preserves the input surface mesh (does not modify it).
  defOPTs = [ defOPTs , 'A' ];  %Assigns attributes to tetrahedra in different regions.
  defOPTs = [ defOPTs , 'M' ];  %No merge of coplanar facets or very close vertices.
  defOPTs = [ defOPTs , 'k' ];  %Outputs mesh to .vtk file for viewing by Paraview.
  defOPTs = [ defOPTs , 'B' ];  %Suppresses output of boundary information.
  defOPTs = [ defOPTs , 'N' ];  %Suppresses output of .node file.
  defOPTs = [ defOPTs , 'E' ];  %Suppresses output of .ele file.
  defOPTs = [ defOPTs , 'F' ];  %Suppresses output of .face and .edge file.
  defOPTs = [ defOPTs , 'I' ];  %Suppresses mesh iteration numbers.
  defOPTs = [ defOPTs , 'T1e-16' ];
%   defOPTs = [ defOPTs , 'C' ];  %Checks the consistency of the final mesh.
%   defOPTs = [ defOPTs , 'Q' ];  %Quiet: No terminal output except errors.
%   defOPTs = [ defOPTs , 'J' ];  %No jettison of unused vertices from output .node file.
% -r	Reconstructs a previously generated mesh.
% -R	Mesh coarsening (to reduce the mesh elements).
% -m	Applies a mesh sizing function.
% -S	Specifies maximum number of added points.
% -T	Sets a tolerance for coplanar test (default 10?8).
% -X	Suppresses use of exact arithmetic.
% -w	Generates weighted Delaunay (regular) triangulation.
% -c	Retains the convex hull of the PLC.
% -d	Detects self-intersections of facets of the PLC.
% -z	Numbers all output items starting from zero.
% -f	Outputs all faces to .face file.
% -e	Outputs all edges to .edge file.
% -n	Outputs tetrahedra neighbors to .neigh file.
% -v	Outputs Voronoi diagram to files.
% -g	Outputs mesh to .mesh file for viewing by Medit.
% -V	Verbose: Detailed information, more terminal output.
% -h	Help: A brief instruction for using TetGen.


  xOPTs     = '';
  ADDpoints = [];
  HOLES     = [];
  VERBOSE   = false;
  while ~isempty( varargin )
    switch varargin{1}
      case {'V','VV','VVV'}
        xOPTs = [ xOPTs , varargin{1} ];
        varargin(1) = [];
        VERBOSE = true;
      case {'verbose'}
        xOPTs = [ xOPTs , 'V' ];
        varargin(1) = [];
        VERBOSE = true;
      case '-Y', defOPTs( defOPTs == 'Y' ) = []; varargin(1) = [];
      case '-A', defOPTs( defOPTs == 'A' ) = []; varargin(1) = [];
      case '-M', defOPTs( defOPTs == 'M' ) = []; varargin(1) = [];
      case 'q'
        %Refines mesh (to improve mesh quality).
        xOPTs = [ xOPTs , 'q' ];
        varargin(1) = [];
        if numel( varargin ) && ~ischar(varargin{1})
          v = varargin{1}; varargin(1) = [];
        else, v = [];
        end
        if     numel( v ) == 2,  xOPTs = [ xOPTs , sprintf( '%.16g/%.16g' , v(1) , v(2) ) ];
        elseif numel( v ) == 1,  xOPTs = [ xOPTs , sprintf( '%.16g' , v(1) ) ];
        elseif numel( v ) == 0,
        else,                    error('no more than 2 values were expected after ''q''.');
        end

      case 'O'
        %Specifies the level of mesh optimization.
        xOPTs = [ xOPTs , 'O' ];
        varargin(1) = [];
        if numel( varargin ) && ~ischar(varargin{1})
          v = varargin{1}; varargin(1) = [];
        else, v = [];
        end
        if     numel( v ) == 2,  xOPTs = [ xOPTs , sprintf( '%.16g/%.16g' , v(1) , v(2) ) ];
        elseif numel( v ) == 1,  xOPTs = [ xOPTs , sprintf( '%.16g' , v(1) ) ];
        elseif numel( v ) == 0,
        else,                    error('no more than 2 values were expected after ''O''.');
        end
        
      case 'a'
        %Applies a maximum tetrahedron volume constraint.
        xOPTs = [ xOPTs , 'a' ];
        varargin(1) = [];
        if numel( varargin ) && ~ischar(varargin{1})
          v = varargin{1}; varargin(1) = [];
        else, v = [];
        end
        if v == 0
          v = median( meshEdges(S,S) )^3 / ( 6*sqrt(2) );
        end
        if     numel( v ) == 1
          v = eval( regexprep( strrep( sprintf( '%e',v ) , 'e' , '00000e' ) , '(\.\d\d).*e','$1e') );
          xOPTs = [ xOPTs , uneval( v(1) ) ];
        elseif numel( v ) == 0,
        else,                    error('no more than 1 value was expected after ''a''.');
        end
        
      case 'i'
        %Inserts a list of additional points.
        varargin(1) = [];
        if numel( varargin ) && ~ischar(varargin{1})
          ADDpoints = varargin{1}; varargin(1) = [];
          if size( ADDpoints ,1)
            xOPTs = [ xOPTs , 'i' ];
          end
        else
          error('additional points were expected after ''i''.');
        end

      case 'holes'
        varargin(1) = [];
        if numel( varargin ) && ~ischar(varargin{1})
          HOLES = varargin{1}; varargin(1) = [];
        else
          error('points defining holes were expected after ''holes''.');
        end
        
      otherwise
        if ischar(  varargin{1} )
          xOPTs = [ xOPTs , varargin{1}(:).' ];
          varargin(1) = [];
        else
          error('invalid option');
        end
    end
  end

  
  if isempty( S )
    V = sprintf( '-%s%s' , defOPTs , xOPTs );
    return;
  end
  
  
  [ DIR , CLEANUP ] = tmpname( 'tetgen_????\' , 'mkdir' );
  Sname = fullfile( DIR , 'S.smesh' );
  
  write_SMESH( S , Sname , HOLES );
  if ~isempty(ADDpoints)
    w = ismember( ADDpoints , S.xyz ,'rows' );
    ADDpoints(w,:) = [];
  end
  if ~isempty(ADDpoints)
    ADDpoints = unique( ADDpoints , 'rows' );
    fid = fopen( fullfile( DIR , 'S.a.node' ) ,'w');
    fprintf(fid,'# Node count, 3 dim, no attribute, no boundary marker\n');
    fprintf(fid,'%d %d 0 0\n',size(ADDpoints,1),size(ADDpoints,2));
    fprintf(fid,'# Node index, node coordinates\n');
    fprintf(fid,'%d  %.16g  %.16g  %.16g\n', [ (1:size(ADDpoints,1)) ; ADDpoints.' ] );
    fclose( fid );
  end
  
  tetgen_executable = fileparts( mfilename('fullpath') );
  if ispc, tetgen_executable = fullfile( tetgen_executable , 'tetgen1.5.1.exe' );
  else,    tetgen_executable = fullfile( tetgen_executable , 'tetgen' );
  end
  cmd = sprintf( '"%s"  -%s%s   "%s"' , tetgen_executable , defOPTs , xOPTs , Sname );
  
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
      fprintf(2,'************************** error in tetgen\n');
      fprintf(2,'\n%s\n\n',result);
      fprintf(2,'************************** error in tetgen\n');
      error('error in tetgen');
    end

    V = read_VTK( fullfile( DIR , 'S.vtk' ) );

  catch LE
    
    eDIR = strrep( DIR , 'tetgen_' , 'error_in_tetgen_' );
    
    fprintf( 'there was an error... check the tempDir!:   %s\n' , eDIR );
    
    
    movefile( DIR , eDIR );

    fid = fopen( fullfile( eDIR , 'command' ) , 'w' );
    fprintf( fid , '%s\n' , cmd );
    fclose( fid );
    
    fid = fopen( fullfile( eDIR , 'outputmsg' ) , 'w' );
    fprintf( fid , '%s\n' , result );
    fclose( fid );

    rethrow( LE );
    
  end
  
  V.TETGEN_options = sprintf( '%s%s' , defOPTs , xOPTs );
    
end
