%% Torso Re-contouring

BS  = Loadv( 'BS' , 'BS' );
BC  = contoursFrom( BS , 'BC'  , true );
BC0 = contoursFrom( BS , 'BC0' , true );

img_cls = { 'CINE_segmented_LAX_2Ch', 'CINE_segmented_SAX', 'DefineLongaxis_3Ch_4Ch_2Ch', 'Define_SAX', 'Localizer' };
idx = find( cellfun( @(I) isa(I,'I3D') && isstruct(I.INFO) && isfield(I.INFO,'SeriesDescription') && any( cellfun( @(C) strncmpi( I.INFO.SeriesDescription, C, length(C) ), img_cls ) ) , BS(:,1) ) );
BC(idx,2) = BC0(idx,2);

Save( 'BC.mat' , 'BC' );
clear BS BC BC0 img_cls idx;