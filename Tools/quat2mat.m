function [M,dM] = quat2mat(q)
% 
%   
%   q = randn(3,1); while norm(q)>1, q = rand(3,1); end
%   quat2mat( q ) - maketransform( 'l_xyz' , 2*q/norm(q)*asin(norm(q)) ,'noh')
% 
%

  q = q(:);

  if numel(q)==4
      if abs( norm(q) - 1 )>1e-10
          error( 'ERROR: q must be a unit quaternion.' );
      end
      q = q( 2:4 );
  end

  b = q(1);
  c = q(2);
  d = q(3);

  a = sqrt( max( 1 - b^2 - c^2 - d^2 , 0 ) );

  M = [  1 - 2*c*c-2*d*d   ,    2*( b*c - a*d )   ,    2*( b*d + a*c )     ; ...
         2*( b*c + a*d )   ,    1 - 2*b*b-2*d*d   ,    2*( c*d - a*b )     ; ...
         2*( b*d - a*c )   ,    2*( c*d + a*b )   ,    1 - 2*b*b-2*c*c     ];
       
  if nargout > 1
    dM = [        0   ,     -2*a*c   ,     -2*a*d       ;...
            a*c-b*d   ,    a*b-c*d   ,    a*a-d*d       ;...
            b*c+a*d   ,    c*c-a*a   ,    a*b+c*d       ;...
            a*c+b*d   ,    a*b+c*d   ,    d*d-a*a       ;...
             -2*a*b   ,          0   ,     -2*a*d       ;...
            a*a-b*b   ,    a*d-b*c   ,    a*c-b*d       ;...
            a*d-b*c   ,    a*a-c*c   ,    a*b-c*d       ;...
            b*b-a*a   ,    b*c+a*d   ,    a*c+b*d       ;...
             -2*a*b   ,     -2*a*c   ,          0       ]*2/a;
  end            

end
