function MontageHeartSlices( HS , hFig , varargin )

    


  if nargin < 2 || isempty( hFig ), hFig = []; end
  
  %{
  [varargin,w3D] = parseargs( varargin , '3d' , '$FORCE$',{true,false} );
  if w3D
    firstSA = [];
    [~,~,firstSA] = parseargs(varargin,'firstSA','$DEFS$',firstSA);
    if isempty( firstSA )
      firstSA = find( cellfun( @(I)isfield(I.INFO,'PlaneName') && strncmp(I.INFO.PlaneName,'SAx',3) , HS(:,1) ) ,1);
    end
    if isempty( firstSA )
      firstSA = 4;
    end
    firstSA = min( firstSA , size( HS ,1) );
    HSS = HS( [ 1:firstSA-1 , size(HS,1):-1:firstSA ] ,1); 
    for r = 1:size(HSS,1)
      try
        B = HSS{r,1}(:,:,:,1);
        if size(B,5) == 1
          B = todouble( B );
          B = B - prctile(B,5);
          B = B / prctile(B,95);
          B = cat(5,B,B,B);
          B = clamp( B , 0 , 1 );
        end
        HSS{r,1} = B;
      end
    end
    
    h3D = figure('Visible','off','Toolbar','none','MenuBar','none','RendererMode','manual','Renderer','OpenGL','NextPlot','add','Color',[1 1 1],'IntegerHandle','off');
    for r = 1:size( HSS ,1)
      imagesc( HSS{r} , 'Tag','3Dslice','UserData',r,'Visible','on');
      
      for s = [ 1:r-1 ]
        L = intersectionLine( HSS{r} , HSS{s} );
        if isempty(L),continue;end
        
        line('XData',L(:,1),'YData',L(:,2),'ZData',L(:,3),'Color',[1 1 0],'LineWidth',2,'LineStyle','-','Marker','o','Tag','3Dline','UserData',[r s],'Visible','off');
      end
    end
    view(3);
    axis( objbounds(gca) );
    set(gca,'DataAspectRatio',[1 1 1])

    
    MontageHeartSlices( HS , hFig , varargin{:} , 'FCN', @(r,xr,s,xs)with3D(h3D,r,xr,s,xs) );
    P = get(gcf,'Position');
    set( h3D , 'Position',[ P(1)+P(3) , P(2) , 400 , 400 ],'Visible','on' );
    return;
  end

  
  function with3D( h3D , r , xr , s , xs )
    SLICES = findall( h3D , 'Tag' , '3Dslice' );
    LINES  = findall( h3D , 'Tag' , '3Dline'  );

    set( SLICES , 'Visible','off');
    set( LINES  , 'Visible','off' );
    
    if ~isempty(r)
      set( SLICES( r == cell2mat( get( SLICES , 'UserData' ) ) ) , 'Visible','on','FaceAlpha',1);
      r
    end
    if ~isempty(s)
      set( SLICES( s == cell2mat( get( SLICES , 'UserData' ) ) ) , 'Visible','on','FaceAlpha',0.5);
    end
    if ~isempty(r) && ~isempty(s)
      rs = cell2mat( get( LINES , 'UserData' ) );
      set( LINES( all( ( rs == r ) | ( rs == s ) , 2 ) ) , 'Visible','on' );
    end
  end
  %}

  
  try
      VERTICAL_FLIP_IN_MONTAGES = [];
      mppOption VERTICAL_FLIP_IN_MONTAGES  false
      VERTICAL_FLIP = VERTICAL_FLIP_IN_MONTAGES;
  catch
      VERTICAL_FLIP = false;
  end
  [varargin,VERTICAL_FLIP] = parseargs(varargin,'VerticalFlip','$FORCE$',{true,VERTICAL_FLIP});

  
  [varargin,~,FCN] = parseargs(varargin,'fcn','$DEFS$',[]);
  VISIBLE = false;
  [varargin,VISIBLE] = parseargs(varargin,'visible','$FORCE$',{true,VISIBLE});
  VISIBLE = onoff( VISIBLE );
  
  
  CColors = [0.2 0.2 1;
             1 0 0;
             0 1 0;
             1 1 0;
             1 0 1;
             1 .5 0;
             0 1 1;
             1 .5 1];
  CColors = [1 0 0;
             0 1 0;
             0 0 1;
             1 1 0;
             1 0 1;
             1 .5 0;
             0 .5 1;
             .5 .5 1;
             1 .5 0;
             0  1 1;
             0 .5 0;
             0 1 1;
             ];

  if isempty( hFig )
    hFig = figure('Position',[1,50,ceil([1080,810]*1)],'Toolbar','none','MenuBar','none','Visible',VISIBLE,'RendererMode','manual','Renderer','OpenGL','NextPlot','add','Color',[1 1 1]*0.5);
