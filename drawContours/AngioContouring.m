function CS_ = AngioContouring( IS , varargin )
  if nargin < 1
%     IS = { I3D( mean(double(imread('cameraman.tif')),3)' );
%       I3D( mean(double(imread('ngc6543a.jpg')) ,3)' );
%       I3D( mean(double(imread('peppers.png'))  ,3)' );
%       };

    try
      close all
      CS_= AngioContouring( evalin('base',IS) );
      return;
    end

    cd('C:\Dropbox\WORK\Abhi\');

    IS = cell(0);
    IS{end+1,1} = I3D( dicomread('VID_GUI\02.vid') ); IS{end,1}.INFO = dicominfo('VID_GUI\02.vid');
    IS{end+1,1} = I3D( dicomread('VID_GUI\03.vid') ); IS{end,1}.INFO = dicominfo('VID_GUI\03.vid');
    IS{end+1,1} = I3D( dicomread('VID_GUI\04.vid') ); IS{end,1}.INFO = dicominfo('VID_GUI\04.vid');
    IS{end+1,1} = IS{2,1}(:,:,:,8:end);
    IS{end+1,1} = IS{1,1}(:,:,:,8:end);
    IS{end+1,1} = IS{3,1}(:,:,:,8:end);
    IS{end+1,1} = IS{2,1}(:,:,:,8:end);
    CS_ = AngioContouring( IS );

    return
  end

  IMA = [];
  MAX_RESOLUTION = 200;
  try, [varargin,~,MAX_RESOLUTION] = parseargs(varargin ,'RESolution','$DEFS$',MAX_RESOLUTION); end
  

  TEMPfile = [];
  try, [varargin,~,TEMPfile] = parseargs(varargin ,'TEMPfile','$DEFS$',TEMPfile); end
  if isempty( TEMPfile )
    TEMPfile = tmpname( 'AngioContouring_******.con' );
  end

  reDECORATE = [];
  try, [varargin,~,reDECORATE] = parseargs(varargin ,'reDECORATE','$DEFS$',reDECORATE); end

  
  COLORS = [1,0,0;0,1,0;0,0,1;1,0.5,0;0.5,0,0.5;0,1,1;0.5,0,0;0.5,0.5,0;0.75,0.25,0.25;0.25,0.25,0.75];
  
  
  R  = size( IS ,1);                %number of rows
  CS = IS(:,1:min(end,12));         %the complete images-contours-landmarks structure (cell actually)
  IS = IS(:,1);                     %only the images
  [ CS{:,end+1:12} ] = deal( [] );  %column 1 will have the "simplified" images, columns 2-11 have the contours, column 12 has the 9 landmarks.
  for r = 1:R                       %simplyfiyng the images in the first column
    if isempty(CS{r,1}), continue; end
    CS{r,1}.data = [];
    try
      CS{r,1}.INFO = struct(  'MediaStorageSOPInstanceUID'  , DICOMxinfo( CS{r,1}.INFO , 'MediaStorageSOPInstanceUID' ) ,...
                              'SeriesInstanceUID'           , DICOMxinfo( CS{r,1}.INFO , 'SeriesInstanceUID' ) ,...
                              'xZLevel'                     , DICOMxinfo( CS{r,1}.INFO , 'xZLevel' ) );
    catch
      CS{r,1}.INFO = [];
    end
    
    if isempty( CS{r,12} ), CS{r,12} = NaN(1,3); end
    CS{r,12}(end+1:9,1:3) = NaN;
    
  end

  
  
  hFig = figure('Toolbar','figure','CreateFcn','','Renderer','OpenGL','RendererMode','manual','Colormap',gray(256) );
  set(hFig ,'Position'     , FullScreenPosition() + [ 50 75 -200 -150 ] ,...
            'Renderer'     , 'opengl' ,...
            'RendererMode' , 'manual' ,...
            'Menu'         , 'none' ,...
            'Toolbar'      , 'none' ,...
            'Color'        , 'w'    ,...
            'NumberTitle'  , 'off'  ); drawnow();

          
  %% List of images (right panel)
  iconNameString = cell(R,1);
  for r = 1:R
    sn = 'noNumber';      try, sn = IS{r,1}.INFO.SeriesNumber; end; if isnumeric(sn), sn = sprintf('%03d',sn); end
    sd = 'noDescription'; try, sd = IS{r,1}.INFO.SeriesDescription; end
    iconNameString{r}  = ['<html>' , sprintf('%s.%s', sn , sd ) ];
  end
          
  hIconList = uicontrol('Parent',hFig,'Max',2,'Position',[10 10 200 800],'Style','list','String',[iconNameString;{''}],'FontUnits','pixel','FontSize',10,'BackgroundColor','w');
  SetPosition( hIconList , [ -300 , 305 , 300 , -305 ] , true );
  jScrollPane = findjobj(hIconList);
  jIconList   = handle(jScrollPane.getViewport.getView, 'CallbackProperties');
  
  THUMB = struct();
  THUMB.hAX = axes('Parent',hFig,'Units','pixels','Position',[1 1 100 100],'Visible','on',...
                   'XTick',[],'YTick',[],'ZTick',[],'Box','on','LineWidth',2);
  view( THUMB.hAX , [ 0 , -90 ] );                 
  SetPosition( THUMB.hAX , [ -300 , 0 , 300 , 300 ] , true );
  
  THUMB.hIM = surface('XData',NaN(2,2),'YData',NaN(2,2),'ZData',NaN(2,2),'CData',NaN(2,2),'FaceColor','interp','EdgeColor','none');
  for c = 1:10
    THUMB.hC(c) = line('XData',NaN,'YData',NaN,'ZData',NaN,'LineWidth',2,'Color',COLORS(c,:));
  end
  for c = 1:9
    THUMB.hL(c) = line('XData',NaN,'YData',NaN,'ZData',NaN,'LineWidth',1,'Color','k','Marker','o','MarkerFaceColor',COLORS(c,:));
  end
  THUMBnailFCN( 0 );

  % Set the mouse-movement event callback
  set( jIconList, 'MouseMovedCallback', @mouseMovedCallback );

  
  %%
  
  
  CONTOURS      = [];
  ACTIVE        = 0;
  hDrawPanel    = [];
  hDrawAxe      = [];
  CLID          = 1;
  getXYZ        = [];
  T             = 1;
  hT            = [];
  hPLAYER       = [];
  PLAYER        = arrayPlayer( @(t)t , 1 ); set( PLAYER , 'ElementsPerSecond' , 10 );
  LMKS          = [];
  set( ancestor( hFig ,'figure') , 'CloseRequestFcn' , @(h,e)Closing() );

  
  set( hIconList , 'Callback' , @(h,e)SetActive( get( h , 'Value' ) ) );

  if nargout
    waitfor( ancestor( hFig ,'figure') );
    
    [ CS{ cellfun('isempty',CS) } ] = deal( [] );
%     for c = size( CS ,2):-1:2
%       if all( cellfun('isempty',CS(:,c)) )
%         CS(:,c) = [];
%       else
%         break;
%       end
%     end4
    CS_ = CS;
  end
  
  
  function SetActive(r)
    if numel( r ) > 1, r = r(1); end
    try, stop( PLAYER ); end
    THUMBnailFCN( 0 );

    if ACTIVE
      for c = 1:10
        CS{ACTIVE,c+1} = getXYZ(c);
      end
      for k = 1:9
        CS{ACTIVE,12}(k,1) = mean( get( LMKS(k) ,'XData' ) );
        CS{ACTIVE,12}(k,2) = mean( get( LMKS(k) ,'YData' ) );
        CS{ACTIVE,12}(k,3) = 0;
      end
      %CS{ACTIVE,12}

      try
%        if r == ACTIVE, fprintf('saving current contours in: "%s" ...' , TEMPfile ); end
        save( TEMPfile , 'CS' );
%        if r == ACTIVE, fprintf( ' done.\n' ); end
      catch
        fprintf('error saving current contours in: "%s"\n' , TEMPfile );
      end


      CLID = 1;
      try
        hLS = findall( hDrawPanel,'Type','uicontrol','Style','togglebutton','-regexp','Tag','LabelButton\.[\d]+$' );
        [~,ord] = sort( get( hLS , 'Tag' ) );
        hLS = hLS(ord);

        CLID = find( cell2mat( get( hLS , 'Value') ) ,1);
      end

      if ACTIVE == r
        THUMBnailFCN( ACTIVE );
        return;
      end

      iconNameString{ACTIVE} = strrep( iconNameString{ACTIVE} , '<html><b>' , '<html>' ); set( hIconList , 'String' , iconNameString );
      try, delete( hDrawPanel ); end
    end
    
    if isinf( r ), return; end
    ACTIVE = r;
    THUMBnailFCN( ACTIVE );

    iconNameString{ACTIVE} = strrep( iconNameString{ACTIVE} , '<html>' , '<html><b>' ); set( hIconList , 'String' , iconNameString );
    
%%

    hDrawPanel = uipanel('Parent',hFig,'Position',[0 0 1 1],'BorderWidth',1,'BorderType','none','BackgroundColor','w');
    SetPosition( hDrawPanel , [  0 , 0 , -302 , -0.1 ], true );
    hDrawAxe   = axes('Parent',hDrawPanel,'Position',[0 0 1 1],'Visible','off','Hittest','off');

    set( ancestor( hFig ,'figure') , 'CurrentAxes' , hDrawAxe );
    
    T = 1;
    try, stop( PLAYER ); end
    set( PLAYER , 'Callback' , @(t)setT(t) , 'Elements' , 1:size(IS{ACTIVE,1},4) );
    
    
    IMA = IS{r,1};
    if isfinite( MAX_RESOLUTION ) && any( size( IMA ,1:2) > MAX_RESOLUTION )
      IMA = resample( IMA , -MAX_RESOLUTION , 'linear' );
    end
    
    getXYZ = drawContours( IMA.t1 , CS(r,2:end) ,...
            'FILTERSIZE',0.05,...
            'CLID', CLID ,...
            'DECORATEfcn', @(h)DECORATE(h) ,...
            'Parent', hDrawAxe ...
            );

  end
  function Closing()
    try, SetActive(Inf); end
    try
      stop( PLAYER );
      delete( PLAYER );
    end
    delete( ancestor(hFig,'figure') );
    drawnow;
  end
  function DECORATE( hP )
    oFcn = get( hFig , 'WindowButtonDownFcn' );   set( hFig , 'WindowButtonDownFcn'   , @(h,e)Moving(h,e,oFcn,'WindowButtonDownFcn') );
    oFcn = get( hFig , 'WindowButtonMotionFcn' ); set( hFig , 'WindowButtonMotionFcn' , @(h,e)Moving(h,e,oFcn,'WindowButtonMotionFcn') );
    oFcn = get( hFig , 'WindowKeyPressFcn' );     set( hFig , 'WindowKeyPressFcn'     , @(h,e)Moving(h,e,oFcn,'WindowKeyPressFcn') );
    oFcn = get( hFig , 'WindowKeyReleaseFcn' );   set( hFig , 'WindowKeyReleaseFcn'   , @(h,e)Moving(h,e,oFcn,'WindowKeyReleaseFcn') );

    CONTOURS = findall(hDrawAxe,'-regexp','Tag','drawContours\.contour\.[\d]+$');
    for c = CONTOURS(:).'
      r = get(c,'Tag'); r = str2double( r(22:end) );
      set( c , 'Color', COLORS(r,:) );
    end
    hLS = findall( hDrawPanel,'Type','uicontrol','Style','togglebutton','-regexp','Tag','LabelButton\.[\d]+$' );
    for c = hLS(:).'
      r = get(c,'Tag'); r = str2double( r(13:end) );
      set( c , 'BackgroundColor', COLORS(r,:) );
    end
    
    if size(IS{ACTIVE,1},4) > 1
      hT = uicontrol( 'Parent',hP,'Style','text','String',sprintf( 'Phase: %d' ,T),'Position',[ 1 , 30 , 80 , 20 ] , 'BackgroundColor' ,[0.6 , 0.7 , 1.0],'Enable','on','HorizontalAlignment','center','FontSize',11);
      SetPosition( hT , [ 2 -78 75 22 ] , true );

      hPLAYER = uicontrol( 'Parent',hP,'Style','togglebutton','Value',0,'String','>','Position',[ 1 , 30 , 80 , 20 ] , 'BackgroundColor' ,[1 1 1],'Enable','on','Callback',@(h,e)run_and_stop_PLAYER() ,'TooltipString','PLAY');
      SetPosition( hPLAYER , [ 76 -78 24 22 ] , true );
    end
    L = CS{ACTIVE,12};
    for k = 1:9
      LMKS(k) = line( 'XData' , L(k,1)*[1,1] , 'YData' , L(k,2)*[1,1] , 'ZData' , [-1,1]*0.1 ,'Marker','o','Color','k','MarkerFaceColor',COLORS(k,:),'MarkerSize',10);
    end
%    fprintf('redecoration done.\n');
    
%     ch = get( hFig , 'Children' );
%     set( hFig , 'Children', unique( [ THUMB.hAX ; hP ; ch ] ,'stable') );
%     jScrollPane = findjobj(hIconList);
%     jIconList   = handle(jScrollPane.getViewport.getView, 'CallbackProperties');
%     set( jIconList, 'MouseMovedCallback', @mouseMovedCallback );

    try, feval( reDECORATE ); end
  end
  function Moving( h , e , origFcn , action )
    ht = hittest();
    if strcmp( get(THUMB.hAX,'Visible') , 'on' )
      if ~isequal( ht , hIconList )
        THUMBnailFCN( 0 );
      end
    end
    
%     set( CONTOURS , 'hittest','off' );
    
%     disp(e)
    switch action
      case 'WindowButtonDownFcn'
        pk = pressedkeys;
        if 0
        elseif numel(pk) == 1 && numel( pk{1} ) == 1 && any( pk{1} == '123456789' )
%          fprintf('landmarking ...\n');
          k = str2double( pk{1} );
          b = pressedkeys_win(3);
%          fprintf('lmk %d  with button  %d\n',k,b);
          xy = NaN(1,3);
          if b == 1
            xy = get( hDrawAxe , 'CurrentPoint' ); xy(:,3) = [-1,1]*0.1;
          end
%          fprintf('xy: %s\n',uneval(xy));
          set( LMKS(k) , 'XData' , xy(:,1) , 'YData', xy(:,2) , 'ZData', xy(:,3) );
        end
      
      case 'WindowButtonMotionFcn'

      case 'WindowKeyReleaseFcn'
        if 0
        elseif isequal( e.Key , 'v' ) && numel( e.Modifier ) == 0 
          set( findall( hDrawAxe ,'Type','line') ,'Visible','on');
          return;
        end
        
      case 'WindowKeyPressFcn'
        if 0
        elseif numel( e.Key ) == 1 && any( e.Key == '123456789' )
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
    
%     set( CONTOURS , 'hittest','on' );

    try, origFcn( h , e ); end
  end
  function THUMBnailFCN( ID )
    %fprintf( 'in THUMBnailFCN: %d   %s\n', ID , datestr(now,'HH:MM:SS.FFF') );
    if ID == 0
      set( [ THUMB.hAX ; findall( THUMB.hAX ) ] , 'Visible','off' );
      set( hIconList , 'Value',[]);
      return;
    end
    
    set( hIconList , 'Value',ID);
    set( [ THUMB.hAX ; findall( THUMB.hAX ) ] , 'Visible','on' );

    try
      for p = {'XDir','YDir','CameraUpVector','CameraPosition','CameraTarget','ZLim'}
        %fprintf('%s  :  %s\n', p{1} , uneval( get( hDrawAxe ,p{1}) ) );
        set( THUMB.hAX ,p{1}, get( hDrawAxe ,p{1}) );
      end
    end

    set( THUMB.hIM , 'XData' , IS{ID}.XX , 'YData' , IS{ID}.YY , 'ZData' , IS{ID}.ZZ , 'CData' , double( IS{ID}.data(:,:,:,1) ) );
    set( THUMB.hAX , 'XLim' , range( IS{ID}.DX ) , 'YLim' , range( IS{ID}.DY ) );

    for c = 1:10
      xyz = CS{ID,c+1};
      if isempty( xyz ), xyz = NaN(1,3); end
      xyz(:,3) = 0;
      set( THUMB.hC(c) , 'XData' , xyz(:,1) , 'YData' , xyz(:,2) , 'ZData' , xyz(:,3) );
    end
    for k = 1:9
      xyz = CS{ID,12}(k,:); xyz(:,end+1:3) = 0;
      set( THUMB.hL(k) , 'XData' , xyz(:,1)*[1,1] , 'YData' , xyz(:,2)*[1,1] , 'ZData' , [-1,1]*0.1 );
    end
    
%     if numel(LMKS)
%     for k = 1:9
%       xyz = CS{ID,12}(k,:); xyz(:,end+1:3) = 0;
%       lmk = [ vec( get( LMKS(k) , 'XData' ) ) , vec( get( LMKS(k) , 'YData' ) ) , vec( get( LMKS(k) , 'ZData' ) ) ];
%       
%       lmk(1,:) = [1,0]*figurexy2axesxyz( axesxyz2figurexy( hDrawAxe , lmk(1,:) ) , THUMB.hAX );
%       lmk(2,:) = [1,0]*figurexy2axesxyz( axesxyz2figurexy( hDrawAxe , lmk(2,:) ) , THUMB.hAX );
%       lmk(:,3) = [-1,1]*0.1;
%       
%       xyz = [ lmk(1,:) ; xyz ; lmk(2,:) ];
%       set( THUMB.hK(k) , 'XData' , xyz(:,1) , 'YData' , xyz(:,2) , 'ZData' , xyz(:,3) );
%     end
%     end
  end
  function mouseMovedCallback( jListbox, jEventData )
    persistent lastID
    if isempty( lastID ), lastID = ACTIVE; end
    mousePos = java.awt.Point( jEventData.getX, jEventData.getY );
    ID = jListbox.locationToIndex(mousePos) + 1;
    if     ID == lastID
%     elseif ID == ACTIVE
%       THUMBnailFCN( 0 );
    elseif ID > R
      THUMBnailFCN( 0 );
    else
      THUMBnailFCN( ID );
    end
    lastID = ID;
  end
  function setT( t )
    T = t;
    T = mod( T-1 , size( IS{ACTIVE,1} ,4) )+1;
    hS = findall( hDrawAxe , 'Tag','drawContour.IMsurface' );
    feval( get( hS , 'UserData' ) , permute( IMA(:,:,:,T) , [1 2 3 4] ) );
    
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
