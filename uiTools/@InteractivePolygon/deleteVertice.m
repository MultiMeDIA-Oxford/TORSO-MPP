function deleteVertice( IP , id , minnum )

  if nargin<3, minnum=2; end
  
  if length(IP) <= minnum, return; end

  IPdata = getappdata(IP.handle,'InteractivePolygon');
  if ishandle(id)
    id = find( IPdata.vertices == id );
  end

  vertices= getVertices( IP );
  vertices(id,:)= [];
  
  if size(vertices,1) < 3
    IPdata.close = 0;
    setappdata( IP.handle , 'InteractivePolygon', IPdata );
  end
  if size(vertices,1) > 1
    setVertices(IP,vertices,'update');
  end
end
