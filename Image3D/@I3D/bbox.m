function bb = bbox( I , mask )

  if nargin < 2
    
    bb = ndmat_mx( I.X([1 end]) , I.Y([1 end]) , I.Z([1 end]) );
    
  else
    
    bb = ndmat_mx( I.X , I.Y , I.Z );
    bb = bb( mask , : );
    
  end
  
  bb = transform( bb , I.SpatialTransform );

  bb = [ min(bb,[],1) ; max(bb,[],1) ];
  
end
