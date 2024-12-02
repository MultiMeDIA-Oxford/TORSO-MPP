function C = Contour2Segments( XY , id )

  splits = [ 0 ; find( any(~isfinite(XY),2) ) ; size( XY ,1)+1 ];
  
  C = cell(0);
  for s = 1:numel(splits)-1
    fr = splits( s )+1;
    to = splits(s+1)-1;
    if to-fr < 1, continue; end
    C{end+1,1} = XY( fr:to ,:);
  end

  if nargin > 1
    C = C{id};
  end
  
end
