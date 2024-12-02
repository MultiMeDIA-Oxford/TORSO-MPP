function I1 = bsxfun( op , I1 , I2 )

  if       isa( I1 , 'I3D' ) &&  isa( I2 , 'I3D' )

    I1 = remove_dereference( I1 );
    I1.data = bsxfun( op , I1.data , I2.data );

  elseif   isa( I1 , 'I3D' ) && ~isa( I2 , 'I3D' )

    if numel( I2 ) < 10
      
      I1 = DATA_action( I1 , [ '@(X) bsxfun(@' , func2str( op ) ',X,' uneval(I2) ')' ] );
      
    else

      I1 = remove_dereference( I1 );
      I1.data = bsxfun( op , I1.data , I2      );

    end

  elseif  ~isa( I1 , 'I3D' ) &&  isa( I2 , 'I3D' )

    II = I1;
    
    if numel( II ) < 10
      
      I1 = DATA_action( I2 , [ '@(X) bsxfun(@' , func2str( op ) ',' uneval(II) ',X)' ] );
      
    else
    
      I1 = remove_dereference( I2 );
      I1.data = bsxfun( op , II , I2.data      );
      
    end

  elseif  ~isa( I1 , 'I3D' ) &&  ~isa( I2 , 'I3D' )
    
    error('porque esta aqui???');

  end
  
end
