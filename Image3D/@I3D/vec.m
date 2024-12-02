function x = vec( x , dim )

  if nargin < 2 , dim = 1; end
  
  if isempty(dim)
    x = x.data;
  else
    x = vec( x.data , dim );
  end

end
