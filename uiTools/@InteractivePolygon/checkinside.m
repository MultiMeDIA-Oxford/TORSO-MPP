function p = checkinside( IP , p )

  xyz= getCurve(IP);
  
  if     all( xyz(:,3) == xyz(1,3) )
    xyz = xyz(:,[1 2]);
  elseif all( xyz(:,1) == xyz(1,1) )
    xyz = xyz(:,[2 3]);
  elseif all( xyz(:,2) == xyz(1,2) )
    xyz = xyz(:,[1 3]);
  end

  p = inpoly( p' , xyz(:,:)' )';

end