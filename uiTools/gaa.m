function axs = gaa( parent , varargin )


% gaa=@(p)findall(p,'type','axes');

  if nargin < 1 || isempty(parent), parent = 0; end
  
  axs = findall( parent , 'type','axes',varargin{:} );


end
