function [id,d] = closestVertice(IP,P)

  if numel(P)==1 && ishandle( P ) 
    IPdata= getappdata( IP.handle , 'InteractivePolygon' );
    id = find( IPdata.vertices == P );
    d = 0;
  else
    v = getVertices(IP);
    d = sum( [v(:,1)-P(1) v(:,2)-P(2) v(:,3)-P(3)].^2 , 2 );
    [d,id]= min(d);
    d= sqrt(d);
  end  
end
