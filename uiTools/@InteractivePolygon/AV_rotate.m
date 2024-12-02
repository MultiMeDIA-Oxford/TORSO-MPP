function AV_rotate(IP,vertice)
  hFig = ancestortool( IP.handle , 'figure' );
  hAxe = ancestortool( IP.handle , 'axes'   );

  pointerlocation = getappdata( hFig, 'IP_pointerlocation');
  if ~isempty( pointerlocation )
    set(0,'PointerLocation',pointerlocation); 
    setappdata( hFig, 'IP_pointerlocation', [] );
  end
  
  vertices = getVertices(IP);
  center   = [get(vertice,'XData') get(vertice,'YData') get(vertice,'ZData')];

  startInteraction( IP , vertice );

  startpoint = get( hFig , 'CurrentPoint' );
  N = get(hAxe,'CameraPosition') - get(hAxe,'CameraTarget');

  set( hFig , 'WindowButtonMotionFcn', @(h,e) rotate_(IP,startpoint,vertices) );
  function rotate_(IP,startpoint,vertices)
    cp = get(hFig,'CurrentPoint');
    alpha = atan2( cp(2)-startpoint(2) , cp(1)-startpoint(1) ) ;
    if strcmp( get(hAxe,'XDir'),'reverse' ), alpha= -alpha; end
    if strcmp( get(hAxe,'YDir'),'reverse' ), alpha= -alpha; end

    H = maketransform( 'center', center,'radians','raxis',N,alpha );
    vertices = transform(vertices,H);
    setVertices(IP,vertices,'update');
  end
end

