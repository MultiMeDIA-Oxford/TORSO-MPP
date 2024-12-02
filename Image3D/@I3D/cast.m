function [I,e,E] = cast( I , type )

  switch lower(type)
    case 'float'
      switch lower(class(I.data))
        case {'single'}, type = 'single';
        case {'double'}, type = 'double';
        otherwise,       type = 'single';
      end
  end


  if nargout > 1
    E = tofloat( I.data );
  end

  I = DATA_action( I , [ '@(X) cast(X,' , uneval(type) , ')' ] );
  
  if nargout > 1
    E = abs( E - tofloat( I.data ) );
    e = double( max( E(:) ) );
  end
  
  if nargout > 2
    E = cleanout( I.fill( E ) );
  end
  
end
