function AV_scale(IP,vertice)

  hFig = ancestortool( IP.handle , 'figure' );

  pointerlocation = getappdata( hFig, 'IP_pointerlocation');
  if ~isempty( pointerlocation )
    set(0,'PointerLocation',pointerlocation); 
    setappdata( hFig, 'IP_pointerlocation', [] );
  end
  
  vertices = getVertices(IP);
  center   = [get(vertice,'XData') get(vertice,'YData') get(vertice,'ZData')];

  startInteraction( IP , vertice );

  startpoint = get( hFig , 'CurrentPoint' );
  set( hFig , 'WindowButtonMotionFcn', @(h,e) scale_(IP,startpoint,vertices) );
  function scale_(IP,startpoint,vertices)
    cp = get(hFig,'CurrentPoint');
    s = exp( (cp(2)-startpoint(2))/70 );
    H = maketransform( 'center', center , 's',s );
    vertices = transform(vertices,H);
    setVertices(IP,vertices,'update');
  end

end
