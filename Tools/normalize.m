function x = normalize( x , dim , p_norm )
% x = randn(4,5,6,7,8);
% 
% xn=normalize(x,3,'fro'); fro( xn(2,3,:,4,1) )
% xn=normalize(x,4,1);     sum( abs(xn(1,5,3,:,7)) )
% xn=normalize(x,5,Inf);   max( abs(xn(1,5,3,3,:)) )
% 
% xn=normalize(x,[1,5],2); fro( xn(:,5,3,3,:) )
% xn=normalize(x,[1,5,3],2); fro( xn(:,5,:,3,:) )
% 
% x = randn(4,5,6,5,8);
% xn=normalize(x,[2,4],@trace); trace(squeeze(xn(1,:,3,:,4)))
% 


  if nargin < 2 || isempty( dim )
    nosingles = find( size(x) ~= 1 );
    if numel( nosingles == 1 ),
      dim = nosingles;
    else
      dim = 1;
    end
  end
  if numel( unique(dim) ) ~= numel(dim)
    error('incorrect dim');
  end

  if nargin < 3
    p_norm = 'fro';
  end
  if isa( p_norm ,'function_handle' )
    FCN = p_norm;
    p_norm = 'FCN';
    
    DOTS( 1:numel(dim) ) = {':'};
    PERM = unique( [ dim(:).' , 1:ndims(x) ] , 'stable' );
    x = permute( x , PERM );
    SZ = size( x );
    x = reshape( x , [ SZ(1:numel(dim)) , prod(SZ(numel(dim)+1:end)) ] );
  end
  
  
  maxits = 5;
  for it = 1:maxits
    N = compute_norma( x , dim , p_norm );
    if all( N(:) == 1 ), break; end

    xp = x;
    x = bsxfun( @rdivide , x , N );
    if isequal( xp , x ), break; end
  end

  
  if isequal( p_norm , 'FCN' )
    x = ipermute( reshape( x , SZ ) , PERM );
  end

  function N = compute_norma( x , dim , p_norm )
    switch p_norm
      case {2,'fro'}
        N = x.^2;
        for d = dim(:).', N = sum( N , d ); end
        N = sqrt( N );

      case {1}
        N = abs(x);
        for d = dim(:).', N = sum( N , d ); end
  
      case {Inf}
        N = abs(x);
        for d = dim(:).', N = max( N , [] , d ); end

      case {'FCN'}
        N  = zeros( size( x , numel(dim)+1 ) , 1 ); 
        for k = 1:numel(N)
          N(k) = FCN( x( DOTS{:} , k ) );
        end
        N = reshape( N , [ ones(1,numel(dim)) , numel(N) ] );
        
      otherwise
        error('invalid norm.');
    end
  end    

end
