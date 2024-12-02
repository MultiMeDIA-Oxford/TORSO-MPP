function [str,ymwdhms] = seconds2str( seconds )

  secs = abs( seconds );
  
  ymwdhms(1) = floor( secs / ( 365*24*60*60 ) );  secs = secs - ymwdhms(1)*365*24*60*60;
  ymwdhms(2) = floor( secs / (  30*24*60*60 ) );  secs = secs - ymwdhms(2)* 30*24*60*60;
  ymwdhms(3) = floor( secs / (   7*24*60*60 ) );  secs = secs - ymwdhms(3)*  7*24*60*60;
  ymwdhms(4) = floor( secs / (     24*60*60 ) );  secs = secs - ymwdhms(4)*    24*60*60;
  ymwdhms(5) = floor( secs / (        60*60 ) );  secs = secs - ymwdhms(5)*       60*60;
  ymwdhms(6) = floor( secs / (           60 ) );  secs = secs - ymwdhms(6)*          60;
  ymwdhms(7) = secs;
  

  str = [];
  
  if      ymwdhms(1) > 1
    str = sprintf('%s%d years',str,ymwdhms(1));
  elseif  ymwdhms(1) == 1
    str = sprintf('%s1 year',str);
  end
  
  if      ymwdhms(2) > 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s%d months',str,ymwdhms(2));
  elseif  ymwdhms(2) == 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s1 month',str);
  end
  
  if      ymwdhms(3) > 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s%d weeks',str,ymwdhms(3));
  elseif  ymwdhms(3) == 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s1 week',str);
  end
  
  if      ymwdhms(4) > 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s%d days',str,ymwdhms(4));
  elseif  ymwdhms(4) == 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s1 day',str);
  end
  
  if      ymwdhms(5) > 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s%d hours',str,ymwdhms(5));
  elseif  ymwdhms(5) == 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s1 hour',str);
  end
  
  if      ymwdhms(6) > 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s%d minutes',str,ymwdhms(6));
  elseif  ymwdhms(6) == 1
    if ~isempty( str ), str = [ str ', ']; end
    str = sprintf('%s1 minute',str);
  end

  if      ymwdhms(7) ~= 1
    if ~isempty( str ), str = [ str ' and ']; end
    str = sprintf('%s%f seconds',str,ymwdhms(7));
    %str = sprintf('%s%s seconds',str,uneval(ymwdhms(7)));
  elseif  ymwdhms(7) == 1
    if ~isempty( str ), str = [ str ' and ']; end
    str = sprintf('%s1 second',str);
  end

  if seconds < 0
    str = [ 'minus '  str ];
  end
  
end
