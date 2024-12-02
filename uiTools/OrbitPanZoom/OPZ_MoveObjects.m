function OPZ_MoveObjects(h)

  aa = ancestortool( hittest , 'axes' );

  objs = findall( aa , 'Selected' , 'on' );
  if isempty(objs), return; end
  
  startPoint= mean( get(aa,'CurrentPoint'), 1);

  STORED_STATE = setACTIONS(h,'suspend');

  set( h ,'keyPressFcn'           , ';' );
  set( h ,'WindowButtonMotionFcn' , @(h,e) MOVEOBJECTS      );
  set( h ,'WindowButtonUpFcn'     , @(h,e) setACTIONS(h,'restore',STORED_STATE) );
  
  function MOVEOBJECTS
    cp = mean( get( aa, 'CurrentPoint') , 1);
    D= cp - startPoint;
    startPoint = cp;
    
    for o = objs(:)'
      switch get(o,'type')
        case 'line'
          set( o , 'XData', get(o,'XData') + D(1) ,...
                   'YData', get(o,'YData') + D(2) ,...
                   'ZData', get(o,'ZData') + D(3) );

        case 'rectangle'
          set( o , 'Position' , get( o,'Position' ) + [ D(1:2) 0 0 ] );
          
        case 'text'
          p= get( o,'Position' );
          p(:,1)= p(:,1) + D(1);
          p(:,2)= p(:,2) + D(2);
          try, p(:,3)= p(:,3) + D(3); end
          set(o,'Position',p);

        case 'patch'
          v= get( o,'Vertices' );
          v(:,1)= v(:,1) + D(1);
          v(:,2)= v(:,2) + D(2);
          try, v(:,3)= v(:,3) + D(3); end
          set(o,'Vertices',v);
          
        case 'image'
          set( o , 'XData', get(o,'XData') + D(1) ,...
                   'YData', get(o,'YData') + D(2) );
                 
        case 'surface'
          set( o , 'XData', get(o,'XData') + D(1) ,...
                   'YData', get(o,'YData') + D(2) ,...
                   'ZData', get(o,'ZData') + D(3) );
                 
      end
    end
  end

end
