function x = frt( x , N , type )

  if nargin == 2  &&  ischar( N )
    type = N;
    N = size(x,1);
  else
    if nargin < 2 || isempty(N), N = size(x,1); end
    if nargin < 3,               type = 'dct';  end
  end

  if ~isscalar( N ), error('N has to be a scalar'); end
  
  nd = ndims(x);
  cc(1:nd-1) = {':'};
  
  if size(x,1) > N
    x = x(1:N,cc{:});
  elseif size(x,1) < N
    x(N,cc{:}) = 0;
  end
  
  
  switch lower(type)
    case {'dct','dctn','dct-ii','dct2e','dct2','dct-2'},         type = 'dct-ii'; 
    case {'idct','idctn','dct-iii','dct3e','dct3','dct-3'},      type = 'dct-iii'; 
    case {'dct-i','dct1e','dct1','dct-1'},                       type = 'dct-i'; 
    case {'dct-iv','dct4e','dct4','dct-4'},                      type = 'dct-iv'; 

    case {'dst-i','dst1e','dst1','dst-1'},                       type = 'dst-i'; 
    case {'dst-ii','dst2e','dst2','dst-2'},                      type = 'dst-ii'; 
    case {'dst-iii','dst3e','dst3','dst-3'},                     type = 'dst-iii'; 
    case {'dst-iv','dst4e','dst4','dst-4'},                      type = 'dst-iv'; 

    case {'h','hartley'},                                        type = 'hartley'; 

    case {'dct1no'},                                             type = 'dct1no'; 
  end

  x = frt_mx( x , type );
  
end

