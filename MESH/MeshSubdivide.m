function M = MeshSubdivide( M , varargin )
if 0

  M = Mesh(1:3,1:3);
  MeshSubdivide( M );
  MeshSubdivide( M , 1:10 );
  MeshSubdivide( M , 'linear' );
  MeshSubdivide( M , 'butterfly' );
  MeshSubdivide( M , 1:10 , 'butterfly' );
  MeshSubdivide( M , 'linear' , 1:10 ,'kp');
  
end


if 0
  M.xyz = randn(2000,3); M.tri = delaunayn( M.xyz ); M.celltype = 10; M.triL = (1:size(M.tri,1)).';
  MM = MeshSubdivide( M , 1:11:size(M.tri,1) );
%   plMESH( MM )
  w = MeshQuality( MM , 'volume' ) < 0; unique( MM.triCASE(w) )
  %%
end
if 0
  p1=1;p2=2;p3=3;p4=4;p12=5;p13=6;p14=7;p23=8;p24=9;p34=10;
  T=[];F=[];w=[];

  V = struct('tri',T,'xyz',[0,0,0;2,0,0;1,1.6,0;1,0.6,1.4;1,0,0;0.5,0.8,0;0.5,0.3,0.7;1.5,0.8,0;1.5,0.3,0.7;1,1.1,0.7],'celltype',10);
  MeshQuality( V , 'volume' )
  plMESH(V);
  %%  
end
if 0
%   M.xyz = rand(20,2); M.tri = delaunayn( M.xyz ); M.triL = (1:size(M.tri,1)).';
  W = [ 1 8 10 20 25 ]; W( W>size(M.tri,1) ) = []; cm = rand(size(M.tri,1),3)/2+0.5;
  subplot(121); plotMESH(  M , 'td','L' ); colormap(cm); colorbar
  MM = MeshSubdivide( M , W );
  subplot(122); plotMESH( MM , 'td','L' ); colormap(cm); colorbar
  hplot3d( getv( FacesCenter( M ) , W , ':' ) ,'*r' )
  hplotMESH( MeshBoundary(MM) , '-','EdgeColor','r','LineWidth',3)
  %%
