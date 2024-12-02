function C = safe_MeshBoolean( A , op , B )

  A = struct( 'xyz' , double( single( A.xyz ) ) , 'tri' , double( A.tri ) ); A = MeshFixCellOrientation( A );
  B = struct( 'xyz' , double( single( B.xyz ) ) , 'tri' , double( B.tri ) ); B = MeshFixCellOrientation( B );

  C = [];
  while 1
    try
      C = MeshBoolean( A , op , B );
    end

    try
      if isempty( C.tri ), C = []; end
      if isempty( C.xyz ), C = []; end
    catch
      C = [];
    end
    
    if ~isempty( C )
      D = MeshBoundary( C );
      if ~isempty( D.tri )
        C = [];
      end
    end
    
    if ~isempty( C ), break; end

    fprintf('Perturbing and trying again.\n');
    A.xyz = single( A.xyz ); A.xyz = A.xyz + ( 8*( 2*(rand( size( A.xyz ) ) - 0.5) ) .* eps( A.xyz ) ); A.xyz = double( A.xyz );
    B.xyz = single( B.xyz ); B.xyz = B.xyz + ( 8*( 2*(rand( size( B.xyz ) ) - 0.5) ) .* eps( B.xyz ) ); B.xyz = double( B.xyz );
  end

end
