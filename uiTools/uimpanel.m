function P = uimpanel( varargin )
if 0
%%  
  close all; figure;
  P = uimpanel( 'visibilitycontrol','on' ,...
                'tag','hola' ,...
                'units','pixel' ,...
                'Position',[20 20 100 100] ,...
                'Rollable','on' ,...
                'Moveable'            , 'on' ,...
                'title','hola' ,...
                'leftresizecontrol','on' ,...
                'rightresizecontrol','on' ,...
                'constrainedtoparent','on' ,...
                'UnDockControl'       , 'off' );
%%  
end

  matlabV = sscanf(version,'%d.%d.%d.%d.%d',5); matlabV=[100,1,1e-2,1e-9,1e-13]*[ matlabV(1:min(5,end)) ; zeros(5-numel(matlabV),1) ];

  [varargin,~,PARENT] = parseargs(varargin,'parent','$DEFS$',[]);
  if ~isempty( PARENT )
    PARENT = { 'Parent' , PARENT };
  else
    PARENT = {};
  end

  [varargin,~,VISIBLE] = parseargs(varargin,'visible','$DEFS$','on');
  
  P =  handle( uipanel( 'Visible' , 'off' , 'BorderType' , 'beveledout' , PARENT{:} ) );
  v = 1; while v < numel( varargin )
    try,   set( P , varargin{v} , varargin{v+1} );
    catch, v = v+2; continue; end
    varargin(v:v+1) = [];
  end

  %%add new Properties
  addProp( P , 'MinimumSize'         , [ 25 18 ] );
  addProp( P , 'Moveable'            , 'on'  );
  addProp( P , 'ConstrainedToParent' , 'on'  );
  addProp( P , 'VisibilityControl'   , 'on'  );
  addProp( P , 'LeftResizeControl'   , 'off' );
  addProp( P , 'RightResizeControl'  , 'on'  );
  addProp( P , 'Rollable'            , 'off' );
  addProp( P , 'UnDockControl'       , 'off' );
  addProp( P , 'TitleBarColor'       , [0 0.50 0.8] );
  addProp( P , 'ShowTitleBar'        , 'on' );
  addProp( P , 'HideRequestFcn'      , '' );

  v = 1; while v < numel( varargin )
    try,   set( P , varargin{v} , varargin{v+1} );
    catch, v = v+2; continue; end
    varargin(v:v+1) = [];
  end
  if numel( varargin )
    set(P,'DeleteFcn',''); delete( P );
    try,   strErr = sprintf('invalid arguments: %s',varargin{1} );
    catch, strErr = sprintf('invalid arguments.' );                 end
    error( strErr );
  end
  
  %new properties to add (they cannot be specified in constructor!)
  nPOS = getPosition( P , 'normalized' ); pxPOS = round( getPosition( P , 'pixel' ) );
  addProp( P , 'Location'       , [  nPOS(1) , nPOS(2)+nPOS(4) ] );
  addProp( P , 'Size'           , [ pxPOS(3) , pxPOS(4)        ] );
  addProp( P , 'Glued'          , false(1,4) ); %left botton right top
  addProp( P , 'IsRolled'       , 'off' );
  addProp( P , 'IsUnDocked'     , 'off' );
  addProp( P , 'InParentDepth'  , 0 );
  
  %once defined, some properties cannot be modified
  np = findprop( P , 'VisibilityControl' );   np.AccessFlags.PublicSet = 'off';
  np = findprop( P , 'LeftResizeControl' );   np.AccessFlags.PublicSet = 'off';
  np = findprop( P , 'RightResizeControl' );  np.AccessFlags.PublicSet = 'off';
  np = findprop( P , 'UnDockControl' );       np.AccessFlags.PublicSet = 'off';
  np = findprop( P , 'Moveable' );            np.AccessFlags.PublicSet = 'off';
  np = findprop( P , 'Rollable' );            np.AccessFlags.PublicSet = 'off';

  %and some others are hide
  np = findprop( P , 'Location' );            np.Visible = 'off';
  np = findprop( P , 'Size' );                np.Visible = 'off';
  np = findprop( P , 'Glued' );               np.Visible = 'off';

  %%"remove" some original Properties (no.. I cannot!!)
  %hideProp( P , 'Position' );

  
  HH.Fig = ancestor( P , 'figure' );
  HH.RolledHeight = 14;  
  HH.TitleBarHeight = 8;  
  HH.GripSize = 6;
  HH.auxHGs = [];
  
  %titlebar
  if true
    title = get( P , 'Title' ); set( P , 'Title','' );
    HH.TitleBar = uicontrol( 'Parent',P,'Style','text','Units','pixel',...
                             'HandleVisibility' , 'off' ,...
                             'Enable' , 'inactive' ,...
                             'HitTest' , 'on' ,...
                             'HorizontalAlignment' , 'left' ,...
                             'FontUnits' , 'pixel' ,...
                             'FontSize' , HH.TitleBarHeight - 0 + 1 ,...
                             'String', [ ' ' , title ] ,...
                             'BackgroundColor' , get(P,'TitleBarColor') ,...
                             'FontName' , 'MS Sans Serif' ,...
                             'FontWeight' , 'bold' ,...
                             'FontAngle' , 'normal' ,...
                             'Tag' , 'uimpanel:titlebar' ,...
                             'ButtonDownFcn' , '' ,...
                             'TooltipString' , sprintf('<html><b>%s</b> panel' , title ) );
    HH.auxHGs = [ HH.auxHGs ; HH.TitleBar ];
    set( HH.TitleBar , 'ForegroundColor' , contrastedColor( get(HH.TitleBar,'BackgroundColor') ) );
    HH.listenerTitle = addlistener( P , 'Title' , 'PostSet' , @(h,e)localSet( P , e , 'Title' ) );
  end
  
  %isMoveable
  if onoff( P , 'Moveable' )
    set( HH.TitleBar , 'TooltipString' , [ get( HH.TitleBar , 'TooltipString' ) , '<br><i>drag to move</i>' ] );
    if isempty( get( HH.TitleBar , 'ButtonDownFcn' ) )
      set( HH.TitleBar , 'ButtonDownFcn' , @(h,e)ClickOnTitleBar( P , HH.Fig ) );
    end
  end
  
  %isRollable
  if onoff( P , 'Rollable' )
    set( HH.TitleBar , 'TooltipString' , [ get( HH.TitleBar , 'TooltipString' ) , '<br><i>double-click to roll</i>' ] );
    if isempty( get( HH.TitleBar , 'ButtonDownFcn' ) )
      set( HH.TitleBar , 'ButtonDownFcn' , @(h,e)ClickOnTitleBar( P , HH.Fig ) );
    end
  end
  
  %RightResizeControl
  if onoff( P , 'RightResizeControl' )
    HH.RGrip = uicontrol( 'Parent',P,'Style','checkbox','Units','pixel',...
                           'HandleVisibility' , 'off' ,...
                           'BackgroundColor', get( P , 'BackgroundColor' ),...
                           'Enable' , 'inactive' ,...
                           'HitTest' , 'on' ,...
                           'Tag' , 'uimpanel:rightgrip' );
    HH.auxHGs = [ HH.auxHGs ; HH.RGrip ];
    cdata = zeros( HH.GripSize*[1 1] ); cdata( ~~tril(ones(HH.GripSize*[1 1])) ) = NaN; cdata = flipud( cdata ); cdata = repmat( cdata , [1 1 3] );
    set( HH.RGrip , 'CData' , cdata , 'ButtonDownFcn' , @(h,e)START_rresize( P , HH.Fig ) );
    %set( P , 'Visible' , 'on' ); jRGrip = findjobj( HH.RGrip ); set( P , 'Visible' , 'off' );
    %set( jRGrip , 'MouseEnteredCallback' , @(j,e)MouseEntered(j,'botr') );
  end
  
  %LeftResizeControl
  if onoff( P , 'LeftResizeControl' )
    HH.LGrip = uicontrol( 'Parent',P,'Style','checkbox','Units','pixel',...
                           'HandleVisibility' , 'off' ,...
                           'BackgroundColor', get( P , 'BackgroundColor' ),...
                           'Enable' , 'inactive' ,...
                           'HitTest' , 'on' ,...
                           'Tag' , 'uimpanel:rightgrip' );
    HH.auxHGs = [ HH.auxHGs ; HH.LGrip ];
    cdata = zeros(HH.GripSize*[1 1]); cdata( ~~triu(ones(HH.GripSize*[1 1])) ) = NaN; cdata = repmat( cdata , [1 1 3] );
    set( HH.LGrip , 'CData' , cdata , 'ButtonDownFcn' , @(h,e)START_lresize( P , HH.Fig ) );
  end
  
  
  %VisibilityControl
  if onoff( P , 'VisibilityControl' )
    HH.HideButton = uicontrol( 'Parent',P,'Style','checkbox','Units','pixel',...
                             'HandleVisibility' , 'off' ,...
                             'CData', zeros( [ HH.TitleBarHeight , HH.TitleBarHeight , 3 ] )+0.3 ,...
                             'Enable' , 'on' ,...
                             'HitTest' , 'on' ,...
                             'String', '' ,...
                             'BackgroundColor' , [0 0 0] ,...
                             'Tag' , 'uimpanel:hidebutton' ,...
                             'Callback' , @(h,e)set(P,'Visible','off') ,...
                             'TooltipString' , 'Hide panel' );
    HH.auxHGs = [ HH.auxHGs ; HH.HideButton ];
  end
  
  
  %glues
  HH.Glue(1,1) = uicontrol( 'Parent',P,'Style','frame','ForegroundColor',[1 0 0],'Visible','off','Hittest','off');
  HH.Glue(2,1) = uicontrol( 'Parent',P,'Style','frame','ForegroundColor',[1 0 0],'Visible','off','Hittest','off');
  HH.Glue(3,1) = uicontrol( 'Parent',P,'Style','frame','ForegroundColor',[1 0 0],'Visible','off','Hittest','off');
  HH.Glue(4,1) = uicontrol( 'Parent',P,'Style','frame','ForegroundColor',[1 0 0],'Visible','off','Hittest','off');
  HH.auxHGs = [ HH.auxHGs ; HH.Glue ];
  
  HH.GlueTimer = timer( 'TimerFcn' , @(h,e)set(HH.Glue,'Visible','off') , 'StartDelay' , 0.5 , 'ExecutionMode' , 'singleShot' );
  set( HH.Glue(1,1) , 'DeleteFcn' , @(h,e)stop_and_delete( HH.GlueTimer ) );
  
  
  
  if VISIBLE, set( P , 'Visible' , 'on' ); end
  setappdata( P , 'uimpanel' , HH );
  redraw(P);

  
  if matlabV > 804
    HH.listenerParentSize = addlistener( get(P,'Parent') , 'SizeChanged' , @(hh,ee)ChangingParentSize( P ) );
  else
    HH.listenerVisible    = addlistener( P , 'Visible'    , 'PostSet' , @(h,e)localSet(P,e,'Visible') );
    HH.listenerBorderType = addlistener( P , 'BorderType' , 'PostSet' , @(h,e)redraw(P) );
    HH.listenerPosition   = addlistener( P , 'Position'   , 'PostSet' , @(h,e)redraw(P) );
    HH.listenerParentSize = addlistener( get(P,'Parent')  , 'Position' , 'PostSet' , @(hh,ee)ChangingParentSize( P ) );
  end
  set( HH.Glue(4,1) , 'DeleteFcn' , @(h,e)delete(HH.listenerParentSize) );
  
  
  function redraw( P )
    if onoff( P , 'IsRolled' )
      HH = getappdata( P , 'uimpanel' );
      pxPOS = getPosition( P , 'pixel' );

      try, if ishandle( HH.TitleBar )
        pos = [ 0 , pxPOS(4)-HH.TitleBarHeight , pxPOS(3) , HH.TitleBarHeight ];
        switch get( P , 'BorderType' )
          case {'none'},       pos = pos + [ 0 , +2 , +1 , 0 ];
          case {'beveledout'}, pos = pos + [ 1 , +1 , -3 , 0 ];
          case {'line'},       pos = pos + [ 1 , +1 , -3 , 0 ];
          case {'beveledin'},  pos = pos + [ 1 , +1 , -2 , 0 ];
          case {'etchedin'},   pos = pos + [ 1 , +0 , -4 , 0 ];
          case {'etchedout'},  pos = pos + [ 1 , +0 , -4 , 0 ];
        end
        set( HH.TitleBar , 'Position' , pos );
      end; end

      try, if ishandle( HH.HideButton )
        pos = [ pxPOS(3)-HH.TitleBarHeight , pxPOS(4)-HH.TitleBarHeight , HH.TitleBarHeight-1 , HH.TitleBarHeight];
        switch get( P , 'BorderType' )
          case {'none'},       pos = pos + [  2 , +2 , 0 , 0 ];
          case {'beveledout'}, pos = pos + [  0 , +1 , 0 , 0 ];
          case {'line'},       pos = pos + [  0 , +1 , 0 , 0 ];
          case {'beveledin'},  pos = pos + [  0 , +1 , 0 , 0 ];
          case {'etchedin'},   pos = pos + [ -2 , +0 , 0 , 0 ];
          case {'etchedout'},  pos = pos + [ -1 , +0 , 0 , 0 ];
        end
        set( HH.HideButton , 'Position' , pos );
      end; end
      return;
    end
    
    if onoff( P , 'IsUndocked' )
      return;
    end  
    
    HH = getappdata( P , 'uimpanel' );
    pxPOS = getPosition( P , 'pixel' );

    try, if ishandle( HH.TitleBar )
      pos = [ 0 , pxPOS(4)-HH.TitleBarHeight , pxPOS(3) , HH.TitleBarHeight ];
      switch get( P , 'BorderType' )
        case {'none'},       pos = pos + [ 0 , +1 , +1 , 0 ];
        case {'beveledout'}, pos = pos + [ 1 , -1 , -3 , 0 ];
        case {'line'},       pos = pos + [ 1 , -1 , -3 , 0 ];
        case {'beveledin'},  pos = pos + [ 1 , -1 , -2 , 0 ];
        case {'etchedin'},   pos = pos + [ 1 , -3 , -4 , 0 ];
        case {'etchedout'},  pos = pos + [ 1 , -3 , -4 , 0 ];
      end
      set( HH.TitleBar , 'Position' , pos );
    end; end

    try, if ishandle( HH.HideButton )
      pos = [ pxPOS(3)-HH.TitleBarHeight , pxPOS(4)-HH.TitleBarHeight , HH.TitleBarHeight-1 , HH.TitleBarHeight];
      switch get( P , 'BorderType' )
        case {'none'},       pos = pos + [  2 , +1 , 0 , 0 ];
        case {'beveledout'}, pos = pos + [  0 , -1 , 0 , 0 ];
        case {'line'},       pos = pos + [  0 , -1 , 0 , 0 ];
        case {'beveledin'},  pos = pos + [  0 , -1 , 0 , 0 ];
        case {'etchedin'},   pos = pos + [ -2 , -3 , 0 , 0 ];
        case {'etchedout'},  pos = pos + [ -1 , -3 , 0 , 0 ];
      end
      set( HH.HideButton , 'Position' , pos );
    end; end
  
    try, if ishandle( HH.RGrip )
      pos = [ pxPOS(3)-HH.GripSize , 0 , HH.GripSize , HH.GripSize ];
      switch get( P , 'BorderType' )
        case {'none'},       pos = pos + [ +1 , 1 , 0 , 0 ];
        case {'beveledout'}, pos = pos + [ -1 , 1 , 0 , 0 ];
        case {'line'},       pos = pos + [ -1 , 1 , 0 , 0 ];
        case {'beveledin'},  pos = pos + [ -1 , 1 , 0 , 0 ];
        case {'etchedin'},   pos = pos + [ -3 , 1 , 0 , 0 ];
        case {'etchedout'},  pos = pos + [ -2 , 0 , 0 , 0 ];
      end
      set( HH.RGrip , 'Position' , pos );
    end; end
    try, if ishandle( HH.LGrip )
      pos = [ 0 , 0 , HH.GripSize , HH.GripSize ];
      switch get( P , 'BorderType' )
        case {'none'},       pos = pos + [ 1 , 1 , -1 , -1 ];
        case {'beveledout'}, pos = pos + [ 0 , 1 , -1 , -1 ];
        case {'line'},       pos = pos + [ 0 , 1 , -1 , -1 ];
        case {'beveledin'},  pos = pos + [ 1 , 1 , -1 , -1 ];
        case {'etchedin'},   pos = pos + [ 0 , 1 , -1 , -1 ];
        case {'etchedout'},  pos = pos + [ 0 , 0 , -1 , -1 ];
      end
      set( HH.LGrip , 'Position' , pos );
    end; end
  end
  function ChangingParentSize( P )
    parentPOS = getPosition( get( P , 'Parent' ) , 'pixel' );
    pxPOS = getPosition( P , 'pixel' );
    POS = [ ( get( P , 'Location' ).*parentPOS(3:4) ) , pxPOS(3:4) ];
    POS(2) = POS(2) - POS(4);
    
    if onoff( P , 'ConstrainedToParent' )
      if POS(1) + POS(3) > parentPOS(3) + 1
        POS(1) = parentPOS(3) - POS(3) + 1;
      end
      if POS(2) + POS(4) > parentPOS(4) + 1
        POS(2) = parentPOS(4) - POS(4) + 1;
      end
      if POS(1) < 1,
        POS(1) = 1;
      end
      if POS(2) < 1,
        POS(2) = 1;
      end
      
      GLUED = get( P , 'Glued' );
      if GLUED(1), POS(1) = 1; end
      if GLUED(2), POS(2) = 1; end
      if GLUED(3), POS(1) = parentPOS(3) - POS(3) + 1; end
      if GLUED(4), POS(2) = parentPOS(4) - POS(4) + 1; end
      if any( GLUED )
        set( P , 'Glued' , false(1,4) );
        set( P , 'Glued' , GLUED );
      end
      
    end
    
    setPosition( P , 'pixel' , POS );
  end
  
  function value = localSet( h , value , prop , hook )
    if nargin > 3 && hook
      set( P , prop , value );
      return;
    end
    switch lower( prop )
      case {'visible'}
        if onoff( P , 'Visible' )
          uistack( P , 'top' );
        else
          fun = get(P,'HideRequestFcn');
          if isempty( fun )
          elseif ischar(fun)
            evalin('base',fun);
          elseif iscell(fun)
            fun{1}( P , 'Hiding' , fun{2:end} );
          else
            fun( P , 'Hiding' );
          end
        end
      case {'glued'}
        HH = getappdata( P , 'uimpanel' );
        POS = getPosition( P , 'pixel' );
        w = 2;
        m = 3; mm = m*2;
        if value(1),  set( HH.Glue(1) , 'Visible','on','Position',[        0 ,        m ,         w , POS(4)-mm ] );
        else,         set( HH.Glue(1) , 'Visible','off');
        end
        if value(2),  set( HH.Glue(2) , 'Visible','on','Position',[        m ,        0 , POS(3)-mm ,         w ] );
        else,         set( HH.Glue(2) , 'Visible','off');
        end
        if value(3),  set( HH.Glue(3) , 'Visible','on','Position',[ POS(3)-w ,        m ,         w , POS(4)-mm ] );
        else,         set( HH.Glue(3) , 'Visible','off');
        end
        if value(4),  set( HH.Glue(4) , 'Visible','on','Position',[        m , POS(4)-w , POS(3)-mm ,         w ] );
        else,         set( HH.Glue(4) , 'Visible','off');
        end
        stop( HH.GlueTimer ); start( HH.GlueTimer );
      case {'location'}
      case {'size'}
      case {'isundocked'}, if ~isonoff( value ), error('on/off was expected'); end
        HH = getappdata( P , 'uimpanel' );
        if onoff( value )
          title = get( HH.TitleBar , 'String' ); title = title(2:end);

          ScreenPosition = getScreenPosition( P );
          
          HH.UnDockedFigure = figure('IntegerHandle','off','Visible','off','position', ScreenPosition ,'MenuBar','none','ToolBar','none');

          set( HH.UnDockedFigure , 'CloseRequestFcn' , @(h,e)set( P , 'IsUndocked' , 'off' ) );
          set( HH.UnDockedFigure , 'Color' , get( P , 'BackgroundColor' ) );
          set( HH.UnDockedFigure , 'DeleteFcn' , get( P , 'DeleteFcn' ) );
          set( HH.UnDockedFigure , 'DockControls' , 'off' );
          set( HH.UnDockedFigure , 'HandleVisibility' , 'off' );
          set( HH.UnDockedFigure , 'Name' , title );
          set( HH.UnDockedFigure , 'NextPlot' , 'new' );
          set( HH.UnDockedFigure , 'NumberTitle' , 'off' );
          set( HH.UnDockedFigure , 'Pointer' , get( HH.Fig , 'Pointer' ) );
          set( HH.UnDockedFigure , 'PointerShapeCData' , get( HH.Fig , 'PointerShapeCData' ) );
          set( HH.UnDockedFigure , 'PointerShapeHotSpot' , get( HH.Fig , 'PointerShapeHotSpot' ) );
          set( HH.UnDockedFigure , 'Renderer', get( HH.Fig , 'Renderer' ) );
          set( HH.UnDockedFigure , 'RendererMode', get( HH.Fig , 'RendererMode' ) );
          set( HH.UnDockedFigure , 'Resize' , onoff( onoff( P , 'LeftResizeControl' ) || onoff( P , 'RightResizeControl' ) ) );
          set( HH.UnDockedFigure , 'ResizeFcn' , get( P , 'ResizeFcn' ) );
          set( HH.UnDockedFigure , 'Tag' , get( P , 'Tag' ) ); set( P , 'Tag' , '' );
          set( HH.UnDockedFigure , 'WindowStyle' , 'normal' );
          
          set( HH.UnDockedFigure , 'Visible','on' );
          set( P , 'Visible' , 'off' );
        else
          
          
          try, delete( HH.UnDockedFigure ); end
          HH = rmfield( HH , 'UnDockedFigure' );
          set( P , 'Visible' , 'on' );
        end
        setappdata( P , 'uimpanel' , HH );
        
      case {'isrolled'}, if ~isonoff( value ), error('on/off was expected'); end
        HH = getappdata( P , 'uimpanel' );
        
        pxPOS = getPosition( P , 'pixel' );
        if onoff( value )
          localSet( P  , pxPOS(3:4) , 'Size' , true );
          
          try, set( HH.TitleBar , 'BackgroundColor' , [1 1 1]*0.5 , 'ForegroundColor' , [1 1 1]*0.3 ); end
          try, set( HH.RGrip    , 'Visible' , 'off' ); end
          try, set( HH.LGrip    , 'Visible' , 'off' ); end

          CH = setdiff( get( P , 'Children' ) , HH.auxHGs );
          HH.VIS = [];
          for c = 1:numel(CH)
            if strcmp( get( CH(c) , 'Visible' ) , 'on' )
              HH.VIS = [ HH.VIS ; CH(c) ];
            end
          end
          set( HH.VIS , 'Visible' , 'off' );
          setappdata( P , 'uimpanel' , HH );
          
          POS = [ pxPOS(1) , pxPOS(2) + pxPOS(4) - HH.RolledHeight , pxPOS(3) , HH.RolledHeight ];
        else
          Size = get( P , 'Size' );

          try, set( HH.TitleBar , 'BackgroundColor' , get(P,'TitleBarColor') , 'ForegroundColor' , contrastedColor(get(P,'TitleBarColor')) ); end
          try, set( HH.RGrip    , 'Visible' , 'on' ); end
          try, set( HH.LGrip    , 'Visible' , 'on' ); end
          
          set( HH.VIS , 'Visible' , 'on' );

          POS = [ pxPOS(1) , pxPOS(2) + pxPOS(4) - Size(2) , pxPOS(3) , Size(2) ];
        end
        setPosition( P , 'pixel' , POS );
        
      case {'title'}
        HH = getappdata( P , 'uimpanel' );
        oldTitle = get( HH.TitleBar , 'String' ); oldTitle = oldTitle(2:end);
        newTitle = get( P , 'Title' ); set( P , 'Title' , '' );
        set( HH.TitleBar , 'String' , [ ' ' , newTitle ] );
        set( HH.TitleBar , 'TooltipString' , builtin( 'strrep' , get( HH.TitleBar , 'TooltipString' ) , sprintf('<html><b>%s</b> panel' , oldTitle ) , sprintf('<html><b>%s</b> panel' , newTitle ) ) );
        
        if onoff( P , 'IsUndocked' )
          set( HH.UnDockedFigure , 'Name' ,  newTitle );
        end
      case {'bordertype'}
        redraw( P );
      case {'showtitlebar'}, if ~isonoff( value ), error('on/off was expected'); end
        HH = getappdata( P , 'uimpanel' );
        try, set( HH.TitleBar   , 'Visible' , value ); end
        try, set( HH.HideButton , 'Visible' , value ); end
        try, set( HH.RGrip      , 'Visible' , value ); end
        try, set( HH.LGrip      , 'Visible' , value ); end
        
      case {'titlebarcolor'}
        HH = getappdata( P , 'uimpanel' );
        try,
          set( HH.TitleBar , 'BackgroundColor' , value , 'ForegroundColor' , contrastedColor( get(HH.TitleBar,'BackgroundColor') ) );
        end
      case { 'moveable' , 'constrainedtoparent' , 'visibilitycontrol' , 'leftresizecontrol' , 'rightresizecontrol' , 'rollable' , 'undockcontrol' }
        if ~isonoff( value ), error('on/off was expected'); end
    end
  end
  function value = localGet( h , value , prop )
