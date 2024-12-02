function [Z,iZ] = poseFromMRI( HLA , VLA , SAb )

 
  if ~isnumeric( SAb ) &&  numel( SAb ) > 1
    Zs = NaN( numel(SAb) ,1);
    for s = 1:numel(SAb)
      SA = SAb(s);
      if iscell( SA ), SA = SA{1}; end
      if isa( SA , 'I3D' ), SA = SA.INFO; end
      
      Zs(s) = DICOMxinfo( SA , 'xZLevel' );
    end
    [~,id] = max( Zs );
    SAb = SAb(id);
    if iscell( SAb ), SAb = SAb{1}; end
  end

  try, HLA = getPlane( HLA ); end
  try, VLA = getPlane( VLA ); end
  try, SAb = getPlane( SAb ,'+z'); end
  iZ = minv( SAb );
  

  C  = intersectionPlanePlane( HLA , VLA , SAb );
  C  = C(1:3,4)';
  iZ = transform( iZ , 't' , -transform( C , iZ ) );

  LR = intersectionPlanePlane( HLA , SAb );
  LR = LR(1:3,3)';
  if LR(2) > 0, LR = -LR; end
  LR = C + 50 * LR;
  LR = transform( LR , iZ );
  iZ = transform( iZ , 'rz', -atan2d(LR(2),LR(1)) , 'rz',180 );
  
%   showSlices( transform( HS([1 2 4]) , iZ ) ); hline(0,'r2');vline(0,'g2');
  
%%  
  Z = minv( iZ );
  
  %%
end
