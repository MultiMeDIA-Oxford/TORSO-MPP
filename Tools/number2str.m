function S = number2str(x,level)

  if ~isscalar( x )      , error( 'only a double real scalar number accepted.' ); end

  if nargin < 2 , level = 2; end
  if level > 100, level = 99; end
  
  
  switch class( x )
    case 'double'
      if imag(x) ~= 0  &&  real(x) ~= 0
        S = [ double2str( real(x) , level ) '+(1i*' double2str( imag(x) , level ) ')' ];
        S = strrep( S , '+(1i*-','-(1i*');
      elseif imag(x) ~= 0  &&  real(x) == 0
        S = [ '+(1i*' double2str( imag(x) , level ) ')' ];
        S = strrep( S , '+(1i*-','-(1i*');
      else
        S = double2str( x , level );
      end
      
      
    case 'single'
      if imag(x) ~= 0  &&  real(x) ~= 0
        S = [ single2str( real(x) , level ) '+(1i*' single2str( imag(x) , level ) ')' ];
        S = strrep( S , '+(1i*-','-(1i*');
      elseif imag(x) ~= 0  &&  real(x) == 0
        S = [ '+(1i*' single2str( imag(x) , level ) ')' ];
        S = strrep( S , '+(1i*-','-(1i*');
      else
        S = single2str( x , level );
      end
      
    case {'int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
      level = min( level , 2 );
      x = double(x);
      if imag(x) ~= 0  &&  real(x) ~= 0
        S = [ double2str( real(x) , level ) '+(1i*' double2str( imag(x) , level ) ')' ];
        S = strrep( S , '+(1i*-','-(1i*');
      elseif imag(x) ~= 0  &&  real(x) == 0
        S = [ '+(1i*' double2str( imag(x) , level ) ')' ];
        S = strrep( S , '+(1i*-','-(1i*');
      else
        S = double2str( x , level );
      end
      
    case {'logical'}
      if x
        S = '1';
      else
        S = '0';
      end

  end
  
  
end
