function C = tprod( varargin )
% Multi-dimensional generalisation of matrix multiplication
%
%   Z = tprod( X , xdims , Y , ydims )
%   Z = tprod( 'Zdims' , X , 'xdims' , Y , 'ydims' )
%
% This function computes a generalised multi-dimensional matrix product
% based upon the Einstein Summation Convention.  This means
% given 2 n-d inputs:
%
%   X = [ A x B x C x E .... ], denoted in ESC as X_{abce}
%   Y = [ D x F x G x H .... ], denoted in ESC as Y_{dfgh}
%
% we define a particular tensor operation producing the result Z as
%
%    Z_{cedf} = X_{abce}Y_{dfab}
%
% where, we form an inner-product (multiply+sum) for the dimensions with
% *matching* labels on the Right Hand Side (RHS) and an outer-product over
% the remaining dimensions.  Note, that in conventional EinsteinSumCsonvention
% the *order* of dimensions in Z is specified on the LHS where the matching 
% label specifies its location.
% 
% Tprod calls closely follow this convention, the tprod equivalent of the
% above is:
%
%   Z = tprod( X , [-1 -2 1 2] , Y , [3 4 -1 -2] )
%   Z = tprod( 'cedf' , X , 'abce' , Y , 'dfab'  )
%
%                 ---  ---
%     Z_{cedf} =  \    \     X_{abce}Y_{dfab}
%                 /    /
%                 ---  ---
%                  a    b
%
% here, *matching negatively* labelled RHS dimensions are inner-product
% dimensionss, whilst the *positively* labelled dimensions directly
% specify the position of that dimension in the result Z. Hence only 2
% dimension-specifications are needed to unambigiously specify this
% tensor product.  
%
%
%
%

  if ischar( varargin{1} ) % || iscell( varargin{1} )
    
    Cidx = varargin{1};  Cidx = strrep( Cidx , ' ','' );
    Aidx = varargin{3};  Aidx = strrep( Aidx , ' ','' );
    Bidx = varargin{5};  Bidx = strrep( Bidx , ' ','' );

    indA = zeros(size(Aidx));
    indB = zeros(size(Bidx));

    % Map inner product dimensions, to unique *negative* index
    for i=1:numel(Aidx)
      Bmatch = ( Aidx(i)==Bidx );
      if ( any(Bmatch) )
        indB(Bmatch) = -i; 
        indA(i)      = -i; 
      end;
    end

    % Map to output position numbers, to correct *positive* index
    for i=1:numel(Cidx);
      indA(Cidx(i)==Aidx)=i;
      indB(Cidx(i)==Bidx)=i;
    end

    A = varargin{2};
    B = varargin{4};

  else

    A    = varargin{1};
    indA = varargin{2};
    B    = varargin{3};
    indB = varargin{4};

  end
    

  szA =  size(A);
  if numel(indA) > numel(szA)
    szA( numel(indA) ) = 0;
    szA( ~szA ) = 1;
  end
  
  szB =  size(B);
  if numel(indB) > numel(szB)
    szB( numel(indB) ) = 0;
    szB( ~szB ) = 1;
  end

  indC = [ indA indB ];
  szC  = [ szA  szB  ];
  szC  =  szC( indC > 0 );
  indC = indC( indC > 0 );


  indA(2,:) = 1:numel(indA);
  rowsA = indA(2,indA(1,:)>0);

  [aux,s] = sort(indA(1,:));  indA  = indA(:,s);
  colsA = indA(2,indA(1,:)<0);

  A = reshape( permute( A , [ rowsA colsA ] ) , prod( szA(rowsA) ) , prod( szA(colsA) ) );
  

  
  indB(2,:) = 1:numel(indB);
  colsB = indB(2,indB(1,:)>0);

  [aux,s] = sort(indB(1,:));   indB  = indB(:,s);
  rowsB = indB(2,indB(1,:)<0);

  B = reshape( permute( B , [ rowsB colsB ] ) , prod( szB(rowsB) ) , prod( szB(colsB) ) );


  
  C = ipermute( reshape( A*B , [szC 1 1] ) , [indC numel(indC)+[1 2]] );

end
