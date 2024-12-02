function [hg_,I,J,K] = image3( V , varargin )

  if nargin < 1
    close all; clc;
    V = rand(10,20,30,1);
    A = maketransform('rz',20);
    figure; image3( V , 'r',A , 'facemode','interp' ,'st',10 );
%     figure; image3( V , 'r',R , 'facemode','flat'    ,'st',10 );
%     figure; image3( V , 'r',R , 'facemode','interp'  ,'st',10 );
    return;
  end


  
  if isstruct( V )
    A = [];
    if      isfield( V , 'SpatialTransform' )
      A = V.SpatialTransform;
    elseif  isfield( V , 'R' )
      A = V.R;
    elseif  isfield( V , 'TransformMatrix' )
      A = V.TransformMatrix;
      if isfield( V , 'origin' )
        A = [ A , V.origin(:) ; 0 0 0 1 ];
      else
        A(4,4) = 1;
      end
    end
    if ~isempty( A ), varargin = { 'R' , A , varargin{:} }; end
    
    
    A = [];
    if      isfield( V , 'Z' )
      A = V.Z;
    elseif  isfield( V , 'spacing' )
      if isfield( V , 'dim' ), d = V.dim(3);
      else,                    d = size(V.data,3);
      end
      A = ( 0:d-1 ) * V.spacing(3);
    end
    if ~isempty( A ), varargin = { 'Z' , A , varargin{:} }; end
    
    
    A = [];
    if      isfield( V , 'Y' )
      A = V.Y;
    elseif  isfield( V , 'spacing' )
      if isfield( V , 'dim' ), d = V.dim(2);
      else,                    d = size(V.data,2);
      end
      A = ( 0:d-1 ) * V.spacing(2);
    end
    if ~isempty( A ), varargin = { 'Y' , A , varargin{:} }; end

    
    A = [];
    if      isfield( V , 'X' )
      A = V.X;
    elseif  isfield( V , 'spacing' )
      if isfield( V , 'dim' ), d = V.dim(1);
      else,                    d = size(V.data,1);
      end
      A = ( 0:d-1 ) * V.spacing(1);
    end
    if ~isempty( A ), varargin = { 'X' , A , varargin{:} }; end
    
    if isfield( V , 'DATA' ) && ~isfield( V , 'data' )
      V.data = permute( V.DATA ,[2 1 3:6] );
    end
    
    if nargout
      [hg_,I,J,K] = image3( V.data , varargin{:} );
    else
      image3( V.data , varargin{:} );
    end
    return;
  end
  

  if iscell( V ) && isnumeric( V{1} ) && isstruct( V{2} ) %&& isfield( V{2} , 'Format' ) && isequal( V{2}.Format , 'DICOM' )
    V{2} = DICOMxinfo( V{2} );
    [u,~,v] = svd( V{2}.xSpatialTransform(1:3,1:3) );
    V{2}.xSpatialTransform(1:3,1:3) = u * v.';
    try, varargin = { 'R' , V{2}.xSpatialTransform , varargin{:} }; end
    try, varargin = { 'X' , ( 0:size( V{1} ,2)-1 ) * V{2}.PixelSpacing(1) , varargin{:} }; end
    try, varargin = { 'Y' , ( 0:size( V{1} ,1)-1 ) * V{2}.PixelSpacing(2) , varargin{:} }; end
    
    if nargout
      [hg_,I,J,K] = image3( permute( V{1} ,[2 1 3 4 5]) , varargin{:} );
    else
      image3( permute( V{1} ,[2 1 3 4 5]) , varargin{:} );
    end
    return;
  end
  
  
  [varargin,i,T] = parseargs(varargin,'t','$DEFS$',[]);
  if ~isempty( T )
    try, V = V(:,:,:,T);
    catch
      error( 'invalid T.');
    end
  end
  
  
  if ndims( V ) > 4
    error('at most 3d volumes'); 
  end
  sz = size(V); sz(end+1:4) = 1;
  if ~isempty(V)  && ndims( V ) == 4  && ( max( V(:) ) > 1 ||  min( V(:) ) < 0 )
    if sz(4) ~= 3
      error('only for scalar and RGB volumes !!!');
    end
    error('values entre 0 y 1 !!!');
  end
  if ~all( sz )
    error('sizes must be specified for empty volumes.');
  end
  
  [varargin,i,FaceMode] = parseargs( varargin , 'faceMODE' , '$DEFS$', 'texture' );
  FaceMode = lower(FaceMode);
  switch FaceMode
    case {'texture'},     FM = 'texture';  EDGEcolor = 'none';        THICKNESS = 0;
    case {'flat'} ,       FM = 'flat';     EDGEcolor = 'none';        THICKNESS = 1;
    case {'flat_edge'} ,  FM = 'flat';     EDGEcolor = [.4 .4 .6];    THICKNESS = 1;
    case {'interp'},      FM = 'interp';   EDGEcolor = 'none';        THICKNESS = 0;
    case {'interp_edge'}, FM = 'interp';   EDGEcolor = [.4 .4 .6];    THICKNESS = 0;
    otherwise, error('incorrect facemode, try: texture  flat  flat_edge  interp  interp_edge');
  end


  K_CONTOURS = cell(sz(3),1);
  [varargin,~,K_CONTOURS] = parseargs( varargin , 'KContours' , '$DEFS$', K_CONTOURS );
  
  
  
  X = 0:sz(1)-1;
  [varargin,i,X] = parseargs(varargin,'x','$DEFS$',X); X = double(X(:));
  if numel( X ) ~= sz(1), error( 'incorrect size 1'); end
  if ~issorted( X ), error( 'X must be sorted;'); end

  Y = 0:sz(2)-1;
  [varargin,i,Y] = parseargs(varargin,'y','$DEFS$',Y); Y = double(Y(:));
  if numel( Y ) ~= sz(2), error( 'incorrect size 2'); end
  if ~issorted( Y ), error( 'Y must be sorted;'); end

  Z = 0:sz(3)-1;
  [varargin,i,Z] = parseargs(varargin,'z','$DEFS$',Z); Z = double(Z(:));
  if numel( Z ) ~= sz(3), error( 'incorrect size 3'); end
  if ~issorted( Z ), error( 'Z must be sorted;'); end

  
  if strcmp(FM,'texture') && ~isempty(V) && ( var(diff(X)) > 1e-8 || var(diff(Y)) > 1e-8 || var(diff(Z)) > 1e-8 )
    warning('image3:texture_not_recommended','The texture facemode is not recomended for this image. Try flat.');
  end
  

  [varargin,i,M] = parseargs(varargin,'r','m','$DEFS$',eye(4));
  iM = eye(4)/M;

  [varargin,i,THICKNESS] = parseargs( varargin , 'SingletonThickness' , 'THICKness' , '$DEFS$', THICKNESS );
  
  SHOWLINES = [];
  [varargin,SHOWLINES] = parseargs( varargin , 'lines'   , '$FORCE$',{true ,SHOWLINES } );
  [varargin,SHOWLINES] = parseargs( varargin , 'NOLines' , '$FORCE$',{false,SHOWLINES } );

  BOUNDLINES = true;
  [varargin,BOUNDLINES] = parseargs( varargin , 'NOBoundaries' , '$FORCE$',{false,BOUNDLINES } );
  [varargin,BOUNDLINES] = parseargs( varargin , 'boundaries'   , '$FORCE$',{true ,BOUNDLINES } );
  
  
  [varargin,i,FCN]       = parseargs( varargin , 'fcn'   );
  [varargin,i,INFO_FCN]  = parseargs( varargin , 'info'  );
  [varargin,i,CLICK_FCN] = parseargs( varargin , 'click' );

  
  
  ISSINGLETON = sz(1:3) == 1;
  
  IS2D = false;
  if ISSINGLETON( 3 )              &&...
     THICKNESS == 0                &&...
     isequal( Z , 0 )              &&...
     isequal( M(3,:) , [0,0,1,0] ) &&...
     isequal( M(:,3) , [0;0;1;0] )
    IS2D = true;
  end

  if isempty(SHOWLINES), SHOWLINES = ~IS2D; end
  
  SHOWCONTROLS = false;
  if ~any( ISSINGLETON )      ||...
     THICKNESS > 0            ||...
     SHOWLINES
    SHOWCONTROLS = true;
  end
  
  
  
  hAxe = newplot;
  hFig = ancestor( hAxe , 'figure' );
  set( hFig ,'renderer','opengl');
  
  
  
  [a,b,c] = svd(M(1:3,1:3));
  M(1:3,1:3) = a * ( eye(3)*mean(diag(b)) ) *c.';
  
