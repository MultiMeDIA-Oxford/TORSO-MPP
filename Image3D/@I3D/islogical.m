function is = islogical( I )

  %is = isa( I.data , 'logical' ) || isequalwithequalnans( I.data , ~~I.data );
  is = islogical( I.data );

end
