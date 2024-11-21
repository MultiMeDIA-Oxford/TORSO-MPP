function DCMexplorer_contours( info , C , pxSize )

  if nargin < 3, pxSize = [1 1]; end

  hL = findall( gcf , 'Tag','contours_in_DCMexplorer' );
  if ~isempty( hL ), delete( hL ); end

  if isempty( info ), return; end
  
  allDescriptions = cellfun(@char,{ C.Description },'un',0);
  [~,id] = unique( allDescriptions );
  allDescriptions = allDescriptions( sort(id) );
  
  
  imageUID = info.MediaStorageSOPInstanceUID;
  C = C( strcmp( cellfun(@char,{ C.parentUID },'un',0) , imageUID ) );
  for c = 1:numel(C)
    ith = find( strcmp( allDescriptions , char( C(c).Description ) ) );
    
    hL = line( 'Parent',gca,'XData',NaN,'YData',NaN,'Tag','contours_in_DCMexplorer','linewidth',2,'color',colorith(ith),'Marker','none' );
    XY = bsxfun( @times , C(c).Points/C(c).SubpixelResolution , pxSize(:).' );
    set( hL , 'XData', XY(:,1) , 'YData', XY(:,2) );
    if size( XY , 1 ) <= 3
      set( hL , 'Marker' , 'o' , 'MarkerSize', 6 , 'MarkerFaceColor', get( hL , 'Color' ) );
    end
    if size( XY , 1 ) == 1
      set( hL , 'Color' , [0 0 0] , 'LineWidth' , 1 );
    end
    if ~isempty( strfind( C(c).Description , '_original' ) )
      set( hL , 'LineStyle',':','linewidth',1)
    end
    if ~isempty( strfind( C(c).Description , '_new' ) )
      set( hL , 'LineStyle','--')
    end
  end
  
end

