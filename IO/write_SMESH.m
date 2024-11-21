function write_SMESH( S , fname , holes )
  if nargin < 3, holes = []; end

  fid = fopen( fname , 'w' ); CLEANUP = onCleanup( @()fclose(fid) );

  data = S.xyz;

  fprintf( fid , '#PART 1 - Node list\n' );
  fprintf( fid , '#num nodes, num dimensions, num attributes, num boundary markers\n' );
  fprintf( fid , '%d 3 0 0\n' , size( data ,1) );
  fprintf( fid , '#Node ID, x, y, z,attribute,boundary marker\n' );
  if isinteger( data )
    data = [ int32( 1:size( data ,1) ).' , data ];
    data = data.';
    fprintf( fid , '%d   %d   %d   %d\n' , data );
  elseif isa( data , 'single' )
    data = [ single(1:size(data,1)).' , data ];
    data = data.';
    fprintf( fid , '%d   %0.8e   %0.8e   %0.8e\n' , data );
  else
    data = double( data );
    data = [ (1:size(data,1)).' , data ];
    data = data.';
    fprintf( fid , '%d   %0.16e   %0.16e   %0.16e\n' , data );
  end


  data = S.tri;

  fprintf( fid , '#PART 2 - Facet list\n');
  fprintf( fid , '#num faces, boundary markers\n');
  fprintf( fid , '%d 0\n', size( data ,1) );
  fprintf( fid , '#Facet ID, <corner1, corner2, corner3,...>,[attribute],[boundary marker]\n');

  data(:,4) = 3; data = data(:,[4 1 2 3]);
  data = data.';
  fprintf( fid , '%d  %d  %d  %d\n', data );


  fprintf( fid , '#PART 3 - Hole list\n');
  fprintf( fid , '#Num holes\n');
  fprintf( fid , '%d\n' , size( holes , 1 ) );
  fprintf( fid , '#<hole #> <x> <y> <z>\n');
  for h = 1:size( holes , 1 )
    fprintf( fid , '%d   %0.16e   %0.16e   %0.16e\n' , h , holes( h , : ) );
  end

  fprintf( fid , '\n' );

end
