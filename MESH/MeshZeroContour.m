function C = MeshZeroContour( M , V , KP )
% normals pointing to the positive!

  if nargin < 3, KP = false; end
  if ischar( KP ) && ( strcmpi( KP ,'kp' ) || strcmpi( KP ,'keepparent' ) || strcmpi( KP ,'keepparentedge' ) )
    KP = true;
  end


  if isa( V , 'function_handle' )
    try, V = feval( V , M ); catch
    try, V = feval( V , M.xyz ); catch
      error('invalid function to evaluate on mesh');
    end; end
  elseif ischar( V )
    try, V = M.(['xyz',V]); catch
    try, V = M.(V); catch
      error('invalid attribute name.');
    end; end
  elseif isnumeric( V ) && isequal( size( V ) , [4 4] )
    V = distance2Plane( M.xyz , V , true );
  end
  if numel( V ) ~= size( M.xyz ,1)
    error('invalid scalar for contouring');
  end

  
  M = MeshOrderCells( M , V );
  s = reshape( sign( V( M.tri ) ) ,size(M.tri) ); s( ~s ) = 1;

  C = struct();

  P   = [];
  T   = [];
  Tid = [];
  
  M.celltype = meshCelltype( M );
  switch M.celltype
    case 3,   M.celltype = 1;

      t = all( bsxfun( @eq , s , [ -1 ,  1 ] ) ,2); 
      addCELLS( t ,1); P = [ P ; E(1,2) ];
      
      t = all( bsxfun( @eq , s , [  1 , -1 ] ) ,2); 
      addCELLS( t ,1); P = [ P ; E(1,2) ];

    case 5,   M.celltype = 3;

      t = all( bsxfun( @eq , s , [ -1 , -1 ,  1 ] ) ,2); 
      addCELLS( t ,2); P = [ P ; E(2,3) ; E(1,3) ];
      
      t = all( bsxfun( @eq , s , [ -1 ,  1 , -1 ] ) ,2); 
      addCELLS( t ,2); P = [ P ; E(1,2) ; E(2,3) ];

      t = all( bsxfun( @eq , s , [ -1 ,  1 ,  1 ] ) ,2); 
      addCELLS( t ,2); P = [ P ; E(1,2) ; E(1,3) ];
      
    case 10,    M.celltype = 5;
      
      t = all( bsxfun( @eq , s , [ -1 , -1 , -1 ,  1 ] ) ,2); 
      addCELLS( t ,3); P = [ P ; E(4,1) ; E(4,2) ; E(4,3) ];
      
      t = all( bsxfun( @eq , s , [ -1 , -1 ,  1 , -1 ] ) ,2); 
      addCELLS( t ,3); P = [ P ; E(3,1) ; E(3,4) ; E(3,2) ];
      
      t = all( bsxfun( @eq , s , [ -1 , -1 ,  1 ,  1 ] ) ,2);
      addCELLS( t ,3); P = [ P ; E(4,1) ; E(4,2) ; E(3,1) ];
      addCELLS( t ,3); P = [ P ; E(3,1) ; E(4,2) ; E(3,2) ];
      
      t = all( bsxfun( @eq , s , [ -1 ,  1 ,  1 ,  1 ] ) ,2); 
      addCELLS( t ,3); P = [ P ; E(3,1) ; E(4,1) ; E(2,1) ];

    otherwise, error('not implemented yet'); 
  end

  P = double( P );
  P = sort( P , 2 );
  P = [ P , V( P(:,1) ) ./ ( V( P(:,1) ) - V( P(:,2) ) ) ];
  w   = P(:,3) == 1; P(w,1) = P(w,2); P(w,3) = 0;
  w   = P(:,3) == 0; P(w,2) = 1;

  [P,~,b] = unique( P , 'rows' , 'stable' ); T = reshape( b( T ) ,size(T) );
  for i = 1:size(T,2)-1
    for j = i+1:size(T,2)
      w = T(:,i) == T(:,j);
      T(w,:) = [];
      Tid(w) = [];
    end
  end

  for f = fieldnames( M ).', f = f{1};
    if strncmp( f , 'xyz' , 3 )
      if ~isfloat( M.(f) ), M.(f) = double( M.(f) ); end
      C.(f) = bsxfun( @times , 1-P(:,3) , M.(f)( P(:,1) ,:,:,:,:,:) ) + bsxfun( @times , P(:,3) , M.(f)( P(:,2) ,:,:,:,:,:) );
    elseif strcmp( f , 'tri' )
      C.(f) = T;
    elseif strncmp( f , 'tri' , 3 )
      C.(f) = M.(f)( Tid ,:,:,:,:,:,:);
    end
  end
  if KP
    fn = fieldnames(C); fn = sort( fn( strncmp( fn , 'xyzParentEdge' ,13) ) );
    for f = fn(end:-1:1).', C = renameStructField( C , f{1} , [ f{1} , '_' ] ); end
    P( P(:,3) == 0 ,2) = 0;
    C.xyzParentEdge = P;
  end
  C.celltype = M.celltype;

  function e = E(a,b), e = M.tri( t , [a,b] ); end
  function addCELLS( t , n )
    nt = sum( t ); if ~nt, return; end
    T = [ T ;  size( P ,1) + reshape( 1:(nt*n) ,nt,n) ];
    Tid = [ Tid ; find( t(:) ) ];
  end
  
end
