function SPP = splitpanel( varargin )
%   sp1 = splitpanel('horizontal','r',0.3);
%   sp2 = splitpanel('vertical','Parent',sp1.right);
%   sp3 = splitpanel('horizontal','Parent',sp2.bottom);
%   sp4 = splitpanel('horizontal','Parent',sp3.left);
%   sp5 = splitpanel('vertical','Parent',sp4.right );
  
  [varargin,direction ]  = parseargs(varargin,'Horizontal','hor','$FORCE$',{'horizontal','both'});
  [varargin,direction ]  = parseargs(varargin,'Vertical','ver','vert','$FORCE$',{'vertical',direction});
  [varargin,i,ratio ]    = parseargs(varargin,'ASPECTratio','Ratio','$DEFS$',[0.5 0.5]);
  [varargin,i,resizeFcn] = parseargs(varargin,'resizefcn','$DEFS$',@(x) 1);

  SP.panel = uipanel( 'BorderType','none','BorderWidth',0,'SelectionHighlight','off', varargin{:} );
  try
  set( SP.panel , 'BackgroundColor' , get( get( SP.panel ,'Parent' ) , 'Color' ) );
  catch
  set( SP.panel , 'BackgroundColor' , get( get( SP.panel ,'Parent' ) , 'BackgroundColor' ) );
  end
  
  parent = get(SP.panel,'parent');
  if strcmp(get(parent,'Type'),'uipanel')
    set(parent,'BorderType','none');
    delete(findall( parent , 'Tag', 'MINMAX'));
  end
  hFig= ancestor(SP.panel,'figure');

  SP.Hseparator= uipanel('Parent',SP.panel,'Units','Normalized','Position',[0 0 1 1],'BorderType','none','BorderWidth',0,'ButtonDownFcn',@(h,e) START_DRAG(h),'Tag','HorizontalSeparator');
  SP.Vseparator= uipanel('Parent',SP.panel,'Units','Normalized','Position',[0 0 1 1],'BorderType','none','BorderWidth',0,'ButtonDownFcn',@(h,e) START_DRAG(h),'Tag','VerticalSeparator');
