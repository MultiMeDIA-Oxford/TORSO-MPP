function M_ = isosurface( I , value , varargin )
% 
% S = I3D('X',linspace(-10,10,120),'Y',linspace(-10,10,120),'Z',linspace(-10,10,120));
% S.data(:) = sqrt( sum( bsxfun(@times,S.XYZ,[1 1 0]).^2 , 2 ) );
% M = isosurface( S , 6 ,'remesh',100,'edgelength', 0.5 , 'maxsmooth',0.002 );
% plotMESH(M)
% 


  sz = size(I);
  if max(sz(4:end)) > 1
    error('I3D:IsosurfaceNoScalar','Only for scalar images of 1 time');
  end

  if nargin < 2 || isempty(value)
    value = isovalue( double(I.data(:)) );
  else
    if ischar( value )
      I.data = I.LABELS == str2double(value);
      value = 0.25;
    end
  end
  I.data = double(I.data);
  I = cleanout( I , 'labels','info','others','fields','landmarks','meshes','contours' );
  

  T = I.SpatialTransform;
  I.SpatialTransform = eye(4);
  
  
  [varargin,largest   ] = parseargs(varargin,'Largest','$FORCE$',1);
  [varargin,i,remesh  ] = parseargs(varargin,'remesh','$DEFS$',0);
  [varargin,i,elen    ] = parseargs(varargin,'EdgeLength','$DEFS$',[]);
  [varargin,i,resamp  ] = parseargs(varargin,'Resample','$DEFS$',[]);

  if ~isempty( resamp )
    Io = I;
    I = resample( I , resamp );
  end
  
  
  if isempty( which('vtkCleanPolyData') ) || isempty( which('DeletePoints.m') ) 

    M = isosurface( I.data , value );
    M.vertices = M.vertices(:,[2 1 3]);
    remesh = 0;

  else

    try
      M = vtkContour( I.data , value );
    catch
      M = isosurface( permute(I.data,[2 1 3]) , value );
      M = struct('xyz',M.vertices,'tri',M.faces);
    end

    M = CleanMesh( M );

    if largest
      M = vtkPolyDataConnectivityFilter( M , 'SetExtractionModeToLargestRegion',[],'ColorRegionsOff',[]);

      M = CleanMesh( M );

    end
    
    M = struct( 'vertices' , M.xyz , 'faces' , M.tri );

  end
  
  M.vertices(:,1) = Interp1D( I.X(:) , (1:numel(I.X))' , M.vertices(:,1) ,'linear' );
  M.vertices(:,2) = Interp1D( I.Y(:) , (1:numel(I.Y))' , M.vertices(:,2) ,'linear' );
  M.vertices(:,3) = Interp1D( I.Z(:) , (1:numel(I.Z))' , M.vertices(:,3) ,'linear' );
  

  if remesh > 0
    if ~isempty( resamp ), I = Io; end

    xyz = min( M.vertices , [] , 1 );
    id1 = max( [ val2ind( I.X , xyz(1) , 'sorted' ) , ...
                 val2ind( I.Y , xyz(2) , 'sorted' ) , ...
                 val2ind( I.Z , xyz(3) , 'sorted' ) ] - 2 , 1 );

    xyz = max( M.vertices , [] , 1 );
    id2 = min( [ val2ind( I.X , xyz(1) , 'sorted' ) , ...
                 val2ind( I.Y , xyz(2) , 'sorted' ) , ...
                 val2ind( I.Z , xyz(3) , 'sorted' ) ] + 2 , size( I , 1:3 ) );

    I.data = I.data( id1(1):id2(1) , id1(2):id2(2) , id1(3):id2(3) , :,:,:,: );
    I.X    = I.X( id1(1):id2(1) );
    I.Y    = I.Y( id1(2):id2(2) );
    I.Z    = I.Z( id1(3):id2(3) );
    I.data = I.data - value;
    
    M = RemeshOnSurface( M , I , 'EdgeLength' , elen , 'maxIT' , remesh , varargin{:} );

    M = struct( 'vertices' , M.xyz , 'faces' , M.tri );
  end
  
  
  M.vertices = transform( M.vertices , T );
  
  if nargout == 0
    newplot;
    patch( 'vertices', M.vertices,'faces',M.faces,'facecolor',[0.5 0.5 0.7],'edgecolor',[0.2 0.2 0.2],varargin{:});
    if ~ishold, view(3); axis('equal'); end
  else
    M_ = M;
  end
    
  
  

  function val = isovalue(data)
    [n x] = hist(data,100);

    % remove large first max value
    pos = find( n==max(n) );
    pos = pos(1);
    q = max( n(1:2) );
    if pos<=2 && q/(sum(n)/length(n)) > 10
      n = n(3:end); 
      x = x(3:end);
    end

    % get value of middle bar of non-small values
    pos = find(n<max(n)/50);
    if length(pos) < 90
      x(pos) = [];
    end
    val = x(floor(length(x)/2));
  end

end
