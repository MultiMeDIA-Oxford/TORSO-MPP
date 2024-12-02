function AL_move_segment( IP )
  hFig = ancestortool( IP.handle , 'figure' );
  hAxe = ancestortool( IP.handle , 'axes'   );

  pointerlocation = getappdata( hFig, 'IP_pointerlocation');
  if ~isempty( pointerlocation )
    set(0,'PointerLocation',pointerlocation); 
    setappdata( hFig, 'IP_pointerlocation', [] );
  end


  IPdata= getappdata( IP.handle , 'InteractivePolygon');

  startpoint = mean( get( hAxe,'CurrentPoint'),1 );
  [aux,id]= nearestpoint( IP , startpoint );

  startInteraction( IP  );

  set( hFig , 'WindowButtonMotionFcn', @(h,e) move_segment(IP) );
  function move_segment(IP)
    vertices = getVertices(IP);
    cp = mean( get( hAxe,'CurrentPoint'),1 );
    if ~IPdata.close || id ~= size(vertices,1)
      vertices([id id+1],1)= vertices([id id+1],1) + cp(1)-startpoint(1);
      vertices([id id+1],2)= vertices([id id+1],2) + cp(2)-startpoint(2);
      vertices([id id+1],3)= vertices([id id+1],3) + cp(3)-startpoint(3);
    else
      vertices([id 1],1)= vertices([id 1],1) + cp(1)-startpoint(1);
      vertices([id 1],2)= vertices([id 1],2) + cp(2)-startpoint(2);
      vertices([id 1],3)= vertices([id 1],3) + cp(3)-startpoint(3);
    end
    startpoint = cp;
    setVertices( IP , vertices , 'update');
  end

end
