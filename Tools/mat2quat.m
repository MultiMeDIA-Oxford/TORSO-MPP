function q = mat2quat(M)


  % 
  if sum(sum(abs(M*M' - eye(3))))>1e-10, error('ERROR: M is not a rotation matrix.' ); end
  if abs(det(M) - 1)>1e-10, error('ERROR: M is not a rotation matrix.' ); end


  q(1) = 0.5*sqrt(1+M(1,1)+M(2,2)+M(3,3));

  s = sign(M(3,2)-M(2,3)); if s==0, s=1; end
  q(2) = abs(0.5*sqrt(1+M(1,1)-M(2,2)-M(3,3)))*s;

  s = sign(M(1,3)-M(3,1)); if s==0, s=1; end
  q(3) = abs(0.5*sqrt(1-M(1,1)+M(2,2)-M(3,3)))*s;

  s = sign(M(2,1)-M(1,2)); if s==0, s=1; end
  q(4) = abs(0.5*sqrt(1-M(1,1)-M(2,2)+M(3,3)))*s;


  q = real(q(:));


%     nq = sqrt(q(2:4)'*q(2:4));
%     ang = asin(nq)*2;
%     ax = q(2:4)/nq*ang;
%     a  = [0 -ax(3) +ax(2); ax(3) 0 -ax(1); -ax(2) ax(1) 0];
%     expm(a) - M

end
