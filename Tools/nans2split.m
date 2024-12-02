function C = nans2split( X )
if 0

X = reshape( 1:240 ,[30 8 1] );
X([1 4 5:10 ],:,:) = NaN;
% X(:,[ 5 8],:,:) = NaN;
% X(:,:,2) = NaN;

nans2split( X )

%%
end  
  
  nd = ndims( X );
  dots = repmat( {':'} , 1 , nd );
  
  C = {};
  for d = 1:nd
    Z = ~isfinite( X );
    for dd = [ 1:d-1 , d+1:nd ]
      Z = all( Z , dd );
    end
    Z = Z(:).';
    
    c = diff( find([ true , Z , true ] ) );
    c = c - 1; c( ~c ) = [];
    C{d} = c;
      
    dots{d} = Z;
    X( dots{:} ) = [];
    dots{d} = ':';
  end

  C = mat2cell( X , C{:} );

end
