function i = argmin( x )

  try,
    [~,i]= min( x(:) );
  catch
    [ignore,i] = min( x(:) );
  end

end
