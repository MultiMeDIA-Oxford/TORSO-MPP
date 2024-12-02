function I1 = minus( I1 , I2 )

  if       isa(I1,'I3D')  &&   isa(I2,'I3D')

    if ~isequal( size(I1.data) , size(I2.data) ), error('I1 and I2 have different sizes'); end
    try
      I1 = remove_dereference( I1 );
      I1.data = I1.data - I2.data;
    catch LE, fprintf(2, '%s\n',LE.message ); error('try with  tofloat( I1 ) - tofloat( I2 )'); end

  elseif   isa(I1,'I3D')  &&  ~isa(I2,'I3D')

    if ~isscalar( I2 )

      if ~isequal( size(I1.data) , size(I2     ) ), error('I1 and I2 have different sizes'); end
      try
        I1 = remove_dereference( I1 );
        I1.data = I1.data - I2;
      catch LE, fprintf(2, '%s\n',LE.message ); error('try with  tofloat( I1 ) - tofloat( I2 )'); end

    else

      try
        I1 = DATA_action( I1 , [ '@(X) X-' uneval(I2) ] );
      catch LE, fprintf(2, '%s\n',LE.message ); error('try with  tofloat( I1 ) - tofloat( I2 )'); end

    end

  elseif   isa(I2,'I3D')  &&  ~isa(I1,'I3D')

    if ~isscalar( I1 )

      if ~isequal( size(I1     ) , size(I2.data) ), error('I1 and I2 have different sizes'); end
      try
        I2 = remove_dereference( I2 );
        I2.data = I1 - I2.data;
        I1 = I2;
      catch LE, fprintf(2, '%s\n',LE.message ); error('try with  tofloat( I1 ) - tofloat( I2 )'); end

    else

      try
        I1 = DATA_action( I2 , [ '@(X) ' uneval(I1) '-X' ] );
      catch LE, fprintf(2, '%s\n',LE.message ); error('try with  tofloat( I1 ) - tofloat( I2 )'); end

    end

  else

    error('no deberia pasar por aca');

  end
  
  
  if I1.isGPU && ~isa( I1.data , 'parallel.gpu.GPUArray'),  I1.data = parallel.gpu.GPUArray( I1.data );
  elseif          isa( I1.data , 'parallel.gpu.GPUArray'),  I1.data = gather( I1.data );
  end

end

