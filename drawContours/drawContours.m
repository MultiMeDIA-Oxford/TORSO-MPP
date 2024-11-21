function [ getXYZ , HH ] = drawContours( I0 , H , XYZ , varargin )
% 
% In order to get the correct pose of the data in the space, H must contain at least:
% H.PixelSpacing
% H.ImageOrientationPatient
% H.ImagePositionPatient
% 

% TODO:
% - allow to load temporal sequences
% - clicking with shift on LABELS checkboxes
% - real-time previos of Adder
% - ESCAPE key functionality (cancel accidental clicks)
% - get/set Image_contract function
% - exahustive test of SELECTOR (it is not working well enough)
% - add SELECTOR option to Move (like stretch)
% - exahustive test of Adder/Breaker, I think that sometimes it doesn't work well
% - improve the behaviour of Adder/Breaker on closed contours
% - fix axes limits on RotateView
% - automatic correction of self-intersections in offset
% - allow rounded offset / with right button
% - add alphaShape control on convexhull
% - bezier tool
% - REDO (CTRL+Y)
% - deform/move points with a weighted influence
% - improve the control of FlipH/FlipV
% - liveWire (with anchor points?)
% - fix horizontal/vertical discrete/prefixed displacements in Move
% - magnet/osnap to closest point
% - allow Adder to find intersection/mid points
% - simplify a segment
% - allow to replace instead of delete and re-create from scratch
% 


