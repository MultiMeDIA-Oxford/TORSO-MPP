function SA1 = firstSA( HS )

  SA1 = 4;
  try, SA1 = find( cellfun( @(I)isa(I,'I3D') && isstruct(I.INFO) && isfield(I.INFO,'PlaneName') && strncmp(I.INFO.PlaneName,'SAx',3) , HS(:,1) ) ,1); end
  SA1 = min( SA1 , size( HS ,1) );

end