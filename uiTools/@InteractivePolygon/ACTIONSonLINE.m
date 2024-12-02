function ACTIONSonLINE( IP )

  hFig = ancestor( IP.handle , 'figure' );
  IPdata = getappdata( IP.handle , 'InteractivePolygon' );

  cmenu = uicontextmenu( 'callback',@(h,e) setappdata( hFig, 'IP_pointerlocation',get(0,'PointerLocation')) );
  for ac = 1:numel( IPdata.AL )
    label = IPdata.AL(ac).menu;
    if ~isempty(label)
      FCN   = IPdata.AL(ac).FCN;
      if label(1) == '_'
        uimenu(cmenu, 'Label',label(2:end),'Callback',@(h,e,varargin) FCN(IP,varargin{:}),'separator','on' );
      else
        uimenu(cmenu, 'Label',label       ,'Callback',@(h,e,varargin) FCN(IP,varargin{:}) );
      end
    end
  end
  set( IPdata.line , 'UIContextMenu', cmenu , 'ButtonDownFcn', @(h,e,varargin) CallAction(varargin{:}) );
  
  function CallAction(varargin)
%     cmenu_ = get( IPdata.line , 'UIContextMenu' );
%     if ~isempty( cmenu_ ), cmenu = cmenu_; end
%     set( IPdata.line , 'UIContextMenu', [] );
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

    for i= numel(IPdata.AL):-1:1
      action = unique( IPdata.AL(i).action );
      if isequal( keys , action )
        setappdata( hFig, 'IP_pointerlocation', [] );
        feval( IPdata.AL(i).FCN , IP , varargin{:} );
        break;
      end
    end
%       set( IPdata.line , 'UIContextMenu', cmenu );
  end
  
end