%#ok<*NOCOM>
%#ok<*TRYNC>

  if nargin < 1
    I0 = mean(double(imread('cameraman.tif')),3);
    close all;
    drawContours( I0 );
    return;
  end

  
  if isa( I0 , 'I3D' )
    if ~isstruct( H )
      varargin = [ XYZ , varargin ];
      XYZ = H;
      H = struct();
      H.SpatialTransform = I0.SpatialTransform;
      H.X = I0.X;
      H.Y = I0.Y;
      H.PixelSpacing = [ mean( diff( I0.X ) ) , mean( diff( I0.Y ) ) ];
      try, H = mergestruct( H , I0.INFO , '<'); end
      H = { H };
    else
      H = { [] };
    end
    [ getXYZ , HH ] = drawContours( permute( I0.data , [2 1 3 4:10] ) ,...
            H{:} , XYZ , varargin{:} );
    return;
  end

  d = fileparts( fileparts( mfilename('fullpath') ) );
  if isempty( which('polygon_mx') )  , addpath( fullfile( d , 'polygons' ) ); end
  if isempty( which('sub2indv') )    , addpath( fullfile( d , 'Tools' ) );    end
  if isempty( which('SetPosition') ) , addpath( fullfile( d , 'uiTools' ) );  end


  if nargin < 3, XYZ = []; end
  if ischar( XYZ ) && strcmpi( XYZ , 'restore' ), XYZ = getappdata( 0 , 'drawContours_RESTORE' ); end
  if ~iscell( XYZ ), XYZ = {XYZ}; end
  if numel( XYZ ) < 10, XYZ{10} = []; end

  if nargin < 2, H = []; end
  if isempty( H ), H = struct(); end
  if ~isstruct( H ), error( 'H was expected as a struct'); end
  if isfield( H , 'Filename' ) && isfield( H , 'Format' ) && strcmp( H.Format , 'DICOM' )
    try, H = DICOMxinfo( H ); catch LE, DE(LE); end
  end
  if isfield( H , 'PixelSpacing' ), H.PxSize = H.PixelSpacing; end
  if ~isfield( H , 'PxSize' ), H.PxSize = 1; end
  if numel( H.PxSize ) < 2, H.PxSize = [ 1 , 1 ]*H.PxSize; end
  
  if ( ~isfield( H , 'SpatialTransform' ) || isempty( H.SpatialTransform ) ) && isfield( H , 'xSpatialTransform' ) && ~isempty( H.xSpatialTransform ), H.SpatialTransform = H.xSpatialTransform; end
  if ~isfield( H , 'SpatialTransform' )
    try
      R = reshape( H.ImageOrientationPatient , 3 , 2 );
      R(:,3)= cross( R(:,1), R(:,2) );
      for cc = 1:3, for it = 1:5, R(:,cc) = R(:,cc)/sqrt( R(:,cc).' * R(:,cc) ); end; end

      R = [ R , H.ImagePositionPatient ; 0 0 0 1 ];
      H.SpatialTransform = R;
    catch LE, DE(LE);
      H.SpatialTransform = eye(4);
    end
  end
  if ~isequal( size( H.SpatialTransform ) , [4 4] ), error( 'H.SpatialTransform was expected as a 4x4 homo transf matrix'); end
  
  I0 = double( I0 )';
  if isempty( I0 )
    xyz = cell2mat( XYZ(:) ); xyz(:,end+1:3) = 0;
    if isempty( xyz )
    else

      if ~isfield( H , 'invSpatialTransform' ), H.invSpatialTransform = H.SpatialTransform \ eye(4); end
      xyz = bsxfun( @plus, xyz * H.invSpatialTransform(1:3,1:3).' , H.invSpatialTransform(1:3,4).' );
      
      H.X = [ min( xyz(:,1) , [] , 1 ) , max( xyz(:,1) , [] , 1 ) ];
      H.X = 1.5 * ( H.X - mean(H.X) ) + mean( H.X );
      
      H.Y = [ min( xyz(:,2) , [] , 1 ) , max( xyz(:,2) , [] , 1 ) ];
      H.Y = 1.5 * ( H.Y - mean(H.Y) ) + mean( H.Y );
      
      H.GrayLevel0 = 0;
      H.GrayLevel1 = 1;
      I0 = ones([2,2,3]);
    end
    
  end
  
  
  if ~isfield( H , 'X' ),  H.X  = ( 0:size(I0,1)-1 )*H.PxSize(1); end
  if ~isfield( H , 'Y' ),  H.Y  = ( 0:size(I0,2)-1 )*H.PxSize(2); end
  if ~isfield( H , 'XX' ) && ~isfield( H , 'YY' )
    [H.XX,H.YY] = ndgrid( H.X , H.Y );
  end
  if ~isfield( H , 'DX' ), H.DX = DualGrid( H.X ); end
  if ~isfield( H , 'DY' ), H.DY = DualGrid( H.Y ); end
  if ~isfield( H , 'DXX' ) && ~isfield( H , 'DYY' )
    [H.DXX,H.DYY] = ndgrid( H.DX , H.DY );
  end
  
  if ~isfield( H , 'GrayLevel0' ) || ~isfield( H , 'GrayLevel1' )
    H.GrayLevel0 = 0;
    H.GrayLevel1 = 0;
    prc = 10;
    while isequal( H.GrayLevel0 , H.GrayLevel1 )
      if prc < 1, prc = 0; end
      H.GrayLevel0 = prctile( I0(:) ,       prc );
      H.GrayLevel1 = prctile( I0(:) , 100 - prc );
      if ~prc, break; end
      prc = prc/2;
    end
  end
  if ~isfield( H , 'InterPointThreshold' )
    H.InterPointThreshold  = 1 * min( mean( diff( H.DX ) ) , mean( diff( H.DY ) ) );
  end
  H.InterPointThreshold2 = H.InterPointThreshold.^2;

  FCN = [];
  try, [varargin,~,FCN] = parseargs(varargin, 'FCN','$DEFS$',FCN); catch LE, DE(LE); end
  
  hParent = [];
  try, [varargin,~,hParent] = parseargs(varargin, 'PARENT','$DEFS$',hParent); catch LE, DE(LE); end
  if isempty( hParent )
%     oldDefaultFigureCreateFcn = get( 0 , 'DefaultFigureCreateFcn' );
%     set( 0 , 'DefaultFigureCreateFcn' , 'factory' );
    HH.Fig = figure('Toolbar','none','CreateFcn','','Renderer','opengl');
%     set( 0 , 'DefaultFigureCreateFcn' , oldDefaultFigureCreateFcn );
    colormap( HH.Fig , gray(256) );
    hParent = HH.Fig;
  else
    HH.Fig = ancestor( hParent , 'figure' );
  end
  
  
  if strcmp( get( hParent , 'Type' ) , 'axes' )
    HH.Axe = hParent;
  else
    HH.Axe = axes( 'Parent',hParent,'Position',[0 0 1 1] ,'CLim',[0 1]);
    set( HH.Axe , 'Visible','off' );
  end
  HH.Parent = get( HH.Axe , 'Parent' );
  HH.Surface = surface( 'XData', H.XX , 'YData', H.YY , 'ZData', zeros(size(H.XX)) , 'CData', I0 , 'FaceColor','interp' ,'EdgeColor','none','Hittest','on','Visible','off','UserData',@(IMdata)filterI0([],IMdata) ,'Tag','drawContour.IMsurface');
  drawnow('expose');
  if ~strcmp( get( HH.Fig , 'RendererMode' ) ,'manual' ), set( HH.Fig , 'RendererMode' ,'manual' ); end

  HH.Crosshair = line( 'XData', [0,0,0,0,0]+1e8 , 'YData', [0,0,0,0,0] ,'Linestyle',':','color',[1 .5 1],'Hittest','off','Visible','off');
  set( HH.Crosshair ,'ZData', NaN(1,5) );
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %contours objects
  matlabV = sscanf(version,'%d.%d.%d.%d.%d',5); matlabV=[100,1,1e-2,1e-9,1e-13]*[ matlabV(1:min(5,end)) ; zeros(5-numel(matlabV),1) ];
  if matlabV > 804,  HH.Contour = gobjects(1,10);
  else,              HH.Contour = zeros(1,10)-1;
  end
  RESTORE = cell( 1 , numel( HH.Contour ) );

  H.invSpatialTransform = minv( H.SpatialTransform );
  
  for LID = 1:numel( HH.Contour )
    switch LID
      case 1,  color = [4 0 0]/4;
      case 2,  color = [0 4 0]/4;
      case 3,  color = [0 0 4]/4;
      case 4,  color = [4 2 0]/4;
      case 5,  color = [2 0 2]/4;
      case 6,  color = [0 4 4]/4;
      case 7,  color = [2 0 0]/4;
      case 8,  color = [2 2 0]/4;
      case 9,  color = [3 1 1]/4;
      case 10, color = [1 1 3]/4;
    end

    xyz = XYZ{LID};  xyz(1:end,end+1:3) = 0;
    if     isempty( xyz ),             xyz = zeros(0,3);
    elseif any( isnan( xyz(end,:) ) ), xyz = [ xyz ; NaN(1,3) ]; %#ok<AGROW>
    else,  xyz = xyz( [1:end,end],: );
    end
    if ~isempty(xyz)
      xyz = bsxfun( @plus, xyz * H.invSpatialTransform(1:3,1:3).' , H.invSpatialTransform(1:3,4).' );
      r = max(abs(xyz(:,3)));
      if r > 1e-5
        warning('range in z too large (%g). Projecting on the xy-plane.',r);
      end
      xyz(:,3) = 0;
    end
    
    HH.Contour(LID) = line('XData',xyz(:,1),'YData',xyz(:,2),'ZData',xyz(:,3),'Color',color,'marker','.','linestyle','-','markerfacecolor',color,'markersize',3,'hittest','off','Tag',sprintf('drawContours.contour.%d',LID) );
    set( HH.Contour(LID) , 'ApplicationData', struct( 'UpdateContourFcn' , @(varargin)setCoords( varargin{:} ) ,'SetUndoFcn' , @(varargin)saveUNDO( varargin{:} ) ) );
    try, set( HH.Contour(LID) , 'PickableParts','none'); catch LE, DE(LE); end
    set( HH.Contour(LID) , 'UserData' , {zeros(0,2,'single')} );
  end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %add markers
  [varargin,~,MARKERS] = parseargs(varargin,'markers','$DEFS$',[]);
  if isnumeric( MARKERS ), MARKERS = { MARKERS }; end
  for m = 1:numel(MARKERS)
    if iscell( MARKERS )
      tMARKER = MARKERS{m};
    elseif isstruct( MARKERS )
      tMARKER = MARKERS(m);
    end
    if isstruct( tMARKER )
      MARKERopts = tMARKER;
      xyz        = tMARKER.xyz;
    else
      MARKERopts = [];
      xyz = tMARKER;
    end
    if isempty( xyz ), continue; end
    xyz = bsxfun( @plus, xyz * H.invSpatialTransform(1:3,1:3).' , H.invSpatialTransform(1:3,4).' );
    xyz(:,3) = 0;
 
    
    hM = [ line(xyz(:,1),xyz(:,2),xyz(:,3)+0.005,'Color',[0 1 1]); line(xyz(:,1),xyz(:,2),xyz(:,3)-0.005,'Color',[0 1 1]) ];
    try
      for o = fieldnames( MARKERopts ).', o = o{1};
        try, set( hM , o , MARKERopts.(o) ); end
      end        
    catch LE, DE(LE);
    end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  IF = I0;
  
  
  
  
  HH.GUIObjects = [];
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %Prepare the auxiliar objects in Parent
  %%%%Help
  HH.HelpPanel = uicontrol('Parent',HH.Parent,'Style','listbox','String',{'Help:'},'Tag','HelpPanel');
  set( HH.HelpPanel , 'Visible','off' );
  SetPosition( HH.HelpPanel , [ -300 , 5 , 330 , -25 ] , true );
  if true %HELP
  HelpString = {};
  HelpString{end+1} = '<b>CTRL</b>: show aux GUI controls';
  HelpString{end+1} = '----------';
  HelpString{end+1} = '<b>SPACE+click 1</b>: adjust intensity level-window';
  HelpString{end+1} = '<b>SPACE+doubleclick 1</b>: adjust intensity level-window';
  HelpString{end+1} = '<b>SPACE+click 2</b>: pan';
  HelpString{end+1} = '<b>SPACE+click 3</b>: zoom';
  HelpString{end+1} = '<b>SPACE+doubleclick 3</b>: zoom extents';
  HelpString{end+1} = '<b>SPACE+wheel</b>: zoom plus/minus';
  HelpString{end+1} = '<b>SPACE+UP</b>: flip view vertically';
  HelpString{end+1} = '<b>SPACE+DOWN</b>: flip view horizontally';
  HelpString{end+1} = '<b>SPACE+LEFT/RIGHT</b>: rotate view';
  HelpString{end+1} = '<b>G</b>: turn on/off grid';
  HelpString{end+1} = '<b>I</b>: switch flat/interpolated';
  HelpString{end+1} = '----------';
  HelpString{end+1} = '<b>click 1</b>: add point';
  HelpString{end+1} = '<b>drag 1</b>: draw lasso';
  HelpString{end+1} = '<b>click 3</b>: break contour and start a new segment';
  HelpString{end+1} = '----------';
  HelpString{end+1} = '<b>BACKSPACE</b>: one point back';
  HelpString{end+1} = '<b>SHIFT+BACKSPACE</b>: one segment back';
  HelpString{end+1} = '<b>CTRL+Z</b>: undo';
  HelpString{end+1} = '----------';
  HelpString{end+1} = '<b>X</b>: info panel';
  HelpString{end+1} = '<b>C</b>: close segment (if at least 3 points)';
  HelpString{end+1} = '<b>A</b>: add point/break segment';
  HelpString{end+1} = '<b>J</b>: join segments';
  HelpString{end+1} = '<b>U</b>: union regions';
  HelpString{end+1} = '<b>E</b>: select and delete points';
  HelpString{end+1} = '<b><font color="blue">M</b>: select and move points';
  HelpString{end+1} = '<b>D</b>: Ball corrector of existing contour';
  HelpString{end+1} = '<b>W</b>: weighted motion/deformation';
  HelpString{end+1} = '<b>T</b>: smooth a segment';
  HelpString{end+1} = '<b>O</b>: offset a segment';
  HelpString{end+1} = '<b>H</b>: convex hull';
  HelpString{end+1} = '<b><font color="blue">S</b>: convert segment in spline';
  HelpString{end+1} = '<b>L</b>: isophotes';
  HelpString{end+1} = '<b><font color="blue">B</b>: snap to boundary points';
  HelpString{end+1} = '<b><font color="red">Y</b>: lazy wire (aka intelligent scissors)';
  HelpString{end+1} = '----------';
  HelpString{end+1} = '<b>1</b>,<b>2</b> ... <b>9</b>: copy selection to label 1,2 ... or 9';
  HelpString{end+1} = '<b>CTRL+1</b> ... <b>CTRL+9</b>: change current label';
  HelpString{end+1} = '<b>SHIFT+CTRL+1</b> ...';
  HelpString{end+1} = '   ...<b>SHIFT+CTRL+9</b>: change current label hiding the others';
  end

  HelpButton = uicontrol('Parent',HH.Parent,'Style','togglebutton','Value',0,'String','H','Callback',@(h,e)ShowHelp(h),'ToolTipString','Show/Hide Help','Visible','off','BackgroundColor',[.9 .9 .3],'SelectionHighlight','off');
  HH.GUIObjects(end+1,1) = HelpButton;
  SetPosition( HH.GUIObjects(end) , [ -(20*numel(HH.GUIObjects)+1) , -20 , 20 , 20 ] , true );
  function ShowHelp( h )
    if strcmp( get(get(HH.Fig,'CurrentObject'),'Type') , 'uicontrol' )
      set(HH.Fig,'CurrentObject',HH.Fig);
      lostfocus(HH.Fig);
    end
    v = get( h , 'Value' );
    if v
      for b = HH.GUIObjects(:).'
        if h == b, continue; end
        if strcmp( get(b,'Type') ,'uicontrol') && strcmp( get(b,'Style') ,'togglebutton') && strcmp( get(b,'SelectionHighlight') ,'off')
          set( b , 'Value' , 0 );
          try, feval( get( b , 'Callback' ) , b , 0 ); catch LE, DE(LE); end
        end
      end
    end
    set( HH.HelpPanel , 'Visible' , onoff( v ) );
    uistack( HH.HelpPanel , 'top' );
    uistack( HH.GUIObjects , 'top' );
  end
  %%%%

  %%%%Zoom
  if true
    HH.ZoomAxe = [];
    HH.ZoomAxe = axes('Parent',HH.Parent,'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'ZTick',[],'Box','on','Visible','off','ZLim',[-1 1],'XColor',[1 0 1],'YColor',[1 0 1],'ZColor',[1 0 1],'Units','pixels','CLim',[0 1]);
    set( HH.ZoomAxe , 'XLim' , H.DX([1 end]) , 'YLim' , H.DY([1 end]) );
    SetPosition( HH.ZoomAxe , [ -201 , -201 , 200 , 200 ] , true );
    HH.ZoomSurface = surface( 'Parent', HH.ZoomAxe , 'XData', H.DXX , 'YData', H.DYY , 'ZData', zeros(size(H.DXX)) , 'CData', IF , 'FaceColor','flat' ,'EdgeColor',[0.7 , 0.7 , 0.3],'Hittest','off','Visible','off');
    HH.ZoomCenter  = line( 'Parent', HH.ZoomAxe , 'XData', [0 0] , 'YData', [0 0] , 'ZData', [-1,1]*0.1 , 'Marker','o','MarkerSize',4,'Hittest','off','Visible','off','MarkerFaceColor',[1 1 0],'Color',[1 0 1]);
    HH.ZPanel = uipanel('Parent',HH.Parent ,'BorderType','none' );
    SetPosition( HH.ZPanel , [ -71 , -20 , 71 , 20 ] , true );
    HH.FactorSpinner = javacomponent( com.mathworks.mwswing.MJSpinner(javax.swing.SpinnerNumberModel(8,4,50,1)) , [1 , 1 , 50 , 20] , HH.ZPanel );
    set( HH.FactorSpinner , 'StateChangedCallback' , @(h,e)setZoomFactor( h ) ,'ToolTipText','<html><b>Zoom factor</b><br/>number of pixels included in zoom<br/>Also, <b>Z+wheelUp</b>/<b>Z+wheelDown</b> can be used.<br/><b>Z++</b>/<b>Z+-</b> too.');
    setZoomFactor( HH.FactorSpinner );
    HH.ZoomPin = uicontrol('Parent',HH.ZPanel,'Style','togglebutton','Value',1,'Position',[51,1,20,20],'Callback',@(h,e)unPinZoom(h),'Visible','off');
    unPinZoom( HH.ZoomPin );
    HH.ZoomFrame = line('Parent',HH.Axe,'XData',NaN(1,5),'YData',NaN(1,5),'ZData',NaN(1,5),'Marker','+','MarkerSize',5,'Color',[1 0 1],'LineStyle',':','Visible','off');
    set( HH.ZPanel ,'Visible','off');
    for LID = 1:numel( HH.Contour )
      HH.ZoomContour(LID) = line('XData',get(HH.Contour(LID),'XData'),...
                                 'YData',get(HH.Contour(LID),'YData'),...
                                 'ZData',get(HH.Contour(LID),'ZData'),...
                                 'Color',get(HH.Contour(LID),'Color'),...
                                 'marker','none','linestyle','-','hittest','off','Visible','off','Clip','on' );
    end
    %HH.MousePositionListener = handle.listener( HH.Fig , 'WindowButtonMotionEvent' , @(h,e)UpdateZoom() );

    ZoomButton = uicontrol('Parent',HH.Parent,'Style','togglebutton','Value',0,'String','Z','Callback',@(h,e)ShowZoom(h),'ToolTipString','Show/Hide Zoom','Visible','off','BackgroundColor',[.8 .3 .3],'SelectionHighlight','off');
    HH.GUIObjects(end+1,1) = ZoomButton;
    SetPosition( HH.GUIObjects(end) , [ -(20*numel(HH.GUIObjects)+1) , -20 , 20 , 20 ] , true );
  end
  function ShowZoom( h )
    if strcmp( get(get(HH.Fig,'CurrentObject'),'Type') , 'uicontrol' )
      set(HH.Fig,'CurrentObject',HH.Fig);
      lostfocus(HH.Fig);
    end
    v = get( h , 'Value' );
    if v
      for b = HH.GUIObjects(:).'
        if h == b, continue; end
        if strcmp( get(b,'Type') ,'uicontrol') && strcmp( get(b,'Style') ,'togglebutton') && strcmp( get(b,'SelectionHighlight') ,'off')
          set( b , 'Value' , 0 );
          try, feval( get( b , 'Callback' ) , b , 0 ); catch LE, DE(LE); end
        end
      end
    end
    if v
      set( HH.ZoomPin , 'Value',1 ); unPinZoom( HH.ZoomPin );
    end
    
    v = onoff( v );
    set(      HH.ZoomFrame            , 'Visible' , v );
    set(      HH.ZoomAxe              , 'Visible' , v );
    set( get( HH.ZoomAxe ,'Children') , 'Visible' , v );
    set( HH.ZPanel                    , 'Visible' , v );
    set( HH.ZoomPin                   , 'Visible' , v );
    
    uistack( HH.ZoomFrame , 'top' );
    uistack( HH.ZoomAxe , 'top' );
    uistack( HH.GUIObjects , 'top' );
    
    UpdateZoom( );
  end
  function unPinZoom( h )
    if strcmp( get(get(HH.Fig,'CurrentObject'),'Type') , 'uicontrol' )
      set(HH.Fig,'CurrentObject',HH.Fig);
      lostfocus(HH.Fig);
    end
    v = get( h , 'Value' );
    
    if v
      set( h , 'ToolTipString','Unpin Zoom','CData',repmat([ones(1,18);ones(1,8),0.9,0.55,0.25,0.25,0.35,0.65,1,1,1,1;ones(1,7),0.9,0.35,0.55,0.8,0.8,0.45,0.2,0.65,1,1,1;ones(1,6),0.75,0.35,0.45,1,1,1,1,0.35,0.35,1,1,1;1,1,1,1,1,0.65,0.35,0.25,0.75,1,0.9,0.9,0.8,0.65,0.1,1,1,1;1,1,1,1,0.75,0.35,1,0.25,0.75,0.8,0.8,0.75,0.75,0.55,0.1,1,1,1;1,1,1,1,0.45,0.65,1,0.45,0.35,0.75,0.65,0.65,0.65,0.2,0.25,1,1,1;1,1,1,1,0.2,0.9,1,0.8,0.2,0.25,0.45,0.45,0.2,0.1,0.75,1,1,1;1,1,1,1,0.1,0.8,0.9,0.8,0.55,0.2,0.1,0,0.1,0,1,1,1,1;1,1,1,1,0.35,0.45,0.8,0.65,0.45,0.35,0.25,0.25,0.1,0.1,1,1,1,1;1,1,1,1,0.65,0.2,0.55,0.45,0.35,0.25,0.25,0.2,0,0.45,1,1,1,1;1,1,0.9,0.9,1,0.1,0.1,0.2,0.2,0.2,0.1,0,0.25,0.9,1,1,1,1;1,1,0.9,0.9,0,0.25,0.35,0.2,0,0,0.1,0.35,0.75,0.8,0.9,1,1,1;1,0.9,0.8,0.25,0.1,0.35,0.45,0.55,0.55,0.55,0.65,0.65,0.75,0.8,0.9,1,1,1;1,1,0.9,0.55,0.45,0.55,0.55,0.55,0.45,0.55,0.55,0.65,0.75,0.75,0.9,0.9,1,1;1,1,1,0.9,0.9,0.9,0.8,0.8,0.75,0.75,0.75,0.75,0.8,0.8,0.9,1,1,1],[1,1,3]));
      set( HH.ZoomAxe , 'LineWidth',3 );
      SetPosition( HH.ZoomAxe , [ -201 , -201 , 200 , 200 ] );
    else
      set( h , 'ToolTipString','Pin Zoom','CData',repmat([ones(1,18);ones(1,18);ones(1,6),0.15,0.15,ones(1,10);ones(1,6),0.15,1,0.15,ones(1,6),0.15,0.35,1;ones(1,6),0.15,0.85,1,0.15*ones(1,6),1,0,1;ones(1,6),0.15,0.85,1,0.35,1,1,1,1,0.5,0.85,0,1;1,1,0.85,0.85,0.65,0.65,0.15,0.65,0.65,0.35,0.65,0.65,0.65,0.65,0.35,0.65,0,1;1,0.15,0,0,0,0,0.15,0.5,0.5,0.15,0.5,0.5,0.5,0.5,0.15,0.5,0,1;ones(1,6),0.15,0.35,0.35,0,0.15,0.15,0.15,0.15,0,0.35,0,1;ones(1,6),0.15,0.35,0.15,zeros(1,8),1;1,0.85,0.85,0.85,0.85,0.85,0.15,0,0,0.35,0.65,0.65,0.65,0.65,0.65,0,0.15,1;1,0.85,0.65,0.65,0.5,0.5,0,0,0.35,0.5*ones(1,7),0.65,1;1,0.85,0.85,0.85,0.85,0.65,0.35,0.35,0.5*ones(1,9),1;1,0.85,0.85,0.85,0.85,0.85,0.65*ones(1,9),0.85,0.85,1;ones(1,18);ones(1,18)],[1,1,3]));
      set( HH.ZoomAxe , 'LineWidth',1 );
    end
    
    uistack( HH.ZoomAxe , 'top' );
    
    UpdateZoom( );
  end
  function UpdateZoom( cp )
    try,   if ~strcmp( get( HH.ZoomAxe , 'Visible' ) , 'on' ), return; end
    catch LE, DE(LE); return;
    end
    if ~nargin, cp = [0.5,0.5]*get( HH.Axe , 'CurrentPoint' ); end
    %if ~isfinite( cp(1) ), return; end
    f = get( HH.ZoomAxe , 'UserData' );
    nxl = cp(1) + [-1,1]*f;
    nyl = cp(2) + [-1,1]*f;
    set( HH.ZoomAxe , 'XLim' , nxl , 'YLim' , nyl );
    set( HH.ZoomCenter , 'XData' ,[0 0]+cp(1) , 'YData',[0 0]+cp(2) );
    set( HH.ZoomFrame  , 'XData', [ nxl(1) nxl(2) nxl(2) nxl(1) nxl(1) ] ,...
                         'YData', [ nyl(1) nyl(1) nyl(2) nyl(2) nyl(1) ] ,...
                         'ZData', zeros(1,5) + Z );
    
    if ~get( HH.ZoomPin , 'Value' )
%       fCP = get( HH.Fig , 'CurrentPoint' );
      fCP = parentxy( HH.Axe );
      set( HH.ZoomAxe , 'Position' , [ fCP(1) - 100 , fCP(2) - 100 , 200 , 200 ] );
    end
    
  end
  function setZoomFactor( h )
    f = get(h,'Value');
    if f > 15, set( HH.ZoomSurface , 'EdgeColor','none' );
    else,      set( HH.ZoomSurface , 'EdgeColor',[0.7 , 0.7 , 0.3] );
    end
    f = f * mean( diff( H.DY ) );
    set( HH.ZoomAxe , 'UserData' , f );
    xl = get( HH.ZoomAxe , 'XLim' );
    yl = get( HH.ZoomAxe , 'YLim' );
    set( HH.ZoomAxe , 'XLim' , mean(xl)+[-1,1]*f , 'YLim' , mean(yl)+[-1,1]*f );
    UpdateZoom( );
  end
  %%%%
  
  %%%%Navigator
  if true
%     HH.NavigatorAxe = [];
%     HH.NavigatorAxe = axes('Parent',HH.Parent,'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'ZTick',[],'Box','on','Visible','off','ZLim',[-1 1],'LineWidth',3,'XColor',[1 0 1],'YColor',[1 0 1],'ZColor',[1 0 1],'CLim',[0 1]);
%     c = [ H.DX(1)+H.DX(end) , H.DY(1)+H.DY(end) ]/2; r = max( H.DX(end)-H.DX(1) , H.DY(end)-H.DY(1) )/2*1.11;
%     set( HH.NavigatorAxe , 'XLim' , c(1)+[-1,1]*r , 'YLim' , c(2)+[-1,1]*r );
%     SetPosition( HH.NavigatorAxe , [ -201 , -201 , 200 , 200 ] , true );

    HH.NavigatorPanel = [];
    HH.NavigatorPanel = uimpanel( 'Parent',HH.Parent,'Units','pixels','LeftResizeControl','off','RightResizeControl','off','ConstrainedToParent','on','Position',[0 0 121 121+8],'title','Navigator','BorderType','none','BackgroundColor',[1 1 1],'Hittest','off');
    set( HH.NavigatorPanel , 'Visible','off','Glued',~~[1 1 0 0]);
    
    HH.NavigatorAxe = [];
    HH.NavigatorAxe = axes('Parent',HH.NavigatorPanel,'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'ZTick',[],'Box','on','Visible','off','ZLim',[-1 1],'LineWidth',1,'XColor',[1 0 1],'YColor',[1 0 1],'ZColor',[1 0 1],'CLim',[0 1]);
    set( HH.NavigatorAxe , 'Units','pixel','Position' , [2 2 120 120] ,'Hittest','off');
    c = [ H.DX(1)+H.DX(end) , H.DY(1)+H.DY(end) ]/2; r = max( H.DX(end)-H.DX(1) , H.DY(end)-H.DY(1) )/2*1.11;
    set( HH.NavigatorAxe , 'XLim' , c(1)+[-1,1]*r , 'YLim' , c(2)+[-1,1]*r );
    
    HH.NavigatorSurface = surface( 'Parent', HH.NavigatorAxe , 'XData', H.DXX , 'YData', H.DYY , 'ZData', zeros(size(H.DXX)) , 'CData', IF , 'FaceColor','flat' ,'EdgeColor','none','Hittest','off','Visible','on');
    HH.NavigatorArea = surface('Parent',HH.NavigatorAxe,'XData',NaN(2,2),'YData',NaN(2,2),'ZData',zeros(2,2),'LineWidth',1,...
      'EdgeColor',[1 0 1],'FaceAlpha',0.1,...
      'FaceColor',[1 1 0],'XLimInclude','off','YLimInclude','off' ,'Visible','on','hittest','on' );
    HH.NavigatorNegArea = surface('Parent',HH.NavigatorAxe,'XData',NaN(5,5),'YData',NaN(5,5),'ZData',zeros(5,5),'LineWidth',1,...
      'EdgeColor','none', 'CData', repmat([1 1 1 1 1;1 1 1 1 1;1 1 NaN 1 1;1 1 1 1 1;1 1 1 1 1],[1,1,3]) , 'FaceAlpha',0.8 , ...
      'FaceColor','interp','XLimInclude','off','YLimInclude','off' ,'Hittest','off' ,'Visible','on' );
    DRAGGING_NavigatorArea = false;
    set( HH.NavigatorArea , 'ButtonDownFcn', @(h,e) START_DRAG_on_NavigatorArea );
    %%%%addlistener( HH.Axe , 'XLim','PostSet',@UpdateAxesLims );
    %%%%addlistener( HH.Axe , 'YLim','PostSet',@UpdateAxesLims );

    NavigatorButton = uicontrol('Parent',HH.Parent,'Style','togglebutton','Value',0,'String','N','Callback',@(h,e)ShowNavigator(h),'ToolTipString','Show/Hide Navigator','Visible','off','BackgroundColor',[.3 .3 .9]);
    HH.GUIObjects(end+1,1) = NavigatorButton;
    SetPosition( HH.GUIObjects(end) , [ -(20*numel(HH.GUIObjects)+1) , -20 , 20 , 20 ] , true );
    set( HH.NavigatorPanel , 'HideRequestFcn' , @(h,e)set( NavigatorButton , 'Value' , 0 ) ); %@(h,e)HideNavigator() );
  end
  function HideNavigator()
    if strcmp( get(get(HH.Fig,'CurrentObject'),'Type') , 'uicontrol' )
      set(HH.Fig,'CurrentObject',HH.Fig);
      lostfocus(HH.Fig);
    end
    set( NavigatorButton , 'Value' , 0 );
  end
  function ShowNavigator( h )
    if strcmp( get(get(HH.Fig,'CurrentObject'),'Type') , 'uicontrol' )
      set(HH.Fig,'CurrentObject',HH.Fig);
      lostfocus(HH.Fig);
    end
    v = get( h , 'Value' );
    set(      HH.NavigatorPanel              , 'Visible' , onoff( v ) );
  end
  function UpdateAxesLims( h , e )
    if DRAGGING_NavigatorArea, return; end
    xl = get( HH.Axe , 'XLim' ); yl = get( HH.Axe , 'YLim' );
    set( HH.NavigatorArea , 'XData' , xl(:)*[1,1] , 'YData' , [1;1] * yl(:).' );
   
    xl = [ -1e5 , xl(1) , ( xl(2)+xl(1) )/2 , xl(2) , 1e5 ];
    yl = [ -1e5 , yl(1) , ( yl(2)+yl(1) )/2 , yl(2) , 1e5 ];
    set( HH.NavigatorNegArea , 'XData' , xl(:)*[1,1,1,1,1] , 'YData' , [1;1;1;1;1] * yl(:).' ,'zdata',zeros(5));
  end      
  function START_DRAG_on_NavigatorArea
%     disp('start dragging on Navigator');
    oldUP     = get( HH.Fig , 'WindowButtonUpFcn'     );
    oldMOTION = get( HH.Fig , 'WindowButtonMotionFcn' );

    set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e) DRAG    );
    set( HH.Fig , 'WindowButtonUpFcn'     , @(h,e) setOLDS );

    ocp = get( HH.NavigatorAxe , 'CurrentPoint' );
    oxl = get( HH.Axe , 'XLim' );
    oyl = get( HH.Axe , 'YLim' );
    scale = pressedkeys(3) == 4;
    function setOLDS
      set( HH.Fig , 'WindowButtonMotionFcn' , oldMOTION );
      set( HH.Fig , 'WindowButtonUpFcn'     , oldUP     );
      DRAGGING_NavigatorArea = false;
    end
    function DRAG
      DRAGGING_NavigatorArea = true;
      try
        cp = get( HH.NavigatorAxe , 'CurrentPoint' );
        
        if scale
          s = exp( ( cp(3) - ocp(3) )/150 );
          xl = ocp(1) + ( oxl - ocp(1) )*s;
          yl = ocp(3) + ( oyl - ocp(3) )*s;
        else
          xl = oxl + cp(1) - ocp(1);
          yl = oyl + cp(3) - ocp(3);
        end
        
        if xl(2) < H.DX(1) || xl(1) > H.DX(end) || yl(2) < H.DY(1) || yl(1) > H.DY(end), return; end
        
        set( HH.Axe , 'XLim' , xl , 'YLim' , yl );
        set( HH.NavigatorArea , 'XData' , xl(:)*[1 1] , 'YData' , [1;1] * yl(:).' );
        
        xl = [ -1e5 , xl(1) , ( xl(2)+xl(1) )/2 , xl(2) , 1e5 ];
        yl = [ -1e5 , yl(1) , ( yl(2)+yl(1) )/2 , yl(2) , 1e5 ];
        set( HH.NavigatorNegArea , 'XData' , xl(:)*[1,1,1,1,1] , 'YData' , [1;1;1;1;1] * yl(:).' ,'zdata',zeros(5));
      catch LE, DE(LE);
      end
    end
  end
  %%%%

  %%%%IntensityControl
  if true
    HH.IControlPanel = [];
%     HH.IControlPanel = uipanel('Parent',HH.Parent,'Units','pixels','Visible','off');
%     SetPosition( HH.IControlPanel , [-227 1 228 130] , true );
    HH.IControlPanel = uimpanel('Parent',HH.Parent,'Units','pixels','RightResizeControl','off','LeftResizeControl','on','ConstrainedToParent','on','Position',[1 1 228 138],'Title','Intensity Control','BorderType','none','BackgroundColor',[1 1 1]);
    set( HH.IControlPanel , 'Visible','off','Glued',~~[0 1 1 0]);
    mI = min( I0(:) ); MI = max( I0(:) ); r = ( mI + MI )/2 + [-1,1]*( MI - mI )/2*1.1;
    if isequal(r,[1 1]), r = [0 1]; end
    HH.IControlHistoAxe = axes('Parent',HH.IControlPanel,'Units','pixels','Position',[10 10 180 100],...
        'XAxisLocation','Top',...
        'GridLineStyle',':',...
        'FontSize',7,'YScale','linear','YGrid','on','XGrid','on','Layer','top',...
        'XTick',[],'YTick',[1],'ZTick',[],'YTickLabel',{},'Box','off','ZLim',[-1 1],'XLim',r,'YLim',[-0.01 , 1.1] ,'hittest','on' );
    HH.IControlLevel(1) = line('Parent',HH.Axe     ,'XData',NaN,'YData',NaN,'linewidth',1,'linestyle','-','marker','none',...
      'Color',[1 0 1],'Visible','off','XLimInclude','off','YLimInclude','off' ,'hittest','off' );
%     HH.IControlLevel(2) = line('Parent',HH.ZoomAxe ,'XData',NaN,'YData',NaN,'linewidth',1,'linestyle','-','marker','none',...
%       'Color',[1 0 1],'Visible','off','XLimInclude','off','YLimInclude','off' ,'hittest','off' );
    HH.IControlHisto = ImageHisto( IF , 'Parent' , HH.IControlHistoAxe ,'hittest','off' );
    HH.IControlCBarAxe = axes('Parent',HH.IControlPanel,'Units','pixels','Position',[190 10 10 100],...
        'Color',[1 0 0]*0.5 ,...
        'Layer','top','YAxisLocation','right',...
        'GridLineStyle',':',...
        'FontSize',7,'YScale','linear','YGrid','on','XGrid','off',...
        'XTick',[],'YTick',[],'ZTick',[],'Box','off','ZLim',[-1 1],'XLim',[-2 2],'YLim',[-0.01 , 1.1] ,'hittest','on' );
    HH.IControlCBar = image(  repmat( linspace(0,1,128).' , [1 1 3] ) , 'Parent',HH.IControlCBarAxe , 'YData' , [0 1] ,'XData',[-1 1]);
    set( HH.IControlCBarAxe ,'YDir','normal',...
        'Color',[1 0 0]*0.5 ,...
        'Layer','top','YAxisLocation','right',...
        'GridLineStyle',':',...
        'FontSize',7,'YScale','linear','YGrid','on','XGrid','off',...
        'XTick',[],'YTick',[],'ZTick',[],'Box','off','ZLim',[-1 1],'XLim',[-2 2],'YLim',[-0.01 , 1.1] ,'hittest','on' );

      IT = [ H.GrayLevel0 , 0 ; H.GrayLevel1 , 1 ];
      AV        = struct('action',{},'FCN',{},'menu',{});
      AV(end+1) = struct('action',{{'BUTTON30' 'LSHIFT'}},'FCN',@(IP,v) deleteVertice(IP,v,2)   ,'menu','Delete' );
      AV(end+1) = struct('action',{{'BUTTON1'          }},'FCN',@(IP,v) AV_moveAsFunction(IP,v) ,'menu','Move'   );
      AV(end+1) = struct('action',{{'BUTTON1' 'LSHIFT' }},'FCN',@(IP,v) AV_moveAsFunction(IP,v) ,'menu',''       );
      AV(end+1) = struct('action',{{'kk'               }},'FCN',@(IP,v) AV_setcoordinates(IP,v) ,'menu','Set'    );
      AL        = struct('action',{},'FCN',{},'menu',{});
      AL(end+1) = struct('action',{{'BUTTON10'         }},'FCN',@(IP) insertVertice(IP)  ,'menu','Insert'  );
      AL(end+1) = struct('action',{{'BUTTON10' 'LSHIFT'}},'FCN',@(IP) insertVertice(IP)  ,'menu',''        );
      AL(end+1) = struct('action',{{'BUTTON1'          }},'FCN',@(IP) AL_moveX(IP)       ,'menu',''   );
      AL(end+1) = struct('action',{{'BUTTON1' 'LSHIFT' }},'FCN',@(IP) AL_deform(IP)      ,'menu',''   );
      AL(end+1) = struct('action',{{'kk'               }},'FCN',@(IP) setVertices(IP,[IT,[0;0]],'update'),'menu','Reset'   );
      
      HH.IT = InteractivePolygon( [ [ -1e15 ; IT(:,1) ; 1e15 ] , IT([ 1 , 1:end , end],2) ]  ,...
        'Parent' , HH.IControlHistoAxe                    ,...
        'constrain',@(xyz,IP,i) min(max(xyz,[NaN 0 0]),[NaN 1 0]) ,...
        'fcn' ,@(IP) ActionOnIT(IP)   ,...
        'AV',AV,'AL',AL,'line','open'            );
      ActionOnIT( HH.IT );
      setIT( HH.IT );
    
    IControlButton = uicontrol('Parent',HH.Parent,'Style','togglebutton','String','IC','Callback',@(h,e)ShowIControl(h),'ToolTipString','Show Intensity Control','Visible','off','Value',0);
    HH.GUIObjects(end+1,1) = IControlButton;
    SetPosition( HH.GUIObjects(end) , [ -(20*numel(HH.GUIObjects)+1) , -20 , 20 , 20 ] , true );
    set( HH.IControlPanel , 'HideRequestFcn' , @(h,e)set( IControlButton , 'Value' , 0 ) );
    set( HH.IControlPanel , 'MinimumSize' , [ 140 80 ] );
    set( HH.IControlPanel , 'resizefcn', @(h,e) ResizeIControlPanel() );
  end
  function ResizeIControlPanel()
    pos = get( HH.IControlPanel , 'Position' );
    
    set( HH.IControlHistoAxe , 'Position' , [ 10 , 10 , pos(3) - 228 + 180 , pos(4) - 138 + 100] );
    set( HH.IControlCBarAxe  , 'Position' , [ pos(3)-228 + 190 , 10 , 10 , pos(4) - 138 + 100] );
  end
  function ShowIControl( h )
    if strcmp( get(get(HH.Fig,'CurrentObject'),'Type') , 'uicontrol' )
      set(HH.Fig,'CurrentObject',HH.Fig);
      lostfocus(HH.Fig);
    end
    v = get( h , 'Value' );
    set(      HH.IControlPanel              , 'Visible' , onoff( v ) );
  end
  function ActionOnIT( IP )
    v = IP.vertices;
    setIT( v(2:end-1,1:2) );

    v( 1 ,2) = v( 2   ,2);
    v(end,2) = v(end-1,2);
    
    set( IP.line , 'YData' , v(:,2) );

    vhandles = IP.vhandles;
    %'Marker','o','MarkerSize',7,'MarkerFaceColor',[0 1 1]
    set( vhandles , 'MarkerFaceColor',[1 0 0] , 'color',[0 0 0] );
    set( vhandles( 1   ) , 'YData' , v( 1 ,2) );
    set( vhandles( end ) , 'YData' , v(end,2) );
  end      
  function setIT( IT )
    RGB = toGray( IF , IT );
    try, set( HH.Surface          , 'CData' , RGB ); catch LE, DE(LE); end
    try, set( HH.ZoomSurface      , 'CData' , RGB ); catch LE, DE(LE); end
    try, set( HH.NavigatorSurface , 'CData' , RGB ); catch LE, DE(LE); end
    UpdateIControl( [] , false );
  end
  function UpdateIControl( x , showLevel )
    try
      if ~strcmp( get( HH.IControlPanel , 'Visible' ) , 'on' )
        return;
      end
    catch LE, DE(LE); 
      return;
    end
    
    if ~isequal( ancestor( hittest() , 'axes' ) , HH.IControlHistoAxe ) || ( ~isempty(x) && isnan( x ) )
      set( HH.IControlHistoAxe , 'XTick' , [] );
      set( HH.IControlHistoAxe , 'YTick' , 1 );
      set( HH.IControlCBarAxe , 'YTick' , [] , 'YTickLabel', {} );
      set( HH.IControlLevel , 'Visible','off' );
      return;
    end
    
    if isempty( x )
      x = get( HH.IControlHistoAxe , 'CurrentPoint' );
    end
    
    set( HH.IControlHistoAxe , 'XTick' , x(1) );
    y = toGray( x(1) , HH.IT );
    set( HH.IControlHistoAxe , 'YTick' , unique( [y 1] ) );
    set( HH.IControlCBarAxe , 'YTick' , y , 'YTickLabel',sprintf('%0.02f',y) );
    
    if showLevel
      try
        c = contourc( H.X , H.Y , IF.' , [1 1]*x(1) ); c = c.';
        i = 1; while i <= size(c,1), c(i,1) = NaN; i = i + c(i,2) + 1; end

        set( HH.IControlLevel , 'XData', c(:,1) , 'YData' , c(:,2) );
      catch LE, DE(LE); 
        set( HH.IControlLevel , 'Visible','off' );
      end
      set( HH.IControlLevel , 'Visible','on' );
    else
      set( HH.IControlLevel , 'Visible','off' );
    end
  end
  %%%%

  function filterI0( s0 , IMdata )
    if isempty( s0 ), s0 = FILTERSIZE; end
    %fprintf('Filtering at %g ...',s0);
    
    if nargin < 2, IMdata = I0; end
    IMdata = double(IMdata);
    
    s = s0 / mean( H.PxSize );
    if s <= 1e-1
      IF = IMdata;
    else
      try
        START_('                 ');
        set( HGS{2} , 'String' , sprintf('Filtering at: %.2f',s) );
      catch LE, DE(LE);
      end
%       g = ceil(s)*3;
%       g = -g:g;
%       g = gaussianKernel( g , g , 's' , s );
%       g = g/sum(g(:));
%       IF = imfilter( IMdata , g , 'same' , 'replicate' );
      IF = gsmooth( IMdata , s , 'replicate' );
      try, clearHGS( ); catch LE, DE(LE); end
    end
    setIT( HH.IT );
    try, ImageHisto( IF , HH.IControlHisto ); catch LE, DE(LE); end
    try, FILTERSIZE = s0; catch LE, DE(LE); end
    %fprintf(' done\n');
  end
  
  %%%Labels control
  if true
    HH.GUIObjects(end+1,1)  = uipanel('Parent',HH.Parent,'BorderType','beveledout','Units','pixels','BorderWidth',2,'Visible','off','Position',[0 -100 10 10]);
    for LID = 1:numel( HH.Contour )
      HH.LabelButton( LID ) = uicontrol('Parent',HH.GUIObjects(end),'Style','togglebutton','Units','pixels','Position',[ 6 + 35*(LID-1) , 5 , 35 , 35 ],...
        'String',sprintf('%d',LID),'FontWeight','bold','BackgroundColor', get( HH.Contour(LID) , 'Color' ),'Callback',@(h,e)ChangeCLid(LID,any(strcmp(pressedkeys,'LSHIFT'))),...
        'ToolTipString',sprintf('Set Label %d as Current',LID) ,'Visible','off','Tag',sprintf('LabelButton.%02d',LID) );
      HH.LabelVisible( LID ) = uicontrol('Parent',HH.GUIObjects(end),'Style','checkbox','Units','pixels','Position',[ 6 + 35*(LID-1) , 3 , 12 , 12 ],'Value',1,...
        'Callback',@(h,e)set( HH.Contour(LID) ,'Visible', onoff(h,'Value') ),...
        'ToolTipString',sprintf('<html>Show/Hide Label %d<br/><b>SHIFT</b> to act on all</html>',LID) ,'Visible','off');
    end
    SetPosition( HH.GUIObjects(end) , [ 1 , -48 , 365 , 47 ] , true );
  end
  %%%%

  
  FILTERSIZE = 0.1;
  [varargin,~,FILTERSIZE] = parseargs(varargin,'FILTERSIZE','$DEFS$',FILTERSIZE);
  filterI0( FILTERSIZE );

  
  
  %%sort parent's children uistack
  CH = get( HH.Parent , 'Children' );
  newCH = [];
  for c = 1:numel( CH )
    thisCH = CH(c);
    if any( thisCH == HH.GUIObjects )
      newCH = [ thisCH ; newCH ];
    else
      newCH = [ newCH ; thisCH ];
    end
  end
  set( HH.Parent , 'Children' , newCH );
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


  CLid = [];
  try, [varargin,~,CLid] = parseargs(varargin, 'CLID' , '$DEFS$', CLid ); catch LE, DE(LE); end
  if isempty(CLid) || ~CLid, CLid = 1; end
  L = HH.Contour(CLid); set( L , 'Marker','o' );
  try, set( HH.LabelButton( CLid )  , 'Value' , 1 );        catch LE, DE(LE); end
  try, set( HH.LabelVisible( CLid ) , 'Visible' , 'off' );  catch LE, DE(LE); end
  
  
  HGS = {};  PP  = [];  LASTTIME = 0;
  
  
  SuspendFigure( HH.Fig , 'Help' , HelpString );
       set(  HH.Axe          , 'ZLim',[-1 1],'DataAspectratio',[1 1 1] );
  try, set(  HH.ZoomAxe      , 'ZLim',[-1 1],'DataAspectratio',[1 1 1] ); catch LE, DE(LE); end
  try, set(  HH.NavigatorAxe , 'ZLim',[-1 1],'DataAspectratio',[1 1 1] ); catch LE, DE(LE); end
       view( HH.Axe          , [ 0 , -90 ] );
  try, view( HH.ZoomAxe      , [ 0 , -90 ] ); catch LE, DE(LE); end
  try, view( HH.NavigatorAxe , [ 0 , -90 ] ); catch LE, DE(LE); end
       set(  HH.Axe          , 'CameraUpVector' , [0,-1,0] );
  try, set(  HH.ZoomAxe      , 'CameraUpVector' , [0,-1,0] ); catch LE, DE(LE); end
  try, set(  HH.NavigatorAxe , 'CameraUpVector' , [0,-1,0] ); catch LE, DE(LE); end
  Z = -0.01;
  ZoomExtents( );
  %RESET_Window( );
  
  UNATTENDED_TIME = Inf;
  try, [varargin,~,UNATTENDED_TIME] = parseargs(varargin, 'UNATTENDED' , '$DEFS$', UNATTENDED_TIME ); catch LE, DE(LE); end %#ok<ASGLU>
  HH.UNATTENDED = [];
  if ~isinf( UNATTENDED_TIME )
    set( HH.Axe , 'UserData' , now );
    HH.UNATTENDED = timer( 'TimerFcn' , @(h,e)UNATTENDED(UNATTENDED_TIME) , 'StartDelay' , UNATTENDED_TIME , 'ExecutionMode' , 'fixedSpacing' , 'Period' , 5 );
  end
  
  function UNATTENDED( seconds )
    if etime( now , get( HH.Axe , 'UserData' ) ) > seconds
      delete( HH.Fig );
    end
  end
  
  drawnow;
  set( HH.Axe , 'DeleteFcn' , @(h,e) DeletingAxes( ) );

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %core of the GUI actions
  ZObj = zoom( HH.Fig ); PObj = pan( HH.Fig ); RObj = rotate3d( HH.Fig );
  set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)ActionsOnFigure( ) );
  set( HH.Fig , 'WindowKeyPressFcn'     , @(h,e)ActionsOnFigure( [ 'K' , e.Key ] ) );
  set( HH.Fig , 'WindowKeyReleaseFcn'   , @(h,e)ActionsOnFigure( [ 'R' , e.Key ] ) );
  set( HH.Fig , 'WindowButtonDownFcn'   , @(h,e)ActionsOnFigure(   'B' ) );
  set( HH.Fig , 'WindowScrollWheelFcn'  , @(h,e)ActionsOnFigure( [ 'W'  , char( ( 1 - e.VerticalScrollCount )/2 * 17 + 'D' ) ] ) );
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  set( HH.Axe , 'UserData' , now );
  if ~isempty( HH.UNATTENDED ), start( HH.UNATTENDED ); end
  
  
  set( HH.Fig , 'CurrentAxes' , HH.Axe );
  set( HH.Surface , 'Visible' , 'on' );
  

  DECORATEfcn = [];
  try, [varargin,~,DECORATEfcn] = parseargs(varargin, 'DECORATEfcn' , '$DEFS$',DECORATEfcn ); catch LE, DE(LE); end %#ok<ASGLU>
  try, feval( DECORATEfcn , HH.Parent ); catch LE, DE(LE); end
  
  set( HH.LabelButton   , 'Visible','on' );
  set( HH.LabelVisible  , 'Visible','on' );
  
  
  WAIT = false;
  try, [varargin,WAIT] = parseargs(varargin, 'WAITfor' , '$FORCE$',{true,WAIT} ); catch LE, DE(LE); end %#ok<ASGLU>
  if ~WAIT
    getXYZ = @(i)bsxfun( @plus , H.SpatialTransform(1:3,4).' , getCoords( HH.Contour(i) ) * H.SpatialTransform(1:3,1:3).' );
  else
    waitfor( HH.Axe );
    getXYZ = RESTORE;
  end
  
  
  function ActionsOnFigure( ev )
    set( HH.Axe , 'UserData' , now );
    if strcmp( ZObj.Enable , 'on' ) || strcmp( PObj.Enable , 'on' ) || strcmp( RObj.Enable , 'on' ), return; end

    pk = pressedkeys(1);
    if     nargin == 0
    elseif ~ischar( ev )
    elseif isequal( ev , 'B' )
      Button = strncmp( pk , 'BUTTON' , 6 );
      switch sum( Button )
        case 0, return; %disp('no button!!'); return;
        case 1,
          pk{ Button } = [ 'PRESS' , pk{ Button } ];
          if strcmp( get( HH.Fig , 'SelectionType' ) , 'open' )
            pk{ Button } = [ pk{ Button } , '0' ];
          end
        otherwise, disp( 'too much buttons pressed at the same time!' ); return;
      end
    elseif isequal( ev , 'WD' )
      pk = [ pk , { 'WHEELDOWN' } ];
    elseif isequal( ev , 'WU' )
      pk = [ pk , { 'WHEELUP' } ];
    elseif numel( ev ) > 1 && isequal( ev(1) , 'K' )
      k = MAPkeys( upper( ev(2:end) ) );
      Key = strcmp( pk , k );
      if ~any( Key )
        return; %disp('no key detected?'); return;
      end
      pk = [ pk( ~Key ) , { [ 'PRESS-' , k ] } ];
    elseif numel( ev ) > 1 && isequal( ev(1) , 'R' )
      k = MAPkeys( upper( ev(2:end) ) );
      Key = strcmp( pk , k );
      if any( Key )
        return; %disp('why key detected?'); return;
      end
      pk = [ pk , { [ 'RELEASE-' , k ] } ];
    end
    
    %%AXES independent ACTIONS
    PERFORMED = true;
    if     false
    elseif CELLeq( pk , {'PRESS-LCONTROL'} ),                               try, set( HH.GUIObjects , 'Visible','on' ); catch LE, DE(LE); end
    elseif CELLeq( pk , {'RELEASE-LCONTROL'} )
      start( timer( 'TimerFcn' , @(h,e)set( areH( HH.GUIObjects ) , 'Visible','off' ) , 'StartDelay' , 2 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe)) ) );
    elseif CELLeq( pk , {'Z','WHEELUP'} )   || CELLeq( pk , {'Z','PRESS-ADD'} ),      try, if onoff( get( HH.ZoomAxe , 'Visible' ) ), set( HH.FactorSpinner , 'Value' , max(4  ,get( HH.FactorSpinner , 'Value' ) - 1) ); setZoomFactor( HH.FactorSpinner ); end; catch LE, DE(LE); end
    elseif CELLeq( pk , {'Z','WHEELDOWN'} ) || CELLeq( pk , {'Z','PRESS-SUBTRACT'} ), try, if onoff( get( HH.ZoomAxe , 'Visible' ) ), set( HH.FactorSpinner , 'Value' , min(200,get( HH.FactorSpinner , 'Value' ) + 1) ); setZoomFactor( HH.FactorSpinner ); end; catch LE, DE(LE); end

    elseif CELLeq( pk , {'PRESSBUTTON1','SPACE'} ),                         START_ChangeWindow( );
    elseif CELLeq( pk , {'BUTTON1','SPACE'} ),                              START_ChangeWindow( );
    elseif CELLeq( pk , {'PRESSBUTTON10','SPACE'} ),                        RESET_Window( true );

    elseif CELLeq( pk , {'PRESS-F1'} ),                                     set( HelpButton ,'Value',~get( HelpButton , 'Value') ); ShowHelp( HelpButton );
    elseif CELLeq( pk , {'PRESS-F2'} )
      v = get( ZoomButton , 'Value' );
      p = get( HH.ZoomPin , 'Value' );
      switch char( [v p] + '0' )
        case {'00','01'}
          set( ZoomButton , 'Value' , 1 );
          ShowZoom( ZoomButton );
        case {'11'}
          set( HH.ZoomPin , 'Value' , 0 );
          unPinZoom( HH.ZoomPin );
        case {'10'}
          set( ZoomButton , 'Value' , 0 );
          ShowZoom( ZoomButton );
      end
    elseif CELLeq( pk , {'PRESS-F3'} ),                                     set( NavigatorButton ,'Value',~get( NavigatorButton , 'Value') ); ShowNavigator( NavigatorButton );
    elseif CELLeq( pk , {'PRESS-F4'} ),                                     set( IControlButton ,'Value',~get( IControlButton , 'Value') ); ShowIControl( IControlButton );
    else, PERFORMED = false;
    end
    if PERFORMED, return; end

    %%AXES dependent ACTIONS
    ht = hittest();
    ON_AXE = []; try, ON_AXE = ancestor( ht , 'axes' ); catch LE, DE(LE); end
    
    if isequal( ON_AXE , HH.IControlHistoAxe )
      UpdateIControl( [] , true );
      return;
    end
    UpdateIControl( NaN , false );
    
    if ~isequal( ON_AXE , HH.Axe ) && ~isequal( ON_AXE , HH.ZoomAxe ), return; end
    if isequal( ON_AXE , HH.ZoomAxe ), pk( strcmp( pk , 'LSHIFT' ) ) = []; end
    
    %%main AXE ACTIONS
    PERFORMED = true;
    if     CELLeq( pk , {} ),                                               setLastPoint( gCP( ) );
    elseif CELLeq( pk , {'PRESSBUTTON1'} ),                                 setLastPoint( [1;1]*gCP( ) );
    elseif CELLeq( pk , {'BUTTON1'} ),                                      setLastPoint( [1;1]*gCP( ) , H.InterPointThreshold2/16 , 1/150 );
    elseif CELLeq( pk , {'PRESSBUTTON3'} ),                                 setLastPoint( [ NaN(1,3) ; gCP( ) ] );
    elseif CELLeq( pk , {'BUTTON3'} ),                                      setLastPoint( [ NaN(1,3) ; gCP( ) ] );

    elseif CELLeq( pk , {'SPACE','WHEELUP'} ),                              WheelZoom( 1/1.2 );
    elseif CELLeq( pk , {'SPACE','WHEELDOWN'} ),                            WheelZoom(   1.2 );
    elseif CELLeq( pk , {'PRESSBUTTON2','SPACE'} ),                         START_Pan( );
    elseif CELLeq( pk , {'PRESSBUTTON3','SPACE'} ),                         START_Zoom( );
    elseif CELLeq( pk , {'BUTTON3','SPACE'} ),                              START_Zoom( );
    elseif CELLeq( pk , {'PRESSBUTTON30','SPACE'} ),                        ZoomExtents( true );
    elseif CELLeq( pk , {'RELEASE-G'} ),                                    SwitchGrid( );
    elseif CELLeq( pk , {'RELEASE-I'} ),                                    SwitchInterpolation( );

    elseif CELLeq( pk , {'RELEASE-CAPITAL'} ),                              CrosshairONOff(); 
    
    elseif CELLeq( pk , {'F','WHEELUP'} ),                                  FILTERSIZE = max(1e-1,FILTERSIZE)*1.15; filterI0( FILTERSIZE );
    elseif CELLeq( pk , {'F','WHEELDOWN'} ),                                FILTERSIZE = FILTERSIZE/1.15/1.15;      filterI0( FILTERSIZE );
      
      
    elseif CELLeq( pk , {'PRESS-BACK'} ),                                   removeLastPoint( );   setLastPoint( gCP( ) );
    elseif CELLeq( pk , {'LSHIFT','PRESS-BACK'} ),                          removeLastSegment( ); setLastPoint( gCP( ) );
    elseif CELLeq( pk , {'LCONTROL','PRESS-Z'} ),                           UNDO( );              setLastPoint( gCP( ) );

    elseif CELLeq( pk , {'PRESS-X'} ),                                      START_Info( );
    elseif CELLeq( pk , {'PRESS-C'} ),                                      START_Close( );
    elseif CELLeq( pk , {'PRESS-A'} ),                                      START_Adder( );
    elseif CELLeq( pk , {'PRESS-J'} ),                                      START_Joiner( );
    elseif CELLeq( pk , {'PRESS-U'} ),                                      START_Union( );
    elseif CELLeq( pk , {'PRESS-E'} )||CELLeq( pk , {'SPACE','PRESS-E'} ),  START_Eraser( );
    elseif CELLeq( pk , {'PRESS-M'} ),                                      START_Move( );
    elseif CELLeq( pk , {'PRESS-W'} ),                                      START_WMove( );
    elseif CELLeq( pk , {'PRESS-D'} ),                                      START_Corrector( );
    elseif CELLeq( pk , {'PRESS-O'} ),                                      START_Offset( );
    elseif CELLeq( pk , {'PRESS-R'} ),                                      START_Circle( );
    elseif CELLeq( pk , {'PRESS-H'} ),                                      START_ConvexHull( );
    elseif CELLeq( pk , {'PRESS-S'} ),                                      START_ConvertToSpline( );
    elseif CELLeq( pk , {'PRESS-L'} ),                                      START_Isophote( );
    elseif CELLeq( pk , {'PRESS-B'} ),                                      START_Snap( );
    %elseif CELLeq( pk , {'PRESS-Y'} ),                                      START_LazyWire( );
    elseif CELLeq( pk , {'PRESS-T'} ),                                      START_Smooth( );
    
    elseif CELLeq( pk , {'PRESS-1'} ),                                      START_CopyTo( 1 );
    elseif CELLeq( pk , {'PRESS-2'} ),                                      START_CopyTo( 2 );
    elseif CELLeq( pk , {'PRESS-3'} ),                                      START_CopyTo( 3 );
    elseif CELLeq( pk , {'PRESS-4'} ),                                      START_CopyTo( 4 );
    elseif CELLeq( pk , {'PRESS-5'} ),                                      START_CopyTo( 5 );
    elseif CELLeq( pk , {'PRESS-6'} ),                                      START_CopyTo( 6 );
    elseif CELLeq( pk , {'PRESS-7'} ),                                      START_CopyTo( 7 );
    elseif CELLeq( pk , {'PRESS-8'} ),                                      START_CopyTo( 8 );
    elseif CELLeq( pk , {'PRESS-9'} ),                                      START_CopyTo( 9 );
    elseif CELLeq( pk , {'PRESS-0'} ),                                      START_CopyTo( 0 );

    elseif CELLeq( pk , {'LCONTROL','RELEASE-1'} ),                         ChangeCLid( 1  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-2'} ),                         ChangeCLid( 2  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-3'} ),                         ChangeCLid( 3  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-4'} ),                         ChangeCLid( 4  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-5'} ),                         ChangeCLid( 5  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-6'} ),                         ChangeCLid( 6  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-7'} ),                         ChangeCLid( 7  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-8'} ),                         ChangeCLid( 8  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-9'} ),                         ChangeCLid( 9  );
    elseif CELLeq( pk , {'LCONTROL','RELEASE-0'} ),                         ChangeCLid( 10 );

    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-1'} ),                ChangeCLid( 1  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-2'} ),                ChangeCLid( 2  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-3'} ),                ChangeCLid( 3  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-4'} ),                ChangeCLid( 4  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-5'} ),                ChangeCLid( 5  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-6'} ),                ChangeCLid( 6  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-7'} ),                ChangeCLid( 7  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-8'} ),                ChangeCLid( 8  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-9'} ),                ChangeCLid( 9  , true );
    elseif CELLeq( pk , {'LSHIFT','LCONTROL','RELEASE-0'} ),                ChangeCLid( 10 , true );

    elseif CELLeq( pk , {'SPACE','PRESS-UP'} ),                             FlipV( ); setLastPoint( gCP( ) );
    elseif CELLeq( pk , {'SPACE','PRESS-DOWN'} ),                           FlipH( ); setLastPoint( gCP( ) );
    elseif CELLeq( pk , {'SPACE','PRESS-RIGHT'} ),                          RotateView(  1 ); setLastPoint( gCP( ) );
    elseif CELLeq( pk , {'SPACE','PRESS-LEFT'} ),                           RotateView( -1 ); setLastPoint( gCP( ) );
    else, PERFORMED = false;
    end
    if PERFORMED, return; end

    %try, set( HH.Fig , 'Name' , uneval(pk) ); catch LE, DE(LE); end
    
    function K = MAPkeys( K )
      switch K
        case 'CONTROL',     K = 'LCONTROL';
        case 'SHIFT',       K = 'LSHIFT';
        case 'BACKSPACE',   K = 'BACK';
        case 'LEFTARROW',   K = 'LEFT';
        case 'RIGHTARROW',  K = 'RIGHT';
        case 'UPARROW',     K = 'UP';
        case 'DOWNARROW',   K = 'DOWN';
        case 'CAPSLOCK',    K = 'CAPITAL';
      end
    end
  end

  function CrosshairONOff()
    v = get( HH.Crosshair , 'ZData' );
    if isnan( v(1) )
      v = zeros( size(v) );
    else
      v = NaN( size(v) );
    end
    set( HH.Crosshair , 'ZData' , v );
  end

  function DeletingAxes( )
    try, stop( HH.UNATTENDED ); delete( HH.UNATTENDED ); catch LE, DE(LE); end
    for i = 1:numel(RESTORE)
      try, RESTORE{i} = bsxfun( @plus , H.SpatialTransform(1:3,4).' , getCoords( HH.Contour(i) ) * H.SpatialTransform(1:3,1:3).' ); catch LE, DE(LE); end
    end
    if ~all( cellfun('isempty',RESTORE) )
      setappdata( 0 , 'drawContours_RESTORE' , RESTORE );
    end
    
    delete( timerfindall('Tag',sprintf('%.16f',double(HH.Axe)) ) );
    for i = 1:numel( HGS )
      try
        if ~isequal( get( HGS{i} , 'Parent' ) , HH.Parent ), continue; end
        safe_delete( HGS{i} );
      catch LE, DE(LE);
      end
    end
    for f = fieldnames( HH ).'
      try
        if ~isequal( get( HH.(f{1}) , 'Parent' ) , HH.Parent ), continue; end
        safe_delete( HH.(f{1}) );
      catch LE, DE(LE);
      end
    end
    try, safe_delete( HH.Axe ); catch LE, DE(LE); end
  end
  function cp = gCP( )
    set( HH.Axe , 'UserData' , now );
    cp = -Inf(1,3);
    ht = hittest();
    if isempty( ht ), return; end
    ON_AXE = ancestor( ht , 'axes' );
    if isempty( ON_AXE ), return; end
    
    if ON_AXE == HH.ZoomAxe && ~any( strcmp( pressedkeys , 'LSHIFT' ) )
      ON_AXE = HH.Axe;
    end
    
    cp = ( [0.5,0.5]*get(ON_AXE,'CurrentPoint').*[1,1,0] );
    
    try
      set( HH.Crosshair , 'XData',[-1e8,1e8,1e8,cp(1),cp(1)],'YData',[cp(2),cp(2),1e8,1e8,-1e8]);
    end
    

    if ON_AXE == HH.Axe
%       xl = get(HH.Axe,'XLim');
%       if cp(1) < xl(1) || cp(1) > xl(2) || cp(1) < H.DX(1) || cp(1) > H.DX(end), cp = -Inf(1,3); return; end
% 
%       yl = get(HH.Axe,'YLim');
%       if cp(2) < yl(1) || cp(2) > yl(2) || cp(1) < H.DY(1) || cp(2) > H.DY(end), cp = -Inf(1,3); return; end

      try, UpdateZoom( cp ); catch LE, DE(LE); end
    end
  end
  function ChangeCLid( newCLid , hideOthers )
    if strcmp( get(get(HH.Fig,'CurrentObject'),'Type') , 'uicontrol' )
      set(HH.Fig,'CurrentObject',HH.Fig);
      lostfocus(HH.Fig);
    end
    if nargin < 2, hideOthers = false; end
    setLastPoint( NaN(1,3) );

    try
      set( HH.LabelButton , 'Value' , 0 ); set( HH.LabelButton(newCLid) , 'Value' , 1 );
      set( HH.LabelVisible , 'Visible', 'on' ); set( HH.LabelVisible(newCLid) , 'Visible', 'off' );
      set( HH.LabelVisible , 'Value', ~hideOthers );
    catch LE, DE(LE);
    end
    
    START_('                    ');
    set( HGS{2} , 'String', sprintf('Setting %d as the current label.', newCLid ),'ApplicationData',struct('DDELAY',5) );
    
    for lid = 1:10
      set( HH.Contour(lid) , 'Marker', '.' , 'Visible','on' );
      if hideOthers
        set( HH.Contour(lid) , 'Visible','off' );
      end
    end

    CLid = newCLid;
    L = HH.Contour( CLid );
    setLastPoint( gCP( ) );
    set( L , 'Marker', 'o' , 'MarkerSize', 15 , 'Visible' , 'on' );
    start( timer( 'TimerFcn' , @(h,e)set(L,'MarkerSize',3) , 'StartDelay' , 0.75 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe)) ) );
    
    clearHGS( );
  end
  function [i,j,V,v] = GetInfo( xy )
    i = getInterval( xy(1) , H.DX );
    j = getInterval( xy(2) , H.DY );
    
    if     i < 1 || i > size(IF,1), V = NaN;
    elseif j < 1 || j > size(IF,2), V = NaN;
    else,                           V = IF(i,j); 
    end
    if nargout > 3
      v = InterpPointsOn3DGrid( IF , H.X , H.Y , 0 , [xy(1),xy(2),0] , 'linear','Outside_value',NaN );
    end
  end
  function SwitchInterpolation( )
    CurrentInterpolation = get( HH.Surface , 'FaceColor' );
    switch CurrentInterpolation 
      case 'interp', set( HH.Surface , 'XData',H.DXX,'YData',H.DYY,'ZData',zeros(size(H.DXX)),'FaceColor','flat'   );
      case 'flat'  , set( HH.Surface , 'XData',H.XX ,'YData',H.YY ,'ZData',zeros(size(H.XX)) ,'FaceColor','interp' );
    end
  end
  function SwitchGrid( )
    if strcmp( get(HH.Surface,'EdgeColor') , 'none' ), color = [0.7 , 0.7 , 0.3];
    else,                                      color = 'none';
    end
    set( HH.Surface , 'EdgeColor', color );
  end
  function xyz = getCoords( h )
    if ~nargin, h = L; end
    x = get( h , 'XData' );
    if numel(x) < 2, xyz = zeros(0,3); return; end
    y = get( h , 'YData' );

    x = x(1:end-1);
    y = y(1:end-1);
    z = zeros(size(x));

    xyz = [ x(:) , y(:) , z(:) ];
  end
  function setCoords( x )
    if numel( x )
      w = any( isnan( x ) , 2 );
      w(end) = false;
      w = w(:);
      w = [ false ; ~diff(w) ] & w;

      x( w , : ) = [];
    end
    try, if any( isnan( x(1,:) ) ), x(1,:) = []; end; catch LE, DE(LE); end
    if ~numel( x ), x = zeros(0,3); end

    x(:,3) = Z;
         set( L                    , 'XData' , x(:,1) , 'YData' , x(:,2) , 'zdata' , x(:,3) );
    try, set( HH.ZoomContour(CLid) , 'XData' , x(:,1) , 'YData' , x(:,2) , 'zdata' , x(:,3) ); catch LE, DE(LE); end
    
    if ~isempty( FCN ), try, feval( FCN , CLid , L ); catch LE, DE(LE); end; end
  end
  function setLastPoint( NewPoints , minIPDsq , minEllapsedTime )
    if isinf( NewPoints(1) ) && NewPoints(1) < 0, return; end
    THISTIME = now();
    if nargin < 3
      if size( NewPoints , 1 ) > 1 && ~any( isnan( NewPoints(:) ) )
        minEllapsedTime = 1/25;
      else
        minEllapsedTime = 1/500;
      end
    end
    elapsedTIME = (THISTIME - LASTTIME)*86400;
    LASTTIME = THISTIME;
    if elapsedTIME < minEllapsedTime, return; end
    
    xyz = getCoords( );
    
    if nargin > 1 && numel(xyz)
      d = xyz(end,1:2) - NewPoints(end,1:2);
      if d(:).'*d(:) < minIPDsq, return; end;
    end
    
    setCoords( [ xyz ; NewPoints ] );
  end
  function removeLastPoint( )
    xyz = getCoords( );
    if ~numel(xyz), return; end
    saveUNDO( xyz );
    setCoords( xyz );
  end
  function removeLastSegment( )
    xyz = getCoords( );
    if ~numel(xyz), return; end
    saveUNDO( xyz );
    SEGS = splitSegments( xyz );
    SEGS(end) = [];
    setCoords( joinSegments( SEGS ) );
  end
  function saveUNDO( xyz )
    if ~nargin, xyz = getCoords( ); end
    xyz = single( xyz(:,1:2) );

    UNDO = get( L , 'UserData' );
    if ~isequal( UNDO{end} , xyz )
      UNDO{end+1} = xyz;
      if numel( UNDO ) > 1000
        UNDO(1:100) = [];
      end
      set( L , 'UserData' , UNDO );
    end
  end
  function UNDO( )
    UNDO = get( L , 'UserData' );
