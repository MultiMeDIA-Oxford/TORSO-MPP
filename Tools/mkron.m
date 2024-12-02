function M = mkron( M , varargin )

  for i = 1:numel(varargin)
    M = kron( M , varargin{i} );
  end

end
