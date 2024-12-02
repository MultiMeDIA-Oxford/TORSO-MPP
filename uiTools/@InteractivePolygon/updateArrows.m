function updateArrows( IP , IPdata )

    X = get( IPdata.line , 'XData' );
    Y = get( IPdata.line , 'YData' );
    Z = get( IPdata.line , 'ZData' );
    
    if IPdata.arrows(1,2) ~= 0
      x0 = [ X( 1 ) ; Y( 1 ) ; Z( 1 ) ];
      r0 = atan2( Y(2)-Y(1) , X(2)-X(1) ) + pi;
      set( IPdata.arrows(1,1) , 'matrix', maketransform('s',IPdata.arrows(1,2),'radians','rz',r0,'t',x0) , 'Visible','on' );
    else
      set( get( IPdata.arrows(1,1) , 'children' ) , 'Visible','off');
    end
    
    if IPdata.arrows(2,2) ~= 0
      x1 = [ X(end) ; Y(end) ; Z(end) ];
      r1 = atan2( Y(end)-Y(end-1) , X(end)-X(end-1) );
      set( IPdata.arrows(2,1) , 'matrix', maketransform('s',IPdata.arrows(2,2),'radians','rz',r1,'t',x1) , 'Visible','on' );
    else
      set( get( IPdata.arrows(2,1) , 'children' ) , 'Visible','off');
    end

end