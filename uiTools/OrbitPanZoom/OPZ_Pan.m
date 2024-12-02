function OPZ_Pan( h , aa )
  if nargin<2 || isempty(aa)
    aa= ancestortool( hittest , 'axes' );
  end
  if ~aa, return; end
  
  if is3daxes(aa)
%     set(aa,'XColor',[.65 0 0],'YColor',[0 .65 0],'ZColor',[0 0 .65],...
%            'DataAspectRatio',[1 1 1]);

    oldUNITS = get(h,'Units');
    set( h , 'Units','pixels');

    FP = get(h,'CurrentPoint');

    STORED_STATE= setACTIONS( h , 'suspend' );
    set( h ,'KeyPressFcn'           , ';'             );
    set( h ,'WindowButtonUpFcn'     , @(h,e) STOP_PAN );
    set( h ,'WindowButtonMotionFcn' , @(h,e) PAN_3D   );
  else
    SP= mean( get(aa,'CurrentPoint'), 1);

    STORED_STATE = setACTIONS(h,'suspend');

    set( h ,'keyPressFcn'           , ';' );
    set( h ,'WindowButtonUpFcn'     , @(h,e) STOP_PAN );
    set( h ,'WindowButtonMotionFcn' , @(h,e) PAN_2D   );
  end
  
  function PAN_3D
    newFPoint= get(h,'CurrentPoint');
    D = newFPoint-FP; 
    D = -D/20;
    campan(aa,D(1),D(2),'camera');
    FP= newFPoint;
  end
  
  function PAN_2D
    CP = mean( get( aa, 'CurrentPoint') , 1);
    xl = get(aa,'XLim');
    yl = get(aa,'YLim');
    zl = get(aa,'ZLim');
    
    if strcmp(get(aa,'XScale'),'log')
      xl = clamp( xl , eps(0)*1000 , maxnum/1000 ); 
      xl = xl * ( SP(1) / CP(1) );
      xl = clamp( xl , eps(0)*1000 , maxnum/1000 ); 
    else
      xl = xl + ( SP(1) - CP(1) );
    end
    
    if strcmp(get(aa,'YScale'),'log')
      yl = clamp( yl , eps(0)*1000 , maxnum/1000 ); 
      yl = yl * ( SP(2) / CP(2) );
      yl = clamp( yl , eps(0)*1000 , maxnum/1000 ); 
    else
      yl = yl + ( SP(2) - CP(2) );
    end
    
    if strcmp(get(aa,'ZScale'),'log')
      zl = clamp( zl , eps(0)*1000 , maxnum/1000 ); 
      zl = zl * ( SP(3) / CP(3) );
      zl = clamp( zl , eps(0)*1000 , maxnum/1000 ); 
    else
      zl = zl + ( SP(3) - CP(3) );
    end

    set( aa ,'XLim',xl ,'YLim',yl ,'ZLim',zl );
  end
  
  function STOP_PAN
    setACTIONS( h , 'restore' , STORED_STATE );
    try, set(h,'Units',oldUNITS); end
  end

end
