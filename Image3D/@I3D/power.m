function I = power( X , Y )

  if       isa( X , 'I3D' ) && isnumeric( Y )
    
    I = DATA_action( X , [ '@(X) power(X,' , uneval(Y) ,')'] );
    
  elseif   isnumeric( X ) && isa( Y , 'I3D' )
    
    I = DATA_action( Y , [ '@(X) power(' , uneval(X) , ',X)'] );
    
  elseif isa( X , 'I3D' ) && isa( Y , 'I3D' );
    
    X = remove_dereference( X );
    
    X.data = power( X.data , Y.data );
    I = X;

  elseif isa( X , 'I3D' )
    
    X = remove_dereference( X );
    
    X.data = power( X.data , Y );
    I = X;
    
  elseif isa( Y , 'I3D' )
    
    Y = remove_dereference( Y );
    
    Y.data = power( Y , Y.data );
    I = Y;
    
  end
  
end
