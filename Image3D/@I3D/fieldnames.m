function o = fieldnames( I )

  o = { 'X'     'Y'      'Z'     'T' ...
        'DX'    'DY'     'DZ'        ...
        'deltaX' 'deltaY' 'deltaZ' 'deltaT' ...
        'XX'    'YY'     'ZZ'        ...
        'CXX'   'CYY'    'CZZ'       ...
        'DXX'   'DYY'    'DZZ'       ...
        'DCXX'  'DCYY'   'DCZZ'      ...
        'XYZ'   'XYZh'               ...
        'CXYZ'  'CXYZh'              ...
        'GRID'  'GRIDh'              ...
        'DXYZ'  'DGRID' 'DCXYZ'      ...
        'IJK'                        ...
        'ID' 'IDgrid'                ...
        'IDENTITY'                   ...
        'data'                       ...
        'SpatialTransform'           ... 
        'ImageTransform'             ...
        'SpatialInterpolation'       ...
        'TemporalInterpolation'      ...
        'BoundaryMode'               ...
        'BoundarySize'               ...
        'OutsideValue'               ...
        'DiscreteTemporalStencil'    ...
        'DiscreteSpatialStencil'     ...
        'INFO'                       ...
        'OTHERS'                     ...
        'FIELDS'                     ...
        'GRID_PROPERTIES'            ...
        'LANDMARKS'                  ...
        'LANDMARKSlocal'             ...
        'CONTOURS'                   ...
        'MESHES'                     ...
        'L' 'LabelsAsData' 'LABELS'  'LabelsInfo'  ...
        'isGPU'                      ...
      };

      
  if ~isempty( I.INFO ) &&  isstruct( I.INFO )
    o = [ o cellfun( @(x) ['INFO.' x] , fieldnames( I.INFO )' ,'uniformOutput', false ) ];
  end

  if ~isempty( I.OTHERS ) &&  isstruct( I.OTHERS )
    o = [ o cellfun( @(x) ['OTHERS.' x] , fieldnames( I.OTHERS )' ,'uniformOutput', false ) ];
  end

  if ~isempty( I.FIELDS	 )
    o = [ o cellfun( @(x) ['FIELDS.' x] , fieldnames( I.FIELDS )' ,'uniformOutput', false ) ];
    o = [ o cellfun( @(x) ['F.'      x] , fieldnames( I.FIELDS )' ,'uniformOutput', false ) ];
    o = [ o cellfun( @(x) ['f.'      x] , fieldnames( I.FIELDS )' ,'uniformOutput', false ) ];
  end
  
  if ~isempty( fieldnames( I.CONTOURS	) )
    o = [ o , cellfun( @(x) ['CONTOURS.' x] , fieldnames( I.CONTOURS )' ,'uniformOutput', false ) ];
  end
  
end

