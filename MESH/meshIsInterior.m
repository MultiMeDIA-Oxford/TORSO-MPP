function v = meshIsInterior( M , G , ALGs )
%{

m = ndmat( [0 1],[0 1],[0 1],[0 1],[0 1],0 );
m = unique( m ,'rows');
m( all( ~m(:,1:3) ,2) & any( m(:,4:5) ,2) ,:) = [];
% m(end+1,end) = 0;
T = [];
for c = 1:size(m,1)
  m(c,:)
  meshIsInterior( RV , G , m(c,:) );
  tic
  meshIsInterior( RV , G , m(c,:) );
  t = toc;
  T(c,1) = t;
end
[~,ord] = sort( T ); T = T(ord); m = m(ord,:); [m,T]


%}


  if 0
    err = false;
    
    if ~err
      B = MeshBoundary( M );
      if isfield( B , 'tri' ) && ~isempty( B.tri )
        err = true;
      end
    end
    if ~err
      if CheckSelfIntersections( M )
        err = true;
      end
    end
    if err
      warning('Mesh shouldn''t look watertight');
    end
  end


  if nargin < 3, ALGs = [true,true,false]; end
  ALGs = ALGs(:).';
  ALGs( 1 , end+1:20 ) = ALGs( end );
  ALGs = ~~ALGs;


  v = false( size(G,1) , 1 );
  G(:,4) = ( 1:size(G,1) ).';
  
  
  M = Mesh(M,0);
  M = MeshTidy( M ,0,true);
  M = MeshFixCellOrientation( M );
  M.triNORMALS = meshNormals( M );
  M.xyzNORMALS = meshNormals( M , 'best' );
  
  CH = M;
  if ALGs(3), try
    CH = Mesh( M , 'convexhull' );
    CH = Mesh( M , 0 );
    CH = MeshTidy( CH );
  end; end

  if ALGs(1), try
    [C,R] = miniball( CH.xyz ); R = R*1.001; R = R*R;
    G( sum( bsxfun( @minus , G(:,1:3) , C(:).' ).^2 ,2) > R ,:) = [];
  end; end

  if ALGs(2), try
    BB = meshBB( CH );
    G( G(:,1) < BB(1,1) ,:) = [];
    G( G(:,1) > BB(2,1) ,:) = [];
    G( G(:,2) < BB(1,2) ,:) = [];
    G( G(:,2) > BB(2,2) ,:) = [];
    G( G(:,3) < BB(1,3) ,:) = [];
    G( G(:,3) > BB(2,3) ,:) = [];
  end; end

  if ALGs(3), try
    G( ~meshIsInterior_helper( CH , G(:,1:3) ) ,:) = [];
  end; end

  if any( ALGs(4:5) ), try
    T = tetgen( M ); T = Mesh( T ,0);
  end; end
  
  if ALGs(4), try
    Tv = meshQuality( T , 'volume' );
    for it = 1:500
      if ~any( Tv ), break; end
      [~,id] = max( Tv ); Tv( id ) = 0;
      C = mean( M.xyz( T.tri( id ,:) ,:) ,1);
      [~,~,R] = vtkClosestElement( M , C ); R = R*0.99; R = R*R;
      w = sum( bsxfun( @minus , G(:,1:3) , C(:).' ).^2 ,2) < R;
      v( G(w,4) ) = true;
      G( w ,:) = [];
    end
  end; end

  if ALGs(5), try
    w = tsearchn( T.xyz , T.tri , G(:,1:3) );
    G( isnan(w) ,:) = [];
  end; end

  w = meshIsInterior_helper( M , G(:,1:3) );
  G( ~w ,:) = [];
  
  v( G(:,4) ) = true;
end
