function DCMexplorer( D , varargin )
% TODO:
% - mouse controls on the image (zoom,pan,intensity)
% - and store the axis limits
% 

  
  COMPACT = false;
  try, [varargin,COMPACT] = parseargs(varargin, 'COMPACT','$FORCE$',{true ,COMPACT} ); end
  try, [varargin,COMPACT] = parseargs(varargin, 'LOOSE'  ,'$FORCE$',{false,COMPACT} ); end
  
  SUPERCOMPACT = false;
  try, [varargin,SUPERCOMPACT] = parseargs(varargin, 'SUPERCOMPACT','$FORCE$',{true,SUPERCOMPACT} ); end
  
  
  if SUPERCOMPACT, COMPACT = true; end
  if ~COMPACT, SUPERCOMPACT = false; end

  useNAVIGATOR = false;
  try, [varargin,useNAVIGATOR ] = parseargs(varargin, 'NAVigator','$FORCE$',{true,useNAVIGATOR} ); end
  hNAV = -1;
  if useNAVIGATOR, hNAV = DCMexplorer_navigator( D ); end

  
  showOVERLAY = false;
  try, [varargin,showOVERLAY ] = parseargs(varargin, 'showOVERLAY','$FORCE$',{true,showOVERLAY} ); end
  
  
  [varargin,i,imageFCN] = parseargs(varargin, 'IMAGEFCN','$DEFS$',[] );
  [varargin,i,FCN     ] = parseargs(varargin, 'FCN','$DEFS$',[] );


  VarName = inputname(1);
  hFig  = figure('NumberTitle', 'off',...
                 'IntegerHandle','off',...
                 'NextPlot','new',...
                 'Name','DCM Explorer',...
                 'HandleVisibility','on',...
                 'Toolbar', 'none',...
                 'Menu','none',...
                 'BusyAction','cancel',...
                 'Position',[300,70,1000,720]);
  if useNAVIGATOR
    set( hFig , 'DeleteFcn' , @(h,e)safe_delete(ancestor(hNAV,'figure')) );
  end

  EditInBase = false;
  if ~isempty( VarName )
    EditInBase = true;
    set( hFig , 'Name' , [ 'DCM Explorer:  ' , VarName ] );
  end

  LAYOUT_tool = 'splitpanel';
  switch LAYOUT_tool
    case 'uisplitpane'
  [hTreePanel ,hR ,hDivider1] = uisplitpane(hFig,'Orientation','hor','dividercolor',[1 1 1]*0.5,'dividerwidth',3);
  [hFullInfoPanel,hT ,hDivider2] = uisplitpane(hR  ,'Orientation','ver','dividercolor',[1 1 1]*0.5,'dividerwidth',3);
  [hNodeInfoPanel,hImagePanel,hDivider3] = uisplitpane(hT  ,'Orientation','hor','dividercolor',[1 1 1]*0.5,'dividerwidth',3);
  set( hDivider1 , 'DividerMinLocation',0.15,'DividerMaxLocation',0.85,'DividerLocation',0.25);
  set( hDivider2 , 'DividerMinLocation',0.15,'DividerMaxLocation',0.85,'DividerLocation',0.35);
  set( hDivider3 , 'DividerMinLocation',0.15,'DividerMaxLocation',0.65,'DividerLocation',0.5 );
    case 'layout14'
  hHflex1 = uix.HBoxFlex( 'Parent', hFig , 'Spacing', 3 );
  hTreePanel   = uix.BoxPanel( 'Title', 'DICOM tree', 'Parent', hHflex1 );
  hVflex  = uix.VBoxFlex( 'Parent', hHflex1 , 'Spacing', 3 );
  hHflex2 = uix.HBoxFlex( 'Parent', hVflex , 'Spacing', 3 );
  hNodeInfoPanel  = uix.BoxPanel( 'Title', 'Node INFO', 'Parent', hHflex2 );
  hImagePanel     = uix.BoxPanel( 'Title', 'Image', 'Parent', hHflex2 , 'BackgroundColor',[1 1 1],'FontSize',8 );
  hFullInfoPanel  = uix.BoxPanel( 'Title', 'Full INFO', 'Parent', hVflex );

  hHflex1.Widths = [ 200 -1 ];
  hHflex1.MinimumWidths = [50 160];
  hVflex.MinimumHeights = [100 100];
  hHflex2.MinimumWidths = [50 50];

  hNodeInfoPanel = uicontainer( hNodeInfoPanel );
  hFullInfoPanel = uicontainer( hFullInfoPanel );
  hImagePanel    = uicontainer( hImagePanel );
    case 'layout00'
  hHflex1 = uiextras.HBoxFlex( 'Parent', gcf, 'Spacing', 3 );
  hTreePanel   = uiextras.BoxPanel( 'Title', 'DICOM tree', 'Parent', hHflex1 );
  hVflex  = uiextras.VBoxFlex( 'Parent', hHflex1 , 'Spacing', 3 );
  hHflex2 = uiextras.HBoxFlex( 'Parent', hVflex , 'Spacing', 3 );
  hNodeInfoPanel  = uiextras.BoxPanel( 'Title', 'Node INFO', 'Parent', hHflex2 );
  hImagePanel     = uiextras.BoxPanel( 'Title', 'Image', 'Parent', hHflex2 , 'BackgroundColor',[1 1 1],'FontSize',8 );
  hFullInfoPanel  = uiextras.BoxPanel( 'Title', 'Full INFO', 'Parent', hVflex );

  hHflex1.Sizes = [ 200 -1 ];
  hHflex1.MinimumSizes = [50 160];
  hVflex.MinimumSizes = [100 100];
  hHflex2.MinimumSizes = [50 50];
    case 'splitpanel'
  sp1 = splitpanel('horizontal','resizefcn',@placetree,'ratio',0.3);
  set(sp1.Hseparator,'background',[.4 .4 .4]);
  set(sp1.left   , 'BorderType','none');
  set(sp1.right  , 'BorderType','none');
  delete( findall(sp1.left ,'Tag','MINMAX') );
  delete( findall(sp1.right,'Tag','MINMAX') );
  hTreePanel = sp1.left;

  sp2 = splitpanel('vertical','Parent',sp1.right,'ratio',0.7);
  set(sp2.Vseparator,'background',[.4 .4 .4]);
  set(sp2.top    , 'BorderType','none');
  set(sp2.bottom , 'BorderType','none');
  delete( findall(sp2.top   ,'Tag','MINMAX') );
  delete( findall(sp2.bottom,'Tag','MINMAX') );
  hFullInfoPanel = sp2.bottom;

  sp3 = splitpanel('horizontal','Parent',sp2.top,'ratio',0.4);            
  set(sp3.Hseparator,'background',[.4 .4 .4]);
  set(sp3.left   , 'BorderType','none');
  set(sp3.right  , 'BorderType','none');      
  delete( findall(sp3.left ,'Tag','MINMAX') );
  delete( findall(sp3.right,'Tag','MINMAX') );
  hImagePanel = sp3.right;
  hNodeInfoPanel = sp3.left;
    case 'waterloo_GSplitPane'
