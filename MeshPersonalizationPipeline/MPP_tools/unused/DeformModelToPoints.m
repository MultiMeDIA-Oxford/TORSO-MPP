function [p,R] = DeformModelToPoints( M_ , Y , LAMBDA , p0 , R0 )

  Y0 = Y;

  if nargin < 4, p0 = [0;0]; end
  if nargin < 5, R0 = eye(4); end
  
  Y = transform( Y , R0 , 'inv' );

  p = p0;
  
  while 1
    R = MovePointsToMesh( Y , M_(p) , 'Rt' );
    Y = transform( Y , R );
    fprintf( 'Mag Rot: %g\n' , fro2( R - eye(4) ) );
    if fro2( R - eye(4) ) < 1e-2, break; end
  end

  Nstops = 0;
  while 1
    p = Optimize( @(p)EnergyPoints2Mesh( M_(p) , Y ) + LAMBDA * p(:).'*p(:) , p , 'methods',{'conjugate'},'ls',{'quadratic'},struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}},'MAX_ITERATIONS',25),'noplot');
    
    fprintf( '\n\np: %s\n' , uneval(p) );

    R = MovePointsToMesh( Y , M_(p) , 'Rt' );
    Y = transform( Y , R );
    fprintf( 'Mag Rot: %g\n\n' , fro2( R - eye(4) ) );

    if fro2( R - eye(4) ) < 1e-2
      Nstops = Nstops + 1;
    end
    if Nstops > 4
      break;
    end
  end


  R = MatchPoints( Y0 , Y , 'Rt' );
  
end
function E = EnergyPoints2Mesh( M , P )
  [~,~,d] = vtkClosestElement( M , P );
  E = sum( d.^2 );
end
