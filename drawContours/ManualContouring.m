function C_ = ManualContouring( I , varargin )

  MODE = [];
  try, [varargin,~,MODE] = parseargs(varargin ,'mode','$DEFS$',MODE); end
  if isempty( MODE ), MODE = 'default'; end

  UNATTENDED = Inf;
  try, [varargin,~,UNATTENDED] = parseargs(varargin ,'UNATTENDED','$DEFS$',UNATTENDED); end
  
  MAX_RESOLUTION = 200;
  try, [varargin,~,MAX_RESOLUTION] = parseargs(varargin ,'RESolution','$DEFS$',MAX_RESOLUTION); end
  
  TEMPfile = [];
  try, [varargin,~,TEMPfile] = parseargs(varargin ,'TEMPfile','$DEFS$',TEMPfile); end
  if isempty( TEMPfile )
    TEMPfile = tmpname( 'ManualContouring_******.con' );
  end

  MANN = [];
  try, [varargin,~,MANN] = parseargs(varargin ,'MANNequin','$DEFS$',MANN); end

  MESHES = [];
  try, [varargin,~,MESHES] = parseargs(varargin ,'MESHES','$DEFS$',MESHES); end
  
  reDECORATE = [];
  try, [varargin,~,reDECORATE] = parseargs(varargin ,'reDECORATE','$DEFS$',reDECORATE); end
  
  C = I(:,1:min(end,11)); I = I(:,1);
  for h = 1:size(C,1)
    if isempty(C{h,1}), continue; end
    C{h,1}.data = [];
    C{h,1}.INFO = struct( 'MediaStorageSOPInstanceUID'  , DICOMxinfo( C{h,1}.INFO , 'MediaStorageSOPInstanceUID' ) ,...
                          'SeriesInstanceUID'           , DICOMxinfo( C{h,1}.INFO , 'SeriesInstanceUID' ) ,...
                          'xZLevel'                     , DICOMxinfo( C{h,1}.INFO , 'xZLevel' ) );
  end

  
  
  if strcmpi( MODE , 'heart' )
