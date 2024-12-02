function [ xyz , Id , abc ] = randOnMesh( M , uv , T )
try, usingMESHES(); end

if 0
  
  model = @(varargin)HANDS(varargin{:});
  M = model( [-1,-1,2,-1,-1] );
  T = model( 0 );
  
  
  uv = rand(2, size(M.tri,2)-1 );

  %on template coords, all result in the same points
  randOnMesh( M , uv , T )
  T.prior = randOnMesh( T );
  randOnMesh( M , uv , T )
  randOnMesh( M , uv , T.prior )
  randOnMesh( M , uv , randOnMesh( T ) )
  randOnMesh( struct('xyz',M.xyz,'tri',M.tri,'prior',T.prior) , uv )

  [~,Id,abc] = randOnMesh( M , uv , T );
  xyz = 0; for c = 1:size( abc ,2), xyz = xyz + bsxfun( @times , abc(:,c) , M.xyz( M.tri(Id,c),:) ); end; xyz
  
  [~,abc] = randOnMesh( M , uv , T );
  xyz = 0; for c = 1:size( abc ,2), xyz = xyz + bsxfun( @times , mod( abc(:,c) , 1 ) , M.xyz( M.tri(floor(abc(:,1)),c),:) ); end; xyz



  %without template, on native coords
  randOnMesh( M , uv )
  randOnMesh( M , uv , randOnMesh( M )  )
  randOnMesh( struct('xyz',M.xyz,'tri',M.tri,'prior',randOnMesh( M ) ) , uv )
  [~,abc] = randOnMesh( M , uv );
  xyz = 0; for c = 1:size( abc ,2), xyz = xyz + bsxfun( @times , mod( abc(:,c) , 1 ) , M.xyz( M.tri(floor(abc(:,1)),c),:) ); end; xyz
  %all result in the same points

  %
  M = model( [3,3,3,-3,3] ); plotMESH( M )
  u = linspace( 0 , 1 , 200 ).';
  plot3d( randOnMesh( M , u ) ,'.' )
  hplot3d( randOnMesh( M , u , T ) ,'xr' );
  hplot3d( randOnMesh( M , Interp1D( randOnMesh( T ) , randOnMesh( M ) , u ) , T ) ,'or' );

  
  %relation between uniform sampling on T and on M
  M = model( [-100,-100,200,-1,-1] );
  plot( randOnMesh( T ) , randOnMesh( M ) , '.-' ); axis equal
  u = linspace(0,1,51);
  vline( u ,'-')
  hline( Interp1D( randOnMesh( M ) , randOnMesh( T ) , u ) ,'-r');
  
  
end




  if nargin < 3, T = M; end
  if      isstruct( T ) && isfield( T , 'prior' )
    E = T.prior;
  elseif  isnumeric( T )
    E = T;
  elseif  size( T.tri ,2) == 2   %for a polyline case of a bag of segments
    E = sqrt( sum( ( T.xyz( T.tri(:,2) ,: ) - T.xyz( T.tri(:,1) ,: ) ).^2 ,2) );
    E = [ 0 ; cumsum( E ) ];
    E = E / E(end);
  elseif  size( T.tri ,2) == 3   %for a triangle mesh case
    E = cross2( T.xyz(T.tri(:,2),:) - T.xyz(T.tri(:,1),:) , T.xyz(T.tri(:,3),:) - T.xyz(T.tri(:,1),:) );
    E = sqrt( sum( E.^2 ,2) );
    E = [ 0 ; cumsum( E ) ];
    E = E / E(end);
  end
  
  if nargin < 2
    xyz = E;
    return;
  end

  if numel( uv ) == 1   &&   uv >= 2   &&   ~mod( uv , 1 ) || uv < 0
    uv = rand( abs(uv) , size( M.tri ,2)-1 );
  end
  if any( uv(:) < 0 ) || any( uv(:) > 1 )
    error('sampling parameters outside [0,1] interval');
  end

  %select the cell
  [~,Id] = histc( uv(:,1) , E );
  Id( uv(:,1) == 0 ) = 1;
  Id( uv(:,1) == 1 ) = numel( E ) - 1;

  %proportion within the cell
  uv(:,1) = ( uv(:,1) - E(Id,1) )./( E(Id+1,1) - E(Id,1) );
  
  if     size( M.tri ,2) == 2   %for a polyline case of a bag of segments
    
    %parametric coordinates
    %xyz = A + (B-A)*u = A*(1-u) + B*u;
    %and A, B are the vertices of the segment
    abc = [ 1 - sum( uv , 2 ) , uv ];
    
    xyz = bsxfun( @times , abc(:,1) , M.xyz( M.tri(Id,1),:) ) +  ...
          bsxfun( @times , abc(:,2) , M.xyz( M.tri(Id,2),:) );  
    
  elseif size( M.tri ,2) == 3   %for a triangle mesh case

    %first component to a triangular distribution
    uv(:,1) = 1-sqrt(1-uv(:,1));
    %second component uniform within the corresponding height
    uv(:,2) = uv(:,2) .* (1-uv(:,1));

    %parametric coordinates
    %xyz = a*A + b*B + c*C
    %where a + b + c = 1
    %and A, B, C are the vertices of the triangle
    abc = [ 1 - sum( uv , 2 ) , uv ];

    xyz = bsxfun( @times , abc(:,1) , M.xyz( M.tri(Id,1),:) ) +  ...
          bsxfun( @times , abc(:,2) , M.xyz( M.tri(Id,2),:) ) +  ...
          bsxfun( @times , abc(:,3) , M.xyz( M.tri(Id,3),:) );
    
  end

  if nargout == 2
    abc(:,1) = abc(:,1) + Id;
    Id = abc;
  end
  
end
function r = cross2(a,b)
  % Optimizes r = cross(a,b,2), that is it computes cross products per row
  % Faster than cross if I know that I'm calling it correctly
  r = [ a(:,2).*b(:,3) - a(:,3).*b(:,2) ,...
        a(:,3).*b(:,1) - a(:,1).*b(:,3) ,...
        a(:,1).*b(:,2) - a(:,2).*b(:,1) ];
end