hDivider1 = GSplitPane( hFig , 'vertical' ); set( hDivider1 , 'Width' , 0.15 );
hDivider1.setProportion( 0.3 );
hDivider2 = GSplitPane( hDivider1.getComponent( 2 ) , 'horizontal' ); set( hDivider2 , 'Width' , 0.15 );
hDivider2.setProportion( 0.7 );
hDivider3 = GSplitPane( hDivider2.getComponent( 1 ) , 'vertical' ); set( hDivider3 , 'Width' , 0.15 );
% hDivider3 = GElasticPane( hDivider2.getComponent( 1 ) , 'left' );
hDivider3.setProportion( 0.4 );
hTreePanel   = hDivider1.getComponent( 1 ); set( hTreePanel , 'ResizeFcn' , @placetree );
hFullInfoPanel  = hDivider2.getComponent( 2 );
hNodeInfoPanel  = hDivider3.getComponent( 1 );
hImagePanel     = hDivider3.getComponent( 2 );
  end
  
  hNodeInfo = uicontrol('Parent', hNodeInfoPanel ,'Style','edit','units','normalized','Position',[0 0 1 1] ,...
                   'FontUnits','pixels','FontSize',12,'Fontname','Courier New','HorizontalAlignment','left','max',10);
  jScrollPane = findjobj(hNodeInfo);
  jViewPort = jScrollPane.getViewport;
  jNodeInfo = jViewPort.getComponent(0);
  jNodeInfo.setEditorKit( javax.swing.text.html.HTMLEditorKit );
  
  
  hFullInfo = uicontrol('Parent', hFullInfoPanel , 'Style','edit','units','normalized','Position',[0 0 1 1] ,...
                   'FontUnits','pixels','FontSize',10,'Fontname','Courier New','HorizontalAlignment','left','max',10);
  jScrollPane = findjobj(hFullInfo);
  jViewPort = jScrollPane.getViewport;
  jFullInfo = jViewPort.getComponent(0);
  jFullInfo.setEditorKit(javax.swing.text.html.HTMLEditorKit);
  

  hFilterAux = uicontrol('Parent', hFullInfoPanel , 'Style','text','Position',[2 2 34 19],'string','Filter:','backgroundColor',[.8 .8 1],'TooltipString','regexpi on the attributes','fontweight','bold','horizontalalignment','left');
  hFilter = uicontrol('Parent', hFullInfoPanel , 'Style','edit','units','pixels','Position',[36 3 350 18] ,'String','^([xz].*|.*U?ID)$',...
                   'FontUnits','pixels','FontSize',10,'Fontname','Courier New','HorizontalAlignment','left','max',1,'backgroundColor',[.8 .8 1]);

  hTreeFilter = uicontrol('Parent', hTreePanel , 'Style','edit','units','pixels','Position',[55  3 300 18] ,'String','',...
                   'FontUnits','pixels','FontSize',10,'Fontname','Courier New','HorizontalAlignment','left','max',1,'backgroundColor',[1 .8 .8]);
  hTreeFilterAux = uicontrol('Parent', hTreePanel , 'Style','pushbutton','Position',[3 3 54 19],'string','Highlight', 'Callback', @(h,e)filterTree());
  [varargin,i,TFILTER] = parseargs(varargin, 'TreeFILTER','$DEFS$','' );
  if ~isempty( TFILTER )
    set( hTreeFilter , 'String', TFILTER );
  end
  
                 
  try
    set( hImagePanel , 'BackgroundColor',[1 1 1]);
  catch LE, storeERROR( hFig , LE );
  end
  hImageAxe = axes('Parent', hImagePanel ,'CLim',[0 1],'YDir','reverse','Position',[0 0 1 1],'DataAspectRatio',[1 1 1],'visible','off' );
  set( hFig , 'colormap' , gray(256) );
  hImage = image('Parent',hImageAxe,'CData',NaN([4,4]),'cdatamapping','scaled','Visible','off');

  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%    PLAYER_DESIGN                                          %%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  PLAYER = arrayPlayer( @(t)t , 1 );
  uiPLAYER_panel = uipanel('Parent',hImagePanel,'Units','pixels','Position',[ 1 , 1 , 160 , 17 ] ,'Visible','on');
  uiPLAYER_slower = uicontrol('Parent',uiPLAYER_panel,'Style','pushbutton','Position',[  1 , 0 , 18 , 15 ],'CData',reshape([NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0.48,NaN,NaN,NaN,NaN,NaN,0.2,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0.47,NaN,NaN,NaN,NaN,NaN,0.2,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0.49,NaN,NaN,NaN,NaN,NaN,0.2,0.49,NaN,NaN;NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,NaN;NaN,NaN,NaN,0.2,0,0,0.48,NaN,NaN,NaN,0.2,0,0,0.48,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0.47,NaN,NaN,NaN,0.2,0,0,0.47,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0.49,NaN,NaN,NaN,0.2,0,0,0.49,NaN,NaN;NaN,NaN,0.2,0,0,0,0.48,NaN,NaN,0.2,0,0,0,0.48,NaN,NaN,NaN,NaN,0.2,0,0,0,0.47,NaN,NaN,0.2,0,0,0,0.47,NaN,NaN,NaN,NaN,0.2,0,0,0,0.49,NaN,NaN,0.2,0,0,0,0.49,NaN,NaN;NaN,0.2,0,0,0,0,0.48,NaN,0.2,0,0,0,0,0.48,NaN,NaN,NaN,0.2,0,0,0,0,0.47,NaN,0.2,0,0,0,0,0.47,NaN,NaN,NaN,0.2,0,0,0,0,0.49,NaN,0.2,0,0,0,0,0.49,NaN,NaN;NaN,NaN,0,0,0,0,0.48,NaN,NaN,0,0,0,0,0.48,NaN,NaN,NaN,NaN,0,0,0,0,0.47,NaN,NaN,0,0,0,0,0.47,NaN,NaN,NaN,NaN,0,0,0,0,0.49,NaN,NaN,0,0,0,0,0.49,NaN,NaN;NaN,NaN,NaN,0,0,0,0.48,NaN,NaN,NaN,0,0,0,0.48,NaN,NaN,NaN,NaN,NaN,0,0,0,0.47,NaN,NaN,NaN,0,0,0,0.47,NaN,NaN,NaN,NaN,NaN,0,0,0,0.49,NaN,NaN,NaN,0,0,0,0.49,NaN,NaN;NaN,NaN,NaN,NaN,0,0,0.48,NaN,NaN,NaN,NaN,0,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,0,0,0.47,NaN,NaN,NaN,NaN,0,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,0,0,0.49,NaN,NaN,NaN,NaN,0,0,0.49,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0,0.48,NaN,NaN,NaN,NaN,NaN,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0,0.47,NaN,NaN,NaN,NaN,NaN,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0,0.49,NaN,NaN,NaN,NaN,NaN,0,0.49,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,0.48,NaN,NaN,NaN,NaN,NaN,NaN,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.47,NaN,NaN,NaN,NaN,NaN,NaN,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.49,NaN,NaN,NaN,NaN,NaN,NaN,0.49,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN],[16,16,3]));
  set( uiPLAYER_slower , 'Callback' , @(h,e)PLAYER_SET_SPEED( get( PLAYER , 'ElementsPerSecond' )/realpow(2,1/4) ) );
  uiPLAYER_faster = uicontrol('Parent',uiPLAYER_panel,'Style','pushbutton','Position',[ rPos(uiPLAYER_slower)+1 , 0 , 18 , 15 ],'CData',reshape([NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,0.2,NaN,NaN,NaN,NaN,NaN,0.2,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,NaN,NaN,NaN,NaN,NaN,0.2,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,NaN,NaN,NaN,NaN,NaN,0.2,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,0.2,0,NaN,NaN,NaN,NaN,0.2,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,NaN,NaN,NaN,NaN,0.2,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,NaN,NaN,NaN,NaN,0.2,0,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,0.2,0,0,NaN,NaN,NaN,0.2,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0,NaN,NaN,NaN,0.2,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0,NaN,NaN,NaN,0.2,0,0,NaN,NaN,NaN,NaN;NaN,NaN,NaN,0.2,0,0,0,NaN,NaN,0.2,0,0,0,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0,NaN,NaN,0.2,0,0,0,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0,NaN,NaN,0.2,0,0,0,NaN,NaN,NaN;NaN,NaN,NaN,0.2,0,0,0,0,NaN,0.2,0,0,0,0,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0,0,NaN,0.2,0,0,0,0,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0,0,NaN,0.2,0,0,0,0,NaN,NaN;NaN,NaN,NaN,0.2,0,0,0,0.48,NaN,0.2,0,0,0,0.48,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0,0.47,NaN,0.2,0,0,0,0.47,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0,0.49,NaN,0.2,0,0,0,0.49,NaN,NaN;NaN,NaN,NaN,0.2,0,0,0.48,NaN,NaN,0.2,0,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0.47,NaN,NaN,0.2,0,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0,0.49,NaN,NaN,0.2,0,0,0.49,NaN,NaN,NaN;NaN,NaN,NaN,0.2,0,0.48,NaN,NaN,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,NaN,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,NaN,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,0.2,0.48,NaN,NaN,NaN,NaN,0.2,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0.47,NaN,NaN,NaN,NaN,0.2,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0.49,NaN,NaN,NaN,NaN,0.2,0.49,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,0.48,NaN,NaN,NaN,NaN,NaN,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.47,NaN,NaN,NaN,NaN,NaN,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.49,NaN,NaN,NaN,NaN,NaN,0.49,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN],[16,16,3]));
  set( uiPLAYER_faster , 'Callback' , @(h,e)PLAYER_SET_SPEED( get( PLAYER , 'ElementsPerSecond' )*realpow(2,1/4) ) );
  uiPLAYER_edit   = uicontrol('Parent',uiPLAYER_panel,'Style','edit','FontSize',7,'Position',[ rPos(uiPLAYER_faster)+0 , 0 , 55 , 15 ]);
  uiPLAYER_slider = uicontrol('Parent',uiPLAYER_panel,'Style','slider','Position',[ rPos(uiPLAYER_edit)+0 , 0 , 75 , 15 ],'Min',1,'Max',2,'Value',1);
  uiPLAYER_jslider = findjobj(uiPLAYER_slider);
  uiPLAYER_jslider.AdjustmentValueChangedCallback = @(j,e)SLIDERcallback();
  function SLIDERcallback()
    try
      feval(get(uiPLAYER_slider,'Callback'));
    catch LE, storeERROR( hFig , LE );
    end
  end
  %[uiPLAYER_jslider,uiPLAYER_slider] = javacomponent( javax.swing.JSlider , [ rPos(uiPLAYER_edit)+1 , 0 , 75 , 15 ] , uiPLAYER_panel );
  if 0
  uiPLAYER_sliderArea = uicontrol('parent',get(uiPLAYER_slider,'Parent'),'Units','pixels','Position',[ 38 , 0 , 130 , 15 ],'Style','pushbutton');
  uiPLAYER_jsliderArea = findjobj( uiPLAYER_sliderArea );
  uiPLAYER_jsliderArea.setBorderPainted( false );
  uiPLAYER_jsliderArea.setOpaque( false );
  set( uiPLAYER_sliderArea , 'Enable','off' );
  end
  uiPLAYER_play   = uicontrol('Parent',uiPLAYER_panel,'Style','togglebutton','Position',[ rPos(uiPLAYER_slider)+1 , 0 , 18  , 15 ],'Value',0 );
  set( uiPLAYER_play , 'Callback' , @(h,e)PLAYER_PLAY_PAUSE() );
  set( uiPLAYER_panel , 'Position' , [ 1,1,rPos(uiPLAYER_play)+1,17 ] );
  function PLAYER_SET_SPEED( s )
    if strcmp( get(get(hFig,'CurrentObject'),'Type') , 'uicontrol' )
      set(hFig,'CurrentObject',hFig);
      lostfocus(hFig);
    end
    set( PLAYER , 'ElementsPerSecond' , s );
    set( uiPLAYER_slower , 'ToolTipString',sprintf( 'Decrease speed... (now: %.2g fps)',s ) );
    set( uiPLAYER_faster , 'ToolTipString',sprintf( 'Increase speed... (now: %.2g fps)',s ) );
    if s < 0.1, set( uiPLAYER_slower , 'Enable','off' );
    else,       set( uiPLAYER_slower , 'Enable','on'  );
    end
  end
  function PLAYER_PLAY_PAUSE( state )
    if strcmp( get(get(hFig,'CurrentObject'),'Type') , 'uicontrol' )
      set(hFig,'CurrentObject',hFig);
      lostfocus(hFig);
    end
    if nargin < 1
      try
        state = get( uiPLAYER_play , 'Value' );
      catch
        return;
      end
    else
      try
        set( uiPLAYER_play , 'Value' , state );
      end
    end
    n = numel( get(PLAYER,'Elements') );
    v = get( uiPLAYER_slider , 'Value' );
    v = min( max( v , 1 ) , n );
    set( uiPLAYER_slider , 'Min',1 , 'Max', max(n,2) , 'SliderStep' , [1/10 , 1/max((n-1),1)] ,'Value', v );
    if state
      loop( PLAYER );
      set( uiPLAYER_play   , 'ToolTipString','Pause','CData',reshape([NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0.2,0.48,NaN,0.2,0.2,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0.2,0.47,NaN,0.2,0.2,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0.2,0.49,NaN,0.2,0.2,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.2,0,0.48,NaN,0.2,0,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.47,NaN,0.2,0,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.2,0,0.49,NaN,0.2,0,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,0.48,0.48,0.48,NaN,0.48,0.48,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.47,0.47,0.47,NaN,0.47,0.47,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.49,0.49,0.49,NaN,0.49,0.49,0.49,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN],[16,16,3]) );
      %set( uiPLAYER_slider , 'Enable', 'off' );
      %set( uiPLAYER_edit   , 'Enable', 'off' );
      try
        set( uiPLAYER_sliderArea , 'Visible','on' );
      end
      set( uiPLAYER_slider , 'Callback', @(h,e)0 );
      set( uiPLAYER_edit   , 'Callback', @(h,e)0 );
    else
      stop( PLAYER );
      set( uiPLAYER_play   , 'ToolTipString','Play','CData',reshape([NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.49,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.2,0.48,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.6,0.47,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0,0.49,0.49,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.2,0.2,0.2,0.48,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.6,0.6,0.6,0.47,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0,0,0,0.49,0.49,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.2,0.2,0.2,0.2,0.2,0.48,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.6,0.6,0.6,0.6,0.6,0.47,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0,0,0,0,0,0.49,0.49,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.2*ones(1,7),0.48,0.48,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.6*ones(1,7),0.47,0.47,NaN,NaN,NaN,NaN,NaN,NaN,NaN,zeros(1,7),0.49,0.49,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.2*ones(1,7),0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.6*ones(1,7),0.4,0.4,NaN,NaN,NaN,NaN,NaN,NaN,NaN,zeros(1,9),NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.2,0.2,0.2,0.2,0.2,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.6,0.6,0.6,0.6,0.6,0.4,0.4,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,zeros(1,7),NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.2,0.2,0.2,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.6,0.6,0.6,0.4,0.4,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0,0,0,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0.2,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.6,0.4,0.4,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0,0,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0.4,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,0,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN;NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN,NaN],[16,16,3]) );
      %set( uiPLAYER_slider , 'Enable', 'on' );
      %set( uiPLAYER_edit   , 'Enable', 'on' );
      try
        set( uiPLAYER_sliderArea , 'Visible','off' );
      end
      set( uiPLAYER_slider , 'Callback', @(h,e)feval( get(PLAYER,'Callback') , round( get( uiPLAYER_slider , 'Value' ) ) ) );
      set( uiPLAYER_edit   , 'Callback', @(h,e)feval( get(PLAYER,'Callback') , min( max( round( string2number( get( uiPLAYER_edit , 'string' ) ) ) , 1 ) , n ) ) );
    end
  end

  set( hImage , 'DeleteFcn' , @(h,e)DeleteHI() );
  function DeleteHI()
    try, set( uiPLAYER_play , 'Value' , 0 ); end
    try, PLAYER_PLAY_PAUSE( 0 ); end
    try, stop( PLAYER ); end
    try, delete( uiPLAYER_panel ); end
    try, delete( PLAYER ); end
  end
  set( uiPLAYER_panel ,'Visible','off');
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % end %    PLAYER_DESIGN                                          %%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



  if ~EditInBase, VarName = 'DICOM files (no VAR from caller)'; end

  % uitreenode( NodeName , TextToDisplay , Icon , IsLeaf );
  root = uitreenode( 'v0' , 'D' , VarName , [], 0 );
  [TREE, TREEcontainer] = uitree( 'v0' , 'Root' , root , 'ExpandFcn' , @(h,e)createNewNodes(e) );
  try
    set( TREEcontainer , 'Parent', hTreePanel );
  catch LE, storeERROR( hFig , LE );
  end % fix the uitree Parent
  set( TREEcontainer , 'units','normalized','Position',[0 0 0.3 1]);
  set( TREE , 'NodeSelectedCallback'  , @(h,ev)NodeSelectedFcn( ev.getCurrentNode ) );
  set( TREE.getTree , 'RowHeight' , 0 );

  % Set the TREE mouse-click callback
  MenuItem{1} = javax.swing.JMenuItem( 'NODE_name' );
  MenuItem{2} = javax.swing.JMenuItem( 'Read in base workspace' );
  MenuItem{3} = javax.swing.JMenuItem( 'Load Data/Thumbnails' );
  MenuItem{4} = javax.swing.JMenuItem( 'Delete Node' );
  MenuItem{5} = javax.swing.JMenuItem( 'Rename' );

  % Add all menu items to the context menu (with internal separator)
  jMenu = javax.swing.JPopupMenu;
  jMenu.add(MenuItem{1});
  jMenu.addSeparator;
  jMenu.add(MenuItem{2});
  jMenu.add(MenuItem{3});
  jMenu.addSeparator;
  jMenu.add(MenuItem{4});
  jMenu.add(MenuItem{5});
  
  set( handle(TREE.getTree,'CallbackProperties') , 'MousePressedCallback', @(h,e)MousePressed(e) );

  try
    placetree();
  catch LE, storeERROR( hFig , LE );
  end
  %ExpandAll( root ); CollapseMultiples( TREE , root );
  %set( TREE ,'NodeCollapsedCallback' , @(h,e)CollapsedNode(e) );
  TREE.expand( root );
