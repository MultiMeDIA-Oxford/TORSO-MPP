function iseq = isequalcontainer( A , B )

  iseq = false;
  
  if ~isa(A,'I3D')  ||  ~isa(B,'I3D'), return; end
  
  if ~isequal( A.T , B.T ), return; end

  if numel( A.X ) ~= numel( B.X ), return; end
  if numel( A.Y ) ~= numel( B.Y ), return; end
  if numel( A.Z ) ~= numel( B.Z ), return; end

  
  xA = transform( ndmat( A.X(:) , A.Y(1) , A.Z(1) ) , A.SpatialTransform );
  xB = transform( ndmat( B.X(:) , B.Y(1) , B.Z(1) ) , A.SpatialTransform );
  if maxnorm( xA - xB ) > 1e-10 , return; end

  yA = transform( ndmat( A.X(1) , A.Y(:) , A.Z(1) ) , A.SpatialTransform );
  yB = transform( ndmat( B.X(1) , B.Y(:) , B.Z(1) ) , A.SpatialTransform );
  if maxnorm( yA - yB ) > 1e-10 , return; end

  
  zA = transform( ndmat( A.X(1) , A.Y(1) , A.Z(:) ) , A.SpatialTransform );
  zB = transform( ndmat( B.X(1) , B.Y(1) , B.Z(:) ) , A.SpatialTransform );
  if maxnorm( zA - zB ) > 1e-10 , return; end
  
  
  iseq = true;

end
