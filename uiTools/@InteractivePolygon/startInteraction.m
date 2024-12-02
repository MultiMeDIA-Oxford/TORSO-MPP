function startInteraction( IP , vertice )
  hAxe = ancestortool( IP.handle , 'axes'   );
  hFig = ancestortool( IP.handle , 'figure' );
  
  setappdata( hFig, 'IP_pointerlocation' , [] );

  IPdata = getappdata( IP.handle , 'InteractivePolygon' );
  set( IPdata.vertices , 'Visible', 'off');
  try, set( vertice , 'Visible', 'On' ); end
  oldUP       = get( hFig , 'WindowButtonUpFcn' );
  oldDown     = get( hFig , 'WindowButtonDownFcn' );
  oldMOTION   = get( hFig , 'WindowButtonMotionFcn' );
  oldXLimMode = get( hAxe , 'XLimMode' );    
  oldYLimMode = get( hAxe , 'YLimMode' );    
  oldZLimMode = get( hAxe , 'ZLimMode' );
  set( hFig , 'WindowButtonUpFcn'     , @(h,e) setOLDS );
  set( hFig , 'WindowButtonDownFcn'   , @(h,e) setOLDS );
  set( hAxe , 'XlimMode'              , 'Manual'       );
  set( hAxe , 'YlimMode'              , 'Manual'       );
  set( hAxe , 'ZlimMode'              , 'Manual'       );
  function setOLDS
    set( hFig , 'WindowButtonMotionFcn' , oldMOTION  );
    set( hFig , 'WindowButtonUpFcn'     , oldUP      );
    set( hFig , 'WindowButtonDownFcn'   , oldDown    );
    set( hAxe , 'XlimMode'              , oldXLimMode);
    set( hAxe , 'YlimMode'              , oldYLimMode);
    set( hAxe , 'ZlimMode'              , oldZLimMode);
    set( IPdata.vertices , 'Visible', 'on');
  end

end