%     if numel( UNDO ) < 2, return; end
    xyz = double( UNDO{end} ); xyz(:,3) = 0;
    if size( xyz , 1 ) > 1, xyz = [ xyz ; NaN(1,3) ]; end
    setCoords( xyz );
    if numel( UNDO ) > 1, UNDO(end) = []; end
    set( L , 'UserData' , UNDO );
  end
  function clearHGS( defdelay )
    if ~nargin, defdelay = 0; end
    for i = 1:numel( HGS )
      if ishandle( HGS{i} )
        try
          ddelay = get( HGS{i} , 'ApplicationData' );
          ddelay = ddelay.DDELAY;
        catch LE, DE(LE); 
          ddelay = defdelay;
        end
        if ~ddelay
          safe_delete( HGS{i} );
        else
          start( timer( 'TimerFcn' , @(h,e)safe_delete( HGS{i} ) , 'StartDelay' , ddelay , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)safe_delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe))) );
        end
      end
    end
    HGS = {};
  end
  function START_( str , varargin )
    PP = [];
    if ~isempty( HGS )
    end
    auxs = findall( HH.Parent , 'Tag','drawContours.auxHandles' );
    for i = 1:numel(auxs), safe_delete( auxs(i) ); end
    
    db = dbstack();
    
    HGS{1} = db(2).name;
    HGS{1} = builtin( 'strrep' , HGS{1} , mfilename , '' );
    HGS{1} = builtin( 'strrep' , HGS{1} , '/' , '' );
    HGS{1} = builtin( 'strrep' , HGS{1} , '\' , '' );
    
    if isempty( str )
      str = builtin( 'strrep' , HGS{1} , 'START_' , '' );
    else
      str = [ builtin( 'strrep' , HGS{1} , 'START_' , '' ), ': ' , str ];
    end
    
    AxePos = AxePosition( HH.Axe );
    HGS{2} = uicontrol( 'Parent',HH.Parent,'Style','text','HorizontalAlignment','left','FontWeight','normal','Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.1),'BackgroundColor',[1,0.7,1],'hittest','off',...
      'FontName','monospaced','FontSize',12,...
      'Position',[ AxePos(1)+2 , AxePos(2)+2 , 10.5*numel(str) , 21 ],'String', str , varargin{:} );
  end
  function STOP_AND_RESTORE_( oldSTATE , LE )
    try, DE( LE ); end
    if nargin > 1
      AxePos = AxePosition( HH.Axe );
      HGS{end+1} = uicontrol( 'Parent',HH.Parent,'Style','text','HorizontalAlignment','left','FontWeight','normal','Tag','drawContours.auxHandles_NoAutomaticDeletion','ApplicationData',struct('DDELAY',5),'BackgroundColor',[1,0.2,0.2],'hittest','off',...
        'FontName','monospaced','FontSize',12,...
        'Position',[ AxePos(1)+2 , AxePos(2)+35 , 250 , 50 ],'String', {'an ERROR ocurred...','Inspect it from getappdata(gcf,''LastERROR'')'} );
      setappdata( HH.Fig , 'LastERROR' , LE );
      clearHGS( 0 );
    else
      clearHGS();
    end
    RestoreFigure( HH.Fig , oldSTATE );
    setLastPoint( gCP( ) );
  end
  function ScaleHgTransform( e , h )
    if isstruct(e), e = -e.VerticalScrollCount; end
    M = get( h , 'Matrix' );
    if     e > 0, M(1:3,1:3) = M(1:3,1:3) * 1.1;
    elseif e < 0, M(1:3,1:3) = M(1:3,1:3) / 1.1;
    else, return;
    end
    setM( h , M );
  end
  function [ varargout ] = ClickOnSegment( h , xy , varargin )
    if isnumeric( varargin{1} )
      minD = varargin{1};
      varargin(1) = [];
    else
      minD = 8;
    end
    minD = minD * PixelSize( get(h,'Parent') );
    xx = getCoords( h ); xx = xx(:,1:2);

    D = Inf;
    try, [XY,D,pID] = ClosestPointToPolyline( xy(1:2) , xx ); catch LE, DE(LE); end

    if D > minD
      XY = [];
      pID = 0;
      sID = 0;
    else
      sID = sum( any( isnan( xx(1:pID,:) ) , 2 ) )+1;
    end

    for o = 1:min( numel( varargin ) , nargout )
      switch varargin{o}
        case 'XY',  varargout{o} = XY;  %#ok<AGROW>
        case 'pID', varargout{o} = pID; %#ok<AGROW>
        case 'sID', varargout{o} = sID; %#ok<AGROW>
        case 'D',   varargout{o} = D;   %#ok<AGROW>
        otherwise, error('unknown output required');
      end
    end
  end

  function ZoomExtents( anima )
    xl = H.DX([1 end]); xl = ( xl - mean(xl) )*1.1 + mean( xl );
    yl = H.DY([1 end]); yl = ( yl - mean(yl) )*1.1 + mean( yl );
    
    AxePos = AxePosition( HH.Axe );
    rx = diff(xl); cx = mean(xl);
    ry = diff(yl); cy = mean(yl);
    
    r = max( rx/AxePos(3) , ry/AxePos(4) );

    xl = cx + [-1,1]/2*r*AxePos(3);
    yl = cy + [-1,1]/2*r*AxePos(4);

    if nargin && anima
      setLastPoint( NaN(1,3) );
      START_( '' );
      oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'WindowKeyReleaseFcn' , @(h,e)0 );
      
      cx = get( HH.Axe , 'XLim' ); cy = get( HH.Axe , 'YLim' );
      HGS{end+1} = line('Parent',HH.Axe,'XData',[ cx(1) , cx(2) , cx(2) , cx(1) , cx(1) ],'YData',[ cy(1) , cy(1) , cy(2) , cy(2) , cy(1) ],...
        'Color',[1,0.5,1],'LineStyle','--','LineWidth',3,'Marker','none','ApplicationData',struct('DDELAY',0.5),'Tag','drawContours.auxHandles');
       for t = linspace( 0 , 1 , 10 )
        set( HH.Axe , 'XLim' , cx + t * ( xl - cx ) , 'YLim' , cy + t * ( yl - cy ) );
        try, UpdateAxesLims(); catch LE, DE(LE); end
        pause(1/10/4);
      end
      
      RestoreFigure( HH.Fig , oldSTATE );
      clearHGS();
      setLastPoint( gCP( )  );
    else
      set( HH.Axe , 'XLim' , xl , 'YLim' , yl );
      try, UpdateAxesLims(); catch LE, DE(LE); end
    end
  end
  function WheelZoom( f )
    if f > 1, START_( '--' );
    else    , START_( '++' );
    end
    CP = gCP( );
    setLastPoint( NaN(1,3) );
    xl = get( HH.Axe , 'Xlim' ); xl = CP(1) + ( xl - CP(1) )*f;
    yl = get( HH.Axe , 'Ylim' ); yl = CP(2) + ( yl - CP(2) )*f;
                      set( HH.Axe , 'XLim' , xl , 'YLim' , yl );
    try, UpdateAxesLims(); catch LE, DE(LE); end
    clearHGS();
    setLastPoint( gCP( )  );
  end
  function START_Zoom( )
    setLastPoint( NaN(1,3) );
    START_( 'Move Up(+) and Down(-)' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'glass' , 'Help' , 'Up and Down' );

    if strcmp( get( HH.NavigatorPanel , 'Visible' ) , 'off' )
      uistack( HH.NavigatorPanel , 'top' );
      set( HH.NavigatorPanel , 'ShowTitleBar' , 'off' , 'Visible', 'on' );
    end
    
    cx = get( HH.Axe , 'XLim' ); cy = get( HH.Axe , 'YLim' );
    
    SP  = gCP( );
    fSP = get(HH.Fig,'CurrentPoint');
    
    set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE( oldSTATE ) , 'WindowButtonUpFcn' , @(h,e)STOP_AND_RESTORE( oldSTATE ) );
    function MOVING( ), try, %#ok<ALIGN>
      fCP = get( HH.Fig , 'CurrentPoint' );
      
      d = fCP(2) - fSP(2);
      if     d > 0, setFigurePointer( HH.Fig , 'glassplus' );
      elseif d < 0, setFigurePointer( HH.Fig , 'glassminus' );
      else,         setFigurePointer( HH.Fig , 'glass' );
      end

      f = exp( - d / 150 );
      
      try, set( HGS{2} , 'String' , sprintf('Zoom: %.2f',1/f ) ); end
       
      xl = ( cx - SP(1) )*f + SP(1);
      yl = ( cy - SP(2) )*f + SP(2);
      
      set( HH.Axe , 'XLim' , xl , 'YLim' , yl ); 
      try, UpdateAxesLims(); end
    catch LE, STOP_AND_RESTORE( oldSTATE , LE ); end; end
    function STOP_AND_RESTORE( oldSTATE , varargin )
      if ~get( NavigatorButton , 'Value' )
        start( timer( 'TimerFcn' , @(h,e)set(HH.NavigatorPanel,'Visible','off','ShowTitleBar','on') , 'StartDelay' , 0.2 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe)) ) );
      end
      STOP_AND_RESTORE_( oldSTATE , varargin{:} );
    end
  end
  function START_Pan( )
    setLastPoint( NaN(1,3) );
    START_( '' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'WindowKeyReleaseFcn' , @(h,e)0 , 'Pointer' , 'closedhand' );
    
    if strcmp( get( HH.NavigatorPanel , 'Visible' ) , 'off' )
      set( HH.NavigatorPanel , 'ShowTitleBar' , 'off' , 'Visible', 'on' );
    end
    
    SP = gCP( );

    set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonUpFcn' , @(h,e)STOP_AND_RESTORE( oldSTATE ) );
    function MOVING( ), try, %#ok<ALIGN>
      %CP = gCP( );
      CP = [0.5,0.5]*get( HH.Axe , 'CurrentPoint' );
      xl = get( HH.Axe , 'Xlim' ); xl = xl + SP(1) - CP(1);
      yl = get( HH.Axe , 'Ylim' ); yl = yl + SP(2) - CP(2);
      try, set( HH.Axe , 'XLim' , xl , 'YLim' , yl ); end
      try, UpdateAxesLims(); catch LE, DE(LE); end
    catch LE, STOP_AND_RESTORE( oldSTATE , LE ); end; end
    function STOP_AND_RESTORE( oldSTATE , varargin )
      if ~get( NavigatorButton , 'Value' )
        start( timer( 'TimerFcn' , @(h,e)set(HH.NavigatorPanel,'Visible','off','ShowTitleBar','on') , 'StartDelay' , 0.2 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe)) ) );
      end
      STOP_AND_RESTORE_( oldSTATE , varargin{:} );
    end
  end

  function START_ChangeWindow( )
    setLastPoint( NaN(1,3) );