%   set(SP.Hseparator,'background',max( get(SP.Hseparator,'background')-0.1 , [0 0 0] ) );
%   set(SP.Vseparator,'background',max( get(SP.Vseparator,'background')-0.1 , [0 0 0] ) );
  
  SP.top_left     = uipanel('Parent',SP.panel,'Units','normalized','Tag','TopLeft'    );
  SP.top_right    = uipanel('Parent',SP.panel,'Units','normalized','Tag','TopRight'   );
  SP.bottom_left  = uipanel('Parent',SP.panel,'Units','normalized','Tag','BottomLeft' );
  SP.bottom_right = uipanel('Parent',SP.panel,'Units','normalized','Tag','BottomRight');
  
  SP.mtop_left     = uicontrol('Parent',SP.top_left     ,'Style','togglebutton','tag', 'MINMAX','Callback',@(h,e) MINMAX(h) );
  SP.mtop_right    = uicontrol('Parent',SP.top_right    ,'Style','togglebutton','tag', 'MINMAX','Callback',@(h,e) MINMAX(h) );
  SP.mbottom_left  = uicontrol('Parent',SP.bottom_left  ,'Style','togglebutton','tag', 'MINMAX','Callback',@(h,e) MINMAX(h) );
  SP.mbottom_right = uicontrol('Parent',SP.bottom_right ,'Style','togglebutton','tag', 'MINMAX','Callback',@(h,e) MINMAX(h) );

  SPP.panel = SP.panel;
  switch direction
    case 'both'
      SPP.top_left     = SP.top_left;
      SPP.top_right    = SP.top_right;
      SPP.bottom_left  = SP.bottom_left;
      SPP.bottom_right = SP.bottom_right;
      SPP.Vseparator = SP.Vseparator;
      SPP.Hseparator = SP.Hseparator;
      SPLITV( ratio(1) );
      SPLITH( ratio(2) );
    case 'vertical'
      delete(SP.Hseparator);
      delete(SP.top_right);
      delete(SP.bottom_right);
      set( SP.top_left    , 'Tag','Top'    );
      set( SP.bottom_left , 'Tag','Bottom' );
      SPP.top    = SP.top_left;
      SPP.bottom = SP.bottom_left;
      SPP.Vseparator = SP.Vseparator;
      SPLITV( ratio(1) );
    case 'horizontal'
      delete(SP.Vseparator);
      delete(SP.bottom_left);
      delete(SP.bottom_right);
      set( SP.top_left    , 'Tag','Left'   );
      set( SP.top_right   , 'Tag','Right'  );
      SPP.left    = SP.top_left;
      SPP.right   = SP.top_right;
      SPP.Hseparator = SP.Hseparator;
      SPLITH( ratio(1) );
  end      
  try, fixposition( SP.mtop_left     ,'1-15p,1-15p,15p,15p' ); end
  try, fixposition( SP.mtop_right    ,'1-15p,1-15p,15p,15p' ); end
  try, fixposition( SP.mbottom_left  ,'1-15p,1-15p,15p,15p' ); end
  try, fixposition( SP.mbottom_right ,'1-15p,1-15p,15p,15p' ); end
  try, set(SP.Hseparator,'ResizeFcn',@(h,e) place); end
  try, set(SP.Vseparator,'ResizeFcn',@(h,e) place); end

  
  function START_DRAG(h)
    oldMOTION = get( hFig , 'WindowButtonMotionFcn' );
    oldUP     = get( hFig , 'WindowButtonUpFcn'     );

    if isequal(h,SP.Vseparator),   set( hFig , 'WindowButtonMotionFcn', @(h,e) SPLITV );    end
    if isequal(h,SP.Hseparator),   set( hFig , 'WindowButtonMotionFcn', @(h,e) SPLITH );    end
    set( hFig , 'WindowButtonUpFcn'    , @(h,e) STOP_DRAG );
    function STOP_DRAG
      set( hFig , 'WindowButtonMotionFcn', oldMOTION );
      set( hFig , 'WindowButtonUpFcn'    , oldUP     );
    end
  end

  function place
    try, fixposition(SP.top_left      ); end
    try, fixposition(SP.top_right     ); end
    try, fixposition(SP.bottom_left   ); end
    try, fixposition(SP.bottom_right  ); end
    
    try, fixposition( SP.Hseparator   ); end
    try, fixposition( SP.Vseparator   ); end

    try, fixposition(SP.mtop_left     ); end
    try, fixposition(SP.mtop_right    ); end
    try, fixposition(SP.mbottom_left  ); end
    try, fixposition(SP.mbottom_right ); end
    try, feval( resizeFcn ); end
  end


  function MINMAX(h)
    pa = get(h,'Parent');
    lostfocus(h);
    
    switch get(h,'Value')
      case 1
        try, set( SP.top_left     ,'Visible','off' ); end
        try, set( SP.top_right    ,'Visible','off' ); end
        try, set( SP.bottom_left  ,'Visible','off' ); end
        try, set( SP.bottom_right ,'Visible','off' ); end
        try, set( SP.Hseparator   ,'Visible','off' ); end
        try, set( SP.Vseparator   ,'Visible','off' ); end
        fixposition(pa,[0 0 1 1;0 0 0 0]);
        set(pa,'Visible','on');
      case 0
        try, set( SP.top_left     ,'Visible','on' ); end
        try, set( SP.top_right    ,'Visible','on' ); end
        try, set( SP.bottom_left  ,'Visible','on' ); end
        try, set( SP.bottom_right ,'Visible','on' ); end
        try, set( SP.Hseparator   ,'Visible','on' ); end
        try, set( SP.Vseparator   ,'Visible','on' ); end
        try
          pos= get(SP.Hseparator,'Position');
          SPLITH( pos(1)+pos(3)/2 );
        end
        try
          pos= get(SP.Vseparator,'Position');
          SPLITV( pos(2)+pos(4)/2 );
        end
    end  
    try, fixposition( SP.Hseparator   ); end
    try, fixposition( SP.Vseparator   ); end
    try, fixposition(SP.mtop_left     ); end
    try, fixposition(SP.mtop_right    ); end
    try, fixposition(SP.mbottom_left  ); end
    try, fixposition(SP.mbottom_right ); end
    try, feval( resizeFcn ); end
  end

  function SPLITH(w)
    if nargin<1
      pos = getposition(SP.panel,'pixels');
      w = get(hFig,'CurrentPoint');
      w = w(1) - pos(1);
      w = w/pos(3);
    end
    wp = getposition(SP.panel,'pixels','local',3);
    if     w*wp<5, w =   5/wp; end
    if (1-w)*wp<4, w = 1-4/wp; end

    if     ishandle( SP.Vseparator )
      h = getposition( SP.Vseparator , 'normalized', 'local' );
      h = h(2)+h(4)/2;
    else
      h = 0;
    end
    
    fixposition( SP.Hseparator , [w 0 0 1;-2.5 0 5 0] );
    if ~h
      try, fixposition( SP.top_left     , [ 0 0  w  1 ; 0 0 -3 0 ]);     end
      try, fixposition( SP.top_right    , [ w 0 1-w 1 ; 3 0 -3 0 ] );    end
    else
      try, fixposition( SP.top_left     , [ 0 h  w  1-h ; 0 3 -3 -3 ]);  end
      try, fixposition( SP.top_right    , [ w h 1-w 1-h ; 3 3 -3 -3 ] ); end
      try, fixposition( SP.bottom_left  , [ 0 0  w   h  ; 0 0 -3 -3 ]);  end
      try, fixposition( SP.bottom_right , [ w 0 1-w  h  ; 3 0 -3 -3 ] ); end
    end
    try, fixposition(SP.mtop_left     ); end
    try, fixposition(SP.mtop_right    ); end
    try, fixposition(SP.mbottom_left  ); end
    try, fixposition(SP.mbottom_right ); end
    try, feval( resizeFcn ); end
  end

  function SPLITV(h)
    if nargin<1
      pos = getposition(SP.panel,'pixels');
      h = get(hFig,'CurrentPoint');
      h = h(2) - pos(2);
      h = h/pos(4);
    end
    hp = getposition(SP.panel,'pixels','local',4);
    if     h*hp<5, h =   5/hp; end
    if (1-h)*hp<4, h = 1-4/hp; end

    if     ishandle( SP.Hseparator )
      w = getposition( SP.Hseparator , 'normalized', 'local' );
      w = w(1)+w(3)/2;
    else
      w = 0;
    end
    
    fixposition( SP.Vseparator , [0 h 1 0;0 -2.5 0 5] );
    if ~w
      try, fixposition( SP.top_left     , [ 0 h 1 1-h ; 0 3 0 -3 ] );    end
      try, fixposition( SP.bottom_left  , [ 0 0 1  h  ; 0 0 0 -3 ] );    end
    else
      try, fixposition( SP.top_left     , [ 0 h  w  1-h ; 0 3 -3 -3 ]);  end
      try, fixposition( SP.top_right    , [ w h 1-w 1-h ; 3 3 -3 -3 ] ); end
      try, fixposition( SP.bottom_left  , [ 0 0  w   h  ; 0 0 -3 -3 ]);  end
      try, fixposition( SP.bottom_right , [ w 0 1-w  h  ; 3 0 -3 -3 ] ); end
    end
    try, fixposition(SP.mtop_left     ); end
    try, fixposition(SP.mtop_right    ); end
    try, fixposition(SP.mbottom_left  ); end
    try, fixposition(SP.mbottom_right ); end
    try, 
      feval( resizeFcn ); 
    end
  end

end
