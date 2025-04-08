function M = MeshWeld( M , B )

  [isM,m] = ismember( B.xyz , M.xyz , 'rows' );

  %maxnorm( B.xyz( isM ,:) , M.xyz( m(isM) ,:) )
  
  m = m( isM );
  b = find( isM ) + size( M.xyz ,1);

  M = MeshAppend( M , B );

  map = 1:max( M.tri(:) );
  map( b ) = m;
  
  M.tri = map( M.tri );
  
  for f=fieldnames(M).',f=f{1};
    if ~strncmp(f,'xyz',3), continue; end
  
    w = any( ~isfinite( M.(f)(m,:) ) ,2);
    if any(w)
      M.(f)( m(w) ,:,:,:,:,:) = M.(f)( b(w) ,:,:,:,:,:);
    end
    w = any( ~isfinite( M.(f)(b,:) ) ,2);
    if any(w)
      M.(f)( b(w) ,:,:,:,:,:) = M.(f)( m(w) ,:,:,:,:,:);
    end
    if maxnorm( M.(f)( m ,:,:,:,:,:,:) , M.(f)( b ,:,:,:,:,:,:) ) ~= 0
      M.(f)( m ,:,:,:,:,:,:) = ( M.(f)( m ,:,:,:,:,:,:) + M.(f)( b ,:,:,:,:,:,:) )/2;
    end
  end
  
  M = MeshRemoveNodes( M , b );
  
end
