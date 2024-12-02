function is = isbinary( I )

  %is = isa( I.data , 'logical' ) || isequalwithequalnans( I.data , ~~I.data );
  I  =  nonans( I , 0 );
  is =  islogical( I.data )  ||  isequal( unique( I.data(:) ) , [0;1] );

end
