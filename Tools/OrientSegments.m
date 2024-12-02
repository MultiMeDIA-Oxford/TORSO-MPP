function C = OrientSegments( C )

  if iscell( C )
    asCell = true;
  else
    asCell = false;
    C = { C };
  end

  
  for c = 1:numel(C)
    if size(C{c},2) ~= 2, error('only 2d segments can be oriented'); end
    
    N = size( C{c} , 1 );
    [~,i2] = max( C{c}(:,2) );
    if i2 == 1
      i1 = N; i3 = 2;
    elseif i2 == N
      i1 = N-1; i3 = 1;
    else
      i1 = i2-1; i3 = i2+1;
    end

    cr = cross( [ C{c}(i2,:)-C{c}(i1,:) , 0 ] , [ C{c}(i3,:)-C{c}(i2,:) , 0 ] );
    if cr(:,3) < 0
      C{c} = flip(C{c},1);
    end
  end
  
  if ~asCell
    C = C{1};
  end

end
