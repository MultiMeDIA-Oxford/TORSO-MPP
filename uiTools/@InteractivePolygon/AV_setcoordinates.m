function AV_setcoordinates(IP,vertice)
  coordinate = [ get(vertice,'XData') get(vertice,'YData') get(vertice,'ZData') ];

  coordinate = inputdlg({'X value:','Y value:','Z value:'},'Coordinates.',1, ...
    { num2str(coordinate(1)) num2str(coordinate(2)) num2str(coordinate(3)) } );
  try
    coordinate = [ str2double(coordinate{1}) str2double(coordinate{2}) str2double(coordinate{3}) ];
  catch
    return;
  end

  IPdata= getappdata( IP.handle , 'InteractivePolygon' );
  try, 
    coordinate= IPdata.constrain( coordinate , IP , closestVertice(IP,vertice) ); 
  end

  set( vertice , 'XData', coordinate(1) , 'YData', coordinate(2) , 'ZData', coordinate(3) );
  xyz= getCurve( IP );
  set( IPdata.line , 'XData',xyz(:,1),'YData',xyz(:,2),'ZData',xyz(:,3) );
  updateArrows( IP , IPdata );
  
  feval( IPdata.fcn , IP );
end
