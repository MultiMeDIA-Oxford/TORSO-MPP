function M = SurFCo( C , M , varargin )
if 0
  
cd E:\Dropbox\Vigente\ezCode\SurFCo\
load HQ
C = HQ(:,[4 6]);
M = initialHeartMesh( C );
SurFCo( C , M , 'USE_BOUNDARIES','PLOT','verbose');
Contours2Surface_ez( C , 'INITIAL_MESH' , M );
  
  %%
end

  PLOT = false;
  USE_BOUNDARIES = true;
  EAP = [];
  DENSIFY_CONTOURS_AT = 0.005;

  %%
  [varargin,PLOT] = parseargs(varargin,'PLOT','$FORCE$', {true,PLOT} );
  [varargin,USE_BOUNDARIES] = parseargs(varargin,'USE_BOUNDARIES','$FORCE$', {USE_BOUNDARIES,false} );
  [varargin,~,EAP] = parseargs(varargin,'ExtraAnchorPoints','$DEFS$', EAP );
  
  %%
  M = Mesh( M , 0 );

  %% join contours in the same row
  for r = 1:size(C,1)
    tC = C{r,1};
    for c = 2:size(C,2)
      tC(end+1, 1:max( size(tC,2) , size(C{r,c},2) ) ) = NaN;
      tC = [ tC ; C{r,c} ];
    end
    tC = polyline( tC );
    %tC = join( tC );
    tC = double( tC );
    C{r,1} = tC;
  end
  C = C(:,1);
  C( cellfun('isempty',C) ) = [];

  %% normalize the data to be in the unit sphere
  oC   = C;
  oEAP = EAP;
  [~,rP,nP] = miniballNormalize( C );
  C   = transform( C   , nP );
  M   = transform( M   , nP );
  EAP = transform( EAP , nP );
  
  %% include the original boundaries of M as attractor contours
  B = [];
  if USE_BOUNDARIES
    B = meshSeparate( MeshBoundary( M ) );
    for b = 1:numel(B)
      B{b} = mesh2contours( B{b} );
    end
  end
  
  %% "densify" the contours
  for c = 1:numel(C)
    tC = C{c};
    tC = polyline( tC );
    tC = polylinefun( @(p)resample( p , '+e' , DENSIFY_CONTOURS_AT )  , tC );
    C{c} = double( tC );
  end
  % and the boundaries!
  for b = 1:numel(B)
    B{b} = double( resample( polyline( B{b} ) , '+e' , DENSIFY_CONTOURS_AT ) );
  end

  %% collect all points
  XYZ  = [ cell2mat( C(:) ) ; cell2mat( B(:) ) ];
  nEAP = size( XYZ ,1);
  XYZ  = [ XYZ ; EAP ];
  
  %%
  
  if PLOT
    hFig = initiate_PLOT( rP( M ) , rP( C ) , rP( B ) , rP( EAP ) );
    PLOT_FCN = @(M,it,mode,~)plotFCN( rP( M ) , it , mode , hFig );
  else
    PLOT_FCN = @(varargin)true;
  end
    
  M = MeshKneading( M , XYZ , 250 , ...
                    'DECIMATE'    , { 0.28 , 20 } ,...
                    'SUBDIVIDE'   , { 'safebutterfly' , 20 } ,...
                    'SMOOTH'      , { 200 , 20 } ,...
                    'SAMPLING'    , { @(XYZ,M)SAMPLING( XYZ , M , {0.08,Inf} , nEAP , 4 ) , 1 } ,...
                    'CLOSEST'     , true ,...
                    'PERCENTAGES' , 0.1 ,....
                    'LAMBDAS'     , -1e5 / 2  ,...
                    'plotFCN'     , PLOT_FCN ,...
                    varargin{:} );
  
  %% undo the normalization to the unit sphere
  M = rP( M );

  if PLOT
    hAX = get( hFig , 'CurrentAxes' );
    delete( findall( hAX , 'Tag','closest_points' ) );
    delete( findall( hAX , 'Tag','attractor_points' ) );
    delete( findall( hAX , 'Tag','boundary_points' ) );
    delete( findall( hAX , 'Tag','contour_points' ) );
    delete( findall( hAX , 'Tag','extra_points' ) );
    
    allDISTANCES = [];
    
    x = cell2mat( oC(:) );
    x( any( isnan( x ) ,2) ,:) = [];
    d = distanceFrom( x , M ); allDISTANCES = [ allDISTANCES ; d(:) ];
    hC = patch('Vertices',x,'faces', [ 1:size(x,1)-1 ; 2:size(x,1) ].',...
      'EdgeColor','none','FaceColor','none','FaceVertexCData',d,...
      'MarkerSize',5,...
      'CData',d,...
      'LineStyle','none','Marker','o','MarkerFaceColor','flat',...
      'MarkerEdgeColor',[1 1 1]*0.1 );
    uicontrol('Position',[5,10,100,20],'String','OriginalContours',...
      'Value',true,'Style','checkbox','BackgroundColor','w',...
      'Callback',@(h,e)set(hC,'Visible',onoff(get(h,'Value'))) );

    
    try, x = cell2mat( oEAP(:) ); end
    x( any( isnan( x ) ,2) ,:) = [];
    d = distanceFrom( x , M ); allDISTANCES = [ allDISTANCES ; d(:) ];
    hX = patch('Vertices',x,'faces', [ 1:size(x,1)-1 ; 2:size(x,1) ].',...
      'EdgeColor','none','FaceColor','none','FaceVertexCData',d,...
      'MarkerSize',5,...
      'CData',d,...
      'LineStyle','none','Marker','s','MarkerFaceColor','flat',...
      'MarkerEdgeColor',[1 1 1]*0.1 );
    uicontrol('Position',[5,10+25,100,20],'String','ExtraAttractors',...
      'Value',true,'Style','checkbox','BackgroundColor','w',...
      'Callback',@(h,e)set(hX,'Visible',onoff(get(h,'Value'))) );

    x = oC;
    for c = 1:numel(x)
      x{c} = double( polylinefun( @(p)resample(p,'+w',linspace(0,1,15000) ) , polyline( x{c} ) ) );
    end
    x = cell2mat( x );
    x( any( isnan( x ) ,2) ,:) = [];
    [d,c] = distanceFrom( x , M );
    hD = patch( 'Vertices',[ x ; c] ,'Faces',reshape( 1:(2*size(c,1)) ,[],2 ),...
      'FaceColor','none','LineWidth',1,'EdgeColor','flat','FaceVertexCData',[d;d]);
    uicontrol('Position',[5,35+25,100,20],'String','Distances2Mesh',...
      'Value',true,'Style','checkbox','BackgroundColor','w',...
      'Callback',@(h,e)set(hD,'Visible',onoff(get(h,'Value'))) );

    x = [];
    for c = 1:numel( oC )
      x = [ x ; meshSlice( M , getPlane( oC{c} ) ) ; NaN NaN NaN ];
    end
    hS = line('XData',x(:,1),'YData',x(:,2),'ZData',x(:,3),'LineWidth',2,'Color','k');
    uicontrol('Position',[5,60+25,100,20],'String','newContours',...
      'Value',true,'Style','checkbox','BackgroundColor','w',...
      'Callback',@(h,e)set(hS,'Visible',onoff(get(h,'Value'))) );
    
    
    %set( hM , 'EdgeAlpha',0.1,'EdgeColor','k');
    
    hM = findall( hAX , 'Tag' , 'mesh' );
    uicontrol('Position',[5,85+25,100,20],'String','MeshEdges',...
      'Value',true,'Style','checkbox','BackgroundColor','w',...
      'Callback',@(h,e)set(hM,'EdgeColor',iff( get(h,'Value') ,[1,1,1]*0.3,'none' ) ) );
    
    set( hM , 'FaceAlpha',0.8 );
    uicontrol('Position',[5,110+25,100,12],'String','',...
      'min',0,'max',1,...
      'Value',0.8,'Style','slider','BackgroundColor','w',...
      'Callback',@(h,e)set(hM,'FaceAlpha',get(h,'Value') ) );
    

    set( hAX , 'CLim' , prctile( allDISTANCES , [0 , 90 ] ) );
    set( get(hAX,'Parent') , 'Colormap' , [ get( get(hAX,'Parent') , 'Colormap' ) ; 1 0 1 ] )
    colorbar;
    
    headlight;
  end
  
  
