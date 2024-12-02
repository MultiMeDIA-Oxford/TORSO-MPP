function x = noninfs( x , v )

  remove = isinf(x)  &  x < 0;

  if nargin == 1

    x = x( ~remove );

  else
    
    x( remove ) = v;
    
  end
    
end
