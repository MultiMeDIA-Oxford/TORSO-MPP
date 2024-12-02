function ACTIONSonVERTICES( IP , vertice )

  IPdata= getappdata( IP.handle , 'InteractivePolygon' );
  hFig = ancestor( vertice , 'figure' );

  cmenu = uicontextmenu( 'callback',@(h,e) setappdata( hFig, 'IP_pointerlocation',get(0,'PointerLocation')) );
  for ac = 1:numel( IPdata.AV )
    label = IPdata.AV(ac).menu;
    if ~isempty(label)
      FCN   = IPdata.AV(ac).FCN;
      if label(1) == '_'
        uimenu(cmenu, 'Label',label(2:end),'Callback',@(h,e) FCN(IP,vertice),'separator','on' );
      else
        uimenu(cmenu, 'Label',label       ,'Callback',@(h,e) FCN(IP,vertice) );
      end
    end
  end
  set( vertice , 'UIContextMenu', cmenu , 'ButtonDownFcn', @(h,e) CallAction( IP , vertice ) );

  function CallAction( IP , v )
%     cmenu_ = get( vertice , 'UIContextMenu' );
%     if ~isempty( cmenu_ ), cmenu = cmenu_; end
%     set( vertice , 'UIContextMenu', [] );
    buttons = pressedkeys(4);
    if strcmp(get(hFig,'SelectionType'),'open')
      buttons= buttons*10;
    end
    keys    = pressedkeys;
    for b=1:3
      if buttons(b) == 1
        keys = [ keys  sprintf('BUTTON%d',  b  ) ];
      elseif buttons(b) == 10
        keys = [ keys  sprintf('BUTTON%d', b*10) ];
      end
    end
    keys = unique( keys );

    for i= numel(IPdata.AV):-1:1
      action = unique( IPdata.AV(i).action );
      if isequal( keys , action )
        setappdata( hFig, 'IP_pointerlocation', [] );
        feval( IPdata.AV(i).FCN , IP , v );
        break;
      end
    end
%       set( vertice , 'UIContextMenu', cmenu );
  end

end