%     I = MaskHeart( I );
  end

  try,   SUBJECT_DIR = evalin('base', 'SUBJECT_DIR' );
  catch, SUBJECT_DIR = ''; end
  
  iconSz = 150;
  R = size( I ,1);
  
  hFig = figure('Toolbar','figure','CreateFcn','','Renderer','OpenGL','RendererMode','manual');
  colormap( hFig , gray(256) );


  set(hFig ,'Position'     , FullScreenPosition() + [ 50 75 -200 -150 ] ,...
            'Menu'         , 'none' ,...
            'Toolbar'      , 'none' ,...
            'Color'        , 'w'    ,...
            'NumberTitle'  , 'off'  ,...
            'Colormap'     , gray(256) ,...
            'Name'         , sprintf('( "%s" )\n' , SUBJECT_DIR ) ); drawnow();
  

  PROFILES      = [];
  ILS           = [];
  ILS3D         = [];
  SCS           = [];
  CCS           = [];
  PLANES        = [];
  CONTOURS      = [];
  MontageAXs    = [];
  MontageLINEs  = [];
          
  iconDir = tmpname( 'contouringIcons????\' , 'mkdir' );
  iconColor = zeros(R,3);
  for r = 1:R
    if isempty( I{r,1} ), continue; end
    iconFilename = generateIcon( [ { I{r,1}.t1 } , C(r,2:end) ] , iconSz , r );

    
    sn = 'noNumber';      try, sn = I{r,1}.INFO.SeriesNumber; end; if isnumeric(sn), sn = sprintf('%03d',sn); end
    sd = 'noDescription'; try, sd = I{r,1}.INFO.SeriesDescription; end
    iconName = sprintf('%s.%s', sn , sd );
    iconTooltip{r} = ['<html>' ,...
      '<div style="text-align:right"><b><font color="black" size="5">' , iconName ,...
      '<br><div style="text-align:right"><img src="file:///' , iconFilename , '">' ];
    
    if ~isfield( I{r,1}.INFO , 'PlaneName' ) ||...
        isempty( I{r,1}.INFO.PlaneName ) ||...
        strcmp( I{r,1}.INFO.PlaneName , '?' )
      iconColor(r,:) = [0.9,0.5,0.0];  iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><i>unknown view' ];
    else
      switch lower( I{r,1}.INFO.PlaneName )
        case {'cor'},        iconColor(r,:) = [1 0 1]*0.8;    iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><b>CORONAL view' ];
        case {'sag'},        iconColor(r,:) = [1 0.5 0.2];    iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><b>SAGITTAL view' ];
        case {'hla','hlax'}, iconColor(r,:) = [1 0 0]*0.8;    iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><b>HLA view' ];
        case {'vla','vlax'}, iconColor(r,:) = [0 1 0]*0.75;   iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><b>VLA view' ];
        case {'lvot','lvotx'}, iconColor(r,:) = [0 1 1]*.5;   iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><b>LVOT view' ];
        case {'sa','sax'},   iconColor(r,:) = [1 1 0]*.6;     iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><b>SA view' ];
        case {'ax'},         iconColor(r,:) = [0.2 0.2 1];    iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><b>AXIAL view' ];
        case {'rvlax'},      iconColor(r,:) = [0.2 0.2 1];    iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><b>RVLA view' ];
        otherwise,           iconColor(r,:) = [0.3,0.3,0.2];  iconTooltip{r} = [ iconTooltip{r} , '<br><div style="text-align:right"><font color="#FF0000" size="4"><i>' , I{r,1}.INFO.PlaneName , ' view' ];
      end
    end

    iconPrefix{r} = prefix( C(r,:) );

%     iconString{r}  = ['<html><font bgcolor="#FFFF00" color="#0000FF">' iconName ];
    iconString{r}  = ['<html>' , iconPrefix{r} , '<font bgcolor="none" color="#' , vec(dec2hex( round( 255*iconColor(r,:) )')')' , '">' , iconName ];
%     iconString{r}  = ['<html>' iconName ];

  end
  
  jThumbnail = javax.swing.JEditorPane('text/html', iconTooltip{1} );
  [ ~ , hThumbnail ] = javacomponent( javax.swing.JScrollPane(jThumbnail) , [], hFig);
  set( hThumbnail , 'Visible','off' );
  set( hThumbnail , 'units', 'pixels', 'position', [10,10,150,100]);
  

  
  
  
  hshowILS = uicontrol('Parent',hFig,'Position',[10 -40 150 20],'Style','checkbox','String','Show Lines','FontUnits','pixel','FontSize',13,'BackgroundColor','w','Value',true,'Callback',@(h,e)showILSfcn(h));
  function showILSfcn(h)
    lostfocus( h );
    showILS = get(h,'Value');
    try
      set( ILS , 'Visible',onoff(showILS));
    end
  end
  SetPosition( hshowILS , [ -150 , -22 , 150 , 20 ] , true );
  hIconList = uicontrol('Parent',hFig,'Max',2,'Position',[10 10 200 800],'Style','list','String',iconString,'FontUnits','pixel','FontSize',10,'BackgroundColor','w');
  SetPosition( hIconList , [ -150 , 0 , 150 , -23 ] , true );
  jScrollPane = findjobj(hIconList);
  jIconList = handle(jScrollPane.getViewport.getView, 'CallbackProperties');
  
  % Set the mouse-movement event callback
  set( jIconList, 'MouseMovedCallback', {@mouseMovedCallback,hIconList});


  showMCS = false;
  function showMCSfcn(h)
    lostfocus( h );
    showMCS = get(h,'Value');
    try
      set( hLineOnMann , 'Visible',onoff(showMCS));
    end
  end
  if ~isempty( MANN )
    hMannPanel = uipanel('Parent',hFig,'Position',[0 0 1 1],'BorderWidth',1,'BorderType','none','BackgroundColor','w');
    SetPosition( hMannPanel , [ 0 , 0 , 200 , -0.1 ] , true );

    hMannAxe = axes('Parent',hMannPanel,'Position',[0 0 1 1],'Visible','off');

    hshowMCSs = uicontrol('Parent',hMannPanel,'Position',[10 -40 150 20],'Style','checkbox','String','Show 3D Contours','FontUnits','pixel','FontSize',13,'BackgroundColor','w','Value',showMCS,'Callback',@(h,e)showMCSfcn(h));
    SetPosition( hshowMCSs , [ 5 , -22 , 150 , 20 ] , true );
    
    
    
    hMann = plotMESH( MANN , 'ne','FaceColor',[255,224,189]/255,'gouraud','shiny','FaceAlpha',0.3,'Clip','off','ButtonDownFcn',@(h,e)ObjectViewRotate(h) ,'patch');
%     hMann = patch( 'vertices', MANN.xyz , 'Faces', MANN.tri , 'EdgeColor','none','FaceColor',[255,224,189]/255,'FaceAlpha',0.3,'Clip','off','ButtonDownFcn',@(h,e)ObjectViewRotate(h) );
%     ,'gouraud','shiny'
    axis( hMannAxe , 'equal' );
    axis( hMannAxe , objbounds(hMannAxe) );
    view( hMannAxe , 0 , 15 );
    set(  hMannAxe ,'Visible','off');

    headlight

    for r = 1:R
      xyz = ndmat( I{r,1}.X([1 end]) , I{r,1}.Y([1 end]) , 0 );
      xyz = transform( xyz , I{r,1}.SpatialTransform );
      PLANES(r) = surface( 'Parent', hMannAxe ,...
                           'XData' , reshape( xyz(:,1) ,2,2) ,...
                           'YData' , reshape( xyz(:,2) ,2,2) ,...
                           'ZData' , reshape( xyz(:,3) ,2,2) ,...
                           'CData' , NaN(2,2) , 'EdgeColor','k','FaceColor','none','UserData',r,'Tag','PLANE','Visible','off');
      set( PLANES(r) , 'EdgeColor', iconColor(r,:) );

                         
      for c = 1:10
        xyz = [];
        try, xyz = C{r,c+1}; end
        if isempty( xyz ), xyz = NaN(1,3); end
        hLineOnMann(r,c) = line( xyz(:,1) , xyz(:,2) , xyz(:,3) , 'Color' , colorith(c) ,'LineWidth',1,'hittest','off','Visible','off');
      end
    end
    if showMCS
      set( hLineOnMann , 'Visible', 'on' );
    end
  end
  
  UNATTENDEDtimer = [];
  if isfinite( UNATTENDED )
    %hUnattPB = uicomponent( 'Parent',hMannPanel ,'Style','JProgressBar');
%     try
%       hUnattPB = uiProgressBar( hMannPanel );
%     catch
      hUnattPB = uiProgressBar( hFig );
%     end
    set( hUnattPB ,'Visible' ,'off','StringPainted',1,'Maximum',100,'BorderPainted',1 );
    SetPosition( hUnattPB , [ 4 , -20 , 120 , 18 ] , true );
    
    UNATTENDEDtimer = timer( 'TimerFcn' , @(h,e)UNATTENDEDfcn() , 'StartDelay' , 0 , 'ExecutionMode' , 'fixedSpacing' , 'Period' , max( UNATTENDED / 50 , 0.25 ) );
  end
  
  
  
  showILS       = true;
  showSCS       = true(10,1); %show Sliced ContourS
  A             = 0;
  hImageOnMann  = [];
  hSliceOnMann  = [];
  hDrawPanel    = [];
  hDrawAxe      = [];
  CLID          = 1;
  getXYZ        = [];
  hF            = [];
  previewed     = [];
  T             = 1;
  hT            = [];
  hPLAYER       = [];
  PLAYER        = arrayPlayer( @(t)t , 1 ); set( PLAYER , 'ElementsPerSecond' , 10 );
  
  set( hFig , 'CloseRequestFcn' , @(h,e)Closing() );

  
  setIconListValue( [] );
  set( hIconList , 'Callback' , @(h,e)SetActive( get( h , 'Value' ) ) );

  function setIconListValue( s , thumbnail )
    if nargin < 2, thumbnail = false; end
    set( hIconList , 'Value' , s );

    pk = pressedkeys_win();
    if thumbnail  ||  ( 0 && numel(pk) == 1 &&  isequal( pk{1} , 'TAB' ) )
      set( hThumbnail , 'Visible','on' );
    else
      set( hThumbnail , 'Visible','off' );
    end
    

    if ~( numel(pk) == 1 && isequal( pk{1} , 'TAB' ) )
      try, set( PLANES , 'Visible','off' ); end
      try, set( hLineOnMann , 'LineWidth',1,'Visible',onoff( showMCS ) ); end
      try, set( ILS3D , 'Visible','off' ); end
    end
    try, set( hLineOnMann(A,:) ,'Visible','on' ); end
    
    for c = 1:3
      try, showSCSfcn(  [] , c ); end
    end    
  
    if isempty( s )
      set( PROFILES , 'Visible', 'off' );
      set( ILS , 'LineWidth',1 ,'LineStyle',':','Visible',onoff(showILS));
      set( SCS , 'MarkerSize', 5 ,'LineWidth',1 );
      set( CCS , 'LineWidth',1 );
    end
    if numel( s ) ~= 1, return; end
    
    hs = findall( hDrawAxe , 'UserData',s);
    for hh = hs(:).'
      tag = get( hh , 'Tag' );
      
      if      strcmp( tag , 'IL' ),     set( hh , 'LineWidth' , 2 , 'Visible' , 'on' );
      elseif  strncmp( tag, 'SC.' ,3 ), set( hh , 'LineWidth' , 3 , 'MarkerSize' , 7 , 'Visible' , 'on' );
      elseif  strcmp( tag , 'CC' ),     set( hh , 'LineWidth' , 3 );
      end
    end
    
    try, set( ILS3D(s) , 'Visible','on' ); end

    try, set( findall( PLANES ,'UserData',s) , 'Visible' , 'on' ); end
    try, set( hLineOnMann(s,:) , 'LineWidth',2 ,'Visible','on' ); end

    try, set( MontageAXs , 'Visible','off' ); end
    try, set( MontageAXs(s) , 'Visible','on' ); end
  end
  
  hMontage = [];
  if strcmpi( MODE , 'heart' )
  
    switch R
      case 1, montage_size = [1,1];
      case 2, montage_size = [1,2];
      case 3, montage_size = [1,3];
      case 4, montage_size = [2,2];
      otherwise
        montage_size = [2,3];
        for i=1:10, if prod( montage_size ) < R, montage_size( rem(i,2)+1 ) = montage_size( rem(i,2)+1 )+1; end; end
    end    
    
    hMontage = uipanel('Parent', hFig,'Visible','on','BackgroundColor',[1 1 1]*0.7 );
    SetPosition( hMontage , [ 10 , 20 , -170 , -40 ] );
    try, uistack( hMontage , 'top' ); end
    
    sep = 0.00;
    MontageAXs = axesArray( montage_size , 'L',sep,'R',sep,'T',sep,'B',sep,'H',sep,'V',sep ,'Parent',hMontage ).';
    set( MontageAXs , 'Units' , 'normalized' );
    set( MontageAXs ,'Tag','sliceAxe','XTick',[],'YTick',[],'ZTick',[],...
              'Box','on','LineWidth',2,'Layer','top','Visible','off','ZLim',[-1,1],'Color',[1 1 1]);
            
    for r = 1:R
      II = I{r,1};
      if isempty( II ), continue; end
      
      II = II.t1;
      try, II = crop( II , 0 , 'mask' , II.FIELDS.Hmask ); end
      II = todouble( II );
      
      II = II - prctile( II , 5 );
      II = II / prctile( II , 95 );
      II = clamp( II , 0 , 1 );
      II = repmat( II , [1,1,1,1,3] );
      II = transform( II , minv(  II.SpatialTransform ) );
      
      
      set( hFig , 'CurrentAxes',MontageAXs(r) );
      
      imagesc( II );
      for c = 1:10
        xyz = [];
        try
          xyz = transform( C{r,c+1} , minv( I{r,1}.SpatialTransform ) );
          xyz(:,3) = 0.1;
        end
        if isempty( xyz ), xyz = NaN(1,3); end
        MontageLINEs(r,c) = line( xyz(:,1) , xyz(:,2) , xyz(:,3) , 'Color' , colorith(c) ,'LineWidth',3,'Hittest','off');
      end
      
      axis( MontageAXs(r) , [ centerscale( II.DX([1 end]) ,1.1) , centerscale( II.DY([1 end]) ,1.1) ] );
      set( MontageAXs(r) , 'DataAspectRatio',[1 1 1]);
%       OPZ_SetView( AXs(r) ,'warptofill');
      
      set( MontageAXs(r) , 'YDir' , 'reverse' );
      set( MontageAXs(r) , 'XColor' , iconColor(r,:) , 'YColor' , iconColor(r,:) , 'ZColor' , iconColor(r,:) );
    end
  
  end
  
  
  if ~isempty( UNATTENDEDtimer )
    UNATTENDEDstart = now; start( UNATTENDEDtimer );
  end
  
  if nargout
    waitfor( hFig );
    
    [ C{ cellfun('isempty',C) } ] = deal( [] );
    for c = size( C ,2):-1:2
      if all( cellfun('isempty',C(:,c)) )
        C(:,c) = [];
      else
        break;
      end
    end
    C_ = C;
  end
  
  
  function SetActive(r)
    if numel( r ) > 1, r = r(1); end
    try, set( hMontage , 'Visible','off' ); drawnow(); end
    UNATTENDEDstart = now; try, set( hUnattPB , 'Visible','off'); end

%     if A == r, return; end

%     fprintf( 'terminando %d\n' , A );
    
    if A
      
      iconString{A} = strrep( iconString{A} , '<html><b>' , '<html>' );
      
      for c = 1:10
        C{A,c+1} = getXYZ(c);
      end
      w = all( cellfun( 'isempty' , C ) ,1); w(1:4) = false; w( 1:find( ~w ,1,'last') ) = false; C(:,w) = [];
      
      try
        save( TEMPfile , 'C' );
        %fprintf('saving current contours in: "%s"\n' , TEMPfile );
      catch
        fprintf('error saving current contours in: "%s"\n' , TEMPfile );
      end
      
      if ~isinf(r)
        generateIcon( [ { I{A,1}.t1 } , C(A,2:end) ] , iconSz , A );
        
        pre = iconPrefix{A};
        iconPrefix{A} = prefix( C(A,:) );
        iconString{A} = strrep( iconString{A} , pre , iconPrefix{A} );
      end
      
      CLID = 1;
      try
        hLS = findall( hDrawPanel,'Type','uicontrol','Style','togglebutton','-regexp','Tag','LabelButton\.[\d]+$' );
        [~,ord] = sort( get( hLS , 'Tag' ) );
        hLS = hLS(ord);
        
        CLID = find( cell2mat( get( hLS , 'Value') ) ,1);
      end
      
      try, delete( hDrawPanel ); end
      try, delete( hImageOnMann ); end
      try, delete( hSliceOnMann ); end
      try, delete( ILS3D( ~~ILS3D ) ); end
    end
    
    if isinf( r ), return; end
    A = r;

    
    
%     fprintf( 'empezando %d\n' , A )


    sn = 'noNumber';      try, sn = I{A,1}.INFO.SeriesNumber; end; if isnumeric(sn), sn = sprintf('%03d',sn); end
    sd = 'noDescription'; try, sd = I{A,1}.INFO.SeriesDescription; end
    set( hFig , 'Name' , sprintf('( "%s" ) ---  %s.%s\n' , SUBJECT_DIR , sn , sd ) );

    iconString{A} = strrep( iconString{A} , '<html><i>' , '<html>' );
    iconString{A} = strrep( iconString{A} , '<html>' , '<html><b>' );
    set( hIconList , 'String' , iconString );
    
    
    FCN = @(clid,L)UpdateLine( L );
    if ~isempty( MANN )
      hold( hMannAxe , 'on' );
      hImageOnMann = imagesc( I{A,1}.t1 ,'Parent',hMannAxe,'HitTest','off');
      hSliceOnMann = plot3d( meshSlice( MANN , I{A,1} ) ,'Parent',hMannAxe, 'Color','m','LineWidth',1,'HitTest','off');
      hold( hMannAxe , 'off' );
      
      FCN = @(clid,L)UpdateLine( L , I{A,1}.SpatialTransform );
    end
    
    
    
%%
    MARKERS = struct([]);

    for s = 1:R
      iconString{s} = strrep( iconString{s} , 'bgcolor="#FFFF99"' , 'bgcolor="none"' );
    end
    
    ILS3D = [];
    %intersetion lines
    for s = [ 1:A-1 , A+1:R ]
      iconString{s} = strrep( iconString{s} , '<html><i>' , '<html>' );

      if ipd( I{A,1}.SpatialTransform(1:3,3).' , I{s,1}.SpatialTransform(1:3,3).' , 'normal') < 1e-4, continue; end
      XYZ = intersectionLine( I{A,1} , I{s,1} );
      if isempty( XYZ ), continue; end
      try
        ILS3D(s) = line( XYZ(:,1) , XYZ(:,2) , XYZ(:,3) , 'Parent' , hMannAxe , 'LineStyle',':','Color','y','Visible','off','hittest','off');
      end
      
      iconString{s} = strrep( iconString{s} , '<html>' , '<html><i>' );
      
%       try
        tM = struct('xyz', XYZ ,...
                    'Color',iconColor(s,:),'LineStyle',':','Marker','none','Tag','IL','UserData',s);
        MARKERS = catstruct(1,MARKERS,tM);
%       end
      
    end
    set( hIconList , 'String' , iconString );
    
    
    %intersetion contours
    for c = 2:size( C ,2)
      for s = [ 1:A-1 , A+1:R ]
        if ipd( I{A,1}.SpatialTransform(1:3,3).' , I{s,1}.SpatialTransform(1:3,3).' , 'normal') < 1e-4, continue; end
        
        CC = C{s,c};                    if isempty( CC ), continue; end
        try
            CC = meshSlice( CC , I{A,1} );
        catch
            CC = [];
        end
        if isempty( CC ), continue; end
        tM = struct('xyz', CC ,...
                    'Color',           clamp( -0.0 + colorith(c-1) ,0,1) ,...
                    'MarkerFaceColor', clamp( -0.4 + colorith(c-1) ,0,1) ,...
                    'Marker','o','LineWidth',1,'LineStyle','none','MarkerSize',5 ,...
                    'Hittest','on',...
                    'Tag', sprintf('SC.%d',c-1) , 'UserData' , s );
        MARKERS = catstruct(1,MARKERS,tM);
      end
    end

    
    %coincident planes
    for c = 2:size( C ,2)
      Zs = arrayfun( @(s)max( distance2Plane( C{s,c} ,  I{A,1} ) ) , 1:R );
      Zs(A) = Inf;
      for s = find( Zs(:).' < 1e-2 )
        iconString{s} = strrep( iconString{s} , 'bgcolor="none"' , 'bgcolor="#FFFF99"' );
        
        
        tM = C{s,c}; if isempty( tM ), continue; end
        tM = struct('xyz',tM , ...
          'Color', ( [1,1,1] + colorith(c-1) )/2 ,...
          'Marker','none','LineWidth',1,'LineStyle','--',...
                    'Hittest','on',...
                    'Tag', 'CC' , 'UserData' , s );
        MARKERS = catstruct(1,MARKERS,tM);
      end
    end
    set( hIconList , 'String' , iconString );
    
    
    %slice MESHES
    for m = 1:numel( MESHES )
      try,
        tM = struct('xyz',meshSlice( MESHES{m} , I{A,1} ) ,'Color',[1,0.5,0],'LineStyle','--','LineWidth',2);
        try, tM.Color     = MESHES{m}.Color;      end
        try, tM.LineWidth = MESHES{m}.LineWidth;  end
        try, tM.LineStyle = MESHES{m}.LineStyle;  end
        MARKERS = catstruct(1,MARKERS,tM);
      end
    end
    
    
%%    
    
    hDrawPanel = uipanel('Parent',hFig,'Position',[0 0 1 1],'BorderWidth',1,'BorderType','none','BackgroundColor','w');
    if ~isempty( MANN ), SetPosition( hDrawPanel , [200 , 0 , -350 , -0.1 ], true );
    else,                SetPosition( hDrawPanel , [  0 , 0 , -150 , -0.1 ], true );
    end
    hDrawAxe   = axes('Parent',hDrawPanel,'Position',[0 0 1 1],'Visible','off','Hittest','off');

    set( hFig , 'CurrentAxes' , hDrawAxe );
    
    T = 1;
    

    IMA = I{r,1}.t1;
    if isfinite( MAX_RESOLUTION ) && any( size( IMA ,1:2) > MAX_RESOLUTION )
      IMA = resample( IMA , -MAX_RESOLUTION , 'linear' );
    end
    
    
    getXYZ = drawContours( IMA , C(r,2:end) ,...
            'FILTERSIZE',0.05,...
            'MARKERS',MARKERS(end:-1:1),...
            'CLID', CLID ,...
            'FCN',FCN ,...
            'DECORATEfcn', @(h)DECORATE(h,MODE) ,...
            'Parent', hDrawAxe ...
            );
    try
      uistack( hMontage , 'top' ); set( hMontage , 'Visible','off' );
      jScrollPane = findjobj(hIconList);
      jIconList = handle(jScrollPane.getViewport.getView, 'CallbackProperties');
      set( jIconList, 'MouseMovedCallback', {@mouseMovedCallback,hIconList})
    end

    set( PLAYER , 'Callback' , @(t)setT(t) , 'Elements' , 1:size(I{A,1},4) );
  end
  
  
  function fn = generateIcon( I , sz , r )
    I{1,1} = I{1,1}.coords2matrix;

    icon = double( I{1,1}.t1 );
    icon = icon - prctile(icon(:), 5  );
    icon = icon/prctile( icon(:) , 95 );
    icon = clamp( icon ,0,1);
    icon = repmat( icon ,[1 1 3]);

    icon = imresize( icon , [sz,NaN] ,'bilinear' );
    if size(icon,2) > sz, icon = imresize( icon , [NaN,sz] ,'bilinear'); end
    icon = clamp( icon ,0,1);

    sc = max( size( I{1,1} ,1:2 )./sz ); n = size(icon,1)*size(icon,2);
    for c = 2:size(I,2)
      X = I{1,c}; if isempty( X ),continue; end
      X = transform( X , minv( I{1,1}.SpatialTransform ) );
      X = X(:,1:2)/sc;
      X = Interp1D( X , 1:size(X,1) , linspace( 1 , size(X,1) , 10000 ) );
      X( any( ~isfinite(X) ,2) ,:) = [];
      
      X = unique( round( X ) ,'rows');
      mask = zeros( size(icon,1) , size(icon,2) );
      
      X = sub2indv( size( mask ) , X );
      X( X > numel(mask) ) = [];
       
        X=X(X>0);%peter's fix
      mask( X ) = 1;
      mask = imdilate( mask , ones(2) );
      
      col = colorith(c-1); 
      X = find( mask );
      icon(       X ) = col(1);
      icon(   n + X ) = col(2);
      icon( 2*n + X ) = col(3);
    end
    icon = permute( icon , [2 1 3] );
    
    fn = fullfile( iconDir , sprintf('%03d.gif',r) );
    
    [icon,map] = rgb2ind(icon,256); 
		imwrite( icon , map , fn ,'gif');
    
    fn = strrep( fn , filesep ,'/');
  end
  function Closing()
    try, SetActive(Inf); end
    try
      stop( UNATTENDEDtimer );
      delete( UNATTENDEDtimer );
    end
    try
      stop( PLAYER );
      delete( PLAYER );
    end
    delete( hFig );
    drawnow;
    try, rmdir(iconDir,'s'); end
  end
  function UpdateLine( L , T )
    try, set( hLineOnMann ,'Marker','none','LineWidth',1); end
    x = get( L , 'XData' );
    y = get( L , 'YData' );
    z = zeros(size(x));
    c = get( L , 'Color' );
    
    s = get( L , 'tag' ); s = s(end); s = str2double(s);
    
    try, set( MontageLINEs(A,s) ,'Color',c ,'XData',x,'YData',y,'ZData',z+0.1); end
      
    try
      xyz = transform( [x(:),y(:),z(:)] , T );
      set( hLineOnMann(A,s) , 'XData' , xyz(:,1) , 'YData' , xyz(:,2) , 'ZData' , xyz(:,3) , 'Color', c ,'Visible','on','Marker','.','LineWidth',2);
    end
  end
  function DECORATE( hP , mode )
    ILS = findall( hDrawAxe , 'Tag','IL' );
    SCS = findall( hDrawAxe , '-regexp','Tag','SC\.[\d]+$');
    CCS = findall( hDrawAxe ,'Tag','CC');
    CONTOURS = findall(hDrawAxe,'-regexp','Tag','drawContours\.contour\.[\d]+$');
    
    oFcn = get( hFig , 'WindowButtonMotionFcn' ); set( hFig , 'WindowButtonMotionFcn' , @(h,e)Moving(h,e,oFcn,'WindowButtonMotionFcn') );
    oFcn = get( hFig , 'WindowKeyPressFcn' );     set( hFig , 'WindowKeyPressFcn'     , @(h,e)Moving(h,e,oFcn,'WindowKeyPressFcn') );
    oFcn = get( hFig , 'WindowKeyReleaseFcn' );   set( hFig , 'WindowKeyReleaseFcn'   , @(h,e)Moving(h,e,oFcn,'WindowKeyReleaseFcn') );

    switch lower(mode)
      case 'default'
        
        hLB = findall(hP,'Type','uicontrol','Style','togglebutton','TooltipString','Set Label 1 as Current');

        oldButtonBox = get( hLB ,'Parent' );
        %SetPosition( oldButtonBox , [ -0.1 , 0 , 1 , 1 ] , true );
        delete( getappdata( oldButtonBox ,'SetPosition_listener' ) );
        set( oldButtonBox , 'Position' , [ 1 , -100 , 1 , 1 ] );
        set( get(oldButtonBox,'Children') , 'Visible','off' );

        
        pos = [ 1 , -37 , 55 , 37 ];
        for l = 1:3
          hLB = findall(hP,'Type','uicontrol','Style','togglebutton','TooltipString',sprintf('Set Label %d as Current',l));
          
          set( hLB , 'Parent', hP ,'String',sprintf('LABEL %d',l) ,'ToolTipString',sprintf('Segment label %d',l),'Visible','on');
          SetPosition( hLB   , pos , true );
          SetPosition( ...
            uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(l),'TooltipString',sprintf('Show/Hide sliced contours from label %d',l),'Callback',@(h,e)showSCSfcn(h,l))  ...
            , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );
          showSCSfcn(  [] , l );
          
          pos(1) = pos(1) + pos(3);
        end
          
        
        if size(I{A,1},4) > 1
          hT = uicontrol( 'Parent',hP,'Style','text','String',sprintf( 'Phase: %d' ,T),'Position',[ 1 , 30 , 80 , 20 ] , 'BackgroundColor' ,[0.6 , 0.7 , 1.0],'Enable','on','HorizontalAlignment','center','FontSize',11);
          SetPosition( hT , [ 2 -78 75 22 ] , true );

          hPLAYER = uicontrol( 'Parent',hP,'Style','togglebutton','Value',0,'String','>','Position',[ 1 , 30 , 80 , 20 ] , 'BackgroundColor' ,[1 1 1],'Enable','on','Callback',@(h,e)run_and_stop_PLAYER() ,'TooltipString','PLAY');
          SetPosition( hPLAYER , [ 76 -78 24 22 ] , true );
        end

        
        
      case 'heart'
        hB = findall(hP,'Type','uicontrol','Style','togglebutton','Tag','LabelButton.01');

        oldButtonBox = get( hB ,'Parent' );
        %SetPosition( oldButtonBox , [ -0.1 , 0 , 1 , 1 ] , true );
        delete( getappdata( oldButtonBox ,'SetPosition_listener' ) );
        set( oldButtonBox , 'Position' , [ 1 , -100 , 1 , 1 ] );
        set( get(oldButtonBox,'Children') , 'Visible','off' );


        tint = @(c,f)(1-c)*f + c;
        tintB = @(h)set(h,'BackgroundColor',tint( get(h,'BackgroundColor'), 0.3 ) );


        pos = [ 1 , -30 , 50 , 30 ];
        set( hB , 'Parent', hP ,'String','LV-EPI' ,'ToolTipString','Segment LV EPIcardium','Visible','on'); tintB( hB );
        SetPosition( hB   , pos , true );
        SetPosition( ...
          uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(1),'TooltipString','Show/Hide sliced EPI contours','Callback',@(h,e)showSCSfcn(h,1))  ...
          , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );

        
        hB  = findall(hP,'Type','uicontrol','Style','togglebutton','Tag','LabelButton.02');
        pos(1) = pos(1) + pos(3) + 5;
        set( hB  , 'Parent', hP ,'String','LV-ENDO','ToolTipString','Segment LV ENDOcardium','Visible','on'); tintB( hB );
        SetPosition( hB  , pos , true );
        SetPosition( ...
          uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(2),'TooltipString','Show/Hide sliced LV contours','Callback',@(h,e)showSCSfcn(h,2))  ...
          , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );

        
        hB  = findall(hP,'Type','uicontrol','Style','togglebutton','Tag','LabelButton.03');
        pos(1) = pos(1) + pos(3) + 5;
        set( hB  , 'Parent', hP ,'String','RV-ENDO','ToolTipString','Segment RV','Visible','on'); tintB( hB );
        SetPosition( hB  , pos , true );
        SetPosition( ...
          uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(3),'TooltipString','Show/Hide sliced RV contours','Callback',@(h,e)showSCSfcn(h,3))  ...
          , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );

        
        hB  = findall(hP,'Type','uicontrol','Style','togglebutton','Tag','LabelButton.08');
        pos(1) = pos(1) + pos(3) + 5;
        set( hB  , 'Parent', hP ,'String','L Atria','ToolTipString','Segment Left Atria','Visible','on'); tintB( hB );
        SetPosition( hB  , pos , true );
        SetPosition( ...
          uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(8),'TooltipString','Show/Hide sliced LA contours','Callback',@(h,e)showSCSfcn(h,8))  ...
          , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );
        

        hB  = findall(hP,'Type','uicontrol','Style','togglebutton','Tag','LabelButton.09');
        pos(1) = pos(1) + pos(3) + 5;
        set( hB  , 'Parent', hP ,'String','R Atria','ToolTipString','Segment Right Atria','Visible','on'); tintB( hB );
        SetPosition( hB  , pos , true );
        SetPosition( ...
          uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(9),'TooltipString','Show/Hide sliced RA contours','Callback',@(h,e)showSCSfcn(h,9))  ...
          , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );
        

        hB  = findall(hP,'Type','uicontrol','Style','togglebutton','Tag','LabelButton.10');
        col = [1 3 3]/4;
        pos(1) = pos(1) + pos(3) + 5;
        set( hB  , 'Parent', hP ,'String','EXTRAS','ToolTipString','Segment EXTRAS','Visible','on','BackgroundColor', col ); tintB( hB );
        SetPosition( hB  , pos , true );
        SetPosition( ...
          uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(10),'TooltipString','Show/Hide','Callback',@(h,e)showSCSfcn(h,10),'Visible','off')  ...
          , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );
        
        set( findall( hP , 'Type','line','Tag',sprintf('drawContours.contour.%d',10) ) , 'Color', col ,'MarkerFaceColor', col );
        

        showSCSfcn(  [] , 1  );
        showSCSfcn(  [] , 2  );
        showSCSfcn(  [] , 3  );
        showSCSfcn(  [] , 8  );
        showSCSfcn(  [] , 9  );
        showSCSfcn(  [] , 10 );
        
        
        pos(1) = pos(1) + pos(3); pos(1) = pos(1) + 10; pos(3) = 80;
        hF = uicontrol( 'Parent',hP,'Style','togglebutton','String','Preview Fixed','Position',[ 1 , 30 , 80 , 20 ] ,'Callback',@(h,e)PreviewFixed(h) , 'BackgroundColor' , [1 1 1]*0.8);
        SetPosition( hF , pos , true );
  
        
        %PROFILES
        PROFILES = [];
        for s = [ 1:A-1 , A+1:R ]
          if ipd( I{A,1}.SpatialTransform(1:3,3).' , I{s,1}.SpatialTransform(1:3,3).' , 'normal') < 1e-4, continue; end

          XYZ = intersectionLine( I{A,1} , I{s,1} , 0.1 );
          if isempty( XYZ ), continue; end

          ev    = 1;
          XYZ   = XYZ( 1:ev:end ,:);
          CDATA = at( I{s,1}(:,:,:,1) , XYZ , 'closest' );
          XYZ   = transform( XYZ , minv( I{A,1}.SpatialTransform ) );

          [~,ord] = sort( CDATA , 'descend');
          XYZ   = XYZ(   ord ,:);
          XYZ(:,3) = -0.0005;
          CDATA = CDATA( ord ,:);
          CDATA = CDATA - prctile( CDATA ,     2 );
          CDATA = CDATA / prctile( CDATA , 100-2 );
          CDATA = clamp( CDATA , 0 , 1 );
          CDATA = repmat( CDATA , [1 1 3] );

          PROFILES(s) = patch('Vertices',XYZ,'Faces',(1:size(XYZ,1)).','Marker','o','MarkerSize',7,...
            'MarkerFaceColor','flat','EdgeColor','none',...
            'CData', CDATA ,'Visible','off','Tag','CLINE','Clipping','on');
        end
     
        if size(I{A,1},4) > 1
          hT = uicontrol( 'Parent',hP,'Style','text','String',sprintf( 'Phase: %d' ,T),'Position',[ 1 , 30 , 80 , 20 ] , 'BackgroundColor' ,[0.6 , 0.7 , 1.0],'Enable','on','HorizontalAlignment','center','FontSize',11);
          SetPosition( hT , [ 2 -78 75 22 ] , true );

          hPLAYER = uicontrol( 'Parent',hP,'Style','togglebutton','Value',0,'String','>','Position',[ 1 , 30 , 80 , 20 ] , 'BackgroundColor' ,[1 1 1],'Enable','on','Callback',@(h,e)run_and_stop_PLAYER() ,'TooltipString','PLAY');
          SetPosition( hPLAYER , [ 76 -78 24 22 ] , true );
        end
        
        if strcmp( getHOSTNAME , 'ENGS-24337' )
          hD = [];
          hCNN = uicontrol( 'Parent',hP,'Style','pushbutton','String','CNN','Position',[ 1 , -10 , 1 , 1 ] ,'Callback',@(h,e)HaoCNN() );
          SetPosition( hCNN , [ 280 , -37 , 48 , 37 ] , true );
        end
        
      case 'torso'
        hVEST = findall(hP,'Type','uicontrol','Style','togglebutton','BackgroundColor','r');

        oldButtonBox = get( hVEST ,'Parent' );
        %SetPosition( oldButtonBox , [ -0.1 , 0 , 1 , 1 ] , true );
        delete( getappdata( oldButtonBox ,'SetPosition_listener' ) );
        set( oldButtonBox , 'Position' , [ 1 , -100 , 1 , 1 ] );
        set( get(oldButtonBox,'Children') , 'Visible','off' );


        hLUNG  = findall(hP,'Type','uicontrol','Style','togglebutton','BackgroundColor','g');

        pos = [ 1 , -37 , 55 , 37 ];
        set( hVEST , 'Parent', hP ,'String','TORSO' ,'ToolTipString','Segment Torso','Visible','on');
        SetPosition( hVEST   , pos , true );
        SetPosition( ...
          uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(1),'TooltipString','Show/Hide sliced TORSO contours','Callback',@(h,e)showSCSfcn(h,1))  ...
          , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );

        pos(1) = pos(1) + pos(3);
        set( hLUNG  , 'Parent', hP ,'String','LUNGS','ToolTipString','Segment Lungs','Visible','on');
        SetPosition( hLUNG  , pos , true );
        SetPosition( ...
          uicontrol('Parent',hP,'Style','checkbox','String','','Value',showSCS(2),'TooltipString','Show/Hide sliced LUNGS contours','Callback',@(h,e)showSCSfcn(h,2))  ...
          , pos.*[1 1 0 0] + [ 4 , -7 , 15 , 15  ] , true );

        showSCSfcn(  [] , 1 );
        showSCSfcn(  [] , 2 );
        
    end
    
    function HaoCNN()
      lostfocus();
      hD = waitbar(0,'Please wait to Hao''s CNN...'); set( hD , 'CloseRequestFcn' ,'' );
      switch lower( I{A,1}.INFO.PlaneName )
        case {'hla','hlax'}
          waitbar( 0 , hD , 'Please wait to Hao''s CNN in LAX mode...' );
          CNNc = CNN( I{A,1} );
        case {'vla','vlax'}
          waitbar( 0 , hD , 'Please wait to Hao''s CNN in LAX mode...' );
          CNNc = CNN( I{A,1} );
        case {'lvot','lvotx'}
          waitbar( 0 , hD , 'Please wait to Hao''s CNN in LAX mode...' );
          CNNc = CNN( I{A,1} );
        case {'sa','sax'}
          waitbar( 0 , hD , 'Please wait to Hao''s CNN in SAX mode...' );
          CNNc = CNN( I{A,1} );
        otherwise
          waitbar( 1 , hD , 'no valid PlaneView' ); pause(1);
      end
      delete( hD );
    end
    function C = CNN( I )
      try
        C = HeartSlicesCNNsegmentation( I.t1 , I.INFO.PlaneName );
        waitbar( 1 , hD , 'updating contour' );
        
        CLID = find( [ get( hB ,'Value' ) , get( hB ,'Value' ) , get( hB ,'Value' ) ] );
        C = transform( C{CLID} , minv( I.SpatialTransform ) );
        C( end+1:end+2 ,:) = NaN;
    
        hL = findall( hDrawAxe , 'Tag',sprintf('drawContours.contour.%d',CLID) );
        appData =  get( hL , 'ApplicationData' );
        appData.SetUndoFcn( );
        appData.UpdateContourFcn( C );
      catch
        waitbar( 1 , hD , 'some error' ); pause(1);
      end
    end
    
    try, feval( reDECORATE ); end
  end
  function showSCSfcn( h , c )
    if ~isempty( h )
      lostfocus( h );
      showSCS(c) = get(h,'Value');
    end
