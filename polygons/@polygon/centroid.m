function C = centroid( P )


  [P,S] = polygon_mx( P.XY );
  
  V = [];
  F = [];
  for i = 1:size(S,1)
    NV = size( V , 1 );
    V = [ V ; S{i} ];
    F = [ F ;  bsxfun( @plus , ( 1:(size(S{i},1)-2) ).' , NV+[0 1 2] ) ];
  end
  
  croi2D = @(x,y) x(:,1).*y(:,2) - x(:,2).*y(:,1);
  
	As = abs( croi2D( V( F(:,2) , : ) - V( F(:,1) , :) , V( F(:,3) , : ) - V( F(:,1) , :) ) );
  
  Cs = [  mean( [ V(F(:,1),1) , V(F(:,2),1) , V(F(:,3),1) ] , 2 ) , ...
          mean( [ V(F(:,1),2) , V(F(:,2),2) , V(F(:,3),2) ] , 2 ) ];

  C = sum( bsxfun( @times , As , Cs ) , 1 )/( sum( As ) );
  
end

 