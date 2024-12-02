function [H,ZZ] = canonicalize_SSM_Heart( H )

  ZZ = eye(4);
  [EPI,LV,RV,~,cLV] = split_SSM_Heart( H );
%   plotMESH( {EPI,LV,RV} ,'ne' ); headlight

  bEPI = MeshTidy( MeshBoundary( EPI ) );

  [~,Z] = getPlane( bEPI ,'+z');
  T = transform( EPI , Z );
  if issorted( abs( range( T.xyz(:,3) ) ) )
    Z = diag([-1 1 -1 1]) * Z;
  end
  
  EPI = transform( EPI ,Z); bEPI = MeshTidy( MeshBoundary( EPI ) );
  LV  = transform( LV  ,Z);
  RV  = transform( RV  ,Z);
  cLV = transform( cLV ,Z);
  H   = transform( H   ,Z); ZZ = transform( ZZ , Z );
%   plotMESH( {EPI,LV,RV} ,'ne' ); axis(objbounds); headlight

  Z = min(bEPI.xyz(:,3));
  Z = maketransform('tz',-Z,'tz',2);
%   EPI = transform( EPI ,Z); %bEPI = MeshTidy( MeshBoundary( EPI ) );
  LV  = transform( LV  ,Z);
  RV  = transform( RV  ,Z);
  cLV = transform( cLV ,Z);
  H   = transform( H   ,Z); ZZ = transform( ZZ , Z );
%   plotMESH( {EPI,LV,RV} ,'ne' ); axis(objbounds); headlight

  [~,Z] = meshVolume( cLV ); Z(3) = 0;
  Z = maketransform( 't' , -Z );
%   EPI = transform( EPI ,Z); %bEPI = MeshTidy( MeshBoundary( EPI ) );
%   LV  = transform( LV  ,Z);
%   cLV = transform( cLV ,Z);
  RV  = transform( RV  ,Z);
  H   = transform( H   ,Z); ZZ = transform( ZZ , Z );
%   plotMESH( {EPI,LV,RV} ,'ne' ); axis(objbounds); headlight


  [~,Z] = meshVolume( RV );
  Z = maketransform( 'rz' , -atan2d(Z(2),Z(1)) , 'rz' , 180 );
%   EPI = transform( EPI ,Z); %bEPI = MeshTidy( MeshBoundary( EPI ) );
%   LV  = transform( LV  ,Z);
%   cLV = transform( cLV ,Z);
%   RV  = transform( RV  ,Z);
  H   = transform( H   ,Z); ZZ = transform( ZZ , Z );
%   plotMESH( {EPI,LV,RV} ,'ne' ); axis(objbounds); headlight

end
