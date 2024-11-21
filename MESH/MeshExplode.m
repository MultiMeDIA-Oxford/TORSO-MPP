function M = MeshExplode( M )

  nsd = size( M.xyz ,2);
  nP  = size( M.xyz ,1);
  nT  = size( M.tri ,1);
  nC  = size( M.tri ,2);


  T = M.tri.'; T = T(:);
  for f = fieldnames(M).', f = f{1};
    if ~strncmp( f , 'xyz',3), continue; end
    M.(f) = M.(f)( T ,:);
  end

  M.tri = reshape( 1:nT*nC , [nC,nT] ).';
  
end