function [ eid , xyz , d , c ] = ClosestElement( M , P , DISTANCE )

  if nargin < 3
    DISTANCE = false;
  end
  DISTANCE = ~~DISTANCE;

  na = nargout;
  if DISTANCE, na = 3; end
  
  if     isstruct( M )  &&  isfield( M , 'xyz' )  &&  isfield( M , 'tri' )  &&  size( M.tri ,2) == 3
    
    try
      P = double( P );
      M = struct( 'xyz' , double( M.xyz ) , 'tri' , double( M.tri ) );
      switch na
        case 0
            [ eid               ] = vtkClosestElement( M , P );
        case 1
            [ eid               ] = vtkClosestElement( M , P );
        case 2
            [ eid , xyz         ] = vtkClosestElement( M , P );
        case 3
            [ eid , xyz , d     ] = vtkClosestElement( M , P );
        case 4
            [ eid , xyz , d , c ] = vtkClosestElement( M , P );
      end
    catch LE
      error('not implemented yet. Consider to use VTK libs!!!');
    end
  
  elseif isstruct( M )  &&  isfield( M , 'xyz' )  &&  isfield( M , 'tri' )  &&  size( M.tri ,2) == 2
    
    [ eid , xyz , d ] = ClosestSegment( M.xyz , M.tri , P );
    
  else
    
    TRI = [ 1:size(M,1)-1 ; 2:size(M,1) ].';
    [ eid , xyz , d ] = ClosestSegment( M , TRI , P );
    
  end

  if DISTANCE
    eid = d;
  end
  
end
