function OPZ_WZoom(h,factor)
  aa= ancestortool( hittest , 'axes' );
  if ~aa, return; end
  
  if is3daxes(aa)
%     set(aa,'XColor',[.65 0 0],'YColor',[0 .65 0],'ZColor',[0 0 .65]);
  end

  CP = mean( get(aa,'CurrentPoint') ,1);

  xl = get(aa,'XLim');
  if strcmp(get(aa,'XScale'),'log')
    xl = clamp( xl , eps(0) , maxnum ); 
    xl = realpow( xl/CP(1) , factor ) * CP(1);
    xl = clamp( xl , eps(0) , maxnum ); 
  else
    xl = factor*( xl - CP(1) ) + CP(1);
  end

  yl = get(aa,'YLim');
  if strcmp(get(aa,'YScale'),'log')
    yl = clamp( yl , eps(0) , maxnum ); 
    yl = realpow( yl/CP(2) , factor ) * CP(2);
    yl = clamp( yl , eps(0) , maxnum ); 
  else
    yl = factor*( yl - CP(2) ) + CP(2);
  end

  zl = get(aa,'ZLim');
  if strcmp(get(aa,'ZScale'),'log')
    zl = clamp( zl , eps(0) , maxnum ); 
    zl = realpow( zl/CP(3) , factor ) * CP(3);
    zl = clamp( zl , eps(0) , maxnum ); 
  else
    zl = factor*( zl - CP(3) ) + CP(3);
  end

  set( aa , 'XLim',xl ,'YLim',yl ,'ZLim',zl );

end