%     START_( 'Left<>Right (contrast) - Up<>Down (brightness)' );
    START_( '' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'WindowKeyReleaseFcn' , @(h,e)0 , 'Pointer' , 'blockfleurcontrast' );

    if strcmp( get( HH.IControlPanel , 'Visible' ) , 'off' )
      set( HH.IControlPanel , 'ShowTitleBar' , 'off' , 'Visible', 'on' );
    end
    
    fSP = get(HH.Fig,'CurrentPoint');
    originalIT = HH.IT.v;
    center = ( originalIT(end-1,1)+originalIT(2,1) )/2;
    step   = ( H.GrayLevel1 - H.GrayLevel0 )/10;

    set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonUpFcn' , @(h,e)STOP_AND_RESTORE( oldSTATE )  );
    function MOVING( ), try, %#ok<ALIGN>
      fCP = get( HH.Fig , 'CurrentPoint' );
      
      s = exp( ( fCP(1) - fSP(1) ) * 0.005  );
      c = ( fCP(2) - fSP(2) )/20 * step;
      
      newIT = originalIT;
      newIT(:,1)   = ( originalIT(:,1) - center )*s + center + c;
      newIT(1,1)   = -1e+15;
      newIT(end,1) = 1e+15;
 
      HH.IT.v = newIT;

      catch LE, STOP_AND_RESTORE( oldSTATE , LE ); end; end
    function STOP_AND_RESTORE( oldSTATE , varargin )
      if ~get( IControlButton , 'Value' )
        start( timer( 'TimerFcn' , @(h,e)set(HH.IControlPanel,'Visible','off','ShowTitleBar','on') , 'StartDelay' , 2 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe)) ) );
      end
      STOP_AND_RESTORE_( oldSTATE , varargin{:} );
    end
  
  end
  function RESET_Window( anima )
    originalIT = HH.IT.v;
    origin = originalIT(2,1);
    scale  = originalIT(end-1,1) - originalIT(2,1);

    norigin = H.GrayLevel0;
    nscale  = H.GrayLevel1 - H.GrayLevel0;
    
    if nargin && anima
      setLastPoint( NaN(1,3) );
      oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'WindowKeyReleaseFcn' , @(h,e)0 );

      if strcmp( get( HH.IControlPanel , 'Visible' ) , 'off' )
        set( HH.IControlPanel , 'ShowTitleBar' , 'off' , 'Visible', 'on' );
      end
      for t = linspace( 0 , 1 , 10 )
        nnscale  = (1-t)*scale  + t*nscale;
        nnorigin = (1-t)*origin + t*norigin;
        
        newIT = originalIT;
        newIT(:,1) = ( newIT(:,1) - origin )/scale*nnscale + nnorigin;
        newIT(1,1)   = -1e+15;
        newIT(end,1) = 1e+15;

        HH.IT.v = newIT;
        
        pause(1/10/2); 
      end
      
      RestoreFigure( HH.Fig , oldSTATE );
      setLastPoint( gCP( )  );

      if get( IControlButton , 'Value' )
        start( timer( 'TimerFcn' , @(h,e)set(HH.IControlPanel,'Visible','off','ShowTitleBar','on') , 'StartDelay' , 2 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe)) ) );
      end
    else
      
      newIT = originalIT;
      newIT(:,1) = ( newIT(:,1) - origin )/scale*nscale + norigin;
      newIT(1,1)   = -1e+15;
      newIT(end,1) = 1e+15;
      
      HH.IT.v = newIT;
      
      %set( HH.Axe , 'CLim' , [ H.GrayLevel0 , H.GrayLevel1 ] );
    end
    
    
  end
  function FlipV( )
    [az,el] = view( HH.Axe );
    up = get( HH.Axe , 'CameraUpVector' );
    
    %oldProjection = get( HH.Axe , 'Projection' ); set( HH.Axe , 'Projection','perspective');
    for e = -el %linspace( el , -el , 20 )
      view( HH.Axe          , [ az , e ] );
      set(  HH.Axe          , 'CameraUpVector' , -up );
      %pause(1/50);
    end
    %set( HH.Axe , 'Projection',oldProjection);

    try, view( HH.ZoomAxe      , [ az , e ] ); catch LE, DE(LE); end
    try, view( HH.NavigatorAxe , [ az , e ] ); catch LE, DE(LE); end
    try, set(  HH.ZoomAxe      , 'CameraUpVector' , -up ); catch LE, DE(LE); end
    try, set(  HH.NavigatorAxe , 'CameraUpVector' , -up ); catch LE, DE(LE); end

    Z = -Z;
    for lid = 1:numel(HH.Contour)
      set( HH.Contour(lid) , 'ZData' , - get( HH.Contour(lid) , 'ZData' ) );
    end
  end
  function FlipH( )
    [az,el] = view( HH.Axe );
    up = get( HH.Axe , 'CameraUpVector' );

    %oldProjection = get( HH.Axe , 'Projection' ); set( HH.Axe , 'Projection','perspective');
    for e = -el %linspace( el , -el , 20 )
      view( HH.Axe          , [ az , e ] );
      set(  HH.Axe          , 'CameraUpVector' , up );
      %pause(1/50);
    end
    %set( HH.Axe , 'Projection',oldProjection);

    try, view( HH.ZoomAxe      , [ az , e ] ); catch LE, DE(LE); end
    try, view( HH.NavigatorAxe , [ az , e ] ); catch LE, DE(LE); end
    try, set(  HH.ZoomAxe      , 'CameraUpVector' , up ); catch LE, DE(LE); end
    try, set(  HH.NavigatorAxe , 'CameraUpVector' , up ); catch LE, DE(LE); end

    Z = -Z;
    for lid = 1:numel(HH.Contour)
      set( HH.Contour(lid) , 'ZData' , - get( HH.Contour(lid) , 'ZData' ) );
    end
  end
  function RotateView( direction )
    upO = get( HH.Axe , 'CameraUpVector' );
    for t = linspace(0,pi/2,30)
      c = cos(t); s = sin(t);
      R = [ c -s 0; s c 0; 0 0 1];
      if direction > 0, set( HH.Axe , 'CameraUpVector' , upO*R   );
      else,             set( HH.Axe , 'CameraUpVector' , upO*R.' );
      end
      pause(1/50/2);
    end
    try, set( HH.ZoomAxe      , 'CameraUpVector' , get( HH.Axe , 'CameraUpVector' ) ); catch LE, DE(LE); end
    try, set( HH.NavigatorAxe , 'CameraUpVector' , get( HH.Axe , 'CameraUpVector' ) ); catch LE, DE(LE); end
  end

  function SELECTOR( hSEL , KEYS , w_init )
    if nargin < 3, w_init = []; end
    oldSTRING = get( HGS{2} , 'String' ); set( HGS{2} , 'String' , 'Select' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'select' , 'Help' , {'<b>click 1/3</b>: select/deselect segments','<b>click 1/3 on blank</b>: start dragging rectangle','<b>doubleclick 1/3 on blank</b>: start polygon'});
    
    xxyyzz = getCoords( ); xxyyzz(:,3) = 1:size(xxyyzz,1);
    w_init( w_init > size(xxyyzz,1) ) = [];
    set( hSEL , 'UserData', w_init(:) );

    
    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)SELECTING() , 'WindowKeyPressFcn' , @(h,e)SELECTING() ,  'WindowButtonMotionFcn' , @(h,e)SELECTING() , 'WindowButtonDownFcn' , @(h,e)SELECTING() );
    function STOP_SELECTOR( )
      RestoreFigure( HH.Fig , oldSTATE );
      set( HGS{2} , 'String' , oldSTRING );
      set( hSEL , 'CLimInclude' , 'off' );
    end
    function SELECTING( ), try, %#ok<ALIGN>
                 pk = pressedkeys(1);
      if ~all( cellfun(@(s)any(strcmp(s,pk)),KEYS) )
        STOP_SELECTOR( ); return; end
      
      isB1 = any( strcmp( pk , 'BUTTON1' ) );
      isB3 = any( strcmp( pk , 'BUTTON3' ) );
      if ~isB1 && ~isB3, return; end
      
      THISTIME = now(); elapsedTIME = (THISTIME - LASTTIME)*86400; LASTTIME = THISTIME;
      isDOUBLECLICK = elapsedTIME < 0.2;
      %if strcmp( get( HH.Fig , 'SelectionType' ) , 'open' ), isDOUBLECLICK = true; end
      
      W = get( hSEL , 'UserData' );
      CP = gCP( );
      
      if ~isDOUBLECLICK
        
        sID = ClickOnSegment( L , CP , 'sID' );
        if ~sID   %start selection by rectangle
          
          MAKE_RECTANGLE( CP , W , isB1 );
          return;

        elseif isB1
          
          LASTTIME = 0;
          SEGS = splitSegments( xxyyzz ); SEGS = SEGS{sID};
          W = unique( [ W ; SEGS(:,3) ] );

          set( hSEL , 'XData' , xxyyzz(W,1) , 'YData' , xxyyzz(W,2) , 'UserData' , W );
          set( HGS{2} , 'String' , sprintf('%d points selected', sum( ~any( isnan( xxyyzz(W,:) ),2 ) ) ) );
        
        elseif isB3 
          
          LASTTIME = 0;
          SEGS = splitSegments( xxyyzz ); SEGS = SEGS{sID};
          W = setdiff( W , SEGS(:,3) );

          set( hSEL , 'XData' , xxyyzz(W,1) , 'YData' , xxyyzz(W,2) , 'UserData' , W );
          set( HGS{2} , 'String' , sprintf('%d points selected', sum( ~any( isnan( xxyyzz(W,:) ),2 ) ) ) );
          
        end

      else %start selection by irregular polygon
        
        LASTTIME = 0;
        MAKE_POLYGON( CP , W , isB1 );
        return;
        
      end
    catch LE, DE(LE); STOP_SELECTOR( ); end; end

    function MAKE_RECTANGLE( P0 , w , select )
      oldSTATE2 = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'rectangle' );
      
      RECTANGLE = line( 'Parent' , HH.Axe , 'XData',ones(1,5)*P0(1),'YData',ones(1,5)*P0(2), 'LineWidth',2,'LineStyle','--','Marker','none' );
      if select, set( RECTANGLE , 'Color' , [1,0,1] );
      else,      set( RECTANGLE , 'Color' , [1,1,0] );
      end
      
      set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)DRAG_RECTANGLE() , 'WindowButtonUpFcn' , @(h,e)END_RECTANGLE() );
      function END_RECTANGLE( )
        delete( RECTANGLE );
        RestoreFigure( HH.Fig , oldSTATE2 );
      end
      function DRAG_RECTANGLE( )
        CP = gCP( );
        if isequal( CP , PP ), return; end
        PP = CP;
        
        set( RECTANGLE , 'XData' , [P0(1),CP(1),CP(1),P0(1),P0(1)] , 'YData' , [P0(2),P0(2),CP(2),CP(2),P0(2)] );
      
        Xs = sort( [ P0(1) , CP(1) ] ); Ys = sort( [ P0(2) , CP(2) ] );
        
        ww = xxyyzz(:,1) >= Xs(1) & xxyyzz(:,1) <= Xs(2) &...
             xxyyzz(:,2) >= Ys(1) & xxyyzz(:,2) <= Ys(2);
        ww = xxyyzz( ww , 3 );
           
        if select, ww = union(   w , ww );
        else,      ww = setdiff( w , ww );
        end
        
        set( hSEL , 'XData' , xxyyzz( ww , 1 ) , 'YData' , xxyyzz( ww , 2 ) , 'UserData' , ww );
        set( HGS{2} , 'String' , sprintf('%d points selected', sum( ~any( isnan( xxyyzz(ww,:) ),2 ) ) ) );
      end
    end
    
    function MAKE_POLYGON( P0 , w , select )
      oldSTATE2 = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'polygon' );

      POL = [1;1;1]*P0(1:2);
      POLYGON = line( 'Parent' , HH.Axe , 'XData',POL(:,1),'YData',POL(:,2), 'LineWidth',2,'LineStyle','--','Marker','none' );
      if select, set( POLYGON , 'Color' , [1,0,1] );
      else,      set( POLYGON , 'Color' , [1,1,0] );
      end
      
      set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)DRAG_POLYGON() , 'WindowButtonDownFcn' , @(h,e)DRAG_POLYGON() );
      function END_POLYGON( )
        delete( POLYGON );
        RestoreFigure( HH.Fig , oldSTATE2 );
      end
      function DRAG_POLYGON( )
        pk = pressedkeys(3);
        pk = pk == 1 || pk == 3;

        CP = gCP( );
        if ~pk && isequal( CP , PP ), return; end
        PP = CP;

        pol = [ POL(1:end-1,:) ; CP(1:2) ; POL(end,:) ];

        set( POLYGON ,  'XData' , pol(:,1) , 'YData' , pol(:,2) );
        
        ww = inpolygon( xxyyzz(:,1) , xxyyzz(:,2) , pol(:,1) , pol(:,2) );
        ww = xxyyzz( ww , 3 );
           
        if select, ww = union(   w , ww );
        else,      ww = setdiff( w , ww );
        end
        
        set( hSEL , 'XData' , xxyyzz( ww , 1 ) , 'YData' , xxyyzz( ww , 2 ) , 'UserData' , ww );
        set( HGS{2} , 'String' , sprintf('%d points selected', sum( ~any( isnan( xxyyzz(ww,:) ),2 ) ) ) );

        if ~pk, return; end

        POL = pol;

        THISTIME = now(); elapsedTIME = (THISTIME - LASTTIME)*86400; LASTTIME = THISTIME;
        isDOUBLECLICK = elapsedTIME < 0.2;

        if isDOUBLECLICK, LASTTIME = 0; END_POLYGON( ); end
      end
    end
    
  end

  function START_Info( )
    persistent profile_LENGTH
    persistent profile_ANGLE
    
    if isempty( profile_LENGTH ), profile_LENGTH = sqrt( diff(H.X([1,end]))^2 + diff(H.Y([1,end]))^2 )/4; end
    if isempty( profile_ANGLE ),  profile_ANGLE = 0;  end
    
    START_( '' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'help' , 'Help' , {'Info of the underlying image.','Also info about contours','''x'' correspond to coincident points','''o'' very nearby points.','To control the profile, use:','  wheel to change the angle','  +/- keys to change the length'} );
    
    
    AxePos = AxePosition( HH.Axe );
    HGS{3} = uicontrol('Parent',HH.Parent,'Style','text','Position',[ AxePos(1)+5 , AxePos(2)+AxePos(4)-160-5 , 250 , 160 ],'BackgroundColor',[0.7,0.7,1] ,'FontUnits','pixels','FontSize',10,'FontName','Monospaced','HorizontalAlignment','left',...
      'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5));
    HGS{4} = line('Parent',HH.Axe,'XData',[],'YData',[],'ZData',[],'LineStyle','-','LineWidth',2,'Marker','o','Color',get(L,'Color'),'MarkerFaceColor',get(L,'Color'),'MarkerSize',6,...
      'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5));
    HGS{5} = patch('Parent',HH.Axe,'Vertices',[],'faces',[],'FaceColor',get(L,'Color'),'EdgeColor','none','FaceAlpha',0.6,...
      'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5));
    
    %overlapping points marks
    xyz = getCoords( );
    IPD = ipd( getCoords() , [] );
%     IPD( triu( true(size(IPD)) , -1 ) ) = Inf;
    IPD( 1:(size(IPD,1)+1):end ) = Inf;
    w = find( any( IPD < eps(1) , 2 ) );
    HGS{6} = line('Parent',HH.Axe,'XData',xyz(w,1),'YData',xyz(w,2),'ZData',SV(w,Z),'LineStyle','none','LineWidth',3,'Marker','x','Color',[1,1,0]*0.8,'MarkerSize',15,...
      'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',2.5));
    w = setdiff( find( any( IPD < H.InterPointThreshold/4 , 2 ) ) , w );
    HGS{7} = line('Parent',HH.Axe,'XData',xyz(w,1),'YData',xyz(w,2),'ZData',SV(w,Z),'LineStyle','none','LineWidth',1,'Marker','o','Color',[1,1,0]*0.8,'MarkerSize',15,...
      'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',2.5));
    
    SEGS = [];
    NumberOfPointsForEachSegment = [];
    
    
    HGS{8} = line('Parent',HH.Axe,'XData',NaN(2,1),'YData',NaN(2,1),'ZData',SV([0;0],Z),'LineStyle','-','LineWidth',1,'Marker','none','Color',[1,0.5,0],...
      'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5));
    HGS{9} = line('Parent',HH.Axe,'XData',NaN(2,1),'YData',NaN(2,1),'ZData',SV([0;0],Z),'LineStyle','-','LineWidth',1,'Marker','none','Color',[0,0.5,1],...
      'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5));

%     HGS{13} = line('Parent',HH.Axe,'XData',NaN,'YData',NaN,'ZData',NaN,'LineStyle','none','LineWidth',2,'Marker','*','Color','m',...
%       'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',2.5));
    
    PROFILEn  = 75;
    PROFILExy = linspace( -1 , 1 , 2*PROFILEn+1 ).' * [ profile_LENGTH , 0 ];
    PROFILExy = PROFILExy * [ cosd(profile_ANGLE) , sind(profile_ANGLE) ; -sind(profile_ANGLE) , cosd(profile_ANGLE) ];

    
    HGS{10} = axes('Parent',HH.Parent,'Units','pixels','Position',[ AxePos(1)+5 , AxePos(2)+AxePos(4)-160-5-50-2 , 250 , 50 ],...
      'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5),'XLim',[-1,1]*1.05,'XTick',[],'YTick',[],'Box','on','Layer','top','Visible','off');
    
    rectangle( 'Parent',HGS{10},'Position',[-2 -1e5 2 2e5],'FaceColor',[1,0.95,0.85],'EdgeColor','none','XLimInclude','off','YLimInclude','off');
    rectangle( 'Parent',HGS{10},'Position',[ 0 -1e5 2 2e5],'FaceColor',[0.85,0.95,1],'EdgeColor','none','XLimInclude','off','YLimInclude','off');
    
    HGS{11} = line('Parent',HGS{10},...
      'XData' , linspace( -1 , 1 , 2*PROFILEn+1 ) ,...
      'YData' , NaN(2*PROFILEn+1,1) ,...
      'LineStyle','-','LineWidth',1,'Marker','none','Color',[0,0,0],...
      'Tag','drawContours.auxHandles');
    
    HGS{12} = line('Parent',HGS{10},...
      'XData' , NaN ,...
      'YData' , NaN ,...
      'LineStyle','-','LineWidth',1,'Marker','none','Color',get(L,'Color'),...
      'XLimInclude','off','YLimInclude','off',...
      'Tag','drawContours.auxHandles');
    
    
    %set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonDownFcn' , @(h,e)MOVING() , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE( oldSTATE ) );

    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)MOVING , 'WindowKeyPressFcn' , @(h,e)MOVING ,  'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonDownFcn' , @(h,e)MOVING() , 'WindowScrollWheelFcn'  , @(h,e)RotateProfile( e ) );
    
    MOVING( );
    function RotateProfile( e )
      if sign( e.VerticalScrollCount ) == 1
        profile_ANGLE = profile_ANGLE + 5;
      else
        profile_ANGLE = profile_ANGLE - 2.5;
      end
      %profile_ANGLE
      PROFILExy = linspace( -1 , 1 , 2*PROFILEn+1 ).' * [ profile_LENGTH , 0 ];
      PROFILExy = PROFILExy * [ cosd(profile_ANGLE) , sind(profile_ANGLE) ; -sind(profile_ANGLE) , cosd(profile_ANGLE) ];
      PP = NaN(1,3);
      MOVING( );
    end
    function MOVING( ), try, %#ok<ALIGN>
      pk = pressedkeys(1);
      if ~any( strcmp( pk , 'X' ) ), STOP_AND_RESTORE_( oldSTATE );   return; end
      if CELLeq( pk , {'K','X'} , true )
        profile_LENGTH = profile_LENGTH / 1.1;
        PROFILExy = linspace( -1 , 1 , 2*PROFILEn+1 ).' * [ profile_LENGTH , 0 ];
        PROFILExy = PROFILExy * [ cosd(profile_ANGLE) , sind(profile_ANGLE) ; -sind(profile_ANGLE) , cosd(profile_ANGLE) ];
        PP = NaN(1,3);
      end
      if CELLeq( pk , {'L','X'} , true )
        profile_LENGTH = profile_LENGTH * sqrt( 1.1 );
        PROFILExy = linspace( -1 , 1 , 2*PROFILEn+1 ).' * [ profile_LENGTH , 0 ];
        PROFILExy = PROFILExy * [ cosd(profile_ANGLE) , sind(profile_ANGLE) ; -sind(profile_ANGLE) , cosd(profile_ANGLE) ];
        PP = NaN(1,3);
      end

      CP = gCP( );
      pk = pressedkeys(3);
      if ~pk && isequal( PP , CP ), return; end
      PP = CP;
      
      switch pk
        case 0,       setLastPoint( CP );
        case 1,       setLastPoint( [1;1]*CP , H.InterPointThreshold2/16 , 1/50 ); SEGS = [];
        case 4,       setLastPoint( [ NaN(1,3) ; CP ] ); SEGS = [];
      end
      STR = repmat({''},[11,1]);
      
      [i,j,V,v] = GetInfo( CP );
      UpdateIControl( v , false );

      STR{1} = sprintf('( %d , %d )',i,j);      STR{1} = [ '(i,j):'  , blanks(35-6-numel(STR{1})) , STR{1} ];
      STR{2} = sprintf('%f , %f',CP(1),CP(2));  STR{2} = [ 'x,y:'    , blanks(35-4-numel(STR{2})) , STR{2} ];
      STR{3} = sprintf('( %f )',V);             STR{3} = [ 'value:'  , blanks(35-6-numel(STR{3})) , STR{3} ];
      STR{4} = sprintf('%f',v);                 STR{4} = [ 'interp:' , blanks(35-7-numel(STR{4})) , STR{4} ];

      if isempty( SEGS )
        SEGS = splitSegments( getCoords( ) , true );
        NumberOfPointsForEachSegment = cellfun( @(x)sum(~isnan(x(:,1))) , SEGS );
      end
      STR{6} = sprintf('Current Label: %d  -  %d segments', CLid , numel(NumberOfPointsForEachSegment) );
      STR{7} = sprintf('%d,',NumberOfPointsForEachSegment); STR{7} = [ 'with ' , STR{7}(1:end-1) , ' points' ];
      
      sid = 0;
      try, sid = ClickOnSegment( L , CP , 2 , 'sID' ); catch LE, DE(LE); end
      set( [ HGS{4} , HGS{5} ] , 'Visible','off' );
      if sid
        seg = SEGS{sid};
        set( HGS{4} , 'XData' , seg(:,1) , 'YData' , seg(:,2) , 'ZData', SV(seg,Z) , 'Visible','on' );

        STR{9}  = sprintf('Segment with %d points', size(seg,1) );
        STR{10} = sprintf( 'Perimeter: %f' , sum( sqrt( sum( diff( seg , 1 , 1 ).^2 , 2 ) ) ) );
        if isequal( seg(1,:) , seg(end,:) )
          set( HGS{5} , 'Vertices',seg,'Faces',(1:size(seg,1)) , 'Visible','on' );
          STR{11} = sprintf('Area: %f', polyarea( seg(:,1) , seg(:,2) ) );
        end
      end
      
      set( HGS{3} , 'String' , STR );
      
      %updating profiles
      PROFILE = bsxfun( @plus , CP(1:2) , PROFILExy );
      set( HGS{8} , 'XData' , PROFILE([1,PROFILEn+1     ] ,1) , 'YData' , PROFILE([1,PROFILEn+1    ] ,2) );
      set( HGS{9} , 'XData' , PROFILE([   PROFILEn+1,end] ,1) , 'YData' , PROFILE([  PROFILEn+1,end] ,2) );
      
      PROFILE(:,3) = 0;
      set( HGS{11} , 'YData' , InterpPointsOn3DGrid( IF , H.X , H.Y , 0 , PROFILE , 'linear','Outside_value',NaN ) );
      
      SlicePoints = getCoords();
      if ~isempty( SlicePoints )
        SlicePoints = SliceMesh( SlicePoints , getPlane( [ CP ; -sind( profile_ANGLE ) , cosd( profile_ANGLE ) , 0 ] ) );
%         set( HGS{13} , 'XData',SlicePoints(:,1), 'YData',SlicePoints(:,2) , 'ZData', SV( SlicePoints(:,2) ,Z) );
        SlicePoints = bsxfun( @minus , SlicePoints , CP )/profile_LENGTH;
        
        SlicePoints = SlicePoints(:,1:2) * [ cosd(profile_ANGLE) , -sind(profile_ANGLE) ; sind(profile_ANGLE) , cosd(profile_ANGLE) ];
        SlicePoints = SlicePoints(:,1);
        
        set( HGS{12} , 'YData' , vec( [-1e10;1e10;NaN] * ones(1,numel(SlicePoints)) ) ,...
                       'XData' , vec( [    1;   1;  1] * SlicePoints(:).'           ) );
      else
        set( HGS{12} , 'YData' , NaN , 'XData' , NaN );
      end
        
    catch LE, STOP_AND_RESTORE( oldSTATE , LE ); end; end
    function STOP_AND_RESTORE( oldSTATE , varargin )
      UpdateIControl( NaN , false );
      STOP_AND_RESTORE_( oldSTATE , varargin{:} );
    end
  end
  function START_Close( )
    xyz = getCoords( ); if ~numel(xyz), return; end
    if ~any( isnan(xyz(end,:)),2)
      lastNaN = max( [ 0 ; find( any( isnan(xyz) ,2) ) ] );
      if size( xyz , 1 ) - lastNaN < 3, return; end
      
      a = xyz(end,:);
      b = xyz(lastNaN+1,:);
      
      setLastPoint( [ b ; NaN(1,3) ; gCP() ] );
      
      newS = line('XData',[a(1),b(1)],'YData',[a(2),b(2)],'ZData',[0,0]+Z,'Color',get(L,'Color'),'Marker','o','MarkerSize',7,'MarkerFaceColor',get(L,'Color'),'LineWidth',3);
      start( timer( 'TimerFcn' , @(h,e)delete(newS) , 'StartDelay' , 0.25 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe))) );
      
    else

      START_( 'Click on a segment to close' );
      oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'select' , 'Help' , {'<b>click 1</b>: on a segment to close'} );

      setLastPoint( NaN(1,3) );

      set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK() );
    end
    function CLICK( ), try, %#ok<ALIGN>
      pk = pressedkeys(3);
      if pk ~= 1, return; end
      
      CP = gCP( );
      sid = ClickOnSegment( L , CP , 'sID' );

      if ~sid, return; end
      
      xyz = getCoords( );
      SEGS = splitSegments( xyz );
      seg = SEGS{sid};
      seg( any(isnan(seg),2) , : ) = [];
      
      if size(seg,1) < 3, return; end
      if isequal( seg(1,:) , seg(end,:) ), return; end
      
      saveUNDO( xyz );

      a = seg(end,:);
      b = seg( 1 ,:);
      
      SEGS{sid} = [ seg([1:end,1],:) ; NaN(1,3) ];
      setCoords( joinSegments( SEGS ) );
      
      newS = line('XData',[a(1),b(1)],'YData',[a(2),b(2)],'ZData',[0,0]+Z,'Color',get(L,'Color'),'Marker','o','MarkerSize',7,'MarkerFaceColor',get(L,'Color'),'LineWidth',3);
      start( timer( 'TimerFcn' , @(h,e)delete(newS) , 'StartDelay' , 0.25 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe))) );

    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Adder( )
    START_( 'Click on a segment add a point' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'point' , 'Help' , {'<b>click 1</b>: on a segment to add a point','<b>click 3</b>: break the segment'} );
    
    setLastPoint( NaN(1,3) );
    
    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK() );
    function CLICK( ), try, %#ok<ALIGN>
      pk = pressedkeys(3);
      if pk == 1 || pk == 4
        CP = gCP( );

        [cxy,id] = ClickOnSegment( L , CP , 'XY','pID' );
        if ~id, return; end

        xyz = getCoords( );
        saveUNDO( xyz );

        if pk == 1
          newP = line('XData',cxy(1),'YData',cxy(2),'ZData',Z,'Color',get(L,'color'),'Marker','o','MarkerSize',10,'MarkerFaceColor',get(L,'color'));
          start( timer( 'TimerFcn' , @(h,e)delete(newP) , 'StartDelay' , 0.75  , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe))) );

          xyz = [ xyz(1:id,:) ; [ cxy , 0 ] ; xyz(id+1:end,:) ; NaN NaN NaN ];
        elseif pk == 4
          newP1 = [ xyz( 1:id , : ) ; [ cxy , 0 ] ];
          newP1(1:find(any(isnan(newP1),2),1),:) = [];
          newP1 = line('XData',newP1(:,1),'YData',newP1(:,2),'ZData',SV(newP1,Z),'Color',[1,0,1],'Marker','o','MarkerSize',5,'MarkerFaceColor',[1,0,1],'LineWidth',3);

          newP2 = [ [ cxy , 0 ] ; xyz( id+1:end , : ) ];
          newP2( find(any(isnan(newP2),2),1):end ,:) = [];
          newP2 = line('XData',newP2(:,1),'YData',newP2(:,2),'ZData',SV(newP2,Z),'Color',[1,1,0],'Marker','o','MarkerSize',5,'MarkerFaceColor',[1,1,0],'LineWidth',3);
          
          start( timer( 'TimerFcn' , @(h,e)delete([newP1,newP2]) , 'StartDelay' , 1 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe))) );
          
          xyz = [ xyz(1:id,:) ; [ cxy , 0 ] ; NaN(1,3) ; [ cxy , 0 ] ; xyz(id+1:end,:) ; NaN NaN NaN ];
        end
        setCoords( xyz );
      end
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Joiner( )
    START_( 'Click on segments to join' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'select' , 'Help' , {'<b>click 1</b>: on segments to join'} );

    setLastPoint( NaN(1,3) );
    xyz = getCoords();
    SEGS = splitSegments( xyz , true );
    sids = [];

    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK() );
    function CLICK( ), try, %#ok<ALIGN>
      pk = pressedkeys(3);
      if pk ~= 1, return; end
      
      CP = gCP( );
      sid = ClickOnSegment( L , CP , 'sID' );

      if ~sid, return; end

      seg = SEGS{sid};
      HGS{end+1} = line('Parent',HH.Axe,'XData',seg(:,1),'YData',seg(:,2),'ZData',SV(seg,Z),'Color',get(L,'Color'),'Marker','o','MarkerSize',7,'MarkerFaceColor',get(L,'Color'),'LineWidth',1,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));
      
      sids = [ sids , sid ];
      
      if numel( sids ) == 2
        if      sids(1) == sids(2)
          set( HGS{2} , 'String','cannot join the same segment','ApplicationData',struct('DDELAY',1.5));
          return;
        end

        segA = SEGS{sids(1)}; A0 = segA(1,:); A1 = segA(end,:);
        if isequal( A0 , A1 )
          set( HGS{2} , 'String','First segment is closed.','ApplicationData',struct('DDELAY',1.5));
          return;
        end
        
        segB = SEGS{sids(2)}; B0 = segB(1,:); B1 = segB(end,:);
        if isequal( B0 , B1 )
          set( HGS{2} , 'String','Second segment is closed.','ApplicationData',struct('DDELAY',1.5));
          return;
        end
          
        d = sum([ A0 - B0;...
                  A0 - B1;...
                  A1 - B0;...
                  A1 - B1 ].^2,2);
        [~,d] = min(d);
        switch d
          case 1, A = A0; B = B0; segA = flipdim(segA,1);
          case 2, A = A0; B = B1; segA = flipdim(segA,1); segB = flipdim(segB,1);
          case 3, A = A1; B = B0;
          case 4, A = A1; B = B1; segB = flipdim(segB,1);
        end
        
        
        saveUNDO( xyz );
        
        J = line('XData',[A(1),B(1)],'YData',[A(2),B(2)],'ZData',[Z,Z],'Color',get(L,'color'),'Marker','o','MarkerSize',10,'MarkerFaceColor',get(L,'color'),'LineWidth',3);
        start( timer( 'TimerFcn' , @(h,e)delete(J) , 'StartDelay' , 0.75  , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe))) );

        if isequal( A , B ), segB( 1,: ) = []; end
        
        SEGS{ max(sids) } = [];
        SEGS{ min(sids) } = [ segA ; segB ];
        
        setCoords( joinSegments( SEGS ) );
      end
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Union( )
    START_( 'Click on regions to join' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'select' , 'Help' , {'<b>click 1</b>: on segments to join'} );

    setLastPoint( NaN(1,3) );
    xyz = getCoords();
    SEGS = splitSegments( xyz );
    sids = [];

    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK() );
    function CLICK( ), try, %#ok<ALIGN>
      pk = pressedkeys(3);
      if pk ~= 1, return; end
      
      CP = gCP( );
      sid = ClickOnSegment( L , CP , 'sID' );

      if ~sid, return; end
      
      s = SEGS{sid}; s( any(isnan(s),2) , :) = [];
      HGS{end+1} = patch('Vertices',bsxfun(@plus,s,[0,0,+Z]),'faces', 1:size(s,1) ,'FaceColor',get(L,'Color'),'EdgeColor','none','FaceAlpha',0.6,'Parent',HH.Axe,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));
      
      sids = [ sids , sid ];
      
      if numel( sids ) == 2
        if      sids(1) == sids(2)
          set( HGS{2} , 'String','cannot join the same segment','ApplicationData',struct('DDELAY',1.5));
          return;
        end

        s1 = SEGS{sids(1)}; s1( any( isnan( s1 ),2 ) ,: ) = [];
        s2 = SEGS{sids(2)}; s2( any( isnan( s2 ),2 ) ,: ) = [];
        
        if ~isequal( s1(1,:) , s1(end,:) )
          set( HGS{2} , 'String','First segment must be closed.','ApplicationData',struct('DDELAY',1.5));
          return;
        end
        if ~isequal( s2(1,:) , s2(end,:) )
          set( HGS{2} , 'String','Second segment must be closed.','ApplicationData',struct('DDELAY',1.5));
          return;
        end
          
        
        saveUNDO( xyz );

        P = polygon_mx( { s1(:,1:2) , 1 } , { s2(:,1:2) , 1 } );

        new_segs = SEGS(1:min(sids)-1);
        for p = 1:size( P , 1 )
          xy = P{p,1}.XY;
          xy(:,3) = 0;
          new_segs{end+1} = xy([1:end 1],:); %#ok<AGROW>
        end
        for p = min(sids)+1:max(sids)-1
          new_segs{end+1} = SEGS{p}; %#ok<AGROW>
        end
        for p = max(sids)+1:size(SEGS,1)
          new_segs{end+1} = SEGS{p}; %#ok<AGROW>
        end
        
        setCoords( joinSegments( new_segs ) );
      end
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Eraser()
    START_( 'Click->remove points; SPACE->start SELECTOR' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'circle' , 'Help' , {'<b>click 1</b>: erase points','<b>wheel</b>: increase/decrease radius','<b>numeric +/-</b>: increase/decrease radius','<b>SPACE + E</b>: start selector'});
    
    UNDOset = false;
    setLastPoint( NaN(1,3) );
    xyz = [ getCoords( ) ; NaN(1,3) ];
    
    HGS{3} = line('Parent',HH.Axe,'LineStyle',':','Marker','o','MarkerSize',1,'XData',get(L,'XData'),'YData',get(L,'YData'),'ZData',get(L,'ZData'),'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));
    
    PP = gCP( );

    screenSize = get(0,'ScreenSize');
    R = screenSize(4) / 60 * PixelSize(HH.Axe);
    
    HGS{4} = hgtransform('Parent',HH.Axe,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.2));
    t = linspace( 0 , 2*pi , 100 );
    line( 'Parent' , HGS{4} , 'XData', cos(t) , 'YData', sin(t) ,'zdata',zeros(size(t)) , 'linewidth',2,'linestyle','-','color',[1 0 1],'marker','none' );
    setM( HGS{4} , [ eye(3)*R , [ PP(1:2).' ; Z ] ; 0 0 0 1 ] );

    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)MOVING , 'WindowKeyPressFcn' , @(h,e)MOVING ,  'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonDownFcn' , @(h,e)MOVING() , 'WindowScrollWheelFcn'  , @(h,e)ScaleHgTransform( e , HGS{4} ) );
    MOVING( );
    function MOVING( ), try, %#ok<ALIGN>
      pk = pressedkeys(1);
      if ~any( strcmp( pk , 'E'        ) ), STOP_AND_RESTORE_( oldSTATE );   return; end

      if  any( strcmp( pk , 'SPACE'    ) )
        
        set( HGS{4} , 'Visible' , 'off' );
        
        HGS{5} = line('XData',[],'YData',[],'LineStyle','-','LineWidth',3,'Marker','s','Color',get(L,'Color'),'MarkerFaceColor',get(L,'Color'),'MarkerSize',8,'Parent',HH.Axe,'CLimInclude','on','Tag','drawContours.auxHandles');
        
        w = find( any( isnan( xyz ) , 2 ) );
        SELECTOR( HGS{5} , {'SPACE','E'} , w );
        waitfor( HGS{5} , 'CLimInclude' , 'off' );
        
        w = get( HGS{5} , 'UserData' );
        delete( HGS{5} ); HGS(5) = [];
        
        if isempty( w ), return; end
        
      else
        
        set( HGS{4} , 'Visible' , 'on' );
        if  any( strcmp( pk , 'ADD'      ) ), ScaleHgTransform( +1 , HGS{4} ); return; end
        if  any( strcmp( pk , 'SUBTRACT' ) ), ScaleHgTransform( -1 , HGS{4} ); return; end

        isB1 = any( strcmp( pk , 'BUTTON1' ) );
        CP = gCP( );
        if ~isB1 && isequal( PP , CP ), return; end
        PP = CP;
        M = get( HGS{4} ,'Matrix'); M(13:14) = CP(1:2); setM( HGS{4} , M );

        if ~isB1, return; end

        R2 = M(1)^2;
        w = sum( bsxfun( @minus , xyz , CP ).^2 , 2 ) < R2;
        if ~any(w), return; end
        
      end

      if ~UNDOset, saveUNDO( xyz ); UNDOset = true; end

      xyz( w , : ) = NaN;
      setCoords( xyz );
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_CopyTo( newL )
    START_( sprintf('Click on a segment to copy in label %d',newL) );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'select' , 'Help' , {'<b>click 1</b>: on a segment'} );
    
    setLastPoint( NaN(1,3) );

    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK( ) );
    function CLICK( ), try,  %#ok<ALIGN>
      CP = gCP( );
      
      sid = ClickOnSegment( L , CP , 'sID' );
      if ~sid, return; end
      
      SEGS = splitSegments( getCoords( ) );
      seg = SEGS{sid};
      seg( any(isnan(seg),2) ,:) = [];
      seg = [ seg ; NaN(1,3) ];

      oldL = L;
      L = HH.Contour(newL);
      setCoords( joinSegments( [ splitSegments( getCoords() ) ; seg ] ) );

      oldVisible = get( L , 'Visible' );
      set( L , 'Visible','on', 'LineWidth',8 );
      
      start( timer( 'TimerFcn' , @(h,e)set(L,'LineWidth',1,'Visible',oldVisible) , 'StartDelay' , 1 , 'ExecutionMode' , 'singleShot' , 'StopFcn' , @(h,e)delete(h) , 'UserData' , dbstack() ,'Tag',sprintf('%.16f',double(HH.Axe))) );
      
      L = oldL;
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Move( )
    %%TODO, I would like to move points besides of segments (by means of
    %%the use of SELECTOR.
    START_( 'Click on a segment and drag' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'move' , 'Help' , {'<b>click 1</b>: on a segment and drag'} );
    
    setLastPoint( NaN(1,3) );
    
    HGS{3} = line('Parent',HH.Axe,'LineStyle',':','Marker','o','MarkerSize',1,'XData',get(L,'XData'),'YData',get(L,'YData'),'ZData',get(L,'ZData'),'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));

    xyz = getCoords( );
    SP   = [];
    sid  = 0; w = [];
    SEGS = {};
    seg  = []; fixed_step = 10*[ mean( diff( H.DX ) ) , mean( diff( H.DY ) ) , 0 ];
    
    set( HH.Fig , 'WindowButtonDownFcn' , @(h,e)CLICK( ) , 'WindowButtonMotionFcn' , @(h,e)MOVING( ) , 'WindowKeyPressFcn' , @(h,e)MOVING( ) );
    %function STOP_MOVING( ), sid = 0; end
    function CLICK( ), try, %#ok<ALIGN>
      SP = gCP( );
      
      sid = ClickOnSegment( L , SP , 'sID' );
      if ~sid, return; end
      
      saveUNDO( xyz );
      
      SEGS = splitSegments( xyz );
      seg  = SEGS{sid};
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
    function MOVING( ), try, %#ok<ALIGN>
      pk = pressedkeys(1);
      if ~any( strcmp( pk , 'M') )
        STOP_AND_RESTORE_( oldSTATE )
        
      elseif  any( strcmp( pk , 'SPACE'    ) ) && 0
        
        HGS{5} = line('XData',[],'YData',[],'LineStyle','-','LineWidth',3,'Marker','s','Color',get(L,'Color'),'MarkerFaceColor',get(L,'Color'),'MarkerSize',8,'Parent',HH.Axe,'CLimInclude','on','Tag','drawContours.auxHandles');
        
        w = find( any( isnan( xyz ) , 2 ) );
        SELECTOR( HGS{5} , {'SPACE','M'} , w );
        waitfor( HGS{5} , 'CLimInclude' , 'off' );
        
        w = get( HGS{5} , 'UserData' );
        delete( HGS{5} ); HGS(5) = [];
        w = setdiff( w , find( any( isnan( xyz ) , 2 ) ) );
        SP = mean( xyz(w,:) , 1 );
        
      elseif ~isempty( w )
        
        CP = gCP( );
        xyz(w,:) = bsxfun( @plus , xyz(w,:) , CP - SP );
        SP = CP;
        setCoords( xyz );
        
      elseif ~~sid && (  any( strcmp( pk , 'LEFT' ) ) || any( strcmp( pk , 'NUMPAD6' ) ) )
        seg = bsxfun( @plus , seg , [-1 0 0].*fixed_step ); SEGS{sid} = seg; setCoords( joinSegments( SEGS ) );
      elseif ~~sid && (  any( strcmp( pk , 'RIGHT' ) ) || any( strcmp( pk , 'NUMPAD4' ) ) )
        seg = bsxfun( @plus , seg , [1 0 0].*fixed_step ); SEGS{sid} = seg; setCoords( joinSegments( SEGS ) );
      elseif ~~sid && (  any( strcmp( pk , 'UP' ) ) || any( strcmp( pk , 'NUMPAD8' ) ) )
        seg = bsxfun( @plus , seg , [0 1 0].*fixed_step ); SEGS{sid} = seg; setCoords( joinSegments( SEGS ) );
      elseif ~~sid && (  any( strcmp( pk , 'DOWN' ) ) || any( strcmp( pk , 'NUMPAD2' ) ) )
        seg = bsxfun( @plus , seg , [0 -1 0].*fixed_step ); SEGS{sid} = seg; setCoords( joinSegments( SEGS ) );
        
      elseif ~~sid         
        
        CP = gCP( );
        SEGS{sid} = bsxfun( @plus , SEGS{sid} , CP - SP );
        SP = CP;
        setCoords( joinSegments( SEGS ) );
      
      end
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_WMove( )
    START_( 'Click and drag' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'point' , 'Help' , {'<b>click 1</b>: and drag for push contours','<b>click 3</b>: and drag for kernelized deformation','<b>wheel</b>: increase/decrease radius','<b>numeric +/-</b>: increase/decrease radius'} );
    
    setLastPoint( NaN(2,3) );
    
    HGS{3} = line('Parent',HH.Axe,'LineStyle',':','Marker','o','MarkerSize',1,'XData',get(L,'XData'),'YData',get(L,'YData'),'ZData',get(L,'ZData'),'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));
    
    xyz = [];
    SP  = [];
    W   = [];
    MODE = 0;
    R   = [];
    
    PP = gCP( );
    if MODE == 0
      R = sqrt( min( sum( bsxfun( @minus , getCoords( ) , PP ).^2 , 2 ) ) );
      R = R * 1.2;
    end
    if isempty( R ) 
      screenSize = get(0,'ScreenSize');
      R = screenSize(4) / 15 * PixelSize(HH.Axe);
    end
    
    
    HGS{4} = hgtransform('Parent',HH.Axe,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.2));
    setM( HGS{4} , [ eye(3)*R , [ PP(1:2).' ; Z ] ; 0 0 0 1 ] );
    
    t = linspace( 0 , 2*pi , 100 );
    col = [ 0.9 , 1.0 , 1.0 ];
    patch( 'Parent' , HGS{4} , ...
      'Vertices' , [ cos(t(:)) , sin(t(:)) , zeros(numel(t),1) ] ,...
      'Faces', 1:numel(t) ,...
      'LineWidth' , 1 ,...
      'FaceColor' , 'none' ,...
      'EdgeColor' , col ,...
      'EdgeAlpha' , 0.2 );
    patch( 'Parent' , HGS{4} , ...
      'Vertices' , [ cos(t(:)) , sin(t(:)) , zeros(numel(t),1) ; 0 0 0 ] ,...
      'Faces', [ 1:numel(t) ; 2:numel(t) , 1 ; zeros(1,numel(t)) + numel(t)+1 ].' ,...
      'FaceColor' , col ,...
      'EdgeColor' , 'none' ,...
      'FaceAlpha' , 'interp' ,...
      'FaceVertexAlphaData', [ zeros(numel(t),1)+0.01 ; 1 ] ,...
      'Marker' , 'none' );
      

    HGS{5} = line('Parent',HH.Axe,'LineWidth',2,'LineStyle','-','XData',[NaN NaN],'YData',[NaN NaN],'Color',[1,0,1],'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.15));
    
    
    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)MOVING , 'WindowKeyPressFcn' , @(h,e)MOVING ,  'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonDownFcn' , @(h,e)CLICK() , 'WindowScrollWheelFcn'  , @(h,e)ScaleHgTransform( e , HGS{4} ) );
    function CLICK( ), try, %#ok<ALIGN>
      pk = pressedkeys(3);
      if pk == 1,      MODE = 1;
      elseif pk == 4,  MODE = 4;
      end
      if MODE == 0, return; end
      
      xyz = [ getCoords( ) ; NaN(1,3) ]; saveUNDO( xyz );
      W   = zeros( size( xyz ,1) , 1);

      SP = gCP( );
      if MODE == 4
      
        M = get( HGS{4} ,'Matrix'); R = M(1);
        set( HGS{5} , 'XData' , SP(1)+[0 0] , 'YData' , SP(2)+[0 0] );

        D2 = sum( bsxfun( @minus , xyz , SP ).^2 , 2 );
        w = D2 < R^2;
        W(w) = ( 1 + cos( sqrt( D2(w) )/ R * ( pi) ) )/2;
      
      end

    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end    
    function MOVING( ), try, %#ok<ALIGN>
      pk = pressedkeys(1);
      if ~any( strcmp( pk , 'W'        ) ), STOP_AND_RESTORE_( oldSTATE );   return; end

      if MODE ~= pressedkeys(3)
        MODE = 0;
      end
      
        
      CP = gCP( );
      if MODE == 0
        
        set( HGS{5} , 'XData' , [NaN NaN] );
        
        if  any( strcmp( pk , 'ADD'      ) ), ScaleHgTransform( +1 , HGS{4} ); return; end
        if  any( strcmp( pk , 'SUBTRACT' ) ), ScaleHgTransform( -1 , HGS{4} ); return; end

        M = get( HGS{4} ,'Matrix'); M(13:14) = CP(1:2); setM( HGS{4} , M );
        
      elseif MODE == 4
        
        set( HGS{5} , 'XData' , [ SP(1) , CP(1) ] , 'YData' , [ SP(2) , CP(2) ] );
        setCoords( xyz + W * ( CP - SP ) );
        
      elseif MODE == 1
      
        M = get( HGS{4} ,'Matrix'); M(13:14) = CP(1:2); setM( HGS{4} , M );
        R = M(1);
        
        W(:) = 0;
        D2 = sum( bsxfun( @minus , xyz , SP ).^2 , 2 );
        w = D2 < R^2;
        W(w) = ( 1 + cos( sqrt( D2(w) )/ R * ( pi) ) )/2;
        
        xyz = xyz + W * ( CP - SP );
        setCoords( xyz );
        SP = CP;

      end

    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Corrector()
    START_( 'Click to push points' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'crosshair' , 'Help' , {'<b>click 1 and move</b>: push points','<b>wheel</b>: increase/decrease radius','<b>numeric +/-</b>: increase/decrease radius'});
    
    UNDOset = false;
    setLastPoint( NaN(1,3) );
    xyz = [ getCoords( ) ; NaN(1,3) ];
    
    HGS{3} = line('Parent',HH.Axe,'LineStyle',':','Marker','o','MarkerSize',1,'XData',get(L,'XData'),'YData',get(L,'YData'),'ZData',get(L,'ZData'),'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));
    
    PP = gCP( );

    R = sqrt( min( sum( bsxfun( @minus , getCoords( ) , PP ).^2 , 2 ) ) );
    if isempty( R ), R = 20 * H.InterPointThreshold; end

    HGS{4} = hgtransform('Parent',HH.Axe,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.2));
    %,'Clip','off'
    t = linspace( 0 , 2*pi , 100 );
    %line( 'Parent' , HGS{4} , 'XData', cos(t) , 'YData', sin(t) ,'zdata', zeros(size(t)) , 'linewidth',2,'linestyle','-','color',[1 1 0],'marker','none' );%,'Clip','off');
    
    if 1
      patch( 'Parent' , HGS{4} , ...
        'Vertices' , [ cos(t(:)) , sin(t(:)) , zeros(numel(t),1) ] ,...
        'Faces', 1:numel(t) ,...
        'FaceAlpha' , 0.1 ,...
        'FaceColor' , [1,1,0] ,...
        'EdgeColor' , [1,1,0] ,...
        'EdgeAlpha' , 0.4 );
    else
      col = [ 0.9 , 1.0 , 1.0 ];
      patch( 'Parent' , HGS{4} , ...
        'Vertices' , [ cos(t(:)) , sin(t(:)) , zeros(numel(t),1) ] ,...
        'Faces', 1:numel(t) ,...
        'LineWidth' , 1 ,...
        'FaceColor' , 'none' ,...
        'EdgeColor' , col ,...
        'EdgeAlpha' , 0.2 );
      patch( 'Parent' , HGS{4} , ...
        'Vertices' , [ cos(t(:)) , sin(t(:)) , zeros(numel(t),1) ; 0 0 0 ] ,...
        'Faces', [ 1:numel(t) ; 2:numel(t) , 1 ; zeros(1,numel(t)) + numel(t)+1 ].' ,...
        'FaceColor' , col ,...
        'EdgeColor' , 'none' ,...
        'FaceAlpha' , 'interp' ,...
        'FaceVertexAlphaData', [ zeros(numel(t),1)+0.01 ; 1 ] ,...
        'Marker' , 'none' );
    end
    
    %'XData', cos(t) , 'YData', sin(t) ,'zdata', zeros(size(t)) , 'linestyle','-','color',[1 1 0],'marker','none' );%,'Clip','off');
    setM( HGS{4} , [ eye(3)*R , [ PP(1:2).' ; Z ] ; 0 0 0 1 ] );

    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)MOVING( ) , 'WindowKeyPressFcn' , @(h,e)MOVING( ) ,  'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonDownFcn' , @(h,e)MOVING( ) , 'WindowScrollWheelFcn'  , @(h,e)ScaleHgTransform( e , HGS{4} ) );
    MOVING( );
    function MOVING( ), try, %#ok<ALIGN>
      pk = pressedkeys(1);
      if ~any( strcmp( pk , 'D'        ) ), STOP_AND_RESTORE_( oldSTATE );   return; end
      if  any( strcmp( pk , 'ADD'      ) ), ScaleHgTransform( +1 , HGS{4} ); return; end
      if  any( strcmp( pk , 'SUBTRACT' ) ), ScaleHgTransform( -1 , HGS{4} ); return; end

      isB1 = any( strcmp( pk , 'BUTTON1' ) );
      CP = gCP( );
      if isequal( PP , CP ), return; end
      M = get( HGS{4} ,'Matrix'); M(13:14) = CP(1:2); setM( HGS{4} , M );

      if ~isB1, PP = CP; return; end

      R = M(1); R2 = R.^2;
      res = bsxfun( @minus , xyz , CP );
      w = sum( res.^2 , 2 ) < R2  &  res(:,1:2)*( CP(1:2) - PP(1:2) ).' > 0;
      PP = CP;
      if ~any(w), return; end
      if ~UNDOset, saveUNDO( xyz ); UNDOset = true; end
      
      res = res(w,1:2);
      res = bsxfun( @rdivide , res , sqrt( sum( res.^2 , 2 ) ) );
      res = res * R;
      res = bsxfun( @plus , res , CP(1:2) );
      
      xyz( w , 1:2 ) = res;
      setCoords( xyz );      
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_ConvertToSpline( )
    START_( 'Click on a segment to convert it into spline' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'selects' , 'Help' , {'<b>click 1</b>: on a segment to convert it into spline','<b>click 3</b>: interactively select number of points'} );
    
    oldSTRING = get( HGS{2} , 'String' );
    
    setLastPoint( NaN(1,3) );
    HGS{3} = line('Parent',HH.Axe,'LineStyle',':','Marker','o','MarkerSize',1,'XData',get(L,'XData'),'YData',get(L,'YData'),'ZData',get(L,'ZData'),'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));

    %AxePos = AxePosition( HH.Axe );
    %HGS{4} = uicontrol('Parent', HH.Parent ,'style','edit','position',[ AxePos(1)+5 , AxePos(2)+AxePos(4)-5-20 , 75 , 20 ],'String',sprintf('%.5f',H.InterPointThreshold),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.0) ,'ToolTipString','Approximate InterPoint Distance');
    
    xyz  = getCoords( );
    SEGS = splitSegments( xyz );
    seg  = [];
    sid  = 0;
    
    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK() );
    function CLICK( ), try %#ok<ALIGN>
      %if isequal(  hittest( ) , HGS{4} ), return; end
      CP = gCP( );

      sid = ClickOnSegment( L , CP , 'sID' );
      if ~sid, return; end

      seg  = SEGS{sid};

      pk = pressedkeys(3);
      if pk == 1

        SEGS{sid} = toSpline( seg , -H.InterPointThreshold ); %-str2double( get( HGS{4} , 'Value' ) ) );
        saveUNDO( xyz );
        xyz = joinSegments( SEGS );
        setCoords( xyz );

      elseif pk == 4
        
        oldSTATE2 = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'heditbar' , 'Help' , {'<b>move up/down</b>: increase/decrease the number of points'} );

        n_original = sum( ~any( isnan( seg ) , 2 ) );
        n_max = cumsum( sqrt( sum( diff( seg , 1 , 1 ).^2 , 2 ) ) );
        n_max = max( n_max );
        n_max = ceil( n_max / H.InterPointThreshold );
        n_min = 2;
        fSP = get(HH.Fig,'CurrentPoint');

        set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonMotionFcn' , @(h,e)MOVING( fSP(2) , [ n_original , n_min , n_max ] ) , 'WindowButtonUpFcn' , @(h,e)STOP_MOVING( oldSTATE2 ) );
        
      end
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
    function STOP_MOVING( oldSTATE2 )
      set( HGS{2} , 'String' , oldSTRING );
      RestoreFigure( HH.Fig , oldSTATE2 );
    end
    function MOVING( fSP , r )
      
      SP = get(HH.Fig,'CurrentPoint');
      
      if     SP(2) < fSP

        h = fSP - SP(2);
        d = h * ( r(1) - r(2) )/200;
        n = r(1) - d;
        n = round( max( n , r(2) ) );
        
      elseif SP(2) > fSP

        h = SP(2) - fSP;
        d = h * ( r(3) - r(1) )/200;
        n = r(1) + d;
        n = round( min( n , r(3) ) );
        
      else
        n = r(1);
      end
      
      set( HGS{2} , 'String' , sprintf('%d points (originally: %d)',n,r(1)) );
      
      SEGS{sid} = toSpline( seg , n );

      xyz = joinSegments( SEGS );
      setCoords( xyz );
      %%%TODO (save UNDO)
      
    end
  end
  function START_Offset( )
    START_( 'Click on a segment and drag' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'offset' , 'Help' , {'<b>click 1</b>: on a segment and drag'} );
    
    setLastPoint( NaN(1,3) );
    
    HGS{3} = line('Parent',HH.Axe,'LineStyle',':','Marker','o','MarkerSize',1,'XData',get(L,'XData'),'YData',get(L,'YData'),'ZData',get(L,'ZData'),'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));

    sid  = 0;
    SEGS = {};
    seg  = [];
    normals = [];
    
    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK( ) , 'WindowButtonMotionFcn' , @(h,e)MOVING( ) , 'WindowButtonUpFcn' , @(h,e)STOP_MOVING( ) );
    function STOP_MOVING( )
      sid = 0;
      set( HGS{2} , 'String' , 'Offset' );
    end
    function CLICK( ), try, %#ok<ALIGN>
      CP = gCP( );
      
      sid = ClickOnSegment( L , CP , 'sID' );
      if ~sid, return; end
      PP = CP;
      
      xyz = getCoords( ); saveUNDO( xyz );
      SEGS = splitSegments( xyz );
      
      seg = SEGS{sid};
