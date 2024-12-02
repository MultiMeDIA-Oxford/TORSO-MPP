function A = fuse( A , B , C )

  A = cleanout( A ); A = remove_dereference( A );
  A = tofloat( A );

  B = cleanout( B );
  B = at( B , A );
  B = tofloat( B );

  if nargin > 2
    C = cleanout( C );
    C = at( C , A );
    C = tofloat( C );
  end
  
  
%   A.data = ApplyContrastFunction( A.data , [min(A.data(:)) 0; max(A.data(:)) 1] );
%   B.data = ApplyContrastFunction( B.data , [min(B.data(:)) 0; max(B.data(:)) 1] );
  
  A.data = ApplyContrastFunction( A.data , [ prevnum( prctile(A.data(:),5) ,1000) , 0 ; nextnum( prctile(A.data(:),95) ,1000) , 1 ] );
  B.data = ApplyContrastFunction( B.data , [ prevnum( prctile(B.data(:),5) ,1000) , 0 ; nextnum( prctile(B.data(:),95) ,1000) , 1 ] );
  
  A.data = clamp( A.data , 0 , 1 );
  B.data = clamp( B.data , 0 , 1 );
  
  if nargin > 2
    C.data = ApplyContrastFunction( C.data , [ prevnum( prctile(C.data(:),5) ,1000) , 0 ; nextnum( prctile(C.data(:),95) ,1000) , 1 ] );
    C.data = clamp( C.data , 0 , 1 );
  end

  if nargin > 2
    A.data = cat( 5 , A.data , B.data , C.data );
  else
    A.data = cat( 5 , A.data , B.data , zeros(size(A.data),class(A.data)) );
  end
  
  
end
