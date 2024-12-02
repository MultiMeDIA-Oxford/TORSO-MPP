function A = catstruct( dim , A , varargin )

  if isempty( A )
    A = varargin{1};
    varargin(1) = [];
  end

  
  NDV = ndv();
  for i = 1:numel(varargin)
    B = varargin{i}; if isempty( B ), continue; end
    
    for fn = fieldnames( B ).'
      if ~isfield( A , fn{1} )
        for j = 1:numel(A)
          A(j).(fn{1}) = NDV;
        end
      end
    end
    for fn = fieldnames( A ).'
      if ~isfield( B , fn{1} )
        for j = 1:numel(B)
          B(j).(fn{1}) = NDV;
        end
      end
    end
    
    A = cat( dim , A , B );
  end

end
