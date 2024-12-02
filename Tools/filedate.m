function d = filedate( f , t0 )

  if ~iscell( f ), f = {f}; end
  
  d = NaN( size(f) );
  if nargin > 1
    t0 = datevec( t0 );
  end

  
  for i = 1:numel(f)
    try
      F = dir( f{i} );
      F = F.datenum;

      if nargin > 1
        F = etime( datevec( F ) , t0 );
      end
      d(i) = F;
    end
  end
  
end
