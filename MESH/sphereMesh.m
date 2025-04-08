function S = sphereMesh( its )
  
  if ~nargin, its = 5; end
  
  S = icosahedronMesh();
  for it = 1:its
    S = MeshSubdivide( S );
  end
  S = struct('xyz',S.xyz,'tri',S.tri);
  S.xyz = bsxfun( @rdivide , S.xyz , sqrt( sum( S.xyz.^2 ,2)  ) );

end