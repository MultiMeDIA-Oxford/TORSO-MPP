function sz = size( I , dim )

  sz = [  numel(I.X)  numel(I.Y)  numel(I.Z)  numel(I.T)  ];
  
  if isempty( I.data )
    sz(5) = 0;
  else
    sz(5) = size( I.data , 5 );
    d = 6;
    while d <= ndims( I.data )
      sz(d) = size( I.data , d );
      d = d+1;
    end
  end
  
 
  if nargin > 1
    sz( (numel(sz)+1):max(dim) ) = 1;
    sz= sz(dim);
  end
  
  
end