%   set( TREE ,'NodeExpandedCallback',@(h,e)filterTree );
  ExpandedCallback = get( TREE ,'NodeExpandedCallback' );
  set( TREE ,'NodeExpandedCallback' , ExpandedCallback );
  
  set( hFilter , 'Callback', @(h,e)NodeSelectedFcn() );
  LastSelectNode = 'D';
  NodeSelectedFcn();
  set( findall( hFig , 'Interruptible','off'    ) , 'Interruptible' , 'on'    );
  set( findall( hFig , 'BusyAction'   ,'cancel' ) , 'BusyAction'    , 'queue' );
  set( hFig , 'HandleVisibility','off');
  
  function MousePressed( ev )
    if     ev.getClickCount == 1 && ev.getButton == 1, return; end
    [ NODE , xy ] = getPressedNODE( ev );
    if isempty( NODE ), return;  end
    if     ev.getClickCount == 2 && ev.getButton == 1, ExpandAll( NODE );
    elseif ev.getClickCount == 2 && ev.getButton == 3, recursiveCollapseParent( NODE );
    elseif ev.getClickCount == 1 && ev.isMetaDown,     showContentMenu( NODE , xy , ev );
    end
  end
  function [ NODE , xy ] = getPressedNODE( ev )
    NODE = []; xy = [];
    try
      xy = [ ev.getX , ev.getY ];
      treePath = ev.getSource.getPathForLocation( xy(1) , xy(2) );
      if isempty( treePath ), return; end
      NODE = treePath.getLastPathComponent;
      TREE.setSelectedNode( NODE );
    catch LE, storeERROR( hFig , LE );
    end
  end
  function recursiveCollapseParent( NODE )
    try
      NODE = NODE.getParent;
      for child = 1:NODE.getChildCount
        TREE.collapse( NODE.getChildAt(child-1) );
      end
    catch LE, storeERROR( hFig , LE );
    end
  end
  function showContentMenu( NODE , xy , ev )
    try
      node = char( NODE.getValue );
      thisD = eval(node);
      
      % Modify the context menu or some other element based on the clicked node
      MenuItem{1}.setLabel( [ '<html><b>' , [ VarName , node(2:end) ] , '</b></html>' ] );
      if isfield( thisD , 'zThumbnail' ) && ~isempty( thisD.zThumbnail )
        MenuItem{3}.setLabel( '<html><font bgcolor="#FFFF00"><b><font bgcolor="#FFFF00" color="#0000FF">Re-</font></b>Load Data/Thumbnails</font></html>' );
        REDO = true;
      else
        MenuItem{3}.setLabel( 'Load Data/Thumbnails' );
        REDO = false;
      end
      MenuItem{2}.setEnabled( DCMread( thisD , 'CHECKonly' ) );
      
      set( handle(MenuItem{1},'CallbackProperties') , 'ActionPerformedCallback',@(h,e) fprintf('%s\n\n',[ VarName , node(2:end) ]) );
      set( handle(MenuItem{2},'CallbackProperties') , 'ActionPerformedCallback',@(h,e) callReadNode( NODE ) );
      %set( handle(MenuItem{3},'CallbackProperties') , 'ActionPerformedCallback',@(h,e) CallToMakeThumbnail( node(3:end) , 128 ) );
      set( handle(MenuItem{3},'CallbackProperties') , 'ActionPerformedCallback',@(h,e) callMakeThumbnail( NODE , 'default' , REDO ) );
      set( handle(MenuItem{4},'CallbackProperties') , 'ActionPerformedCallback',@(h,e) callDeleteNode( NODE ) );
      set( handle(MenuItem{5},'CallbackProperties') , 'ActionPerformedCallback',@(h,e) callRenameNode( NODE , xy + [20 0] , ev ) );
      
      
      jMenu.show( ev.getSource , xy(1) + 20 , xy(2) );
      jMenu.repaint;
    catch LE, storeERROR( hFig , LE );
    end
  end
  function callReadNode( NODE )
    node = char( NODE.getValue );
    thisD = eval( node );
    try
      tempVarName = genvarname( char(round(rand(1,40)*('Z'-'A'))+'A') , evalin('base','who') );
      evalin( 'base' , [ tempVarName , ' = [];' ] );
      CLEANUP = onCleanup( @()evalin( 'base' , [ 'try, clearvars(''' , tempVarName , '''); end' ] ) );

      proposedName = [];
      if isempty( proposedName ), try, proposedName = thisD.zPatientID;          end; end
      if isempty( proposedName ), try, proposedName = thisD.zStudyDescription;   end; end
      if isempty( proposedName ), try, proposedName = thisD.zSeriesDescription;  end; end
      if isempty( proposedName ), try, proposedName = thisD.Position_001.IMAGE_001.INFO.SeriesDescription;  end; end
      if isempty( proposedName ), try, proposedName = thisD.Position_001.IMAGE_001.info.SeriesDescription;  end; end
      if isempty( proposedName ), try
          if isempty( proposedName ), try, proposedName = dicominfo( thisD.Position_001.IMAGE_001.zFilename );       end; end
          if isempty( proposedName ), try, proposedName = dicominfo( thisD.Position_001.IMAGE_001.INFO.FileName );   end; end
          if isempty( proposedName ), try, proposedName = dicominfo( fullfile( thisD.Position_001.IMAGE_001.INFO.zDirname , thisD.Position_001.IMAGE_001.INFO.zFilename ) );  end; end
          if isempty( proposedName ), try, proposedName = dicominfo( fullfile( thisD.Position_001.IMAGE_001.INFO.xDirname , thisD.Position_001.IMAGE_001.INFO.xFilename ) );  end; end
          if isempty( proposedName ), try, proposedName = dicominfo( thisD.IMAGE_001.zFilename );       end; end
          if isempty( proposedName ), try, proposedName = dicominfo( thisD.IMAGE_001.INFO.FileName );   end; end
          if isempty( proposedName ), try, proposedName = dicominfo( fullfile( thisD.IMAGE_001.INFO.zDirname , thisD.IMAGE_001.INFO.zFilename ) );  end; end
          if isempty( proposedName ), try, proposedName = dicominfo( fullfile( thisD.IMAGE_001.INFO.xDirname , thisD.IMAGE_001.INFO.xFilename ) );  end; end
          if isempty( proposedName ), try, proposedName = dicominfo( thisD.zFilename );       end; end
          if isempty( proposedName ), try, proposedName = dicominfo( thisD.INFO.FileName );   end; end
          if isempty( proposedName ), try, proposedName = dicominfo( fullfile( thisD.INFO.zDirname , thisD.INFO.zFilename ) );  end; end
          if isempty( proposedName ), try, proposedName = dicominfo( fullfile( thisD.INFO.xDirname , thisD.INFO.xFilename ) );  end; end
          proposedName = proposedName.SeriesDescription;
      end; end
      if isempty( proposedName ), try, proposedName = 'dicomIMAGE';           end; end
      proposedName = genvarname( proposedName , evalin('base','who') );
      
      proposedName = inputdlg( 'Enter name of new variable                                                    .' , 'In ''base''workspace' , 1 , { proposedName } , struct('Resize','off','WindowStyle','modal') );
      proposedName = proposedName{1};
      if isempty( proposedName ) || ~ischar( proposedName )
        fprintf(2,'No variable specified by the user\n');
        return;
      end
      
      %[I,s] = DCMload( thisD );
      I = DCMread( thisD );
      assignin( 'base' , tempVarName , I );
      evalin( 'base' , [ proposedName , ' = ' , tempVarName , ';' ] );
      evalin( 'base' , [ 'disp( ' , proposedName , ' );' ] );
      
    catch
      fprintf(2,'error loading DCM: try,  DCMread( %s )\n', [ VarName , node(2:end) ]);
    end
  end
  function callMakeThumbnail( NODE , sz , REDO )
    if nargin < 2, sz = 'default'; end
    node = char( NODE.getValue );
    
    D = DCMthumbnail( D , sz , node(3:end) , REDO );
    if EditInBase, assignin('base', VarName , D ); end

    NodeSelectedFcn( [] );
  end
  function callDeleteNode( NODE )
    node   = char( NODE.getValue );
    PARENT = NODE.getParent;
    parent = char( PARENT.getValue );

    TREE.setSelectedNode( PARENT );
    TREE.getModel.removeNodeFromParent( NODE );

    eval( sprintf( '%s = rmfield( %s , ''%s'' );' , parent , parent , substring( node , '.' , -1 ) ) );
    if EditInBase, assignin('base', VarName , D ); end

    F = substring( parent , '.' , -1 );
    if isempty( F ), return; end
    
    PA = eval( substring( parent , '.' , [1,-2]) );
    [ NODEtext , NODEicon , NumberOfChildren ] = NodeText( F , PA.(F) );
    
    if ~NumberOfChildren
      callDeleteNode( PARENT );
    else
      PARENT.setName( NODEtext );
      TREE.setSelectedNode( PARENT );
      NodeSelectedFcn( PARENT );
      try, TREE.repaint(); end
    end
  end
  function callRenameNode( NODE , xy , ev )
    oldNodeSelectedCallback = get( TREE , 'NodeSelectedCallback' );                                       set( TREE , 'NodeSelectedCallback' , @(h,e)TREE.setSelectedNode( NODE ) );
    oldMousePressedCallback = get( handle(TREE.getTree,'CallbackProperties') , 'MousePressedCallback' );  set( handle(TREE.getTree,'CallbackProperties') , 'MousePressedCallback' , '' );

    newNAME = '';
    node = char( NODE.getValue );
    parent = substring( node , '.' , [1,-2] );
    PA = eval( parent );
    oldNAME = substring( node , '.' , -1 );
    nodeTYPE = [ substring( oldNAME , '_' , 1 ) , '_' ];

    colorBAD = java.awt.Color(1,0.3,0.3);
    colorOK  = java.awt.Color(0.7,0.7,1);

    jED = javax.swing.JTextField( oldNAME );
    ev.getSource.add( jED );
    jED.setLocation( xy(1) , xy(2)-20 );
    jED.setSize( 250 , 40 );
    jED.setBackground( colorOK );
    jED.setFont( java.awt.Font('Arial',1,18) );
    jED.requestFocus(); drawnow();
    jED.setSelectionStart( numel( nodeTYPE ) );
    jED.setSelectionEnd( numel( oldNAME ) );
    set( handle( jED , 'CallbackProperties' ) , 'KeyPressedCallback' , @(j,e)CheckNewName( e ) );

    set( hFig , 'UserData' , [] );
    try
      waitfor( hFig , 'UserData' );
    catch LE, storeERROR( hFig , LE );
    end

    try
      set( TREE , 'NodeSelectedCallback' , oldNodeSelectedCallback );
    catch LE, storeERROR( hFig , LE );
    end
    try
      set( handle(TREE.getTree,'CallbackProperties') , 'MousePressedCallback' , oldMousePressedCallback  );
    catch LE, storeERROR( hFig , LE );
    end
    try
      ev.getSource.requestFocus();
    catch LE, storeERROR( hFig , LE );
    end
    
    try
      newNAME = char( jED.getText );
      if ~isequal( get( jED , 'Background' ) , colorOK ), newNAME = ''; end
    catch LE, storeERROR( hFig , LE );
    end
    ev.getSource.remove( jED );
    ev.getSource.repaint();
    
    if isempty( newNAME ) || isequal( newNAME , oldNAME ), return; end
    
    eval( sprintf( '%s = renameStructField( %s , ''%s'' , ''%s'' );' , parent , parent , oldNAME , newNAME ) );
    if EditInBase, assignin('base', VarName , D ); end

    PA = eval( parent );
    NODEtext = NodeText( newNAME , PA.(newNAME) );
    
    NODE.setName( NODEtext );
    NODE.setValue( [ parent , '.' , newNAME ] );
    TREE.repaint();
 
    function CheckNewName( ev )
      if     isequal( ev.getKeyCode , 10 ),  set( hFig , 'UserData' , 1 ); return;
      elseif isequal( ev.getKeyCode , 27 ),  set( hFig , 'UserData' , 1 ); return;
      end
      
      tmpNAME = char( jED.getText );
      if     isequal( tmpNAME , oldNAME )
        jED.setBackground( colorOK );
      elseif isfield( PA , tmpNAME )
        jED.setBackground( colorBAD );
      elseif ~strncmp( tmpNAME , nodeTYPE , numel(nodeTYPE) )
        jED.setBackground( colorBAD );
      elseif numel( tmpNAME ) > 63
        jED.setBackground( colorBAD );
      elseif ~isempty( regexp( tmpNAME , '[^a-zA-Z0-9_]' ,'once' ) )
        jED.setBackground( colorBAD );
      else
        jED.setBackground( colorOK );
      end
    end    
  end

  function NodeSelectedFcn( NODE )
    try
      if nargin < 1 || isempty( NODE ), NODE = LastSelectNode; end
      LastSelectNode = NODE;
      node = char( NODE.getValue );
    catch
      return;
    end
    try
      FILTER = get( hFilter , 'string' );
      jFullInfo.setText( FullInfoText( node , FILTER ) );

      if ~nargin, return; end

      type = substring( substring( node , '.' , -1 ) , '_' , 1 );
      try
        thisD = eval( node );
      catch
        return;
      end
      
      jNodeInfo.setText( NodeInfoText( thisD ) );

      I = getImage( thisD , node );
        
      set( uiPLAYER_panel , 'Visible','off' );
      PLAYER_PLAY_PAUSE( 0 );
      if isempty(I)
        set( hImage , 'Visible','off'); %drawnow expose;
      else
        set( hImageAxe , 'xlim' , 0.5 + [0 , size(I,2)] , 'ylim' , 0.5 + [0 , size(I,1)] );
        try,   set( hImageAxe , 'clim' , prctile( I(:) , [5 95] ) );
        catch, set( hImageAxe , 'clim' , [0 1] );
        end
        set( hImage , 'Visible','on');
        nT = size(I,4);
        set( PLAYER , 'Callback' , @(t)setT(t) , 'Elements' , 1:nT );
        if nT > 1
          set( uiPLAYER_panel , 'Visible','on'  );
          PLAYER_SET_SPEED( min( 25 , size(I,4) ) );

          PLAYER_PLAY_PAUSE( 1 );
        end
        setT(1);
      end
      
      
      if ishandle( hNAV )
        II = [];
        if size( I ,4) < 2, II = I; end
        try, DCMexplorer_navigator(thisD,hNAV,II); end
      end
      
      if ~isempty( FCN )
        try, feval( FCN , thisD ); end
      end
      
      if showOVERLAY
        if strcmp( type , 'IMAGE' )
          try, DCMexplorer_overlay( eval( [ node , '.info' ] ) , hImageAxe ); end
        else
          try, DCMexplorer_overlay( [] , hImageAxe ); end
        end
      end
      
      if ~isempty( imageFCN )
        if strcmp( type , 'IMAGE' )
          try, feval( imageFCN , eval( [ node , '.info' ] ) , hImageAxe ); catch
          try, feval( imageFCN , eval( [ node , '.info' ] ) ); 
          end; end
        else
          try, feval( imageFCN , [] , hImageAxe ); catch
          try, feval( imageFCN , [] ); end
          end
        end
      end
    catch LE, storeERROR( hFig , LE );
    end

    function setT( t )
      set( hImage , 'CData',I(:,:,:,t) );
      set( uiPLAYER_edit , 'String', sprintf('%d of %d',t,nT) );
      set( uiPLAYER_slider , 'Value' , t );
    end
    
  end

  function str = FullInfoText( node , FILTER )
    str = '<html>';
    try
      str = [ str , '<table border="1" cellspacing="0" width="95%" cellpadding="0">' ];
      while 1
        type = substring( substring( node , '.' , -1 ) , '_' , 1 );
        try, thisD = eval( node ); catch, return; end
        switch type
          case 'IMAGE'
            color = '#000000';
            str = [ str , sprintf( '<tr><th align="left" colspan="2"><font color="%s">&nbsp;INFO in the IMAGE</font></th>' , color ) ];
          case 'Position'
            color = '#FF00FF';
            str = [ str , sprintf( '<tr><th align="left" colspan="2"><font color="%s">&nbsp;comon INFO in Position</font></th>' , color ) ];
          case 'Orientation'
            color = '#A52A2A';
            str = [ str , sprintf( '<tr><th align="left" colspan="2"><font color="%s">&nbsp;comon INFO in Orientation</font></th>' , color ) ];
          case 'Serie'
            color = '#0000FF';
            str = [ str , sprintf( '<tr><th align="left" colspan="2"><font color="%s">&nbsp;comon INFO in Serie</font></th>' , color ) ];
          case 'Study'
            color = '#008000';
            str = [ str , sprintf( '<tr><th align="left" colspan="2"><font color="%s">&nbsp;comon INFO in Study</font></th>' , color ) ];
          case 'Patient'
            color = '#FF0000';
            str = [ str , sprintf( '<tr><th align="left" colspan="2"><font color="%s">&nbsp;comon INFO in Patient</font></th>' , color ) ];
          case 'D'
            color = '#000000';
            str = [ str , sprintf( '<tr><th align="left" colspan="2"><font color="%s">&nbsp;comon INFO</font></th>' , color ) ];
        end
        F = {};
        try, F = fieldnames(thisD.INFO); end
        if isempty( F )
          try
            F = fieldnames(thisD.info);
            thisD.INFO = thisD.info;
          end
        end
        for f = 1:numel(F)
          if ~isempty(FILTER) && isempty( regexpi( F{f} , FILTER ,'once' ) ), continue; end
          if F{f}(1) == 'z' || F{f}(1) == 'x'
            str = [ str ,...
              sprintf( '<tr><td align="right"><font color="%s"><i>%s</i></font>&nbsp </td><td align="left">&nbsp <i>%s</i></td></tr>' , color , F{f} , value2string( thisD.INFO.(F{f}) ) ) ];
          else
            str = [ str ,...
              sprintf( '<tr><td align="right"><font color="%s"><b>%s</b></font>&nbsp </td><td align="left">&nbsp %s</td></tr>' , color , F{f} , value2string( thisD.INFO.(F{f}) ) ) ];
          end
        end
        
        node = substring( node , '.' , [1,-2] );
        if isempty( node ), break; end
      end
      str = [ str , '<tr><td colspan="2"></td></tr>' ];
      str = [ str , '</table>' ];
    catch LE, storeERROR( hFig , LE );
    end
    str = [ str , '</html>' ];
  end
  function str = NodeInfoText( thisD )
    str = '<html>';
    try
        str = [ str , '<table border="0" width="95%" cellpadding="1">' ];
        F = fieldnames(thisD); F = [ setdiff( F(:) , 'zzKEY' ) ; 'zzKEY' ];
        for f = 1:numel(F), try
          if F{f}(1) ~= 'z', continue; end
          str = [ str ,...
            sprintf( '<tr><td align="right"><b>%s:</b></td><td align="left">%s</td></tr>' , F{f} , value2string( thisD.(F{f}) ) ) ];
        end; end
        str = [ str , '</table>'];
    catch LE, storeERROR( hFig , LE );
    end
    str = [ str , '</html>' ];
  end
  function I = getImage( DD , node )
    type = substring( substring( node , '.' , -1 ) , '_' , 1 );
    I = [];
    if     isfield( DD , 'DATA' ) && ~isempty( DD.DATA )
      I = DD.DATA;
    elseif isfield( DD , 'zThumbnail' ) && ~isempty( DD.zThumbnail )
      I = DD.zThumbnail;
    elseif isfield( DD , 'zDirname' ) && isfield( DD , 'zFilename' )
      try, I = dicomread( fullfile( DD.zDirname , DD.zFilename ) ); end
      try, eval( [ node , '.zThumbnail = I;' ] ); end
    elseif isfield( DD , 'zFileName' )
      try, I = dicomread( DD.zFileName ); end
      try, eval( [ node , '.zThumbnail = I;' ] ); end
    elseif strcmp( type , 'IMAGE' ) && isfield( DD , 'INFO' ) && isfield( DD.INFO , 'Filename' )
      try, I = dicomread( DD.INFO.Filename ); end
      try, eval( [ node , '.zThumbnail = I;' ] ); end
    elseif strcmp( type , 'IMAGE' ) && isfield( DD , 'info' ) && isfield( DD.info , 'Filename' )
      try, I = dicomread( DD.INFO.Filename ); end
      try, eval( [ node , '.zThumbnail = I;' ] ); end
    else
      switch type
        case 'Position',      F = fieldnames( DD ); F = F( strncmp( F , 'IMAGE_'       , 6  ) );
        case 'Orientation',   F = fieldnames( DD ); F = F( strncmp( F , 'Position_'    , 9  ) );
        case 'Serie',         F = fieldnames( DD ); F = F( strncmp( F , 'Orientation_' , 12 ) );
        case 'Study',         F = fieldnames( DD ); F = F( strncmp( F , 'Serie_'       , 6  ) );
        case 'Patient',       F = fieldnames( DD ); F = F( strncmp( F , 'Study_'       , 6  ) );
        case 'D',             F = fieldnames( DD ); F = F( strncmp( F , 'Patient_'     , 8  ) );
      end
      if numel(F) == 1
        DD    = DD.(F{1});
        node  = [ node , '.' , F{1} ];
        I     = getImage( DD , node );
        if ~isempty( I ), return; end
      end
    end
    if ~isempty( I )
      if  isinteger( I ) && size( I , 3 ) == 3
        I = double( I )/255;
      end
      I = double(I);
      if max( I(:) ) > 1
        I = I - min( I(:) );
        I = I / max( I(:) );
      end
    end
  end

  function NODES = createNewNodes( node )
    thisD = eval( node );
    NODES = {};
    
    F = {}; try, F = fieldnames(thisD); end
    F( strncmp( F , 'z' , 1 ) ) = [];
    F( strcmp(  F , 'INFO'  ) ) = [];
    F( strcmp(  F , 'CONFLICT'  ) ) = [];
    for f = 1:numel(F)
      if SUPERCOMPACT && numel(F) == 1 && strncmp( F{f} , 'Orientation_' , 12 )
        NN = createNewNodes( [ node , '.' , F{f} ] );
        for nn = 1:numel(NN), NODES{end+1} = NN(nn); end
      elseif SUPERCOMPACT && numel(F) == 1 && strncmp( F{f} , 'Position_' , 9 )
        NN = createNewNodes( [ node , '.' , F{f} ] );
        for nn = 1:numel(NN), NODES{end+1} = NN(nn); end
      else
        try
          [NODEtext, NODEicon, NumberOfChildren] = NodeText( F{f} , thisD.(F{f}) );
          
          NODES{end+1} = uitreenode( 'v0' , [ node , '.' , F{f} ] , NODEtext , NODEicon , ~NumberOfChildren );
        catch LE
          disperror( LE );
        end
      end
    end
    NODES = cat(1, NODES{:} );
    if numel( NODES ) == 1
      TREE.expand(NODES); drawnow();
    end
  end
  function [NODEtext, NODEicon, NumberOfChildren] = NodeText( node , thisD )
    
    NODEtext = '<html>';
    NODEicon = '';
    NumberOfChildren = 0;
    NODEtype = '';
    if     strncmp( node , 'Patient_'     , 8  )
      NODEtype = 'Patient';
      NODEicon = fullfile(matlabroot,'/toolbox/matlab/icons/','pageicon.gif'); %HDF_VGroup.gif
      NumberOfChildren = sum( strncmp( fieldnames( thisD ) , 'Study_' , 6 ) );
      try, NODEtext = [ NODEtext , '<b><font family="Monospace" color="#000000" bgcolor="#C0C0C0" size=4>&nbsp;' , NumberOfChildren_text( thisD , node ) , '&nbsp;</font></b>&nbsp;' ]; end
           NODEtext = [ NODEtext ,            '<b><font Color="#FF0000" size=5>' , node        ,'</font></b>'];
      try, NODEtext = [ NODEtext , '&#8212;' ,'<b><font color="#808080">'        , thisD.zPatientID   ,'</font></b>']; end
      try, NODEtext = [ NODEtext , '&#8212;' ,   '<font color="#D3D3D3">'        , thisD.zPatientName ,'</font>'    ]; end
      try, NODEtext = [ NODEtext , '<!--' , thisD.zFamilyName ,  '-->' ]; end

    elseif strncmp( node , 'Study_'       , 6  )
      NODEtype = 'Study';
      NODEicon = fullfile(matlabroot,'/toolbox/matlab/icons/','tool_text.gif');
      NumberOfChildren = sum( strncmp( fieldnames( thisD ) , 'Serie_' , 6 ) );
      try, NODEtext = [ NODEtext , '<b><font family="Monospace" color="#000000" bgcolor="#C0C0C0" size=4>&nbsp;' , NumberOfChildren_text( thisD , node ) , '&nbsp;</font></b>&nbsp;' ]; end
           NODEtext = [ NODEtext ,            '<b><font Color="#008000" size=5>' , node              ,'</font></b>'];
      try, NODEtext = [ NODEtext , '&#8212;' ,'<b><font color="#808080">'        , thisD.zStudyDescription  ,'</font></b>']; end
      try, NODEtext = [ NODEtext , '&#8212;' ,'<b><font color="#808080">('       , thisD.zStudyDate       ,')</font></b>']; end
      try, NODEtext = [ NODEtext , '<!--' , thisD.zStudyInstanceUID ,  '-->' ]; end

    elseif strncmp( node , 'Serie_'       , 6  )
      NODEtype = 'Serie';
      NODEicon = fullfile(matlabroot,'/toolbox/matlab/icons/','tool_align.gif');
      NumberOfChildren = sum( strncmp( fieldnames( thisD ) , 'Orientation_' , 12 ) );
      try, NODEtext = [ NODEtext , '<b><font family="Monospace" color="#000000" bgcolor="#C0C0C0" size=4>&nbsp;' ,  NumberOfChildren_text( thisD , node ) , '&nbsp;</font></b>&nbsp;' ]; end
           NODEtext = [ NODEtext ,            '<b><font Color="#0000FF" size=5>' , node               ,'</font></b>'];
      try, NODEtext = [ NODEtext , '&#8212;' ,'<b><font color="#808080">'        , thisD.zSeriesDescription  ,'</font></b>']; end
      try, NODEtext = [ NODEtext , '&#8212;' ,'<b><font color="#808080">'        , thisD.zModality           ,'</font></b>']; end
      try, NODEtext = [ NODEtext , '&#8212;' ,'<b><font color="#808080">('       , thisD.zSeriesTime(1:8)   ,')</font></b>']; end
      try, NODEtext = [ NODEtext , '<!--' , thisD.zSeriesInstanceUID ,  '-->' ]; end

    elseif strncmp( node , 'Orientation_' , 12 )
      NODEtype = 'Orientation';
      NODEicon = fullfile(matlabroot,'/toolbox/matlab/icons/','HDF_object01.gif'); %'tool_rotate_3d.gif'
      NumberOfChildren = sum( strncmp( fieldnames( thisD ) , 'Position_' , 9 ) );
      try, NODEtext = [ NODEtext , '<b><font family="Monospace" color="#000000" bgcolor="#C0C0C0" size=4>&nbsp;' , NumberOfChildren_text( thisD , node ) , '&nbsp;</font></b>&nbsp;' ]; end
           NODEtext = [ NODEtext ,            '<b><font Color="#A52A2A" size=5>' , node          ,'</font></b>'];
      try
        if numel( thisD.zSize ) == 4
          NODEtext = [ NODEtext , '&#8212' ,'<b><font color="#A52A2A">'        , sizestr( thisD.zSize ) ,'</font></b>'];
        else
          NODEtext = [ NODEtext , '&#8212' ,'<b><font color="#A0A0A0">'        , sizestr( thisD.zSize ) ,'</font></b>'];
        end
      catch
        NODEtext = [ NODEtext , '&#8212' ,'<b><font color="#A0A0A0">'        , '(no size)' ,'</font></b>'];
      end

    elseif strncmp( node , 'Position_'    , 9  )
      NODEtype = 'Position';
      NODEicon = fullfile(matlabroot,'/toolbox/matlab/icons/','tool_text_align_justify.png');
      NumberOfChildren = sum( strncmp( fieldnames( thisD ) , 'IMAGE_' , 6 ) );
      try, NODEtext = [ NODEtext , '<b><font family="Monospace" color="#000000" bgcolor="#C0C0C0" size=4>&nbsp;' , NumberOfChildren_text( thisD , node ) , '&nbsp;</font></b>&nbsp;' ]; end
           NODEtext = [ NODEtext ,            '<b><font Color="#FF00FF" size=4>' , node ,'</font></b>'];

    elseif strncmp( node , 'IMAGE_'       , 6  )
      NODEtype = 'IMAGE';
      NODEicon = ''; %NODEicon = fullfile(matlabroot,'/toolbox/matlab/icons/','tool_font_italic.png');
           NODEtext = [ NODEtext ,            '<b><font Color="#000000" size=2>&nbsp;&nbsp;' , node ,'&nbsp;&nbsp;</b></font>'];
      try, NODEtext = [ NODEtext , '&#8212' ,    '<font color="#404040" size=2>' , sizestr( thisD.zSize ) ,'</font>']; end
      try, NODEtext = [ NODEtext , '&#8212' , '<i><font color="#707070" size=2>"' , fullfile( thisD.zDirname , thisD.zFilename )  ,'"</font></i>']; end
      try, NODEtext = [ NODEtext , '<!--' , thisD.zMediaStorageSOPInstanceUID ,  '-->' ]; end

    else
      error('no node');
    end
    NODEtext = [ NODEtext , '</html>' ];
    try, if ~isempty( NODEicon ) && ~isfile( NODEicon , 'fast' ), NODEicon = ''; end; end
    
    if COMPACT && NumberOfChildren == 1
      if strcmp( NODEtype , 'Position' )
        F = fieldnames( thisD ); F = F( strncmp( F , 'IMAGE_' , 6 ) );
        
        [Ctext, Cicon, NumberOfChildren] = NodeText( F{1} , thisD.(F{1}) );
%         if ~isempty( Cicon ), NODEicon = Cicon; end
        NODEtext = [ NODEtext , Ctext ];
        NODEtext = strrep( NODEtext , '</html><html>' , '' );

      elseif strcmp( NODEtype , 'Orientation' )
        
        F = fieldnames( thisD ); F = F( strncmp( F , 'Position_' , 9 ) );
        if numel( F ) > 1, return; end
        
        [Ctext, Cicon, CNumberOfChildren] = NodeText( F{1} , thisD.(F{1}) );
        if CNumberOfChildren > 1, return; end
%         if ~isempty( Cicon ), NODEicon = Cicon; end
        NODEtext = regexprep( NODEtext , '&#8212.*\</b>' , '' );
        Ctext = strrep( Ctext , '<b><font family="Monospace" color="#000000" bgcolor="#C0C0C0" size=4>&nbsp;1&nbsp;</font></b>&nbsp;' , '' );
        
        NODEtext = [ NODEtext , Ctext ];
        NODEtext = strrep( NODEtext , '</html><html>' , '' );
        
        NumberOfChildren = CNumberOfChildren;
      end
    end
    
  end
  function ExpandAll( NODE )
%     node = char( NODE.getValue );
%     type = substring( substring( node , '.' , -1 ) , '_' , 1 );
%     if strcmp( type , 'Serie' )
% %       if TREE.Tree.isCollapsed( javax.swing.tree.TreePath(NODE.getParent.getPath) )
%         return;
% %       end
%     end
    
    TREE.expand(NODE); drawnow();
    for c = 1:NODE.getChildCount
      CHILD = NODE.getChildAt(c-1);
      child = char( CHILD.getValue );
      type = substring( substring( child , '.' , -1 ) , '_' , 1 );
      if strcmp( type , 'IMAGE' )
        return;
      end
      if ~strcmp( type , 'Serie' )
        ExpandAll( CHILD );
      end
    end
  end
  function CollapseMultiples( TREE , NODE )
    nChildren = NODE.getChildCount;
    for nn = 1:nChildren
      CollapseMultiples( TREE , NODE.getChildAt(nn-1) );
    end
    if nChildren > 1, TREE.collapse(NODE); end
  end
  function placetree(varargin)
    try
      set( hTreePanel ,'units','pixels');
      pos = get( hTreePanel , 'position');
      set(TREE,'units','pixels','Position', pos+[2 22 -4 -4-22] );
    catch LE, %storeERROR( hFig , LE );
    end
  end
  function filterTree
    FILTER = get( hTreeFilter , 'string' );
    FILTERNODE( root );
    TREE.repaint;

    function FILTERNODE( NODE )
      node = char( NODE.getName );
      if ~isempty( regexpi( node , FILTER , 'once' ) )
        NODE.setName( strrep( node , '<font Color=' , '<font bgcolor="#FFFF00" color=' ) );
      else
        NODE.setName( strrep( node , '<font bgcolor="#FFFF00" color=' , '<font Color=' ) );
      end
      for child = 1:NODE.getChildCount
        FILTERNODE( NODE.getChildAt(child-1) );
      end
    end
  end

end

function s = sizestr( s )
  s = sprintf( '%d x ' , s ); s = s(1:end-3);
end
function str = value2string(v)
  switch class(v)
    case 'char',
      if     numel(v)==1,   str = v;
      elseif isempty(v),    str = '<font color="#808080"><i>empty char</i></font>';
      elseif numel(v)>=1000, str = sprintf('<font color="#808080"><i>&lt;%s&gt; too long. size: %s</i></font>', class(v) , sizestr(size(v)) );
      elseif isrow(v),      str = [ '"'  , v , '"' ];
      elseif iscolumn(v),   str = [ '[ ' , v , ' ]''' ];
      elseif numel(v)<100,  str = uneval( v );
      else,                 str = sprintf('<font color="#808080"><i>&lt;%s&gt; too long. size: %s</i></font>', class(v) , sizestr(size(v)) );
      end

    case {'double'}
      if     numel(v)==1,   str = number2str(v,1);
      elseif isempty(v),    str = '<font color="#808080"><i>empty double</i></font>';
      elseif numel(v)>=100, str = sprintf('<font color="#808080"><i>&lt;%s&gt; too long. size: %s</i></font>', class(v) , sizestr(size(v)) );
      elseif isrow(v),      str = '['; for x=v(:).', str = [ str , ' ' , number2str(x,1) , ' ,' ]; end; str = [ str(1:end-1) , ' ]' ];
      elseif iscolumn(v),   str = '['; for x=v(:).', str = [ str , ' ' , number2str(x,1) , ' ;' ]; end; str = [ str(1:end-1) , ' ]' ];
      elseif numel(v)<100,  str = uneval( v );
      else,                 str = sprintf('<font color="#808080"><i>&lt;%s&gt; too long. size: %s</i></font>', class(v) , sizestr(size(v)) );
      end

    case {'single','uint32','int32','uint16','int16','uint8','int8'}
      if     numel(v)==1,   str = sprintf('&lt;%s&gt; %s',class(v),number2str(v,1));
      elseif isempty(v),    str = sprintf('<font color="#808080"><i>empty &lt;%s&gt;</i></font>',class(v));
      elseif numel(v)>=100, str = sprintf('<font color="#808080"><i>&lt;%s&gt; too long. size: %s</i></font>', class(v) , sizestr(size(v)) );
      elseif isrow(v),      str = sprintf('&lt;%s&gt; [',class(v)); for x=v(:).', str = [ str , ' ' , number2str(x,1) , ' ,' ]; end; str = [ str(1:end-1) , ' ]' ];
      elseif iscolumn(v),   str = sprintf('&lt;%s&gt; [',class(v)); for x=v(:).', str = [ str , ' ' , number2str(x,1) , ' ;' ]; end; str = [ str(1:end-1) , ' ]' ];
      elseif numel(v)<100,  str = uneval( v );
      else,                 str = sprintf('<font color="#808080"><i>&lt;%s&gt; too long. size: %s</i></font>', class(v) , sizestr(size(v)) );
      end

    otherwise,     str = sprintf('<font color="#808080"><i>content of class &lt;%s&gt; cannot be displayed here</i></font>',class(v));
  end
