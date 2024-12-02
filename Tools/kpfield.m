function S = kpfield( S , varargin )

  if numel(varargin) == 1 && iscell( varargin{1} )
    varargin = varargin{1};
  end
  
  S = rmfield( S , setdiff( fieldnames(S) , varargin ) );


end
