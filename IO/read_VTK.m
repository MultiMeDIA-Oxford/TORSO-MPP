function M = read_VTK( filename , ConvertToDouble , onlyHDR )
%
%

  if nargin < 2 || isempty( ConvertToDouble )
    ConvertToDouble = false;
  end
  if nargin < 3 || isempty( onlyHDR )
    onlyHDR = false;
  end
  
  
  fid = fopen(filename,'r');
  if( fid < 0 ), error('Can''t open the file.'); end
  CLEANUP = onCleanup( @()fclose(fid) );
  
  AB = 'ASCII';
  ENDIAN = 'ieee-be';
  
  HEADER = {};
  TITLE  = {};
  nCELLS  = 0;
  nPOINTS = 0;
  XT = 'field_';
  L = '';
  while ~feof(fid),
    getL();
    KEY = getKEY();
    switch upper( KEY )
      case '#'
        HEADER = L; L = ''; 
        while ~feof(fid)
          getL(); KEY = getKEY();
          if any(strcmpi( KEY , {'BINARY','ASCII'} ) ), break; end
          TITLE = [ TITLE , L ]; L = '';
        end
        
      case 'BINARY',  AB = 'BINARY'; L = '';

      case 'ASCII',   AB = 'ASCII';  L = '';

      case 'DATASET'
        datasetTYPE = parseline( '%*s %s' ); L = '';
        if ~any( strcmp( datasetTYPE , {'POLYDATA' , 'UNSTRUCTURED_GRID' } ) )
          error('This reader is for ''POLYDATA''s and ''UNSTRUCTURED_GRID''s only, not for ''%s''.' , datasetTYPE );
        end
        M.DatasetType = datasetTYPE;

      case 'POINTS'
        [nPOINTS,readTYPE] = parseline( '%*s %d %s' ); L = '';
        M.xyz = read( nPOINTS * 3 , readTYPE , AB );
        M.xyz = permute( reshape( M.xyz , [ 3 , nPOINTS , size( M.xyz , 2 ) ] ) , [2 1 3] );
        
      case {'LINES','POLYGONS','CELLS'}
        [nC,nDATA] = parseline( '%*s %d %d' ); L = '';
        nCELLS = nCELLS + nC;
        if onlyHDR
          read( nDATA , 'int32' , AB );
          M.tri = zeros( [ nCELLS , 0 ] , 'int32' );
        else
          M = AddCells( M , FixCells( read( nDATA , 'int32' , AB ) ) );
        end
        
      case 'CELL_TYPES'
        N = parseline( '%*s %d' ); L = '';
        if N ~= nCELLS
          warning('N in CELL_TYPES (%d) and nCELLS (%d) differ.',N,nCELLS);
        end
        M.celltype = read( N , 'int32' , AB );
        M.celltype = M.celltype(:);
        try
          if all( M.celltype == M.celltype(1) )
            M.celltype = M.celltype(1);
          end
        end

      case 'CELL_DATA'
        N = parseline( '%*s %d' ); L = '';
        if N ~= nCELLS
          warning('N in CELL_DATA (%d) and nCELLS (%d) differ.',N,nCELLS);
        end
        XT = 'tri'; gN = nCELLS;
        
      case 'POINT_DATA'
        N = parseline( '%*s %d' ); L = '';
        if N ~= nPOINTS
          warning('N in POINT_DATA (%d) and nCELLS (%d) differ.',N,nPOINTS);
        end
        XT = 'xyz'; gN = nPOINTS;

      case 'FIELD'
        [NAME , nA ] = parseline( '%*s %s %d' ); L = '';
        NAME = strrep( NAME , '%20' , ' ' );
        a = 0;
        while a < nA
          try
            getL();
            [ NAME , nC , nT , readTYPE ] = parseline('%s %d %d %s'); L = '';
            NAME = strrep( NAME , '%20' , ' ' );
            if strcmpi( readTYPE , 'string' )
              getL();
              DATA = L;
              L = ''; 
            else
              DATA = read( nC * nT , readTYPE , AB );
              DATA = permute( reshape( DATA , [ nC , nT , size( DATA , 2 ) ] ) , [2 1 3] );
            end
            M.( genvarname([ XT , NAME ]) ) = DATA;
            a = a+1;
          end
        end
        
      case 'SCALARS'
        [ NAME , readTYPE , nC ] = parseline( '%*s %s %s %d' ); L = '';
        NAME = strrep( NAME , '%20' , ' ' );
        if isempty( nC ), nC = 1; end
        getL(); KEY = getKEY();
        if ~strcmpi( KEY , 'LOOKUP_TABLE' )
          error('LOOKUP_TABLE was expected.');
        end
        [ tableName , tableSize ] = parseline( '%*s %s %d' ); L = '';
        if ~strcmp( tableName , 'default' )
          if isempty( tableSize ), tableSize = 0; end
          switch AB
            case 'BINARY', fseek( fid , 4*tableSize , 'cof' );
            case 'ASCII',  textscan( fid , '%f' , 4*tableSize );
          end
        end
        DATA = read( nC * gN , readTYPE , AB );
        DATA = permute( reshape( DATA , [ nC , gN , size( DATA , 2 ) ] ) , [2 1 3] );
        M.( genvarname([ XT , NAME ]) ) = DATA;
        
      case 'VECTORS'
        [NAME , readTYPE ] = parseline( '%*s %s %s' ); L = '';
        NAME = strrep( NAME , '%20' , ' ' );
        DATA = read( 3 * gN , readTYPE , AB );
        DATA = permute( reshape( DATA , [ 3 , gN , size( DATA , 2 ) ] ) , [2 1 3] );
        M.( genvarname([ XT , NAME ]) ) = DATA;
        
      case 'NORMALS'
        [NAME , readTYPE ] = parseline( '%*s %s %s' ); L = '';
        NAME = strrep( NAME , '%20' , ' ' );
