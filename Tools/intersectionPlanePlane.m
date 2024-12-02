function I = intersectionPlanePlane( A , B , C )


  nA = A(1:3,3).';  nA = nA / sqrt( sum( nA.^2 ) ); pA = A(1:3,4);
  nB = B(1:3,3).';  nB = nB / sqrt( sum( nB.^2 ) ); pB = B(1:3,4);

  if min( asin( sqrt( sum( ( nA - nB ).^2 ) )/2 ) , asin( sqrt( sum( ( nA + nB ).^2 ) )/2 ) ) < 1e-6
    I = []; return;
  end
  
  try,    nI = cross2( nA , nB ).';
  catch,  nI = cross(  nA , nB ).';
  end
  nI = nI / sqrt( nI(:).'*nI );
  if any( ~isfinite( nI ) ), I = []; return; end
  if nI(3) < 0, nI = -nI; end
  
  
%   pI = [ nA ; nB ] \ [ nA * pA ; nB * pB ];
  pI = [ nA ; nB ];
  pI = pinv( pI.' * pI ) * pI.';
  pI = pI * [ nA * pA ; nB * pB ];

  
  I = [ null3( nI.' ) , nI , pI ; 0 0 0 1 ];
  if det(I(1:3,1:3)) < 0, I(:,[1 2]) = I(:,[2 1]); end

  if nargin > 2
    
    i = [ I(1:3,4).' + I(1:3,3).' ; I(1:3,4).' - I(1:3,3).' ];
    i = transform( i , minv( C ) );

    w = i(2,3) ./ ( i(2,3) - i(1,3) );
    i = bsxfun(@times, i(1,:) , w) + bsxfun(@times, i(2,:) ,1-w);
    
    I(1:3,4) = transform( i , C );
    
  end
  
  
end
function N = null3( n )
  try
    N = null( n );
  catch
    proj = @(u,v) ( v(:).' * u(:) )/( u(:).' * u(:) ) * u(:);
    
    u1 = n(:);
    u1 = u1/sqrt( u1(:).' * u1(:) );
    
    v2 = [1;0;0];
    u2 = v2 - proj(u1,v2);
    u2 = u2/sqrt( u2(:).' * u2(:) );
    
    v3 = [0;1;0];
    u3 = v3 - proj(u1,v3) - proj(u2,v3);
    u3 = u3/sqrt( u3(:).' * u3(:) );
    
    if det( [u2 u3 u1] ) < 0
      N = [ u3 , u2 ];
    else
      N = [ u2 , u3 ];
    end
  end
end