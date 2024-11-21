function S = read_INI( fname , groupName )
% 
% S = read_INI( fname )
%   Read the whole file. Each group section in a structure field.
%   All keys defined before any group section, grouped in S.E_m_p_t_y__G_r_o_u_p
% 
% S = read_INI( fname , groupName )
%   Only read keys under [groupName] section.
% 
% S = read_INI( fname , '' )
%   Only read keys defined before any group section.
% 

  S = struct([]);
  if ~isfile( fname , 'fast' ), return; end
  
  T = {'[E_m_p_t_y__G_r_o_u_p]'};
  T = [ T ; read_File( fname ) ];
  
  g_starts = [ find( ~cellfun('isempty', regexp( T , '^\[[A-Za-z0-9_]*\]\s*$' , 'once' )) ) ; numel(T)+1 ];
  if nargin > 1
    if isempty( groupName )
      groupName = 'E_m_p_t_y__G_r_o_u_p';
    end
    id = find( ~cellfun('isempty',regexp( T , [ '^\[' , groupName , '\]\s*$' ] )) , 1 );
    if isempty( id ), return; end
    T = T( (id+1) : ( g_starts( find( g_starts>id ,1) )-1 ) );
  end
  
  S = struct();
  g = '';
  for t = 1:numel( T )
    L = strtrim(T{t});
    if isempty(L) , continue; end
    if L(1) == ';', continue; end
    if L(1) == '#', continue; end
    if ( L(1) == '[' ) && ( L(end) == ']' )
      g = fixName( L(2:end-1) , 'G_' );
      continue;
    end
    
    [k,v] = parseLine( L );
    
    if isempty(k), continue; end
    if isempty( g ), S.(k)     = v;
    else           , S.(g).(k) = v;
    end
  end
  
  
  function n = fixName( n , kg )
    n(64:end) = [];
    try, kk.(n) = 1; return; end

    n = regexprep( n , '[^A-Za-z0-9_]' , '_' );
    n(64:end) = [];
    try, kk.(n) = 1; return; end
    
    n = [kg,n];
    n(64:end) = [];
    try, kk.(n) = 1; return; end
    
  end
  
  function [k,v] = parseLine( L )
    Lorig = L;
    L = regexp( L , '(?<key>[^=]*)\s*=\s*(?<value>.*)' , 'names' );
    
    if numel(L) ~= 1 || ~isfield( L , 'key' ) || ~isfield( L , 'value' )
      k = 'NonParseableLine';
      v = Lorig;
      return;
    end
    
    k = fixName( strtrim( L.key ) , 'K_' );
    v = strtrim( L.value );

    if isempty( v ), v = ''; return; end
    
    vv = strcmpi( v , 'false' );
    try, if vv
      v = false;
    return; end; end
    
    vv = strcmpi( v , 'true' );
    try, if vv
      v = true;
    return; end; end

    vv = ismember( v , '0123456789edEDij., -+INnFfAa' );
    try, if all(vv)
      v = eval( [ '[' , v , ']' ] );
    return; end; end
    
    vv = regexp( v , '^eval\(\s*(.*)\s*\)\s*;?$' , 'tokens' , 'once' );
    try, if ~isempty(vv)
      v = eval(vv{1});
    return; end; end

    vv = regexp( v , '^"([^"]*)"$' , 'tokens' , 'once' );
    try, if ~isempty(vv)
      v = vv{1};
    return; end; end
    
    vv = regexp( v , '^""([^"]*)""$' , 'tokens' , 'once' );
    try, if ~isempty(vv)
      v = ['"' , vv{1} , '"' ];
    return; end; end

    vv = regexp( v , '^''([^'']*)''$' , 'tokens' , 'once' );
    try, if ~isempty(vv)
      v = vv{1};
    return; end; end

  end

  function L = read_File( fn )
    fid = fopen( fn , 'r' );
    L = { fgetl(fid) };
    while ~feof(fid);
      L{end+1,1} = fgetl(fid);
    end
    fclose(fid);
  end

end