%     if ~system_dependent('useJava','Desktop')
%       pos = get( hFig , 'Position' );
%       pos(3:4) = ceil([1080,810]*2);
%       pos(1) = - pos(3) - 20;
%       set( hFig , 'Position' , pos );
%     end
    HOLD = false;
  else
    HOLD = true;
  end
  
  FirstSA = firstSA( HS ); if isempty( FirstSA ), FirstSA = 4; end
  try, [varargin,~,FirstSA] = parseargs(varargin,'firstSA','$DEFS$',FirstSA); end
  FirstSA = min( FirstSA , size( HS ,1) );

  
  for r = 1:size(HS,1)
    if isempty( HS{r,1} ), continue; end
    HS{r,1}.INFO.rowID = r;
    try, HS{r,1}.INFO = mergestruct( HS{r,1}.INFO , HS{r,1}.INFO.DICOM_INFO ); end
  end
  
  
  HS = HS( [ 1:FirstSA-1 , size(HS,1):-1:FirstSA ] ,:);
  for r = 1:size(HS,1)
    if isempty( HS{r,1} ), continue; end
    IS{r,1} = todouble( HS{r,1}(:,:,:,1,1) );
    try
      w = IS{r,1}.FIELDS.Hmask;
      w = expand(w,size(IS{r,1}));
      IS{r,1}.data(~w) = NaN;
      IS{r,1} = crop( IS{r,1} , 0 , 'mask' , isfinite( IS{r,1}.data ) );
    end
    %if ~HOLD
      B = HS{r,1}(:,:,:,1);
      if size(B,5) == 1
        B = todouble( B );
        
        
        try
          B = B - B.INFO.GrayLevel0;
          B = B / B.INFO.GrayLevel1;
        catch
          B = B - prctile(B(:), 5);
          B = B / prctile(B(:),95);
        end
        
        B = clamp( B , 0 , 1 );
        B = cat(5,B,B,B);

        try
          w = expand( ~HS{r,1}.FIELDS.Hmask , size(B) );
          B.data( w ) = 0.6 + ( B.data( w ) - 0.5 )*0.2;
          w(:,:,:,:,1) = false;
          B.data( w ) = B.data( w ) + 0.075;
        end

      end
      HS{r,1} = B.centerGrid;
    %end
  end

  
  AXs = safeflip( findall( hFig , 'Type','axes','Tag','sliceAxe') ,1);
  if ~HOLD
    switch size(HS,1)
      case 1, montage_size = [1,1];
      case 2, montage_size = [1,2];
      case 3, montage_size = [1,3];
      case 4, montage_size = [2,2];
      otherwise
        montage_size = [2,3];
        for i=1:10, if prod( montage_size ) < size(HS,1), montage_size( rem(i,2)+1 ) = montage_size( rem(i,2)+1 )+1; end; end
    end    
    
    sep = 0.00000;
    AXs = axesArray( montage_size , 'L',sep,'R',sep,'T',sep,'B',sep,'H',sep,'V',sep).';
    set( AXs ,'Tag','sliceAxe','XTick',[],'YTick',[],'ZTick',[],...
              'Box','on','LineWidth',2,'Layer','top','Visible','off','ZLim',[-1,1],'Color',[1 1 1]*0.6);
    try,set( AXs(1)           , 'XColor','r','YColor','r','ZColor','r');end
    try,set( AXs(2)           , 'XColor','g','YColor','g','ZColor','g');end
    try,set( AXs(3)           , 'XColor','c','YColor','c','ZColor','c');end
    try,set( AXs(4:FirstSA-1) , 'XColor','w','YColor','w','ZColor','w');end
    try,set( AXs(FirstSA:end) , 'XColor','y','YColor','y','ZColor','y');end
    C = NaN( size(HS,1),2);
    D = NaN( size(HS,1),2);
  end

  a = 0; DATEdone = false;
  for r = 1:size(HS,1), 
    a = a+1; set( hFig , 'CurrentAxes' , AXs(a) );
    if isempty( HS{r,1} ), continue; end
    try
    set( AXs(a) ,'NextPlot','add' );
    if HOLD, delete( findall( AXs(a) , 'Type','line' ) ); drawnow; end

    if VERTICAL_FLIP
        set( AXs(a) , 'YDir' , 'reverse' );
    end
    
