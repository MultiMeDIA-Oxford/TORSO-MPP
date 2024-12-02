function I = var( I , w , dim )

  if nargin < 3, error('dim must be specified.'); end

  I.data = var( I.data , w , dim );
  
  switch dim
    case 1, I.X = mean(I.X);
    case 2, I.Y = mean(I.Y);
    case 3, I.Z = mean(I.Z);
    case 4, I.T = mean(I.T);
  end
  
end
