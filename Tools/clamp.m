function x = clamp( x , lower , upper , values )

  if nargin < 4
    values = [ lower upper ];
  end

  nonan = ~isnan(x);
  x( x < lower & (nonan) ) = values( 1 );
  x( x > upper & (nonan) ) = values(end);
  
  
end