%     [~,iZ] = getPlane( HS{r,1} , 'z+' , 'y+' ); %%%%%%%%%%%%%%%%%%%
%     if isfield( HS{r,1}.INFO , 'UpVector' )
%       UpVector = HS{r,1}.INFO.UpVector;
%     elseif r < FirstSA
%       UpVector = HS{FirstSA,1}.SpatialTransform(1:3,3);
%     else
% %       UpVector = HS{1,1}.SpatialTransform(1:3,3);
% %       if UpVector(2)<0, UpVector = -UpVector; end
%       UpVector = [];
%     end
%     if ~isempty( UpVector )
%       UpVector = iZ(1:3,1:3) * UpVector(:);
%       iZ = maketransform( iZ , 'rz' , -atan2d( UpVector(2) , UpVector(1) ) + 90 );
%     end

    iZ = minv( HS{r,1}.SpatialTransform );

    B = HS{r,1}(:,:,:,1);
    
    if ~HOLD
      imagesc( transform( B , iZ ) ,'Tag','I3D','UserData',iZ);
    else
      set( findall(gca,'Tag','I3D') , 'UserData',iZ);
      
      Sdata = double( permute( B.data , [1 2 5 3 4] ) );
      if isequal( size(Sdata) , size( get( findall(gca,'Tag','I3D') ,'CData' ) ) )
        set( findall(gca,'Tag','I3D') , 'CData' , Sdata ,'UserData',iZ);
      end
    end
    for s = [ 1:r-1 , r+1:size(HS,1) ]
      if isempty( HS{s,1} ), continue; end
      if ipd( HS{r,1}.SpatialTransform(1:3,3).' , HS{s,1}.SpatialTransform(1:3,3).' , 'normal') < 1e-4, continue; end
      
      try
        IL3d = intersectionLine( HS{min(r,s),1} , HS{max(r,s),1} );
        if isempty(IL3d),continue;end
        
        IL3d = bsxfun( @plus , IL3d(1,:) , ( 0:0.1:floor(fro( IL3d(end,:)-IL3d(1,:) )) ).' * ( IL3d(end,:)-IL3d(1,:) )/fro( IL3d(end,:)-IL3d(1,:) ) );
        
        IL = transform( IL3d , iZ , 'tz',0.1 );
        hS = plot3d( IL([1,end],:) , ':' ,'XLimInclude','off','YLimInclude','off','ZLimInclude','off','Tag','IL','UserData',s);
%         if     s == 1,      set(hS,'Color','r');
%         elseif s == 2,      set(hS,'Color','g');
%         elseif s < firstSA, set(hS,'Color','c');
%         else,               set(hS,'Color','y');
%         end
        set(hS,'Color',get(AXs(s),'XColor'));
        
        ev = 5;
        vert    = IL(1:ev:end,:); vert(:,3) = 0.4;
        cdata   = permute(at( HS{s,1}(:,:,:,1) , IL3d(1:ev:end,:) , 'closest' ),[1 3 2]);
        try
          w = ~~at( HS{s,1}.F.Hmask , IL3d(1:ev:end,:) , 'closest' );
          cdata = cdata(w,:,:);
          vert  = vert(w,:);
        end
        
        [~,ord] = sort( cdata(:,:,1) , 'descend');
        vert  = vert(  ord ,:,:);
        cdata = cdata( ord ,:,:);
        
        hCLINE = patch('Vertices',vert,'Faces',(1:size(vert,1)).','Marker','o','MarkerSize',7,...
          'MarkerFaceColor','flat','EdgeColor','none',...
          'CData', cdata ,'Visible','off','Tag','CLINE','Clipping','on');
        
        set( hS , 'ApplicationData', struct(...
          'il3d'      , IL3d([1 end],:)       ,...
          'r'         , r                     ,...
          's'         , s                     ,...
          'r_values'  , IS{r}(IL3d,'closest') ,...
          's_values'  , IS{s}(IL3d,'closest') ,...
          'cline'     , hCLINE                 ...
        ) );
        set( hS , 'ButtonDownFcn' , @(h,e)showProfiles(h) );
      end
    end

    try
      L = transform( HS(r,2:end) , iZ );
      
      for l = find( ~cellfun('isempty',L) )
        if max( abs(L{l}(:,3)) ) > 1e-5
          warning('Contour (%d,%d) doesn''t lie on the image plane.',r,l+1);
        end
        L{l}(:,3) = 0.1;
        if l >= 10
          L{l}(:,3) = 0.05;  end
        hLine = plotC( L{l} , 'Color',CColors(min(l,end),:),'LineWidth',2,'Hittest','off');
        if l >= 10
          set( hLine , 'LineWidth',1,'Marker','none');
          children = get(get(hLine(1),'Parent'),'Children');
          children( ismember( children , hLine ) ) = [];
          children = [ children ; hLine ];
          set(get(hLine(1),'Parent'),'Children',children);
        end
      end
    end
    
    try
      L = {};
      for s = [ 1:r-1 , r+1:size(HS,1) ], try
        if ipd( HS{r,1}.SpatialTransform(1:3,3).' , HS{s,1}.SpatialTransform(1:3,3).' , 'normal') < 1e-4, continue; end
        for c = 1:min(9,size(HS,2)), try
          L{s,c} = transform( meshSlice( HS{s,c+1} , HS{r,1} ) , iZ );
        end; end
      end; end
      
      for c = find( any( ~cellfun('isempty',L) ,1) )
        LL = vertcat( L{:,c} );
        LL(:,3) = 0.15;
        plot3d( LL  , 'o' ,'linestyle','none' , 'LineWidth',1,'Color','k','MarkerFaceColor',CColors(min(c,end),:),'MarkerSize',5,'Hittest','off');
      end
    end
    if strcmp(get(hFig,'Visible'),'on'); drawnow; end

    if ~HOLD
      SN = '';
      if isempty( SN )
        try
          SN = DICOMxinfo( B.INFO , 'SeriesNumber' );
          if isnumeric( SN ), SN = sprintf('%d',SN); end
          SN = [ '.SN' , SN ];
        end
      end
      
      PH = [];
      if isempty( PH )
        PH = DICOMxinfo( B.INFO , 'xPhase' );
      end
      if isequal( PH , -1)
        PH = '';
      elseif numel( PH ) == 1
        PH = sprintf(' [%d]', PH );
      else
        PH = sprintf(' [%d of %d]', PH(1:2) );
      end

      
      SN = sprintf('%d.%s%s', B.INFO.rowID , SN , PH );
      if r >= FirstSA, try, SN = [ SN , sprintf('(%0.1f)' , DICOMxinfo( B.INFO , 'xZLevel' ) ) ]; end; end
      hT = text( 0 , 0 , 0.2 , SN , 'HorizontalAlignment','left','VerticalAlignment','top','BackgroundColor',[1 1 0]*1,'Color','r','Margin',4,'FontWeight','bold','EdgeColor','k','Tag','SN','BackgroundColor',get(AXs(a),'XColor'));

      
      if isequal( get( hT ,'Color') , get( hT , 'BackgroundColor' ) )
        set( hT , 'Color' , 1 - get( hT , 'BackgroundColor' ) );
      end

      DATE = '';
      try,   DATE = datestr( DICOMxinfo( HS{r,1}.INFO,'xDatenum') ,'HH:MM:SS'); end
      if ~isempty( DATE )
        if ~DATEdone
          try
            DATE = datestr( DICOMxinfo( HS{r,1}.INFO,'xDatenum') ,'HH:MM:SS  (dd/mm/yy)');
            DATEdone = true;
          end
        end
        hD = text( 0 , 0 , 0.2 , DATE , 'HorizontalAlignment','left','VerticalAlignment','bottom','BackgroundColor',[1 1 1]*0.8,'Color','r','Margin',3,'FontWeight','bold','EdgeColor','none','Tag','DATE');
      end

      
      ha = handle(AXs(a));
      try
        hl(1) = handle.listener( ha , findprop(ha,'XLim') , 'PropertyPostSet' , @(h,e)UpdateAxesLims(AXs(a)) );
        hl(2) = handle.listener( ha , findprop(ha,'YLim') , 'PropertyPostSet' , @(h,e)UpdateAxesLims(AXs(a)) );
      catch
          hl(1) = event.proplistener( ha , findprop(ha,'XLim') , 'PostSet' , @(h,e)UpdateAxesLims(AXs(a)) );
          hl(2) = event.proplistener( ha , findprop(ha,'YLim') , 'PostSet' , @(h,e)UpdateAxesLims(AXs(a)) );
          %hl(3) = event.listener( get(ha,'XRuler') ,'MarkedClean',@(h,e)UpdateAxesLims(AXs(a)) );
          %hl(4) = event.listener( get(ha,'YRuler') ,'MarkedClean',@(h,e)UpdateAxesLims(AXs(a)) );
      end
      setappdata( AXs(a) ,'Listener',hl );

      
      
      LIMS = []; D(a,1:2) = 0;
      if isempty( LIMS ), try, LIMS = reshape( objbounds( findall( AXs( a )   , 'Type','line' ) )    , [2,3] ).'; end; end
      if isempty( LIMS )

        LIMS = {};
        for l = findall( AXs(a) , 'Type' , 'line' , 'Tag' , 'IL' ).'
          LIMS{end+1,1} = [ vec( get( l , 'XData' ) ) , vec( get( l , 'YData' ) ) ];
        end
        LIMS = CentralPoint( LIMS );
        LIMS = [ LIMS(1) + 80*[-1,1] ;
                 LIMS(2) + 80*[-1,1] ;
                 0 0];
        D(a,:) = NaN;
      end
      if isempty( LIMS ), try, LIMS = reshape( objbounds( findall( AXs( a )   , 'Type','surface' ) ) , [2,3] ).'; end; end
      if isempty( LIMS ), LIMS = [ NaN NaN ]; end

      C(a,:) = mean( LIMS(1:2,:) , 2 ).';
      D(a,:) = D(a,:) + abs( diff(LIMS(1:2,:),1,2) ).';
    end
    
  end; end
  delete( AXs(a+1:end) ); AXs(a+1:end) = [];

  if ~HOLD
    for w = 1:FirstSA-1
      if ~isfinite( D(w,1) ), D(w,:) = 160; end
    end
    w = 1:FirstSA-1;
    D(w,1) = max( D(w,1) );     D(w,2) = max( D(w,2) );

    
    w = FirstSA:size(D,1);
    if all( ~isfinite( D(w,:) ) ), D(w,:) = 160; end
    
    D = max( D , 100 );
    
    
    D = D * 1.05/2;
    
    
    D(1:FirstSA-1,:) = min( D(1:FirstSA-1,:) , 160 );
    
    XLIM = [ C(:,1) - D(:,1) , C(:,1) + D(:,1) ];
    XLIM( FirstSA:end ,1 ) = min( XLIM( FirstSA:end ,1) );
    XLIM( FirstSA:end ,2 ) = max( XLIM( FirstSA:end ,2) );
    
    YLIM = [ C(:,2) - D(:,2) , C(:,2) + D(:,2) ];
    YLIM( FirstSA:end ,1 ) = min( YLIM( FirstSA:end ,1) );
    YLIM( FirstSA:end ,2 ) = max( YLIM( FirstSA:end ,2) );
    
    
    for r = 1:a, setappdata( AXs(r) , 'LIMS' , [ XLIM(r,:) , YLIM(r,:) ] ); end
    
    set( hFig , 'ResizeFcn' , @(h,e)redrawAXs(AXs) )
  end    
  redrawAXs(AXs);
  set( hFig , 'Visible' ,'on' );
  drawnow;

  if 0, return; end
  
  if ~HOLD
    hPanel = hFig;
    pos = get(hFig,'Position');
    try
      error('1');
      hPanel = uimpanel( 'Parent',hFig ,...
                'VisibilityControl','on' ,...
                'ShowTitleBar','off',...
                'MinimumSize' , [200 150] ,...
                'units','pixel' ,...
                'Position', [ pos(3)-400-1 , 1 , 400 300 ] ,...
                'Rollable','off' ,...
                'Moveable','on' ,...
                'Title',' ' ,...
                'LeftResizeControl' ,'on' ,...
                'RightResizeControl','off' ,...
                'ConstrainedToParent','on' ,...
                'UnDockControl' , 'off' ,...
                'Tag','profilesPanel');
    catch
      hPanel = uipanel( 'Parent',hFig ,...
                'Units','Normalized' ,...
                'Position',[0.7 0 0.3 0.3] ,...
                'Title','' , 'Tag','profilesPanel' );
    end
    
    hAr = axes('Parent',hPanel, 'Position',[0.02 , 0.50 , 0.96 , 0.49 ],'Box','off','XTick',[],'YTick',[],'ZTick',[],'LineWidth',1,'XColor',[1,1,1]*0.9,'YColor',[1,1,1]*0.9,'Visible','on','Xlim',[-0.02,1.02],'Color',[1 1 1]*0.9,'Layer','bottom','Tag','profileRAxe','XAxisLocation','top');
    hAs = axes('Parent',hPanel, 'Position',[0.02 , 0.01 , 0.96 , 0.49 ],'Box','off','XTick',[],'YTick',[],'ZTick',[],'LineWidth',1,'XColor',[1,1,1]*0.9,'YColor',[1,1,1]*0.9,'Visible','on','Xlim',[-0.02,1.02],'Color',[1 1 1]*0.9,'Layer','bottom','Tag','profileSAxe','XAxisLocation','bottom');
    drawnow;

    hlink = linkprop( [hAr;hAs] ,{'xlim'});
    setappdata( hAr ,'graphics_linkprop' , hlink );

    set( findall(hFig,'Tag','I3D') , 'ButtonDownFcn' , @(h,e)clickOnImage() );
  else
    hPanel = findall( hFig , 'Tag','profilesPanel');
    hAr    = findall( hFig , 'Tag','profileRAxe');
    hAs    = findall( hFig , 'Tag','profileSAxe');
  end
  hideProfile();
  
  
  ILs    = findall(hFig,'Type','line' ,'Tag','IL'   );
  CLINEs = findall(hFig,'Type','patch','Tag','CLINE');

  set( hFig , 'WindowKeyPressFcn' , @(h,e)MovingMouse() );
  set( hFig , 'WindowKeyReleaseFcn' , @(h,e)MovingMouse() );
  set( hFig , 'WindowButtonMotionFcn' , @(h,e)MovingMouse() );
  set( hFig , 'WindowScrollWheelFcn'  , @(h,e)ScrollingMouse(e) );


  function hideProfile()
    try
    delete(findall(gcf,'Tag','MarkerR'));
    delete(findall(gcf,'Tag','MarkerS'));

    delete( get(hAr ,'Children') );
    delete( get(hAs,'Children') );
    set( findall(hPanel) , 'Visible','off');
    end

  end
  function clickOnImage()
    pk = pressedkeys(3);
    if pk == 1
      hideProfile();
    elseif pk == 2
      hA = gca;
      oldWindowButtonMotionFcn = get( hFig , 'WindowButtonMotionFcn' );
      set( hFig , 'WindowButtonUpFcn'     , @(h,e)STOP() );
      SP = mean( get(hA,'CurrentPoint'), 1);
      set( hFig , 'WindowButtonMotionFcn' , @(h,e)PAN() );
    elseif pk == 4
      limits= [ get(gca,'XLim') , get(gca,'YLim') ];
      WorldPoint = mean( get( gca ,'CurrentPoint' ) ,1);
      hF = gcf;
      oldWindowButtonMotionFcn = get( hFig , 'WindowButtonMotionFcn' );
      set( hFig , 'WindowButtonUpFcn'     , @(h,e)STOP() );
      FP = get(hF,'CurrentPoint');
      set( hFig , 'WindowButtonMotionFcn' , @(h,e)ZOOM() );
    end
    
    

    function PAN()
%       if ~isequal( hA , ancestor( hittest() , 'axes' ) ), STOP(); end
      CP = mean( get( hA, 'CurrentPoint') , 1);
      xl = get(hA,'XLim'); xl = xl + ( SP(1) - CP(1) );
      yl = get(hA,'YLim'); yl = yl + ( SP(2) - CP(2) );
      set( hA ,'XLim',xl ,'YLim',yl );
    end
    function ZOOM()
      CP = get(hF,'CurrentPoint');
      d  = CP(1) - FP(1);
      d = exp(-d/50); %d = round(d*100)/100;

      xl = limits(1:2); xl = ( xl - WorldPoint(1) )*d + WorldPoint(1);
      yl = limits(3:4); yl = ( yl - WorldPoint(2) )*d + WorldPoint(2);
      
      set( hA ,'XLim',xl ,'YLim',yl );
    end
    function STOP()
      set(hFig,'WindowButtonMotionFcn',oldWindowButtonMotionFcn);
    end
    
  end
  function showProfiles(hR)
    delete( get(hAr,'Children') );
    delete( get(hAs,'Children') );
    delete(findall(hFig,'Tag','MarkerR'));
    delete(findall(hFig,'Tag','MarkerS'));

    
    IL = get(hR,'ApplicationData');
    hS = findall( AXs( IL.s ) , 'UserData' , IL.r );

    hA = ancestor( hR , 'axes' );
    cp = [1 0] * get( hA , 'CurrentPoint' ); cp = cp(1:2);
    
    
    XYR = [ get(hR,'XData').' , get(hR,'YData').' ];
    t  = ( cp - XYR(1,:) ) * ( XYR(end,:) - XYR(1,:) ).' / fro2( XYR(end,:) - XYR(1,:) );
    P  = XYR(1,:) + t*( XYR(end,:) - XYR(1,:) );
    
    line( P(1) , P(2) , 0.2 , 'Parent',AXs(IL.r),...
      'LineWidth',2,'MarkerSize',12,'LineStyle','none',...
      'marker','+','Color',[0,0.5,1],'Tag','MarkerR','Hittest','off','Clip','on');

    XYS = [ get(hS,'XData').' , get(hS,'YData').' ];
    P  = XYS(1,:) + t*( XYS(end,:) - XYS(1,:) );
    line( P(1) , P(2) , 0.2 , 'Parent',AXs(IL.s),...
      'LineWidth',2,'MarkerSize',12,'LineStyle','none',...
      'marker','+','Color',[1,0.5,0],'Tag','MarkerS','Hittest','off','Clip','on');

    %%
    set( findall(hPanel) ,'Visible','on');
    set( hAr , 'UserData' , IL.r  );
    set( hAs , 'UserData' , IL.s );

    vline( t , 'Parent',hAr ,'Hittest','off','Tag','vline','color',[0,0.5,1]);
    vline( t , 'Parent',hAs ,'Hittest','off','Tag','vline','color',[1,0.5,0]);
    
    x = linspace(0,1,numel(IL.r_values));

    yl = [ min( [ 0 , min(IL.r_values ) , min(IL.s_values ) ] ) , max( [ max(IL.r_values ) , max(IL.s_values ) ] ) ];
%     yl = centerscale( yl , 1.2 );
    
%     yl = [0.6 1.4];
    
%   image( 'CData',permute( IL.r_rgb , [3 1 2] ) , 'XData',x,'Parent',hAr,'ydata',yl);
    image( 'CData', repmat( clamp( IL.r_values.'/max( IL.r_values ) ,0,1) , [1 1 3] ) , 'XData',x,'Parent',hAr,'ydata',yl(1) + diff(yl)/10 * ( [1,2]/3 - 1 ) );
    line( x , IL.s_values , x*0+0.1 , 'Color',[1,0.5,0] ,'Parent',hAr ,'Hittest','off','LineWidth',1);
    line( x , IL.r_values , x*0+1   , 'Color',[0,0.5,1] ,'Parent',hAr ,'Hittest','off','LineWidth',2);
    set( hAr  , 'YLim' , yl + diff(yl)*[-0.1,0.025] );
    for c = 2:size(HS,2)
      %L = SliceMesh( HS{r,c} ,  HS{s,1} );
      L = [];
      try, L = meshSlice( HS{r,c} , getPlane( HS{s,1} ) ); end
      for p = 1:size(L,1)
        t = ( L(p,:) - IL.il3d(1,:) ) * ( IL.il3d(end,:) - IL.il3d(1,:) ).' / fro2( IL.il3d(end,:) - IL.il3d(1,:) );
        vline( t , 'Color',CColors(min(c-1,end),:),'Parent',hAr ,'Hittest','off','LineStyle','-');
      end
    end
    
%   image( 'CData',permute( IL.s_rgb , [3 1 2] ) , 'XData',x,'Parent',hAs,'ydata',yl);
    image( 'CData', repmat( clamp( IL.s_values.'/max( IL.r_values ) ,0,1) , [1 1 3] ) , 'XData',x,'Parent',hAs,'ydata',yl(2) + diff(yl)/10 * ( [1,2]/3 ) );
    line( x , IL.r_values , x*0+0.1 ,'Color',[0,0.5,1] ,'Parent',hAs,'Hittest','off','LineWidth',1);
    line( x , IL.s_values , x*0+1   ,'Color',[1,0.5,0] ,'Parent',hAs,'Hittest','off','LineWidth',2); set( hAs , 'YLim' , yl );
    set( hAs  , 'YLim' , yl + diff(yl)*[-0.025,0.1]);
    for c = 2:size(HS,2)
      L = [];
      try, L = meshSlice( HS{s,c} , getPlane( HS{r,1} ) ); end
      for p = 1:size(L,1)
        t = ( L(p,:) - IL.il3d(1,:) ) * ( IL.il3d(end,:) - IL.il3d(1,:) ).' / fro2( IL.il3d(end,:) - IL.il3d(1,:) );
        vline( t , 'Color',CColors(min(c-1,end),:),'Parent',hAs,'Hittest','off','LineStyle','-');
      end
    end

    oldWindowButtonMotionFcn = get( hFig , 'WindowButtonMotionFcn' );
    set( hFig , 'WindowButtonUpFcn'     , @(h,e)STOP() );
    set( hFig , 'WindowButtonMotionFcn' , @(h,e)DRAG() );

    function DRAG()
      if ~isequal( hA , ancestor( hittest() , 'axes' ) ), STOP(); end
      
      cp = [1 0] * get( hA , 'CurrentPoint' ); cp = cp(1:2);
      t  = ( cp - XYR(1,:) ) * ( XYR(end,:) - XYR(1,:) ).' / fro2( XYR(end,:) - XYR(1,:) );
      updateMARKERS(t);
    end
    function STOP()
      set(hFig,'WindowButtonMotionFcn',oldWindowButtonMotionFcn);
    end
  end
  function ScrollingMouse(e)
    h  = hittest();
    hA = ancestor( h ,'axes');

    if isequal( hA , hAr ) || isequal( hA , hAs )
      xl = get( hA , 'XLim' );
      
      cp = get(hA,'CurrentPoint'); t = cp(1);
      
      switch sign( e.VerticalScrollCount )
        case  1, xl = ( xl - t )*1.2 + t;
        case -1, xl = ( xl - t )/1.1 + t;
      end
      xl = clamp( xl , -0.02 , 1.02 );
      
      set( [hAr,hAs] , 'XLim',xl);
    else
      
      xl = get( hA , 'XLim' );
      yl = get( hA , 'YLim' );
      
      cp = get(hA,'CurrentPoint');
      cp = cp(1,:);
      
      switch sign( e.VerticalScrollCount )
        case  1
          xl = ( xl - cp(1) )*1.2 + cp(1);
          yl = ( yl - cp(2) )*1.2 + cp(2);
        case -1
          xl = ( xl - cp(1) )/1.1 + cp(1);
          yl = ( yl - cp(2) )/1.1 + cp(2);
      end
      
      set( hA  , 'XLim',xl , 'YLim',yl );
    end
  end
  function MovingMouse()
    try,
    set( ILs , 'LineWidth',1,'LineStyle',':');
    set( CLINEs , 'Visible','off');
    set( AXs , 'Visible','off');

    h  = hittest();
    hA = ancestor( h ,'axes');

    if isequal( hA , hAr ) || isequal( hA , hAs )
      r = get( hAr , 'UserData' );
      s = get( hAs , 'UserData' );

      set( AXs([r,s]) , 'Visible','on');

      cp = get(hA,'CurrentPoint'); t = cp(1);
      updateMARKERS(t);
    else
      r = []; s = [];
      if strcmp( get(h,'Tag') , 'IL' );
        set( h , 'LineWidth',2,'LineStyle','--');
        s = get(h,'UserData');
        set( AXs( s ) , 'Visible','on');
      end
      
        
      if ~isempty( hA )
        r = find( AXs == hA );
        hh = findall(hFig,'Type','Line','Tag','IL','UserData',r);
        set( hh , 'LineWidth',2,'LineStyle','--');
      end

      pk = pressedkeys;
      if numel(pk) == 1 && isequal( pk{1} , 'LSHIFT')
        set( getappdata( h , 'cline' ) , 'Visible','on' );
        arrayfun(@(hh)set( getappdata( hh , 'cline' ) , 'Visible','on' ) ,hh)
      elseif numel(pk) == 1 && isequal( pk{1} , 'LCONTROL')
        set( findall(hA,'Tag','CLINE') , 'Visible','on' );
      end
      
      try, FCN( r , [] , s , [] ); end
    end
    end
  end
  function updateMARKERS(t)
    r  = get( hAr  , 'UserData' );
    s = get( hAs , 'UserData' );

    hR  = findall( AXs( r  ) , 'UserData' , s );
    hS = findall( AXs( s ) , 'UserData' , r  );
    
    set( findall( hAr  ,'Tag','vline' ) , 'XData' , [1;1;1]*t );
    set( findall( hAs ,'Tag','vline' ) , 'XData' , [1;1;1]*t );

    XY = [ get(hR,'XData').' , get(hR,'YData').' ];
    P  = XY(1,:) + t*( XY(end,:) - XY(1,:) );
    set( findall(hFig,'Tag','MarkerR') ,'XData',P(1),'YData',P(2));
    
    XY = [ get(hS,'XData').' , get(hS,'YData').' ];
    P  = XY(1,:) + t*( XY(end,:) - XY(1,:) );
    set( findall(hFig,'Tag','MarkerS') ,'XData',P(1),'YData',P(2));
  end
end


function redrawAXs(AXs)
  AXs = AXs(:);
  AXs( ~ishandle( AXs ) ) = [];
  if isempty( AXs )
    AXs = safeflip( findall( gcf , 'Type','axes','Tag','sliceAxe') ,1);
  end
  for a = AXs(:).'
    LIMS = getappdata( a , 'LIMS' );
    try, set( a , 'XLim', LIMS(1:2) , 'YLim', LIMS(3:4)+[-5,5] ,'ZLim',[-1 1] ); end
    set( a , 'DataAspectRatio',[1 1 1]);
    OPZ_SetView(a,'warptofill')
  end
end

function h = plotC( C , varargin )
  if ~iscell( C ), C = Contour2Segments( C ); end
  h = plot3d( C , varargin{:} );
  color = get( h , 'Color' );
  try, varargin = getLinespec( varargin ); end
  for s = 1:numel(C)
    c = color;
    if numel(C) > 1, c = ( c + rand(1,3) )/2; end
    
    xy = C{s}; xy(:,end+1:3) = 0; xy(:,3) = xy(:,3)+0.2;

%     x = xy(end,:);
%     line( x(1) , x(2) , x(3) , varargin{:} , 'LineStyle','none','Marker','d','MarkerSize',18,'MarkerFaceColor','none','Color',c,'LineWidth',2);

%     if numel(C) > 1
%       ArcLength = [ 0 ; cumsum( sqrt( sum( diff(xy,1,1).^2 ,2) ) ) ];
%       x = Interp1D( xy , ArcLength , ArcLength(end)/5 );
%       line( x(1) , x(2) , x(3) , varargin{:} , 'LineStyle','none','Marker','o','MarkerSize',10,'MarkerFaceColor',c,'Color',color,'LineWidth',1);
%       text( x(1) , x(2) , x(3) , sprintf('%d',s) , 'HorizontalAlignment','center','VerticalAlignment','middle','fontsize',7,'Color',1-c,'FontWeight','bold');
%     end


    if 0 && numel(C{s}) > 1  && ~isequal( get(h(1),'Color') , [0,0.85,0.85])

      ArcLength = [ 0 ; cumsum( sqrt( sum( diff(xy,1,1).^2 ,2) ) ) ];

      for v = 1.5:.5:10
        x = Interp1D( xy , ArcLength , [ ArcLength( ArcLength < ArcLength(end)/(4*v) ) ; ArcLength(end)/(4*v) ] );
        h(end+1,1) = hplot3d( x , varargin{:} ,'LineWidth', round( v*get(h(1),'LineWidth') ) );
      end
      
    else
      
      h(end+1,1) = line( xy(1,1) , xy(1,2) , xy(1,3) , varargin{:} , 'LineStyle','none','Marker','x','MarkerSize',8,'MarkerFaceColor',c,'Color',color,'LineWidth',2);
    
    end


  end
end
function h = vline( x , varargin )
  h = line(0,0,'xliminclude','on','yliminclude','off','color',0.7*[1 1 1],'linestyle','--',varargin{:});

  set( h , 'ydata' , vec( [-1e10;1e10;NaN]*ones(1,numel(x)) ) ,...
           'zdata' , vec( [    1;   1;  1]                  )*0.001 ,...
           'xdata' , vec( [    1;   1;  1]* x(:).'          ) );

  ch = get( get(h,'Parent') , 'Children' );
  ch = ch(:);
  ch = [ h ; setdiff( ch , h ) ];
  set( get(h,'Parent') , 'Children' , ch );
end


function x = safeflip( x , d )
  try,   x = flip(x,d);
  catch, x = flipdim(x,d);
  end
end

function UpdateAxesLims(h)
  xl = get( h , 'XLim' );
  xl = xl + [1,-1]*diff(xl)*2/100;

  yl = get( h , 'YLim' );
  yl = yl + [1,-1]*diff(yl)*2/100;
  
  SN   = findall( h , 'Type','text' , 'Tag' , 'SN');
  if ~isempty( SN )
      if strcmp( get( h , 'YDir' ) , 'normal' )
          set( SN ,'Position',[ xl(1) , yl(2) , 0.2 ] );
      else
          set( SN ,'Position',[ xl(1) , yl(1) , 0.2 ] );
      end
  end
  
  DATE = findall( h , 'Type','text' , 'Tag' , 'DATE');
  if ~isempty( DATE )
      if strcmp( get( h , 'YDir' ) , 'normal' )
          set( DATE ,'Position',[ xl(1) , yl(1) , 0.2 ] );
      else
          set( DATE ,'Position',[ xl(1) , yl(2) , 0.2 ] );
      end
  end
end
