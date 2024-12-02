function I = mean( I , dim )

  if nargin < 2, error('dim must be specified.'); end

  I.data = mean( I.data , dim );
  
  switch dim
    case 1, I.X = mean(I.X);
    case 2, I.Y = mean(I.Y);
    case 3, I.Z = mean(I.Z);
    case 4, I.T = mean(I.T);
  end
  
end
