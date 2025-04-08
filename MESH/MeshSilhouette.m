function S_ = MeshSilhouette( M , CAM , FeaturesAngle , varargin )

  if nargin < 2
    CAM = '';
  end
  if nargin < 3 || isempty( FeaturesAngle )
    FeaturesAngle = 0;
  end

  if ischar( M )
    [p,f,e] = fileparts( M ); if isempty( p ), p = pwd; end
    M = read_VTK( M );
    if isempty( CAM ), CAM = fullfile( p , 'CAMERA.pvcc' ); end
    S = getSilhouette( M , CAM , FeaturesAngle );
    write_VTK_UNSTRUCTURED_GRID( S , fullfile( p , [ f , '_silhouette.vtk' ] ) );
    return;
  end
  
  axesHandle = [];
  if ishandle( M )
    axesHandle = ancestor( M , 'axes' );
    M = Mesh( M );
    if isempty( CAM ), CAM = axesHandle; end
  end
  
  if ischar( CAM )

    CAM = xml_read( CAM );
    for p = 1:numel( CAM.Proxy.Property )
      Aname  = CAM.Proxy.Property(p).ATTRIBUTE.name;
      Avalue = zeros( 1 , numel( CAM.Proxy.Property(p).Element ) );
      for e = 1:numel( CAM.Proxy.Property(p).Element )
        Avalue(e) = CAM.Proxy.Property(p).Element(e).ATTRIBUTE(1).value;
      end
      CAM.(Aname) = Avalue;
    end
    CAM = rmfield( CAM ,'ATTRIBUTE' );
    CAM = rmfield( CAM ,'Proxy');
  
  elseif ishandle( CAM ) && strcmp( get(CAM,'Type') , 'axes')
    
    hCAM = CAM;
    CAM = struct();
    CAM.CameraParallelProjection  = strcmp( get( hCAM , 'Projection' ) , 'orthographic' );
    CAM.CameraFocalPoint          = get( hCAM , 'CameraTarget' );
    CAM.CameraPosition            = get( hCAM , 'CameraPosition' );
    
  else
    error('invalid CAMERA');
  end

  F = [];
  
  B = boundary( M.tri );
  F = [ F ; B ];
  
  N = normals( M.xyz , M.tri );

  if CAM.CameraParallelProjection
    
    viewDIR = CAM.CameraFocalPoint - CAM.CameraPosition;
    angles  = N * viewDIR(:);
    
  else
    
    FaceCenters = ( M.xyz( M.tri(:,1) ,:) + M.xyz( M.tri(:,2) ,:) + M.xyz( M.tri(:,3) ,:) )/3;
    viewDIR = bsxfun( @minus , FaceCenters , CAM.CameraPosition );
    angles  = sum( N .* viewDIR , 2 );
    
  end

  angles = angles < 0;
  if sum( angles ) > numel( angles )/2
    angles = ~angles;
  end
  B = boundary( M.tri( angles ,:) );
  F = [ F ; B ];


  if FeaturesAngle > 0
    [E,~,A] = meshCellsContact( M );
    
    B = E( A >= FeaturesAngle , :);
    F = [ F ; B ];
  end

  if ~isempty( axesHandle )
    S = patch( 'Vertices',double(M.xyz),'Parent',axesHandle,'EdgeColor','k','Faces', F , varargin{:} );
    set( S , 'UserData', CAM );
  else
    S = struct('xyz',double(M.xyz),'tri',int32(F),'celltype',3);
  end
  
  if nargout, S_ = S; end
end
function B = boundary( T )
  E = [ T(:,[1,2]) ; T(:,[2,3]) ; T(:,[1,3]) ];
  E = sort( E ,2);
  [~,b,c] = unique( E(:,1) + 1i*E(:,2) );
  B = E( b( accumarray( c , 1 ) == 1 ),:);
end
function N = normals( V , F )
  P1 = V( F(:,1) ,:);
  P2 = V( F(:,2) ,:);
  P3 = V( F(:,3) ,:);
  
  N = cross2( P3 - P1 , P2 - P1 );
end
function r = cross2(a,b)
  % Optimizes r = cross(a,b,2), that is it computes cross products per row
  % Faster than cross if I know that I'm calling it correctly
  r = [ a(:,2).*b(:,3) - a(:,3).*b(:,2) ,...
        a(:,3).*b(:,1) - a(:,1).*b(:,3) ,...
        a(:,1).*b(:,2) - a(:,2).*b(:,1) ];
end
