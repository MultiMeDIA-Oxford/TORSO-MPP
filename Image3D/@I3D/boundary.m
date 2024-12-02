function M = boundary( I , offset )

  if nargin < 2
    offset = 0;
  end

  if  isempty( I.data ), error('the image have to be a non empty image'); end
  if ~isbinary( I )
    error('the image have to be a binary image');
  end

  
  I = cleanout( I , 'labels','info','others','fields','landmarks','meshes','contours');
  T = I.SpatialTransform;
  I.SpatialTransform = eye(4);

  I = crop( I , 1 );
  
  X = I.X; DX = dualVector(X);
  Y = I.Y; DY = dualVector(Y);
  Z = I.Z; DZ = dualVector(Z);
  
  if numel(X) > 1  &&  min( diff( DX ) )/2 <= offset
    warning('I3D:BoundaryOffsetTooLarge','Boundary Offset Too Large, reducing it.' );
    offset = min( diff( DX ) )*0.4;
  end
  if numel(Y) > 1  &&  min( diff( DY ) )/2 <= offset
    warning('I3D:BoundaryOffsetTooLarge','Boundary Offset Too Large, reducing it.' );
    offset = min( diff( DY ) )*0.4;
  end
  if numel(Z) > 1  &&  min( diff( DZ ) )/2 <= offset
    warning('I3D:BoundaryOffsetTooLarge','Boundary Offset Too Large, reducing it.' );
    offset = min( diff( DZ ) )*0.4;
  end

  
  if offset > 0
  
    nX = unique( [ X , DX - offset/2 , DX + offset/2 ] );
    nY = unique( [ Y , DY - offset/2 , DY + offset/2 ] );
    nZ = unique( [ Z , DZ - offset/2 , DZ + offset/2 ] );

    I = ~~at( I , {nX , nY , nZ} ,'nearest' , 'outside_value' , 0 , 'value' );
    I = dilate3d( I );
    
    DX = unique( [ DX  DX-offset  DX+offset ] ); 
    DY = unique( [ DY  DY-offset  DY+offset ] ); 
    DZ = unique( [ DZ  DZ-offset  DZ+offset ] ); 
    
    
    M = boundary3d( I , DX , DY , DZ );
    
  elseif offset == 0
    
    M = boundary3d( ~~I.data , DX , DY , DZ );
    
  elseif offset < 0
    
    error('offset negative not implemented yet');
    
  end

  M = struct( 'vertices' , M.xyz , 'faces' , M.tri );
  M.vertices = transform( M.vertices , T );
  
end
