function xyz = joinSegments( SEGS )
  xyz = SEGS{1};
  for s = 2:numel(SEGS)
    xyz = [ xyz ; NaN(1,size(xyz,2)) ; SEGS{s} ]; %#ok<AGROW>
  end
end
