function AV_deform(IP,vertice)
  hFig = ancestortool( IP.handle , 'figure' );
  hAxe = ancestortool( IP.handle , 'axes'   );

  pointerlocation = getappdata( hFig, 'IP_pointerlocation');
  if ~isempty( pointerlocation )
    set(0,'PointerLocation',pointerlocation); 
    setappdata( hFig, 'IP_pointerlocation', [] );
  end
  
  startInteraction( IP , vertice );
  IPdata= getappdata(IP.handle,'InteractivePolygon');

  startpoint = [get(vertice,'XData') get(vertice,'YData') get(vertice,'ZData')];
  set( hFig , 'WindowButtonMotionFcn', @(h,e) deform_( IP , closestVertice(IP,vertice) , IPdata.close) );

  function deform_(IP,id,isclose)
    cp = mean( get( hAxe,'CurrentPoint'),1 );
    DX = cp(1)-startpoint(1);
    DY = cp(2)-startpoint(2);
    DZ = cp(3)-startpoint(3);
    startpoint = cp;

    vertices = getVertices(IP);
    N  = size( vertices , 1 );
    minid= ceil(-N/4);
    maxid= floor(N/4);
    for i= minid:maxid
      vid = id+i;
      if vid <= 0 
        if ~isclose,   continue;  end
        vid = vid+N;
      end
      if vid > N 
        if ~isclose,   continue;  end
        vid= vid-N;
      end
%         exp( -(10*i/N)^2 )
      vertices(vid,:)= vertices(vid,:) + [DX DY DZ]*exp( -(10*i/N)^2 );
%         vertices(vid,:)= vertices(vid,:) + [DX DY DZ]*( 1-4/N*abs(i) ).^2;
    end
    setVertices( IP , vertices , 'update' );
  end
end
