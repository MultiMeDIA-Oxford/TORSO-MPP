function I = torgb( I , IT )

  if size( I.data , 5 ) ~= 1
    error('the 5th dim has to be 1.');
  end

%   if min( I.data(:) ) < 0  ||  max( I.data(:) ) > 1
%     I = rescaleimage( I );
%   end

  if nargin > 1
    I.ImageTransform = IT;
  end

  I.data = ApplyContrastFunction( I.data , I.ImageTransform );
  
  if ~isfloat( I.data )
    I = tofloat( I );
  end

  I = repmat( I , [1 1 1 1 3] );
  
end
