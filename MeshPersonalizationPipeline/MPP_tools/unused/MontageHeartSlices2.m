function MontageHeartSlices2( HS , hFig )

  if nargin < 2, hFig = []; end

  
  Fname = [];
  if ischar( HS )
    [~,Fname,~] = fileparts( HS );
    fprintf( 'Montage of %s\n' , Fname );
    HS = loadv( fullfile( 'Hearts' , [ Fname , '.mat' ] ) , 'HS' );
    
    Fname = fullfile( 'montages' , [ Fname , '.png' ] );
    fileprintf( Fname , ' ' );
  end

  
  for h = 1:size(HS,1)
    try
      B = HS{h,1}(:,:,:,1);
      if size(B,5) == 1
        B = todouble( B );
        B = B - prctile(B,5);
        B = B / prctile(B,95);
        B = cat(5,B,B,B);
        B = clamp( B , 0 , 1 );
      end
      HS{h,1} = B;
    end
  end
  
  
  if isempty( hFig )
    hFig = figure('Position',[1,50,ceil([1080,810]*1)],'Toolbar','none','MenuBar','none','Color','w','Visible','off','RendererMode','manual','Renderer','OpenGL','NextPlot','add');
    if ~system_dependent('useJava','Desktop')
      pos = get( hFig , 'Position' );
      pos(3:4) = ceil([1080,810]*2);
      pos(1) = - pos(3) - 20;
      set( hFig , 'Position' , pos );
    end
    HOLD = false;
  else
    HOLD = true;
  end
  AXs = flip( findall( hFig , 'Type','axes' ) ,1);
  if ~HOLD
    montage_size = [2,3];
    for i=1:10, if prod( montage_size ) < size(HS,1), montage_size( rem(i,2)+1 ) = montage_size( rem(i,2)+1 )+1; end; end
    s = 0.000;
    AXs = axesArray( montage_size , 'L',s,'R',s,'T',s,'B',s,'H',s,'V',s).';
  end
  
  
  a = 0;
  for h = [1 2 3 size(HS,1):-1:4], try
    a = a+1; set( hFig , 'CurrentAxes' , AXs(a) ); set( AXs(a) ,'NextPlot','add' );
    if HOLD
      delete( findall( AXs(a) , 'Type','patch' ) );
      delete( findall( AXs(a) , 'Type','line'  ) );
      drawnow;
    end

    [~,iZ] = getPlane( HS{h,1} ); %%%%%%%%%%%%%%%%%%%
    %iZ = minv( HS{min(h,4),1}.SpatialTransform );
    %iZ = maketransform( iZ , 'tz' , -median( B.transform( iZ ).XYZ(:,3) ) );
      
    B = HS{h,1};
    B = B(:,:,:,1);
    
    if ~HOLD
      imagesc( transform( B , iZ ) ,'Tag','I3D');

      SN = sprintf('SN%d [%d]', DICOMxinfo( B.INFO , 'SeriesNumber' ) , DICOMxinfo( B.INFO , 'xPhase' ) );
      if h > 3, SN = [ SN , sprintf('(%0.1f)' , DICOMxinfo( B.INFO , 'xZLevel' ) ) ]; end
      text( 0 , 0 , 0 , SN , 'HorizontalAlignment','left','VerticalAlignment','top','BackgroundColor',[1 1 0]*1,'Color','r','Margin',4,'FontWeight','bold','EdgeColor','k','Tag','SN');

      DATE = datestr( HS{h,1}.INFO.xDatenum ,'HH:MM:SS');
      if h == 1
        DATE = datestr( HS{h,1}.INFO.xDatenum ,'HH:MM:SS  (dd/mm/yy)');
      end
      text( 0 , 0 , 0 , DATE , 'HorizontalAlignment','left','VerticalAlignment','bottom','BackgroundColor',[1 1 1]*0.8,'Color','r','Margin',3,'FontWeight','bold','EdgeColor','none','Tag','DATE');
    end
    for hh = [ 1:h-1 , h+1:size(HS,1) ]
      try
        IL = intersectionLine( HS{h,1} , HS{hh,1} );
        if isempty( IL ), continue; end
        IL = transform( IL , iZ );
        IL = transform( IL , 'tz',0.001 );
        IL = plot3d( IL , 'y' ,'XLimInclude','off','YLimInclude','off','ZLimInclude','off','Tag','IntersectionLine');
        switch hh
          case 1, set(IL,'Color','r');
          case 2, set(IL,'Color','g');
          case 3, set(IL,'Color','w');
        end
      end
      
      try
        IL = intersectionLine( HS{h,1} , HS{hh,1} , 0.1 );

        A = todouble( HS{h,1}(:,:,:,1,1) );
        try, A.data( ~A.FIELDS.mask ) = NaN; end
        A = A( IL );

        B = todouble( HS{hh,1}(:,:,:,1,1) );
        try, B.data( ~B.FIELDS.mask ) = NaN; end
        B = B( IL );
        
        w = any( ~isfinite( A ) , 2 ) | any( ~isfinite( B ) , 2 );
        IL( w ,:) = NaN;
        A(w) = NaN;
        B(w) = NaN;
        
        B = B - mean( B(~w) );
        B = B /  std( B(~w) );
        B = B *  std( A(~w) );
        B = B + mean( A(~w) );
        
        
        
        IL = transform( IL , iZ );
        IL = transform( IL , 'tz',0.1 );
        IL = cline( IL , B , 'LineWidth',6);
      end
    end

    if 1
      try
        L = transform( HS(h,2:end) , diag([1 1 0 1])*iZ );
        L = transform( L , 'tz',0.01 );
        hplot3d( L , 'color','c' );
      end
    end
    if 1
      try
        L = transform( fmap( @(c)SliceMesh( c , HS{h,1} ), HS([1:h-1,h+1:end],[2:end]) ) , diag([1 1 0 1])*iZ );
        L = transform( L , 'tz',0.2 );
        hplot3d( L , 'Marker','.','Color','m','LineWidth',3,'LineStyle','none','MarkerFaceColor','m','MarkerSize',5 );
      end
    end
    
  catch
    a = a+1;
  end
  end
  
  if ~HOLD
    delete( AXs(a+1:end) ); AXs(a+1:end) = [];

    set( AXs , 'Visible' ,'off' );
    set( hFig , 'Visible' ,'on' );
    drawnow;

    HLAlim = zeros(3,2);
    VLAlim = zeros(3,2);
    LVOlim = zeros(3,2);
    SASlim = zeros(3,2);


    try, HLAlim = reshape( objbounds( findall( AXs( 1 )   , 'Type','patch' ) ) , [2,3] ).'; end
    try, VLAlim = reshape( objbounds( findall( AXs( 2 )   , 'Type','patch' ) ) , [2,3] ).'; end
    try, LVOlim = reshape( objbounds( findall( AXs( 3 )   , 'Type','patch' ) ) , [2,3] ).'; end
    try, SASlim = reshape( objbounds( findall( AXs(4:end) , 'Type','patch' ) ) , [2,3] ).'; end

    D = max( [ diff( HLAlim , 1 , 2 ) , diff( VLAlim , 1 , 2 ) , diff( LVOlim , 1 , 2 ) , diff( SASlim , 1 , 2 ) ] , [] , 2 )*1.02;

    LIMS = mean( HLAlim , 2 )*[1,1] + D*[-1,1]/2; set( AXs(1)     , 'XLim', LIMS(1,:)+[0 0] , 'YLim', LIMS(2,:)+[0 0] ,'ZLim',[-1 1] );
    LIMS = mean( VLAlim , 2 )*[1,1] + D*[-1,1]/2; set( AXs(2)     , 'XLim', LIMS(1,:)+[0 0] , 'YLim', LIMS(2,:)+[0 0] ,'ZLim',[-1 1] );
    LIMS = mean( LVOlim , 2 )*[1,1] + D*[-1,1]/2; set( AXs(3)     , 'XLim', LIMS(1,:)+[0 0] , 'YLim', LIMS(2,:)+[0 0] ,'ZLim',[-1 1] );
    LIMS = mean( SASlim , 2 )*[1,1] + D*[-1,1]/2; set( AXs(4:end) , 'XLim', LIMS(1,:)+[0 0] , 'YLim', LIMS(2,:)+[0 0] ,'ZLim',[-1 1] );

    fmap( @(h)OPZ_SetView(h,'warptofill') , AXs(:) ); drawnow

    for h = findall( AXs , 'Type','text','Tag','SN').'
      set(h,'Position',[ min( get( get(h,'Parent'),'XLim') ) + 4 , max( get( get(h,'Parent'),'YLim') ) - 3 , 0.1 ] );
    end
    for h = findall( AXs , 'Type','text','Tag','DATE').'
      set(h,'Position',[ min( get( get(h,'Parent'),'XLim') ) + 2 , min( get( get(h,'Parent'),'YLim') ) + 2 , 0.1 ] );
    end
  end    


  if ~isempty( Fname );
    fprintf( 'Exporting to "%s"...' , Fname );
    export_fig( hFig , Fname  ,'-png','-a1'); close(hFig);
    fprintf( '  ...Done!\n' );
  end
  
end

