function o = alleq( x , dims )
  
  if nargin < 2 

    o = all( eq( x(:) , x(1) ) );
  
  else

    dots = repmat( {':'} , 1 , ndims(x) );
    [dots{dims}] = deal(1);
    o = bsxfun( @eq , x , x(dots{:}) );
    
    for d = dims(:).'
      o = all( o , d );
    end
    o = all( o(:) );
    
  end
  
end
