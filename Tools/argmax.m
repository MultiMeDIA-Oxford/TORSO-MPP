function i = argmax( x )

  try,
    [~,i]= max( x(:) );
  catch
    [ignore,i] = max( x(:) );
  end

end
