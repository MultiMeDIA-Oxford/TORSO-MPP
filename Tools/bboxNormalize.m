function [ X , returnFCN , normalizePOSE , returnPOSE ] = bboxNormalize( X , BB )

  if nargin < 2
    BB = [ 0 , 1 ];
  end
  cBB = ( BB(1) + BB(2) )/2;
  sBB = BB(2) - BB(1);
  cBB(end+1:3) = cBB(end);

  if ~iscell( X )
    X = { X };
  end
  
  XYZ = zeros(0,3);
  for x = 1:numel(X)
    if iscell( X{x} )
      XYZ = [ XYZ ; cell2mat( X{x}(:) ) ];
    elseif isstruct( X{x} ) && isfield( X{x} , 'xyz' )
      XYZ = [ XYZ ; X{x}.xyz ];
    else
      XYZ = [ XYZ ; double( X{x} ) ];
    end
    if size( XYZ ,2) ~= 3
      error('only for 3d data');
    end
  end
  XYZ = double( XYZ );

  XYZ = [ min( XYZ , [] ,1 ) ; max( XYZ , [] ,1 ) ];
  
  sXYZ = max( XYZ(2,:) - XYZ(1,:) );
  cXYZ = ( XYZ(1,:) + XYZ(2,:) )/2;
  
  normalizePOSE = maketransform( 't' , -cXYZ , 's' , 1/sXYZ , 's' , sBB , 't' , cBB );

  returnPOSE     = minv( normalizePOSE );
  
  X = transform( X , normalizePOSE );
  %transform( XYZ , normalizedPOSE );
  
  if nargout > 1
    returnFCN = @(x)transform( x , returnPOSE );
    try, returnFCN = CleanFH( returnFCN ); end
  end
  
end
