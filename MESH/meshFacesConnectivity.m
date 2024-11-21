function C = meshFacesConnectivity( F )
% - USE_VTK is only valid for Triangle Meshes (celltype == 5)

  USE_VTK = false;

  X = [];
  if isstruct( F )
    USE_VTK = meshCelltype(F) == 5;
    for f = fieldnames( F ).', f = f{1};
      if  strcmp(  f , 'tri' ),      continue; end
      if  strcmp(  f , 'triID' ),    continue; end
      if ~strncmp( f , 'tri' , 3 ),  continue; end
      thisX = F.(f); thisX = thisX(:,:);
      thisX(:, all( bsxfun( @eq , thisX , thisX(1,:) ) ,1) ) = [];
      X = [ X , thisX ];
      USE_VTK = false;
    end
    F = F.tri;
  end
  
  if USE_VTK
    M = struct('tri',double(F));
    nV = max( M.tri(:) );
    M.xyz = reshape( 1:3*nV , [ nV , 3 ] );
    
    M = vtkPolyDataConnectivityFilter( M ,...
              'SetExtractionModeToAllRegions' , []   ,...
              'SetColorRegions'               , true ,...
              'ScalarConnectivityOff'         , []   );
    C = M.xyzRegionId( M.tri );
    
    if all( all( bsxfun( @eq , C , C(:,1) ) ,2) )
      C = C(:,1) +1;
      return;
    end
  end
  
  
  nF = size( F ,1);

  IDS = ( 1:nF ).';
  ToRem = zeros(nF,1); nR = 0;
  
  C = zeros( nF , 1 ); c = 1;
  while 1
    IDS( ToRem(1:nR) ) = [];
    F( ToRem(1:nR) ,:) = [];%size(T)
    
    G = find( ~C , 1 ); if isempty( G ), break; end
    C( G ) = c;
    G = find( IDS == G ,1);
    if ~isempty(X)
      X( ToRem(1:nR) ,:) = [];
      v = all( bsxfun( @eq , X , X( G ,:) ) ,2);
    end
    nR = 0;
    while ~isempty( G )
      m = F( G(:) ,:);
      w = any( myISMEMBER( F , m ) ,2);
      if ~isempty(X)
        w = w & v;
      end
      G = find( w );
      
      G( ~~C( IDS(G) ) ) = [];
      C( IDS(G) ) = c;
      
      ToRem( (nR+1):(nR+numel(G)) ) = G;
      nR = nR + numel(G);
    end
    c = c+1;
  end

end
function lia = myISMEMBER( a , b )
  done = false;
  if numel(b) == 1
    lia = a == b;
    done = true;
  end
  
  if ~done, b = sort(b(:)); end
  if ~done, try, lia = builtin('_ismemberoneoutput',a,b); done = true; end; end
  if ~done, try, lia = builtin('_ismemberhelper',a,b);    done = true; end; end
  if ~done, lia = ismember( a , b ); end
end