end

  W       = Inf;
  SubType = '';
  KP      = false;

  for v = 1:numel(varargin)
    if ischar( varargin{v} ) && ...
       ( strcmpi( varargin{v} ,'kp' ) || strcmpi( varargin{v} ,'keepparent' ) || strcmpi( varargin{v} ,'keepparentedge' ) )
      KP = true; continue;
    end
    if ischar( varargin{v} ),                                              SubType = varargin{v}; continue; end
    if isnumeric( varargin{v} ),                                           W = varargin{v}; continue; end
    if islogical( varargin{v} ),                                           W = varargin{v}; continue; end
  end

  if strcmpi( SubType , 'fakebutterfly' )
    if isempty( W ), W = 1000; end

    T = M.xyz;
    [~,ids] = FarthestPointSampling( T , 1 , 0 , W );
    M = MeshSubdivide( M , 'loop' );
    M.xyz = InterpolatingSplines( T(ids,:) , M.xyz(ids,:) , M.xyz , 'r' );
    
    return;
  end
  if strcmpi( SubType , 'safebutterfly' )
    try
      M = MeshSubdivide( M , 'butterfly' );
    catch
      M = MeshSubdivide( M , 'fakebutterfly' , W );
    end
    return;
  end

  
  if iscell( M )
    Nits = M{2};
    M    = M{1};
    for it = 1:Nits
      M = MeshSubdivide( M , W , SubType );
    end
    return;
  end
  
  if ischar( W ) && isempty( W ), W = Inf; end
  nT  = size( M.tri , 1);   %number of faces
  if isinf( W )
    W = 1:nT;
  elseif islogical( W )
    if numel(W) ~= nT, error('a number of triangles logical were expected'); end
    W = find(W);
    if any( W > nT ),   error('Index exceeds number of faces.');        end
    if isempty( W ), return; end
  else
    W = unique( W(:) ,'sorted');
    if any( mod(W,1) ), error('indexes must be integers or logicals.'); end
    if any( W < 1 ),    error('indexes must be positive integers.');    end
    if any( W > nT ),   error('Index exceeds number of faces.');        end
    if isempty( W ), return; end
  end
  W = W(:);

  M.celltype = meshCelltype( M );
  T  = M.tri;
  F  = ( 1:nT ).';         %face indexes
  nP = size( M.xyz , 1);   %number of points
  
  if isempty( SubType ), SubType = 'default'; end

  if 0
  elseif M.celltype == 3   %segments case
    switch lower(SubType)
      case {'default'},
        if isempty( W ), return; end

        %middle points on edges
        E   = T( W ,:);
        for f = fieldnames( M ).', if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
          M.(f{1}) = [ M.(f{1}) ; ( M.(f{1})( E(:,1) ,:) + M.(f{1})( E(:,2) ,:) )/2 ];
        end
        P = nP + ( 1:size(E,1) ); P = P(:);    %indexes of the new points


        %old and new faces
        T = [   T ; ... 
              [ T( W ,1) , P        ] ;...
              [ P        , T( W ,2) ] ;...
            ];
        F = [ F ; W ; W ];      %original ids of the new faces

      case {'cornercutting'}
        if ~isequal( W(:).' , 1:nT ), error('cornercutting subdivision is only valid when all faces are considered.'); end
        
        error('not implemented yet');
        
      case {'4points'}
        if ~isequal( W(:).' , 1:nT ), error('4points subdivision is only valid when all faces are considered.'); end
        
        error('not implemented yet');
        
        
      otherwise, error('Unknown SubType for segments.');

    end
    
  elseif M.celltype == 5          %% triangular mesh
    switch lower(SubType)
      case {'default','triangular','linear4'},
        if isempty( W ), return; end

        allE = sort( [ T(:,[1 2]) ; T(:,[2 3]) ; T(:,[1 3]) ] ,2); %no remove the repeated

        if strcmpi( SubType , 'triangular' )   %% case 1, in case of cuadrilateral faces, split the whole triengle into 4

          while 1
            E = allE( [ W ; W + nT ; W + 2*nT ] , : );
            E = unique( E , 'rows' );
            TtD = reshape( ismember( allE , E , 'rows' ) , nT , 3 );
            Wp = W;
            W = find( sum( TtD ,2) > 1 );
            if isequal( Wp , W ), break; end
          end

        elseif strcmpi( SubType , 'default' ) ||...
               strcmpi( SubType , 'linear4' )   %% case 2, keep to minimum the number of faces

          E = allE( [ W ; W + nT ; W + 2*nT ] , : );
          E = unique( E , 'rows' );

        end

        
        %triangles containing edges
        [~,ET] = ismember2ROWS( allE , E(:,1:2) );
        ET = reshape( ET , [nT,3] );
        LET = ~~ET;  %logical ET

        %original faces, to be removed at the end
        W = find( any( LET ,2) );

        %indexes of the new points
        P = ( (nP+1):(nP+size(E,1)) ).';

        %middle points on edges
        for f = fieldnames( M ).'
          if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
          M.(f{1}) = [ M.(f{1}) ; ( M.(f{1})( E(:,1) ,:,:,:,:,:) + M.(f{1})( E(:,2) ,:,:,:,:,:) )/2 ];
        end
        if KP
          fn = fieldnames(M); fn = sort( fn( strncmp( fn , 'xyzParentEdge' ,13) ) );
          for f = fn(end:-1:1).', M = renameStructField( M , f{1} , [ f{1} , '_' ] ); end
          PE = (1:nP).'; PE(:,2) = 0;
          PE = [ PE ; double(E) ];
          PE( 1:nP ,3) = 0;
          PE( nP+1:end ,3) = 0.5;
          M.xyzParentEdge = PE;
        end
        

        %first, triangles to be divided into 4.
        w = find( LET(:,1) & LET(:,2) & LET(:,3) );
        T = [ T ; ...
              [     T(w, 1 )   , P( ET(w, 1 ) ) , P( ET(w, 3 ) ) ] ;...
              [ P( ET(w, 1 ) ) ,     T(w, 2 )   , P( ET(w, 2 ) ) ] ;...
              [ P( ET(w, 3 ) ) , P( ET(w, 2 ) ) ,     T(w, 3 )   ] ;...
              [ P( ET(w, 1 ) ) , P( ET(w, 2 ) ) , P( ET(w, 3 ) ) ] ;...
            ];
        F = [ F ; w ; w ; w ; w ];

        %triangles to be divided at edge 1-2
        w = find( LET(:,1) & ~LET(:,2) & ~LET(:,3) );
        T = [ T ; ...
              [     T(w, 1 )   , P( ET(w, 1 ) ) ,     T(w, 3 )   ] ;...
              [ P( ET(w, 1 ) ) ,     T(w, 2 )   ,     T(w, 3 )   ] ;...
            ];
        F = [ F ; w ; w ];

        %triangles to be divided at edge 2-3
        w = find( ~LET(:,1) & LET(:,2) & ~LET(:,3) );
        T = [ T ; ...
              [     T(w, 1 )   ,     T(w, 2 )   , P( ET(w, 2 ) ) ] ;...
              [     T(w, 1 )   , P( ET(w, 2 ) ) ,     T(w, 3 )   ] ;...
            ];
        F = [ F ; w ; w ];

        %triangles to be divided at edge 1-3
        w = find( ~LET(:,1) & ~LET(:,2) & LET(:,3) );
        T = [ T ; ...
              [     T(w, 1 )   ,     T(w, 2 )   , P( ET(w, 3 ) ) ] ;...
              [     T(w, 2 )   ,     T(w, 3 )   , P( ET(w, 3 ) ) ] ;...
            ];
        F = [ F ; w ; w ];

        %triangles to be divided at edge 1-2 && 2-3
        w = find( LET(:,1) & LET(:,2) & ~LET(:,3) );
        T = [ T ; ...
              [ P( ET(w, 1 ) ) ,     T(w, 2 )   , P( ET(w, 2 ) ) ] ;...
              [     T(w, 1 )   , P( ET(w, 1 ) ) ,     T(w, 3 )   ] ;...
              [ P( ET(w, 1 ) ) , P( ET(w, 2 ) ) ,     T(w, 3 )   ] ;...
            ];
        F = [ F ; w ; w ; w ];

        %triangles to be divided at edge 1-2 && 1-3
        w = find( LET(:,1) & ~LET(:,2) & LET(:,3) );
        T = [ T ; ...
              [     T(w, 1 )   , P( ET(w, 1 ) ) , P( ET(w, 3 ) ) ] ;...
              [ P( ET(w, 1 ) ) ,     T(w, 3 )   , P( ET(w, 3 ) ) ] ;...
              [ P( ET(w, 1 ) ) ,     T(w, 2 )   ,     T(w, 3 )   ] ;...
            ];
        F = [ F ; w ; w ; w ];

        %triangles to be divided at edge 2-3 && 1-3
        w = find( ~LET(:,1) & LET(:,2) & LET(:,3) );
        T = [ T ; ...
              [ P( ET(w, 3 ) ) , P( ET(w, 2 ) ) ,     T(w, 3 )   ] ;...
              [     T(w, 1 )   , P( ET(w, 2 ) ) , P( ET(w, 3 ) ) ] ;...
              [     T(w, 1 )   ,     T(w, 2 )   , P( ET(w, 2 ) ) ] ;...
            ];
        F = [ F ; w ; w ; w ];
    
      case {'linear3'}
        if isempty( W ), return; end
        
        %middle points on faces
        for f = fieldnames( M ).', if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
          M.(f{1}) = [ M.(f{1}) ; ( M.(f{1})( T(W,1) ,:) + M.(f{1})( T(W,2) ,:) + M.(f{1})( T(W,3) ,:) )/3 ];
        end
        P = nP + ( 1:numel(W) ); P = P(:);    %indexes of the new points

        T = [ T ; ...
              [  P         ,  T(W, 2 )  ,  T(W, 3 )  ] ;...
              [  T(W, 1 )  ,  P         ,  T(W, 3 )  ] ;...
              [  T(W, 1 )  ,  T(W, 2 )  ,  P         ] ;...
            ];
        F = [ F ; W ; W ; W ];
        
      case {'loop_matrix'}
        if ~isequal( W(:).' , 1:nT ), error('LOOP subdivision is only valid when all faces are considered.'); end
        
        E = [ T(:,[1 2 3]) ; T(:,[2 3 1]) ; T(:,[1 3 2]) ];
        E(:,5) = repmat( ( 1:nT ).' , [3,1] );
        E(:,1:2) = sort( E(:,1:2) ,2);      allE = E(:,1:2);
        E = sortROWS( E , [1 2] );
        w = find( all( ~diff( E(:,1:2) , 1 , 1 ) ,2) );
        E( w  ,4) = E( w+1 ,3);
        E( w+1,:) = [];
        E = sortROWS( E , 5 );
        nE = size( E ,1);
        
        B = E(:,4) == 0;
        B = uniqueROWS( [ E( B  ,1) ; E( B ,2) ] , 1 );
        
        %triangles containing edges
        [~,ET] = ismember2ROWS( allE , E(:,1:2) );
        ET = reshape( ET , [nT,3] );
        allE = [ allE ; allE(:,[2 1]) ];
        allE = uniqueROWS( allE , [1 2] );
        aEB = ismembc( allE , B );

        %indexes of the new points
        P = nP + ( 1:nE ); P = P(:);
        T = [ T ; ...
              [     T(:, 1 )   , P( ET(:, 1 ) ) , P( ET(:, 3 ) ) ] ;...
              [ P( ET(:, 1 ) ) ,     T(:, 2 )   , P( ET(:, 2 ) ) ] ;...
              [ P( ET(:, 3 ) ) , P( ET(:, 2 ) ) ,     T(:, 3 )   ] ;...
              [ P( ET(:, 1 ) ) , P( ET(:, 2 ) ) , P( ET(:, 3 ) ) ] ;...
            ];
        F = [ F ; W ; W ; W ; W ];
        
        %interpolate fields at middle points on edges
        for f = fieldnames( M ).'
          if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
          if strcmp( f{1} , 'xyz' ), continue; end
          M.(f{1}) = [ M.(f{1}) ; ( M.(f{1})( E(:,1) ,:) + M.(f{1})( E(:,2) ,:) )/2 ];
        end

        G = NaN( 100 , 3 ); GN = 0;
        
        %for boundaries: middle points on edges
        w  = all( ismembc( E(:,1:2) , B ) ,2);
        ww = find( w );
        add2G( nP+ww , E(w,1:2) , 1/2 );

        %for internals: rule 3/8 , 1/8
        w  = ~w;
        ww = find( w );
        c1 = 3/8; c2 = 1/8;
        add2G( nP+ww , E(w,1:2) , c1 );
        add2G( nP+ww , E(w,3:4) , c2 );


        %correction of original ("even") on the boundary
        w = all( aEB ,2);
        add2G( allE(w,1) , allE(w,2) , 1/8 );
        
        %correction of original ("even") internal nodes 
        w = ~aEB(:,1);
        K = accumarray( allE(:,1) , 1 );
        beta = ( 5/8 - ( 3/8 + cos( 2*pi ./ K )/4 ).^2 ) ./ K;
        add2G( allE(w,1) , allE(w,2) , beta( allE(w,1) ) );

        
        %perform the interpolation
        ww = ( 1:nP ).';
        d = accumarray( G(1:GN,1) , G(1:GN,3) , [ nP + nE , 1 ] ); d = 1-d( ww );
        add2G( ww , ww , d );

        G = G( 1:GN ,:);
        
        G = sparse( G(:,1) , G(:,2) , G(:,3) , nP + nE , nP );
        M.xyz = G * double( M.xyz );
        M.LoopMatrix = G;
        
      case {'loop'}
        if ~isequal( W(:).' , 1:nT ), error('LOOP subdivision is only valid when all faces are considered.'); end
        
        E = [ T(:,[1 2 3]) ; T(:,[2 3 1]) ; T(:,[1 3 2]) ];
        E(:,5) = repmat( ( 1:nT ).' , [3,1] );
        E(:,1:2) = sort( E(:,1:2) ,2);      allE = E(:,1:2);
        E = sortROWS( E , [1 2] );
        w = find( all( ~diff( E(:,1:2) , 1 , 1 ) ,2) );
        E( w  ,4) = E( w+1 ,3);
        E( w+1,:) = [];
        E = sortROWS( E , 5 );
        nE = size( E ,1);
        
        B = E(:,4) == 0;
        B = uniqueROWS( [ E( B  ,1) ; E( B ,2) ] , 1 );
        
        %triangles containing edges
        [~,ET] = ismember2ROWS( allE , E(:,1:2) );
        ET = reshape( ET , [nT,3] );
        allE = [ allE ; allE(:,[2 1]) ];
        allE = uniqueROWS( allE , [1 2] );
        aEB = ismembc( allE , B );

        %indexes of the new points
        P = nP + ( 1:nE ); P = P(:);
        T = [ T ; ...
              [     T(:, 1 )   , P( ET(:, 1 ) ) , P( ET(:, 3 ) ) ] ;...
              [ P( ET(:, 1 ) ) ,     T(:, 2 )   , P( ET(:, 2 ) ) ] ;...
              [ P( ET(:, 3 ) ) , P( ET(:, 2 ) ) ,     T(:, 3 )   ] ;...
              [ P( ET(:, 1 ) ) , P( ET(:, 2 ) ) , P( ET(:, 3 ) ) ] ;...
            ];
        F = [ F ; W ; W ; W ; W ];
        
        %interpolate fields at middle points on edges
        for f = fieldnames( M ).'
          if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
          if strcmp( f{1} , 'xyz' ), continue; end
          M.(f{1}) = [ M.(f{1}) ; ( M.(f{1})( E(:,1) ,:,:,:,:,:,:,:) + M.(f{1})( E(:,2) ,:,:,:,:,:,:,:) )/2 ];
        end

        M.xyz( nP + nE ,1) = 0;
        
        %for boundaries: middle points on edges
        w  = all( ismembc( E(:,1:2) , B ) ,2);
        ww = find( w );
        M.xyz( nP+ww ,: ) = ( M.xyz( E(w,1) ,:,:,:,:,:,:,:) + M.xyz( E(w,2) ,:,:,:,:,:,:,:) )/2;

        %for internals: rule 3/8 , 1/8
        w  = ~w; Ew = E(w,:);
        ww = find( w );
        c1 = 3/8; c2 = 1/8;
        M.xyz( nP+ww ,: ) = c1 * ( M.xyz( Ew(:,1) ,:,:,:,:,:,:,:) + M.xyz( Ew(:,2) ,:,:,:,:,:,:,:) ) +...
                            c2 * ( M.xyz( Ew(:,3) ,:,:,:,:,:,:,:) + M.xyz( Ew(:,4) ,:,:,:,:,:,:,:) );


        G = NaN( 10 , 3 ); GN = 0;

        %correction of original ("even") on the boundary
        w = all( aEB ,2); %aEw = aE(w,:);
        add2G( allE(w,1) , allE(w,2) , 1/8 );
        
        %correction of original ("even") internal nodes 
        w = ~aEB(:,1);
        K = accumarray( allE(:,1) , 1 );
        beta = ( 5/8 - ( 3/8 + cos( 2*pi ./ K )/4 ).^2 ) ./ K;
        add2G( allE(w,1) , allE(w,2) , beta( allE(w,1) ) );

        
        %perform the interpolation
        ww = ( 1:nP ).';
        d = accumarray( G( 1:GN ,1) , G( 1:GN ,3) , [ nP , 1 ] ); d = 1-d;
        add2G( ww , ww , d );
        
        G = G( 1:GN ,:);
        
        G = sparse( G(:,1) , G(:,2) , G(:,3) , nP , nP );
        M.xyz(ww,:) = G * double( M.xyz(ww,:) );

      case {'butterfly'}
        if ~isequal( W(:).' , 1:nT ), error('BUTTERFLY subdivision is only valid when all faces are considered.'); end
        
        E = [ T(:,[1 2 3]) ; T(:,[2 3 1]) ; T(:,[1 3 2]) ];
        E(:,5) = repmat( ( 1:nT ).' , [3,1] );
        E(:,1:2) = sort( E(:,1:2) ,2);      allE = E(:,1:2);
        E = sortROWS( E , [1 2] );
        w = find( all( ~diff( E(:,1:2) , 1 , 1 ) ,2) );
        E( w  ,4) = E( w+1 ,3);
        E( w+1,:) = [];
        E = sortROWS( E , 5 );
        nE = size( E ,1);
        E(:,5) = ( 1:nE ).';
        
        K = accumarray( T(:) , 1 , [nP,1] );
        
        %triangles containing edges
        [~,ET] = ismember2ROWS( allE , E(:,1:2) );
        ET = reshape( ET , [nT,3] );
        aEB = E( ~E(:,4) ,1:2);

        %indexes of the new points
        P = nP + ( 1:nE ); P = P(:);
        T = [ T ; ...
              [     T(:, 1 )   , P( ET(:, 1 ) ) , P( ET(:, 3 ) ) ] ;...
              [ P( ET(:, 1 ) ) ,     T(:, 2 )   , P( ET(:, 2 ) ) ] ;...
              [ P( ET(:, 3 ) ) , P( ET(:, 2 ) ) ,     T(:, 3 )   ] ;...
              [ P( ET(:, 1 ) ) , P( ET(:, 2 ) ) , P( ET(:, 3 ) ) ] ;...
            ];
        F = [ F ; W ; W ; W ; W ];
        
        %interpolate fields at middle points on edges
        for f = fieldnames( M ).'
          if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
          if strcmp( f{1} , 'xyz' ), continue; end
          M.(f{1}) = [ M.(f{1}) ; ( M.(f{1})( E(:,1) ,:) + M.(f{1})( E(:,2) ,:) )/2 ];
        end

        %butterfly stencil
        Ec = E(:,1) + 1i*E(:,2);
        [~,c] = ismember2ROWS( sort( E(:,[1,3]) , 2 ) , Ec ); cc = [ 6 7 ]; w=~~c; E(w,cc) = E(c(w),3:4); w = E(:,cc(1)) == E(:,1) | E(:,cc(1)) == E(:,2); E(w,cc(1)) = 0;  w = E(:,cc(2)) == E(:,1) | E(:,cc(2)) == E(:,2); E(w,cc(2)) = 0; w=all(~E(:,cc),2); E(w,cc(1))=-E(w,4);
        [~,c] = ismember2ROWS( sort( E(:,[1,4]) , 2 ) , Ec ); cc = [ 8 9 ]; w=~~c; E(w,cc) = E(c(w),3:4); w = E(:,cc(1)) == E(:,1) | E(:,cc(1)) == E(:,2); E(w,cc(1)) = 0;  w = E(:,cc(2)) == E(:,1) | E(:,cc(2)) == E(:,2); E(w,cc(2)) = 0; w=all(~E(:,cc),2); E(w,cc(1))=-E(w,3);
        [~,c] = ismember2ROWS( sort( E(:,[2,3]) , 2 ) , Ec ); cc = [10 11]; w=~~c; E(w,cc) = E(c(w),3:4); w = E(:,cc(1)) == E(:,1) | E(:,cc(1)) == E(:,2); E(w,cc(1)) = 0;  w = E(:,cc(2)) == E(:,1) | E(:,cc(2)) == E(:,2); E(w,cc(2)) = 0; w=all(~E(:,cc),2); E(w,cc(1))=-E(w,4);
        [~,c] = ismember2ROWS( sort( E(:,[2,4]) , 2 ) , Ec ); cc = [12 13]; w=~~c; E(w,cc) = E(c(w),3:4); w = E(:,cc(1)) == E(:,1) | E(:,cc(1)) == E(:,2); E(w,cc(1)) = 0;  w = E(:,cc(2)) == E(:,1) | E(:,cc(2)) == E(:,2); E(w,cc(2)) = 0; w=all(~E(:,cc),2); E(w,cc(1))=-E(w,3);
        
        E( ~E(:) ) = -Inf;
        E(:, 6:13) = sort( E(:,6:13) , 2 ,'descend');
        E( ~isfinite( E(:) ) ) = 0;
        E(:,10:13) = [];


        B = unique( E( ~E(:,4),1:2) );
        
        G = NaN( 100 ,3); GN = 0;
        %TYPES = zeros( nE , 1 );
        
        %cases from:
        %vtkButterflySubdivisionFilter.cxx

        
        %case boundary, edges belonging to only one triangle
        w = ~E(:,4);
        Ew = E(w,:); eid = Ew(:,5);
        for n = 1:numel(eid)
          p1 = Ew(n,1); p2 = Ew(n,2);
          
          R1 = aEB( any( aEB == p1 ,2) ,:);
          R1( any( R1 == p2 ,2) ,:) = [];
          R1 = R1(1,:); R1( R1 == p1 ) = [];
          
          R2 = aEB( any( aEB == p2 ,2) ,:);
          R2( any( R2 == p1 ,2) ,:) = [];
          R2 = R2(1,:); R2( R2 == p2 ) = [];
          
          add2G( eid(n) , [ R1 ; R2 ] , -1/16 );
          %add2G( eid(n) , R2 , -1/16 );
        end
        add2G( eid , Ew(:,1:2) , 9/16 );
        E(w,:) = []; %TYPES(eid) = 1;
        
        %boundary-boundary case (ears case)
        w = all( ismember( E(:,1:2) , B ) ,2);
        Ew = E(w,:); eid = Ew(:,5);
        add2G( eid , Ew(:,1:2) ,  1/2  );
        E(w,:) = []; %TYPES(eid) = 2;
        
        %regular-regular interior
        w = K(E(:,1)) == 6 & K(E(:,2)) == 6;
        Ew = E(w,:); eid = Ew(:,5);
        add2G( eid , Ew(:,1:2) ,  1/2  );
        add2G( eid , Ew(:,3:4) ,  1/8  );
        add2G( eid , Ew(:,6:9) , -1/16 );
        E(w,:) = []; %TYPES(eid) = 2;


        %extraordinary-regular
        w = K(E(:,1)) ~= 6 & K(E(:,2)) == 6;
        E = [ E(w,:) ; E(~w,:) ];
        w = K(E(:,1)) == 6 & K(E(:,2)) ~= 6;
        E = [ E(w,[2 1 3:end]) ; E(~w,:) ];
        
        
        w = K(E(:,1)) ~= 6 & K(E(:,2)) == 6;
        Ew = E(w,:); eid = Ew(:,5);
        
        TT = M.tri; TT = TT( any( ismember( TT , E(:,1:2) ) ,2) ,:);
        RS = meshRings( TT );
        
        for n = 1:numel(eid)
          R = CIRCULARshift( RS{ Ew(n,1) }.' , Ew(n,2) );
          k = numel(R);
          switch k
            case 0,     s = [1/2,1/2,1/8,1/8,-1/16,-1/16,-1/16,-1/16]; R =  Ew(n,[1:4 6:9]);
            case 3,     s = [ 5/12 , -1/12 , -1/12 ];
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,1) ];
            case 4,     s = [ 3/8 , 0 , -1/8 , 0 ];
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,1) ];
            otherwise,  s = ( 1/4 + cos( 2 * pi * (0:k-1) / k ) + 1/2 * cos( 4 * pi * (0:k-1) / k ) ) / k;
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,1) ];
          end
          add2G( eid(n) , R , s );
        end
        E(w,:) = []; %TYPES(eid) = 3;
        
        
        %extraordinary-extraordinary
        w = K(E(:,1)) ~= 6  &  K(E(:,2)) ~= 6;
        Ew = E(w,:); eid = Ew(:,5);
        for n = 1:numel(eid)
          R = CIRCULARshift( RS{ Ew(n,1) }.' , Ew(n,2) );
          k = numel(R);
          switch k
            case 0,     s = [1/2,1/2,1/8,1/8,-1/16,-1/16,-1/16,-1/16]; R = Ew(n,[1:4 6:9]);
            case 3,     s = [ 5/12 , -1/12 , -1/12 ];
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,1) ];
            case 4,     s = [ 3/8 , 0 , -1/8 , 0 ];
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,1) ];
            otherwise,  s = ( 1/4 + cos( 2 * pi * (0:k-1) / k ) + 1/2 * cos( 4 * pi * (0:k-1) / k ) ) / k;
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,1) ];
          end
          add2G( eid(n) , R , s/2 );
