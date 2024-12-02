function [P,prev] = nearestpoint(IP,P)

  xyz = getCurve( IP );
  nsegs = size(xyz,1)-1;
  distances = zeros(nsegs,1);
  for i = 1:nsegs
    P1 = xyz(i  ,:);
    P2 = xyz(i+1,:);
    S  = P2-P1;
    t  = ((P-P1)*S')/norm(S)^2;
    if t<0, t=0; end
    if t>1, t=1; end
    distances(i)= norm( P-P1-t*S );
  end
  [distances,i]= min(distances);
  P1 = xyz(i  ,:);
  P2 = xyz(i+1,:);
  S  = P2-P1;
  t  = ((P-P1)*S')/norm(S)^2;
  if t<0, t=0; end
  if t>1, t=1; end
  P = P1 + t*S;
  
  if nargout>1
    IPdata= getappdata( IP.handle , 'InteractivePolygon');
    if IPdata.spline
      vertices= getVertices(IP);
      prev = 0;
      for j=1:i+1
        if norm(vertices(prev+1,:)-xyz(j,:)) < 1e-10
          prev = prev+1;
          if prev >= size(vertices,1), break; end
        end
      end
    else
      prev= i;
    end
  end
  
end
