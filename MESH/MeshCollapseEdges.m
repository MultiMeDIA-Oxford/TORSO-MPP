function M = MeshCollapseEdges( M , TARGET_EDGE_LENGTH , FEATURE_NODE , FIXED_NODES )
%%

  if nargin < 3, FEATURE_NODE = []; end
  if nargin < 4, FIXED_NODES  = []; end
    
    
  [ED,EL] = meshEdges( M );
  EL( EL == 0 ) = Inf;
  w = any( ismember( ED , FIXED_NODES  ) , 2 );       ED(w,:) = []; EL(w,:) = [];
  w = sum( ismember( ED , FEATURE_NODE ) , 2 ) == 1;  ED(w,:) = []; EL(w,:) = [];
  
  while 1
    [~,ord] = sort( EL ); EL = EL(ord,:); ED = ED(ord,:);
    
    w = find( EL < TARGET_EDGE_LENGTH );
    if isempty( w ), break; end
%     disp(numel(w));
    
    [~,b] = unique( ED(w,:).' ,'stable');
    f = false( 2 , numel(w) );
    f( b ) = true;
    w = w( all( f ,1) );
    
    for f=fieldnames(M).',f=f{1};
      if ~strncmp( f , 'xyz' ,3), continue; end
      m = ( M.(f)( ED(w,1) ,:) + M.(f)( ED(w,2) ,:) )/2;
      M.(f)( ED(w,1) ,:) = m;
      M.(f)( ED(w,2) ,:) = m;
    end
    map = 1:size( M.xyz ,1);
    map( ED(w,2) ) = ED(w,1);
    M.tri = reshape( map( M.tri ) , size(M.tri) );
    ED = reshape( map( ED ) , size(ED) );
    
    w = any( ismember( ED , ED(w,:) ) ,2);
    EL( w ) = sqrt( sum( ( M.xyz( ED(w,1) ,:) - M.xyz( ED(w,2) ,:) ).^2 ,2) );
    EL( EL == 0 ) = Inf;
  end

  M = MeshTidy( M ,NaN,true);
  
end
