function [HT,T] = transformFrom( HS , HA , side )
if 0

  clc
  HS = loadv('h:\DTI001\mpp\HS.mat','HS');
  HC = contoursFrom( HS , loadv('h:\DTI001\mpp\HC.mat','HC') );
  HC = HC([1 2 5 end],:);
  
  
  HA = loadv('h:\DTI001\mpp\HA.mat','HA'); HA = HA( randperm(end) ,1);
  
  M = maketransform( 'rx',20,'rz',40,'ry',20,'t',[1000 200 30] );
  
  R0 = transformFrom( HC , HA , 'r' );
  R1 = transformFrom( HC , transform( HA , M ) , 'r' );
%   showSlices( R0 );
%   showSlices( R1 );
%   linkprop( gaa(0) ,{'xlim','ylim','zlim','CameraPosition','CameraUpVector','CameraTarget','CameraViewAngle','Projection'});
  [ R0{1}.SpatialTransform - R1{1}.SpatialTransform ]
  
  
  L0 = transformFrom( HC , HA , 'l' );
  L1 = transformFrom( HC , transform( HA , M ) , 'l' );
%   showSlices( L0 );
%   showSlices( L1 );
%   linkprop( gaa(0) ,{'xlim','ylim','zlim','CameraPosition','CameraUpVector','CameraTarget','CameraViewAngle','Projection'});
  [ L0{1}.SpatialTransform - L1{1}.SpatialTransform ]
  
%   [ R0{1}.SpatialTransform - L0{1}.SpatialTransform ]

  %%
end

  T = repmat( { eye(4) } , [ size(HS,1) , 1 ] );
%   if mppBranch('ct')
%     HT = HS;
%     return;
%   end
  
  
  KM_iterations = 3;
  try, mppOption KM_iterations 3; end

  if nargin < 3, side = 'L'; end

  if ischar( HA )
    HA = Loadv( HA );
  end
  HA = HA(:,1);
  HA( cellfun('isempty',HA) ) = [];
  
  for s = 1:size(HS,1)
    if isempty( HS{s,1} ), continue; end
    a = strcmp( cellfun(@(I)I.INFO.MediaStorageSOPInstanceUID , HA(:,1) ,'un',0) , HS{s,1}.INFO.MediaStorageSOPInstanceUID );
    a = find(a,1);
    if isempty( a ), continue; end
    
    A = HA{a,1}.coords2matrix;
    S = HS{s,1}.coords2matrix;
    
    T{s} = A.SpatialTransform / S.SpatialTransform;
  end
  
  
  switch lower(side)
    case {'r'}
%       ( sum( (cellfun(@Log_SEr,T)).^2 ) )
      for kmit = 1:KM_iterations
        fprintf('KM iteration %d from the right\n',kmit);
        KM = real( KarcherMean( cat(3,T{:}) , @Exp_SEr , @Log_SEr , 'R' ) ); KM(4,:) = [0,0,0,1];
        iKM = minv( KM ); iKM(4,:) = [0,0,0,1];
        for s = 1:numel(T), T{s} = T{s} * iKM; end
      end  
%       ( sum( (cellfun(@(T)Log_SEr((T)),T)).^2 ) )
      
    case {'l'}
%       ( sum( (cellfun(@Log_SE,T)).^2 ) )
      for kmit = 1:KM_iterations
        fprintf('KM iteration %d from the left\n',kmit);
        KM = real( KarcherMean( cat(3,T{:}) , @Exp_SE , @Log_SE , 'L' ) ); KM(4,:) = [0,0,0,1];
        iKM = minv( KM ); iKM(4,:) = [0,0,0,1];
        for s = 1:numel(T), T{s} = iKM * T{s}; end
      end  
%       ( sum( (cellfun(@(T)Log_SE((T)),T)).^2 ) )
      
    case {'n','none'}
      error( 'not implememted yet');
    otherwise
      error( 'unknown side. It should be ''R'', or ''L'', or ''none''.');
  end
  
  HT = transform( HS , T );

end
