function I1 = gt( I1 , I2 )

  if ~isa( I1 , 'I3D' )
    error('first argument have to be an I3D');
  end


  if isa( I2 , 'I3D' )
  
    if ~isequal( size( I1.data ) , size( I2.data ) ), error('I1 and I2 have different sizes'); end
    
    I1 = remove_dereference( I1 );
    I1.data = gt( I1.data , I2.data );

  else
    
    if ~isscalar( I2 )

      if ~isequal( size(I1.data) , size( I2 ) ), error('I1 and I2 have different sizes'); end
      
      I1 = remove_dereference( I1 );
      I1.data = gt( I1.data , I2      );

    else
      
      I1 = DATA_action( I1 , [ '@(X) X>' uneval(I2) ] );
      
    end
      
  end

end

