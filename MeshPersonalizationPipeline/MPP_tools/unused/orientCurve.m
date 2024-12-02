function xy = orientCurve( xy )

  N = size( xy , 1 );
  [~,i2] = max( xy(:,2) );
  if i2 == 1
    i1 = N; i3 = 2;
  elseif i2 == N
    i1 = N-1; i3 = 1;
  else
    i1 = i2-1; i3 = i2+1;
  end

  cr = cross( [ xy(i2,:)-xy(i1,:) , 0 ] , [ xy(i3,:)-xy(i2,:) , 0 ] );
  if cr(:,3) < 0
    xy = flip(xy,1);
  end

end