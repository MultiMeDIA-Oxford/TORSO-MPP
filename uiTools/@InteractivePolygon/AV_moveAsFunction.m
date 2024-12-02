function AV_moveAsFunction(IP,vertice)

  hFig = ancestortool( IP.handle , 'figure' );
  hAxe = ancestortool( IP.handle , 'axes'   );

  pointerlocation = getappdata( hFig, 'IP_pointerlocation');
  if ~isempty( pointerlocation )
    set(0,'PointerLocation',pointerlocation); 
    setappdata( hFig, 'IP_pointerlocation', [] );
  end
  
  startInteraction( IP , vertice );

  id = closestVertice(IP,vertice);
  vs = getVertices(IP);
  N  = size(vs,1);

  set( hFig , 'WindowButtonMotionFcn', @(h,e) move_(IP,vertice) );
  function move_(IP,vertice)
    cp         = mean( get( hAxe ,'CurrentPoint'),1 );
    coordinate = cp;
    
    if id > 1, coordinate(1) = max( vs(id-1,1)+eps(vs(id-1,1))*10 , coordinate(1) ); end
    if id < N, coordinate(1) = min( vs(id+1,1)-eps(vs(id+1,1))*10 , coordinate(1) ); end

    IPdata= getappdata( IP.handle , 'InteractivePolygon' );
    try, 
      coordinate= IPdata.constrain( coordinate , IP , closestVertice(IP,vertice) ); 
    end

    set( vertice , 'XData', coordinate(1) , 'YData', coordinate(2) , 'ZData', coordinate(3) );
    xyz= getCurve( IP );
    set( IPdata.line , 'XData',xyz(:,1),'YData',xyz(:,2),'ZData',xyz(:,3) );
    updateArrows( IP , IPdata );
    feval( IPdata.fcn , IP );
  end
end
