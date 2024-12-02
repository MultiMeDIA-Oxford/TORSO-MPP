function OPZ_Zoom( h , aa , show_factors )
  if nargin<2 || isempty(aa)
    aa = ancestortool( hittest , 'axes' );
  end
  if ~aa, return; end
  
  if nargin < 3, show_factors = true; end

  STORED_STATE= setACTIONS( h , 'suspend' );

  oldUNITS= get(h,'Units');
  set( h , 'Units' , 'pixels' );

  FigurePoint     = get(h,'CurrentPoint');
  if is3daxes(aa)
%     set(aa,'XColor',[.65 0 0],'YColor',[0 .65 0],'ZColor',[0 0 .65] );
    %              'DataAspectRatio',[1 1 1]);
    
    originalCV  = get( aa ,'CameraView'  );

    set(h,'KeyPressFcn',';');
    set(h,'WindowButtonMotionFcn',@(h,e) ZOOM_3D   );
    set(h,'WindowButtonUpFcn'    ,@(h,e) STOP_ZOOM );
  else
    fixedDAR = strcmp( get(aa,'DataAspectRatioMode'),'manual' );
    
    WorldPoint      = mean( get(aa,'CurrentPoint') ,1);
    
    limits= [get(aa,'XLim') get(aa,'YLim') get(aa,'ZLim')];
    [ vi , HH , VV ] = viewfrom(aa);

    if show_factors
      AnnotationAxes  = axes( 'Parent',h,...
        'Units','normalized',...
        'Position',[0 0 1 1],...
        'Visible','off' );
      AnnotationPoint = mean(get(AnnotationAxes,'CurrentPoint'),1);
      AnnotationLine  = line( 'Parent',AnnotationAxes     ,...
        'XData', AnnotationPoint(1) ,...
        'YData', AnnotationPoint(2) ,...
        'LineStyle',':'             ,...
        'LineWidth',3               ,...
        'Color',[1 0 0]             );
      AnnotationText  = text( 'Parent',AnnotationAxes,...
        'BackgroundColor',[.7 .7 .8]  ,...
        'Color',[1 0 0]               ,...
        'FontSize',7                  ,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','middle'  ,...
        'Position',AnnotationPoint    );
      set(AnnotationAxes,'XLim',[0 1],'YLim',[0 1],'ZLim',[0 1],...
        'XLimMode','manual','YLimMode','manual','ZLimMode','manual');
    end
    
    set(h,'KeyPressFcn',';');
    set(h,'WindowButtonMotionFcn',@(h,e) ZOOM_2D   );
    set(h,'WindowButtonUpFcn'    ,@(h,e) STOP_ZOOM );
  end
  
  function ZOOM_3D
    newFPoint = get(h,'CurrentPoint');
    dY = newFPoint(2) - FigurePoint(2);
    set( aa , 'cameraview' , originalCV );

    camzoom( aa , exp(dY/100) );
  end

  function ZOOM_2D
    newFPoint = get(h,'CurrentPoint');
    dH = newFPoint(1) - FigurePoint(1);
    dV = newFPoint(2) - FigurePoint(2);
    
    if ~any( strcmp( pressedkeys , 'LCONTROL') )
      if fixedDAR
        [d,d] = max(abs([dH,dV]));
        if d == 1
          dV = dH;
        else
          dH = dV;
        end
      else
        slope = atan2(dV,dH);
        slope = floor( slope / pi * 12 );
        switch slope
          case {-12,-11}        , dV = 0;
          case {-10,-9}         , dH = (dH+dV)/2; dV = dH;
          case {-8,-7,-6,-5,-4} , dH = 0;
          case {-3,-2,-1,0,1}   , dV = 0;
          case {2,3}            , dH = (dH+dV)/2; dV = dH;
          case {4,5,6,7,8}      , dH = 0;
          case {9,10,11,12}     , dV = 0;
        end
      end
    end
    


    if show_factors
      newAPoint= figurexy2axesxyz( FigurePoint+[dH dV] , AnnotationAxes);
      set( AnnotationLine,'XData',[AnnotationPoint(1) newAPoint(1)],...
                          'YData',[AnnotationPoint(2) newAPoint(3)] );
    end
    
    dV = exp(-dV/100); dV= round(dV*100)/100;
    dH = exp(-dH/100); dH= round(dH*100)/100;

    sX = 1;
    sY = 1;
    sZ = 1;
      
    switch HH
      case 'X', sX = dH;
      case 'Y', sY = dH;
      case 'Z', sZ = dH;
    end
    switch VV
      case 'X', sX = dV;
      case 'Y', sY = dV;
      case 'Z', sZ = dV;
    end
        
    xl = limits(1:2);
    if sX ~= 1 && strcmp( get(aa,'XScale') , 'log' )
      xl = clamp( xl , eps(0) , maxnum );
      xl = realpow( xl/WorldPoint(1) , sX ) * WorldPoint(1);
      xl = clamp( xl , eps(0) , maxnum );
    elseif sX ~= 1
      xl = ( xl - WorldPoint(1) )*sX + WorldPoint(1);
    end
    
    yl = limits(3:4);
    if sY ~= 1 && strcmp( get(aa,'YScale') , 'log' )
      yl = clamp( yl , eps(0) , maxnum );
      yl = realpow( yl/WorldPoint(2) , sY ) * WorldPoint(2);
      yl = clamp( yl , eps(0) , maxnum );
    elseif sY ~= 1
      yl = ( yl - WorldPoint(2) )*sY + WorldPoint(2);
    end
    
    zl = limits(5:6);
    if sZ ~= 1 && strcmp( get(aa,'ZScale') , 'log' )
      zl = clamp( zl , eps(0) , maxnum );
      zl = realpow( zl/WorldPoint(3) , sZ ) * WorldPoint(3);
      zl = clamp( zl , eps(0) , maxnum );
    elseif sZ ~= 1
      zl = ( zl - WorldPoint(3) )*sZ + WorldPoint(3);
    end
    
    set(aa,'XLim', xl , 'YLim', yl , 'ZLim', zl );
    
    if show_factors
      switch vi(2)
        case 'Z', set( AnnotationText,'String',{ sprintf('X: %.02f',1/dH) , sprintf('Y: %.02f',1/dV) });
        case 'X', set( AnnotationText,'String',{ sprintf('Y: %.02f',1/dH) , sprintf('Z: %.02f',1/dV) });
        case 'Y', set( AnnotationText,'String',{ sprintf('X: %.02f',1/dH) , sprintf('Z: %.02f',1/dV) });
      end
    end
  end

  function STOP_ZOOM
    setACTIONS( h , 'restore' , STORED_STATE );
    try, set(h,'Units',oldUNITS); end
    try, delete(AnnotationAxes);  end
  end
end
