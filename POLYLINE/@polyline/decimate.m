function P = decimate( P )

  if ~isSingle( P ), error('only single polylines'); end

  tod = false( size( P.C{1} ,1) , 1 );
  for i = 2:numel( tod )-1
    [~,~,d] = distancePoint2Segments( P.C{1}(i,:) , P.C{1}(i+[-1 1],:) );
    if d < 1e-10
      tod(i) = true;
    end
  end
  
  P.C{1} = P.C{1}( ~tod ,:);

end
