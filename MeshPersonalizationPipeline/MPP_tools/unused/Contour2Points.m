function P = Contour2Points( xy , d )

  xy = splitSegments( xy );
  
  P = [];
  for s = 1:numel(xy)
    c = xy{s};
    if size(c,1) > 3
      L = [ 0 ; cumsum( fro( diff( c , 1 , 1 ) ,2) ) ];
      nL = linspace( 0 , L(end) , ceil(L(end)/d)+3 );
      c = Interp1D( c , L , nL , 'linear' );
    end
    P = [ P ; c ];
  end



end

function SEGS = splitSegments( xyz )
  w = any( isnan(xyz) , 2 );
  w( find(~w,1,'last'):end ) = false;
  w = [ true ; w ; true ];
  w = find(w)-1;
  SEGS = cell( numel(w)-1 , 1 );
  for s = 1:numel(SEGS)
    SEGS{s} = xyz( w(s)+1:w(s+1)-1 , : );
    SEGS{s}( any(isnan(SEGS{s}),2) , : ) = [];
  end
  SEGS( cellfun('isempty',SEGS) ) = [];
end
