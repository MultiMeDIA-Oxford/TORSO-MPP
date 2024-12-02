function [EPI,LV,RV,MIO,cLV] = split_SSM_Heart( H )

  if iscell( H )
    EPI = MeshTidy( H{1} ,-1);
  else
    EPI = MeshTidy( Mesh(MeshRemoveNodes( H , { H.xyzLABEL == 0 } ),0) );
  end
  EPI = Mesh( EPI ,0);

  if nargout > 1
  if iscell( H )
    LV = MeshTidy( H{2} ,-1);
  else
    LV  = MeshTidy( Mesh(MeshRemoveNodes( H , { H.xyzLABEL == 1 } ),0) );
  end
  LV  = Mesh( LV ,0);
  end
  
  
  if nargout > 2
  if iscell( H )
    RV = MeshTidy( H{3} ,-1);
  else
    RV  = MeshTidy( Mesh(MeshRemoveNodes( H , { H.xyzLABEL == 2 } ),0) );
  end
  RV  = MeshRemoveNodes( RV , [ 3182 , 1811 , 1243 , 1115 , 757 ] );
  RV.tri = [ RV.tri ; 
             3177 , 3359 , 3357 ;
             3177 , 2996 , 2997 ;
             1807 , 1959 , 1957 ;
             1807 , 1657 , 1660 ;
             1369 , 1240 , 1371 ;
             1113 ,  986 ,  988 ;
              756 ,  871 ,  868 ;
              756 ,  651 ,  653 ];
  RV  = MeshTidy( RV ,0,true);
  RV  = MeshFixCellOrientation( RV );
  RV  = Mesh( RV ,0);
  end
  
  if nargout > 3
  MIO = MeshWeld( EPI , LV );
  MIO = Mesh( MIO ,0);
  end
  
  if nargout > 4

  bLV = MeshTidy( MeshBoundary( LV ) );
  [~,iZ] = getPlane( bLV ,'+z');
  
  cLV = transform( LV ,iZ);
  if issorted( abs( range( cLV.xyz(:,3) ) ) )
    iZ = diag([1 -1 -1 1]) * iZ;
  end
  cLV = transform( LV ,iZ);
  
  bLV = MeshTidy( MeshBoundary( cLV ) );
  
  cLV = MeshClipAndClose( cLV , getPlane( [0 , 0 , min( bLV.xyz(:,3) ) - 0.1 ; 0 , 0 , 1] ) );
  Z = minv( iZ );
  cLV = transform( cLV , Z );
  cLV = Mesh( cLV ,0);
  end
  
end