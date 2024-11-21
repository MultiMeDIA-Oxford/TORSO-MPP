function bb = meshBB( M )

bb = [ min(M.xyz,[],1) ; max(M.xyz,[],1) ];

end