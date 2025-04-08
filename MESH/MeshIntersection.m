function C = MeshIntersection( A , B )

  if ~isstruct( A ) || ~isfield( A , 'tri' )
    error( 'A  must be a mesh' );
  end
  celltypeA = meshCelltype( A );
  MODE = sprintf( 'mesh%d' , celltypeA );
  
  if isstruct( B ) && isfield( B , 'tri' )
    celltypeB = meshCelltype( B );
    MODE = sprintf('%s-mesh%d',MODE,celltypeB );
  end


  switch MODE
    case 'mesh5-mesh5'
      A = struct('xyz',double(A.xyz),'tri',double(A.tri));
      B = struct('xyz',double(B.xyz),'tri',double(B.tri));
      
      C = struct('xyz',zeros(0,3),'tri',zeros(0,2));
      try
        C = IntersectingMeshes( A , B );
        C.tri = C.tri(:,1:2);
        %C = mesh2contours( C );
      end
      
%       if isempty( C )
%         C = struct('xyz',zeros(3,0),'tri',zeros(2,0));
%       end

  end
  
  



end
