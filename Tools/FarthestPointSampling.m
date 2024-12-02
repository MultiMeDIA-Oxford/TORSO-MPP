function [P,IDS] = FarthestPointSampling( P , IDS , minD , maxN , D_fcn , VERBOSE )
%
% [P,IDS] = FarthestPointSampling( P , IDS , minD , maxN , D_fcn )
%


  if nargin < 6,   VERBOSE = false; end
  if nargin < 3 || isempty( minD ), minD = 0;   end
  if nargin < 4 || isempty( maxN ), maxN = Inf; end

  if minD < 0 && maxN > size( P,1)
    IDS = 1:size( P,1);
    return;
  end

  if nargin < 2 || isempty( IDS )
    IDS = 1;
  end
  
  
  if isstruct( P )
    if nargout > 1
      error('for meshes, only coordinates are returned.');
    end
    P = meshFarthestPointSampling( P , IDS , minD , maxN );
    return;
  end
  
  if nargin < 5 || isempty( D_fcn )
    D_fcn = @(x,s)sum( bsxfun( @minus , x , s ).^2 ,2);
  end 
  
  if any( IDS < 1 )
    error('initial IDS should be all indexes (greater than zero)');
  end
  if any( IDS > size( P ,1) )
    error('initial IDS should be all valid indexes (smaller than number of points)');
  end
  
  if isequal( P(1,:) , P(end,:) ), P(end,:) = []; end
  
  maxN = min( maxN , size(P,1) );
  minD = minD ^ 2;
  
  IDS = IDS(:).'; 
  n = numel( IDS );
  D = Inf;
  for new = IDS
    if VERBOSE, 
      fprintf('%d\n' , new );
    end
    D = min( D , D_fcn( P , P( new , : ) ) );
  end
  IDS(1, n+1:maxN ) = NaN;
  
  while 1
    [ d , new ] = max( noinfs( D ,NaN) );
    if d < minD, break; end

    n = n + 1;
    IDS(1, n ) = new;

    if n >= maxN, break; end
    
    D = min( D , D_fcn( P , P( new , : ) ) );

    if VERBOSE, 
      fprintf('%d   %g\n' , n , sqrt(d) );
    end
  end
  IDS = IDS(1, 1:n );
  
  P = P( sort(IDS) , : );

end
