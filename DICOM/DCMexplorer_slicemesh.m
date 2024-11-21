function DCMexplorer_slicemesh( info , M )

  try, info = DCMgetimages( info ); end
  try, info = info(1).info; end

  if ~iscell( M ), M = { M }; end

  hL = findall( gcf , 'Tag','slices_in_DCMexplorer' );
  if ~isempty( hL ), delete( hL ); end

  if isempty( info ), return; end
  

  [Z,iZ] = getPlane( info );
  
  for m = 1:numel(M)

    xyz = SliceMesh( Mesh( M{m} ) , Z );
    if isempty( xyz ), continue; end
    
    h = line('Parent',gca,'XData',NaN,'YData',NaN,'Tag','slices_in_DCMexplorer','linewidth',2,'color',colorith(m),'Marker','none' );
    
    xyz = transform( xyz , iZ );
    set( h , 'XData' , 1 + xyz(:,1)/info.PixelSpacing(1) ,'YData' , 1 + xyz(:,2)/info.PixelSpacing(1) );
    
    try, set( h , 'Color'     , M{m}.Color     ); end
    try, set( h , 'LineWidth' , M{m}.LineWidth ); end
    try, set( h , 'Marker'    , M{m}.Marker    ); end
    try, set( h , 'LineStyle' , M{m}.LineStyle ); end
  end
end