%       seg( any( isnan( seg ) , 2 ) , : ) = [];
      seg = seg( : ,1:2);
      normals = ComputeNormals( seg );
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
    function MOVING( ), try,  %#ok<ALIGN>
      if ~sid, return; end
      CP = gCP( );
      if isequal( PP , CP ), return; end
      PP = CP;

      [cxy,d,id] = ClosestPointToPolyline( CP(1:2) , seg );
      n_at_cxy = diff( seg(id:id+1,:) , 1 , 1 ) * [0,-1;1,0];
      if ( cxy - CP(1:2) )*n_at_cxy(:) > 0, d = -d; end
      
      SEGS{sid}(:,1:2) = seg + normals * d;
      
      %%%%%%%SEGS{sid} = offsetCurve( seg(:,1) , seg(:,2) , -d , true );
      
      setCoords( joinSegments( SEGS ) );
      
      set( HGS{2} , 'String' , sprintf('Offset: %.2f', abs(d) ) );
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Circle( )
    START_( 'Click center point' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'circle' , 'Help' , {'<b>click 1</b>: to specify the center'} );
    
    setLastPoint( NaN(1,3) );
    
    HGS{3} = line('Parent',HH.Axe,'LineStyle','-','Marker','o','MarkerSize',1,'XData',NaN,'YData',NaN,'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.25));
    HGS{4} = line('Parent',HH.Axe,'LineStyle',':','Marker','+','XData',NaN,'YData',NaN,'color',[1,0,1],'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.85));

    C = [];
    MODE = 0;
    
    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK( ) , 'WindowButtonMotionFcn' , @(h,e)MOVING( ) , 'WindowButtonUpFcn' , @(h,e)STOP_MOVING( ) );
    MOVING( );
    function STOP_MOVING( )
      xyz = getCoords( );
      if size(xyz,1), xyz = [ xyz ; NaN NaN NaN ]; end
      x = get( HGS{3} , 'XData' );
      y = get( HGS{3} , 'YData' );
      z = zeros( size(x) );
      xyz = [ xyz ; x(:) , y(:) , z(:) ; NaN(2,3) ];
      setCoords(  xyz );
    end
    function CLICK( ), try, %#ok<ALIGN>
      C = gCP( );
      MODE = pressedkeys(3);
      set( HGS{2} , 'String' , 'Radius: ' );
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
    function MOVING( ), try,  %#ok<ALIGN>
      CP = gCP( );
      if ~MODE
        set( HGS{4} , 'XData' , CP(1) , 'YData' , CP(2) );
        return;
      end

      
      switch MODE
        case 1
          set( HGS{4} , 'XData' , [ C(1) , CP(1) ] , 'YData' , [ C(2) , CP(2) ] );
          R = sqrt( sum( ( C - CP ).^2 ) );
          set( HGS{2} , 'String' , sprintf('Radius: %.2f', R ) );

          n = ceil( R * pi / H.InterPointThreshold ) + 1;
          t = linspace( 0 , 2*pi , n ); t(end) = 0;
          x = cos(t(:))*R + C(1);
          y = sin(t(:))*R + C(2);
        
        case 4
          R = abs( CP - C );
          pk = pressedkeys(0);
          if numel(pk) == 2 && strcmp( pk{2} , 'LSHIFT' )
            CP = C - max(R) * sign( C - CP );
            R(:) = max(R);
          end
            
          
          set( HGS{4} , 'XData' , [ C(1) , CP(1) , CP(1) , C(1) , C(1) ] , 'YData' , [ C(2) , C(2) , CP(2) , CP(2) , C(2) ] );
          set( HGS{2} , 'String' , sprintf('Lengths: %.2f , %.2f', R(1) , R(2) ) );
          
          n = ceil( max(R) * pi / H.InterPointThreshold ) + 1;
          t = linspace( 0 , 2*pi , n ); t(end) = 0;
          x = cos(t(:))*R(1)/2 + C(1) - R(1)/2*sign( C(1) - CP(1) );
          y = sin(t(:))*R(2)/2 + C(2) - R(2)/2*sign( C(2) - CP(2) );
          
      end
      set( HGS{3} , 'XData' , x , 'YData' , y );
      
      
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_ConvexHull( )
    START_( 'Click on a segment and drag' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'select' , 'Help' , {'<b>click 1</b>: on a segment and drag'} );
    
    setLastPoint( NaN(1,3) );
    
    HGS{3} = line('Parent',HH.Axe,'LineStyle',':','Marker','o','MarkerSize',1,'XData',get(L,'XData'),'YData',get(L,'YData'),'ZData',get(L,'ZData'),'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));

    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK( ) );
    function CLICK( ), try, %#ok<ALIGN>
      CP = gCP( );
      
      sid = ClickOnSegment( L , CP , 'sID' );
      if ~sid, return; end
      
      xyz = getCoords( ); 
      SEGS = splitSegments( xyz );
      seg = SEGS{sid};
      NaNs_at = any( isnan( seg ) , 2 );
      seg( NaNs_at , : ) = [];
      
      ch = convhull( seg(:,1) , seg(:,2) );
      ch = seg( ch , :);
      if ~isequal( ch , seg )
        saveUNDO( xyz );
      end
      
      SEGS{sid} = ch;
      setCoords( [ joinSegments( SEGS ) ; NaN( any(NaNs_at) , 3 ) ] );
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Isophote( )
    START_( '                 ' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'pencil' , 'Help' , {'<i>contour</i> for interpolation mode','<i>boundary</i> for flat mode','------------','thin lines: whole image','thick line: closest to pointer','------------','<b>click 1</b>: add as a segment'});

    HGS{3} = line('Parent',HH.Axe    ,'Color',[0.8,0.4,0.8],'LineStyle',':','Marker','none','XData',[],'YData',[]              ,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5));
    HGS{4} = line('Parent',HH.ZoomAxe,'Color',[0.8,0.4,0.8],'LineStyle',':','Marker','none','XData',[],'YData',[]              ,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5));
    HGS{5} = line('Parent',HH.Axe    ,'Color',[1.0,0.2,1.0],'LineStyle','-','Marker','none','XData',[],'YData',[],'LineWidth',2,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.5));

    set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonDownFcn' , @(h,e)MOVING() , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) );
    MOVING( );
    function MOVING( ), try %#ok<ALIGN>
      CP = gCP( );
      pk = pressedkeys(3);
      if ~pk && isequal( PP , CP ), return; end
      PP = CP;

      setLastPoint( CP );
      
      switch lower( get(HH.Surface,'FaceColor') )
        case 'interp'
          [~,~,V,v] = GetInfo( CP ); if isnan(V), return; end
          set( HGS{2} , 'String' , sprintf('Isophote: %f',v) );

          c = contourc( H.X , H.Y , IF.' , [1 1]*v ); c = c.';
          i = 1; while i <= size(c,1), c(i,1) = NaN; i = i + c(i,2) + 1; end
        case 'flat'
          [~,~,V] = GetInfo( CP ); if isnan(V), return; end
          set( HGS{2} , 'String' , sprintf('Isophote: <= %.2f',V) );

          c = boundary( IF <= V  , H.DX , H.DY , 0 ).';
      end
      set( [ HGS{3} , HGS{4} ] , 'XData' , c(:,1) , 'YData' , c(:,2) );

      [~,~,s] = ClosestPointToPolyline( CP(1:2) , c );
      ns = [ 0 ; find( isnan(c(:,1)) ) ; size(c,1)+1 ];
      c = c( ( ns( find( ns < s , 1 ,'last' ) )+1 ):( ns( find( ns > s , 1 ) )-1 ) , : );
      set( HGS{5} , 'XData' , c(:,1) , 'YData' , c(:,2) );

      if pk == 1
        xyz = getCoords( );
        if size(xyz,1), xyz = [ xyz ; NaN NaN NaN ]; end
        c(:,3) = 0;
        xyz = [ xyz ; c ; NaN(2,3) ];
        setCoords(  xyz );
      end
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function START_Snap( )
    START_( '                 ' );
    if ~isfield( H , 'SnapPoints' )
      set( HGS{2} , 'String' , 'Building SnapPoints' );
      
      E = SubpixelBoundaryDetector( IF , -1 , 2 );
      [~,o]=sort( E.i1-E.i0 );
      E = [ E.x(o) , E.y(o) , E.i1(o)-E.i0(o) ];
      E( E(:,1) < 0.5 | E(:,1) > size(IF,2)+0.5 | E(:,2) < 0.5 | E(:,2) > size(IF,1)+0.5 , : ) = [];
      E(:,3) = E(:,3)/max( E(:,3) );
      E = [ Interp1D( H.X(:) , (1:numel(H.X)).' , E(:,2) ) , Interp1D( H.Y(:) , (1:numel(H.Y)).' , E(:,1) ) , Interp1D( jet(1000) , linspace(0,1,1000) , E(:,3) ) ];
      
      H.SnapPoints = E;
    end
    set( HGS{2} , 'String' , '' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'cross' , 'Help' , {'<i>click 1 and drag</i> draw but snapping to points'});

    if ~isfield( H , 'SnapPoints_0' ), H.SnapPoints_0 = 1; end
    if ~isfield( H , 'SnapPoints_1' ), H.SnapPoints_1 = size( H.SnapPoints , 1 ); end
    SNAPS = H.SnapPoints( H.SnapPoints_0:H.SnapPoints_1 , : );
    set( HGS{2} , 'String' , sprintf('%d Boundary points',size(SNAPS,1)) );

    AxePos = AxePosition( HH.Axe );
    HGS{3} = uicontrol('Parent',HH.Parent,'Style','slider','Position',[ AxePos(1)+5 , AxePos(2)+AxePos(4)-5 - 15 , 150 , 15 ],'Min',1,'Max',size(H.SnapPoints,1),'Value',H.SnapPoints_0,'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.0) );
    jScrollBar = findjobj( HGS{3} );
    jScrollBar.AdjustmentValueChangedCallback = @(h,e)Change_SnapLimits( );

    HGS{4} = patch( 'Parent',HH.Axe , 'Vertices' , [ SNAPS(:,1:2) , SV(SNAPS,Z) ] , 'Faces' , (1:size(SNAPS,1)).' , 'CData' , permute(SNAPS(:,[3 4 5]),[1 3 2]) , 'Marker','o','MarkerSize',3,'MarkerFaceColor','flat','MarkerEdgeColor','none','FaceColor','none','EdgeColor','none','Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));
    
    set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonDownFcn' , @(h,e)MOVING() , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) );
    function MOVING( ), try, %#ok<ALIGN>
      if isequal(  hittest( ) , HGS{3} ), return; end
      CP = gCP( );
      CP(1:2) = SNAPS( ClosestPoint( SNAPS , CP(1:2) ) , 1:2 );
      
      pk = pressedkeys(3);
      if pk == 1
        if isequal( PP , CP ), return; end
        CP = [1;1]*CP;
        PP = CP;
      elseif pk == 4
        CP = NaN(2,3);
      end
      setLastPoint( CP );
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
    function Change_SnapLimits( )
      H.SnapPoints_0 = round( get( HGS{3} , 'Value' ) );
      SNAPS = H.SnapPoints( H.SnapPoints_0:H.SnapPoints_1 , : );
      
      set( HGS{4} , 'Vertices' , [ SNAPS(:,1:2) , SV(SNAPS,Z) ] , 'Faces' , (1:size(SNAPS,1)).' , 'CData' , permute(SNAPS(:,[3 4 5]),[1 3 2]) );
      set( HGS{2} , 'String' , sprintf('%d Boundary points',size(SNAPS,1)) );
    end
  end
  function START_Smooth( )
    START_( 'Click on a segment and move up/down' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'select' , 'Help' , {'<b>click 1</b>: on a segment to interactivelly','smooth the contour.','Move UP/DOWN to increase/decrease the smoothing'} );
    
    oldSTRING = get( HGS{2} , 'String' );
    
    setLastPoint( NaN(1,3) );
    HGS{3} = line('Parent',HH.Axe,'LineStyle',':','Marker','o','MarkerSize',1,'XData',get(L,'XData'),'YData',get(L,'YData'),'ZData',get(L,'ZData'),'color',get(L,'Color'),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.75));

    %AxePos = AxePosition( HH.Axe );
    %HGS{4} = uicontrol('Parent', HH.Parent ,'style','edit','position',[ AxePos(1)+5 , AxePos(2)+AxePos(4)-5-20 , 75 , 20 ],'String',sprintf('%.5f',H.InterPointThreshold),'Tag','drawContours.auxHandles','ApplicationData',struct('DDELAY',0.0) ,'ToolTipString','Approximate InterPoint Distance');
    
    xyz  = getCoords( );
    SEGS = splitSegments( xyz , true );
    seg  = [];
    sid  = 0;
    
    set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonDownFcn' , @(h,e)CLICK() );
    function CLICK( ), try %#ok<ALIGN>
      CP = gCP( );

      sid = ClickOnSegment( L , CP , 'sID' );
      if ~sid, return; end

      seg  = SEGS{sid};

      pk = pressedkeys(3);

        oldSTATE2 = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'Pointer' , 'heditbar' , 'Help' , {'<b>move up/down</b>: increase/decrease the number of points'} );


        fSP = get(HH.Fig,'CurrentPoint');

        set( HH.Fig , 'WindowKeyReleaseFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE ) , 'WindowButtonMotionFcn' , @(h,e)MOVING( fSP(2) ) , 'WindowButtonUpFcn' , @(h,e)STOP_MOVING( oldSTATE2 ) );
        
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
    function STOP_MOVING( oldSTATE2 )
      set( HGS{2} , 'String' , oldSTRING );
      RestoreFigure( HH.Fig , oldSTATE2 );
    end
    function MOVING( fSP )
      
      SP = get(HH.Fig,'CurrentPoint');

      sigma = max( SP(2) - fSP , 0 )/50;
      
      set( HGS{2} , 'String' , sprintf('sigma: %g', sigma ) );
      
      if sigma == 0
        
        SEGS{sid} = seg;
      
      else
        
        SEGS{sid} = smoothCurve( seg , sigma );
        
      end

      xyz = joinSegments( SEGS );
      setCoords( xyz );

    end
  end

end

function xy = toSpline( xy , n )
  nanAtEnd = any( isnan(xy(end,:)) );
  xy( any(isnan(xy),2) , : ) = [];
  if size( xy , 1 ) < 2
    error('too few points');
  end
  
  Xs = [ 0 ; cumsum( sqrt( sum( diff( xy , [] , 1 ).^2 , 2 ) ) ) ];
  w = diff(Xs) == 0;
  xy(w,:) = [];
  Xs(w)   = [];

  if n < 0, n = ceil( Xs(end) / (-n) ); end
  nXs = linspace( 0 , Xs(end) , n );

  if ~isequal( xy(1,:) , xy(end,:) )

    xy = interp1( Xs , xy , nXs , 'spline' );
    
  else
    
    xy = interp1( [ Xs(1:end-1) - Xs(end) ; Xs ; Xs(2:end) + Xs(end) ] , xy( [ 1:end-1 , 1:end , 2:end ] ,:) , nXs );
    
  end
  if nanAtEnd
    xy(end+1,:) = NaN;
  end
  
end
function id = ClosestPoint( xy , p )
  nsd = min( size( xy , 2 ) , size( p , 2 ) );
  [~,id] = min( sum(bsxfun( @minus , xy(:,1:nsd) , p(:,1:nsd) ).^2 ,2) );
end
function X = DualGrid( X )
  try,  X = dualVector( X );
  catch LE, DE(LE);
    X = X(:).';
    X = [ X(1) - ( X(2) - X(1) )/2 , ( X(1:end-1) + X(2:end) )/2 , X(end) + ( X(end) - X(end-1) )/2 ];
  end
end
function SEGS = splitSegments( xyz , clean )
  if nargin < 2, clean = false; end
  w = any( isnan(xyz) , 2 );
  w( find(~w,1,'last'):end ) = false;
  w = [ true ; w ; true ];
  w = find(w)-1;
  SEGS = cell( numel(w)-1 , 1 );
  for s = 1:numel(SEGS)
    SEGS{s} = xyz( w(s)+1:w(s+1)-1 , : );
    if clean
      SEGS{s}( any(isnan(SEGS{s}),2) , : ) = [];
    end
  end
  SEGS( cellfun('isempty',SEGS) ) = [];
end
function xyz = joinSegments( SEGS )
  xyz = [];
  for s = 1:numel(SEGS)
    xyz = [ xyz ; SEGS{s} ; NaN NaN NaN ]; %#ok<AGROW>
  end
  if size( xyz , 1 ) > 1, xyz = [ xyz ; NaN(1,3) ]; end
end
function ps = PixelSize( h )
  oldUNITS = get( h , 'Units' );
  set( h , 'Units' , 'pixel' );
  AxePos = get( h , 'Position' );
  set( h , 'Units' , oldUNITS );    
  ps  = diff( get( h , 'YLim' ) )/AxePos(4);
end
function ap = AxePosition( h , idx )
  oldUNITS = get( h , 'Units' );
  set( h , 'Units' , 'pixel' );
  ap = get( h , 'Position' );
  set( h , 'Units' , oldUNITS );
  if nargin > 1, ap = ap( idx ); end
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
  oldSTATE.HelpString             = get( findall(h,'Tag','HelpPanel') , 'String' ); set( findall(h,'Tag','HelpPanel') , 'String' , {''} );

  for v = 1:2:numel(varargin)
    if strcmpi( varargin{v} ,'pointer' )
      setFigurePointer( h , varargin{v+1} );
    elseif strcmpi( varargin{v} , 'help' )
      if ischar( varargin{v+1} )
        str = varargin(v+1);
      else
        str = varargin{v+1};
        for i = 1:numel(str)
          str{i} = [ '<html>&nbsp;' , str{i} , '</html>' ];
        end
      end
      set( findall(h,'Tag','HelpPanel') , 'String' , [ {''} ; str(:) ] );
      set( findall(h,'Tag','HelpPanel') , 'Value', 1 );
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
  set( findall(h,'Tag','HelpPanel') , 'String' , oldSTATE.HelpString );
end
function safe_delete( h )
  try, delete( h ); drawnow(); catch LE, DE(LE); end
end
function [cxy,d,id] = ClosestPointToPolyline( xy , L )
  nxy = size( xy ,1);
  nL  = size( L  , 1 );
  
  xy = permute( xy ,[1 3 2]);
  L  = permute( L  ,[3 1 2]);
  
  D = diff( L , 1 , 2 );

  t = bsxfun( @rdivide, ...
              sum( bsxfun(@times, bsxfun(@minus, xy , L(:,1:nL-1,:) ) , D ) ,3),...
              sum( D.^2 ,3) );
  t = max(min(t,1),0);

  cxy = bsxfun(@plus, L(:,1:nL-1,:) , bsxfun(@times, t , D ) );
  d = sum( bsxfun(@minus,cxy,xy).^2 , 3);
  [d,id] = min( d , [] , 2 );
  
  t = t( sub2indv( size(t) , [ (1:nxy).' , id ] ) );
  
  L = ipermute( L ,[3 1 2]);
  D = ipermute( D ,[3 1 2]);
  
  cxy = L( id ,:) + bsxfun(@times, t , D(id,:) );
  d = sqrt(d);
end
function N = ComputeNormals( xy )

  NaNs_at = any( isnan(xy) , 2 );
  xy( NaNs_at , : ) = [];

  N = diff( xy , 1 , 1 );
  N = N * [ 0 , -1 ; 1 , 0 ];
  N = [ 0 0 ; N ] + [ N ; 0 0 ];
  if isequal( xy(1,:) , xy(end,:) ), N([1 end],:) = [1;1]*( N(1,:) + N(end,:)); end
  N = bsxfun( @rdivide , N , sqrt( sum( N.^2 , 2 ) ) );
  N( any( ~isfinite(N) ,2 ),: ) = 0;

  if any( NaNs_at ), N( NaNs_at ,:) = 0; end
  
end
function x = SV( x , v )  %scalar vector
  x = zeros(size(x,1),1) + v;
end
function setM( hg , M )
  if all(isfinite(M(:)))
    set( hg , 'Matrix' , M );
  end
end
function xy = smoothCurve( xy , s )

  g = 10 * ceil( s );
  g = -g:g;
  g = exp( - g.^2/(2*s*s) );
  
  g = g(:);
  g = g / sum(g);
  
  if isequal( xy(1,:) , xy(end,:) )
    bm = 'circular';
  else
    bm = 'replicate';
  end
    
  xy(:,1:2) = imfilter( xy(:,1:2) , g , 'same' , bm );

end
function h = ImageHisto( I , varargin )
  I = double(I(:));
  m = min(I);
  M = max(I);
  r = M-m;
  
  Nb = 50;
  e = [ m - r , linspace( m - r/10 , M + r/10 , Nb ) , M + r ];
  n = histc( I , e ).';
%   n = n;
  
  x = e( [ 1 , floor(2:0.5:Nb+1.5) , Nb+2 ] );
  try
  y = n( floor( 1:0.5:Nb+1.5 ) );
  y = log10( y );
  y = y - min(noinfs(y)) + 1/numel(I);
  y( isinf(y) ) = 0;
  y = y / max(y);
  y = y * 0.8;
  catch LE, DE(LE); 
    y = x * 0 + 1;
  end
  
  I = sort( I(:) );
  prcs = [0,5,10,25,50,75,90,95,100];
  if isempty( varargin ) || ischar( varargin{1} )
  
    h = patch( 'vertices' , [ x(:) , y(:) , zeros(numel(x),1)-1 ; x(end) , 0 , -1 ; x(1) , 0 , -1 ] , 'faces' , 1:(numel(x)+2) , 'edgecolor',[0 0 0],'facecolor',[1 1 1]*0.5 , varargin{:} );

    h(2) = line( 'XData' , I , 'YData', linspace(0,1,numel(I)) , 'Color',[1 1 1]*0.3,'LineWidth',1, varargin{:} );

    h(3) = line( 'XData' , prctile( I , prcs ) , 'YData', prcs/100 , 'Color',[1 1 1]*0.3,'Marker','.','LineStyle','none', varargin{:} );

  else
    
    h = varargin{1};

    set( h(1) , 'vertices' , [ x(:) , y(:) , zeros(numel(x),1)-1 ; x(end) , 0 , -1 ; x(1) , 0 , -1 ] , 'faces' , 1:(numel(x)+2) );

    set( h(2) , 'XData' , I , 'YData', linspace(0,1,numel(I)) );

    set( h(3) , 'XData' , prctile( I , prcs ) , 'YData', prcs/100 );
    
  end
  
end
function G = toGray( I , IT )
  try
    G = Interp1D( IT(:,2) , IT(:,1) , double(I(:)) , 'linear' , 'closest' );
  catch LE, DE(LE); 
    GI = griddedInterpolant( IT(:,1) , IT(:,2) , 'linear', 'nearest' );
    G = GI( double(I(:)) );
  end
  G = reshape( G , size(I) );
end


function y = intercalate( x , w )
  y = []; 
  if isempty( w ), return; end
  w = w(:).';
  w = sort( unique(w) );
  ww = find( [true,diff(w) > 1,true] );
  for i = 2:numel(ww)
    y = [ y ; NaN ; x( w(ww(i-1)):w(ww(i)-1) ) ];
  end
  y = [ y ; NaN ];
end


function xy = offsetCurve( x, y, offset, intersectremove)
% Offset a curve by a given distance
% Inputs:
%       x, y: input x and y coordinates
%       offset: offset amount in arbitrary units or in points if haxes
%           is provided
%       haxes: handle to parent axis if offset is determined in points
%       intersectremove: remove self-intersecting portions (default is
%           true)
%
% J. Duchateau, - IHU LIRYC, Bordeaux, France - 2015.
%
% You are free to distribute/modify as you please.


% First check for colinear points and remove them
if nargin < 4, intersectremove = 1; end
iPt=2;
eps = 10^-10;
xprod = @(x1, y1, x2, y2) x1*y2 - x2*y1;

while iPt < length(x)
  if abs(xprod(x(iPt)-x(iPt-1), y(iPt)-y(iPt-1), x(iPt+1)-x(iPt), y(iPt+1)-y(iPt))) < eps
    y(iPt) = [];
    x(iPt) = [];
  else
    iPt = iPt+1;
  end
end

% Now offset...
% 1) Get unit vector size in points
dirvect = [1 1];

% 2) Convert vector directions in points
compvect = dirvect(1) .* diff(x) + 1i*dirvect(2) .* diff(y);
directions = angle(compvect);

% 3) Rotate by 90
directions = directions + pi/2;

% 4) Offset by input offset value
offsetvect = offset * exp(1i*directions);

