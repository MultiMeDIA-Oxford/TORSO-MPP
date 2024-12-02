function OPZ_WPAN(h,x,factor)
  aa= ancestortool( hittest , 'axes' );
  if ~aa, return; end
  
  if is3daxes(aa)
    set(aa,'XColor',[.65 0 0],'YColor',[0 .65 0],'ZColor',[0 0 .65]);
  end

  xl = get(aa,'XLim');
  yl = get(aa,'YLim');
  zl = get(aa,'ZLim');
  switch lower(x)
    case 'x'
      if strcmp(get(aa,'XScale'),'log')
        xl = clamp( xl , eps(0)*1000 , maxnum/1000 ); 
        xl = xl * ( xl(2)/xl(1) )^factor;
        xl = clamp( xl , eps(0)*1000 , maxnum/1000 );
      else
        xl = xl + factor*( diff(xl) );
      end 
    case 'y'
      if strcmp(get(aa,'YScale'),'log')
        yl = clamp( yl , eps(0)*1000 , maxnum/1000 ); 
        yl = yl * ( yl(2)/yl(1) )^factor;
        yl = clamp( yl , eps(0)*1000 , maxnum/1000 ); 
      else
        yl = yl + factor*( diff(yl) );
      end 
    case 'z'
      if strcmp(get(aa,'ZScale'),'log')
        zl = clamp( zl , eps(0)*1000 , maxnum/1000 ); 
        zl = zl * ( zl(2)/zl(1) )^factor;
        zl = clamp( zl , eps(0)*1000 , maxnum/1000 ); 
      else
        zl = zl + factor*( diff(zl) );
      end 
  end
  set( aa , 'XLim',xl ,'YLim',yl ,'ZLim',zl );

end
