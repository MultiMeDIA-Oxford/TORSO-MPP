function SS = uneval( varargin )
%{

files = rdir( 'c:\' ,'\.mat' );

for f = 3100:numel(files)
  try
    vars = whos('-file',files(f).name);
    for v = 1:numel(vars)
      fprintf('%6d  - %6d de %6d\n' , f , v , numel(vars) );
      X = load( files(f).name , vars(v).name );
      X = X.(vars(v).name);
      bs = bytessize( X ,'disk')/1024/1024
      if bs > 0.5, continue; end
      try
        S = uneval( X );
      catch, save( [ tmpname(['g:\Work\inverter\BADS\' class(X) '_' ] , 8 ) '.mat' ] , 'X' );
      end      
    end
  end
end

%}


  LEVEL = 2;


  if nargin == 0
    SS = '';
    return;
  end
  
  if nargin > 1
    SS = uneval( varargin{1} );
    for idx = 2:numel(varargin)
      SS = [ SS , ' , ' , uneval( varargin{idx} ) ];
    end
    
    return;
  end


  M = varargin{1};

  nolast = @(x) x(1:end-1);
  sizestr = @(x) [ '[' nolast( sprintf('%d,',size(x)) ) ']' ];
  function ss = no_bracks( ss )
    try
      if isequalwithequalnans( eval(ss) , eval(ss(2:end-1)) )
        ss = ss(2:end-1);
      end        
    end
  end
  


  if ~issparse(M)

    switch class(M)
      case {'int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
                                  S = uneval_integer( M );
      case {'double'},            S = uneval_double( M );
      case {'single'},            S = uneval_single( M );
      case {'logical'},           S = uneval_logical( M );
      case {'char'},              S = uneval_char( M );
        if ~ischar( eval(S) ), S = [ 'char('   S   ')' ]; end
      case {'cell'},              S = uneval_cell( M );
      case {'struct'},            S = uneval_struct( M );
			case {'function_handle'},   S = uneval_fhandle(M);
        
      case {'parallel.gpu.GPUArray'}, S = uneval_gpuarray( M );
        
      
      otherwise
        error('unknown class!!');
    end

  elseif isa( M , 'double'),      S = uneval_sparsedouble(M);
  elseif isa( M , 'logical'),     S = uneval_sparselogical(M);
  else
    error('unknown class!!');
  end
  
  
  
  try
    Y = eval(S);
    if ~isidentical( M , Y )
%       X = M;
%       isequal( typecast(X(1:end),'uint8') , typecast(Y(1:end),'uint8') )
%       save( [ tmpname('g:\Work\inverter\BADS\bads_unevals_' , 8 ) '.mat' ] , 'M' );
      error('alguna  differencia!!!    %s', S);
    end
  catch LE
%     save( [ tmpname('g:\Work\inverter\BADS\bads_unevals_' , 8 ) '.mat' ] , 'M' );
    disperror(LE);
    error('algun error!!!    %s', S);
  end

  if nargout > 0
    SS = S;
  else
    Iname = inputname(1);
    if isempty( Iname  )
      fprintf('%s\n', S );
    else
      fprintf('%s   = %s\n', Iname , S );
    end
  end


  
  function S = uneval_gpuarray( M )
    S = uneval( gather(M) );
    
    S = [ 'parallel.gpu.GPUArray(' , S , ')' ];
    
    S = regexprep( S , '\.GPUArray\(eye\((.*)\)\)'    ,'.GPUArray.eye($1)'   );
    S = regexprep( S , '\.GPUArray\(zeros\((.*)\)\)'  ,'.GPUArray.zeros($1)' );
    S = regexprep( S , '\.GPUArray\(NaN\((.*)\)\)'    ,'.GPUArray.nan($1)'   );
    
    S = regexprep( S , 'parallel\.gpu\.GPUArray\(-Inf\((.*)\)\)'    ,'-parallel.gpu.GPUArray.inf($1)'   );
    
    S = regexprep( S , '\.GPUArray\(Inf\((.*)\)\)'    ,'.GPUArray.inf($1)'   );
    
    S = regexprep( S , '\.GPUArray\(ones\((.*)\)\)'   ,'.GPUArray.ones($1)'  );
    S = regexprep( S , '\.GPUArray\(true\((.*)\)\)'   ,'.GPUArray.true($1)'  );
    S = regexprep( S , '\.GPUArray\(false\((.*)\)\)'  ,'.GPUArray.false($1)' );
    
  end
  

  function S = uneval_integer( M )
    cl = class( M );
    if numel(M) == 0
      if isequal( size(M) , [0 0] )
        S = [ cl '([])' ];
        return;
      end
      S = [ 'zeros('  sizestr(M)   ',''' cl ''')' ];
      return;
    end
    if numel(M) == 1                          , S = [ cl '(' number2str( M ,LEVEL)  ')' ];         return; end
    if all( M(:) == 0 )                       , S = [ 'zeros('  sizestr(M)   ',''' cl ''')' ];   return; end
    if all( M(:) == 1 )  && numel( M )>16                      , S = [  'ones('  sizestr(M)   ',''' cl ''')' ];   return; end
    if all( M(:) == -1 ) && numel( M )>16                      , S = [ '-ones('  sizestr(M)   ',''' cl ''')' ];   return; end
    if ndims(M)<=2 && isequal( eye(size(M)),M), S = [   'eye('  sizestr(M)   ',''' cl ''')' ];   return; end
    if ndims(M)<=2 && isequal(-eye(size(M)),M), S = [  '-eye('  sizestr(M)   ',''' cl ''')' ];   return; end


    S = [ cl '(' numeric2str( M ) ')' ];
  end
  
  
  function S = uneval_double( M )
    if numel(M) == 0
      if isequal( size(M) , [0 0] )
        S = '[]';
        return;
      end
      S = [ 'zeros('  sizestr(M)   ')' ];
      return;
    end
    if numel(M) == 1
      S = number2str( M , LEVEL );
      return; 
    end
    if all( M(:) == 0 ) && numel( M )>16
      if isidentical( zeros(size(M)) , M ) 
        S = [ 'zeros('  sizestr(M)   ')' ];
        return;
      end
    end
    if all( M(:) == 1 )  && numel( M )>16                     , S = [  'ones('  sizestr(M)   ')' ];   return; end
    if all( M(:) == -1 ) && numel( M )>16                     , S = [ '-ones('  sizestr(M)   ')' ];   return; end
    if all( M(:) == Inf )                     , S = [   'Inf('  sizestr(M)   ')' ];   return; end
    if all( M(:) == -Inf )                    , S = [  '-Inf('  sizestr(M)   ')' ];   return; end
    if ndims(M)<=2 && isequal( eye(size(M)),M), S = [   'eye('  sizestr(M)   ')' ];   return; end
    if ndims(M)<=2 && isequal( eye(size(M)),M), S = [  '-eye('  sizestr(M)   ')' ];   return; end

    if all( isnan(M(:)) )
      if isidentical( NaN(size(M)) , M )
        S = [   'NaN('  sizestr(M)   ')' ];
        return;
      elseif isidentical( -NaN(size(M)) , M )
        S = [   '-NaN('  sizestr(M)   ')' ];
        return;
      elseif isvector( M )
        S1 = [ 'typecast(' uneval( typecast(M,'int32') ) ',''double'')' ];
        S2 = numeric2str( M );
        if numel(S1) < numel(S2),   S = S1;
        else,                       S = S2;
        end
        return;
      else
        S1 = [ 'reshape( typecast(' uneval( typecast(M(:)','int32') ) ',''double''),' sizestr(M) ')' ];
        S2 = numeric2str( M );
        if numel(S1) < numel(S2),   S = S1;
        else,                       S = S2;
        end
        return;
      end
    end

    S = numeric2str( M );
  end
  
  
  function S = uneval_single( M )
    if numel(M) == 0
      if isequal( size(M) , [0 0] )
        S = 'single([])';
        return;
      end
      S = [ 'zeros('  sizestr(M)   ',''single'')' ];
      return;
    end
    if numel(M) == 1
      S = [ 'single('  number2str( M , LEVEL )  ')' ] ;
      return; 
    end
    if all( M(:) == 0 )
      if isidentical( zeros(size(M)) , M )
        S = [ 'zeros('  sizestr(M)   ',''single'')' ];
        return;
      end
    end
    if all( M(:) == 1 )                       , S = [  'ones('  sizestr(M)   ',''single'')' ];   return; end
    if all( M(:) == -1 )                      , S = [ '-ones('  sizestr(M)   ',''single'')' ];   return; end
    if all( M(:) == Inf )                     , S = [   'Inf('  sizestr(M)   ',''single'')' ];   return; end
    if all( M(:) == -Inf )                    , S = [  '-Inf('  sizestr(M)   ',''single'')' ];   return; end
    if ndims(M)<=2 && isequal( eye(size(M)),M), S = [   'eye('  sizestr(M)   ',''single'')' ];   return; end
    if ndims(M)<=2 && isequal( eye(size(M)),M), S = [  '-eye('  sizestr(M)   ',''single'')' ];   return; end

    if all( isnan(M(:)) )
      if isidentical( NaN(size(M),'single') , M )
        S = [   'NaN('  sizestr(M)   ',''single'')' ];
        return;
      elseif isidentical( -NaN(size(M),'single') , M )
        S = [   '-NaN('  sizestr(M)   ',''single'')' ];
        return;
      elseif isvector( M )
        S1 = [ 'typecast(' uneval( typecast(M,'int32') ) ',''single'')' ];
        S2 = [ 'single('  numeric2str( M )  ')' ];
        if numel(S1) < numel(S2),   S = S1;
        else,                       S = S2;
        end
        return;
      else
        S1 = [ 'reshape( typecast(' uneval( typecast(M(:)','int32') ) ',''single''),' sizestr(M) ')' ];
        S2 = [ 'single('  numeric2str( M )  ')' ];
        if numel(S1) < numel(S2),   S = S1;
        else,                       S = S2;
        end
        return;
      end
    end

    S = [ 'single(' numeric2str( M ) ')' ];
  end
  
  
  
  
  
  
  
  
  function S = uneval_sparselogical(M)
    [m,n] = size( M );
    nz    = nzmax( M );
    if nz == 1
      if m == 0 && n == 0
        S = 'sparse(true(0))';
        return;
      elseif m == 0 || n == 0
        S = [ 'sparse(true('  number2str(m,LEVEL) ',' number2str(n,LEVEL) '))' ];
        return;
      end
    elseif m == 0 || n == 0
      S = [ 'logical(sparse([],[],[],' number2str(m,LEVEL) ',' number2str(n,LEVEL) ',' number2str(nz,LEVEL) '))' ];
      return;
    end
    
    s     = nonzeros( M );
    if numel(s) == 0 
      if nz == 1
        S = [ 'sparse(false(' number2str(m,LEVEL) ',' number2str(n,LEVEL) '))' ];
      else
        S = [ 'sparse([],[],false(0),' number2str(m,LEVEL) ',' number2str(n,LEVEL) ',' number2str(nz,LEVEL) ')' ];
      end
      return;
    end

    [i,j] = find( M );
    if numel(s) == nz, nz = 0; end
    if all( s(:) == s(1) ), s = s(1); end
    
    if nz == 0 && max(i) == m && max(j) == n, m=0; n=0; end

    if nz > 0
      S = [ 'sparse(' no_bracks( uneval(i(:).' ) ) ',' no_bracks( uneval(j(:).' ) ) ',' no_bracks( uneval(s(:).' ) ) ',' number2str(m,LEVEL) ',' number2str(n,LEVEL) ',' number2str(nz,LEVEL) ')' ];
    elseif m > 0 && n > 0
      S = [ 'sparse(' no_bracks( uneval(i(:).' ) ) ',' no_bracks( uneval(j(:).' ) ) ',' no_bracks( uneval(s(:).' ) ) ',' number2str(m,LEVEL) ',' number2str(n,LEVEL) ')' ];
    else
      S = [ 'sparse(' no_bracks( uneval(i(:).' ) ) ',' no_bracks( uneval(j(:).' ) ) ',' no_bracks( uneval(s(:).' ) ) ')' ];
    end

  end


  function S = uneval_sparsedouble(M)
    [m,n] = size( M );
    nz    = nzmax( M );
    if nz == 1
      if m == 0 && n == 0
        S = 'sparse([])';
        return;
      elseif m == 0 || n == 0
        S = [ 'sparse('  number2str(m,LEVEL) ',' number2str(n,LEVEL) ')' ];
        return;
      end
    elseif m == 0 || n == 0
      S = [ 'sparse([],[],[],' number2str(m,LEVEL) ',' number2str(n,LEVEL) ',' number2str(nz,LEVEL) ')' ];
      return;
    end
    
    s     = nonzeros( M );
    if numel(s) == 0 
      if nz == 1
        S = [ 'sparse(' number2str(m,LEVEL) ',' number2str(n,LEVEL) ')' ];
      else
        S = [ 'spalloc(' number2str(m,LEVEL) ',' number2str(n,LEVEL) ',' number2str(nz,LEVEL) ')' ];
%         S = [ 'sparse([],[],[],' number2str(m,LEVEL) ',' number2str(n,LEVEL) ',' number2str(nz,LEVEL) ')' ];
      end
      return;
    end

    [i,j] = find( M );
    if all( s(:) == 1 ) && isequal(i,j) && nz == numel(s) && max(i) == min(m,n)
      if isequal( i(:).' , 1:max(i) )
        S = [ 'speye(' number2str(m,LEVEL) ',' number2str(n,LEVEL) ')' ];
        return;
      end
    end
    
    
    if numel(s) == nz, nz = 0; end
    if all( s(:) == s(1) ), s = s(1); end
    
    if nz == 0 && max(i) == m && max(j) == n, m=0; n=0; end
    
    if nz > 0
      S = [ 'sparse(' no_bracks( uneval(i(:).' ) ) ',' no_bracks( uneval(j(:).' ) ) ',' no_bracks( uneval(s(:).' ) ) ',' number2str(m,LEVEL) ',' number2str(n,LEVEL) ',' number2str(nz) ')' ];
    elseif m > 0 && n > 0
      S = [ 'sparse(' no_bracks( uneval(i(:).' ) ) ',' no_bracks( uneval(j(:).' ) ) ',' no_bracks( uneval(s(:).' ) ) ',' number2str(m,LEVEL) ',' number2str(n,LEVEL) ')' ];
    else
      S = [ 'sparse(' no_bracks( uneval(i(:).' ) ) ',' no_bracks( uneval(j(:).' ) ) ',' no_bracks( uneval(s(:).' ) ) ')' ];
    end      
  end


  function S = uneval_fhandle(M)
    error('function_handle no esta implementada todavia');
    
    S = func2str( M );
    
    F = functions(M);
    W = F.workspace;
    for c = 1:numel(W)
      WW = W{c};
      VS = fieldnames( WW );
      for vv = 1:numel(VS)
        if isempty( regexp( S , ['\<' VS{vv} '\>' ] , 'Once' ) ), continue; end
        S = regexprep( S , ['\<' VS{vv} '\>' ] , uneval( WW.(VS{vv}) ) );
      end
    end
  end


  function S = uneval_struct( M )
    if numel(M) == 0  
      if isequal( size(M) , [0 0] ) && isempty(fieldnames(M))
        S = 'struct([])' ;
        return;
      end

      FNs = fieldnames( M );
      
      if isequal( size(M) , [0 0] )
        S = 'struct(';
        for ff = 1:numel(FNs)
          S = [ S , uneval( FNs{ff} ) ,',' , '{}' , ',' ];
        end
      
        S = [ S(1:end-1) ')' ];
        return;
      end
      
      S = [ 'reshape(' 'struct(' ];
      for ff = 1:numel(FNs)
        S = [ S , uneval( FNs{ff} ) ,',' , '{}' , ',' ];
      end

      if S(end)==',', S(end)=[]; end
      S = [ S ')' ];
      S = [ S ',' sizestr( M ) ')' ];
      return;
      
    end
    
    
    FNs = fieldnames( M );
    if ~isempty( FNs )

      S = 'struct(';
      for ff = 1:numel(FNs)
        if numel(M) > 1
          if ff > 1  && all( arrayfun( @(i) isidentical( M(1).(FNs{ff}) , M(i).(FNs{ff}) ) , 2:numel(M) ) )
            if iscell( M(1).(FNs{ff}) )
              S = [ S '''' FNs{ff} ''',' uneval( { M(1).(FNs{ff}) } )  ','  ];
            else
              S = [ S '''' FNs{ff} ''',' uneval(   M(1).(FNs{ff}) )  ','  ];
            end              
          else
            S = [ S '''' FNs{ff} ''',' uneval( reshape( { M.(FNs{ff}) } , size( M ) ) )  ','  ];
          end
        elseif iscell( M.(FNs{ff}) )
          S = [ S '''' FNs{ff} ''',' uneval( { M.(FNs{ff}) } )  ','  ];
        else
          S = [ S '''' FNs{ff} ''',' uneval( M.(FNs{ff}) )  ','  ];
          
        end
      end
      S = [ S(1:end-1) ')' ];

    elseif numel(M) == 1
      S = 'struct()';
      
    else
      
      
      S = [ 'repmat(struct([]),' sizestr(M) ')' ];
    end
    
  end
  
  
  function S = uneval_cell( M )
    if numel(M) == 0
      if isequal( size(M) , [0 0] )
        S = '{}';
        return;
      end
      S = [ 'cell('  nolast( sprintf('%d,',size(M)) )   ')' ];
      return;
    end

    if all( cellfun( @(m) isequal(size(m),[0 0]) ,M(:) ) )  && all( cellfun( @(c) isa(c,'double') , M(:) ) )
      S = [ 'cell('  nolast( sprintf('%d,',size(M)) )  ')' ];
      return;
    end

    if numel( M ) == 1
      S = [ '{' uneval(M{1} ) '}' ];
      return;
    end
    
    if all( cellfun( @(ci) isidentical(ci,M{1}) , M(2:end) ) )  && all( cellfun( @(c) isa(c,class(M{1})) , M(2:end) ) )
      S = [ 'repmat(' uneval_cell(M(1)) ',' sizestr(M) ')' ];
      return;
    end
    
    if all( cellfun( @isscalar  , M(:) ) )  &&   all( cellfun( @(c) isnumeric(c) , M(2:end) ) )
      S = [ 'num2cell(' uneval(cell2mat(M) ) ')' ];
      return;
    end
    
    if ndims(M) > 2
      S = [ 'reshape(' uneval_cell(M(:,:)) ',' sizestr(M) ')' ];
      return;
    end
    
    S = '{';
    for i = 1:size(M,1)
      for j = 1:size(M,2)
        S = [ S  uneval(M{i,j} ) ',' ];
      end
      S = [ S(1:end-1)  ';' ];
    end
    S = [ S(1:end-1) '}' ];
        
    
  end
  

  function S = uneval_char( M )
    if numel(M) == 0
      if isequal( size(M) , [0 0] )
        S = '''''';
        return;
      end
      S = [ 'zeros('  sizestr(M)   ')' ];
      return;
    end
    if all( M(:) == 0 )                       , S = [ 'zeros('  sizestr(M)   ')' ];   return; end
    if all( M(:) == 1 )                       , S = [  'ones('  sizestr(M)   ')' ];   return; end

    if numel(M) == 1
      if any( M < 32 ) || any( M > 126 )
        S = sprintf('%d', uint16( M ) );
      elseif uint16(M) == 39
        S = '''''''''' ;
      else
        S = [ ''''  M  '''' ];
      end
      return; 
    end
    
    
    if ndims( M ) > 3
      S = [ 'reshape('   uneval_char( M(:,:,:) )   ','  sizestr(M)  ')' ];
      return;
    end
    
    if ndims( M ) == 3
      S = 'cat(3,';
      for k=1:size(M,3)
        S = [ S  uneval_char( M(:,:,k) ) ',' ];
      end
      S = [ S(1:end-1) ')' ];
      return;
    end
    
    if size(M,2) == 1
      
    end
    
    if size(M,1) > 1
      S = '[';
      for i = 1:size(M,1)
        S = [ S  uneval_char(M(i,:)) ';' ];
      end
      S = [ S(1:end-1) ']' ];
      return;
    end
    
    if all( M == 32 )  && numel(M) > 9
      S = [ 'blanks(' sprintf('%d',numel(M)) ')' ];
    elseif any( M < 32 ) || any( M > 126 )
      S = M;
      S = strrep( S , char(92) , '\\' );
      S = strrep( S , char(8 ) , '\b' );
      S = strrep( S , char(9 ) , '\t' );
      S = strrep( S , char(10) , '\n' );
      S = strrep( S , char(12) , '\f' );
      S = strrep( S , char(13) , '\r' );
      S = strrep( S , char(37) , '%%' );
      S = strrep( S , char(39) , '''''' );
      S = [ 'sprintf(''' S ''')' ];
      if ~isequal( eval( S ) , M )
        S = [ '[' sprintf('%d ', uint16( M ) ) ']' ];
      end
    else
      S = [ ''''  strrep( M , '''' , '''''' )   '''' ];
    end
    
  end
  
  
  function S = uneval_logical( M )
    if numel(M) == 0
      if isequal( size(M) , [0 0] )
        S = 'true(0)';
        return;
      end
      S = [ 'true('  sizestr(M)  ')' ];
      return;
    end
    if numel(M) == 1  &&  M                   , S = 'true';     return;  end
    if numel(M) == 1  && ~M                   , S = 'false';    return;  end
    if all( M(:) )                            , S = [  'true('  sizestr(M)   ')' ];   return; end
    if ~any( M(:) )                           , S = [ 'false('  sizestr(M)   ')' ];   return; end

    S = numeric2str( M );
    if ~isidentical( M , eval(S) )
      S = [ 'logical(' S ')' ];
    end
  end



  function S = numeric2str( M )
    if numel(M) == 1
      S = number2str( M ,LEVEL);
      return;
    end
    
    if numel(M)>16 && isidentical( M , repmat( M(1) , size( M ) ) )
      S = [ 'repmat(' number2str( M(1) , LEVEL )   ','  sizestr(M)  ')' ];
      return;
    end

    if ndims( M ) > 2
      
      dots(1:ndims(M)) = {':'};
      unos             = ones( 1 , ndims(M) );
      for d = ndims(M):-1:1
        if size(M,d) == 1, continue; end
        dots{d} = 1;
        unos(d) = size(M,d);
        
        if numel(M)>16 && isidentical( M , ...
                  repmat( M(dots{:}) , unos ) );

          ss = numeric2str( M(dots{:}) );
%           if strncmp( ss , 'repmat(' , 7 )
%             sz = unos;
% 
%             [ssz,id] = regexp(ss,',(\[.*\])\)$' ,'tokens' , 'start' );
%             ssz = eval( ssz{1}{1} );
% 
%             ssz(end+1:max(numel(sz),numel(ssz))) = 1;
%             sz(end+1:max(numel(sz),numel(ssz))) = 1;
%             sz = ssz.*sz;
% 
%             S = [ ss(1:id+1)  nolast( sprintf('%d,',sz) )  ss(end-1:end) ] ;
% 
%           else
            
            S = [ 'repmat('  ss ',[' nolast(sprintf('%d,',unos)) '])'  ];

%           end
          return;
        end
        dots{d} = ':';
        unos(d) = 1;
      end
      
      S = [ 'reshape(' numeric2str(M(:,:)) ',' sizestr(M) ')' ];
      return;
    end

    if isequal( eye(size(M)) , M )
      if size(M,1) == size(M,2)
        S = sprintf('eye(%d)', size(M,1) );
      else
        S = sprintf('eye(%d,%d)', size(M,1) , size(M,2) );
      end
      return;
    end

    if size(M,1) == size(M,2) &&  isidentical( diag(diag(M)) , M )
      if all( diag(M) == M(1) )  && isidentical( M , eye(size(M,1),class(M))* M(1) )
        S = [ numeric2str(M(1)) '*eye(' numeric2str(size(M,1)) ')' ];
        return;
      end
        
      S = [ 'diag(' numeric2str( diag(M).' ) ')' ];
      return;
    end
    
    if size(M,1)>1  &&  isidentical( repmat(M(1,:),size(M,1),1) , M )
      sz = [size(M,1) 1];

      ss = numeric2str(M(1,:));
      if strncmp( ss , 'repmat(' , 7 )
        [ssz,id] = regexp(ss,',(\[.*\])\)$' ,'tokens' , 'start' );
        ssz = eval( ssz{1}{1} );
        
        ssz(end+1:max(numel(sz),numel(ssz))) = 1;
         sz(end+1:max(numel(sz),numel(ssz))) = 1;
        sz = ssz.*sz;
        
        S = [ ss(1:id+1)  nolast( sprintf('%d,',sz) )  ss(end-1:end) ] ;
      else
        S = [ 'repmat(' ss sprintf(',[%d,%d])',sz) ];
      end
      return;
    end

    if size(M,2) > 1  &&  isidentical( repmat(M(:,1),1,size(M,2)) , M )
      sz = [1 size(M,2)];

      ss = numeric2str(M(:,1));
      if strncmp( ss , 'repmat(' , 7 )
        [ssz,id] = regexp(ss,',(\[.*\])\)$' ,'tokens' , 'start' );
        ssz = eval( ssz{1}{1} );
        
        ssz(end+1:max(numel(sz),numel(ssz))) = 1;
         sz(end+1:max(numel(sz),numel(ssz))) = 1;
        sz = ssz.*sz;
        
        S = [ ss(1:id+1)  nolast( sprintf('%d,',sz) )  ss(end-1:end) ] ;
      else
        S = [ 'repmat(' ss sprintf(',[%d,%d])',sz) ];
      end
      return;
    end


    if  isnan(M(1))  ||  any( M(1) == M(2:end) )
      if size(M,1) == 1
        for r = setdiff( find( ~mod( numel(M) , 2:(numel(M)/2+1) ) )+1 , numel(M) )
          r = numel(M)/r; if isempty(r), r = 1; end
          try, if isidentical( repmat(M(1:r),1,r) , M )
            S = [ 'repmat(' numeric2str( M(1:r) ) sprintf(',[1,%d])',r) ];
            return;
            end; end
        end
      end

      if size(M,2) == 1
        for r = setdiff( find( ~mod( numel(M) , 2:(numel(M)/2+1) ) )+1 , numel(M) )
          try
          if isidentical( repmat(M(1:r),numel(M)/r,1) , M )
            S = [ 'repmat(' numeric2str( M(1:r) ) sprintf(',[%d,1])',numel(M)/r) ];
            return;
          end
          end
        end
      end
    end

    
    S = '[';
    for i=1:size(M,1)
      S = [ S  row2str(M(i,:)) ';' ];
    end
    S = [ S(1:end-1) ']' ];

%     S = [ '[' nolast( cell2mat( arrayfun( @(r) [ row2str(M(r,:)) ';' ] , 1:size(M,1) , 'UniformOutput' , false ) ) ) ']' ];
    
  end


  function S = row2str( M )
    if numel(M) == 1
      S = number2str( M ,LEVEL);
      return;
    end
    
    if all( M == M(1) )
      if isnumeric(M) && M(1) == 1  &&  isidentical( M , ones(1,numel(M),class(M)) )
        S = ['ones(1,' number2str(numel(M),3) ')' ];
        %S = sprintf('%d,',M);S(end)=[];
        return;
      end
      if M(1) == -1  &&  isidentical( M , -ones(1,numel(M),class(M)) )
        S = ['-ones(1,' number2str(numel(M),3) ')' ];
        return;
      end
      if isnumeric(M) && M(1) == 0  &&  isidentical( M , zeros(1,numel(M),class(M)) )
        S = ['zeros(1,' number2str(numel(M),3) ')' ];
        %S = sprintf('%d,',M);S(end)=[];
        return;
      end
      if islogical(M) &&  ~M(1)  &&  isidentical( M , false(1,numel(M)) )
        S = ['false(1,' number2str(numel(M),3) ')' ];
        return;
      end
      if islogical(M) &&  M(1)  &&  isidentical( M , true(1,numel(M)) )
        S = ['true(1,' number2str(numel(M),3) ')' ];
        return;
      end
      if isidentical( M , ones(1,numel(M),class(M))*M(1) )
        S = [ number2str(M(1),LEVEL) '*ones(1,' number2str(numel(M),3) ')' ];
        return;
      end
    end

    try
    if  all( imag(M) == 0 )  && numel(M) > 2  &&  abs( M(end)-M(1) - numel(M) ) < 3  &&  isidentical( M , M(1):M(end) )
%     if numel(M) > 4  &&  all( diff(M) == 1 )
      S = [ number2str(M(1),LEVEL) ':' number2str(M(end),LEVEL) ];
      return;
    end
    end

%     if numel(M) > 4  &&  ~any( diff( M , 2 , 2 ) )
%       S = [ number2str(M(1),LEVEL) ':' number2str(M(2)-M(1),LEVEL) ':' number2str(M(end),LEVEL) ];
%       return;
%     end
    
%     if numel(M) > 4 && isequal( M , double(M(1)):double(mean(diff(M))):double(M(end)) )
    try
    if ~islogical(M) && isreal(M) && numel(M) > 4  &&  abs( ( double(M(end))-double(M(1)) )/mean(diff(double(M))) - numel(M) ) < 3  &&  isidentical( M , M(1):mean(diff(double(M))):M(end) )
      S = [ number2str(M(1),LEVEL) ':' number2str(mean(diff(double(M))),LEVEL) ':' number2str(M(end),LEVEL) ];
      return;
    end
    end
    
%     S = '';
%     for j = 1:numel(M)
%       S = [ S number2str(M(j),LEVEL) ',' ];
%     end
%     S = S(1:end-1);
    
%     S = nolast( cell2mat( arrayfun( @(x) [ number2str(x,LEVEL) ',' ] , M , 'UniformOutput',false ) ) );
    
    S = ''; id = 1;
    while id <= numel( M )
      if numel(M) - id > 6
        d = diff( double( M(id:end) ) );
        
%         d(end+1) = typecast( bitxor( typecast( d(end) , 'uint8') , uint8(1) ) , class(d(end)) );
        
        jumpid = find( [ d ~= d(1) , 1 ] , 1 );
        if jumpid > 5
          S = [  S  ','  row2str( M( ( id-1 ) + ( 1:jumpid ) ) ) ];
          id = id + jumpid;
          continue;
        end
      end
      
      S = [ S ',' number2str( M(id) ,LEVEL) ];
      id = id+1;
    end
    if S(1) == ',', S(1) = []; end
    
  end

  function ise = isequal( a , b )
    ise = false;
    try
      ise = isidentical( a , b );
    end
  end


end

