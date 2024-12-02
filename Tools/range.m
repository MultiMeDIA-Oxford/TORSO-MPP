function [ r , dr ] = range( x , dim , prc )

  if nargin < 2 || isempty( dim ), dim = 0; end
  if nargin < 3 || isempty( prc ), prc = 0; end

  if numel(prc) == 1
    if prc < 0 || prc > 50, error('percentile must be in [0,50)'); end
    prc = [ prc , 100-prc ];
  end
  
  x( ~isfinite(x) ) = NaN;

  if dim == 0
    x = x(:).';
    dim = 2;
  end
  
  
  if prc(1) == 0
    L = min( x , [] , dim );
  else
    L = prctile( x , prc(1) , dim );
  end
  if prc(2) == 100
    M = max( x , [] , dim );
  else
    M = prctile( x , prc(2) , dim );
  end
  
  r = cat( dim , L , M );
    
  if nargout > 1
    dr = diff( r , 1 , dim );
  end

end
