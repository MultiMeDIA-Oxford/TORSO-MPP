function [HS,O] = cleanoutHeartSlices( HS )

  O = HS;

  mppOption CLEANOUT_HSs true;
  if ~CLEANOUT_HSs, return; end

  for r = 1:size(HS,1)
    if isempty(HS{r,1}), continue; end
    HS{r,1} = cleanout( HS{r,1} , ...
        'labels','others','fields','landmarks','contours','meshes','pointer','grid_properties' );
    HS{r,1}.data = [];
    
    HS{r,1}.INFO = struct( 'MediaStorageSOPInstanceUID'  , DICOMxinfo( HS{r,1}.INFO , 'MediaStorageSOPInstanceUID' ) ,...
                           'SeriesInstanceUID'           , DICOMxinfo( HS{r,1}.INFO , 'SeriesInstanceUID' ) ,...
                           'xZLevel'                     , DICOMxinfo( HS{r,1}.INFO , 'xZLevel' ) );
  end

end
