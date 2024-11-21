function C = MeshClip( M , V , varargin )
% clip out the positives

  insideOut = false;
  KP = false;
  for v = 1:numel(varargin)
    if ischar( varargin{v} ) && ...
       ( strcmpi( varargin{v} ,'kp' ) || strcmpi( varargin{v} ,'keepparent' ) || strcmpi( varargin{v} ,'keepparentedge' ) )
      KP = true; continue;
    end
    insideOut = varargin{v};
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
  
  BOTH = false;
  if isequal( insideOut , 2), insideOut = 'both'; end
  if ~ischar( insideOut ), insideOut = ~~insideOut; end
  if numel( insideOut ) && islogical( insideOut ) && insideOut
    V = -V;
  elseif numel( insideOut ) && islogical( insideOut ) && ~insideOut
  elseif ischar( insideOut ) && ( strcmp( insideOut , 'both' ) || strcmp( insideOut , 'b' ) )
    BOTH = true;
  else
    error( 'invalid option' );
  end
  
  
  M = MeshOrderCells( M , V );
  s = reshape( sign( V( M.tri ) ) ,size(M.tri) ); s( ~s ) = 1;

  C = struct();

  P   = [];
  T   = []; Tid = [];
  W   = []; Wid = [];
  
  M.celltype = meshCelltype( M );
  switch M.celltype
    case 3

      t = all( bsxfun( @eq , s , [ -1 ,  1 ] ) ,2); 
      addCELLS( t ,2); P = [ P ; E(1,1) ; E(1,2) ];
      if BOTH
      addCELLS( t ,2); P = [ P ; E(1,2) ; E(2,2) ];
      end
      
      t = all( bsxfun( @eq , s , [  1 , -1 ] ) ,2); 
      addCELLS( t ,2); P = [ P ; E(1,2) ; E(2,2) ];
      if BOTH
      addCELLS( t ,2); P = [ P ; E(1,1) ; E(1,2) ];
      end
      
    case 5

      t = all( bsxfun( @eq , s , [ -1 , -1 ,  1 ] ) ,2); 
      addCELLS( t ,3); P = [ P ; E(1,1) ; E(2,3) ; E(1,3) ];
      addCELLS( t ,3); P = [ P ; E(1,1) ; E(2,2) ; E(2,3) ];
      if BOTH
      addCELLS( t ,3); P = [ P ; E(1,3) ; E(2,3) ; E(3,3) ];
      end

        
      t = all( bsxfun( @eq , s , [ -1 ,  1 , -1 ] ) ,2); 
      addCELLS( t ,3); P = [ P ; E(1,1) ; E(1,2) ; E(2,3) ];
      addCELLS( t ,3); P = [ P ; E(1,1) ; E(2,3) ; E(3,3) ];
      if BOTH
      addCELLS( t ,3); P = [ P ; E(1,2) ; E(2,2) ; E(2,3) ];
      end

      t = all( bsxfun( @eq , s , [ -1 ,  1 ,  1 ] ) ,2); 
      addCELLS( t ,3); P = [ P ; E(1,1) ; E(1,2) ; E(1,3) ];
      if BOTH
      addCELLS( t ,3); P = [ P ; E(1,2) ; E(2,2) ; E(1,3) ];
      addCELLS( t ,3); P = [ P ; E(1,3) ; E(2,2) ; E(3,3) ];
      end
      
    case 10
      
      t = all( bsxfun( @eq , s , [ -1 , -1 , -1 ,  1 ] ) ,2);
      addWEDGES( t );  P = [ P ; E(2,2) ; E(1,1) ; E(3,3) ; E(2,4) ; E(1,4) ; E(3,4) ];
      if BOTH
      addCELLS( t ,4); P = [ P ; E(1,4) ; E(2,4) ; E(3,4) ; E(4,4) ];
      end
      
      t = all( bsxfun( @eq , s , [ -1 , -1 ,  1 , -1 ] ) ,2); 
      addWEDGES( t );  P = [ P ; E(1,1) ; E(2,2) ; E(4,4) ; E(1,3) ; E(2,3) ; E(3,4) ];
      if BOTH
      addCELLS( t ,4); P = [ P ; E(1,3) ; E(2,3) ; E(3,3) ; E(3,4) ];
      end
      
      t = all( bsxfun( @eq , s , [ -1 , -1 ,  1 ,  1 ] ) ,2);
      addWEDGES( t );  P = [ P ; E(1,4) ; E(1,1) ; E(1,3) ; E(2,4) ; E(2,2) ; E(2,3) ];
      if BOTH
      addWEDGES( t );  P = [ P ; E(1,4) ; E(2,4) ; E(4,4) ; E(1,3) ; E(2,3) ; E(3,3) ];
      end
      
      t = all( bsxfun( @eq , s , [ -1 ,  1 ,  1 ,  1 ] ) ,2); 
      addCELLS( t ,4); P = [ P ; E(1,1) ; E(1,2) ; E(1,3) ; E(1,4) ];
      if BOTH
      addWEDGES( t );  P = [ P ; E(1,3) ; E(1,2) ; E(1,4) ; E(3,3) ; E(2,2) ; E(4,4) ];
      end
      
    otherwise, error('not implemented for this celltype');
  end
  

  P = double( P );
  P = sort( P , 2 );
  P = [ P , V( P(:,1) ) ./ ( V( P(:,1) ) - V( P(:,2) ) ) ];
  P( ~isfinite( P(:,3) ) ,3) = 0;
  w   = P(:,3) == 1; P(w,1) = P(w,2); P(w,3) = 0;
  w   = P(:,3) == 0; P(w,2) = 1;

  [P,~,b] = unique( P , 'rows' , 'stable' ); T = reshape( b( T ) ,size(T) );
  
  if ~isempty( W )
    W = reshape( b( W ) ,size(W) );

    W = struct( 'tri' , W , 'triWid' , Wid , 'celltype' , 13 );
    %W.xyz = bsxfun( @times , 1-P(:,3) , M.xyz( P(:,1) ,:) ) + bsxfun( @times , P(:,3) , M.xyz( P(:,2) ,:) );
    %W.xyz      = M.xyz( P(:,1) ,:) + M.xyz( P(:,2) ,:);
    W.xyz      = zeros( size(P,1) , 3 );
    
    W = MeshClip_tetrahedralize_helper( W );

    Tid = [ Tid ; W.triWid ];
    T   = [ T   ; W.tri    ];
  end
    
  for i = 1:size(T,2)-1
    for j = i+1:size(T,2)
      w = T(:,i) == T(:,j);
      T(w,:) = [];
      Tid(w) = [];
    end
  end

  %inclussion of the non-clipped original cells
  oP = ( 1:size(M.xyz,1) ).'; oP(:,2) = 1; oP(:,3) = 0;
  oT = all( bsxfun( @eq , s , -1 ) ,2);
  if BOTH, oT = oT | all( bsxfun( @eq , s , 1 ) ,2); end
  Tid = [ find( oT(:) ) ; Tid ];
  T = [ M.tri( oT ,:) ; size(oP,1) + T ];
  P = [ oP ; P ];
  
  [P,~,b] = unique( P , 'rows' , 'stable' ); T = reshape( b( T ) ,size(T) );

  nid = unique( T(:) );
  map = zeros( numel(nid) ,1);
  map( nid ) = 1:numel(nid);
  P = P( nid ,:);
  T = reshape( map( T ) ,size(T) );

  %[P,~,b] = unique( P , 'rows' , 'stable' ); T = reshape( b( T ) ,size(T) );
  [Tid,ord] = sort( Tid ); T = T( ord ,:);
  %
  
  
  for f = fieldnames( M ).', f = f{1};
    if strncmp( f , 'xyz' , 3 )
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
  function addWEDGES( t )
    nt = sum( t ); if ~nt, return; end
    W = [ W ;  size( P ,1) + reshape( 1:(nt*6) ,nt,6) ];
    Wid = [ Wid ; find( t(:) ) ];
  end  
  
end
