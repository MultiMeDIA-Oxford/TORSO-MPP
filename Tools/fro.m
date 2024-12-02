function n = fro( x , dim )

  if nargin < 2

    n = sqrt( x(:).'*x(:) );

  else
    
    n = sqrt( sum( x.^2 , dim ) );
  
  end

end
