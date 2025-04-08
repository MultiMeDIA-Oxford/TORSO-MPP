function M = MeshRetriangulate( M , nodeIDS )
% 
% MeshRetriangulate( M , ids )
% MeshRetriangulate( M , meshGeodesicDistance( M , ids , 'fastmarching' ) )
% MeshRetriangulate( M , meshGeodesicFarthestPointSampling( M , 12 ) )
% 

  if size( nodeIDS ,1) == size( M.xyz ,1) % && size( nodeIDS ,2) == 1

    D = min( nodeIDS ,[],2);

    R = meshPsuP( M , true );
    for r = 1:numel( R )
      R{r} = [ r ; R{r} ];
      R{r} = [ R{r} , D( R{r} ) ];
    end

    B = zeros( size( M.xyz ,1) ,1);
    for n = 1:numel( B )
      w = n; id = n;
      while ~B(id)
        [~,mid] = min( R{id}(:,2) );
        if mid == 1, B(id) = id; break; end
        id = R{id}( mid ,1);
        w = [ w , id ];
      end
      B( w ) = B(id);
    end
    
%   elseif size( nodeIDS ,1) == size( M.xyz ,1) && size( nodeIDS ,2) > 1
    
  else

    D = meshGeodesicDistance( M , nodeIDS , 'poisson' );
    %D = meshGeodesicDistance( M , nodeIDS , 'fastmarching' );
    [~,B] = min( D , [] ,2);
    B = nodeIDS( B );

  end
  
  
  B = B( M.tri );
  for f = fieldnames( M ).', f = f{1};
    if ~strncmp( f , 'tri' , 3 ), continue; end
    M = rmfield( M , f );
  end

  B( B(:,1) == B(:,2) ,:) = [];
  B( B(:,1) == B(:,3) ,:) = [];
  B( B(:,2) == B(:,3) ,:) = [];

  M.tri = B;
  
end
