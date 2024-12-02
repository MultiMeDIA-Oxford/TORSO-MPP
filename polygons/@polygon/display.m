function display( P )

  if numel( P.XY ) == 0
    fprintf('empty polygon\n');
    return;
  end

  for i = 1:size(P.XY,1)
    switch P.XY{i,2}
      case 1
        fprintf('  solid:  %5d  vertices\n' , size( P.XY{i} , 1 ) );
      case -1
        fprintf('   hole:  %5d  vertices\n' , size( P.XY{i} , 1 ) );
      case 0
        fprintf('  curve:  %5d  vertices\n' , size( P.XY{i} , 1 ) );
    end
    
  end


end
