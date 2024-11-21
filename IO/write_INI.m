function write_INI( fname , gName , kName , Value )
% 
%   If fname does not exist, create fname with the info in struct S.
%   If it does exist, modify existing keys and add new ones.
%
% write_INI( fname , S )
%   S should be:  S.sectionName1.key1 = value1
%                 S.sectionName1.key2 = value2
%                 S.sectionName2.key1 = value
%   or:   S.key1 = value1
%         S.key2 = value2
% 
% write_INI( fname , groupName , S )
%   S should be:  S.key1 = value1
%                 S.key2 = value2
% 
% write_INI( fname , '' , S )
%   add or modify the keys before the first sectionName.
%   S should be:  S.key1 = value1
%                 S.key2 = value2
% 
% write_INI( fname , groupName , keyName , value )
%   add or modify the groupName.keyName.
%   groupName can be ''
%

  if isstruct( gName ) && nargin > 2
    error('If a STRUCT is specified, no more than 2 args are required.');
  end
  if nargin > 2 && isstruct( kName ) && nargin > 3
    error('If a struct is specified, no more than 3 args are required.');
  end
  if nargin > 2 && ischar( kName ) && ~isequal( kName(1) , '-' ) && nargin < 4
    error('A trio ''group''-''key''-value was expected.');
  end
  if nargin > 2 && ischar( kName ) && isequal( kName(1) , '-' ) && nargin > 3
    error('A trio ''group'',''-key'' was expected.');
  end
  
  if isstruct( gName )
    S = gName;
    
    Fn = fieldnames( S );
    if isstruct( S.(Fn{1}) )
      for ff = 1:numel( Fn )
        write_INI( fname , Fn{ff} , S.(Fn{ff}) );
      end
    else
      write_INI( fname , '' , S );
    end
    
    return;
  end
  
  if ischar( kName ) && ~isequal( kName(1) , '-' );
    write_INI( fname , gName , struct( kName , Value ) );
    
    return;
  end

  
  if nargin < 3, error('A structure was expected'); end
  if isempty( gName ), gName = 'E_m_p_t_y__G_r_o_u_p'; end
  
  TT = {'[E_m_p_t_y__G_r_o_u_p]'};
  if isfile( fname )
    TT = [ TT ; read_File( fname ) ];
  end
%   for l=1:numel(TT), fprintf('%3d. %s\n',l,TT{l}); end
  
  
  g_starts = [ find( ~cellfun('isempty', regexp( TT , '^\[[A-Za-z0-9_]*\]\s*$' , 'once' )) ) ; numel(TT)+1 ];
  id0 = find( ~cellfun('isempty',regexp( TT , [ '^\[' , gName , '\]\s*$' ] )) , 1 );
  if isempty( id0 )
    id1 = numel(TT)+1;
    id0 = numel(TT)+1;
  else
    id1 = g_starts( find( g_starts > id0 ,1) );
  end
  
  T0 = TT(     1:id0-1 );
  T1 = TT(   id1:end   );
  TT = [ { [ '[' gName ']' ] } ; TT( id0+1:id1-1 ) ];
  
  try, while isempty( strtrim(T0{1  }) ), T0(1  ) = []; end; end
  try, while isempty( strtrim(T0{end}) ), T0(end) = []; end; end
  try, while isempty( strtrim(TT{1  }) ), TT(1  ) = []; end; end
  try, while isempty( strtrim(TT{end}) ), TT(end) = []; end; end
  try, while isempty( strtrim(T1{1  }) ), T1(1  ) = []; end; end
  try, while isempty( strtrim(T1{end}) ), T1(end) = []; end; end
  
  if ischar( kName ) && isequal(kName(1),'-')

    id = ~cellfun( 'isempty' , regexp( TT , [ '^\s*' strtrim(kName(2:end)) '\s*=' ] , 'once' ) );
    TT(id) = [];
    
  else
  
    Fn = fieldnames( kName );
    for ff = 1:numel( Fn )
      id = find( ~cellfun( 'isempty' , regexp( TT , [ '^\s*' Fn{ff} '\s*=' ] , 'once' ) ) );

      if isempty( id )
        TT = [ TT ; writeLine( Fn{ff} , kName.(Fn{ff}) ) ];
      elseif numel( id ) == 1
        TT{id} = writeLine( Fn{ff} , kName.(Fn{ff}) );
      elseif numel( id ) > 1
        TT{ id(end) } = writeLine( Fn{ff} , kName.(Fn{ff}) );
        TT( id(1:end-1) ) = [];
      end
    end
  
  end
  
  if numel( T0 ) && isequal(T0{1},'[E_m_p_t_y__G_r_o_u_p]'), T0(1) = []; end
  if numel( TT ) && isequal(TT{1},'[E_m_p_t_y__G_r_o_u_p]'), TT(1) = []; end
  if numel( T1 ) && isequal(T1{1},'[E_m_p_t_y__G_r_o_u_p]'), T1(1) = []; end
  
  
  fid = fopen( fname , 'w' );
  for tt = 1:numel( T0 ), fprintf( fid , '%s\n' , T0{tt} ); end
  for tt = 1:numel( TT ), fprintf( fid , '%s\n' , TT{tt} ); end
  for tt = 1:numel( T1 ), fprintf( fid , '%s\n' , T1{tt} ); end
  fclose( fid );
  
  
  function L = writeLine( k , v )
    L = '';
    if      ischar( v ) && ismatrix( v ) && size( v , 1 ) == 1
      try
        if all( ismember( v , '0123456789edEDij., -+INnFfAa' ) ) && ~isqual( eval( [ '[' , v , ']' ] ) , v )
          v = [ '"' , v , '"' ];
        end
      end
      L = v;
    elseif  isa(v,'double') && ismatrix( v ) && size( v , 1 ) == 1
      vv = v(1); L = number2str( vv );
      for vv = v(2:end)
        L = [ L , ',' , number2str(vv) ];
      end
    elseif  isa(v,'logical') && numel( v ) == 1 && v
      L = 'true';
    elseif  isa(v,'logical') && numel( v ) == 1 && ~v
      L = 'false';
    end
    L = sprintf( '%s=%s' , k , L );
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
