function [ M , pIDS ] = MeshTidy( M , varargin )
% TODO
% - allow to keep the unused nodes
% - add a white list of no-merge nodes
% - split at non-manifold

if 0
%%

  rand('seed',0);
  M.xyz = rand(400,2);
  M.tri = delaunayn( M.xyz(10:200,:) )+10-1;
  M.xyz([17 18],:) = [1;1]*mean( M.xyz([17 18],:) , 1 );
  M.xyzZ = rand(size(M.xyz,1),3);
  
  subplot(121); plotMESH( M ); hplot3d( M.xyz , 'okr' )
  
  [MT,pid] = MeshTidy( M , 0.1 ,false,[1 1 1],'rem' ,'sf','sn')
  subplot(122); plotMESH( MT ); hplot3d( MT.xyz , 'okr' )


%%
end

  [M,IDSname] = MeshGenerateIDs( M , 'xyz_' );

  mergeRadius       = NaN;
  keepUNUSED        = false;
  useUNIQUETOL      = false;
  metric            = 1;
  removeSingular    = false;
  removeCollapsed   = false;
  removeRepeated    = false;
  removeCoincident  = false;
  combineFaces      = false;

  sortNodes         = false;
  sortFaces         = false;
  remALL            = [];
  
  
  for v = 1:find( ~cellfun( @ischar , varargin ) ,1,'last' )
    switch v
      case 1, mergeRadius = varargin{v};
      case 2, remALL      = varargin{v};
      case 3, metric      = varargin{v};
      otherwise, error('check varargin!!');
    end
  end
  varargin(1:v) = [];
  if isempty( remALL )
    if mergeRadius == 0
      remALL = true;
    else
      remALL = false; 
    end
  end
  
  try, [varargin,~,mergeRadius    ] = parseargs(varargin, 'mergeRadius','radius' ,'$DEFS$',mergeRadius ); end
  try, [varargin,useUNIQUETOL     ] = parseargs(varargin, 'useUNIQUETOL'         ,'$FORCE$',{true,useUNIQUETOL     } ); end
  try, [varargin,~,metric         ] = parseargs(varargin, 'Metric'               ,'$DEFS$',metric      ); end
  
  try, [varargin,removeSingular   ] = parseargs(varargin, 'RemoveSingular'       ,'$FORCE$',{true,removeSingular   } ); end
  try, [varargin,removeCollapsed  ] = parseargs(varargin, 'RemoveCollapsed'      ,'$FORCE$',{true,removeCollapsed  } ); end
  try, [varargin,removeRepeated   ] = parseargs(varargin, 'RemoveRepeated'       ,'$FORCE$',{true,removeRepeated   } ); end
  try, [varargin,removeCoincident ] = parseargs(varargin, 'RemovecoiNcident'     ,'$FORCE$',{true,removeCoincident } ); end
  try, [varargin,combineFaces     ] = parseargs(varargin, 'CombineFaces'         ,'$FORCE$',{true,combineFaces     } ); end
  
  try, [varargin,remALL         ] = parseargs(varargin, 'REMoveall'            ,'$FORCE$',{true,remALL  } ); end
  if remALL
    removeSingular    = true;
    removeCollapsed   = true;
    removeRepeated    = true;
    removeCoincident  = true;
  end

  try, [varargin,sortNodes ] = parseargs(varargin, 'SortNodes'       ,'$FORCE$',{true,sortNodes } ); end
  try, [varargin,sortFaces ] = parseargs(varargin, 'SortFaces'       ,'$FORCE$',{true,sortFaces } ); end
  

  M = renameStructField( M , 'uv' , 'xyz___UV___' );
  
  classTRI = class( M.tri );
  %classXYZ = class( M.xyz );
  
  Fs = fieldnames( M );
  Fxyz = Fs( strncmp( Fs , 'xyz' , 3 ) ); Fxyz = Fxyz(:).';
  Ftri = Fs( strncmp( Fs , 'tri' , 3 ) ); Ftri = Ftri(:).';
  if isfield( M , 'celltype' ) && ~isscalar( M.celltype )
    Ftri{1,end+1} = 'celltype';
  end

  %remove NaNs and Infs
  w = all( isfinite( M.xyz ) ,2);
  keepXYZ( w );

  %remove unused nodes
  if ~keepUNUSED
    keepXYZ( loss( M.tri ) );
  end
  
  if mergeRadius >= 0
    X = M.xyz;
    for f = Fxyz, f = f{1};
      if strcmp( f , 'xyz'   ), continue; end
      if strcmp( f , IDSname ), continue; end
      if ~isnumeric( M.(f) ), continue; end
      thisX = M.(f);
      thisX = thisX(:,:);
      w = all( bsxfun( @eq , thisX , thisX(1,:) ) ,1);
      thisX(:, w ) = [];
      X = [ X , thisX ];
    end
    metric( end+1:size(X,2) ) = metric(end);
    metric = metric( 1:size(X,2) );
    metric = metric(:).';
    metric( ~isfinite( metric ) ) = 0;
    w = metric == 0;
    X(:,w) = []; metric( w ) = [];
    if isempty( X )
      error('Singular metric!!');
    end
    metric = sqrt( metric );
    if any( metric ~= 1 )
      X = bsxfun( @times , X , metric );
    end
    w = all( bsxfun( @eq , X , X(1,:) ) ,1);
    X(:, w ) = [];

    w = any( ~isfinite( X ) ,1);
    X(:, w ) = [];

    if isempty( X )
      X = zeros( size( M.xyz ,1) ,1);
    end
  end
  
  if mergeRadius == 0
    [~,a,b] = unique( X , 'rows' );
    [a,ord] = sort( a );
    iord = zeros( numel(ord) ,1); iord( ord ) = 1:numel(ord);
    b = iord( b );

    %[~,aa,bb] = unique( X , 'rows' , 'stable' );
    %maxnorm(a,aa),maxnorm(b,bb)
    
    map = a( b );

    z = ~M.tri; M.tri(z) = 1; M.tri = map( M.tri ); M.tri(z) = 0;
    if ~keepUNUSED
      keepXYZ( loss( M.tri ) );
    end
  elseif mergeRadius > 0
    if useUNIQUETOL
      [~,a,b] = uniquetol( X , mergeRadius , 'byrows',true);
      [a,ord] = sort( a );
      iord = zeros( numel(ord) ,1); iord( ord ) = 1:numel(ord);
      b = iord( b );
      map = a( b );
    else
      map = mergePoints( X , mergeRadius );
    end
    
    z = ~M.tri; M.tri(z) = 1; M.tri = map( M.tri ); M.tri(z) = 0;
    if ~keepUNUSED
      keepXYZ( loss( M.tri ) );
    end
  end

  if removeCollapsed && size( M.tri ,2) > 1
    w = any( ~bsxfun( @eq , M.tri , M.tri(:,1) ) ,2);
    keepTRI( w );
    if ~keepUNUSED
      keepXYZ( loss( M.tri ) );
    end
  end
  
  if removeSingular
    for i = 1:size( M.tri ,2)-1
      for j = i+1:size( M.tri ,2)
        w = ( M.tri( : ,i) ~= M.tri( : ,j) )  |  ( ~M.tri( : ,i)  &  ~M.tri( : ,j) );
        if ~all(w)
          keepTRI( w );
        end
      end
    end
    if ~keepUNUSED
      keepXYZ( loss( M.tri ) );
    end
  end
  
  if removeCoincident
    F = sort( M.tri , 2 );
    [~,w] = unique( F , 'rows' , 'first' );
    keepTRI( loss( w ) );
  end
  
  if removeRepeated   &&  ~removeCoincident
    [F,b] = sort( M.tri , 2 );
    pp = parity(b);
    F( pp , [end-1,end] ) = F( pp , [end,end-1] );

    [~,w] = unique( F , 'rows' , 'first' );
    keepTRI( loss( w ) );
  end
  
  if sortNodes
    [~,b] = sortrows( M.xyz , size(M.xyz,2):-1:1 );
    M.tri = MAP( b , M.tri );
    for f = Fxyz, f = f{1};
      M.(f) = M.(f)( b ,:,:,:,:,:,:,:,:,:);
    end
  end
  
  if sortFaces
    z = ~M.tri; M.tri(z) = Inf;
    [M.tri,b] = sort( M.tri , 2 );
    M.tri(z) = 0;
    
    pp = parity(b);
    M.tri( pp , [end-1,end] ) = M.tri( pp , [end,end-1] );

    [~,b] = sortrows( M.tri );
    for f = Ftri, f = f{1};
      M.(f) = M.(f)( b ,:,:,:,:,:,:,:,:,:);
    end
  end


  if combineFaces
    %remove the ones with a corresponding with the opposite parity
    [F,p] = sort( M.tri , 2 );
    p = parity(p);
    [~,~,c] = unique( F ,'rows' ,'stable');
    w = p(c); p(w) = 1-p(w);
    
    F = [ F , (p - 0.5)*2 , ( 1:size(M.tri,1) ).' ];
    %[~,w] = sort( F(:,end-1) );       F = F(w,:);
    
    w = F(:,end-1) == -1;
    F = [ F(w,:) ; flip( F(~w,:) ,1) ];
    %F = [ flip( F(w,:) ,1) ; F(~w,:) ];
    
    [~,w] = sortrows( F(:,1:end-2) ); F = F(w,:);
    
    while 1
      w = all( F( 1:end-1 ,1:end-2) == F( 2:end ,1:end-2) ,2) &...
               F( 1:end-1 ,end-1) == -F( 2:end ,end-1);
             
      w = find(w);
      if isempty(w), break; end
      F( [ w ; w+1 ] ,:) = [];
    end
    
    keepTRI( loss( F(:,end) ) );

    if ~keepUNUSED
      keepXYZ( loss( M.tri ) );
    end
  end


  while all( ~M.tri(:,end) ,1)
    M.tri(:,end) = [];
  end
  [~,b] = sort( sum( ~M.tri ,2) , 'descend' );
  for f = Ftri, f = f{1};
    M.(f) = M.(f)( b ,:,:,:,:,:,:,:,:,:);
  end
  if isfield( M , 'celltype' ) && all( M.celltype == M.celltype(1) )
    M.celltype = M.celltype(1);
  end
  
  
  try, M.tri = feval( classTRI , M.tri ); end
  %try, M.xyz = feval( classXYZ , M.xyz ); end

  
  if nargout > 1
    pIDS = M.(IDSname);
  end
  M = rmfield( M , IDSname );
  

  M = renameStructField( M , 'xyz___UV___' , 'uv' );
  
  
  
  function keepXYZ( nid )
    %if islogical( nid )  &&  numel( nid ) == size( M.xyz ,1)  &&  all( nid )
    if numel( nid ) == size( M.xyz ,1)  &&  all( nid )
      return;
    end
%     if isnumeric( nid )
%       error('here??');
%       nid = sort( nid(:) );
%       if isequal( nid.' , 1:size( M.xyz ,1) )
%         return;
%       end
%     end
    for f = Fxyz, f = f{1};
      M.(f) = M.(f)( nid ,:,:,:,:,:,:,:,:,:);
    end
    if islogical( nid ), nid = find( nid ); end

    fid = all( ismember( M.tri , nid ) | ~M.tri , 2 );
    if ~all(fid), keepTRI( fid ); end
    
    M.tri = MAP( nid , M.tri );
  end

  function keepTRI( fid )
    %if islogical( fid )  &&  numel( fid ) == size( M.tri ,1)  &&  all( fid ) 
    if numel( fid ) == size( M.tri ,1)  &&  all( fid ) 
      return;
    end
%     if isnumeric( fid )
%       error('here??');
%       fid = sort( fid(:) );
%       if isequal( fid.' , 1:size( M.tri ,1) )
%         return;
%       end
%     end
    for f = Ftri, f = f{1};
      M.(f) = M.(f)( fid ,:,:,:,:,:,:,:,:,:);
    end
%     if isfield( M , 'celltype' ) && ~isscalar( M.celltype )
%       M.celltype = M.celltype( fid ,1);
%     end
  end
  function m = MAP( id , T )
    m = zeros( size(M.xyz,1) , 1 ); m( id ) = 1:numel( id );
    if nargin > 1
      z = ~T;
      T(z) = 1;
      m = reshape( m( T ) , size(T) );
      m(z) = 0;
    end
  end
  
end


function [M,pID] = MeshTidy_old( M , th , REMOVE_COLLAPSED , METRIC )

  %first remove nans
  w = find( any( isnan( M.xyz ) ,2 ) );
  M.xyz( w ,:) = -1e+308;
  w = any( ismember( M.tri , w ) ,2);
  M.tri( w ,:) = [];
  if isfield( M , 'celltype' ) && ~isscalar( M.celltype )
    M.celltype( w ,:) = [];
  end
  
  dots = repmat( {':'} , [1,20]);

  if nargin < 2 || isempty( th )
    EL = [];
    for i = 1:size(M.tri,2)
      for j = i+1:size(M.tri,2)
        EL = [ EL ; M.tri(:,[i,j]) ];
      end
    end
    EL = sort( EL , 2 );
    EL = unique( EL ,'rows' );
    EL = M.xyz( EL(:,1) , : ) - M.xyz( EL(:,2) , : );
    EL = sum( EL.^2 , 2 );
    
    EL( ~EL ) = [];
    th = sqrt( min( EL ) )/2;
  end
  if nargin < 3 || isempty( REMOVE_COLLAPSED ), REMOVE_COLLAPSED = true;  end
  if nargin < 4 || isempty( METRIC ),           METRIC = 1;               end
  METRIC = sqrt(METRIC(:).');
  
  
  Fs = fieldnames( M );
  Fxyz = Fs( strncmp( Fs , 'xyz' , 3 ) ); Fxyz = Fxyz(:).';
  Ftri = Fs( strncmp( Fs , 'tri' , 3 ) ); Ftri = Ftri(:).';
  if isfield( M , 'celltype' ) && ~isscalar( M.celltype )
    Ftri{end+1} = 'celltype';
  end
  
  
  
  usedNODES = unique( M.tri(:) , 'sorted' );
  newIDX = zeros( max( usedNODES ) , 1 );
  newIDX( usedNODES ) = 1:numel(usedNODES);
  
  M.tri = reshape( newIDX( M.tri ) , size( M.tri ) );
  for f = Fxyz
    M.(f{1}) = M.(f{1})(usedNODES,dots{:});
  end

  
  
  if th < 0
    %remove the collapsed faces
    if REMOVE_COLLAPSED
      properFaces = all( diff( sort( M.tri , 2 ) , 1 , 2 ) , 2 );
      for f = Ftri
        M.(f{1}) = M.(f{1})( properFaces ,dots{:});
      end
    end    
    return;
  end

  X = [];
  for f = Fxyz
    X = [ X , M.(f{1}) ];
  end
  X = bsxfun(@times, X , METRIC(1:min(end,size(X,2))) );
  X( : , all( isnan( X ) , 1 ) ) = [];

  [~,usedNODES,newIDX] = unique( M.xyz , 'rows' , 'stable' );
  if numel( usedNODES ) ~= size( M.xyz , 1 )
    usedNODES = sort( usedNODES );
    M.tri = newIDX( M.tri );
    for f = Fxyz
      M.(f{1}) = M.(f{1})(usedNODES,dots{:});
    end
    if th > 0, X = X( usedNODES ,:); end
  end  
  
  if th == 0
    %remove the collapsed faces
    if REMOVE_COLLAPSED
      properFaces = all( diff( sort( M.tri , 2 ) , 1 , 2 ) , 2 );
      for f = Ftri
        M.(f{1}) = M.(f{1})( properFaces ,dots{:});
      end
    end    
    return;
  end
  
  
  
  %inter-nodes distance
  D = ipd( X , [] );
  D( D > th ) = Inf;

  %new indexes... on each "cluster" used the node with lower index
  newIDX = double( isfinite( D ) );
  newIDX( ~~newIDX ) = 1:sum( newIDX(:) );
  newIDX(  ~newIDX ) = Inf;
  [~,newIDX] = min( newIDX , [] , 2 );
  
  %remap faces
  M.tri = newIDX( M.tri );
  
  %remove the fullCollapsed faces
  if true
    notCollapsedFaces = ~~var( M.tri , [] , 2 );
    for f = Ftri
      M.(f{1}) = M.(f{1})( notCollapsedFaces ,dots{:});
    end
  end
  
  %remove the collapsed faces
  if REMOVE_COLLAPSED
    properFaces = all( diff( sort( M.tri , 2 ) , 1 , 2 ) , 2 );
    for f = Ftri
      M.(f{1}) = M.(f{1})( properFaces ,dots{:});
    end
  end
  
  usedNODES = unique( M.tri , 'sorted' );
  %average the coordinate and attributes of the "clusters"
  for n = usedNODES(:).'
    w = ~isinf( D(n,:) );
    for f = Fxyz
      M.(f{1})(n,dots{:}) = mean( M.(f{1})(w,dots{:}) , 1 );
    end
  end
  
  %remove unused nodes
  for f = Fxyz
    M.(f{1}) = M.(f{1})(usedNODES,dots{:});
  end
  
  %remap the faces after unused nodes were removed.
  newIDX( usedNODES ) = 1:numel( usedNODES );
  M.tri = newIDX( M.tri );
  
  if nargout > 1
    nX = [];
    for f = Fxyz
      nX = [ nX , M.(f{1}) ];
    end
    nX = bsxfun(@times, nX , METRIC(1:min(end,size(X,2))) );
    nX( : , all( isnan( nX ) , 1 ) ) = [];
    
    %D = bsxfun( @minus , permute( nX , [1 3 2] ) , permute( X , [3 1 2] ) );
    %D = D.^2;
    %D = sum( D , 3 );
    D = ipd( nX , X );

    [~,pID] = min( D , [] , 2 );
  end
  
  
  
if 0
%% find singular non-manifoldness
ED = meshEdges( M.tri );
A = sparse( ED(:,1) , ED(:,2) , true , size( M.xyz,1) , size( M.xyz,1) );
A = A+A.';
arrayfun( @(i)numel( SortChain( find( A(:,i) ) , ED ) ) , 1:size(A,2) ) .* full(~~sum( A ,1))
  
end
  
  
  
  
  
end

function IDS = mergePoints( X , radius )
  IDS       = ( 1:size( X ,1) ).';
  c         = size( X , 2);
  X(:,c+1)  = IDS;

  it = 0;
  while size( X ,1) > 1
    if ~rem(it,20) && size( X ,1) > 10
      Y = X(:,1:c);
      try,    KD = KDTreeSearcher( Y ,'distance','Euclidean');
      catch,  KD = Y;
      end
      [~,d] = knnsearch( KD , Y ,'K',2);
      X( d(:,2) > radius ,:) = [];
    end
    if isempty( X ), return; end
    it = it + 1;

    Y = X(:,1:c);
    try,    KD = KDTreeSearcher( Y ,'distance','Euclidean');
    catch,  KD = Y;
    end
    id = rangesearch( KD , Y , radius );

    n  = cellfun( 'prodofsize' , id ); [~,m] = max( n );
    if n(m) == 1, break; end

    
    id = id{m};
    IDS( X( id ,c+1) ) = X( m ,c+1);
    X( id ,:) = [];
  end
end
function w = loss( id )
  id( ~id ) = [];
  w = false( max(id(:)) , 1 );
  w(id) = true;
end
