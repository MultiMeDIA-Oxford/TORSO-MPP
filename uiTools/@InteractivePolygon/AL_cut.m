function AL_cut(IP,v)

  hFig = ancestortool( IP.handle , 'figure' );
  hAxe = ancestortool( IP.handle , 'axes'   );

  pointerlocation = getappdata( hFig, 'IP_pointerlocation');
  if ~isempty( pointerlocation )
    set(0,'PointerLocation',pointerlocation); 
    setappdata( hFig, 'IP_pointerlocation', [] );
  end

  if nargin < 2
    [P,id1]= nearestpoint( IP , mean(get( hAxe ,'CurrentPoint'),1) );
  else
    P   = [get(v,'XData') get(v,'YData') get(v,'ZData')];
    id1 = closestVertice(IP,v)-1;
  end

  vertices= getVertices( IP );
  id2 = 0;
  xy  = vertices;
  IPdata= getappdata(IP.handle,'InteractivePolygon');
  isclose = IPdata.close;

  cutline = line( 'Parent', hAxe , 'XData',P(:,1),'YData',P(:,2),'ZData',P(:,3),'Color',[1 0 1],'LineStyle',':','LineWidth',3 );

  startInteraction( IP  );
  wbuf = get( hFig , 'WindowButtonUpFcn' );
  set( hFig , 'WindowButtonUpFcn'  , @(h,e) end_cut(h,e,1) );
  set( hFig , 'WindowButtonDownFcn', @(h,e) end_cut(h,e,0) );
%   set( hFig , 'keyPressFcn'        , @(h,e) end_cut(h,e,0) );
  function end_cut(h,e,do)
    feval( wbuf , h , e );
    delete(cutline);

    if do
      setVertices(IP,xy,'update');
    end      
  end
  

  set( hFig , 'WindowButtonMotionFcn', @(h,e) cut_(IP) );
  function cut_(IP)
    [P(2,:),id2] = nearestpoint( IP , mean( get(hAxe,'CurrentPoint'),1 ) );

    keys = pressedkeys;
    if any( strcmp( keys , 'LSHIFT' ) )
      if id1 <= id2
        xy = [ P(1,:) ; vertices(id1+1:id2,:) ; P(2,:) ];
      else
        xy = [ vertices(1:id2,:) ; P([2 1],:) ; vertices(id1+1:end,:) ];
      end
    else
      if id1 <= id2
        xy = [ vertices(1:id1,:) ; P ; vertices(id2+1:end,:) ];
      else
        xy = [ P(2,:) ; vertices(id2+1:id1,:) ; P(1,:) ];
      end
    end    
    
    if isclose
      set( cutline , 'XData',xy([1:end 1],1),'YData',xy([1:end 1],2),'ZData',xy([1:end 1],3) );
    else
      set( cutline , 'XData',xy(:,1),'YData',xy(:,2),'ZData',xy(:,3) );
    end    
  end  
    

end
