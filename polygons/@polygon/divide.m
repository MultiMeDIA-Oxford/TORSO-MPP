function P = divide( P , d )

  for i = 1:size(P.XY,1)
    xy = P.XY{i,1};
    xy = [ xy ; xy(1,:) ];
    
    lengths = cumsum( [ 0 ; sqrt( sum( diff( xy , [] , 1 ).^2 , 2 ) ) ] );
    
    xy = Interp1D( xy , lengths , unique( [ lengths(:).' , 0:d:lengths(end) ] ) );
    
    P.XY{i,1} = xy(1:end-1,:);
  end


end

