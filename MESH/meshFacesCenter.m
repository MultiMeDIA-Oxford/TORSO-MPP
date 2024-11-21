function C = meshFacesCenter( M )


  C = mean( permute( reshape( M.xyz( M.tri(:) , :) , [ size( M.tri , 1 ) , size(M.tri,2) , size( M.xyz,2) ] ) , [1 3 2] ) , 3 );
  

end
