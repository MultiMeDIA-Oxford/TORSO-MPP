function [ X , returnFCN , normalizePOSE , returnPOSE ] = miniballNormalize( X )

% [ X , returnFCN , normalizePOSE , returnPOSE ] = bboxNormalize( X );
% return;


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


  XYZ( any( ~isfinite(XYZ) ,2) ,:) = [];
  [center,radius] = miniball( XYZ );

  returnPOSE      = maketransform( 'scale',radius,'t',center );
  normalizePOSE = minv( returnPOSE );
  
  
  X = transform( X , normalizePOSE );
  %[center,radius] = miniball( transform( XYZ , normalizePOSE ) )
  
  if nargout > 1
    returnFCN = @(x)transform( x , returnPOSE );
    try, returnFCN = CleanFH( returnFCN ); end
  end
  
end
