function V = Version()

  persistent matlabV
  if isempty( matlabV )
    matlabV = sscanf(version,'%d.%d.%d.%d.%d',5); matlabV=[100,1,1e-2,1e-9,1e-13]*[ matlabV(1:min(5,end)) ; zeros(5-numel(matlabV),1) ];
  end
  
  V = matlabV;

end
