function [EPI,LV,RV,LID,MAT,INFO] = HEARTparts( H )
% 
% MAT transform the heart to a "canonical" pose
% by "canonical pose" we refer to a heart with:
%   - the long axes parallel to the Z-axis
%   - the apex at bottom and the base at top
%   - the centroid of the LV blood pool at the most basal SAx is at 0,0,0
%   - them, the most basal plane is coincident with the XY plane
%   - the centroid of the RV blood pool at the most basal SAx lies the negative Xaxis
%   
% iMAT = minv( MAT );
% or
% iMAT = inv( MAT );
% 

  H.celltype = meshCelltype( H );
  if H.celltype == 10
    if isfield( H , 'triATTS' )
      H = MeshRemoveFaces( H , H.triATTS ~= 0 );
    end
%     H.triTID = ( 1:size( H.tri ,1) ).';
    
    H = MeshTidy( MeshBoundary( H ) ,-1);
  end
  
  if isfield( H , 'TITLE' )

    eval( H.TITLE );

    P = zeros( size( H.xyz , 1 ),1 );
    P( 1:EPInodes                                           ) = 1;
    P(   EPInodes + (1:LVnodes)                             ) = 2;
    P(   EPInodes +    LVnodes + (1:RVnodes)                ) = 3;
    P(   EPInodes +    LVnodes +    RVnodes + (1:ZEROnodes) ) = 4;

    EPI = MakeMesh( H , H.tri( all( P(H.tri) == 1 , 2 ) ,:) );
    LV  = MakeMesh( H , H.tri( all( P(H.tri) == 2 , 2 ) ,:) );
    RV  = MakeMesh( H , H.tri( all( P(H.tri) == 3 , 2 ) ,:) );
    LID = MakeMesh( H , H.tri( any( P(H.tri) == 4 , 2 ) ,:) );
    
  elseif isfield( H , 'epi' ) && isfield( H , 'lv' ) && isfield( H , 'rv' )
    
    H = MeshGenerateIDs( H );
    
    EPI = MeshRemoveNodes( H , { ismember( H.xyzID , H.epi ) } );
    LV  = MeshRemoveNodes( H , { ismember( H.xyzID , H.lv  ) } );
    RV  = MeshRemoveNodes( H , { ismember( H.xyzID , H.rv  ) } );
    
    LID = MeshRemoveFaces( H , ismember( H.triID , [ EPI.triID ; LV.triID ; RV.triID ] ) );
    
    [Z,iZ] = getPlane( LID.xyz , '+z' );
    EPIv = MeshTidy( transform( EPI , iZ ) ,-1);
    [~,ApexBase] = min( EPI.xyz(:,3) );
    ApexBase = EPIv.xyz( ApexBase ,:);
    ApexBase = [ ApexBase ; ApexBase .* [1 1 0 ] ];
    
    ApexBase = transform( ApexBase , Z );
    
  else
    
    H = MeshTidy( H , -1 );
    H = MeshGenerateIDs( H );

    S = H;
    Sv = transform( S , minv( getPlane( S.xyz(end-10:end,:) , '+z' ) ) );

    EPI = Sv.xyzID( 1:find( diff( Sv.xyz(:,3) ) < -2 ) );
    EPI = MeshRemoveNodes( S , { ismember( S.xyzID , EPI ) } );
    S = MeshRemoveFaces( S , ismember( S.triID , EPI.triID ) );

    Sv = transform( S , minv( getPlane( EPI.xyz( unique( MeshBoundary( EPI.tri ) ) ,:) , '+z' ) ) );
    Sv = MeshRemoveNodes( Sv , ismember( Sv.xyzID , EPI.xyzID ) );

    LV = Sv.xyzID( 1:find( diff( Sv.xyz(:,3) ) < -2 ) );
    LV = MeshRemoveNodes( S , { ismember( S.xyzID , LV ) } );
    S = MeshRemoveFaces( S , ismember( S.triID , LV.triID ) );

    Sv = transform( S , minv( getPlane( [ EPI.xyz( unique( MeshBoundary( EPI.tri ) ) ,:) ;...
                                           LV.xyz( unique( MeshBoundary(  LV.tri ) ) ,:) ]...
                                          , '+z' ) ) );

    LID = Sv;
    z = LID.xyz(:,3);
    LID = MeshRemoveFaces( LID , all( z( LID.tri ) < -1 ,2) );
    LID = vtkPolyDataNormals( LID , 'SetFeatureAngle' , 1 , 'SetSplitting',true , 'ComputePointNormalsOff',[],'ComputeCellNormalsOn',[] );

    LID.xyzNC = meshNodesConnectivity( MakeMesh( LID ) );
    LID = MeshRemoveNodes( LID , ismember( LID.xyzNC , unique( LID.xyzNC( LID.xyz(:,3) < -0.1 ) ) ) );

    RV = MeshRemoveFaces( S , ismember( S.triID , LID.triID ) );

    LID = MeshRemoveFaces( S , ismember( S.triID , [ EPI.triID ; LV.triID ; RV.triID ] ) );

    [Z,iZ] = getPlane( LID.xyz , '+z' );
    EPIv = MeshTidy( transform( EPI , iZ ) ,-1);
    [~,ApexBase] = min( EPI.xyz(:,3) );
    ApexBase = EPIv.xyz( ApexBase ,:);
    ApexBase = [ ApexBase ; ApexBase .* [1 1 0 ] ];
    
    ApexBase = transform( ApexBase , Z );
    
  end
  
  EPI = MeshTidy( EPI , -1 ); EPI = MeshFixFacesOrientation( EPI );
  LV  = MeshTidy( LV  , -1 ); LV  = MeshFixFacesOrientation( LV  ); LV.tri = LV.tri(:,[2 1 3]);
  RV  = MeshTidy( RV  , -1 ); RV  = MeshFixFacesOrientation( RV  ); RV.tri = RV.tri(:,[2 1 3]);
  LID = MeshTidy( LID , -1 ); w = meshNormals( LID )*[0;0;1] < 0; LID.tri(w,:) = LID.tri(w,[2 1 3]);    

  
  
  
  MAT = { eye(4) };

  m = mean( LV.xyz , 1);
  MAT{end+1} = [ eye( 3 ) , -m(:) ; 0 0 0 1 ];

  ApexBaseDirection = ApexBase(2,:)-ApexBase(1,:);
  ApexBaseDirection = ApexBaseDirection(:);
  ApexBaseDirection = ApexBaseDirection/sqrt( ApexBaseDirection(:).'*ApexBaseDirection(:) );
  MAT{end+1} = [ null( ApexBaseDirection' ) , ApexBaseDirection ];
  if det( MAT{end} ) < 0, MAT{end}(:,2) = -MAT{end}(:,2); end
  MAT{end} = [ MAT{end}.' , zeros(3,1) ; 0 0 0 1 ];

  LIDr = transform( LID , MAT{:} );
  m = mean( LIDr.xyz(:,3) );
  MAT{end+1} = [ eye(3) , [0;0;-m] ; 0 0 0 1 ];
  
  RVr = transform( RV , MAT{:} );
  m = mean( RVr.xyz , 1 );
  MAT{end+1} = maketransform( 'rz' , -atan2d( m(2) , m(1) ) , 'rz' , 180 );
  
  MAT = maketransform( MAT{:} );

  
  if nargout > 5
    INFO = struct();
    
    INFO.MyocardiumVolume = meshVolume( MakeMesh(H) );
    INFO.LBloodPoolVolume = meshVolume( FillHoles( LV ) );
    INFO.RBloodPoolVolume = meshVolume( FillHoles( RV ) );
    
    ApexBase  = transform( [0 0 1] , minv(  MAT(1:3,1:3) ) );
    
    [ApexBase(1,1),ApexBase(1,2),ApexBase(1,3)] = cart2sph( ApexBase(1,1),ApexBase(1,2),ApexBase(1,3) );
    ApexBase(1:2) = ApexBase(1:2)/pi*180;
    INFO.LA_az_el = ApexBase(1:2);
    
    LeftRight  = transform( [-1 0 0] , minv(  MAT(1:3,1:3) ) );
    
    [LeftRight(1,1),LeftRight(1,2),LeftRight(1,3)] = cart2sph( LeftRight(1,1),LeftRight(1,2),LeftRight(1,3) );
    LeftRight(1:2) = LeftRight(1:2)/pi*180;
    INFO.LR_az_el = LeftRight(1:2);
  end
  
  
  
end
