function b = meshMapPoints( a , A , B )

  w = all( isfinite( a ) ,2);
  a( ~w ,:) = 0;
  
  A = struct( 'xyz', double(A.xyz) , 'tri' , double( A.tri ) );
  A.xyz(:,end+1:3) = 1;
  a(:,end+1:3) = 1;
  [e,~,~,c] = vtkClosestElement( A , double( a ) );
  c( c < 0 ) = 0;
  c( c > 1 ) = 1;
  c = bsxfun( @rdivide , c , sum( c ,2) );
  
  b =  bsxfun( @times , c(:,1) , B.xyz( A.tri(e,1) ,:) ) +...
       bsxfun( @times , c(:,2) , B.xyz( A.tri(e,2) ,:) ) +...
       bsxfun( @times , c(:,3) , B.xyz( A.tri(e,3) ,:) );
  b( ~w ,:) = NaN;

end
