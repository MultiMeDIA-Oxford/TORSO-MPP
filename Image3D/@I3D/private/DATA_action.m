function I = DATA_action( I , action , do )

  if nargin < 3, do = true; end

  if ischar(action)
    action = regexprep( action ,',\s*,',',');
    action = regexprep( action ,',\s*\)','\)');
    action = regexprep( action ,'\+\s*-','\-');
    action = {action};
  end
  
  if do
    if iscell( action )
      I.data = feval( eval( action{1} ) , I.data );
    else
      I.data = feval( action , I.data );
    end
  end

  if ~isempty( I.POINTER )
    I.POINTER = [ I.POINTER(:) ; { action } ];
  end
  

end
