function R = rodrigues( a1 , a2 )

  if nargin == 1 && isequal( size(a1),[3 3] )
    a = fro( a1 )/sqrt(2);
    U = a1 / a;
  
    R = eye(3) + sin(a) * U + ( 1 - cos(a) ) * ( U * U );
    
    return;
  end


  if nargin == 0
  elseif nargin == 1
    if numel(a1) == 3 
      u = a1;
      a = sqrt( a1(:).' * a1(:) );
    end
  elseif nargin == 2
    if numel(a1) == 3 && numel( a2 ) == 1
      u = a1;
      a = a2;
    end
  end

  if a == 0, R = eye(3); return; end
  
  u = aer2xyz( xyz2aer( u(:) ) .* [1;1;0] + [0;0;1] );
  u = u / sqrt( u(:).' * u(:) );
  
  U = [  0    , -u(3) ,  u(2) ;...
         u(3) ,  0    , -u(1) ;...
        -u(2) ,  u(1) , 0 ];
      
  R = eye(3) + sin(a) * U + ( 1 - cos(a) ) * ( U * U );

end

function xyz = aer2xyz( aer )
  z = aer(3) .* sin( aer(2) );
  c = aer(3) .* cos( aer(2) );
  x = c .* cos( aer(1) );
  y = c .* sin( aer(1) );
  xyz = [ x ; y ; z ];
end
function aer = xyz2aer( xyz )
  h = hypot( xyz(1) , xyz(2) );
  r = hypot( h      , xyz(3) );
  e = atan2( xyz(3) , h      );
  a = atan2( xyz(2) , xyz(1) );
  
  aer = [ a ; e ; r ];
end