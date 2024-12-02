function resample( IP , n )

  if nargin<2
    n = length(IP);
  end

  xyz= getCurve(IP);
  d= [0; cumsum( sqrt( sum(diff(xyz).^2,2)) )];
  d= d/d(end);
  
  
  IPdata= getappdata(IP.handle,'InteractivePolygon');
  if IPdata.close
    nd= linspace(0,1,n+1);
    nd(end)=[];
  else
    nd= linspace(0,1,n);
  end
  
  vertices = interp1( d , xyz , nd );
  
  setVertices(IP,vertices,'update');

end
