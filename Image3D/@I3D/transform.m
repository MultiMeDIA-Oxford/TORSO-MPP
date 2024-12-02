function [I,dC_t] = transform( I , varargin )

  if nargin < 2, return; end

  if numel( varargin ) == 1 && isempty( varargin{1} )
    if nargout > 1
      [I,dC_t] = transform( I , minv( I.SpatialTransform ) );
    else
      I = transform( I , minv( I.SpatialTransform ) );
    end
    return;
  end
  
  if numel( varargin ) >= 1
    if nargout > 1
      [M,dM] = maketransform( varargin{:} );
    else
      M = maketransform( varargin{:} );
    end
  else
    M = varargin{1};
    dM = zeros(16,0);
  end

  if numel(M) == 3,
    m= eye(4);
    m(1:3,4)= M(:);  
    M=m;
  end
  if any( size(M) ~= [4 4] ), M(4,4)  = 1;     end
  
  origialSpatialTransform = I.SpatialTransform;

  if max( abs( M(4,:) - [0 0 0 1] )) < 100*eps(1)
    M(4,:) = [0 0 0 1];
  end

  I.SpatialTransform = M*I.SpatialTransform;
  
  if max( abs( I.SpatialTransform(4,:) - [0 0 0 1] )) < 100*eps(1)
    I.SpatialTransform(4,:) = [0 0 0 1];
  end
  
  if ~isequal( size(I.SpatialTransform) , [4 4] )
     error('I3D:InvalidSpatialTransformMatrix','The SpatialTransform has to be an 4x4 matrix');
  end
  if ~isequal( I.SpatialTransform(4,:) , [0 0 0 1] )
     warning('I3D:SpatialTransform','The SpatialTransform is not an homogeneous affine transform.');
  end  

  if ~isempty( I.FIELDS )
    for fn = fieldnames(I.FIELDS)'
      if isa( I.FIELDS.(fn{1}) , 'I3D' ),
        I.FIELDS.(fn{1}).SpatialTransform = M*I.FIELDS.(fn{1}).SpatialTransform;
        if ~isequal( size(I.FIELDS.(fn{1}).SpatialTransform) , [4 4] )
           error('I3D:InvalidSpatialTransformMatrix','In a FIELD ... The SpatialTransform has to be an 4x4 matrix');
        end
        if ~isequal(  I.FIELDS.(fn{1}).SpatialTransform(4,:) , [0 0 0 1] )
           warning('I3D:SpatialTransform','In a FIELD ... The SpatialTransform is not an homogeneous affine transform.');
        end  
      end
    end
  end

  if ~isempty( I.MESHES )
    for m = find( ~cellfun('isempty', I.MESHES ) )
      if isstruct( I.MESHES{m} )
        I.MESHES{m} = TransformMesh( I.MESHES{m} , M );
      else
        I.MESHES{m} = transform( I.MESHES{m} , M );
      end
    end
  end


  if nargout > 1
    dC_t = subsref( I , substruct('.','container') );
    
    [ pt , dC_t.data ] = transform( transform( ndmat_mx(dC_t.X,dC_t.Y,dC_t.Z) , origialSpatialTransform ) , { M , dM } );
    
    dC_t.data = reshape( dC_t.data , [numel(dC_t.X)  numel(dC_t.Y)  numel(dC_t.Z) 1 3 size(dC_t.data,2)] );
  end
  


  if I.isGPU
    %iOM = ( I.SpatialTransform \ eye(4) );
    iOM = inv4x4(I.SpatialTransform);
    I.GPUvars.POINTS_fINTERPOLATION_KERNEL.setConstantMemory( 'fiOM' , single(iOM) );
    I.GPUvars.POINTS_dINTERPOLATION_KERNEL.setConstantMemory( 'diOM' , double(iOM) );
    I.GPUvars.GRID_fINTERPOLATION_KERNEL.setConstantMemory( 'fiOM' , single(iOM) );
    I.GPUvars.GRID_dINTERPOLATION_KERNEL.setConstantMemory( 'diOM' , double(iOM) );
    I.GPUvars.fSpatialTransform = single( I.SpatialTransform );
    I.GPUvars.dSpatialTransform = double( I.SpatialTransform );
  end
  
  
  
end
