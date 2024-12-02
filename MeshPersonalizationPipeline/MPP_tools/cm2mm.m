function X = cm2mm( X )

  if isnumeric( X )
    X = X * 10;
  elseif isstruct( X )
    if isfield( X , 'xyz' )
      X.xyz = X.xyz * 10;
    end
  else
    error('Unknown input type.');
  end

end