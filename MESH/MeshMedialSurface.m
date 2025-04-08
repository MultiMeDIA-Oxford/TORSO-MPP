function M = MeshMedialSurface( A , B , LEVEL , TOL , varargin )
if 0

  H = read_VTK( 'C:\Dropbox\AB_EZ\T1CAD002V1_063Y\HEART.vtk' );
  [EPI,LV,RV] = HEARTparts( H );

  A = medialSurface( {MeshDecimate(EPI,500),EPI} , {MeshDecimate(LV,100),LV} , 0 , 50e-3 ,'q',1.3,'-Y');
  B = medialSurface( {MeshDecimate(EPI,500),EPI} , {MeshDecimate(RV,100),RV} , 0 , 50e-3 ,'q',1.3,'-Y');
  
   plotMESH( EPI , 'r[0.1]','ne' );
  hplotMESH( LV  , 'b[0.1]','ne' );
  hplotMESH( RV  , 'g[0.1]','ne' );
  hplotMESH( A ,'m[0.3]','ne','gouraud','patch');
  hplotMESH( B ,'y[0.3]','ne','gouraud','patch');
  
IP = IntersectingMeshes( A , B ); IP.tri(:,3) = [];
IP = MeshTidy( IP , 1e-9 );
hplotMESH( IP , 'EdgeColor','k','LineWidth',3)

%%  
end


  if nargin < 3 || isempty( LEVEL ), LEVEL = 0; end
  if nargin < 4 || isempty( TOL )  , TOL   = 1e-1; end

  if iscell( A ), AA = A{2}; A = A{1};
  else,           AA = A;
  end;            A = Mesh( A ,0); AA = Mesh( AA ,0);
  if iscell( B ), BB = B{2}; B = B{1};
  else,           BB = B;
  end;            B = Mesh( B ,0); BB = Mesh( BB ,0);
  
  n    = @(a,b)(b-a)./(a+b);
  Dfcn = @(x)n( distanceFrom( x , AA ,[],true) , distanceFrom( x , BB ,[],true) );

  
  LID = fillContoursMesh( MeshAppend( MeshBoundary(A) , MeshBoundary(B) ) ,[]);
  T = Mesh( MeshAppend( A , B , LID ) ,0);
  T = MeshTidy( T ,0,1);
  T = tetgen( T , 'q' , 1.4 ,'-Y');

  T = MeshAddField( Mesh( T ,0) , 'xyzN' , Dfcn( T.xyz ) );

  
  if 1
    nP = size( T.xyz ,1);
    w = meshQuality( T , 'maxl');
    w = w > prctile( w , 90 );
    T = MeshSubdivide( T , w );
    T = processMesh( T ,nP);
  end
  
  
  if 1
    w = all( T.xyzN( T.tri ) == 1 ,2) | all( T.xyzN( T.tri ) == -1 ,2);
    if any( w )
      nP = size( T.xyz ,1);
      T = MeshSubdivide( T , w );
      T = processMesh( T ,nP);
    end
  end
  
  if 0
    for d = [-1 1] * 0.05
      nP = size( T.xyz ,1);
      T = MeshClip( T , T.xyzN - ( LEVEL + d ) , 'both' ,'KeepParentEdge');
      if 1
        w = ( nP+1 ):size( T.xyz ,1);
        T.xyz(w,:) = MoveAlongEdges( T.xyz(w,:) , AA , BB ,...
                                     T.xyz( T.xyzParentEdge(w,1) ,:) ,...
                                     T.xyz( T.xyzParentEdge(w,2) ,:) ,...
                                     LEVEL + d + [-1,1]*-1e-1 );
        T = rmfield( T , 'xyzParentEdge' );
      end
      T = processMesh( T ,nP);
    end
  end
  

  if 0
    nP = size( T.xyz ,1);
    T = MeshClip( T , T.xyzN - LEVEL , 'both' );
    T = processMesh( T ,nP);
  end
  
  if 0
    try
    nP = size( T.xyz ,1);
    T = MeshClip( T , T.xyzN - LEVEL , 'both' ,'KeepParentEdge');
    if 0
      w = ( nP+1 ):size( T.xyz ,1);
      T.xyz(w,:) = MoveAlongEdges( T.xyz(w,:) , AA , BB ,...
                                   T.xyz( T.xyzParentEdge(w,1) ,:) ,...
                                   T.xyz( T.xyzParentEdge(w,2) ,:) ,...
                                   LEVEL + [-1,1]*0 );
    end
    T = rmfield( T , 'xyzParentEdge' );
    T = processMesh( T ,nP);
    T = MeshTidy( T ,0,1);
    end
  end
  
  if 1
    try
    d = TOL*2;
    nP = size( T.xyz ,1);
    T = MeshClip( T , T.xyzN - ( LEVEL - d ) , 'both' );
    T = MeshClip( T , T.xyzN - ( LEVEL + d ) , 'both' );
    T = processMesh( T ,nP);
    end
  end
  
  it = 0;
  while 1
    it = it + 1;
    if it > 10, break; end

    if 0
      nP = size( T.xyz ,1);
      T = MeshClip( T , T.xyzN - LEVEL , 'both' ,'KeepParentEdge');
      if 0
        w = ( nP+1 ):size( T.xyz ,1);
        T.xyz(w,:) = MoveAlongEdges( T.xyz(w,:) , AA , BB ,...
                                     T.xyz( T.xyzParentEdge(w,1) ,:) ,...
                                     T.xyz( T.xyzParentEdge(w,2) ,:) ,...
                                     LEVEL + [-1,1]*0 );
      end
      T = rmfield( T , 'xyzParentEdge' );
      T = processMesh( T ,nP);
      T = MeshTidy( T ,0,1);
    end
    
    T = MeshGenerateIDs( T , 'tri' );
    M = MeshZeroContour( T , T.xyzN - LEVEL ,'KeepParentEdge');
    
    w = ~~M.xyzParentEdge(:,1) & ~~M.xyzParentEdge(:,2);
    M.xyzA(w,:) = T.xyz( M.xyzParentEdge(w,1) ,:); M.xyzA(~w,1) = NaN;
    M.xyzB(w,:) = T.xyz( M.xyzParentEdge(w,2) ,:); M.xyzB(~w,1) = NaN;
    M = rmfield( M , 'xyzParentEdge' );
    if 0
      M.xyz = MoveAlongEdges( M.xyz  , AA , BB ,...
                              M.xyzA , M.xyzB ,...
                              LEVEL + [-1,1]*0 );
    end
    M.triN = Dfcn( meshFacesCenter( M ) ); disp( range( M.triN ) - LEVEL );
    
    w = abs( M.triN - LEVEL ) > TOL;
    if ~any(w), break; end
    
    nP = size( T.xyz ,1);
    T = MeshSubdivide( T , unique( M.triID(w) ) );
    T = processMesh( T ,nP);
  end

  if 1  
    for tol = sort( unique( [ TOL/10 , TOL/100 , TOL/1000 , 0 ] ) ,'descend')
      disp(tol)
      M.xyz = MoveAlongEdges( M.xyz , AA , BB , M.xyzA , M.xyzB , LEVEL + [-1,1]*tol );
    end
  end

  if 1
    nP = size( M.xyz ,1);
    M.triN = Dfcn( meshFacesCenter( M ) );
    w = abs( M.triN - LEVEL ) > TOL/10;
    M = MeshSubdivide( M , w );