end
function hFig = initiate_PLOT( M , C , B , EAP )
  hFig = figure( 'HandleVisibility', 'on'     ,...
                  'ToolBar','figure',...
                    'IntegerHandle', 'on'     ,...
                         'NextPlot', 'add'    ,...
                      'NumberTitle', 'off'    ,...
                         'Renderer', 'openGL' ,...
                     'RendererMode', 'manual' );
  set( hFig , 'Colormap' , winter(256) );

  hM = patch( 'Faces' , M.tri , 'Vertices' , M.xyz ,...
     'FaceAlpha',0.5,'EdgeColor',[1,1,1]*0.3,...
     'FaceColor',[1 1 1]*0.6 + [.6 .75 .75]*0 ,...
     'FaceLighting' , 'gouraud' ,...
     'AmbientStrength'  , 0.3 ,...
     'DiffuseStrength' , 0.6  ,...
     'SpecularStrength' , 0.9  ,...
     'SpecularExponent' , 20 ,...
     'SpecularColorReflectance' , 1.0 ,...
     'Tag' , 'mesh' );

  x = cell2mat( C );
  line('XData',x(:,1),'YData',x(:,2),'ZData',x(:,3),'LineWidth',1,'Color','r','LineStyle','none','Marker','.','Tag','contour_points');

  x = cell2mat( B );
  try, line('XData',x(:,1),'YData',x(:,2),'ZData',x(:,3),'LineWidth',1,'Color','g','LineStyle','none','Marker','.','Tag','boundary_points'); end

  x = EAP;
  try, line('XData',x(:,1),'YData',x(:,2),'ZData',x(:,3),'LineWidth',1,'Color','b','LineStyle','none','Marker','.','Tag','extra_points'); end

  set(gca,'DataAspectRatio',[1 1 1]);
  axis(objbounds(get(hM,'Parent'),1.3));
