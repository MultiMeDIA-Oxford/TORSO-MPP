function X = resize( X , varargin )
% 
% resize( X , sz1 , sz2 , sz3 , {value} );
% 

  if nargin == 0, return; end
  
  if iscell( varargin{end} )
    v = varargin{end}{1};
    varargin(end) = [];
  else
    v = zeros(1,class(X));
  end

  empties = cellfun('isempty',varargin);
  for d = find( empties )
    varargin{d} = size(X,d);
  end
  sz = cell2mat( varargin );

  
  nd = max( numel(sz) , ndims(X) );
  sz( (end+1):nd ) = 1;
  
  cc(1:nd) = {':'};
  for d = 1:numel(sz)
    if      size(X,d) > sz(d)
      X = X( cc{1:d-1} , 1:sz(d) , cc{d+1:end} );
    elseif  size(X,d) < sz(d)
      X( cc{1:d-1} , (size(X,d)+1):sz(d) , cc{d+1:end} ) = v;
    end
  end

end
