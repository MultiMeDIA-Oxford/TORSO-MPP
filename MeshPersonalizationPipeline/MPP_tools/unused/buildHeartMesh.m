function [C,M] = buildHeartMesh( C , prune )

  if nargin < 2, prune = true; end
  
  if prune
    CA = flip( ArrangeContourPairs( flip( C ,1) ) ,1);
    w = ~cellfun('isempty',CA);
    for c = 1:size(CA,2)
      CA( w(:,c) ,c ) = { DistancePolyline2Polyline( CA{w(:,c),c} ) };
    end
    CA( ~w ) = {0};
    CA = cell2mat( CA );
    t = prctile( sum( CA , 1)/2 , 90 );
    [ C{ sum(CA > t,2) > 1 ,:} ] = deal([]);
  end

  M = Contours2Surface_ez( C , 'ulid' , -70 , 'blid' , 15 ,...
    'STIFFNESS',250,'FARTHESTP_RESAMPLING',2,...
    'SMTHDEC_ITER',15,'MAX_DEFORMATION_ITS',200,...
    'FARTERPOINTS', 30 * sum(sum( ~cellfun('isempty',C) )) ,...
    'TARGETREDUCTION',0.70 );

  M = vtkPolyDataConnectivityFilter( M , 'SetExtractionModeToLargestRegion' );
  M = FixFacesOrientation( M );
  
end