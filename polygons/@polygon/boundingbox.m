function bb = boundingbox( P )

  bb = [ Inf Inf ; -Inf -Inf ];
  
  
  for i = 1:size( P.XY , 1 )
    if P.XY{i,2} ~= 1, continue; end
    
    bbi = [ min( P.XY{i,1} , [] , 1 ) ; max( P.XY{i,1} , [] , 1 ) ];
    
    bb = [ min( bb(1,:) , bbi(1,:) ) ; max( bb(2,:) , bbi(2,:) ) ];
    
  end



end
