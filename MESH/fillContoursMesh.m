function M = fillContoursMesh( C , delta )
if 0

%Boundary 1
ns=150;
t=linspace(0,2*pi,ns);
t=t(1:end-1);
r=6+2.*sin(5*t);
[x,y] = pol2cart(t,r);
z=1/10*x.^2;
V1=[x(:) y(:) z(:)];

%Boundary 2
ns=100;
t=linspace(0,2*pi,ns);
t=t(1:end-1);
[x,y] = pol2cart(t,ones(size(t)));
z=zeros(size(x));
V2=[x(:) y(:)+4 z(:)];

%Boundary 3
ns=75;
t=linspace(0,2*pi,ns);
t=t(1:end-1);
[x,y] = pol2cart(t,2*ones(size(t)));
z=zeros(size(x));
V3=[x(:) y(:)-0.5 z(:)*0];

%Create Euler angles to set directions
% E=[0.25*pi -0.25*pi 0];
% [R,~]=euler2DCM(E); %The true directions for X, Y and Z axis
% 
% V1=(R*V1')'; %Rotate polygon
% V2=(R*V2')'; %Rotate polygon
% V3=(R*V3')'; %Rotate polygon

M = fillContoursMesh( {V1,V2,V3} , 2 );
M = fillContoursMesh( V1 , 2 );



plotMESH( M );
hplot3d( {V1,V2,V3} , '.-r' );
  
%%  
end
  if nargin < 2
    delta = Inf;
  end

  if isstruct( C )
    C.celltype = meshCelltype( C );
    if C.celltype ~= 3, error('only LINE meshes are allowed'); end

    C = mesh2contours( C );
    C = nans2split( C );
  elseif isnumeric( C )
    C = nans2split( C );
  end
  
  if numel( C ) == 1
    if ~isequal( C{1}(1,:) , C{1}(end,:) )
      C{2,1} = [];
    end
  end
  
  
  if numel( C ) > 1

    C( cellfun('isempty',C) ) = [];
    
    nsd = cellfun( @(c)size(c,2) , C );
    if ~all( nsd == nsd(1) ), error('mixed Number of Spatial Dimensions'); end
    nsd = nsd(1);

    if isnan( delta )
      error('NaN delta corresponds to a centered triangulation which is only valid for single curves closed.');
    end
    
    if nsd == 3
      [Z,iZ] = getPlane( cell2mat( C(:) ) );
    elseif nsd == 2
      Z = eye(4); iZ = eye(4);
    else
      error('Number of Spatial Dimensions must be 2 or 3.');
    end

    %clean and open all curves and collect coordinates
    X = [];
    F = [];
    for c = 1:numel(C)
      C{c}( all( ~diff( C{c} , 1 , 1 ) ,2) ,:) = [];
      if isequal( C{c}(1,:) , C{c}(end,:) )
        C{c}(end,:) = [];
      end
      F = [ F ; size(X,1) + [ ( 1:size(C{c},1) ).' , [ 2:size(C{c},1) , 1 ].' ] ];
      X = [ X ; C{c} ];
    end
    X(:,end+1:3) = 0;
    nX = size( X ,1);

    X0 = X;
    X = transform( X , iZ );
  
  elseif ~isnan( delta )
    
    X0 = C{1};
    X  = MeshFlatten( X0 );
    X(end,:) = [];
    X(:,end+1:3) = 0;
    
    nX = size( X ,1);
    F = [ 1:nX ; 2:nX , 1 ].';
    Z = [];
    
  end
  
  if isnan( delta )
    M.xyz = C{1};
    
    M.tri = [ 1:size( M.xyz ,1)-1 ; 2:size( M.xyz ,1) ].';
    
    M.xyz( end+1 ,:) = mean( M.xyz ,1);
    M.tri(:,3) = size( M.xyz ,1);
    
    return;
  end
  
  
  if isempty( delta )
    delta = median( sqrt( sum( diff(X,1,1).^2 ,2) ) );
  end
  if isfinite( delta )
    xs = [ min( X(:,1) ) , max( X(:,1) ) ];
    xs = mean(xs) + ( -ceil( diff(xs)/2/delta + 1 ):ceil( diff(xs)/2/delta + 1 ) )*delta;
    
    delta = delta * sin(2*pi/3);
    ys = [ min( X(:,2) ) , max( X(:,2) ) ];
    ys = mean(ys) + ( -ceil( diff(ys)/2/delta + 2 ):ceil( diff(ys)/2/delta + 2 ) )*delta;
    
    Y = ndmat( ys(1:end-1) , xs ); Y = Y(:,[2,1]);
    Y(1:2:end,1) = Y(1:2:end,1) + mean(diff(xs))/2;
    Y(:,end+1:3) = 0;
  else
    Y = [];
  end
  Y = [ X ; Y ];
%   Y = unique( Y , 'rows','stable' );
  
  
  DT = delaunayTriangulation( Y(:,1) , Y(:,2) , F );
  M.xyz = DT.Points; M.xyz(:,end+1:3) = 0;
  M.tri = DT.ConnectivityList;
  M.tri = M.tri( isInterior(DT) ,:);
  
%   M.xyz( nX+1:end ,:) = NaN;
%   M = MeshRelax( M );
  
  if size( M.xyz ,1) > nX  &&  any( abs( X(:,3) ) > 1e-10 )
    M.xyz( nX+1:end ,:) = InterpolatingSplines( M.xyz( 1:nX ,:) , X , M.xyz( nX+1:end ,:) , 'rlogr' );
  end
%   M.xyz( 1:nX ,:) = Y( 1:nX ,:);
  
  if ~isempty( Z )
    M = transform( M , Z );
  else
    M.xyz = InterpolatingSplines( M.xyz( 1:nX ,:) , X0( 1:nX ,:) , M.xyz , 'r' );
  end
  M.xyz( 1:nX ,:) = X0( 1:nX ,:);

end