%     disp([ 'getting prop: .' prop ]);
%     uneval( value );
%     disp('ok?');
  end
  function addProp( P , PropName , value )
    np = schema.prop( P , PropName , 'mxArray' );
    np.AccessFlags.PublicGet = 'on';
    np.AccessFlags.PublicSet = 'on';
    np.GetFunction = { @localGet , PropName };
    np.Visible     = 'on';
    
    if nargin > 2
      set( P , PropName , value );
    end
    np.SetFunction = { @localSet , PropName };
  end

  function ClickOnTitleBar( P , Fig )
    uistack( P , 'top' );
    
    if      onoff( P , 'Rollable' ) && strcmp( get( Fig , 'SelectionType' ) , 'open' )
      set( P , 'IsRolled' , onoff( ~onoff( get( P , 'IsRolled' ) ) ) );
      redraw( P );
    elseif  onoff( P , 'Moveable' )
      START_move( P , Fig );
    end
  end
  function START_move( P , Fig )
    if onoff( P , 'IsRolled' ), return; end
    oldUnits = get( P , 'Units' ); set( P , 'Units' , 'pixel' );
    FP  = get( Fig  , 'CurrentPoint' );
    pos = get( P    , 'position'     );
    
    parentPos = [];
    if onoff( P , 'ConstrainedToParent' )
      parentPos = getPosition( get(P,'Parent') , 'pixels' );
    end
    
    oldSTATE = SuspendFigure( Fig , 'WindowButtonMotionFcn',@(h,e) MOVING , 'WindowButtonUpFcn' , @(h,e) STOP );
    function STOP
      RestoreFigure( Fig , oldSTATE );
      set( P , 'Units' , oldUnits );
      
      nPOS = getPosition( P , 'normalized' );
      localSet( P , [  nPOS(1) , nPOS(2)+nPOS(4) ] , 'Location' , true );
    end
    function MOVING
      delta = get( Fig ,'CurrentPoint' ) - FP ;
      new_pos = [ pos(1:2)+delta , pos(3:4) ];

      if ~isempty( parentPos )
        GLUED = false(1,4);
        if new_pos(1) <= 1,
          GLUED(1) = true;
          new_pos(1) = 1;
        end
        if new_pos(2) <= 1,
          GLUED(2) = true;
          new_pos(2) = 1;
        end
        if new_pos(1) + new_pos(3) >= parentPos(3) + 1
          GLUED(3) = true;
          new_pos(1) = parentPos(3) - new_pos(3) + 1;
        end
        if new_pos(2) + new_pos(4) >= parentPos(4) + 1
          GLUED(4) = true;
          new_pos(2) = parentPos(4) - new_pos(4) + 1;
        end
      end
      set( P , 'Position', new_pos );
      if ~isempty( parentPos ), set( P , 'Glued' , GLUED ); end
    end
  end
  function START_rresize( P , Fig )
    oldUnits = get( P , 'Units' ); set( P , 'Units' , 'pixel' );
    FP  = get( Fig  , 'CurrentPoint' );
    pos = get( P    , 'Position'     );
    
    minSize = get( P , 'MinimumSize' );
    
    parentPos = [];
    if onoff( P , 'ConstrainedToParent' )
      parentPos = getPosition( get(P,'Parent') , 'pixels' );
    end
    
    oldSTATE = SuspendFigure( Fig , 'WindowButtonMotionFcn',@(h,e) MOVING , 'WindowButtonUpFcn' , @(h,e) STOP );
    function STOP
      RestoreFigure( Fig , oldSTATE );
      set( P , 'Units' , oldUnits );

      pxPOS = getPosition( P , 'pixel' );
      localSet( P , [ pxPOS(3) , pxPOS(4) ] , 'Size' , true );
    end
    function MOVING
      delta = get( Fig ,'CurrentPoint' ) - FP ;
      new_pos = [ pos(1) , pos(2)+delta(2) , pos(3)+delta(1) , pos(4)-delta(2) ];

      if new_pos(3) <= minSize(1)
        
        new_pos(3) = minSize(1);
      end
      if new_pos(4) <= minSize(2)
        new_pos(2) = new_pos(2) + new_pos(4) - minSize(2);
        new_pos(4) = minSize(2);
      end
      
      if ~isempty( parentPos )
        GLUED = false(1,4); set( P , 'Glued' , GLUED );

        if new_pos(2) <= 1
          GLUED(2) = true;
          new_pos(4) = new_pos(4) + new_pos(2) - 1;
          new_pos(2) = 1;
        end
        if new_pos(1) + new_pos(3) >= parentPos(3) + 1
          GLUED(3) = true;
          new_pos(3) = parentPos(3) - new_pos(1) + 1; 
        end
      end
      
      set( P , 'Position', new_pos );
      if ~isempty( parentPos ), set( P , 'Glued' , GLUED ); end
    end
  end
  function START_lresize( P , Fig )
    oldUnits = get( P , 'Units' ); set( P , 'Units' , 'pixel' );
    FP  = get( Fig  , 'CurrentPoint' );
    pos = get( P    , 'position'     );
    
    minSize = get( P , 'MinimumSize' );
    
    parentPos = [];
    if onoff( P , 'ConstrainedToParent' )
      parentPos = getPosition( get(P,'Parent') , 'pixels' );
    end
    
    oldSTATE = SuspendFigure( Fig , 'WindowButtonMotionFcn',@(h,e) MOVING , 'WindowButtonUpFcn' , @(h,e) STOP );
    function STOP
      RestoreFigure( Fig , oldSTATE );
      set( P , 'Units' , oldUnits );

      pxPOS = getPosition( P , 'pixel' );
      localSet( P , [ pxPOS(3) , pxPOS(4) ] , 'Size' , true );
    end
    function MOVING
      delta = get( Fig ,'CurrentPoint' ) - FP ;
      new_pos = [ pos(1)+delta(1) , pos(2)+delta(2) , pos(3)-delta(1) , pos(4)-delta(2) ];

      if new_pos(3) < minSize(1)
        new_pos(1) = new_pos(1) + new_pos(3) - minSize(1);
        new_pos(3) = minSize(1);
      end
      if new_pos(4) <= minSize(2)
        new_pos(2) = new_pos(2) + new_pos(4) - minSize(2);
        new_pos(4) = minSize(2);
      end
      
      if ~isempty( parentPos )
        GLUED = false(1,4); set( P , 'Glued' , GLUED );

        if new_pos(2) <= 1
          GLUED(2) = true;
          new_pos(4) = new_pos(4) + new_pos(2) - 1;
          new_pos(2) = 1;
        end
        if new_pos(1) <= 1
          GLUED(1) = true;
          new_pos(3) = new_pos(1) + new_pos(3) - 1;
          new_pos(1) = 1;
        end
      end

      set( P , 'Position', new_pos );
      if ~isempty( parentPos ), set( P , 'Glued' , GLUED ); end
    end
  end


