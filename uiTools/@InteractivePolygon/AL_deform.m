function AL_deform( IP )
  hFig = ancestortool( IP.handle , 'figure' );
  hAxe = ancestortool( IP.handle , 'axes'   );

  pointerlocation = getappdata( hFig, 'IP_pointerlocation');
  if ~isempty( pointerlocation )
    set(0,'PointerLocation',pointerlocation); 
    setappdata( hFig, 'IP_pointerlocation', [] );
  end


  IPdata= getappdata( IP.handle , 'InteractivePolygon');
  if IPdata.spline
    startpoint = mean( get(hAxe,'CurrentPoint'),1 );
    insertVertice( IP , startpoint );
    id = closestVertice(IP,startpoint);

    AV_deform( IP , IPdata.vertices(id) );
  else
    AL_move_segment( IP );
  end

end
