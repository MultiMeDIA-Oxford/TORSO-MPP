function setoption( G , K , V )
%SETOPTION Set options.
%   SETOPTION('GROUP','KEY',VAL) sets the option specified by GROUP
%   and KEY to the value VAL. Setting a option that does not yet
%   exist causes it to be created.
%
%   GROUP labels a related collection of options.  You can choose
%   any name that is a legal variable name, and is descriptive enough
%   to be unique, e.g. 'myApp_version1_0_ApplicationPrefs'.
%
%   KEY identifies an individual option in that group, and
%   must be a legal variable name.
%
%   SETOPTION('GROUP',{'KEY1','KEY2',...'KEYn'},{VAL1,VAL2,...VALn})
%   sets each option specified in the cell array of names to the
%   corresponding value.
%

  optsFile = [ prefdir(1) , filesep , 'userOPTIONS.ini' ];
  if nargin < 1
    try, edit( optsFile ); end
    return;
  end


  if nargin < 3
    error('''group'',''key'',value were expected.');
  end
  try,   struct( G , 1 );
  catch, error('invalid GROUP name.');
  end
  if iscell( K )
    if ~iscell( V ) || numel( K ) ~= numel( V )
      error('KEYs cell do not agree with values');
    end
  else
    K = {K};
    V = {V};
  end
  

  for k = 1:numel(K)
    write_INI( optsFile , G , K{k} , V{k} );
  end

end