%   function MouseEntered( j , mPointer )
%     currentPointer = get( HH.Fig , { 'Pointer' , 'PointerShapeCData' , 'PointerShapeHotSpot' } );
%     set( j , 'MouseExitedCallback' , @(j,e)set( HH.Fig , 'Pointer' , currentPointer{1} , 'PointerShapeCData' , currentPointer{2} , 'PointerShapeHotSpot' , currentPointer{3} ) );
%     set( HH.Fig , 'Pointer' , mPointer );
%   end
    
end


function oldSTATE = SuspendFigure( h , varargin )
  oldSTATE.FigPointer             = get( h , 'Pointer'               );
  oldSTATE.FigPointerShapeCData   = get( h , 'PointerShapeCData'     );
  oldSTATE.FigPointerShapeHotSpot = get( h , 'PointerShapeHotSpot'   );
  oldSTATE.WindowButtonDownFcn    = get( h , 'WindowButtonDownFcn'   ); set( h , 'WindowButtonDownFcn'   , '' );
  oldSTATE.WindowScrollWheelFcn   = get( h , 'WindowScrollWheelFcn'  ); set( h , 'WindowScrollWheelFcn'  , '' );
  oldSTATE.WindowKeyReleaseFcn    = get( h , 'WindowKeyReleaseFcn'   ); set( h , 'WindowKeyReleaseFcn'   , '' );
  oldSTATE.WindowKeyPressFcn      = get( h , 'WindowKeyPressFcn'     ); set( h , 'WindowKeyPressFcn'     , '' );
  oldSTATE.WindowButtonMotionFcn  = get( h , 'WindowButtonMotionFcn' ); set( h , 'WindowButtonMotionFcn' , '' );
  oldSTATE.WindowButtonUpFcn      = get( h , 'WindowButtonUpFcn'     ); set( h , 'WindowButtonUpFcn'     , '' );

  for v = 1:2:numel(varargin)
    if strcmpi( varargin{v} ,'pointer' )
      setFigurePointer( h , varargin{v+1} );
    else
      set( h , varargin{v} , varargin{v+1} );
    end
  end