%           if ~isempty(find(isnan(G(1:GN,2))))
%             1;
%           end
          
          R = CIRCULARshift( RS{ Ew(n,2) }.' , Ew(n,1) );
          k = numel(R);
          switch k
            case 0,     s = [1/2,1/2,1/8,1/8,-1/16,-1/16,-1/16,-1/16]; R = Ew(n,[1:4 6:9]);
            case 3,     s = [ 5/12 , -1/12 , -1/12 ];
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,2) ];
            case 4,     s = [ 3/8 , 0 , -1/8 , 0 ];
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,2) ];
            otherwise,  s = ( 1/4 + cos( 2 * pi * (0:k-1) / k ) + 1/2 * cos( 4 * pi * (0:k-1) / k ) ) / k;
                        s = [ s , 1-sum(s) ]; R = [ R , Ew(n,2) ];
          end
          add2G( eid(n) , R , s/2 );
%           if ~isempty(find(isnan(G(1:GN,2))))
%             1;
%           end
%           GN
        end
        E(w,:) = []; %TYPES(eid) = 4;

        if size( E ,1), warning('there are still Edges not processed'); end
        
        G = G( 1:GN ,:);
        
        G = sparse( G(:,1) , abs(G(:,2)) , G(:,3) , nE , nP );
        M.xyz = [ M.xyz ; G * double( M.xyz ) ];

        %TYPES = [ NaN( nP , 1 ) ; TYPES ];
        %setappdata(0,'butterfly',TYPES);
        
      case {'sqrt3'}
        if ~isequal( W(:).' , 1:nT ), error('SQRT3 subdivision is only valid when all faces are considered.'); end
        
        error('not implemented yet');
        
      case {'cubic hermite'}
        if ~isequal( W(:).' , 1:nT ), error('SQRT3 subdivision is only valid when all faces are considered.'); end
        
        error('not implemented yet');
        
      otherwise, error('unknown SubType for triangles.');
    end
    
  elseif M.celltype == 10          %% tetrahedral mesh
    switch lower(SubType)
      case {'default'},
        if isempty( W ), return; end

        allE = sort( [ T(:,[1 2]) ; T(:,[1 3]) ; T(:,[1 4]) ; T(:,[2 3]) ; T(:,[2 4]) ; T(:,[3 4]) ] ,2);

        while 1
          E = allE( [ W ; W + nT ; W + 2*nT ; W + 3*nT ; W + 4*nT ; W + 5*nT ] , : );
          E = unique( E , 'rows' );
          ET = reshape( ismember( allE , E , 'rows' ) , nT , 6 );
          Wp = W;

          W = false;
          W = W | sum( ET ,2) > 3;
          W = W | all( bsxfun(@eq, ET , [0 0 1 0 1 1] ) ,2);
          W = W | all( bsxfun(@eq, ET , [0 0 1 1 0 1] ) ,2);
          W = W | all( bsxfun(@eq, ET , [0 0 1 1 1 0] ) ,2);
          W = W | all( bsxfun(@eq, ET , [0 1 0 0 1 1] ) ,2);
          W = W | all( bsxfun(@eq, ET , [0 1 0 1 0 1] ) ,2);
          W = W | all( bsxfun(@eq, ET , [0 1 0 1 1 0] ) ,2);
          W = W | all( bsxfun(@eq, ET , [0 1 1 0 1 0] ) ,2);
          W = W | all( bsxfun(@eq, ET , [0 1 1 1 0 0] ) ,2);
          W = W | all( bsxfun(@eq, ET , [1 0 0 0 1 1] ) ,2);
          W = W | all( bsxfun(@eq, ET , [1 0 0 1 0 1] ) ,2);
          W = W | all( bsxfun(@eq, ET , [1 0 0 1 1 0] ) ,2);
          W = W | all( bsxfun(@eq, ET , [1 0 1 0 0 1] ) ,2);
          W = W | all( bsxfun(@eq, ET , [1 0 1 1 0 0] ) ,2);
          W = W | all( bsxfun(@eq, ET , [1 1 0 0 0 1] ) ,2);
          W = W | all( bsxfun(@eq, ET , [1 1 0 0 1 0] ) ,2);
          W = W | all( bsxfun(@eq, ET , [1 1 1 0 0 0] ) ,2);

          W = find( W );
          if isequal( Wp , W ), break; end
        end

        %tetras containing edges
%         ET = zeros( nT , 6 );
%         [ ~ , ET(:,1) ] = ismember( sort( T(:,[1 2]) ,2) , E , 'rows' );
%         [ ~ , ET(:,2) ] = ismember( sort( T(:,[1 3]) ,2) , E , 'rows' );
%         [ ~ , ET(:,3) ] = ismember( sort( T(:,[1 4]) ,2) , E , 'rows' );
%         [ ~ , ET(:,4) ] = ismember( sort( T(:,[2 3]) ,2) , E , 'rows' );
%         [ ~ , ET(:,5) ] = ismember( sort( T(:,[2 4]) ,2) , E , 'rows' );
%         [ ~ , ET(:,6) ] = ismember( sort( T(:,[3 4]) ,2) , E , 'rows' );
        
        [~,ET] = ismember2ROWS( allE , E(:,1:2) );
        ET = reshape( ET , [nT,6] );

        LET = ~~ET;  %logical ET
        %original faces to be removed
        W = find( any( LET ,2) ); %size(W)


        %indexes of the new points
        P = ( (nP+1):(nP+size(E,1)) ).';

        %middle points on edges
        for f = fieldnames( M ).'
          if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
          M.(f{1}) = [ M.(f{1}) ; ( M.(f{1})( E(:,1) ,:) + M.(f{1})( E(:,2) ,:) )/2 ];
        end
        if KP
          fn = fieldnames(M); fn = sort( fn( strncmp( fn , 'xyzParentEdge' ,13) ) );
          for f = fn(end:-1:1).', M = renameStructField( M , f{1} , [ f{1} , '_' ] ); end
          PE = (1:nP).'; PE(:,2) = 0;
          PE = [ PE ; double(E) ];
          PE( 1:nP ,3) = 0;
          PE( nP+1:end ,3) = 0.5;
          M.xyzParentEdge = PE;
        end
        
        %C = zeros( nT , 1);

        %first, tetras to be divided into 8.
        w = find( all(  bsxfun(@eq, LET , ~~[1 1 1 1 1 1] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p13  ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 8.1 ];
        T = [ T ;    p12  ,  p2   ,  p23  ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 8.2 ];
        T = [ T ;    p13  ,  p23  ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 8.3 ];
        T = [ T ;    p14  ,  p24  ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 8.4 ];
        T = [ T ;    p12  ,  p13  ,  p14  ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 8.5 ];
        T = [ T ;    p12  ,  p13  ,  p24  ,  p23  ]; F = [ F ; w ]; %C = [ C ; w*0 + 8.6 ];
        T = [ T ;    p13  ,  p14  ,  p24  ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 8.7 ];
        T = [ T ;    p13  ,  p23  ,  p34  ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 8.8 ];
        end

        %tetras to be divided at edge 1-2
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 0 0 0 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 12.1 ];
        T = [ T ;    p12  ,  p2   ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 12.2 ];
        end

        %tetras to be divided at edge 1-3
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 0 0 0 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p13  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 13.1 ];
        T = [ T ;    p13  ,  p2   ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 13.2 ];
        end

        %tetras to be divided at edge 1-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 1 0 0 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 14.1 ];
        T = [ T ;    p14  ,  p2   ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 14.2 ];
        end

        %tetras to be divided at edge 2-3
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 1 0 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p23  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 23.1 ];
        T = [ T ;    p1   ,  p23  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 23.2 ];
        end

        %tetras to be divided at edge 2-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 0 1 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p3   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 24.1 ];
        T = [ T ;    p1   ,  p24  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 24.2 ];
        end

        %tetras to be divided at edge 3-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 0 0 1] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 34.1 ];
        T = [ T ;    p1   ,  p2   ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 34.2 ];
        end

        %tetras to be divided at edge 1-3 & 2-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 0 0 1 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p13  ,  p4   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1324.1 ];
        T = [ T ;    p13  ,  p3   ,  p4   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1324.2 ];
        T = [ T ;    p1   ,  p13  ,  p24  ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1324.3 ];
        T = [ T ;    p13  ,  p3   ,  p24  ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1324.4 ];
        end

        %tetras to be divided at edge 1-2 & 3-4
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 0 0 0 1] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1234.1 ];
        T = [ T ;    p1   ,  p12  ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1234.2 ];
        T = [ T ;    p12  ,  p2   ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1234.3 ];
        T = [ T ;    p12  ,  p2   ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1234.4 ];
        end

        %tetras to be divided at edge 1-4 & 2-3
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 1 1 0 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p23  ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1423.1 ];
        T = [ T ;    p1   ,  p23  ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1423.2 ];
        T = [ T ;    p14  ,  p2   ,  p23  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1423.3 ];
        T = [ T ;    p14  ,  p23  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1423.4 ];
        end


        %tetras to be divided at edge 1-2 & 1-3 & 2-3
        w = find( all(  bsxfun(@eq, LET , ~~[1 1 0 1 0 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p13  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 121323.1 ];
        T = [ T ;    p12  ,  p2   ,  p23  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 121323.2 ];
        T = [ T ;    p13  ,  p23  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 121323.3 ];
        T = [ T ;    p12  ,  p23  ,  p13  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 121323.4 ];
        end

        %tetras to be divided at edge 2-3 & 2-4 & 3-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 1 1 1] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p23  ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 232434.1 ];
        T = [ T ;    p1   ,  p24  ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 232434.2 ];
        T = [ T ;    p1   ,  p23  ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 232434.3 ];
        T = [ T ;    p1   ,  p24  ,  p23  ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 232434.4 ];
        end

        %tetras to be divided at edge 1-3 & 1-4 & 3-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 1 0 0 1] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p13  ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 131434.1 ];
        T = [ T ;    p13  ,  p2   ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 131434.2 ];
        T = [ T ;    p14  ,  p2   ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 131434.3 ];
        T = [ T ;    p14  ,  p2   ,  p13  ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 131434.4 ];
        end

        %tetras to be divided at edge 1-2 & 1-4 & 2-4
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 1 0 1 0] ) ,2) );
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 121424.1 ];
        T = [ T ;    p12  ,  p2   ,  p3   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 121424.2 ];
        T = [ T ;    p14  ,  p24  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 121424.3 ];
        T = [ T ;    p12  ,  p24  ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 121424.4 ];
        end



        %tetras to be divided at edge 2-4 & 3-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 0 1 1] ) ,2) ); w( T(w,2) > T(w,3) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p24  ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 2434.1 ];
        T = [ T ;    p1   ,  p2   ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2434.2 ];
        T = [ T ;    p1   ,  p34  ,  p24  ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 2434.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 0 1 1] ) ,2) ); w( T(w,2) < T(w,3) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p24  ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 2434.4 ];
        T = [ T ;    p1   ,  p3   ,  p24  ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 2434.5 ];
        T = [ T ;    p1   ,  p24  ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2434.6 ];
        end

        %tetras to be divided at edge 2-3 & 2-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 1 1 0] ) ,2) ); w( T(w,3) > T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p23  ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2324.1 ];
        T = [ T ;    p1   ,  p3   ,  p4   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2324.2 ];
        T = [ T ;    p1   ,  p24  ,  p23  ,  p3   ]; F = [ F ; w ]; %C = [ C ; w*0 + 2324.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 1 1 0] ) ,2) ); w( T(w,3) < T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p23  ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2324.4 ];
        T = [ T ;    p1   ,  p4   ,  p24  ,  p23  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2324.5 ];
        T = [ T ;    p1   ,  p23  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 2324.6 ];
        end

        %tetras to be divided at edge 2-3 & 3-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 1 0 1] ) ,2) ); w( T(w,2) > T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p23  ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2334.1 ];
        T = [ T ;    p1   ,  p2   ,  p23  ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2334.2 ];
        T = [ T ;    p1   ,  p34  ,  p4   ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 2334.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 0 1 0 1] ) ,2) ); w( T(w,2) < T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p23  ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2334.4 ];
        T = [ T ;    p1   ,  p4   ,  p23  ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 2334.5 ];
        T = [ T ;    p1   ,  p23  ,  p4   ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 2334.6 ];
        end

        %tetras to be divided at edge 1-2 & 1-3
        w = find( all(  bsxfun(@eq, LET , ~~[1 1 0 0 0 0] ) ,2) ); w( T(w,2) > T(w,3) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p13  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1213.1 ];
        T = [ T ;    p2   ,  p3   ,  p13  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1213.2 ];
        T = [ T ;    p13  ,  p12  ,  p2   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1213.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[1 1 0 0 0 0] ) ,2) ); w( T(w,2) < T(w,3) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p13  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1213.4 ];
        T = [ T ;    p3   ,  p13  ,  p12  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1213.5 ];
        T = [ T ;    p12  ,  p2   ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1213.6 ];
        end

        %tetras to be divided at edge 1-2 & 1-4
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 1 0 0 0] ) ,2) ); w( T(w,2) > T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1214.1 ];
        T = [ T ;    p2   ,  p4   ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1214.2 ];
        T = [ T ;    p14  ,  p12  ,  p3   ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1214.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 1 0 0 0] ) ,2) ); w( T(w,2) < T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p12  ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1214.4 ];
        T = [ T ;    p4   ,  p14  ,  p3   ,  p12  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1214.5 ];
        T = [ T ;    p12  ,  p2   ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1214.6 ];
        end

        %tetras to be divided at edge 1-2 & 2-4
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 0 0 1 0] ) ,2) ); w( T(w,1) > T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p12  ,  p2   ,  p3   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1224.1 ];
        T = [ T ;    p1   ,  p12  ,  p3   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1224.2 ];
        T = [ T ;    p24  ,  p4   ,  p3   ,  p1   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1224.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 0 0 1 0] ) ,2) ); w( T(w,1) < T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p12  ,  p2   ,  p3   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1224.4 ];
        T = [ T ;    p4   ,  p12  ,  p3   ,  p24  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1224.5 ];
        T = [ T ;    p12  ,  p4   ,  p3   ,  p1   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1224.6 ];
        end

        %tetras to be divided at edge 1-2 & 2-3
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 0 1 0 0] ) ,2) ); w( T(w,1) > T(w,3) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p12  ,  p2   ,  p23  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1223.1 ];
        T = [ T ;    p1   ,  p12  ,  p23  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1223.2 ];
        T = [ T ;    p23  ,  p3   ,  p1   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1223.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[1 0 0 1 0 0] ) ,2) ); w( T(w,1) < T(w,3) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p12  ,  p2   ,  p23  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1223.4 ];
        T = [ T ;    p3   ,  p12  ,  p23  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1223.5 ];
        T = [ T ;    p12  ,  p3   ,  p1   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1223.6 ];
        end

        %tetras to be divided at edge 1-3 & 1-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 1 0 0 0] ) ,2) ); w( T(w,3) > T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p13  ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1314.1 ];
        T = [ T ;    p3   ,  p2   ,  p14  ,  p13  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1314.2 ];
        T = [ T ;    p14  ,  p2   ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1314.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 1 0 0 0] ) ,2) ); w( T(w,3) < T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p1   ,  p2   ,  p13  ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1314.4 ];
        T = [ T ;    p4   ,  p2   ,  p14  ,  p13  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1314.5 ];
        T = [ T ;    p13  ,  p2   ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1314.6 ];
        end

        %tetras to be divided at edge 1-4 & 3-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 1 0 0 1] ) ,2) ); w( T(w,1) > T(w,3) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p14  ,  p2   ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1434.1 ];
        T = [ T ;    p1   ,  p2   ,  p34  ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1434.2 ];
        T = [ T ;    p34  ,  p2   ,  p1   ,  p3   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1434.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 1 0 0 1] ) ,2) ); w( T(w,1) < T(w,3) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p14  ,  p2   ,  p34  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1434.4 ];
        T = [ T ;    p3   ,  p2   ,  p34  ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1434.5 ];
        T = [ T ;    p14  ,  p2   ,  p1   ,  p3   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1434.6 ];
        end

        %tetras to be divided at edge 1-4 & 2-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 1 0 1 0] ) ,2) ); w( T(w,1) > T(w,2) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p14  ,  p24  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1424.1 ];
        T = [ T ;    p1   ,  p24  ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1424.2 ];
        T = [ T ;    p24  ,  p1   ,  p3   ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1424.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[0 0 1 0 1 0] ) ,2) ); w( T(w,1) < T(w,2) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p14  ,  p24  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1424.4 ];
        T = [ T ;    p2   ,  p24  ,  p3   ,  p14  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1424.5 ];
        T = [ T ;    p14  ,  p1   ,  p3   ,  p2   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1424.6 ];
        end

        %tetras to be divided at edge 1-3 & 3-4
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 0 0 0 1] ) ,2) ); w( T(w,1) > T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p13  ,  p2   ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1334.1 ];
        T = [ T ;    p1   ,  p2   ,  p13  ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1334.2 ];
        T = [ T ;    p34  ,  p2   ,  p4   ,  p1   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1334.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 0 0 0 1] ) ,2) ); w( T(w,1) < T(w,4) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p13  ,  p2   ,  p3   ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1334.4 ];
        T = [ T ;    p4   ,  p2   ,  p13  ,  p34  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1334.5 ];
        T = [ T ;    p13  ,  p2   ,  p4   ,  p1   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1334.6 ];
        end

        %tetras to be divided at edge 1-3 & 2-3
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 0 1 0 0] ) ,2) ); w( T(w,1) > T(w,2) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p13  ,  p23  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1323.1 ];
        T = [ T ;    p1   ,  p23  ,  p13  ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1323.2 ];
        T = [ T ;    p23  ,  p1   ,  p2   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1323.3 ];
        end
        w = find( all(  bsxfun(@eq, LET , ~~[0 1 0 1 0 0] ) ,2) ); w( T(w,1) < T(w,2) ) = [];
        if ~isempty(w)
        p1  = T(w,1); p2  = T(w,2); p3  = T(w,3); p4  = T(w,4); try, p12 = P( ET(w, 1 ) ); end; try, p13 = P( ET(w, 2 ) ); end; try, p14 = P( ET(w, 3 ) ); end; try, p23 = P( ET(w, 4 ) ); end; try, p24 = P( ET(w, 5 ) ); end; try, p34 = P( ET(w, 6 ) ); end; ET(w,:) = 0;
        T = [ T ;    p13  ,  p23  ,  p3   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1323.4 ];
        T = [ T ;    p4   ,  p23  ,  p2   ,  p13  ]; F = [ F ; w ]; %C = [ C ; w*0 + 1323.5 ];
        T = [ T ;    p13  ,  p1   ,  p2   ,  p4   ]; F = [ F ; w ]; %C = [ C ; w*0 + 1323.6 ];
        end


        ET( ~any( ET ,2) ,:) = [];
        ET = unique( ~~ET , 'rows' );
        if ~isempty( ET )
          warning('ET is not empty');
          ET
        end
        
      case {'linear4'}
        if isempty( W ), return; end

        %indexes of the new points
        P = ( ( nP + 1):( nP + numel(W) ) ).';

        %middle points on faces
        for f = fieldnames( M ).', if ~strncmp( f{1} , 'xyz' , 3 ), continue; end
          M.(f{1}) = [ M.(f{1}) ; ( M.(f{1})( T(W,1) ,:) + M.(f{1})( T(W,2) ,:) + M.(f{1})( T(W,3) ,:) + M.(f{1})( T(W,4) ,:) )/4 ];
        end

        T = [ T ; ...
              [  P        , T(W, 2 ) , T(W, 3 ) , T(W, 4 ) ] ;...
              [  T(W, 1 ) , P        , T(W, 3 ) , T(W, 4 ) ] ;...
              [  T(W, 1 ) , T(W, 2 ) , P        , T(W, 4 ) ] ;...
              [  T(W, 1 ) , T(W, 2 ) , T(W, 3 ) , P        ] ;...
            ];
        F = [ F ; W ; W ; W ; W ];
        
      otherwise, error('Only ''default'' SubType is valid for tetrahedra.');
    end
    
  end
  
  M.tri      = T;
  F(W)       = [];
  M.tri(W,:) = [];            %remove the original faces
  %try, C(W,:)= []; end
  
  
  [F,ord] = sort( F );      %reorder the new faces in their "original position"
  M.tri = M.tri(ord,:);
  %try, C     = C(ord); end
  
  for f = fieldnames( M ).'
    if strcmp( f{1} , 'tri' ), continue; end
    if ~strncmp( f{1} , 'tri' , 3 ), continue; end
    M.(f{1}) = M.(f{1})(F,:,:,:,:,:,:);
  end
  %try, M.triCASE = C; end

  
  
  
  
  function add2G( aaa , bbb , vvv )
    nnn = numel(bbb);
    if ~nnn, return; end
    
    bbb = bbb(:);
    if numel(aaa) > 1 && numel(aaa) ~= nnn
      aaa = repmat( aaa , ceil( size(bbb)./size(aaa) ) );
      aaa = aaa(:); aaa = aaa(1:nnn);
    end
    if numel(vvv) ~= nnn && numel(vvv) > 1
      vvv = repmat( vvv , ceil( size(bbb)./size(vvv) ) );
      vvv = vvv(:); vvv = vvv(1:nnn);
    end

