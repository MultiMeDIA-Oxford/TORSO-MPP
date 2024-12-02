function name = fixname( varargin )
if 0
%%  
disp( fixname( 'c:\test' ) )  
disp( fixname( 'test' ) )  
disp( fixname( '..\test' ) )  
disp( fixname( '..','\test' ) )

%%
end

  while numel(varargin) && isempty( varargin{1} )
    varargin(1) = [];
  end
  if ~numel(varargin), name = ''; return; end
  
  
  name = varargin{1};
  for v = 2:numel(varargin)
    name = [ name , '\' , varargin{v} ];
  end
  
  
  isRel = true;
  sys = computer;
  switch upper(sys)
    case {'PCWIN','PCWIN64'}
      if ~isempty( regexp( name , '^[a-zA-Z]\:(?:\\|/|$)' ) ) ||...
         ~isempty( regexp( name , '^\\\\\' ) )
        isRel = false;
      end
    case {'SOL2','HPUX','GLNX86','GLNXA64','MAC'}
      if ~isempty( regexp( varargin{1} , '^(?:\\|/|\~)' ) )
        isRel = false;
      end
  end
  
  if isRel, name = [ pwd , '\' , name ]; end
    
  
  pre_name = '';
  switch upper(sys)
    case {'PCWIN','PCWIN64'}
      name( ismembc( name , '/' ) ) = '\';

      pattern = regexp( name , '^(?<pre>[a-zA-Z]\:\\+)(?<name>.*)$' , 'names' , 'once' );
      if ~isempty( pattern )
        name     = pattern.name;
        pre_name = [ upper( pattern.pre(1) ) , ':\' ];
      end
      
      pattern = regexp( name , '^(?<pre>\\\\+))(?<name>.*)$' , 'names' , 'once' );
      if ~isempty( pattern )
        name     = pattern.name;
        pre_name = '\\';
      end
      
      name( ismembc( name , '"*:<>?|' ) ) = [];
      name = regexprep( name , '\\\\+' , '\\' );
  end
  name = [ pre_name , name ];
  
  
  try, name = applyUserRules( name ); end
  
  name = builtin( 'strrep' , name , '\' , '\' );
  name = builtin( 'strrep' , name , '/' , '\' );
  name = regexprep( name , '\\\.\\' , '\\' );
  name = regexprep( name , '[^\\]+\\\.\.\\' , '' );
  name = builtin( 'strrep' , name , '\' , filesep );
  name = builtin( 'strrep' , name , '/' , filesep );

  try, name = applyUserRules( name ); end


  name = fixCase( name );
  
  
  function n = applyUserRules( n )
    R = getoption( 'fixname' );
    FN = fieldnames(R);
    for f = 1:numel(FN)
      i = regexp( FN{f} , '^in(\d+)$' , 'tokens' , 'once' );
      if isempty(i), continue; end
      
      n = builtin( 'strrep' , n , R.(FN{f}) , R.(['out',i{1}]) );
    end
  end
  function n = fixCase( n )
    splits = unique( [ find( n == filesep ) , numel(n) ] );
    for i = 1:numel(splits)-1
      s1 = splits(i);
      s2 = splits(i+1);
      if n(s2) == filesep, s2 = s2-1; end

      d = dir( n(1:s1) ); d = { d.name };
      
      found = find( strcmpi( d , n(s1+1:s2) ) );
      if numel( found ) == 1
        n(s1+1:s2) = d{ found };
      else
        break;
      end
    end
  end

end
