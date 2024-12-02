function vertices= getVertices( IP )

  IPdata= getappdata( IP.handle , 'InteractivePolygon' );
  
  n= numel( IPdata.vertices );
  vertices= zeros(n,3);
  for i=1:n
    v = IPdata.vertices(i);
    vertices(i,:)= [ get( v , 'XData' ) ...
                     get( v , 'YData' ) ...
                     get( v , 'ZData' ) ];
  end
  
end
