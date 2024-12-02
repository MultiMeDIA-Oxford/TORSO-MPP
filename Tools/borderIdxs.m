function B = borderIdxs( sz )

  B = false( sz );
  
  d = repmat( {':'} , 1 , ndims(B) );
  
  for c = 1:numel(d)
    d{c} = [ 1 , size( B ,c) ];
    B( d{ : } ) = true;
    d{c} = ':';
  end
  


end