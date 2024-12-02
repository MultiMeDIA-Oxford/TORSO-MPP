function [B,REST] = Remove_Head_Arms_Limbs( B , V , N )

  if nargin < 3
    N = [0 1 7 7];
  end
  N(end+1:4) = N(end);

  B = MeshGenerateIDs( MeshTidy( B ,0,true) ,'tri');
  
  X = meshSeparate( MeshTidy( MeshRemoveFaces( B , vtkClosestElement(Mesh(B,0),meshFacesCenter( V ) ) ) ) );
  
  LEGS = MeshTidy( X{ argmin(cellfun(@(m)min(m.xyz(m.tri(:),3)),X)) } ,0,1);
  HEAD = MeshTidy( X{ argmax(cellfun(@(m)max(m.xyz(m.tri(:),3)),X)) } ,0,1);
  RARM = MeshTidy( X{ argmin(cellfun(@(m)min(m.xyz(m.tri(:),1)),X)) } ,0,1);
  LARM = MeshTidy( X{ argmax(cellfun(@(m)max(m.xyz(m.tri(:),1)),X)) } ,0,1);

  
  B = MeshRemoveFaces( B , ismember( B.triID , RARM.triID ) );
  B = MeshRemoveFaces( B , ismember( B.triID , LARM.triID ) );
  B = MeshTidy( meshSeparate( B , 'largest' ) ,0,true,[1,1,1,0]);

  C=HEAD; for it=1:N(1), C=MeshRemoveFaces( C , meshBoundaryElements(C) ); end; C=MeshTidy( MeshBoundary(C) );
  [~,plane] = MeshRubberBandClip( B , mean( C.xyz ,1) );
  plane = getPlane( plane , '+z' );
  if nargout>1, REST.HEAD = MeshClip( B , plane , true ); end
  B = Clip( B , plane , false );
  
  C=LEGS; for it=1:N(2), C=MeshRemoveFaces( C , meshBoundaryElements(C) ); end; C=MeshTidy( MeshBoundary(C) );
  [~,plane] = MeshRubberBandClip( B , mean( C.xyz ,1) );
  plane = getPlane( plane , '-z' );
  if nargout>1, REST.LEGS = MeshClip( B , plane , true ); end
  B = Clip( B , plane , false );
  
  C=RARM; for it=1:N(3), C=MeshRemoveFaces( C , meshBoundaryElements(C) ); end; C=MeshTidy( MeshBoundary(C) );
  [~,plane] = MeshRubberBandClip( RARM , mean( C.xyz ,1) );
  plane = getPlane( plane , '-z' );
  if nargout>1, REST.RARM = MeshClip( RARM , plane , true ); end
  RARM = Clip( RARM , plane , false );
  B = MeshWeld( B , RARM );
  
  C=LARM; for it=1:N(4), C=MeshRemoveFaces( C , meshBoundaryElements(C) ); end; C=MeshTidy( MeshBoundary(C) );
  [~,plane] = MeshRubberBandClip( LARM , mean( C.xyz ,1) );
  plane = getPlane( plane , '-z' );
  if nargout>1, REST.LARM = MeshClip( LARM , plane , true ); end
  LARM = Clip( LARM , plane , false );
  B = MeshWeld( B , LARM );
  

  B = MeshTidy( B , 0 ,true,[1,1,1,0]);
  B = MeshFillHoles( B , Inf );
  B = MeshTidy( B , 0 ,true,[1,1,1,0]);
  

  B = MeshFixCellOrientation( B );
  
  B = Mesh( B , 0 );

end
function M = Clip( M , varargin )
  try
    M = MeshClipAndClose( M , varargin{:} );
  catch
    M = MeshClip( M , varargin{:} );
  end
end