function R = MovePointsToMesh( P , M , ttype )

  MAX_ITS = 50;
  P0 = P;

  PERCENTAGE = 0.25;
  Ep = Inf; Pp = P0;
  it = 0;

  vtkClosestElement([],[]);
  vtkClosestElement( M );
  CLEANOUT = onCleanup(@()vtkClosestElement([],[]));
  while it < MAX_ITS
    [~,cp,d] = vtkClosestElement( P ); E = sum( d.^2 );
%     disp(E);
    if E > Ep
      P = Pp; E = Ep;
      PERCENTAGE = PERCENTAGE/1.1;
      if PERCENTAGE < 0.01, break; end
      continue;
    end
    
    cp = P + ( cp - P ) * PERCENTAGE;
    R = MatchPoints( cp , P , ttype );
    
    Pp = P; Ep = E; it = it+1;
    P = transform( P , R );
  end
  
  R = MatchPoints( P , P0 , ttype );

end
