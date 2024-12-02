function [I,s,t] = rescaleimage( I , range , clase )

  if nargin == 1
    clase = class( I.data );
    range = [0 1];
  end
  
  if nargin == 2
    if ischar( range )
      clase = lower( range );
      switch clase
        case 'int8',    range = [ intmin(clase)  intmax(clase) ];
        case 'uint8',   range = [ intmin(clase)  intmax(clase) ];
        case 'int16',   range = [ intmin(clase)  intmax(clase) ];
        case '+int16',  clase = 'int16'; range = [ 0              intmax(clase) ];
        case 'uint16',  range = [ intmin(clase)  intmax(clase) ];
        case 'int32',   range = [ intmin(clase)  intmax(clase) ];
        case 'uint32',  range = [ intmin(clase)  intmax(clase) ];
        otherwise,      range = [0 1];
      end
    else
      clase = class( I.data );
    end
  end
  
  
  if ~isempty( range )

    range  = double( range );

    minimum = double( min( I.data( isfinite( I.data(:) )) ) );
    maximum = double( max( I.data( isfinite( I.data(:) )) ) );
    
    s = ( range(2) - range(1) )/( maximum - minimum );
    t = range(1) - minimum * s;
    
    %I.data = cast( tofloat( I.data ) * s + t , clase );
    
    I = DATA_action( I , [ '@(X) cast( tofloat(X)*' uneval(s) '+' uneval(t) ',' uneval(clase) ')' ] );
    
  else    

    %I.data = cast( I.data , clase );
    I = DATA_action( I , [ '@(X) cast(X,' uneval(clase) ,')' ] );

  end


%  switch lower( clase )
%    case 'uint32', I.data = uint32( I.data );
%    case  'int32', I.data =  int32( I.data );
%    case 'uint16', I.data = uint16( I.data );
%    case  'int16', I.data =  int16( I.data );
%    case 'uint8',  I.data = uint8(  I.data );
%    case  'int8',  I.data =  int8(  I.data );
%    case 'double', I.data = double( I.data );
%    case 'single', I.data = single( I.data );
%    otherwise, error('incorrect class');
%  end
    
end