%         if strcmpi( NAME , 'normals' ), NAME = upper( NAME ); end
        DATA = read( 3 * gN , readTYPE , AB );
        DATA = permute( reshape( DATA , [ 3 , gN , size( DATA , 2 ) ] ) , [2 1 3] );
        M.( genvarname([ XT , NAME ]) ) = DATA;

      case 'TEXTURE_COORDINATES'
        [NAME , nC , readTYPE ] = parseline( '%*s %s %d %s' ); L = '';
        NAME = strrep( NAME , '%20' , ' ' );
        DATA = read( nC * gN , readTYPE , AB );
        DATA = permute( reshape( DATA , [ nC , gN , size( DATA , 2 ) ] ) , [2 1 3] );
        M.( genvarname([ XT , NAME ]) ) = DATA;
        
      case 'TENSORS'
        [NAME , readTYPE ] = parseline( '%*s %s %s' ); L = '';
        NAME = strrep( NAME , '%20' , ' ' );
        DATA = read( 9 * gN , readTYPE , AB );
        DATA = reshape( permute( reshape( DATA , [ 9 , gN , size( DATA , 2 ) ] ) , [2 1 3] ) , [gN 3 3 size( DATA , 2 ) ] );
        M.( genvarname([ XT , NAME ]) ) = DATA;
        
      otherwise
        disp(L); L = '';
    end
  end
    
  if ~isempty( HEADER )
    if numel( HEADER ) == 1; HEADER = HEADER{1}; end
    M.HEADER = HEADER;
  end
  if ~isempty( TITLE )
    if numel( TITLE ) == 1; TITLE = TITLE{1}; end
    M.TITLE = TITLE;
  end
  
  if ConvertToDouble
    for f = fieldnames(M).'
      if strncmp( f{1} , 'xyz' , 3 ) || strncmp( f{1} , 'tri' , 3 )
        M.(f{1}) = double( M.(f{1}) );
      end
    end
  end
  
  
  function C = FixCells( C )
    %it is a good opportunity to check the endian
    %C(1) has to make sense!!
    if C(1) >= swapbytes(int32(1))
      C = swapbytes( C );
      for f = fieldnames(M).'
        M.(f{1}) = swapbytes( M.(f{1}) );
      end
      switch ENDIAN
        case {'ieee-be','b'}, ENDIAN = 'ieee-le';
        case {'ieee-le','l'}, ENDIAN = 'ieee-be';
      end      
    end
    try
      C = reshape( C , [ (C(1)+1) , numel(C)/(C(1)+1) ] );
      if ~all( C(1,:) == C(1) )
        error('GoToCatch');
      end
      C = C.';
      C = C(:,2:end);
    catch
      sz = zeros( numel(C) , 1 ,'uint8'); i = 1; j = 1;
      while i < numel( C )
        if C(i) > 255, sz = double(sz); end
        sz(j) = C(i); j = j+1;
        i  = i + C(i) + 1;
      end
      sz( j:end ) = [];
      sz = double(sz) + 1;
      C = mat2cell( C(:).' , 1 , sz );
      m = max( sz );
      for i = find( sz < m )'
        C{i}( (end+1):m ) = -1;
      end
      C = cell2mat( C.' );
      C = C(:,2:end);
    end
    C = C+1;
  end
  function M = AddCells( M , tri )
    if ~isfield( M , 'tri' )
      M.tri = [];
    elseif size( M.tri , 2 ) > size( tri , 2 )
      tri(:,size( M.tri , 2 )) = 0;
    elseif size( M.tri , 2 ) < size( tri , 2 )
      M.tri(:,size( tri , 2 )) = 0;
    end    
    M.tri = [ M.tri ; tri ];
  end
  function getL()
    while isempty(L) && ~feof( fid )
      L = fgetl( fid ); if ~ischar(L), L = ''; break; end
      if isempty( strtrim(L) )
        L = '';
      end
    end
  end
  function K = getKEY()
    K = strtok( L );
  end
  function [varargout] = parseline( varargin )
    out = textscan( L , varargin{:} );
    for o = 1:nargout
      varargout{o} = out{o};
      while iscell( varargout{o} )
        try,   varargout{o} = varargout{o}{1};
        catch, varargout{o} = [];
        end
      end
    end
  end
  function x = read( READnum , READtype , AB )
    READtype = class_as_matlab( READtype );
    switch AB
      case 'BINARY'
%         if onlyHDR
%           fseek( fid , READnum * 1 , 'cof' );
%         else
          x = fread( fid , READnum , ['*' READtype] , 0 , ENDIAN );
%         end

      case 'ASCII'
        cof = ftell( fid );

        switch READtype
          case 'double', x = textscan( fid , '%f64' , READnum );
          case 'single', x = textscan( fid , '%f32' , READnum );
          case 'uint64', x = textscan( fid , '%u64' , READnum );
          case  'int64', x = textscan( fid , '%d64' , READnum );
          case 'uint32', x = textscan( fid , '%u32' , READnum );
          case  'int32', x = textscan( fid , '%d32' , READnum );
          case 'uint16', x = textscan( fid , '%u16' , READnum );
          case  'int16', x = textscan( fid , '%d16' , READnum );
          case 'uint8' , x = textscan( fid , '%u8'  , READnum );
          case  'int8' , x = textscan( fid , '%d8'  , READnum );
        end
        x = x{1};
        
        if numel( x ) ~= READnum
          fseek( fid , cof , 'bof' );
          
          opts = { 'delimiter',{' ','\t','\n','\r','\\','\b',';',','} , 'MultipleDelimsAsOne', true };
          switch READtype
            case 'double', x = textscan( fid , '%f64' , READnum , opts{:} );
            case 'single', x = textscan( fid , '%f32' , READnum , opts{:} );
            case 'uint64', x = textscan( fid , '%u64' , READnum , opts{:} );
            case  'int64', x = textscan( fid , '%d64' , READnum , opts{:} );
            case 'uint32', x = textscan( fid , '%u32' , READnum , opts{:} );
            case  'int32', x = textscan( fid , '%d32' , READnum , opts{:} );
            case 'uint16', x = textscan( fid , '%u16' , READnum , opts{:} );
            case  'int16', x = textscan( fid , '%d16' , READnum , opts{:} );
            case 'uint8' , x = textscan( fid , '%u8'  , READnum , opts{:} );
            case  'int8' , x = textscan( fid , '%d8'  , READnum , opts{:} );
          end
          x = x{1};
          
        end
        if numel( x ) ~= READnum
          warning('wrong reading by textscan!!!');
        end        
        
    end
    if onlyHDR
      x = zeros( [numel(x) 0] , 'like' , x );
    end
  end
  
end
function x = class_as_matlab( x )
  switch lower(strtrim(x))
    case 'double',         x = 'double';
    case 'float',          x = 'single';
    case 'unsigned_long',  x = 'uint64';
    case 'long',           x = 'int64';
    case 'unsigned_int',   x = 'uint32';
    case 'int',            x = 'int32';
    case 'unsigned_short', x = 'uint16';
    case 'short',          x = 'int16';
    case 'unsigned_char',  x = 'uint8';
    case 'char',           x = 'int8';
    case 'vtkidtype',      x = 'int32';
  end
end
