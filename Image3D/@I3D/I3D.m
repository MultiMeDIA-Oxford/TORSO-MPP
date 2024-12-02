function I= I3D( varargin )

  if nargin == 0
    I = I3D(0);
    return;
  end
  
  if numel( varargin ) == 1 && ischar( varargin{1} ) && isdicom( varargin{1} )
    I = I3D( { dicomread( varargin{1} ) , dicominfo( varargin{1} ) } );
    return;
  end
  
  
  if numel( varargin ) == 1 && isstruct( varargin{1} )
    try
      I = orderfields( varargin{1} , {'data','X','Y','Z','T','LABELS','LABELS_INFO','SpatialTransform','ImageTransform','SpatialInterpolation','BoundaryMode','BoundarySize','OutsideValue','DiscreteSpatialStencil','TemporalInterpolation','DiscreteTemporalStencil','LANDMARKS','CONTOURS','MESHES','INFO','OTHERS','FIELDS','GRID_PROPERTIES','POINTER','isGPU','GPUvars'} );
      I = class( I , 'I3D' );
      return;
    end

    S = varargin{1};
    varargin(1) = [];
    
    A = [];
    if      isfield( S , 'SpatialTransform' )
      A = S.SpatialTransform;
    elseif  isfield( S , 'TransformMatrix' )
      A = S.TransformMatrix;
      if isfield( S , 'origin' )
        A = [ A , S.origin(:) ; 0 0 0 1 ];
      else
        A(4,4) = 1;
      end
    end
    if ~isempty( A ), varargin = { 'R' , A , varargin{:} }; end
    
    
    A = [];
    if      isfield( S , 'Z' )
      A = S.X;
    elseif  isfield( S , 'spacing' )
      if isfield( S , 'dim' ), d = S.dim(3);
      else,                    d = size(S.data,3);
      end
      A = ( 0:d-1 ) * S.spacing(3);
    end
    if ~isempty( A ), varargin = { 'Z' , A , varargin{:} }; end
    
    
    A = [];
    if      isfield( S , 'Y' )
      A = S.X;
    elseif  isfield( S , 'spacing' )
      if isfield( S , 'dim' ), d = S.dim(2);
      else,                    d = size(S.data,2);
      end
      A = ( 0:d-1 ) * S.spacing(2);
    end
    if ~isempty( A ), varargin = { 'Y' , A , varargin{:} }; end

    
    A = [];
    if      isfield( S , 'X' )
      A = S.X;
    elseif  isfield( S , 'spacing' )
      if isfield( S , 'dim' ), d = S.dim(1);
      else,                    d = size(S.data,1);
      end
      A = ( 0:d-1 ) * S.spacing(1);
    end
    if ~isempty( A ), varargin = { 'X' , A , varargin{:} }; end    
    
    I = I3D( S.data , varargin{:} );
    return;
  end

  if numel( varargin ) == 1 && iscell( varargin{1} ) && numel( varargin{1} ) == 2 && isnumeric( varargin{1}{1} ) && isstruct( varargin{1}{2} )
    
    I = I3D( permute( varargin{1}{1} , [ 2 1 3:10 ] ) );
    
    info = varargin{1}{2};
    
    %% rotation matrix
    R = reshape( info.ImageOrientationPatient , 3 , 2 );
    R(:,3)= cross( R(:,1), R(:,2) );
    for c=1:3, for it = 1:5, R(:,c) = R(:,c)/sqrt( R(:,c).' * R(:,c) ); end; end
  
    I.SpatialTransform = [ R , info.ImagePositionPatient(:) ; 0 0 0 1 ];
    I.X = ( 0:( double(info.Columns) - 1 ) ) * double( info.PixelSpacing(1) );
    I.Y = ( 0:( double(info.Rows   ) - 1 ) ) * double( info.PixelSpacing(2) );
    I.Z = 0;
    
    
    I.INFO = info;
    
    return;
  end
  
  [varargin,i,XX]= parseargs(varargin,'x' );
  if ~isempty( XX )
    XX = double( XX(:).' );
    if ~issorted(XX), warning('I3D:NotSortedCoordinates','X coordinates are not in increasing `.'); end
  end
  
  [varargin,i,YY]= parseargs(varargin,'y' );
  if ~isempty( YY )
    YY = double( YY(:).' );
    if ~issorted(YY), warning('I3D:NotSortedCoordinates','Y coordinates are not in increasing order.'); end
  end
  
  [varargin,i,ZZ]= parseargs(varargin,'z' );
  if ~isempty( ZZ )
    ZZ = double( ZZ(:).' );
    if ~issorted(ZZ), warning('I3D:NotSortedCoordinates','Z coordinates are not in increasing order.'); end
  end
  
  [varargin,i,TT]= parseargs(varargin,'t' );
  if ~isempty( TT )
    TT = double( TT(:).' );
    if ~issorted(TT), warning('I3D:NotSortedCoordinates','T coordinates are not in increasing order.'); end
  end
  

  [varargin,i,RR]= parseargs(varargin,'spatialtransfoRm' );
  if ~isempty(RR) && ~isequal( size(RR) , [4 4] )
     error('I3D:InvalidSpatialTransformMatrix','The SpatialTransform has to be an 4x4 matrix');
  end
  if ~isempty(RR) && ~isequal( RR(4,:) , [0 0 0 1] )
     warning('I3D:SpatialTransform','The SpatialTransform is not an homogeneous affine transform.');
  end
  
  

  if numel( varargin ) && isa( varargin{1} , 'I3D' )
  
    I = varargin{1};
    
    if ~isempty(XX), I.X = XX; end
    if ~isempty( I.data ) && numel( I.X ) ~= size(I.data,1)  && ~iscell( I.data )
      error('I3D:InvalidDimensions','Different dimensions in X.');
    end

    
    if ~isempty(YY), I.Y = YY; end
    if ~isempty( I.data ) && numel( I.Y ) ~= size(I.data,2)  && ~iscell( I.data )
      error('I3D:InvalidDimensions','Different dimensions in Y.');
    end

    
    if ~isempty(ZZ), I.Z = ZZ; end
    if ~isempty( I.data ) && numel( I.Z ) ~= size(I.data,3)  && ~iscell( I.data )
      error('I3D:InvalidDimensions','Different dimensions in Z.');
    end

    
    if ~isempty(TT), I.T = TT; end
    if ~isempty( I.data ) && numel( I.T ) ~= size(I.data,4)  && ~iscell( I.data )
      error('I3D:InvalidDimensions','Different dimensions in T.');
    end
    
    if ~isempty(RR), I.SpatialTransform = double( RR ); end

    return;

  end
    
  if isempty( varargin )

    data = [];

    if isempty(XX), XX=0; end
    if isempty(YY), YY=0; end
    if isempty(ZZ), ZZ=0; end
    if isempty(TT), TT=0; end

  else

    data = varargin{1};
    if iscell(data) && all( cellfun( @isscalar , data ) )
      data = zeros(data{:});
    end

    if isempty(XX), XX= 0:size(data,1)-1; end
    if isempty(YY), YY= 0:size(data,2)-1; end
    if isempty(ZZ), ZZ= 0:size(data,3)-1; end
    if isempty(TT), TT= 0:size(data,4)-1; end
    
    
    if ~isempty(data) && size(data,1)~=numel(XX), error('I3D:InvalidDimensions','Different dimensions in X.'); end
    if ~isempty(data) && size(data,2)~=numel(YY), error('I3D:InvalidDimensions','Different dimensions in Y.'); end
    if ~isempty(data) && size(data,3)~=numel(ZZ), error('I3D:InvalidDimensions','Different dimensions in Z.'); end
    if ~isempty(data) && size(data,4)~=numel(TT), error('I3D:InvalidDimensions','Different dimensions in T.'); end
    
  end
  
  I.data = data;

  %labels image
%   I.LABELS = zeros([numel(I.X),numel(I.Y),numel(I.Z),numel(I.T)],'uint16');
  I.LABELS = zeros([0 0 0 0],'uint16');

  % labels info
  I.LABELS_INFO = struct('description',{},'alpha',{},'color',{},'state',{});


  if isempty(RR), RR = eye(4); end
  I.SpatialTransform = RR;


  % contrast & brigthness control. It only work at visualization purposes
  if ~any( I.data(:) ) || islogical( I.data )
    I.ImageTransform   = [ 0 0 ; 1 1 ];
  else
    try
      I.ImageTransform   = [ double( prctile(         I.data(:)           ,1)) 0 ; double( prctile(         I.data(:)           ,99))  1 ];
    catch, try
      I.ImageTransform   = [         prctile( double( I.data(:)          ),1)  0 ;         prctile( double( I.data(:)          ),99)   1 ];
    catch, try
      I.ImageTransform   = [ double( prctile(         I.data(1:1000:end)  ,1)) 0 ; double( prctile(         I.data(1:1000:end)  ,99))  1 ];
    catch,
      I.ImageTransform   = [         prctile( double( I.data(1:1000:end) ),1)  0 ;         prctile( double( I.data(1:1000:end) ),99)   1 ];
    end; end; end
  end

  
  I.X = XX;
  I.Y = YY;
  I.Z = ZZ;
  I.T = TT;

  % interpolation type for 3D coordinates access
  I.SpatialInterpolation = 'linear';
  I.BoundaryMode = 'value';
  I.BoundarySize = 0;
  if size(I.X) > 1, I.BoundarySize = I.BoundarySize + I.X(2)-I.X(1); end
  if size(I.Y) > 1, I.BoundarySize = I.BoundarySize + I.Y(2)-I.Y(1); end
  if size(I.Z) > 1, I.BoundarySize = I.BoundarySize + I.Z(2)-I.Z(1); end
  I.OutsideValue = NaN;

  I.DiscreteSpatialStencil = 'subdifferential';
  I.TemporalInterpolation = 'constant';

  I.DiscreteTemporalStencil    = 'forward';  

  I.LANDMARKS = [];
  I.CONTOURS  = struct();
  I.MESHES    = {};

  I.INFO   = [];
  I.OTHERS = [];
  I.FIELDS = [];
  I.GRID_PROPERTIES = [];
  I.POINTER = {};
  
  I.isGPU = false;
	I.GPUvars = struct([]);

  if isempty( I.data )
    I.POINTER = {''};
  elseif ~any( I.data(:) ) && isnumeric( I.data )
    sz   = uneval(  size( I.data ) );
    type = uneval( class( I.data ) );
    I.POINTER = { '' ; { [ '@(X) zeros(' sz ',' type ')' ] } };
  end

  
  try,
    I = orderfields( I , {'data','X','Y','Z','T','LABELS','LABELS_INFO','SpatialTransform','ImageTransform','SpatialInterpolation','BoundaryMode','BoundarySize','OutsideValue','DiscreteSpatialStencil','TemporalInterpolation','DiscreteTemporalStencil','LANDMARKS','CONTOURS','MESHES','INFO','OTHERS','FIELDS','GRID_PROPERTIES','POINTER','isGPU','GPUvars'} );
  end

    
    
  I= class(I,'I3D');

end
