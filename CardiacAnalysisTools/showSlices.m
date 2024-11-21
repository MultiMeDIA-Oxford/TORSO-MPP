function showSlices( HH , varargin )

  PARENT = [];
  [varargin,~,PARENT] = parseargs(varargin,'PARENT','$DEFS$',PARENT);

  prefORIENT = false;
  [varargin,prefORIENT] = parseargs(varargin,'preferentORIENT','$FORCE$',{true,prefORIENT});

  MASK = false;
  [varargin,MASK] = parseargs(varargin,'mask','$FORCE$',{true,MASK});

  CROP = false;
  [varargin,CROP] = parseargs(varargin,'crop','$FORCE$',{true,CROP});

  ALPHA = 1;
  [varargin,~,ALPHA] = parseargs(varargin,'alpha','$DEFS$',ALPHA);

  HH( cellfun('isempty',HH(:,1)) ,:) = [];
  
%   HH(:,1) = fmap( @(h)h(:,:,:,1) , HH(:,1) );
  
  for h = 1:size( HH ,1)
    I = HH{h,1};
    I = I(:,:,:,1);
    I.data = double( I.data );
    try, I.data( ~I.FIELDS.mask ) = NaN; end
    I = crop( I , 0 , 'mask' , ~isnan( I.data ) );
    HH{h,1} = I;
  end
  

  if prefORIENT
    HH = transform( HH , HH{end,1}.SpatialTransform , 'inv' );
  end

  if MASK
    for h = 1:size(HH,1)
      try
        w = HH{h,1}.FIELDS.Hmask;
        w = expand( w , size(HH{h,1} ) );
        HH{h,1}.data    = double( HH{h,1}.data );
        HH{h,1}.data(~w) = NaN;
      end
    end
  end
  
  if CROP
    for h = 1:size(HH,1)
      HH{h,1} = crop( HH{h,1} , 1 , 'Mask' , isfinite( HH{h,1}.data ) );
      HH{h,1} = crop( HH{h,1} , 5 , 'Mask' , ~~inpoly( HH{h,1} , HH{h,2:end} ) );
    end
    
%     bbox = @(x)[ min(x,[],1) ; max(x,[],1) ];
%     for h = 1:size(HH,1)
%       C = transform( vertcat( HH{h,3:end} ) , DICOMxinfo( HH{h,2} , 'xSpatialTransform' ) , 'inv' );
%       if isempty( C ), continue; end
%       C = bbox( C ); C = bsxfun( @rdivide , bsxfun( @plus , C(:,1:2) , [-1;1]*10 ) , HH{h,2}.PixelSpacing(:).' );
%       HH(h,1:2) = cropDicom( HH(h,1:2) , floor( C(1,2) ):ceil( C(2,2) ) , floor( C(1,1) ):ceil( C(2,1) ) );
%     end
  end

  if isempty( PARENT )
    hFig = figure('Visible','off');
    PARENT = axes('Position',[0 0 1 1]);
  else
    hFig = ancestor( PARENT , 'figure' );
    if isempty( ancestor( PARENT , 'axes' ) )
      PARENT = axes('Position',[0 0 1 1],'Parent',PARENT);
    end
  end
  
  arrayfun(@(h)set(findall(himage3( HH{h,1} ,'nolines','showcontrols','facemode','flat','SingletonThickness',0,'KC',{cell2mat(HH(h,2:end).')},'FCN',@(~,ijk,~)set(findall(hFig,'Tag',sprintf('IL%d',h)),'Visible',onoff(~isempty(ijk)))),'Type','surface','LineWidth',2),'LineWidth',1,'EdgeColor','c'),size(HH,1):-1:1 );axis(objbounds);set(findall(gca,'Type','line'),'Marker','.','LineStyle','none');
  arrayfun(@(h)hplot3d( arrayfun( @(j)intersectionLine( HH{h,1} , HH{j,1} ) , [ 1:h-1 , h+1:size(HH,1) ] ,'un',0) ,':','Color',[0.6,0.6,0.0],'Tag',sprintf('IL%d',h),'LineSmoothing','off'),1:size(HH,1))

  
  chBs = findall(gcf,'Type','uicontrol','Style','checkbox');
  for ch = chBs(:).'
    set( ch , 'UserData' , get( ch , 'Callback' ) );
    set( ch , 'Callback' , @(h,e)VISIBLE_all( h ) );
  end
  function VISIBLE_all( h )
    feval( get(h,'UserData') , h , [] );
    val = get( h , 'Value' );
    
    pk = pressedkeys_win;
    if numel( pk ) == 1 && strcmp( pk{1} , 'LSHIFT' )
      for ch = chBs(:).'
        set( ch , 'Value' , val );
        feval( get(ch,'UserData') , ch , [] );
      end
    end
  end
  
  hAxe = gca;
  set(hFig,'Color','w');
  axis( hAxe ,'equal' );
  axis( hAxe ,'off' );


  ALPHAcontrol = eEntry( 'range', [ 0 , 1 ],'ivalue', 1 ,'step', 0.02 ,'normal','position',[ 360 , 1 , 0 , 0] , 'callback',@(a)set(findall(gca,'Type','Surface'),'FaceAlpha',a) );

  
  set(hFig,'visible','on');
  ALPHAcontrol.continuous=true;
  ALPHAcontrol.v = ALPHA;

  ob = objbounds( hAxe ,1.1);
  axis( hAxe , ob );
  set( hAxe , 'CameraTarget' , mean( reshape(ob,2,[]) ,1) );
  
  
  if prefORIENT && size( HH ,1) == 1
    view( hAxe ,2);
    set( hAxe ,'ZLim' , [-5 5] );
  end
    
end

function I = cropDicom( I , a , b )

  D = I{2};

  D.ImagePositionPatient = D.ImagePositionPatient + D.PixelSpacing(1)*(b(1)-1)*D.ImageOrientationPatient(1:3) + D.PixelSpacing(2)*(a(1)-1)*D.ImageOrientationPatient(4:6);
  try, D = rmfield( D , 'xSpatialTransform' ); end
  
  
  I = I{1};
  I = I(a,b,:);
  
  D.Height  = size( I , 1 );
  D.Rows    = size( I , 1 );
  D.Width   = size( I , 2 );
  D.Columns = size( I , 2 );

  I = { I , D };

end