% 5) Convert back to axes units
offx = real(offsetvect) ./ dirvect(1);
offy = imag(offsetvect) ./ dirvect(2);

% Now that we have all our offsets, compute intersections between lines
% 1) Create new segment list
sx = offx + x(1:end-1);
sy = offy + y(1:end-1);
ex = offx + x(2:end);
ey = offy + y(2:end);

% 2) Join neighboring segments
iSeg = 1;
joinedx = sx(1);
joinedy = sy(1);
while iSeg < length(sx)
  % Find intersection with next
  [xi, yi, flag] = intersectSeg(sx(iSeg), sy(iSeg), ex(iSeg), ey(iSeg), sx(iSeg+1), sy(iSeg+1), ex(iSeg+1), ey(iSeg+1));
  if ~flag % Remove the next segment which is colinear
    sx(iSeg+1) = []; sy(iSeg+1) = []; ex(iSeg+1) = []; ey(iSeg+1) = [];
  else % Add the intersection to the point list
    joinedx = [joinedx xi];
    joinedy = [joinedy yi];
    iSeg = iSeg+1;
  end
end
joinedx = [joinedx ex(end)];
joinedy = [joinedy ey(end)];

if ~intersectremove, return; end
% 3) Remove self-intersections
iPt = 2;
while iPt < length(joinedx) - 1
  
  % Find candidates for self intersection
  xbnds = sort(joinedx([iPt-1 iPt]));
  ybnds = sort(joinedy([iPt-1 iPt]));
  
  rside = xbnds(2) < joinedx(iPt+1:end); % Fast scan of candidates
  lside = xbnds(1) > joinedx(iPt+1:end);
  above = ybnds(2) < joinedy(iPt+1:end);
  below = ybnds(1) > joinedy(iPt+1:end);
  
  rside = rside(1:end-1) & rside(2:end); % Both on right side
  lside = lside(1:end-1) & lside(2:end);
  above = above(1:end-1) & above(2:end);
  below = below(1:end-1) & below(2:end);
  
  cands = find(~(rside | lside | above | below));
  if ~isempty(cands)
    [xi, yi, flag] = arrayfun(@(x,y) ...
      intersectSeg(joinedx(iPt-1), joinedy(iPt-1), joinedx(iPt), joinedy(iPt), ...
      joinedx(x), joinedy(x), joinedx(x+1), joinedy(x+1)), (iPt+cands));
    iflag = find(flag == 1, 1, 'last');
    if ~isempty(iflag)
      joinedx(iPt) = xi(iflag);
      joinedy(iPt) = yi(iflag);
      joinedx(iPt+1:iPt+cands(iflag)) = [];
      joinedy(iPt+1:iPt+cands(iflag)) = [];
    end
  end
  iPt = iPt+1;
