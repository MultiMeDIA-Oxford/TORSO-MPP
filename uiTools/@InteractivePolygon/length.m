function n = length( IP )

  n = getappdata( IP.handle , 'InteractivePolygon' );
  n = numel( n.vertices );

end
