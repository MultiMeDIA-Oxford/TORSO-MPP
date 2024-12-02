function hg_ = quiver( I , varargin )

  if numel(I.Z) > 1 || size(I.data,4) > 1 || size(I.data,5) ~= 2 || ndims( I.data ) > 5
    error('para usar quiver se espera una imagen de [ I x J x 1 x 1 x 2 ]');
  end

  xy = transform( ndmat_mx( I.X , I.Y ) , I.SpatialTransform , 'rows2d' );
  hg = quiver( xy(:,1) , xy(:,2) , vec( I.data(:,:,1,1,1) ) , vec( I.data(:,:,1,1,2) ) , ...
                varargin{:} );
    
	if ~ishold( ancestortool(hg,'axes') )
    axis( ancestortool(hg,'axes') , 'equal' );
  end
              
              
  if nargout > 0, hg_ = hg; end
    
end

