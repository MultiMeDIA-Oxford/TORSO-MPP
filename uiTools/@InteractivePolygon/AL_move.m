function AL_move( IP )
  hFig = ancestortool( IP.handle , 'figure' );
  hAxe = ancestortool( IP.handle , 'axes'   );

  pointerlocation = getappdata( hFig, 'IP_pointerlocation');
  if ~isempty( pointerlocation )
    set(0,'PointerLocation',pointerlocation); 
    setappdata( hFig, 'IP_pointerlocation', [] );
  end

  startInteraction( IP  );

  startpoint = mean( get( hAxe,'CurrentPoint'),1 );

  set( hFig , 'WindowButtonMotionFcn', @(h,e) move_(IP) );
  function move_(IP)
    cp = mean( get( hAxe,'CurrentPoint'),1 );

    vertices = getVertices(IP);
    vertices(:,1)= vertices(:,1) + cp(1)-startpoint(1);
    vertices(:,2)= vertices(:,2) + cp(2)-startpoint(2);
    vertices(:,3)= vertices(:,3) + cp(3)-startpoint(3);

    startpoint = cp;
    setVertices( IP , vertices , 'update');
  end
end
