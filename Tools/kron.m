function A = kron( A , varargin )
%KRON Kronecker product.
%   kron(A,B) returns the Kronecker product of two matrices A and B, of 
%   dimensions I-by-J and K-by-L respectively. The result is an I*K-by-J*L
%   block matrix in which the (i,j)-th block is defined as A(i,j)*B.
%
  
for bb = 1:numel( varargin )
  B = varargin{bb};

  [I J] = size(A);
  [K L] = size(B);

  if isa( A , 'sym' ) || isa( B , 'sym' )

     [ia,ib] = meshgrid( 1:I , 1:K );
     [ja,jb] = meshgrid( 1:J , 1:L );
     A = A(ia,ja).*B(ib,jb);   

  elseif ~issparse(A) && ~issparse(B)

      % Both matrices are dense.
      A = reshape( A , [ 1 , I , 1 , J ] );
      B = reshape( B , [ K , 1 , L , 1 ] );
      A = bsxfun( @times , A , B );
      A = reshape( A , [ I*K , J*L ] );

  else

      % One of the matrices is sparse.
      [ia,ja,sa] = find(A);
      [ib,jb,sb] = find(B);
      ix = bsxfun(@plus,K*(ia(:)-1).',ib(:));
      jx = bsxfun(@plus,L*(ja(:)-1).',jb(:));

      % The @and operator is slightly faster for logicals.
      if islogical(sa) && islogical(sb)
          A = sparse(ix,jx,bsxfun(@and,sb(:),sa(:).'),I*K,J*L);
      else
          A = sparse(ix,jx,double(sb(:))*double(sa(:).'),I*K,J*L);
      end

  end

end
