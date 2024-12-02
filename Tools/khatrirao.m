function P = khatrirao(varargin)
%KHATRIRAO Khatri-Rao product of matrices.
%
%   KHATRIRAO(A,B) computes the Khatri-Rao product of matrices A and
%   B that have the same number of columns.  The result is the
%   column-wise Kronecker product
%   [KRON(A(:,1),B(:,1)) ... KRON(A(:,n),B(:,n))]
%
%   KHATRIRAO(A1,A2,...) computes the Khatri-Rao product of
%   multiple matrices that have the same number of columns.
%

  if numel( varargin ) == 1 && iscell( varargin{1} )
    varargin = varargin{1};
  end

  % N = number of columns (must be the same for every input)
  N = size(varargin{1},2); 
  for a = 2:numel(varargin)
    if ndims( varargin{a} ) ~= 2      , error('only 2D matrices allowed'); end
    if  size( varargin{a} , 2 ) ~= N  , error('All matrices must have the same number of columns.'); end
  end


  P = varargin{1};
  for a = 2:numel(varargin)
    P = bsxfun( @times , permute( P , [3 1 2] ) , permute( varargin{a} , [1 3 2] ) );
    P = reshape( P , [ ] , N );
  end
  
end
