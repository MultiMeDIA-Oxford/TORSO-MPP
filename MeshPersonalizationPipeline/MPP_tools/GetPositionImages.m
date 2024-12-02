function PositionList = GetPositionImages( D )

  Pat1 = fieldnames( D );
  Pat1 = Pat1{1};
  D = DCMselect( D , @(i,f)isequal( f{1} , Pat1 ) && prod( i.xSize ) && isempty( regexp( i.SeriesDescription , 'Molli' ) ) && isempty( regexpi( i.SeriesDescription , 'tagging' ) )  );

  
  IMs = DCMgetimages( D );

  PositionList  = cat(1,IMs.LOCATIONS);
  PositionList(:,6) = [];
  [~,ids] = unique( arrayfun( @(r)[ PositionList{r,:} ] , ( 1:size(PositionList,1) ).' , 'Un',0 ) , 'first' );
  PositionList = PositionList( sort( ids ) , : );

  kpfields = @(s,fs)rmfield( s , setdiff( fieldnames(s) , fs ) );
  for i = 1:size( PositionList , 1 )
    DIC = getfield( D , PositionList{i,1:5} );
    

%     I = 0; nI = 0;
%     for f = fieldnames( DIC )', f = f{1};
%       try
%         H = kpfields( DICOMxinfo( DIC.(f).zFileName ) , {'MediaStorageSOPInstanceUID','SeriesInstanceUID','SeriesDescription','PatientName','PatientID''PatientBirthDate','PatientSex','PatientAge','PatientSize','PatientWeight','SequenceName','PatientPosition','SeriesNumber','ImagePositionPatient','ImageOrientationPatient','SliceLocation','PixelSpacing','xDirname','xFilename','xPatientName','xDatenum','xSize','xSpatialTransform'} );
%         I = I + double( dicomread( DIC.(f).zFileName ) );
%         nI = nI + 1;
%       end
%     end
%     I = I / nI;

    I = [];
    if isempty(I), try, I = DIC.IMAGE_001.zDATA; end; end
    if isempty(I), try, I = DIC.IMAGE_001.DATA;  end; end
    H = DIC.IMAGE_001.info;
    H = kpfields( H , {'MediaStorageSOPInstanceUID','SeriesInstanceUID','SeriesDescription','PatientName','PatientID''PatientBirthDate','PatientSex','PatientAge','PatientSize','PatientWeight','SequenceName','PatientPosition','SeriesNumber','ImagePositionPatient','ImageOrientationPatient','SliceLocation','PixelSpacing','xDirname','xFilename','xPatientName','xDatenum','xSize','xSpatialTransform'} );

    PositionList{i,6} = I;
    PositionList{i,7} = H;
    
    
  end

  PositionList = PositionList(:,[6 7]);
  
end