%   M = logm(M);
%   M(~~eye(size(M))) = 0;
%   M = expm( M );
  
  
  hg = hgtransform( 'Parent' , hAxe , 'Matrix' , M ,'Visible','off');
  set( hg ,'UserData',M);
  if nargout, hg_ = hg; end


  lI  = -1; lJ  = -1; lK  = -1;
  hI  = -1; hJ  = -1; hK  = -1; cK = -1;
  hbI = -1; hbJ = -1; hbK = -1;
  
  if ISSINGLETON( 1 ), DX = X + [1,-1]/2*THICKNESS; else, DX = dualV(X); end
  if ISSINGLETON( 2 ), DY = Y + [1,-1]/2*THICKNESS; else, DY = dualV(Y); end
  if ISSINGLETON( 3 ), DZ = Z + [1,-1]/2*THICKNESS; else, DZ = dualV(Z); end
  
  

  BCOLOR = [];
  [varargin,i,BCOLOR] = parseargs( varargin , 'BoundaryColor' , 'BCOLOR' , '$DEFS$', BCOLOR );

  BWIDTH = 2;
  [varargin,i,BWIDTH] = parseargs( varargin , 'BoundaryWidth' , 'BWIDTH' , '$DEFS$', BWIDTH );

  switch FaceMode
    case {'texture'}              , yy = DY([1,end]);        zz = DZ([1,end]);
    case {'flat','flat_edge'}     , yy = DY;                 zz = DZ;
    case {'interp','interp_edge'} , yy = iff(sz(2)>1,Y,DY);  zz = iff(sz(3)>1,Z,DZ);
  end;
  if numel(unique(yy)) > 1 && numel(unique(zz)) > 1
    [ yyb , zzb ] = ndgrid( range(yy) , range(zz) ); xxb = zeros(size(yyb)); xxb(:) = X(1) - eps(X(1));
    [ yy  , zz  ] = ndgrid(       yy  ,       zz  ); xx  = zeros(size(yy )); xx(:)  = X(1);
    hI  = surface('Parent',hg,'XData',xx ,'YData',yy ,'ZData',zz ,'edgecolor',EDGEcolor,'FaceColor',FM,'tag','Iplane','FaceLighting','none');
    switch FM, case {'texture'}, szI = [ sz([2 3])   sz(4) ];
               case {'flat'}   , szI = [ size(xx)-1  sz(4) ];
               case {'interp'} , szI = [ size(xx)    sz(4) ];  end
    BC = BCOLOR; if isempty(BC), BC = [1,0,0]; end
    hbI = surface('Parent',hg,'XData',xxb,'YData',yyb,'ZData',zzb,'EdgeColor',BC,'FaceColor','none','LineWidth',BWIDTH,'hittest','off','FaceLighting','none');
    if ~BOUNDLINES, set(hbI,'EdgeColor','none'); end
  end
  
  switch FaceMode
    case {'texture'}              , xx = DX([1,end]);        zz = DZ([1,end]);
    case {'flat','flat_edge'}     , xx = DX;                 zz = DZ;
    case {'interp','interp_edge'} , xx = iff(sz(1)>1,X,DX);  zz = iff(sz(3)>1,Z,DZ);
  end;
  if numel(unique(xx)) > 1 && numel(unique(zz)) > 1
    [ xxb , zzb ] = ndgrid( range(xx) , range(zz) ); yyb = zeros(size(xxb)); yyb(:) = Y(1) - eps(Y(1));
    [ xx  , zz  ] = ndgrid(       xx  ,       zz  ); yy  = zeros(size(xx )); yy(:)  = Y(1);
    hJ  = surface('Parent',hg,'XData',xx ,'YData',yy ,'ZData',zz ,'edgecolor',EDGEcolor,'FaceColor',FM,'tag','Jplane','FaceLighting','none');
    switch FM, case {'texture'}, szJ = [ sz([1 3])   sz(4) ];
               case {'flat'}   , szJ = [ size(xx)-1  sz(4) ];
               case {'interp'} , szJ = [ size(xx)    sz(4) ];  end
    BC = BCOLOR; if isempty(BC), BC = [0,1,0]; end
    hbJ = surface('Parent',hg,'XData',xxb,'YData',yyb,'ZData',zzb,'edgecolor',BC,'FaceColor','none','LineWidth',BWIDTH,'hittest','off','FaceLighting','none');
    if ~BOUNDLINES, set(hbJ,'EdgeColor','none'); end
  end
  
  switch FaceMode
    case {'texture'}              , xx = DX([1,end]);        yy = DY([1,end]);
    case {'flat','flat_edge'}     , xx = DX;                 yy = DY;
    case {'interp','interp_edge'} , xx = iff(sz(1)>1,X,DX);  yy = iff(sz(2)>1,Y,DY);
  end;
  if numel(unique(xx)) > 1 && numel(unique(yy)) > 1
    [ xxb , yyb ] = ndgrid( range(xx) , range(yy) ); zzb = zeros(size(xxb)); zzb(:) = Z(1) - eps(Z(1));
    [ xx  , yy  ] = ndgrid( xx        ,       yy  ); zz  = zeros(size(xx )); zz(:)  = Z(1);
    hK  = surface('Parent',hg,'XData',xx ,'YData',yy ,'ZData',zz ,'edgecolor',EDGEcolor,'FaceColor',FM,'tag','Kplane','FaceLighting','none');
    switch FM, case {'texture'}, szK = [ sz([1 2])   sz(4) ];
               case {'flat'}   , szK = [ size(xx)-1  sz(4) ];
               case {'interp'} , szK = [ size(xx)    sz(4) ];  end
    BC = BCOLOR; if isempty(BC), BC = [0,0,1]; end
    hbK = surface('Parent',hg,'XData',xxb,'YData',yyb,'ZData',zzb,'EdgeColor',BC,'FaceColor','none','LineWidth',BWIDTH,'hittest','off','FaceLighting','none');
    if ~BOUNDLINES, set(hbK,'EdgeColor','none'); end
    cK = line('XData',NaN,'YData',NaN,'ZData',NaN,'Color',[0 0 1]);
  end

  
  
  

  if SHOWLINES
    if      ishandle(hbJ), xx = get(hbJ,'XData');
    elseif  ishandle(hbK), xx = get(hbK,'XData');
    else                 , xx = [0 0];
    end
    if diff(range(xx))>0
      lI = line( 'Parent',hg,'Color',[1 0 0],'YData',[0 0],'ZData',[0 0],'XData',range(xx),'hittest','off');
    end
    
    if      ishandle(hbI), yy = get(hbI,'YData');
    elseif  ishandle(hbK), yy = get(hbK,'YData');
    else                 , yy = [0 0];
    end
    if diff(range(yy))>0
      lJ = line( 'Parent',hg,'Color',[0 1 0],'XData',[0 0],'ZData',[0 0],'YData',range(yy),'hittest','off');
    end
    
    if      ishandle(hbI), zz = get(hbI,'ZData');
    elseif  ishandle(hbJ), zz = get(hbJ,'ZData');
    else                 , zz = [0 0];
    end
    if diff(range(zz))>0
      lK = line( 'Parent',hg,'Color',[0 0 1],'XData',[0 0],'YData',[0 0],'ZData',range(zz),'hittest','off');
    end
  end

  
  if isempty(V)
    %delete( areH(hI,hJ,hK) );
    bb = { 'Parent',hg,'Color',[1,1,1]*0.8,'linestyle',':','linewidth',1,'hittest','off' };
    line('XData',[X( 1 ) X(end)],'Ydata',[Y( 1 ) Y( 1 )],'Zdata',[Z( 1 ) Z( 1 )],bb{:});
    line('XData',[X( 1 ) X(end)],'Ydata',[Y(end) Y(end)],'Zdata',[Z( 1 ) Z( 1 )],bb{:});
    line('XData',[X( 1 ) X( 1 )],'Ydata',[Y( 1 ) Y(end)],'Zdata',[Z( 1 ) Z( 1 )],bb{:});
    line('XData',[X(end) X(end)],'Ydata',[Y( 1 ) Y(end)],'Zdata',[Z( 1 ) Z( 1 )],bb{:});

    line('XData',[X( 1 ) X(end)],'Ydata',[Y( 1 ) Y( 1 )],'Zdata',[Z(end) Z(end)],bb{:});
    line('XData',[X( 1 ) X(end)],'Ydata',[Y(end) Y(end)],'Zdata',[Z(end) Z(end)],bb{:});
    line('XData',[X( 1 ) X( 1 )],'Ydata',[Y( 1 ) Y(end)],'Zdata',[Z(end) Z(end)],bb{:});
    line('XData',[X(end) X(end)],'Ydata',[Y( 1 ) Y(end)],'Zdata',[Z(end) Z(end)],bb{:});

    line('XData',[X( 1 ) X( 1 )],'Ydata',[Y( 1 ) Y( 1 )],'Zdata',[Z( 1 ) Z(end)],bb{:});
    line('XData',[X( 1 ) X( 1 )],'Ydata',[Y(end) Y(end)],'Zdata',[Z( 1 ) Z(end)],bb{:});
    line('XData',[X(end) X(end)],'Ydata',[Y( 1 ) Y( 1 )],'Zdata',[Z( 1 ) Z(end)],bb{:});
    line('XData',[X(end) X(end)],'Ydata',[Y(end) Y(end)],'Zdata',[Z( 1 ) Z(end)],bb{:});
  end
  

  CURRENT_LOCATION = '';
  CURRENT_POINT    = '';
  CURRENT_VALUE    = '';
  CURRENT_EXTRA    = '';


  [varargin,HIDECONTROLS] = parseargs( varargin , 'hidecontrols' , '$FORCE$',{true,false} );
  
  [varargin,SHOWCONTROLS] = parseargs( varargin , 'showcontrols' , '$FORCE$',{true,SHOWCONTROLS} );
  
  I = []; J = []; K = [];
  if SHOWCONTROLS
    if ~isempty( findall(hFig,'type','uitoolbar','Tag','FigureToolBar') )
      set(hFig,'Toolbar','figure');
    end

    hPAxe = get( hAxe , 'Parent' );
    
    POS = 1;
    controls = findall( hPAxe , 'tag', 'control_image3' );
    if ~isempty( controls )
      POS = arrayfun( @(h) get(h,'position') , controls , 'UniformOutput', false );
      POS = cell2mat( POS(:) );
      POS = max( POS(:,2) ) + 19 ;
    end

    VISIBLE_CHECKBOX = -[1;1;1];
    
    if ishandle( hbI )
      VISIBLE_CHECKBOX(1) = uicontrol( 'Parent',hPAxe,'style','checkbox','position',[ 1 POS+2 15 15],'value',1,'callback',@(h,e) VISIBLE(h, hI , hbI , lI ),'Tag','VisibilityI');
      if HIDECONTROLS, set( VISIBLE_CHECKBOX(1) , 'visible','off' ); end
    end
    I = eEntry( 'Parent',hPAxe,'Range',[1 size(V,1)], 'Step',1  , ...
                'Position' ,[ 17 POS+2  100 17 ] , ...
                'ReturnFcn' , @(x) round(x) , ...
                'slider2edit',@(x) sprintf('%d',round(x)) , ...
                'callback' ,@(x) setI(x) );
    set( I.panel ,'Position', [ 17  POS+2 100 17 ] , 'tag' , 'control_image3' );
    set( I.edit  ,'Position', [  2  1  34 13 ] ,'FontUnits','Pixels','FontSize',9);
    set( I.slider,'Position', [ 37  1  60 13 ] );
    if HIDECONTROLS, set( I.panel , 'visible','off' ); end


    if ishandle( hbJ )
      VISIBLE_CHECKBOX(2) = uicontrol( 'Parent',hPAxe,'style','checkbox','position',[ 120 POS+2 15 15],'value',1,'callback',@(h,e) VISIBLE(h,hJ , hbJ , lJ ),'Tag','VisibilityJ');
      if HIDECONTROLS, set( VISIBLE_CHECKBOX(2) , 'visible','off' ); end
    end
    J = eEntry( 'Parent',hPAxe,'Range',[1 size(V,2)], 'Step',1  , ...
                'Position' ,[ 136 POS+2  100 17 ] , ...
                'ReturnFcn' , @(x) round(x) , ...
                'slider2edit',@(x) sprintf('%d',round(x)) , ...
                'callback' ,@(x) setJ(x) );
    set( J.panel ,'Position', [ 136 POS+2  100 17 ] , 'tag' , 'control_image3' );
    set( J.edit  ,'Position', [  2  1  34 13 ] ,'FontUnits','Pixels','FontSize',9);
    set( J.slider,'Position', [ 37  1  60 13 ] );
    if HIDECONTROLS, set( J.panel , 'visible','off' ); end

  
    if ishandle( hbK )
      VISIBLE_CHECKBOX(3) = uicontrol( 'Parent',hPAxe,'style','checkbox','position',[ 238 POS+2 15 15],'value',1,'callback',@(h,e) VISIBLE(h,hK,hbK,lK,cK),'Tag','VisibilityK');
      if HIDECONTROLS, set( VISIBLE_CHECKBOX(3) , 'visible','off' ); end
    end
    K = eEntry( 'Parent',hPAxe,'Range',[1 size(V,3)], 'Step',1  , ...
                'Position' ,[ 254 POS+2  100 16 ] , ...
                'ReturnFcn' , @(x) round(x) , ...
                'slider2edit',@(x) sprintf('%d',round(x)) , ...
                'callback' ,@(x) setK(x) );
    set( K.panel ,'Position', [ 254 POS+2  100 17 ] , 'tag' , 'control_image3' );
    set( K.edit  ,'Position', [  2  1  34 13 ] ,'FontUnits','Pixels','FontSize',9);
    set( K.slider,'Position', [ 37  1  60 13 ] );
    if HIDECONTROLS, set( K.panel , 'visible','off' ); end

    set( hg , 'DeleteFcn' , @(h,e) delete( areH( VISIBLE_CHECKBOX , I.panel , J.panel , K.panel ) ) );

    I.v = round( sz(1)/2 );
    J.v = round( sz(2)/2 );
    K.v = round( sz(3)/2 );

    try, I.continuous = 1; end
    try, J.continuous = 1; end
    try, K.continuous = 1; end
  
  else
    I.v = 1; J.v = 1; K.v = 1;
    setI( round( sz(1)/2 ) );
    setJ( round( sz(2)/2 ) );
    setK( round( sz(3)/2 ) );
  end

  if ~ishold(hAxe)
    lims = objbounds( hg , 1.05 , true );
