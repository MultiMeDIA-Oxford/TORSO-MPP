function x = expand( x , sz )

  osz = size(x);
  osz(end+1:numel(sz)) = 1;
  
  x = repmat( x , sz ./ osz );

end
