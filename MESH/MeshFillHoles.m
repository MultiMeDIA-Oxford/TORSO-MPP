function M = MeshFillHoles( M , delta )
% - Add the "fan from a central point" option


  if nargin < 2, delta = []; end

  for it = 1:10
    [M,IDSname] = MeshGenerateIDs( M , 'xyz_' );
    B = MeshBoundary( M );
    if isempty( B.tri ), break; end
    
    dummy = zeros(size(B.tri,1),1);
    for ii = 1:size(B.tri,1), dummy(ii) = pdist2(B.xyz(B.tri(ii,1),:),B.xyz(B.tri(ii,2),:)); end
    if isempty( M.tri ) || prctile(dummy,80)*10 < max(dummy)
      M = rmfield( M , IDSname );
      break;
    end
    
    B = meshSeparate( B );

    for b = 1:numel(B)
      try,
      F = fillContoursMesh( B{b} , delta );
      F.(IDSname) = zeros( size(F.xyz,1) ,1);


      [w,id] = ismember( F.xyz , B{b}.xyz ,'rows');
      F.(IDSname)(w,1) = B{b}.(IDSname)(id(w),1);

      M = MeshAppend( M , F );
      end
    end
    M = MeshTidy(M,0,true);

    M = rmfield( M , IDSname );
  end


  return;



  for it = 1:20
    try, M = rmfield( M , 'xyzOriginal__ID' ); end
    M = TidyMesh( M , 0 );
    M.xyzOriginal__ID = ( 1:size( M.xyz , 1) ).';
    B = MeshBoundary( M );
    if isempty( B ) || ~isfield( B , 'tri' ) || isempty( B.tri )
      break;
    end

    fc = meshFacesConnectivity( B );
    B = MeshRemoveFaces( B , fc ~= argmax( accumarray( fc , 1 ) ) );
    B = TidyMesh( B , 0 );

    B.tri = B.xyzOriginal__ID( B.tri );
    B.tri(:,3) = size( M.xyz , 1 ) + 1;
    
    M.xyz = [ M.xyz ; mean( B.xyz , 1 ) ];
    M.tri = [ M.tri ; B.tri ];
  end
  
  try, M = rmfield( M , 'xyzOriginal__ID' ); end

  M = TidyMesh( M , 0 );
  try
    N = vtkFillHolesFilter(M);
    if isfield( N , 'tri' )
      M = N;
    end
  end

  
  

%   while 1
%     
%     M = MeshGenerateIDs( M );
%     
%     B = MeshBoundary( M );
%     if isempty( B ) || ~isfield( B , 'tri' ) || isempty( B.tri )
%       break;
%     end
% 
%     B = TidyMesh( B , -1 );
%     
%     fc = meshNodesConnectivity( MakeMesh( B ) );
%     F = 0;
%     for c = unique( fc ).'
%       ED = B.tri( all( fc( B.tri ) == c , 2) ,:);
%       C = SortChain( [] , ED );
%       if numel( C ) == 1 && numel( C{1} ) == size(ED,1)
%         F = c;
%         break;
%       end
%     end
%     if ~F, break; end
%     B = MeshRemoveNodes( B , { fc == F } );
% 
%     B.tri = B.xyzID( B.tri );
%     B.tri(:,3) = size( M.xyz , 1 ) + 1;
%     
%     M.xyz = [ M.xyz ; mean( B.xyz , 1 ) ];
%     M.tri = [ M.tri ; B.tri ];
% 
%   end
%   
%   try, M = rmfield( M , 'xyzID' ); end
%   try, M = rmfield( M , 'triID' ); end
  
end
