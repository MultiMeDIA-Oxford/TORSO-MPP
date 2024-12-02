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
    if isfield( H ,'triATTS')
      H = MeshRemoveFaces( H , H.triATTS ~= 0 );
    end
    H = MeshTidy( MeshBoundary( H ) );
  end
  
  
  ApexBase = [];
  if isfield( H , 'TITLE' )  && strncmp( H.TITLE , 'ApexBase=' , 9 )

    eval( H.TITLE );
    
    Etri = find( all( ismember( H.tri ,                      ( 1:EPInodes ) ) ,2) );
    Ltri = find( all( ismember( H.tri , EPInodes +           ( 1:LVnodes  ) ) ,2) );
    Rtri = find( all( ismember( H.tri , EPInodes + LVnodes + ( 1:RVnodes  ) ) ,2) );
    Dtri = setdiff( 1:size(H.tri,1) , [ Etri(:) ; Ltri(:) ; Rtri(:) ] );

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
    
  elseif isfield( H , 'epiFACES' ) && isfield( H , 'lvFACES' ) && isfield( H , 'rvFACES' )

    H = MeshGenerateIDs( H );

    EPI = MeshRemoveNodes( H , { ismember( H.xyzID , H.epiFACES ) } );
    LV  = MeshRemoveNodes( H , { ismember( H.xyzID , H.lvFACES  ) } );
    RV  = MeshRemoveNodes( H , { ismember( H.xyzID , H.rvFACES  ) } );
  
    LID = MeshRemoveFaces( H , ismember( H.triID , [ EPI.triID ; LV.triID ; RV.triID ] ) );

    [Z,iZ] = getPlane( LID.xyz , '+z' );
    EPIv = MeshTidy( transform( EPI , iZ ) ,-1);
    [~,ApexBase] = min( EPI.xyz(:,3) );
    ApexBase = EPIv.xyz( ApexBase ,:);
    ApexBase = [ ApexBase ; ApexBase .* [1 1 0 ] ];
    
    ApexBase = transform( ApexBase , Z );

  elseif 0

    H = MeshTidy( H );
    H = MeshGenerateIDs( H , 'tri' );
    
    H = MeshSplit( H , -20 );
    
    HH = meshSeparate( H );
    for h = 1:numel( HH )
      if size( HH{h}.tri ,1) < 10
        HH{h} = [];
        continue;
      end
      n = meshNormals( HH{h} );
      if max( var( n ,1,1) ) > 0.1
        HH{h} = [];
        continue;
      end        
    end
    HH( cellfun('isempty',HH) ) = [];

  elseif 0
    
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

    LID.xyzNC = meshNodesConnectivity( Mesh( LID ,0) );
    LID = MeshRemoveNodes( LID , ismember( LID.xyzNC , unique( LID.xyzNC( LID.xyz(:,3) < -0.1 ) ) ) );

    RV = MeshRemoveFaces( S , ismember( S.triID , LID.triID ) );

    LID = MeshRemoveFaces( S , ismember( S.triID , [ EPI.triID ; LV.triID ; RV.triID ] ) );

    LID = MeshTidy( LID );
    [Z,iZ] = getPlane( LID.xyz , '+z' );
    EPIv = MeshTidy( transform( EPI , iZ ) ,-1);
    [~,ApexBase] = min( EPIv.xyz(:,3) );
    ApexBase = EPIv.xyz( ApexBase ,:);
    ApexBase = [ ApexBase ; ApexBase .* [1 1 0 ] ];
    
    ApexBase = transform( ApexBase , Z );

    
  else
    
    S = MeshTidy( MeshGenerateIDs( Mesh(H,0) ) ,-1);
    
    iZ = getPlane( S.xyz(end-10:end,:) , '+z' );
    Sv = transform( S , minv( iZ ) );
    
    EPI = 1:find( diff( Sv.xyz(:,3) ) < -2 ,1);
    EPI = Sv.xyzID( EPI );
    EPI = MeshRemoveNodes( S , { ismember( S.xyzID , EPI ) } );       Etri = EPI.triID;
    S   = MeshRemoveFaces( S , ismember( S.triID , EPI.triID ) );
    
    iZ = MeshTidy( MeshBoundary( EPI ) ,-1);
    iZ = getPlane( iZ , '+z' );

    Sv = transform( S , minv( iZ ) );
    Sv = MeshRemoveNodes( Sv , ismember( Sv.xyzID , EPI.xyzID  ) );
    
    LV  = 1:find( diff( Sv.xyz(:,3) ) < -2 ,1);
    LV  = Sv.xyzID( LV );
    LV  = MeshRemoveNodes( S , { ismember( S.xyzID , LV ) } );        Ltri = LV.triID;
    S   = MeshRemoveFaces( S , ismember( S.triID , LV.triID ) );
    
    
    Sv = transform( S , minv( iZ ) );
    Sv = MeshCrinkle( Sv , getPlane([0,0,-0.1;0,0,1]) ,1);
    Sv = MeshTidy( Sv , -1);
    Sv = MeshSplit( Sv , -1 );
    
    LID = meshSeparate( Sv ,'maxx');
    LID = MeshTidy( LID , -1);

    RV   = MeshTidy( MeshRemoveFaces( S , ismember( S.triID , LID.triID ) ) ,-1);       Rtri =  RV.triID;
    LID  = MeshTidy( MeshRemoveFaces( S , ismember( S.triID , RV.triID  ) ) ,-1);       Dtri =  LID.triID;
    

    
    [Z,iZ] = getPlane( LID.xyz , '+z' );
    EPIv = MeshTidy( transform( EPI , iZ ) ,-1);
    [~,ApexBase] = min( EPIv.xyz(:,3) );
    ApexBase = EPIv.xyz( ApexBase ,:);
    ApexBase = [ ApexBase ; ApexBase .* [1 1 0 ] ];
    
    ApexBase = transform( ApexBase , Z );
    
    
  end

  H = Mesh( H );
  
  EPI = MeshTidy( MeshRemoveFaces( H , { Etri } ) ); EPI = MeshFixCellOrientation( EPI );
  LV  = MeshTidy( MeshRemoveFaces( H , { Ltri } ) ); LV  = MeshFixCellOrientation( LV  );
  RV  = MeshTidy( MeshRemoveFaces( H , { Rtri } ) ); RV  = MeshFixCellOrientation( RV  );
  LID = MeshTidy( MeshRemoveFaces( H , { Dtri } ) );
  w = meshNormals( LID )*[0;0;1] < 0;
  LID.tri(w,:) = LID.tri(w,[1,3,2]);
  
  if isempty( ApexBase )
    
    
  end
  
  
  MAT = { eye(4) };
  if 1

    m = mean( LV.xyz , 1);
    MAT{end+1} = [ eye( 3 ) , -m(:) ; 0 0 0 1 ];

    ApexBaseDirection = ApexBase(2,:)-ApexBase(1,:);
    ApexBaseDirection = ApexBaseDirection(:);
    ApexBaseDirection = ApexBaseDirection/sqrt( ApexBaseDirection(:).'*ApexBaseDirection(:) );
    MAT{end+1} = [ null( ApexBaseDirection' ) , ApexBaseDirection ];
    if det( MAT{end} ) < 0, MAT{end}(:,2) = -MAT{end}(:,2); end
    MAT{end} = [ MAT{end}.' , zeros(3,1) ; 0 0 0 1 ];

    m = transform( LID , MAT{:} );
    m = mean( m.xyz(:,3) );
    MAT{end+1} = [ eye(3) , [0;0;-m] ; 0 0 0 1 ];

    m = transform( RV , MAT{:} );
    m = mean( m.xyz , 1 );
    MAT{end+1} = maketransform( 'rz' , -atan2d( m(2) , m(1) ) , 'rz' , 180 );

  else
    
    ApexBaseDirection = ApexBase(2,:)-ApexBase(1,:);
    ApexBaseDirection = ApexBaseDirection(:);
    ApexBaseDirection = ApexBaseDirection/sqrt( ApexBaseDirection(:).'*ApexBaseDirection(:) );
    MAT{end+1} = [ null( ApexBaseDirection' ) , ApexBaseDirection ];
    if det( MAT{end} ) < 0, MAT{end}(:,2) = -MAT{end}(:,2); end
    MAT{end} = [ MAT{end}.' , zeros(3,1) ; 0 0 0 1 ];
    
    
    m = transform( LID , MAT{:} );
    n = meshNormals( m );
    w = abs( n(:,3) - 1 ) > 1e-3;
    m = MeshTidy( MeshRemoveFaces( m , w ) );
    LID  = MeshTidy( MeshRemoveFaces( LID  , w ) );
    
    MAT{end+1} = [ eye(3) , -median( m.xyz ,1).' ; 0 0 0 1 ];
    
    m = transform( LV , MAT{:} );
    m = MeshTidy( MeshBoundary( m ) );
    m = MeshRemoveNodes( m , abs( m.xyz(:,3) ) > 1e-3 );
    m = mesh2contours( m );
    m = m(:,1:2);
    [~,m] = area( polygon( m ) );
    m(3) = 0;
    
    MAT{end+1} = [ eye(3) , -m.' ; 0 0 0 1 ];
    
    
    m = transform( RV , MAT{:} );
    m = MeshTidy( MeshBoundary( m ) );
    m = MeshRemoveNodes( m , abs( m.xyz(:,3) ) > 1e-3 );
    m = mesh2contours( m );
    m = m(:,1:2);
    [~,m] = area( polygon( m ) );
    m(3) = 0;
    
    MAT{end+1} = maketransform( 'rz' , -atan2d( m(2) , m(1) ) , 'rz' , 180 );
    
  end
  MAT = maketransform( MAT{:} );
  
  
  if nargout > 5
    INFO = struct();
    
    INFO.MyocardiumVolume = meshVolume( H );
    INFO.LBloodPoolVolume = meshVolume( MeshFixCellOrientation( MeshFillHoles( LV ) ) );
    INFO.RBloodPoolVolume = meshVolume( MeshFixCellOrientation( MeshFillHoles( RV ) ) );
    
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
