function I = getPicture( I )

  C = {};
  if iscell( I )
    if size( I ,1) > 1, error('a single slice was expected'); end
    C = I(1,2:end);
    I = I{1,1};
  end
  
  if isa( I , 'I3D' )
    I = I.coords2matrix;
    C = transform( C , minv( I.SpatialTransform ) );
    I = I.data;
  end
  I = I(:,:,:,1,:,:);
  
  if isinteger( I ), I = double( I )/255; end
  
  I = double( I );
  I = squeeze( I );

  sz = size( I );
  if prod( sz(3:end) ) == 1
    I = I - prctile( I(:) , 5 ); I = I / prctile( I(:) , 95 ); I = clamp( I , 0 , 1 );
  end
  I = permute( I , [2 1 3:10] );
  if alleq( I ,3), I = I(:,:,1); end
  
  if ~any( cellfun('prodofsize',C) )
    return;
  end

  I = repmat( I ,[1 1 3] );
  
  hFig = figure('Units','pixels','Position', [ 1 , 100 , size(I,2)+20 , size(I,1)+20 ] ,'MenuBar','none','ToolBar','none','WindowStyle','modal',...
          'HandleVisibility', 'off',...
                   'HitTest', 'off',...
             'IntegerHandle', 'off',...
                      'Name', '',...
               'NumberTitle', 'off',...
                   'Pointer', 'custom',...
         'PointerShapeCData', NaN(16,16),...
       'PointerShapeHotSpot', [1 1],...
                    'Resize', 'off' );
  
  CLEANUP = onCleanup( @()delete( hFig ) );
  hAxe = axes( 'Parent',hFig , 'Units','pixels','Position', [ 2 , 2 , size(I,2) , size(I,1) ] );
  image( 'Parent',hAxe , 'XData', [0,size(I,2)-1] , 'YData', [0,size(I,1)-1] , 'CData',I );

  for c = 1:numel(C)
    tC = C{c};
    if isempty( tC ), continue;
    elseif size( tC ,1) > 3
      line( 'Parent',hAxe , 'XData', tC(:,1) , 'YData' , tC(:,2) , 'ZData' , tC(:,3)*0+0.1 , 'Color',colorith(c),'LineStyle','-','Marker','none','LineWidth',1.3,'LineSmoothing','on');
    elseif size( tC ,1) == 1
      line( 'Parent',hAxe , 'XData', tC(:,1) , 'YData' , tC(:,2) , 'ZData' , tC(:,3)*0+0.2 , 'Color','k','LineStyle','-','Marker','o','LineWidth',1.3,'LineSmoothing','on','MarkerFaceColor',colorith(c),'MarkerSize',5 );
    else
      error('not implemented for lines yet.');
    end
  end
  
  
  
  
  
  set( hAxe , 'XLim' , [0 , size(I,2)]-0.5 , 'YLim' , [0 , size(I,1)]-0.5 ,'YDir', 'Reverse' );
  set( hAxe , 'ZLim' , [-1 1] );
  set( hAxe , 'XTick',[],'YTick',[],'ZTick',[],'XColor','w','YColor','w','ZColor','w','Layer','bottom');
  set( hFig , 'Color','white' );
  set( hAxe , 'Visible','off' );

  
  I = getframe( hAxe );
  I = I.cdata;
  if alleq( I ,3), I = I(:,:,1); end
  I = double( I )/255;
  I = crop( I , 0 , @(x)x<1 );
  
  
%   I = crop( photoscreen( hFig ) , 0 , @(x)x<0.88 );

end




