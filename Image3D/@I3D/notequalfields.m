function [Ss1,Ss2] = notequalfields( I1 , I2 )

  if ~( isa( I1 , 'I3D' ) && isa( I2 , 'I3D' ) )
    error('only 2 I3Ds admited');
  end


  %data
  if isidentical( I1.data , I2.data )
    fprintf('data  -> identical.\n');
  elseif ~isequal( size( I1.data ) , size( I2.data ) )
    fprintf('data  -> different sizes... ');
    fprintf('( '); fprintf('%d ',size(I1.data) ); fprintf(')');
    fprintf(' --- ');
    fprintf('( '); fprintf('%d ',size(I2.data) ); fprintf(')');
    fprintf('\n');
  elseif isequalwithequalnans( I1.data , I2.data )
    fprintf('data  -> same values, different clases...  %s --- %s\n',class(I1.data),class(I2.data));
  else
    d = range( double(I1.data)  - double(I2.data) );
    fprintf('data  -> difference  entre %g...%g ' , d );
    d = range( noinfs( double(I1.data) ./ double(I2.data) ) );
    fprintf('  relative_diff entre  %g..%g\n', d );
  end
  
  %coordinates
  for c = {'X','Y','Z','T'}
    if isidentical( I1.(c{1}) , I2.(c{1}) )
      fprintf('%s     -> identical.\n', c{1});
    elseif numel(I1.(c{1})) ~= numel(I2.(c{1}))
      fprintf('%s     -> different numel  %d --- %d\n', c{1},numel(I1.(c{1})),numel(I2.(c{1})) );
    else
      d = range( double(I1.(c{1}))  - double(I2.(c{1})) );
      fprintf('%s     -> difference  entre %g...%g ' , c{1} , d );
      d = range( double(I1.(c{1})) ./ double(I2.(c{1})) );
      fprintf('  relative_diff entre  %g..%g\n', d );
    end
  end

  
  %spatial transform
  if isidentical( I1.SpatialTransform , I2.SpatialTransform )
    fprintf('R     -> identical.\n');
  else
    d = range( double(I1.SpatialTransform)  - double(I2.SpatialTransform) );
    fprintf('R     -> difference  entre %g...%g ' , d );
    d = range( double(I1.SpatialTransform) ./ double(I2.SpatialTransform) );
    fprintf('  relative_diff entre  %g..%g\n', d );
  end


  %containers
  econt = isequalcontainer( I1 , I2 );
  if  econt
    fprintf('CONT  -> identical.\n');
  else
    fprintf('CONT  -> different.\n');
  end
  
  
  %bounding box
  ebb =   transform( ndmat(I1.X([1 end]),I1.Y([1 end]),I1.Z([1 end])) , I1.SpatialTransform , 'rows' ) ...
        - transform( ndmat(I2.X([1 end]),I2.Y([1 end]),I2.Z([1 end])) , I2.SpatialTransform , 'rows' ) ;
  ebb = maxnorm( ebb );
  if  ebb < 1e-8
    fprintf('BB    -> identical.\n');
  else
    fprintf('BB    -> difference  %g\n' , ebb );
  end
  
  fprintf('\n');
end
