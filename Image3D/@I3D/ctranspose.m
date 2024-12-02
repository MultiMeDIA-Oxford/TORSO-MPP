function I = ctranspose( I )

  I= permute( I , [2 1 3:ndims(I.data)] );

end
