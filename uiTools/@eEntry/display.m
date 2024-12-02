function display(eE)

  fprintf( '  Value : %f\n', get( eE.slider , 'Value' ) );
  fprintf( '   Text : %s\n', eE.slider2edit_fcn( get( eE.slider , 'Value' ) ) );
  fprintf( ' Return : %f\n', eE.return_fcn( get( eE.slider , 'Value' ) ) );
  
end