%     try
      set( findall( hDrawAxe , 'Tag',sprintf('SC.%d',c) ) , 'Visible',onoff( showSCS(c) ) );
%     end
  end
  function Moving( h , e , origFcn , action )
    UNATTENDEDstart = now; try, set( hUnattPB , 'Visible','off'); end
    set( CONTOURS , 'hittest','off' );
    
%     disp(e)
    switch action
      case 'WindowButtonMotionFcn'

      case 'WindowKeyReleaseFcn'
        if 0
        elseif strcmpi( MODE , 'heart' )  &&  isequal( e.Key , 'backquote' ) && numel( e.Modifier ) == 0
          try, set( hMontage , 'Visible','off' ); end
          return;
        elseif isequal( e.Key , 'v' ) && numel( e.Modifier ) == 0 
          set( findall( hDrawAxe ,'Type','line') ,'Visible','on');
          set( ILS , 'Visible', onoff( showILS ) );
          showSCSfcn( [] , 1 ); showSCSfcn( [] , 2 ); showSCSfcn( [] , 3 );
          return;
        end
        
      case 'WindowKeyPressFcn'
        if 0
        elseif isequal( e.Key , 'g' ) && numel( e.Modifier ) == 1 && isequal( e.Modifier{1} , 'control' )
          s = get( hIconList , 'Value' );
          if numel(s) ~= 1, return; end
          if s == A, return; end
          SetActive(s);
          return;
        elseif isequal( e.Key , 'period' ) && numel( e.Modifier ) == 1 && isequal( e.Modifier{1} , 'control' )
          if A < R, SetActive(A+1); end
          return;
        elseif isequal( e.Key , 'comma' ) && numel( e.Modifier ) == 1 && isequal( e.Modifier{1} , 'control' )
          if A > 1, SetActive(A-1); end
          return;
        elseif strcmpi( MODE , 'heart' )  &&  isequal( e.Key , 'p' ) && numel( e.Modifier ) == 0 
          set( hF , 'Value' , ~get( hF , 'Value' ) );
          feval( get( hF , 'Callback' ) , hF , [] );
          return;
        elseif isequal( e.Key , 'z' ) && numel( e.Modifier ) == 0 
          lims = objbounds( CONTOURS );
          try, set( hDrawAxe , 'XLim', centerscale( lims(1:2) ,1.3) , 'YLim', centerscale( lims(3:4) ,1.3) ,'ZLim',[-2 2]); end
          return;
        elseif strcmpi( MODE , 'heart' )  &&  isequal( e.Key , 'backquote' ) && numel( e.Modifier ) == 0 
          try, set( hMontage , 'Visible','on' ); end
          return;
        elseif isequal( e.Key , 'v' ) && numel( e.Modifier ) == 0
          set( findall( hDrawAxe ,'Type','line') ,'Visible','off');
          return;
        elseif isequal( e.Key , 'rightarrow' ) && numel( e.Modifier ) == 1 && isequal( e.Modifier{1} , 'shift' )
          try, run_and_stop_PLAYER( 1 ); end
          return;
        elseif isequal( e.Key , 'rightarrow' ) && numel( e.Modifier ) == 0
          try, run_and_stop_PLAYER( 0 ); end
          try, setT( T+1 ); end
          return;
        elseif isequal( e.Key , 'leftarrow' ) && numel( e.Modifier ) == 0
          try, run_and_stop_PLAYER( 0 ); end
          try, setT( T-1 ); end
          return;
        elseif isequal( e.Key , 'home' ) && numel( e.Modifier ) == 0
          try, run_and_stop_PLAYER( 0 ); end
          try, setT( 1 ); end
          return;
        end
    end
    
    try
      if ~pressedkeys_win(3)
        setIconListValue( [] );
        ht = hittest(); s = get( ht , 'UserData' );
        if strcmp( get( ht , 'Tag' ) , 'IL' ),              setIconListValue( s );
          if ~isempty( PROFILES )  && any( strcmp( pressedkeys() , 'LSHIFT' ) )
            set( PROFILES(s) , 'Visible','on' );
            set( ht , 'Visible','off' );
          end
        elseif strncmp( get( ht , 'Tag' ) , 'SC.' , 3 ),    setIconListValue( s );
        elseif strcmp( get( ht , 'Tag' ) , 'CC' ),          setIconListValue( s );
        elseif strcmp( get( ht , 'Type') , 'surface' )
          setIconListValue( A );
        end
      end
    end

    try
      if get( hF ,'Value'), return; end
    end
    
    set( CONTOURS , 'hittest','on' );
    try, origFcn( h , e ); end
  end
  function mouseMovedCallback( jListbox, jEventData, hListbox )
    persistent lastID
    try
      mousePos = java.awt.Point( jEventData.getX, jEventData.getY );
      ID = jListbox.locationToIndex(mousePos) + 1;
      %set( hListbox , 'Tooltip' , iconTooltip{s} );
      
      setIconListValue( ID , true );
      
      fp = get( hFig , 'Position' );
      
      pos = [ fp(3)-150-400 , fp(4)-mousePos.y - 150 , 400 , 210 ];
      pos = 10*round(pos/10);
      if pos(2) > fp(4)-210, pos(2) = fp(4)-210; end
      if pos(2) < 1,         pos(2) = 1; end
      set( hThumbnail ,'Position', pos );
      if ~isequal( ID , lastID )
        set( jThumbnail , 'Text' , iconTooltip{ID} );
      end
      lastID = ID;
    end
  end
  function PreviewFixed( h )
    lostfocus( h );
    vh = get( h , 'Value' );
    if vh == 1
      set( h , 'BackgroundColor' , [1 1 1]);
      previewed = findall( hDrawAxe , 'Type','line','LineStyle','-');
      set( previewed , 'Visible','off' );
      
      HC = [ I(:,1) , C(:,2:end) ];
      for c = 1:10
        HC{A,c+1} = getXYZ(c);
      end
      w = all( cellfun( 'isempty' , HC ) ,1); w(1:4) = false; HC(:,w) = [];

      M  = minv( HC{A,1}.SpatialTransform );
      for c = 2:size(HC,2)
        p = transform( HC{A,c} , M );
        if isempty(p), continue; end
        p(:,3) = 0.0;
        line('Parent',hDrawAxe,'XData',p( : ,1),'YData',p( : ,2),'ZData',p( : ,3),'Tag','PreviewFixed','Color',[0 1 1],'LineWidth',1);
      end
      drawnow();
      
      try
        try
          HF = FixHeartSlices( HC , A );
        catch LE
          fprintf(2,'error in FixHeartSlices\n' );
          fprintf(2,'---------------------------------\n' );
          disperror( LE );
          fprintf(2,'---------------------------------\n' );
        end
        HF = HF(A,2:end);
        
        for c = 1:size(HF,2)
          p = transform( HF{1,c} , M );
          if isempty(p), continue; end
          switch c
            case 1, col = [ 1.0 , 0.0 , 0.0 ];
            case 2, col = [ 0.0 , 1.0 , 0.0 ];
            case 3, col = [ 0.0 , 0.0 , 1.0 ];
            case 4, col = [ 1.0 , 1.0 , 0.0 ];
            case 5, col = [ 1.0 , 0.0 , 1.0 ];
            case 6, col = [ 1.0 , 0.5 , 0.0 ];
            case 7, col = [ 0.0 , 0.0 , 1.0 ];
            case 8, col = [ 1.0 , 0.5 , 1.0 ];
          end
          p(:,3) = -0.25;
          line('Parent',hDrawAxe,'XData',p( : ,1),'YData',p( : ,2),'ZData',p( : ,3),'Tag','PreviewFixed','Color',col,'LineWidth',3);
          line('Parent',hDrawAxe,'XData',p( 1 ,1),'YData',p( 1 ,2),'ZData',p( 1 ,3),'Tag','PreviewFixed','Color',col,'LineWidth',2,'Marker','o','MarkerSize',11);
          line('Parent',hDrawAxe,'XData',p(end,1),'YData',p(end,2),'ZData',p(end,3),'Tag','PreviewFixed','Color',col,'LineWidth',3,'Marker','x','MarkerSize',13);
        end
        
        lims = objbounds( findall(hDrawAxe,'Tag','PreviewFixed') );
        set( hDrawAxe , 'XLim', centerscale( lims(1:2) ,1.1) , 'YLim', centerscale( lims(3:4) ,1.1) ,'ZLim',[-2 2]);
      end
    else
      set( h , 'BackgroundColor' , [1 1 1]*0.8);
      try, delete( findall( hDrawAxe , 'Tag','PreviewFixed') ); end
      for c = previewed(:).'
        try, set( c , 'Visible','on'); end
      end
    end
  end

  function UNATTENDEDfcn()
    e_time = etime( UNATTENDEDstart );
    if e_time > UNATTENDED / 2
      set( hUnattPB , 'Visible','on' );
      set( hUnattPB , 'String' , sprintf( 'Close in %d secs' , round( UNATTENDED - e_time ) ) );
      set( hUnattPB , 'Value' , ( e_time / UNATTENDED - 0.5 ) * 2 * 100 );
    else
      set( hUnattPB , 'Visible','off' );
    end
    if e_time > UNATTENDED, Closing(); end
  end

  function setT( t )
    T = t;
    T = mod( T-1 , size( I{A,1} ,4) )+1;
    hS = findall( hDrawAxe , 'Tag','drawContour.IMsurface' );
    feval( get( hS , 'UserData' ) , permute( I{A,1}(:,:,:,T) , [1 2 3 4] ) );
    
    set( hT , 'String' , sprintf( 'Phase: %d' ,T) );
  end
  function run_and_stop_PLAYER( state )
    lostfocus( hFig );
    if nargin < 1
      state = get( hPLAYER , 'Value' );
    else
      set( hPLAYER , 'Value' , state );
    end
    if state
      set( hPLAYER , 'BackgroundColor' ,[0.6 , 0.7 , 1.0] );
      loop( PLAYER );
    else
      set( hPLAYER , 'BackgroundColor' ,[1 1 1] );
      stop( PLAYER );
    end
  end

