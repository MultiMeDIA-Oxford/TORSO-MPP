function x = tofloat( x , type )

  if nargin < 2

    type = 'double';

  else
  
    if ~any( strcmpi( type , {'single','double'} ) )
      error('only  type  ''double'' or ''single'' allowed');
    end

  end
  
  if ~isfloat( x )
    try
      x = cast( x , type );
    catch
      x = single( x );
    end
  end
  
end