%     M = MeshSubdivide( M , w , 'linear3' );
    
    w = ( nP+1 ):size( M.xyz ,1);
    M.xyz( w ,:) = MoveAlongEdges( M.xyz( w ,:) , AA , BB , M.xyzA( w ,:) , M.xyzB( w ,:) , LEVEL + [-1,1]*tol );
  end  
  
  M = Mesh( M ,0);
  M.xyzN = Dfcn( M.xyz );
  M.triN = Dfcn( meshFacesCenter( M ) );
  
%   M = Mesh();
%   
%   it = 0;
%   while 1
%     it = it + 1; if it > 10, break; end
%   
%     T = MeshTidy( T );
%     T = MeshGenerateIDs( T , 'tri' );
%     MM = MeshZeroContour( T , T.xyzN - LEVEL );
%     if isempty( MM.tri ), break; end
%     if 0, M = MoveAlongEdges( M , AA , BB , T.xyz( M.xyzParentEdge(:,1) ,:) , T.xyz( M.xyzParentEdge(:,2) ,:) , LEVEL - TOL/100 , LEVEL + TOL/100 ); end
%     MM = rmfield( MM , 'xyzParentEdge' );
%     
%     E = Dfcn( MM.xyz );
%     E = [ E( MM.tri ) , Dfcn( meshFacesCenter( MM ) ) ];
%     E = abs( E - LEVEL );
%     E = max( E , [] , 2 );
%     range( E )
%     
%     w = E > TOL;
%     MM = MeshRemoveFaces( MM , w );
%     
%     nP = size( T.xyz ,1);
%     T = MeshSubdivide( T , setdiff( T.triID , unique( MM.triID ) ) );
%     T = processMesh( T ,nP);
%     
%     T = MeshRemoveFaces( T , ismember( T.triID , find( accumarray( T.triID , 1 ) == 1 ) ) );
%     
%     MM = MeshRemoveFaces( MM , ismember( MM.triID , T.triID ) );
%     
%     if ~isempty( MM.tri )
%       MM = MeshTidy( Mesh( MM ,0) );
%       M = Mesh( MeshAppend( M , MM ) ,0);
%     end
% 
%     w = all( T.xyzN( T.tri ) > LEVEL + 10*TOL ,2 ) | all( T.xyzN( T.tri ) < LEVEL - 10*TOL ,2 );
%     T = MeshRemoveFaces( T , w )
%     if isempty( T.tri )
%       break;
%     end
% 
%   end
%   
%   M = MeshTidy( M ,0,1);
%   
%   M.xyzN = Dfcn( M.xyz );
%   M.triN = Dfcn( meshFacesCenter( M ) );

  function Y = processMesh( Y ,np)
    if nargin > 1
      Y.xyzN( (nP+1):end ,:) = NaN;
    end
    w = isnan( Y.xyzN );
    Y.xyzN(w) = Dfcn( Y.xyz(w,:) );
  end

end
