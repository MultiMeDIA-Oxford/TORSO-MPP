function write_VTK_UNSTRUCTURED_GRID( M , filename , AB , COMPRESSED )
%
% write_VTP( mesh , filename , ['ascii' or 'binary'])
%

  M.celltype = meshCelltype( M );
%   if ~isfield( M , 'celltype' )
%       error('celltype needed');
%   end

  if nargin < 3, AB = []; end
  if nargin < 4, COMPRESSED = false; end
  if ~isscalar( COMPRESSED ), error('true or false was expected for minFILE_SIZE.'); end
  COMPRESSED = ~~COMPRESSED;
  if isempty( AB )
    if COMPRESSED, AB = 'binary';
    else,          AB = 'ascii';
    end
  end
  if ~ischar( AB ), error( '''ascii'' or ''binary'' was expected for AB'); end
  if strcmpi( AB , 'a' ), AB = 'ascii';  end
  if strcmpi( AB , 'b' ), AB = 'binary'; end
  
  
  AB = upper(AB);
  if ~strcmp( AB , 'ASCII' ) && ~strcmp( AB , 'BINARY' )
    error( '''ascii'' or ''binary'' was expected for AB');
  end

  if isfield( M , 'tri' )
    F  = M.tri; FF = int32( M.tri );
    if ~isequal( F , FF ), error('tri cannot be casting to int32.'); end
    if isfield( M , 'celltype' )
      F  = M.celltype; FF = int32( M.celltype );
      if ~isequal( F , FF ), error('celltype cannot be casting to int32.'); end
    else
      error('celltype must be specified!');
      % typedef enum {
      % // Linear cells
      % EMPTY_CELL                       = 0,
      % VERTEX                           = 1,
      % POLY_VERTEX                      = 2,
      % LINE                             = 3,
      % POLY_LINE                        = 4,
      % TRIANGLE                         = 5,
      % TRIANGLE_STRIP                   = 6,
      % POLYGON                          = 7,
      % PIXEL                            = 8,
      % QUAD                             = 9,
      % TETRA                            = 10,
      % VOXEL                            = 11,
      % HEXAHEDRON                       = 12,
      % WEDGE                            = 13,
      % PYRAMID                          = 14,
      % PENTAGONAL_PRISM                 = 15,
      % HEXAGONAL_PRISM                  = 16,
      % 
      % // Quadratic, isoparametric cells
      % QUADRATIC_EDGE                   = 21,
      % QUADRATIC_TRIANGLE               = 22,
      % QUADRATIC_QUAD                   = 23,
      % QUADRATIC_POLYGON                = 36,
      % QUADRATIC_TETRA                  = 24,
      % QUADRATIC_HEXAHEDRON             = 25,
      % QUADRATIC_WEDGE                  = 26,
      % QUADRATIC_PYRAMID                = 27,
      % BIQUADRATIC_QUAD                 = 28,
      % TRIQUADRATIC_HEXAHEDRON          = 29,
      % QUADRATIC_LINEAR_QUAD            = 30,
      % QUADRATIC_LINEAR_WEDGE           = 31,
      % BIQUADRATIC_QUADRATIC_WEDGE      = 32,
      % BIQUADRATIC_QUADRATIC_HEXAHEDRON = 33,
      % BIQUADRATIC_TRIANGLE             = 34,
      % 
      % // Cubic, isoparametric cell
      % CUBIC_LINE                       = 35,
      % 
      % // Special class of cells formed by convex group of points
      % CONVEX_POINT_SET                 = 41,
      % 
      % // Polyhedron cell (consisting of polygonal faces)
      % POLYHEDRON                       = 42,
      % 
      % // Higher order cells in parametric form
      % PARAMETRIC_CURVE                 = 51,
      % PARAMETRIC_SURFACE               = 52,
      % PARAMETRIC_TRI_SURFACE           = 53,
      % PARAMETRIC_QUAD_SURFACE          = 54,
      % PARAMETRIC_TETRA_REGION          = 55,
      % PARAMETRIC_HEX_REGION            = 56,
      % 
      % // Higher order cells
      % HIGHER_ORDER_EDGE                = 60,
      % HIGHER_ORDER_TRIANGLE            = 61,
      % HIGHER_ORDER_QUAD                = 62,
      % HIGHER_ORDER_POLYGON             = 63,
      % HIGHER_ORDER_TETRAHEDRON         = 64,
      % HIGHER_ORDER_WEDGE               = 65,
      % HIGHER_ORDER_PYRAMID             = 66,
      % HIGHER_ORDER_HEXAHEDRON          = 67,
      % 
      % NUMBER_OF_CELL_TYPES
      % } VTKCellType;
    end
  end
  
  if COMPRESSED && strcmp( AB , 'BINARY' )
    fields = setdiff( fieldnames( M ) , {'tri','celltype'} );
    for f = fields(:).'
      while 1
        F = M.(f{1});
        switch class(F)
          case 'double',  FF = single( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
                          FF = uint32( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
                          FF =  int32( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
          case 'single',  FF = uint32( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
                          FF =  int32( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
          case 'uint64',  FF = uint32( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
          case 'int64',   FF =  int32( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
          case 'uint32',  FF = uint16( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
          case 'int32',   FF =  int16( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
          case 'uint16',  FF =  uint8( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
          case 'int16',   FF =   int8( F ); if isequal( F , FF ), M.(f{1}) = FF; continue; end
        end; break;
      end
    end
  end
  
  
  fid = fopen(filename,'w');
  if( fid==-1 ), error('Cant open the file.'); end
  CLEANUP = onCleanup( @()fclose(fid) );
  

  % header
  fprintf(fid, '# vtk DataFile Version 3.0\n');
  
  % title
  if ~isfield( M , 'TITLE' ), M.TITLE = 'VTK polydata file'; end
  fprintf(fid, '%s\n' , M.TITLE(1:min(end,254)) );
  
  %data encoding
  switch AB
    case 'ASCII',  fprintf(fid, 'ASCII\n');
    case 'BINARY', fprintf(fid, 'BINARY\n');
  end
  
  %geometry/topology type
  fprintf(fid, 'DATASET UNSTRUCTURED_GRID \n');

  % points
  N_xyz = 0;
  if isfield(M,'xyz') && size( M.xyz , 1 ) > 0
    N_xyz = size( M.xyz , 1 );
    switch AB
      case 'ASCII',   fprintf(fid, '\nPOINTS %d double\n', N_xyz );
      case 'BINARY',  fprintf(fid, '\nPOINTS %d %s\n', N_xyz , class_as_c( M.xyz ) );
    end
    write_in_file(fid, M.xyz );
  end


  % polygons
  N_tri = 0;
  if isfield( M , 'tri' ) && size( M.tri , 1 ) > 0
    M.tri = int32( M.tri.' - 1 );
    M.tri = M.tri( : , ~all( M.tri < 0 , 1 ) );

    N_tri = size( M.tri , 2 );
    
    switch AB
      case 'ASCII'
        
        M.tri = [ int32( sum( M.tri >= 0 , 1 ) ) ; M.tri ; ones( 1 , N_tri , 'int32' )*intmin('int32') ];
        M.tri = M.tri(:);
        M.tri( M.tri < 0 & M.tri > intmin('int32') ) = [];
        M.tri( M.tri == intmin('int32') ) = -1;

        str = sprintf('%d ', M.tri );
        str = strrep( str , ' -1 ' , char(10) );
        str(end) = [];
        fprintf( fid , '\nCELLS %d %d\n', N_tri , numel( M.tri ) - N_tri );
        fprintf( fid , str );
        
      case 'BINARY'

        M.tri = [ int32( sum( M.tri >= 0 , 1 ) ) ; M.tri ];
        M.tri = M.tri(:);
        M.tri( M.tri < 0 ) = [];

        fprintf( fid , '\nCELLS %d %d\n', N_tri , numel( M.tri ) );
%         fwrite_flipped( fid , M.tri );
        fwrite( fid , M.tri , 'int32' , 0 , 'b' );

    end
    
    fprintf(fid, '\n');
  end
  
  
  
   if isfield( M , 'regions' ) && size( M.regions , 1 ) > 0
    M.regions = int32(M.regions);

    N_el = size( M.regions , 2 );
    
    switch AB
      case 'ASCII'
        

        str = sprintf('%d ', M.regions );
        str = strrep( str , ' -1 ' , char(10) );
        str(end) = [];
        fprintf( fid , '\nCELLS %d %d\n', N_el , numel( M.regions ) - N_el );
        fprintf( fid , str );
        
      case 'BINARY'



        fprintf( fid , '\nCELLS %d %d\n', N_el , numel( M.regions ) );
%         fwrite_flipped( fid , M.tri );
        fwrite( fid , M.regions , 'int32' , 0 , 'b' );

    end
    
    fprintf(fid, '\n');
  end
  
  

  %CELL_TYPE
  if isscalar( M.celltype )
      M.celltype = zeros( [ N_tri , 1 ] , 'int32' ) + int32( M.celltype );
  elseif numel( M.celltype ) ~= N_tri
      error('numel of celltype does not coincide with number of cells');
  else
      M.celltype = int32( M.celltype );
  end
  fprintf(fid,'\nCELL_TYPES %d\n',N_tri);
  write_in_file(fid, M.celltype );
  
  if isfield(M,'regions') 
      M.regions = int32(M.regions);
      fprintf(fid,'\nREGIONS %d\n',N_xyz);
      write_in_file(fid,M.regions,'int32',0,'b');
  end
      
  
  

  fields = setdiff( fieldnames( M ) , {'xyz','tri','xyzNORMALS','triNORMALS','uv'} );

  % points data
  if N_xyz
    fprintf( fid , '\nPOINT_DATA %d', N_xyz );
    
    if isfield( M , '\nuv' )
      fprintf( fid , '\nTEXTURE_COORDINATES UV 2 %s\n', class_as_c( M.uv ) );
      write_in_file(fid, M.uv );
    end

    if isfield( M , '\nxyzNORMALS')
      fprintf( fid , '\nNORMALS Normals %s\n', class_as_c( M.xyzNORMALS ) );
      write_in_file(fid, M.xyzNORMALS );
    end

    for f = 1:numel(fields)
      field= fields{f};
      if strncmp( field, 'xyz',3)
        fprintf(fid, '\nFIELD field 1\n');
        fprintf(fid, '%s %d %d %s\n', field(4:end), size(M.(field),2), N_xyz , class_as_c( M.(field) ) );
        write_in_file( fid, M.(field) );
      end
    end
  end

  % cells data
  if N_tri
    fprintf(fid,'\nCELL_DATA %d', N_tri );

    if isfield( M , '\ntriNORMALS')
      fprintf( fid , '\nNORMALS CellsNormals %s\n', class_as_c( M.triNORMALS ) );
      write_in_file(fid, M.triNORMALS );
    end

    for f = 1:numel(fields)
      field= fields{f};
      M.(field) = M.(field)(:,:);
      if strncmp( field, 'tri',3)
        fprintf(fid, '\nFIELD field 1\n');
        fprintf(fid, '%s %d %d %s\n', field(4:end), size(M.(field),2), N_tri , class_as_c( M.(field) ) );
        write_in_file( fid, M.(field) );
      end
    end
  end

  fprintf( fid, '\n' );


  function c = class_as_c( x )
    switch class(x)
      case 'double',  c = 'double';
      case 'single',  c = 'float';
      case 'uint64',  c = 'unsigned_long';
      case 'int64',   c = 'long';
      case 'uint32',  c = 'unsigned_int';
      case 'int32',   c = 'int';
      case 'uint16',  c = 'unsigned_short';
      case 'int16',   c = 'short';
      case 'uint8',   c = 'unsigned_char';
      case 'int8',    c = 'char';
      case 'logical', c = 'char';
%       case 'logical', c = 'bool';
    end
  end

  function write_in_file( fid , x )
    switch AB
      case 'ASCII'
        if isfloat(x)
          str = sprintf( [ repmat( ' % 0.018e  ' , 1 , size( x , 2 ) ) , ' \n' ] , x.' );
          fprintf( fid , str );
        elseif isnumeric(x)
          str = sprintf( [ repmat( ' %5d ' , 1 , size( x , 2 ) ) , ' \n' ] , x.' );
          fprintf( fid , str );
        elseif islogical(x)
          str = sprintf( [ repmat( ' %d ' , 1 , size( x , 2 ) ) , ' \n' ] , int8( x.' ) );
          fprintf( fid , str );
        end
        
      case 'BINARY'
%         fwrite_flipped( fid , x.' );
        if islogical( x ), x = int8( x ); end
        fwrite( fid , x.' , class(x) , 0 , 'b' );
    end
    fprintf(fid, '\n');
  end


end
