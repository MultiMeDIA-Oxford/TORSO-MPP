function I = grayimage( I , image_transform )

  if nargin<2, image_transform= I.ImageTransform; end

  I = grayimage( I.data , image_transform );

end