end    
function storeERROR( hFig , LE )
  try
    setappdata( hFig , 'LastERROR' , LE );
    fprintf('an ERROR occured at: %s   <a href="matlab:rethrow( getappdata(%s,''LastERROR'') )" style="font-weight:bold">see it</a>\n', datestr( now , 'HH:MM:SS.FFF' ) , double2str( hFig ) );
  end
end
function n = string2number(s)
  n = str2double(s);
  if ~isnan(n), return; end
  s = regexp(s,'^[^0-9]*([+-]?(?:[0-9]+\.?[0-9]*|[0-9]*\.?[0-9]+)(?:[eE][+-]?[0-9]+)?)','tokens','once');
  if isempty( s ), return; end
  n = str2double( s{1} );
end
function x = rPos( h )
  x = get(h,'Position');
  x=x(1)+x(3);
end
function str = substring( str , sep , idx )
  seps = [ 0 , find( str == sep ) , numel( str ) + 1 ];
  idx( idx <= 0 ) = numel( seps ) + idx( idx <= 0 );
  str = str( seps(idx(1))+1:seps(idx(end)+1)-1 );
end
function safe_delete( h )
  if ishandle( h )
    try, delete( h ); end
  end
end
function str = NumberOfChildren_text( D , node )
  C = fieldnames( D );
  if     strncmp( node , 'Patient_'     , 8  )
    C = C( strncmp( fieldnames( D ) , 'Study_' , 6 ) );
    n = numel( C ); str = sprintf('%d',n);
  elseif strncmp( node , 'Study_'       , 6  )
    C = C( strncmp( fieldnames( D ) , 'Serie_' , 6 ) );
    n = numel( C ); str = sprintf('%d',n);
  elseif strncmp( node , 'Serie_'       , 6  )
    C = C( strncmp( fieldnames( D ) , 'Orientation_' , 12 ) );
    n = numel( C ); str = sprintf('%d',n);
    if n == 1, str = [ str , ',' , NumberOfChildren_text( D.(C{1}) , C{1} ) ]; end
  elseif strncmp( node , 'Orientation_' , 12  )
    C = C( strncmp( fieldnames( D ) , 'Position_' , 9 ) );
    n = numel( C ); str = sprintf('%d',n);
    N = {};
    for c = 1:n
      N{c} = NumberOfChildren_text( D.(C{c}) , C{c} );
    end
    if numel(unique( N )) == 1, str = [ str , ',' , N{1} ]; end
  elseif strncmp( node , 'Position_' , 9  )
    C = C( strncmp( fieldnames( D ) , 'IMAGE_' , 6 ) );
    n = numel( C ); str = sprintf('%d',n);
  end
end