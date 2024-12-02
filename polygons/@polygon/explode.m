function P = explode( P , full_explode )

  if nargin < 2, full_explode = false; end

  [PP,S] = polygon_mx( P.XY );

  if full_explode

    V = [];
    F = [];
    for i = 1:size(S,1)
      NV = size( V , 1 );
      V = [ V ; S{i} ];
      F = [ F ;  bsxfun( @plus , ( 1:(size(S{i},1)-2) ).' , NV+[0 1 2] ) ];
    end

    P.XY = arrayfun(@(i) V(F(i,:),:), (1:size(F,1)).' , 'UniformOutput' , false );

  else

    P.XY = cell(numel(S),2);
    for i = 1:numel(S)
      NV = size( S{i} , 1 );
      P.XY{i,1} = S{i}( [ 1:2:NV , (floor(NV/2)*2):-2:2 ] , : );
    end

  end

  P.XY(:,2) = {1};
  
end