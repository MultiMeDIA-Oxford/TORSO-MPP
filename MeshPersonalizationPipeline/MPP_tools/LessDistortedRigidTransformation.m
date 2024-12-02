function TS = LessDistortedRigidTransformation( A , B )
% 
% return transformations to apply to B such that look like A
% 
% 
% 
  if nargin < 2

    TS = A(:);

  else
    
    for r = 1:size( B , 1 )
      TS{r,1} = [];
      if isempty( B{r,1} ), TS{r,1} = eye(4); continue; end
      
      try
        s = strcmp( cellfun(@(I)I.INFO.MediaStorageSOPInstanceUID , A(:,1) ,'un',0) , B{r,1}.INFO.MediaStorageSOPInstanceUID );
        s = find( s ,1);
        if isempty( s ), TS{r,1} = eye(4); continue; end
        
%         if isequal( A{s,1}.data(:,:,:,1,1) , B{r,1}.data(:,:,:,1,1) )
          A{s,1} = A{s,1}.coords2matrix;
          B{r,1} = B{r,1}.coords2matrix;
%         else
%           s = -1;
%         end
        
        TS{r,1} = A{s,1}.SpatialTransform / B{r,1}.SpatialTransform;
      catch LE
        error('revisar este caso!!');
      end
    end
    
  end
  
  w = ~cellfun('isempty',TS);  [TS{~w}] = deal( eye(4) );
  
  T0 = TS{ find(w,1) };
  TS = transform( TS , minv( T0 ) );
  
  for kmit = 1:5
    KM = real( KarcherMean( cat(3,TS{w}) , @Exp_SE , @Log_SE , 'L' ) ); KM(4,:) = [0,0,0,1];
    KM = minv( KM ); KM(4,:) = [0,0,0,1];
    TS = transform( TS , KM );
  end
  
  TS = transform( TS , T0 );

end
