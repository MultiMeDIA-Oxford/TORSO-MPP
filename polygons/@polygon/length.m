function L = length( P )

    L = 0;
    for c = 1:size( P.XY , 1 )
        L = L + sum( sqrt( sum( diff( [ P.XY{c,1} ; P.XY{c,1}(1,:) ], 1 , 1 ).^2 , 2 ) ) );
    end
    


end

