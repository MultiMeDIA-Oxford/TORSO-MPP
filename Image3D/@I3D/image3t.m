function [hg_,eentryI,eentryJ,eentryK] = image3t( I , varargin )

  if size(I,4) == 1
    [hg,eentryI,eentryJ,eentryK] = image3( V , varargin{:} );
  else
    [hg_,eentryI,eentryJ,eentryK] = image3t( permute( I.data , [1 2 3 5 4] ) , varargin{:} , 'X' , I.X , 'Y' , I.Y , 'Z' , I.Z , 'R' , I.SpatialTransform );
  end
    
  if nargout
    hg_ = hg;
  end
    

end
