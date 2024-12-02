function I = loadobj(I)

  if isa(I,'struct')
    I = renamefield(I,'spatial_transform','SpatialTransform');
    I = renamefield(I,'image_transform','ImageTransform');
    I = renamefield(I,'info','INFO');
    if isfield( I ,'Dx' ), I = rmfield( I , 'Dx' );  end
    if isfield( I ,'Dy' ), I = rmfield( I , 'Dy' );  end
    if isfield( I ,'Dz' ), I = rmfield( I , 'Dz' );  end
    if isfield( I ,'Dt' ), I = rmfield( I , 'Dt' );  end


    if ~isfield( I ,'OTHERS' )
      I.OTHERS= [];
    end

    if ~isfield( I ,'INFO' )
      I.INFO= [];
    end

    if ~isfield( I ,'FIELDS' )
      I.FIELDS= [];
    end

    if ~isfield( I ,'GRID_PROPERTIES' )
      I.GRID_PROPERTIES = [];
    end
    
  %   if ~isfield( I ,'DeformationField' ) || ~iscell( I.DeformationField )
  %     I.DeformationField{ numel(I.T) , numel(I.T) } = [];
  %   end
  %   if ~isfield( I ,'invDeformationField' ) || ~iscell( I.invDeformationField )
  %     I.invDeformationField{ numel(I.T) , numel(I.T) } = [];
  %   end
    if isfield( I ,    'DeformationField' ), I = rmfield( I ,    'DeformationField' ); end
    if isfield( I , 'invDeformationField' ), I = rmfield( I , 'invDeformationField' ); end

    if ~isfield( I ,'LANDMARKS' )
      I.LANDMARKS = [];
    end

    if ~isfield( I ,'CONTOURS' ) || ~isstruct( I.CONTOURS )
      I.CONTOURS = struct();
    end
    
    if ~isfield( I ,'MESHES' )
      I.MESHES = {};
    end

    if ~isfield( I ,'BoundaryMode' )
      I.BoundaryMode = 'value';
    end

    if ~isfield( I ,'BoundarySize' )
      I.BoundarySize = 0;
    end

    if ~isfield( I ,'OutsideValue' )
      I.OutsideValue = NaN;
    end

    if ~isfield( I ,'DiscreteSpatialStencil' )
      I.DiscreteSpatialStencil = 'subdifferential';
    end
    
    if ~isfield( I ,'TemporalInterpolation' )
      if isfield( I , 'TimeInterpolation' )
        I.TemporalInterpolation = I.TimeInterpolation;
        I = rmfield( I , 'TimeInterpolation' );
      else
        I.TemporalInterpolation = 'constant';
      end
    end

    if ~isfield( I ,'DiscreteTemporalStencil' )
      I.DiscreteTemporalStencil = 'forward';
    end

    if ~isfield( I ,'isGPU' )
      I.isGPU = false;
    end

    if ~isfield( I ,'GPUvars' )
      I.GPUvars = struct([]);
    end
    
    if ~isfield( I ,'POINTER' )
      I.POINTER = {};
    end

    try,
      I = orderfields( I , {'data','X','Y','Z','T','LABELS','LABELS_INFO','SpatialTransform','ImageTransform','SpatialInterpolation','BoundaryMode','BoundarySize','OutsideValue','DiscreteSpatialStencil','TemporalInterpolation','DiscreteTemporalStencil','LANDMARKS','CONTOURS','MESHES','INFO','OTHERS','FIELDS','GRID_PROPERTIES','POINTER','isGPU','GPUvars'} );
    end

  end

  if ~isfield( I ,'CONTOURS' ) || ~isstruct( I.CONTOURS )
    I.CONTOURS = struct();
  end
  
  if isa( I.LABELS , 'uint8' )
    I.LABELS = uint16( I.LABELS );
  end
  
  if isempty( I.LABELS )
    I.LABELS = uint16([]);
  end
  
  if ~isa( I.LABELS , 'uint16' )
    warning('I3D:LABELS_class','LABELS are not uint16.');
  end
  

  I.X = double( I.X(:).' );
  I.Y = double( I.Y(:).' );
  I.Z = double( I.Z(:).' );
  I.T = double( I.T(:).' );
  
  I.ImageTransform( isinf( I.ImageTransform(:,1) ) , : ) = [];
  I.ImageTransform = double( I.ImageTransform );
  
  if ~isa(I,'I3D');
    I = class(I,'I3D');
  end

  
  if strcmp( I.TemporalInterpolation , 'nearest' )
    I.TemporalInterpolation = 'constant';
  end
  
  
  if ~issorted(I.X), warning('I3D:NotSortedCoordinates','X coordinates are not in increasing order.'); end
  if ~issorted(I.Y), warning('I3D:NotSortedCoordinates','Y coordinates are not in increasing order.'); end
  if ~issorted(I.Z), warning('I3D:NotSortedCoordinates','Z coordinates are not in increasing order.'); end
  if ~issorted(I.T), warning('I3D:NotSortedCoordinates','T coordinates are not in increasing order.'); end
  if ~isequal( I.SpatialTransform(4,:) , [0 0 0 1] )
     warning('I3D:SpatialTransform','The SpatialTransform is not an homogeneous affine transform.');
  end  
  
  

  function s = renamefield(s,old_name,new_name)
    fns = fieldnames( s );
    i = find( strcmp( fns , old_name ) );

    if ~isempty(i)
      s.(new_name) = s.(old_name);
      s = rmfield(s,old_name);
    end
  end

end

