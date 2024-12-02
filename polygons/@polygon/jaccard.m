function J=jaccard( A , B )

J = 1-area( intersect( A , B ) )/...
      area( union(     A , B ) );
  

