function I = cleanout( I , varargin )

  [varargin,warns] = parseargs( varargin , 'WARNINGs','$FORCE$', true );


  noclean_fields_idx = cellfun( @(v) strncmpi(v,'-fields.',8) , varargin );
  noclean_fields = varargin( noclean_fields_idx );
  noclean_fields = cellfun( @(v) v(9:end) , noclean_fields , 'UniformOutput', false );
  varargin( noclean_fields_idx ) = [];

  
  varargin = cellfun( @(v) lower(v), varargin , 'UniformOutput',false );

  noclean_idx = cellfun( @(v) strcmp(v(1),'-') , varargin );
  noclean = varargin( noclean_idx );
  noclean = cellfun( @(v) v(2:end) , noclean , 'uniformoutput',false );
  varargin( noclean_idx ) = [];
  
  if isempty( varargin )
    varargin = { 'labels','info','others','fields','landmarks','contours','meshes','pointer','grid_properties' };
  end
  
  varargin = setdiff( varargin , noclean );

  
  if any( strcmpi( 'pointer' , varargin ) )
    I = remove_dereference( I );
  end
  
  if any( strcmpi( 'data' , varargin ) )
    if warns  &&  ~isempty( I.data )  && any( I.data(:) )
      warning('I3D:cleanout','I.data will be removed.' );
    end
    I = DATA_action( I , '@(X) []' );
  end
  
  if any( strcmpi( 'labels' , varargin ) )
    if warns  &&  ~isempty( I.LABELS )  &&  any( I.LABELS(:) )
      warning('I3D:cleanout','I.LABELS will be removed.' );
    end
    I.LABELS = [];

    if warns  &&  ~isempty( I.LABELS_INFO )
      warning('I3D:cleanout','I.LABELS_INFO will be removed.' );
    end
    I.LABELS_INFO = struct('description',{},'alpha',{},'color',{},'state',{});
  end

  if any( strcmpi( 'others' , varargin ) )
    if warns  &&  ~isempty( I.OTHERS )   &&  ~isempty( fieldnames( I.OTHERS ) )
      warning('I3D:cleanout','I.OTHERS will be removed.' );
    end
    I.OTHERS  = [];
  end
  
  if any( strcmpi( 'info' , varargin ) )
    if warns  &&  ~isempty( I.INFO )   &&  ~isempty( fieldnames( I.INFO ) )
      warning('I3D:cleanout','I.INFO will be removed.' );
    end
    I.INFO   = [];
  end
  
  if any( strcmpi( 'fields' , varargin ) ) && ~isempty( I.FIELDS ) && ~isempty( fieldnames( I.FIELDS ) )
    fieldsnames = setdiff( fieldnames( I.FIELDS ) , noclean_fields );
    
    if warns  &&  ~isempty( fieldsnames )
      warning('I3D:cleanout','I.FIELDS will be removed.' );
    end
    
    for f = fieldsnames(:)'
      I.FIELDS = rmfield( I.FIELDS , f{1} );
    end
    
    if isstruct( I.FIELDS )  && numel( fieldnames( I.FIELDS ) ) == 0
      I.FIELDS = [];
    end
  end

  if any( strcmpi( 'landmarks' , varargin ) )
    if warns  &&  ~isempty( I.LANDMARKS )
      warning('I3D:cleanout','I.LANDMARKS will be removed.' );
    end
    I.LANDMARKS = [];
  end

  if any( strcmpi( 'contours' , varargin ) )
    if warns  &&  ~isempty( fieldnames( I.CONTOURS ) )
      warning('I3D:cleanout','I.CONTOURS will be removed.' );
    end
    I.CONTOURS = struct();
  end
  
  if any( strcmpi( 'meshes' , varargin ) )
    if warns  &&  ~isempty( I.MESHES )
      warning('I3D:cleanout','I.MESHES will be removed.' );
    end
    I.MESHES = {};
  end

  if any( strcmpi( 'grid_properties' , varargin ) )
    I.GRID_PROPERTIES = [];
  end
  
end
