function C = centerline( A , B )

  rA = [ min( A , [] , 1 ) ; max( A , [] , 1 ) ];
  rB = [ min( B , [] , 1 ) ; max( B , [] , 1 ) ];
  
  r = [ min( [rA;rB] , [] , 1 ) ; max( [rA;rB] , [] , 1 ) ];

  X = linspace( r(1,1) , r(2,1) , 250 );
  Y = linspace( r(1,2) , r(2,2) , 250 );
  XY = ndmat( X , Y );

  [~,dA] = ClosestPointToPolyline( XY , A ); dA = reshape( dA , [numel(X),numel(Y)] );
  [~,dB] = ClosestPointToPolyline( XY , B ); dB = reshape( dB , [numel(X),numel(Y)] );

  C = contourc( X , Y , ( dA - dB ).' , [1 1]*0 ); C = C.';
  i = 1; while i <= size(C,1), C(i,1) = NaN; i = i + C(i,2) + 1; end
  C( any(isnan(C),2) , : ) = NaN;

  while any( isnan(C(1,:)) ), C(1,:) = []; end
  
  
  [~,dA] = ClosestPointToPolyline( C , A );
  [~,dB] = ClosestPointToPolyline( C , B );
  range( dA - dB )
  C = [ C , (dA+dB)/2 ];
  
  
  %plot3d( A ,'b');hplot3d(B,'r'); hplot3d( C , '.-m'); axis equal

end
