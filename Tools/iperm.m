function iorder = iperm( order , applyTo )

  N = numel( order );
  toN = 1:N;
  if ~isequal( sort( order(:).' ) , toN )
    error('order must be a permutation.');
  end


  iorder = zeros( N , 1 );
  iorder( order ) = toN;

  if nargin > 1
    try
      iorder = iorder( applyTo );
    catch
      error('invalid application of the ipermutation');
    end
  end
  
end