end

xy = [ joinedx(:) , joinedy(:) ];
xy(:,3) = 0;

  function [xi, yi, flag] = intersectSeg(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
    eps = 10^-10;
    adx = ax2-ax1; ady = ay2-ay1;
    bdx = bx2-bx1; bdy = by2-by1;
    
    xprod = @(x1, y1, x2, y2) x1*y2 - x2*y1;
    rxs = xprod(adx, ady, bdx, bdy);
    
    if abs(rxs) < eps % Parallel segments
      xi = NaN; yi = NaN; flag = 0;
    else
      t = xprod(bx1-ax1, by1-ay1, bdx, bdy) / rxs;
      u = xprod(bx1-ax1, by1-ay1, adx, ady) / rxs;
      
      xi = ax1 + t*adx;
      yi = ay1 + t*ady;
      if t>=0 && t <= 1 && u >= 0 && u <= 1
        flag = 1;
      else
        flag = 2;
      end
    end
    
    
  end

end
function e = CELLeq( X , Y , ord )
  if nargin > 2 && ord
    X = sort( X );
    Y = sort( Y );
  end
  e = false;
  if numel(X) ~= numel(Y), return; end
  for i = 1:numel(X)
    if ~isequal( X{i} , Y{i} ), return; end
  end
  e = true;
end
function xy = parentxy( ax )
  xy = get( ancestor(ax,'figure') , 'CurrentPoint' );
  
  pa = get( ax , 'Parent' );
  while 1 && ~strcmp( get(pa,'Type'),'figure')
    pos = PixelPos( pa );
    xy = xy - pos(1:2) + 2;
    pa = get( pa ,'Parent' );
  end
  
  function pp = PixelPos( h )
    oldU  = get( h , 'Units' );
    set( h , 'Units' , 'pixels' );
    pp = get( h , 'Position' );
    set( h , 'Units' , oldU );
  end
end
function h = areH( h )
  toRemove = [];
  for i = 1:numel( h )
    if ~ishandle( h(i) )
      toRemove = [ toRemove , i ];
    end
  end
  h( toRemove ) = [];
end

function DE( err )

  if isequal( err.identifier , 'MATLAB:class:InvalidProperty' ) && ...
     isequal( err.message    , 'The name ''PickableParts'' is not an accessible property for an instance of class ''line''.' )
    return;
  end

% error_identifier : MATLAB:class:InvalidProperty
% error_message    : The name 'PickableParts' is not an accessible property for an instance of class 'line'.
% error_cause      : cell(0,1)
% error_type       : {1,'hg.line/set'}

%   disperror( err );
end

%%
%{

  function START_ChangeWindow_old( )
    setLastPoint( NaN(1,3) );
    START_( 'Left<>Right (contrast) - Up<>Down (brightness)' );
    oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'WindowKeyReleaseFcn' , @(h,e)0 , 'Pointer' , 'blockfleurcontrast' );

    originalW = get( HH.Axe , 'CLim' );
    fSP = get(HH.Fig,'CurrentPoint');

    CM = ( uint8( get( HH.Fig , 'ColorMap' ) * 255 ) );
    AxePos = AxePosition( HH.Axe );
    HGS{3} = axes('Parent',HH.Parent,'Units','pixels','Position',[ AxePos(1)+10 , AxePos(2)+40 , 25  , AxePos(4)-80 ],'ApplicationData',struct('DDELAY',1),'Tag','drawContours.auxHandles');
    HGS{4} = image( CM , 'Parent',HGS{3} ,'XData',[-2 2],'YData',originalW , 'ApplicationData',struct('DDELAY',2),'Tag','drawContours.auxHandles');
    set( HGS{3} , 'FontSize',10,'FontWeight','bold','YGrid','on','GridLineStyle','-','XLim',[-1 1],'YLim',originalW,'XTick',[],'YColor',[1,0,1],'XColor',[1,0,1],'YAxisLocation','right','Box','on','LineWidth',1,'YDir','normal','Tag','drawContours.auxHandles');
    
    set( HH.Fig , 'WindowButtonMotionFcn' , @(h,e)MOVING() , 'WindowButtonUpFcn' , @(h,e)STOP_AND_RESTORE_( oldSTATE )  );
    function MOVING( ), try, %#ok<ALIGN>
      fCP = get( HH.Fig , 'CurrentPoint' );
      
      s = exp( ( fCP(1) - fSP(1) ) * 0.01 );
      c = ( fCP(2) - fSP(2) )/500 * ( originalW(2)-originalW(1) )*s;
      
      newW = ( originalW - mean(originalW) )*s + mean( originalW ) + c;

      set( HGS{2} , 'String' , sprintf('ChangeWindow: w = %.2f  c = %.2f', newW(2)-newW(1) , ( newW(2)+newW(1) )/2 ) );
      set( HGS{3} , 'YLim'  , newW );
      set( HGS{4} , 'YData' , newW );
           set( HH.Axe          , 'CLim' , newW );
      try, set( HH.ZoomAxe      , 'CLim' , newW ); end
      try, set( HH.NavigatorAxe , 'CLim' , newW ); end
    catch LE, STOP_AND_RESTORE_( oldSTATE , LE ); end; end
  end
  function RESET_Window_old( anima )
    if nargin && anima
      setLastPoint( NaN(1,3) );
      START_( '                              ' , 'ApplicationData',struct('DDELAY',1.5) );
      oldSTATE = SuspendFigure( HH.Fig , 'WindowKeyPressFcn' , @(h,e)0 , 'WindowKeyReleaseFcn' , @(h,e)0 );
      
      originalW = get( HH.Axe , 'CLim' );

      CM = ( uint8( get( HH.Fig , 'ColorMap' ) * 255 ) );
      AxePos = AxePosition( HH.Axe );
      HGS{3} = axes('Parent',HH.Parent,'Units','pixels','Position',[ AxePos(1)+10 , AxePos(2)+40 , 25  , AxePos(4)-80 ],'ApplicationData',struct('DDELAY',1.5),'Tag','drawContours.auxHandles');
      HGS{4} = image( CM , 'Parent',HGS{3} ,'XData',[-2 2],'YData',originalW , 'ApplicationData',struct('DDELAY',3),'Tag','drawContours.auxHandles');
      set( HGS{3} , 'FontSize',10,'FontWeight','bold','YGrid','on','GridLineStyle','-','XLim',[-1 1],'YLim',originalW,'XTick',[],'YColor',[1,0,1],'XColor',[1,0,1],'YAxisLocation','right','Box','on','LineWidth',1,'YDir','normal','Tag','drawContours.auxHandles');

      for t = linspace( 0 , 1 , 10 )
        newW = originalW + t*( [H.GrayLevel0 , H.GrayLevel1] - originalW );

        set( HGS{2} , 'String' , sprintf('RESET_Window: w= %.2f  c = %.2f', newW(2)-newW(1) , ( newW(2)+newW(1) )/2 ) );
        set( HGS{3} , 'YLim'  , newW );
        set( HGS{4} , 'YData' , newW );
        set( HH.Axe   , 'CLim'  , newW );
        pause(1/10/2);
      end
      
      RestoreFigure( HH.Fig , oldSTATE );
      clearHGS();
      setLastPoint( gCP( )  );
    else
      set( HH.Axe , 'CLim' , [ H.GrayLevel0 , H.GrayLevel1 ] );
    end
    try, set( HH.ZoomAxe      , 'CLim' , get( HH.Axe , 'CLim' ) ); end
    try, set( HH.NavigatorAxe , 'CLim' , get( HH.Axe , 'CLim' ) ); end
  end


%}