end
function RestoreFigure( h , oldSTATE )
  set( h , 'Pointer'               , oldSTATE.FigPointer             );
  set( h , 'PointerShapeCData'     , oldSTATE.FigPointerShapeCData   );
  set( h , 'PointerShapeHotSpot'   , oldSTATE.FigPointerShapeHotSpot );
  set( h , 'WindowButtonMotionFcn' , oldSTATE.WindowButtonMotionFcn  );
  set( h , 'WindowKeyReleaseFcn'   , oldSTATE.WindowKeyReleaseFcn    );
  set( h , 'WindowKeyPressFcn'     , oldSTATE.WindowKeyPressFcn      );
  set( h , 'WindowButtonDownFcn'   , oldSTATE.WindowButtonDownFcn    );
  set( h , 'WindowButtonUpFcn'     , oldSTATE.WindowButtonUpFcn      );
  set( h , 'WindowScrollWheelFcn'  , oldSTATE.WindowScrollWheelFcn   );
end
function pos = getScreenPosition( h )
  pos = getPosition( h , 'pixel' );
  while 1
    try
      h = get( h , 'Parent' );
      ppos = getPosition( h , 'pixel' );
      pos(1:2) = pos(1:2) + ppos(1:2);
    catch
      break;
    end
  end
end
function pos = getPosition( h , units )
  if nargin > 1
    oldUNITS = get( h , 'Units' );
    set( h , 'Units' , units );
    pos = get( h , 'Position' );
    set( h , 'Units' , oldUNITS );
  else
    pos = get( h , 'Position' );
  end
end
function pos = setPosition( h , units , pos )
  oldUNITS = get( h , 'Units' );
  set( h , 'Units' , units );
  if any( isnan( pos ) )
    old_pos = get( h , 'Position' );
    pos( ~isnan( pos ) ) = old_pos( ~isnan( pos ) );
  end
  set( h , 'Position' , pos );
  set( h , 'Units' , oldUNITS );
end
function c = contrastedColor( c )
%     a = 1 - ( 0.299 * c(1) + 0.587 * c(2) + 0.114 * c(3) );
%     if a > 0.5, c = [0 0 0];
%     else,       c = [1 1 1]*0.9;
%     end
  a = 0.2126 * c(1)^2.2  +  0.7151 * c(2)^2.2  +  0.0721 * c(3)^2.2;
  if a > 0.2, c = [0 0 0];
  else,        c = [1 1 1]*0.99;
  end
end
function o = isonoff( str )
  o = false;
  if ~ischar( str ), return; end
  str = lower( str );
  if      strcmp( str , 'on'  ), o = true;
  elseif  strcmp( str , 'of'  ), o = true;
  elseif  strcmp( str , 'off' ), o = true;
  end
end
function stop_and_delete( h )
  try, stop( h ); end
  try, delete( h ); end
end
