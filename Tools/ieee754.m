function xx = ieee754( x )

  if isa( x , 'double' )

    b = sprintf( '%08x.%08x' , typecast( x , 'uint32' ) );
    l = cell2mat( arrayfun( @(h) dec2bin(hex2dec(h),4) , b( 1:8  )  , 'un',0) );
    u = cell2mat( arrayfun( @(h) dec2bin(hex2dec(h),4) , b(10:end)  , 'un',0) );
    n = bin2dec( [ u(13:end)  l ] );
    e = bin2dec( u(2:12) );
    s = bin2dec( u(1) );

    %xx = realpow(-1,s)* ( 1+realpow(2,-52)*n ) *  realpow(2,e-1023);

    str = '';
    if s, str = [ str , '(-1)*' ]; end

    str = [ str , '( 1 + 2^(-52)*' , uneval(n) , ' )*( 2^( ' , uneval(e) ' - 1023 ) )' ];
    
  elseif isa( x , 'single' );
    
    
    b = sprintf( '%04x.%04x' , typecast( x , 'uint16' ) );
    l = cell2mat( arrayfun( @(h) dec2bin(hex2dec(h),4) , b( 1:4   )  , 'un',0) );
    u = cell2mat( arrayfun( @(h) dec2bin(hex2dec(h),4) , b( 6:end )  , 'un',0) );
    n = bin2dec( [ u(10:end)  l ] );
    e = bin2dec( u(2:9) );
    s = bin2dec( u(1) );
    
    %xx = realpow(-1,s)* ( 1+realpow(2,-23)*n ) *  realpow( 2 , e-127 );
    
    str = '';
    if s, str = [ str , '(-1)*' ]; end

    str = [ str , '( 1 + 2^(-23)*' , uneval(n) , ' )*( 2^( ' , uneval(e ) ' - 127 ) )' ];

    
  else
    str = number2str( x );
  end
  
  
  if nargout
    %xx = maple( str );
    xx = char( sym( str ) );

  else
    disp(str);
  end
  

end
