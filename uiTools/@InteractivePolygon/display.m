function display( IP )

  
  fprintf('Interactive Polygon: ');
  if ishandle( IP.handle )
    IPdata= getappdata( IP.handle , 'InteractivePolygon' );
    fprintf('   Number of Vertices:  %d   -', numel( IPdata.vertices ) );
    if IPdata.spline
      fprintf('    SPLINE   ');
    else
      fprintf('    POLYGON  ');
    end
    if IPdata.close
      fprintf('CLOSE \n');
    else
      fprintf('OPEN\n');
    end
  else
    fprintf('No existe más.\n');
  end

end
