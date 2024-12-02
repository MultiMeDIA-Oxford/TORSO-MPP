function [D,u,v,I,J] = DistancePolyline2Polyline_m( U , V )

  nsd = size(U,2);
  if size(V,2) ~= nsd
    error('Points and polyline must be of the same dimension.');
  end

  D = Inf;
  u = [NaN NaN NaN];
  v = [NaN NaN NaN];
  I = 0;
  J = 0;
  for i = 1:(size(U,1)-1)
    a = U(i,:); b = U(i+1,:);
    
    for j = 1:(size(V,1)-1)
      c = V(j,:); d = V(j+1,:);
      
      uuvv = Optimize( @(uv)fro2( a + (b-a)*uv(1) - ( c + (d-c)*uv(2) ) ) , [0;0] ,'methods','conjugate','ls',{'quadratic','golden','quadratic'},'noplot','verbose',0,...
        struct( 'COMPUTE_NUMERICAL_JACOBIAN', {{ 'd' }} ) );
      uu = uuvv(1); uu = min( max( uu , 0 ) , 1 );
      vv = uuvv(2); vv = min( max( vv , 0 ) , 1 );
      
      p1 = a + (b-a)*uu;
      p2 = c + (d-c)*vv;
      
      d = p1 - p2; d = d(:).'*d(:);
%       fprintf('i: %d  j: %d    u: %g    v: %g    d: %g\n', i , j , uuvv(1) , uuvv(2) , d );
      
      if d < D
        D = d;
        u = p1;
        v = p2;
        I = i;
        J = j;
      end
    end
  end

  D = sqrt( D );
end
