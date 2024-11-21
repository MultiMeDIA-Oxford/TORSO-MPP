function M = read_CHASTE( ele_name , node_name , ortho_name )
%% TODO!!!: read Binary files... 

% 
% M = read_CHASTE( 'file.ele' , 'file.node' )
% M = read_CHASTE( 'file' )
% M = read_CHASTE( 'file.ele' , '' )
% M = read_CHASTE( '' , 'file.node' )
%

  face_name = '';
  epi_name  = '';
  lv_name   = '';
  rv_name   = '';

  if nargin < 3
    ortho_name  = '';
  end
  if nargin < 2  || ( nargin == 3 && isempty( node_name ) )
    if ~isempty( ele_name )
      [p,f,e] = fileparts( ele_name );
      if isempty(e), e = '.ele'; end
      ele_name    = fullfile( p , [ f , e ] );
      node_name   = fullfile( p , [ f , '.node' ] );

      face_name   = fullfile( p , [ f , '.face' ] );
      epi_name    = fullfile( p , [ f , '.epi' ] );
      lv_name     = fullfile( p , [ f , '.lv' ] );
      rv_name     = fullfile( p , [ f , '.rv' ] );
    end
    if nargin < 3
      ortho_name  = fullfile( p , [ f , '.ortho' ] );
    end

  end
  
  CLEANUP = {};

  if ~isempty( ele_name )
    ele_fid = fopen( ele_name , 'r' );
    if ele_fid < 0, error('Can''t open element ''%s'' file.' , ele_name ); end
    CLEANUP{end+1} = onCleanup( @()fclose(ele_fid) );

    while ~feof(ele_fid),
      L = strtrim( fgetl( ele_fid ) );
      if isempty( L ), continue; end
      if L(1) == '#', continue; end

      %First line: <number of elements> <nodes per element> <numer of attributes>
      F = textscan( L , '%d %d %d' );
      Ne = F{1};
      Nn = F{2};
      Na = F{3};

      format = '%*d ';
      for n = 1:Nn, format = [ format , '%u32 ' ]; end
      for n = 1:Na, format = [ format , '%d32 ' ]; end

      F = textscan( ele_fid , format , Ne , 'CommentStyle','#' );

      M.tri = horzcat( F{1:Nn} ) + 1;
      if Na
        M.triATTS = horzcat( F{ (Nn+1):(Nn+Na) } );
      end

      F = 0;
      break;
    end
    
    CLEANUP(end) = [];
  end

  if ~isempty( node_name )
    node_fid = fopen( node_name , 'r' );
    if node_fid < 0, error('Can''t open node ''%s'' file.' , node_name ); end
    CLEANUP{end+1} = onCleanup( @()fclose(node_fid) );

    while ~feof(node_fid),
      L = strtrim( fgetl( node_fid ) );
      if isempty( L ), continue; end
      if L(1) == '#', continue; end

      %First line: <number of nodes> <space dimension> <number of attributes> <number of boundary markers (0 or 1)>
      F = textscan( L , '%d %d %d %d' );
      Nn = F{1};
      Nd = F{2};
      Na = F{3};
      Nb = F{4};

      format = '%*d ';
      for n = 1:Nd, format = [ format , '%f ' ]; end
      for n = 1:Na, format = [ format , '%f ' ]; end
      if Nb,        format = [ format , '%d8 ' ]; end

      F = textscan( node_fid , format , Nn , 'CommentStyle','#' );

      M.xyz = horzcat( F{1:Nd} );
      if Na
        M.xyzATTS = horzcat( F{ (Nd+1):(Nd+Na) } );
      end
      if Nb
        M.xyzISBOUNDARY = ~~F{end};
      end

      F = 0;
      break;
    end
    
    CLEANUP(end) = [];
  end

  if ~isempty( face_name )  &&  isfile( face_name )
    face_fid = fopen( face_name , 'r' );
    if face_fid < 0, error('Can''t open face ''%s'' file.' , face_name ); end
    CLEANUP{end+1} = onCleanup( @()fclose(face_fid) );
    
    while ~feof(face_fid),
      L = strtrim( fgetl( face_fid ) );
      if isempty( L ), continue; end
      if L(1) == '#', continue; end

      %First line: <number of triangles> <0>>
      F = textscan( L , '%d %d' );
      Nt = F{1};

      format = '%*d %d %d %d';

      F = textscan( face_fid , format , Nt , 'CommentStyle','#' );

      M.face = horzcat( F{1:3} ) + 1;

      F = 0;
      break;
    end
  
    CLEANUP(end) = [];
  end
  
  if ~isempty( epi_name )  &&  isfile( epi_name )
    epi_fid = fopen( epi_name , 'r' );
    if epi_fid < 0, error('Can''t open epi ''%s'' file.' , epi_name ); end
    CLEANUP{end+1} = onCleanup( @()fclose(epi_fid) );
    
      format = '%d';
      F = textscan( epi_fid , format , 'CommentStyle','#' );
      M.epi = F{1} + 1;
      F = 0;
  
    CLEANUP(end) = [];
  end
  
  if ~isempty( lv_name )  &&  isfile( lv_name )
    lv_fid = fopen( lv_name , 'r' );
    if lv_fid < 0, error('Can''t open lv ''%s'' file.' , lv_name ); end
    CLEANUP{end+1} = onCleanup( @()fclose(lv_fid) );
    
      format = '%d';
      F = textscan( lv_fid , format , 'CommentStyle','#' );
      M.lv = F{1} + 1;
      F = 0;
  
    CLEANUP(end) = [];
  end
    
  if ~isempty( rv_name )  &&  isfile( rv_name )
    lv_fid = fopen( rv_name , 'r' );
    if lv_fid < 0, error('Can''t open rv ''%s'' file.' , rv_name ); end
    CLEANUP{end+1} = onCleanup( @()fclose(lv_fid) );
    
      format = '%d';
      F = textscan( lv_fid , format , 'CommentStyle','#' );
      M.rv = F{1} + 1;
      F = 0;
  
    CLEANUP(end) = [];
  end

  if ~isempty( ortho_name )  &&  isfile( ortho_name )
    ortho_fid = fopen( ortho_name , 'r' );
    if ortho_fid < 0, error('Can''t open ortho ''%s'' file.' , ortho_name ); end
    CLEANUP{end+1} = onCleanup( @()fclose(ortho_fid) );

    n = sscanf( fgetl(ortho_fid) , '%d' );
    F = textscan( ortho_fid , '%f %f %f %f %f %f %f %f %f', n );
    F = horzcat( F{:} );
    M.triORTHO = reshape( F ,[],3,3 );
  
    CLEANUP(end) = [];
  end
  
  
  M.celltype = 10;
  
end
