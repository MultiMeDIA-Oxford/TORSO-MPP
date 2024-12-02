function HC = contoursFrom( HC , C , override )

  if nargin < 3, override = false; end


  if ischar( C )
    try, C = Loadv( C , C );
    catch, C = Loadv( C );
    end
  end
  
  C( all( cellfun('isempty',C) ,2) ,:) = [];
  
  if size(C,2) == 1, return; end
  C( cellfun('isempty',C(:,1)) ,:) = [];
  if all(all( cellfun('isempty',C(:,2:end)) ) ), return; end
  
  
  for r = 1:size( HC , 1 )
      if isempty( HC{r,1} ), continue; end
    
    s = [];
    if isempty(s), try
      s = cellfun( @(I)I.INFO.MediaStorageSOPInstanceUID , C(:,1) ,'un',0 );
      s = find( strcmp( s , HC{r,1}.INFO.MediaStorageSOPInstanceUID ) );
    end; end
    if numel(s)~=1, s = []; end
    if isempty(s), try
      s  = cellfun( @(I)I.INFO.SeriesInstanceUID , C(:,1) ,'un',0 );
      ss = cellfun( @(I)I.INFO.xZLevel           , C(:,1) );
      s  = find( strcmp( s , HC{r,1}.INFO.SeriesInstanceUID ) & ss == HC{r,1}.INFO.xZLevel );
    end; end
    if numel(s)~=1, s = []; end
    if isempty(s), try
      s  = cellfun( @(I)I.INFO.SeriesInstanceUID , C(:,1) ,'un',0 );
      s  = find( strcmp( s , HC{r,1}.INFO.SeriesInstanceUID ) );
    end; end
    if numel(s)~=1, s = []; end
    if isempty(s), continue; end
  
    conts = cellfun( @double , C(s,2:end) , 'un' , 0 );
    conts = transform( conts , HC{r,1}.SpatialTransform / C{s,1}.SpatialTransform );

    for c = 1:numel(conts)
      if override || size(HC,2) < c+1 || isempty( HC{r,c+1} )
        HC{r,c+1} = conts{c};
      end
    end
  end
  
end
