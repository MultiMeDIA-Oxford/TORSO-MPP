function A=complement(A)
    INF = 100;
    A.XY = polygon_mx( {[-INF,-INF;INF,-INF;INF,INF;-INF,INF],[1]} , A.XY , 'difference' );
  
end