%     switch nnn
%       case 1,     iii = GN + ( 1 );
%       case 2,     iii = GN + ( 1:2 );
%       case 3,     iii = GN + ( 1:3 );
%       case 4,     iii = GN + ( 1:4 );
%       case 5,     iii = GN + ( 1:5 );
%       case 6,     iii = GN + ( 1:6 );
%       case 7,     iii = GN + ( 1:7 );
%       case 8,     iii = GN + ( 1:8 );
%       case 9,     iii = GN + ( 1:9 );
%       case 10,    iii = GN + ( 1:10 );
%       case 11,    iii = GN + ( 1:11 );
%       case 12,    iii = GN + ( 1:12 );
%       case 13,    iii = GN + ( 1:13 );
%       case 14,    iii = GN + ( 1:14 );
%       case 15,    iii = GN + ( 1:15 );
%       case 16,    iii = GN + ( 1:16 );
%       case 17,    iii = GN + ( 1:17 );
%       case 18,    iii = GN + ( 1:18 );
%       case 19,    iii = GN + ( 1:19 );
%       case 20,    iii = GN + ( 1:20 );
%       otherwise,  
        iii = ( GN + 1 ):( GN + nnn );
%     end
    
    sz_G = size(G,1);
    if sz_G <= iii(end)
      %G( ( sz_G+1 ):( iii(end)*2 ) ,:) = NaN;
      G( end+1:(iii(end)*2) ,:) = NaN;
    end
    
    G( iii ,1) = aaa(:);
    G( iii ,2) = bbb(:);
    G( iii ,3) = vvv(:);
    
    GN = GN + nnn;
  end
  
end

function A = uniqueROWS( A , cols )
  if isempty( A ), return; end
  A = sortROWS( A , cols );
  w = [ true ; any( diff( A , 1 , 1 ) ,2) ];
  A = A(w,:);
end
function A = sortROWS( A , cols )
  for c = cols(end:-1:1)
    [~,ord] = sort( A(:,c) );
    A = A(ord,:);
  end
end
function varargout = ismember2ROWS( A , B )
  try
    if size( A ,2) == 2
      A = A(:,1) + 1i*A(:,2);
    elseif size(A,2) > 2
      error('A has more than 2 columns');
    end
    if size( B ,2) == 2
      B = B(:,1) + 1i*B(:,2);
    elseif size(B,2) > 2
      error('B has more than 2 columns');
    end

    [varargout{1:nargout}] = ismember( A , B );
  catch
    [varargout{1:nargout}] = ismember( A , B , 'rows' );
  end
end
function R = CIRCULARshift( R , b )
  if R(1) ~= R(end)
    R = [];
  else
    id = find( R == b );
    R = R( [ id:end-1 , 1:id-1 ] );
  end
end