%     lims = reshape( lims , [2,3] ).';
%     lims = bsxfun( @plus , mean( lims , 2 ) , diff( lims ,1,2)/2*1.05 * [-1,1] );
%     lims = lims.';
%     lims = lims(:).';
    if IS2D
      lims = lims(1:4);
    end
    axis( lims );
    set( hAxe , 'DataAspectRatio' , [1 1 1] );
    try, OPZ_SetView( hAxe , 'EQUAL' ,'TIGHT' ); end
    
    try,
      hs = findall(hg,'Type','surface','EdgeColor','none');
      clim = [];
      for h = hs(:).'
        clim = [ clim ; double(vec(get(h,'CData'))) ];
      end
      clim = prctile( clim , [5,95] );
      set( hAxe , 'CLim' , clim );
    end
    
  end
  if ~IS2D, try, XYZ_view_toolbar; end; end
  
  if isunix
    drawnow('expose');
    try, OrbitPanZoom(hFig); end
  end
  
  if ~any( ISSINGLETON ) || THICKNESS ~= 0
    previos_WheelFCN = get( hFig , 'WindowScrollWheelFcn' );
    set( hFig , 'WindowScrollWheelFcn' , @(h,e) WheelFCN(h,e,previos_WheelFCN)  );
  end
%   set( hFig , 'WindowButtonMotionFcn',@(h,e) InfoFunction(h,e,get(hFig,'WindowButtonMotionFcn')) );
  set( areH(hI,hJ,hK) , 'ButtonDownFcn' , @(h,e) ClickOnImages() );
  set( hg , 'Visible','on');
  

  
  function WheelFCN(h,e,previousFCN)
    try
    pk = pressedkeys( true );
    if     isequal( pk , {''} ) || isempty( pk )
      v  = 1 * sign( e.VerticalScrollCount );
    elseif isequal( pk , {'LCONTROL'} )
      v  = 5 * sign( e.VerticalScrollCount );
    else
      v  = 0;
    end
    
    id = hittedPLANE();
    if id && ~ISSINGLETON(id), AddIndex(v,id);
    else, try, feval( previousFCN , h , e ); end
    end
    end
  end
  
  function InfoFunction( h , e , previousFCN )
    CURRENT_POINT = ''; CURRENT_VALUE = ''; CURRENT_EXTRA = '';

    [id,p] = hittedPLANE();
    if id
      p  = iM(1:3,1:3) * p(:) + iM(1:3,4);
      CURRENT_POINT = sprintf('(%g,%g,%g)' , p );
      
      ii = val2ind( X , p(1) , 'sorted' );
      jj = val2ind( Y , p(2) , 'sorted' );
      kk = val2ind( Z , p(3) , 'sorted' );

      if     isempty( V ),  CURRENT_VALUE = '[empty]';
      elseif sz(4) == 1  ,  CURRENT_VALUE = sprintf('[%g]',V(ii,jj,kk,:));
      elseif sz(4) == 3  ,  CURRENT_VALUE = sprintf('[%g,%g,%g]',V(ii,jj,kk,:));
      end

      if isempty( INFO_FCN ), CURRENT_EXTRA = '';
      else, try,              CURRENT_EXTRA = feval( INFO_FCN , [ii,jj,kk] , p ); 
        catch
          CURRENT_EXTRA = 'err';
          try
            feval( INFO_FCN , [ii,jj,kk] , p );
          end
        end
        try
          CURRENT_EXTRA = [ '< ' , CURRENT_EXTRA , ' >' ];
        catch
          CURRENT_EXTRA = [ '< some err >' ];
        end
      end

      UpdateTitle();
    else
      UpdateTitle();
      
      try, feval( previousFCN , h , e ); end
    end
  end
  
  function ClickOnImages()
    try
    buttons = pressedkeys(2);
    if ~any( buttons ), return; end
    b = find(buttons);
    if strcmp(get(hFig,'SelectionType'),'open'),  b= b * 10;    end
    action = [ { sprintf('PRESSBUTTON-%d',b) } , pressedkeys(false) ];
    
    if      isequal( action , {'PRESSBUTTON-2'} )
      
      [id,pa] = hittedPLANE(); pa = pa.';
      
      if ~id || ISSINGLETON(id), return; end

      oldMOVE = get( hFig , 'WindowButtonMotionFcn' );
      oldPOINTER = getptr( hFig );
      
      va = M(1:3,id); va = va/norm(va);
      
      p = get( hAxe , 'CurrentPoint' );
      pb = p(1,:)'; vb = p(2,:)' - p(1,:)'; vb = vb/norm(vb);
      
      if ( 1 - abs( va'*vb ) ) < 0.01
        XY_init = get( hFig , 'CurrentPoint' );

        switch id
          case 1, index_init = I.v;
          case 2, index_init = J.v;
          case 3, index_init = K.v;
          otherwise, return;
        end
        
        setptr( hFig , 'uddrag' );
        set( hFig , 'WindowButtonMotionFcn', @(h,e) movingUP_DOWN(id,XY_init,index_init) );
      else
        setptr( hFig , 'hand' );
        set( hFig , 'WindowButtonMotionFcn', @(h,e) moving(id,pa,va) );
      end
      set( hFig , 'WindowButtonUpFcn'    , @(h,e) STOP_moving(oldMOVE,oldPOINTER) );
      
%     elseif  0 && isequal( action , {'PRESSBUTTON-3'} )
% 
%       hls = findall( hAxe , 'type', 'line' );
%       if onoff( hls(1) , 'Visible' )
%         set( hls , 'Visible', 'off' );
%       else
%         set( hls , 'Visible', 'on' );
%       end
        

    elseif  isequal( action , {'PRESSBUTTON-1'} )
      
      [id,p] = hittedPLANE();
      if isempty(id), return; end

      p = transform( p , iM );
      ii = val2ind( X , p(1) , 'sorted' );
      jj = val2ind( Y , p(2) , 'sorted' );
      kk = val2ind( Z , p(3) , 'sorted' );
      
      try, feval( CLICK_FCN , [ii jj kk] , p );
      %catch, fprintf('CLICKED in {%4d,%4d,%4d}   (%g,%g,%g)\n',[ii,jj,kk],p);
      end

    elseif  isequal( action , {'PRESSBUTTON-10'} )

      [id,p] = hittedPLANE();
      if ~id, return; end

      p  = iM(1:3,1:3) * p(:) + iM(1:3,4);

      I.v = val2ind( X , p(1) , 'sorted' );
      J.v = val2ind( Y , p(2) , 'sorted' );
      K.v = val2ind( Z , p(3) , 'sorted' );
      
    elseif  isequal( action , {'PRESSBUTTON-30'} )
      
      id = hittedPLANE();
      if isempty(id), return; end
      switch id
        case 1, controlui( VISIBLE_CHECKBOX(1) , '.' );
        case 2, controlui( VISIBLE_CHECKBOX(2) , '.' );
        case 3, controlui( VISIBLE_CHECKBOX(3) , '.' );
      end
      
    elseif  0 && isequal( action , {'PRESSBUTTON-1PRESSBUTTON-3'} )
      
      id = hittedPLANE();
      if isempty(id), return; end
      
      set( hAxe , 'cameraposition' , get( hAxe , 'cameratarget' ) + M(1:3,id)' * 10000  );
      
    end
    end
    

    function movingUP_DOWN( id , XY_init , index_init )
      XY = get( hFig , 'CurrentPoint' );
      
      d = XY_init(2) - XY(2);
      d = index_init - d/150*sz(id);
      d = min( max( round( d ) , 1 ) , sz(id) );
      
      switch id
        case 1, I.v = d;
        case 2, J.v = d;
        case 3, K.v = d;
        otherwise, return;
      end      
    end
    function moving(id,pa,va)
      p = get(hAxe,'CurrentPoint');
      
      pb = p(1,:)';
      vb = p(2,:)' - p(1,:)';
      vb = vb/norm(vb);
      
      f  = va - ( vb' * va )*vb;
      f  = f/norm(f);
      
      pp = pa - ( f' * ( ( pa-pb ) - ( (pa-pb)'*vb )*vb ) )*va;
      pp = transform( pp' , iM );
      
      switch id
        case 1, I.v = val2ind( X , pp(1) );
        case 2, J.v = val2ind( Y , pp(2) );
        case 3, K.v = val2ind( Z , pp(3) );
      end
      
    end
    function STOP_moving(oldMOVE,oldPOINTER)
      set( hFig , oldPOINTER{:} );
      set( hFig , 'WindowButtonMotionFcn' , oldMOVE );
    end

  end
  
  
  function setI( i )
    try
    if ~ishandle(hbI) && ~ishandle(lJ) && ~ishandle(lK), return; end
    try, set( areH(lJ,lK) , 'XData' , X([i,i]) ); end
    xxb = get( hbI , 'XData' );
    if ~isobject(V) && X(i) == xxb(1),  return; end
    xxb(:) = X(i); set( hbI , 'XData' , xxb );

    if ishandle(hI)
      xx = get( hI , 'XData' ); xx(:) = X(i); set( hI , 'XData' , xx );
      
      xx = V(i,:,:,:);
      if numel(xx) ~= prod(szI), xx = repmat( xx , [1 2 1 1] ); end
      set( hI  , 'CData' , double(reshape( xx , szI )) );
    end

    try, feval( FCN , 'I' , iff(onoff(hbI,'visible'),[i,J.v,K.v],[]) , hg ); end

    CURRENT_LOCATION = sprintf('{%d,%d,%d}' , i , J.v , K.v );
    UpdateTitle();
    end
  end
  function setJ( j )
    try
    if ~ishandle(hbJ) && ~ishandle(lI) && ~ishandle(lK), return; end
    try, set( areH(lI,lK) , 'YData' , Y([j,j]) ); end
    xxb = get( hbJ , 'YData' );
    if ~isobject(V) && Y(j) == xxb(1),  return; end
    xxb(:) = Y(j); set( hbJ , 'YData' , xxb );

    if ishandle(hJ)
      xx = get( hJ , 'YData' ); xx(:) = Y(j); set( hJ , 'YData' , xx );
      
      xx = V(:,j,:,:);
      if numel(xx) ~= prod(szJ), xx = repmat( xx , [2 1 1 1] ); end
      set( hJ  , 'CData' , double(reshape( xx , szJ )) );
    end

    try, feval( FCN , 'J' , iff(onoff(hbJ,'visible'),[I.v,j,K.v],[]) , hg ); end

    CURRENT_LOCATION = sprintf('{%d,%d,%d}' , I.v , j , K.v );
    UpdateTitle();
    end
  end
  function setK( k )
    try
    if ~ishandle(hbK) && ~ishandle(lI) && ~ishandle(lJ), return; end
    try, set( areH(lI,lJ) , 'ZData' , Z([k,k]) ); end
    xxb = get( hbK , 'ZData' );
    if ~isobject(V) && Z(k) == xxb(1),  return; end
    xxb(:) = Z(k); set( hbK , 'ZData' , xxb );

    if ishandle(hK)
      xx = get( hK , 'ZData' ); xx(:) = Z(k); set( hK , 'ZData' , xx );
      
      xx = V(:,:,k,:);
      if numel(xx) ~= prod(szK), xx = repmat( xx , [2 1 1 1] ); end
      set( hK  , 'CData' , double(reshape( xx , szK )) );
    end
    if ishandle(cK)
           set( cK ,'XData',NaN   ,'YData',NaN   ,'ZData',NaN   );
      C = K_CONTOURS{k};
      if ~isempty(C)
      try, set( cK ,'XData',C(:,1),'YData',C(:,2),'ZData',C(:,3)); end
      end
    end

    try, feval( FCN , 'K' , iff(onoff(hbK,'visible'),[I.v,J.v,k],[]) , hg ); end

    CURRENT_LOCATION = sprintf('{%d,%d,%d}' , I.v , J.v , k );
    UpdateTitle();
    end
  end

  function AddIndex(v,id)
    switch id
      case 1, I.v = I.v + v;  
      case 2, J.v = J.v + v;
      case 3, K.v = K.v + v;
    end
  end
  function VISIBLE( h , varargin )
    hs = areH( varargin{:} );
    set( hs , 'visible' , onoff(h,'value') );
    vs = [I.v J.v K.v];

    try, if any( hs == hbI ), feval( FCN , 'I' , iff( ishandle(hbI) && onoff(hbI,'Visible') , vs , [] ) , hg ); end; end
    try, if any( hs == hbJ ), feval( FCN , 'J' , iff( ishandle(hbJ) && onoff(hbJ,'Visible') , vs , [] ) , hg ); end; end
    try, if any( hs == hbK ), feval( FCN , 'K' , iff( ishandle(hbK) && onoff(hbK,'Visible') , vs , [] ) , hg ); end; end
  end
  function hs = areH(varargin)
    hs = [];
    try, hs = gobjects(0); end
    for v = 1:numel(varargin)
      for i = 1:numel(varargin{v})
        h = varargin{v}(i);
        if ishandle(h)
          hs(end+1,1) = h;
        end
      end
    end      
  end
  function UpdateTitle()
    set( hFig , 'Name' , [ CURRENT_LOCATION , '  ' , CURRENT_POINT , ' ' , CURRENT_VALUE , '  ' , CURRENT_EXTRA ] );
  end
  function [id,xyz] = hittedPLANE()
%     uneval(hbI)
    id = 0; xyz = [NaN,NaN,NaN];
    try,
%     set( areH(hbI,hbJ,hbK) , 'facecolor','r' ,'hittest','on');
    if any( hittest == areH(hI,hJ,hK) )
      [xyz,id] = IntersectSurfaceRay( areH(hbI,hbJ,hbK) );
%       disp(id)
    end
    end
%     set( areH(hbI,hbJ,hbK) , 'facecolor','none' ,'hittest','off');
  end

end
function y = dualV(x)
    try
        y = dualVector( x );
    catch
        x = x(:);
        y =  [  x(1) - ( x(2) - x(1) )/2 ;  ( x(1:end-1) + x(2:end) )/2 ; x(end) + ( x(end) - x(end-1) )/2 ];
        y = y.';
    end
end
function i = val2ind( g , x , varargin )

  [~,i] = min( abs( bsxfun( @minus , g(:) , x(:).' ) ) );
  i = reshape( i , size(x) );

end
function r = range( x )
  r = double( [ min(x(:)) , max(x(:)) ] );
end
function x = vec(x)
  x = x(:);
end