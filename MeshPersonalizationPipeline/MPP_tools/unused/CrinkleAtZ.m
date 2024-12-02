function M = CrinkleAtZ(  M , z )

  zs = M.xyz(:,3);
  
  w = any( zs( M.tri ) >= z , 2 );
  for f = fieldnames( M ).'
    if ~strncmp( f{1} , 'tri' , 3 ), continue; end
    M.(f{1})( w , : ) = [];
  end
  
  M = MeshTidy( M , -1 );
  
end