end
function c = plotFCN( M , it , mode , hFig )
  try
    set( hFig , 'Name' , sprintf('%4d - %s',it,mode) );
    if isempty( M )
      set( hFig , 'Name' , [ get( hFig , 'Name' ) , ' .... ' ] );
      drawnow('expose');
      return;
    end
    hAX = get( hFig , 'CurrentAxes' );
      
    switch uppper(mode)
      case {'PULL'}
        hM = findall( hAX ,'Tag','mesh' );
        set( hM , 'Vertices', M.xyz );
      case {'SMOOTH'}
        hM = findall( hAX ,'Tag','mesh' );
        set( hM , 'Vertices', M.xyz );
      case {'CLOSEST'}
        h = findall( hAX ,'Tag','closest_points' );
        
        v = get(h,'Vertices');
        v( 1:size(M,1) ,:) = M;
        set(h,'Vertices',v);
      case {'FARTHEST','SAMPLING'}
        delete( findall( hAX ,'Tag','attractor_points' ) );
        line('Parent',hAX,'XData',M(:,1),'YData',M(:,2),'ZData',M(:,3),'LineWidth',1,...
          'Color','k','LineStyle','none','Marker','o',...
          'MarkerSize',7,...
          'Tag','attractor_points','MarkerFaceColor','m');
        
        delete( findall( hAX , 'Tag','closest_points' ) );
        v = [M;M];
        f = reshape( 1:(2*size(M,1)) ,[],2 );
        patch('Parent',hAX,'Vertices',v,'Faces',f,'Tag','closest_points',...
          'EdgeColor','k','Marker','.','LineWidth',2);
        
      case {'DECIMATE'}
        hM = findall( hAX ,'Tag','mesh' );
        set( hM , 'Vertices', M.xyz , 'Faces' , M.tri );
      case {'REMESH'}
        hM = findall( hAX ,'Tag','mesh' );
        set( hM , 'Vertices', M.xyz , 'Faces' , M.tri );
      case {'SUBDIVIDE'}
        hM = findall( hAX ,'Tag','mesh' );
        set( hM , 'Vertices', M.xyz , 'Faces' , M.tri );
      otherwise
    end
    c = true;
    drawnow();
  catch
    c = false;
%     if ~ishandle( hM ), c = false; end
%     drawnow('expose')
%     return;
  end
end







function A = SAMPLING( XYZ , M , FPSopts  , nEAP , rep )
  persistent lastA
  persistent lastXYZ
  persistent lastM
  persistent lastID
  
  if isequal( XYZ , lastXYZ )     &&...
     isequal( M.xyz , lastM.xyz ) &&...
     isequal( M.tri , lastM.tri )
    ID = lastID;
  else
    [~,~,d] = vtkClosestElement( M , XYZ );
    [~,ID] = max( d );
    lastXYZ = XYZ;
    lastM   = M;
  end
  
  if lastID == ID
    A = lastA;
    return;
  end
  lastID = ID;
  
  if ~iscell( FPSopts )
    FPSopts = { FPSopts };
  end
  
  [~,ids] = FarthestPointSampling( XYZ , ID , FPSopts{:} );
  if any( ids > nEAP )
    w = ids > nEAP;
    idsEAP = ids( w );
    ids( w ) = [];
    ids = [ ids(:) ; repmat( idsEAP(:) ,rep,1) ];
  end
  A = XYZ( ids ,:);
  
  lastA   = A;
end




