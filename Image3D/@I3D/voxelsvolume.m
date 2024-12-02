function V = voxelsvolume( I , applyDet )
%
%
%  volume of the voxels grids. it has to be multiplied by det(SpatialTransform)
%
%

  if nargin < 2
    applyDet = false;
  end

  if isfield( I.GRID_PROPERTIES , 'voxelsvolume' )
    V = I.GRID_PROPERTIES.voxelsvolume;
    if applyDet
      V = V * abs( det( I.SpatialTransform(1:3,1:3) ) );
    end
    if isscalar( V ) || isequal( size(V) , [ numel(I.X) numel(I.Y) numel(I.Z) ] )
      return;
    end
  end


  DX = diff( dualVector( I.X ) );
  DY = diff( dualVector( I.Y ) );
  DZ = diff( dualVector( I.Z ) );

  if    all( abs( DX - mean( DX ) ) < 1e-6 )  && ...
        all( abs( DY - mean( DY ) ) < 1e-6 )  && ...
        all( abs( DZ - mean( DZ ) ) < 1e-6 )

    V = mean(DX)*mean(DY)*mean(DZ);

  else

    V = DX;
    V = V(:) * DY;
    V = V(:) * DZ;

    V = reshape( V , size( I , 1:3 ) );

  end

  if applyDet
    V = V * abs( det( I.SpatialTransform(1:3,1:3) ) );
  end
  
end
