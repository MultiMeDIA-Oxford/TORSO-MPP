function [x,inds,recover_padding] = crop( x , b , mask , dims )
% 
% 
% F = randn(30,40,15,1,1,2);
% 
% Fp = padding( F , { 1 5 ; 4 20 ; 25 [4 5]} ,'pre'  );
% size( Fp )
% 
% [Fc,d,recover_padding] = crop(Fp , 3 );
% size( Fc )
% 
% Fcc = Fp( d{:} );
% isidentical( Fcc , Fc )
% 
% Fpp = padding( Fc , recover_padding );
% isidentical( Fpp , Fp )
% 
% 




  if nargin < 2 || isempty(b) , b = 0; end
  if nargin < 3, mask = ~~x; end
  if nargin < 4, dims = []; end
  
  if isa( mask , 'function_handle' )
    mask = feval( mask , x );
  end
    
  
  if ~isequal( size(x) , size(mask) )
    error('x   and   mask  has to be of the same size');
  end
  
  nd = ndims(x);
  if isempty( dims ), dims = 1:nd; end
  nd = max( nd , max(dims) );
  
  if size(b,1) == 1,  b = repmat(b,[2 1 ]); end
  if size(b,2) == 1,  b = repmat(b,[1 nd]); end
  if size(b,1) ~= 2 || size(b,2) < nd
    error('incorrect border specification');
  end
  
  
  inds = repmat({':'},[1,nd]);
  recover_padding = zeros(2,nd);
  
  for d = dims(:).'
    
    inds{d} = anyn( mask(inds{:}) , [ 1:d-1 d+1:nd] );
    if ~any( inds{d} ), inds{d}( ceil( end/2 ) ) = true; end
    inds{d} = max( 1         , find(inds{d},1,'first') - b(1,d) )  :...
              min( size(x,d) , find(inds{d},1,'last')  + b(2,d) );
    recover_padding(1,d) = inds{d}(1)-1;
    recover_padding(2,d) = size(x,d) - inds{d}(end);
  end
  
  x = x(inds{:});
  
  
  function i = anyn( xx , ds )

    i = ~~xx;
    for dd = ds
      i = any( i , dd );
    end
    
  end

end
