function insertVertice( IP , id , P )

  if nargin < 2
    id = get( ancestortool( IP.handle , 'axes'),'CurrentPoint');
    id = mean(id);
  end

  if nargin < 3
    [P,id]= nearestpoint( IP , id );
  end

  vertices= getVertices( IP );
  vertices= [vertices(1:id,:) ; P ; vertices(id+1:end,:) ];
  setVertices(IP,vertices,'update');

end