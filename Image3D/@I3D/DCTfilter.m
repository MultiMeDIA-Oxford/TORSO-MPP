function I = DCTfilter( I , f )

  I = remove_dereference( I );
  if isnumeric(f) || islogical( f )

    I.data = DCTfilter( tofloat( I.data ) , f );

  elseif isa( f , 'I3D' )

    I.data = DCTfilter( tofloat( I.data ) , f.data );

  end

end