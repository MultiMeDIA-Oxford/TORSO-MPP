function M = MeshClipAndClose( M , varargin )

  delta = Inf;
  [varargin,~,delta] = parseargs( varargin ,'delta','$DEFS$',delta);

  M = MeshClip( M , varargin{:} ,'KeepParentEdge');
  
  [M,IDSname] = MeshGenerateIDs( M , 'xyz_' );
  
  B = MeshTidy( MeshBoundary( M ) ,-1,false );
  
  B = MeshRemoveNodes( B , ~B.xyzParentEdge(:,2) );
  
  C = nans2split( mesh2contours( B ) );
  C{end+1} = [];
  
  L = fillContoursMesh( C , delta );
  
  M = MeshWeld( M , L );
  
  M = rmfield( M , IDSname );


end
