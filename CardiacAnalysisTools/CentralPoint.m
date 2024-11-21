function X = CentralPoint( LS )

  A = []; B = [];
  for l = 1:numel(LS)
    a = LS{l}(1,:).'; b = LS{l}(2,:).';
    b = a+(b-a)/fro(b-a);

    A = [ A ; ( eye(numel(a)) - (b-a)*(b-a)' )   ];
    B = [ B ; ( eye(numel(a)) - (b-a)*(b-a)' )*a ];
  end
  X = (A.'*A) \ ( A.'*B );
  X = X(:).';

end
