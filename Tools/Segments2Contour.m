function XY = Segments2Contour( S )

  XY = S{1};
  for s = 2:numel(S)
    XY = [ XY ; NaN(1,size(XY,2)) ; S{s} ];
  end

end