end

function s = prefix( C )
    s = '';
    s = [ s , '<font family="monospace">&nbsp</font>' ];
    bg = 'FFFFFF'; try, if isvalidC( C{2} ), bg = 'FF0000'; end; end
    s = [ s , '<font bgcolor="#' , bg , '" family="monospace">&nbsp</font>' ];
    bg = 'FFFFFF'; try, if isvalidC( C{3} ), bg = '00DD00'; end; end
    s = [ s , '<font bgcolor="#' , bg , '" family="monospace">&nbsp</font>' ];
    bg = 'FFFFFF'; try, if isvalidC( C{4} ), bg = '0000FF'; end; end
    s = [ s , '<font bgcolor="#' , bg , '" family="monospace">&nbsp</font>' ];
    s = [ s , '<font family="monospace">&nbsp&nbsp</font>' ];

  function v = isvalidC( x )
    v = false;
    if isempty(x), return; end
    try
      x = polyline( x );
      x( x.n < 2 ) = [];
      if isempty(x), return; end
      v = true;
    end
  end
end

function h = uiProgressBar( hParent )
  [ j , h ] = javacomponent( javax.swing.JProgressBar , [] , hParent );
  set( h ,'Visible','off');
  h = handle( h );
  props  = {'Maximum' , 'String' , 'StringPainted' , 'Value' , 'BorderPainted' };
  for p = props, p = p{1};
    jsp = findprop( j , p );
    msp = schema.prop( h , p , 'mxArray' );
    msp.AccessFlags.PublicSet = jsp.AccessFlags.PublicSet;
    msp.SetFunction = @(h,e)set_( j , p ,e );
    msp.Visible = jsp.Visible;
  end

  function o = set_( varargin )
    o = false;
    try
      set( varargin{:} );
      o = true;
    end
  end
end


%   if 0
%   jIconList.MouseClickedCallback = {@mouseClickedFcn,hIconList};
%   end
%   function mouseClickedFcn(jListbox, jEventData, hListbox)
%     % Get the clicked item and row index
%     clickedX = jEventData.getX;
%     clickedY = jEventData.getY;
%     if clickedX > 15,  return;  end  % did not click a checkbox so bail out
%     clickedRow = jListbox.locationToIndex(java.awt.Point(clickedX,clickedY)) + 1;  % Matlab row index = Java row index+1
%     if clickedRow <= 0,  return;  end  % clicked not on an item - bail out
%     strs = get(hListbox,'String');
%     clickedItem = strs{clickedRow};
%     
%     % Switch the icon between checked.gif <=> unchecked.gif
%     if strfind(clickedItem,'unchecked')
%       strs{clickedRow} = strrep(clickedItem,'unchecked','checked');
%     else
%       strs{clickedRow} = strrep(clickedItem,'checked','unchecked');
%     end
%     set(hListbox,'String',strs);  % update the list item
%   end
