function [A,C,J] = area( P )
  
  if size(P.XY,1) == 0
    A = 0;
    C = NaN(1,3);
    return;
  end


  [P,S] = polygon_mx( P.XY );

  V = [];
  F = [];
  for i = 1:size(S,1)
    NV = size( V , 1 );
    V = [ V ; S{i} ];
    F = [ F ;  bsxfun( @plus , ( 1:(size(S{i},1)-2) ).' , NV+[0 1 2] ) ];
  end
  
  cross2D = @(x,y) x(:,1).*y(:,2) - x(:,2).*y(:,1);
  
	As = abs( cross2D( V( F(:,2) , : ) - V( F(:,1) , :) , V( F(:,3) , : ) - V( F(:,1) , :) ) );
  A  = sum( As ) / 2;
  
  if nargout > 1
    
    Cs = [  mean( [ V(F(:,1),1) , V(F(:,2),1) , V(F(:,3),1) ] , 2 ) , ...
            mean( [ V(F(:,1),2) , V(F(:,2),2) , V(F(:,3),2) ] , 2 ) ];

    C = sum( bsxfun( @times , As , Cs ) , 1 )/( 2*A );

  end
  if nargout > 2
    
    J = 0;
    S = [2 1 1;1 2 1;1 1 2]/24;
    V(:,3) = 0;
    for f = 1:size(F,1)
      W = V(F(f,:),:);
      a = fro( cross( W(2,:)-W(1,:) , W(3,:)-W(1,:) ) );
      D = a * W.' * S * W;
      J = J + trace(D)*eye(3) - D;
    end
    
  end
  

end

