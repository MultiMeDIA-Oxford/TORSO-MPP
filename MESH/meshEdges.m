function [E,EL] = meshEdges( M , XYZ )

  asMESH = true;
  if ~isstruct( M )
    asMESH = false;
    M = struct( 'tri' , M );
  end

  E = [];
  for i = 1:size( M.tri , 2 )
    for j = i+1:size( M.tri , 2 )
      E = [ E ; M.tri(:,[i,j]) ];
    end
  end
  if size( M.tri ,2) > 2
    E = unique( sort( E , 2 ) , 'rows' );
  end
  
  if nargout > 1
    if nargin > 1
      M.xyz = XYZ;
    end
    EL = sqrt( sum( ( M.xyz( E(:,2) ,:)-M.xyz( E(:,1) ,:) ).^2 ,2) );
  elseif nargin > 1
    if ~isstruct( XYZ )
      M = struct( 'xyz' , XYZ );
    end
    E = sqrt( sum( ( M.xyz( E(:,2) ,:)-M.xyz( E(:,1) ,:) ).^2 ,2) );
  end
  
end
