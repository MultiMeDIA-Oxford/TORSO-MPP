function X = sround( X , d )
% round to d significative digits

  neg = X < 0;
  zer = X == 0;
  X   = abs(X);

  d   = 10 ^ d;

  s   = 10 .^ ( floor(log10(X)) + 1 ); %scaleFactors

  X = X ./ s;
  X = X * d;
  X = round( X );
  X = X / d;
  X = X .* s;

  X(neg) = -X(neg);
  X(zer) = 0;

end
