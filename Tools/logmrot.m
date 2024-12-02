function W = logmrot( R )
% 
% 
%  no chequea nada..!! ni que sea una rotacion, ni que sea cuadrada ni
%  nada!!
% 
% 
%
if 0
%%
r = randn(3,1); r = normalize(r)*pi;
R = expm( skewmatrix(r) );
[ Optimize(@(z)fro2(expm(skewmatrix(z))-R),[0;0;0],'methods',{'conjugate'},'noplot','verbose',1,struct('COMPUTE_NUMERICAL_JACOBIAN',{{'d'}}),struct('CONJUGATE_METHOD',{'prp'},'LINE_SEARCH',{'quadratic'})) , r ]
%%
end


  switch size(R,1)
    case 2
      theta = acos( R(1) );
      if R(3) < 0, theta = -theta; end
      
      W = [ 0 theta ; -theta 0 ];
      
    case 3
      theta = acos(  max( min( ( R(1)+R(5)+R(9) - 1 )/2 ,1),-1) );
      stheta = sin(theta);
      try, if abs( stheta ) < 1e-7
        W = skewmatrix( Optimize(@(z)fro2(expm(skewmatrix(z))-R),[0;0;0],'methods',{'conjugate'},'noplot','verbose',0,struct('COMPUTE_NUMERICAL_JACOBIAN',{{'d'}}),struct('CONJUGATE_METHOD',{'prp'},'LINE_SEARCH',{'quadratic'})) );
        return;
      end; end
      W = ( 0.5*theta/stheta )*( R - transpose( R ) );
      if any( ~isfinite( double(W(:)) ) )
        W = logm(R);
      end

    otherwise
      W = logm( R );
    
  end

  W = real( W );
  
end
