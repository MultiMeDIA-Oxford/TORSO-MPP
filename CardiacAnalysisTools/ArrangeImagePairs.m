function CP = ArrangeImagePairs( varargin )

IS  = varargin{1};

if nargin > 1
    
    for i = 1:size( IS , 1 )
        for j = i+1:size( IS , 1 )
            IL = intersectionLine( IS{i} , IS{j} );
            if isempty( IL ), CP(i,j) = 0; continue; end
            CP(i,j) = 1;
        end
    end
    
    
else
    
    nR = size( IS , 1 );
    CP = cell( nR , 0 );
    
    for i = 1:nR
        for j = i+1:nR
            IL = intersectionLine( IS{i} , IS{j} );
            if isempty( IL ), continue; end
            
            c = size( CP , 2 ) + 1;
            CP{i,c} = IS{i};
            CP{j,c} = IS{j};
        end
    end
end

end
