% function MANNEQUIN = PrepareMannequin( )
%PrepareMannequin

try
  mppOption TORSO_MODEL_DIR
  HEART0 = read_VTK( fullfile( TORSO_MODEL_DIR , 'HEART.vtk' ) );
  centerH0 = mean( HEART0.xyz , 1 );

  if ~exist( 'MANNEQUIN' ,'var' ) || isempty( MANNEQUIN )
    Mb_ = loadv( fullfile( TORSO_MODEL_DIR , 'BODY_MODEL' ) , 'Mb_' );
    MANNEQUIN = Mb_(0);
    MANNEQUIN = vtkQuadricDecimation( MANNEQUIN , 'SetTargetReduction',0.9 );
  end


  centerH = [];
  if isempty( centerH ), try
      [~,centerH] = MaskHeart( HS );
  end; end
  if isempty( centerH ), try
      centerH = mean( HM.xyz , 1 );
  end; end
  if isempty( centerH ), try
      centerH = Loadv( 'HM' , 'HM' );
      centerH = mean( centerH.xyz , 1 );
  end; end
  if isempty( centerH ), try
      centerH = read_VTK( Fullfile( 'mpp' , 'HM.vtk' ) );
      centerH = mean( centerH.xyz , 1 );
  end; end
  if isempty( centerH ), try
      centerH = read_VTK( Fullfile( 'mpp' , 'HeartSurfaces.vtk' ) );
      centerH = mean( centerH.xyz , 1 );
  end; end
  if isempty( centerH ), try
      centerH = Loadv( 'HEARTmesh' , 'HEART' );
      centerH = mean( centerH.xyz , 1 );
  end; end
  if isempty( centerH ), try
      centerH = read_VTK( Fullfile( 'HEART.vtk' ) );
      centerH = mean( centerH.xyz , 1 );
  end; end
  if isempty( centerH ), try
      [~,centerH] = MeshVolume( struct('xyz', ecgI.nodes ,'tri', ecgI.mesh ) );
  end; end
  if isempty( centerH ), try
      HS_ = [];
      if isempty( HS_ ), try, HS_ = Loadv('HS'  ,''); end; end
      if isempty( HS_ ), try, HS_ = Loadv('HCm' ,''); HS_ = HS_(:,1); end; end
      if isempty( HS_ ), try, HS_ = Loadv('HC'  ,''); HS_ = HS_(:,1); end; end

      [~,centerH] = MaskHeart( HS_ );
  end; end
  if isempty( centerH ), try
      HS_ = HC;

      [~,centerH] = MaskHeart( HS_ );
  end; end    
  if isempty( centerH ), error('toCatch'); end

  MANNEQUIN = transform( MANNEQUIN , 't' , -centerH0 , 's' ,0.9 , 't' , centerH  );
catch
  fprintf('some error preparing mannequin. no mannequin is possible\n');
  MANNEQUIN = [];
end

