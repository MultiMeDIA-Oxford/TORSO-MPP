function SSM = shapePCA( SS , varargin )

  if 0
  try
    nV  = size( SS(1).xyz ,1);
    nsd = size( SS(1).xyz ,2);
    if ~isfield( SS , 'tri' ), SS.tri = []; end
    F   = SS(1).tri;
    for s = 2:numel(SS)
      if size( SS(s).xyz ,1) ~= nV,   error('not equal number of vertices.'); end
      if size( SS(s).xyz ,2) ~= nsd,  error('not equal nsd.'); end
      if ~isequal( SS(s).tri , F ),   error('not equal faces.'); end
    end
  catch LE
    error('Something is wrong with the shape set.');
  end
  end
  
  
  
  [M,A] = shapeMean( SS , 'scale','orient');

  A = arrayfun( @(s)A(s).xyz , 1:numel(A) , 'un' , 0 );
  
%   [PCA,D,fun,C] = wPCA( cat(3 , A{:} ) ,'Mean',M,'Threshold',1e-4); %,varargin{:});
  PCA = wPCA( cat(3 , A{:} ) ,'Mean',M.xyz,'Threshold',1e-4,varargin{:});
  

  sz = size( M.xyz );
  nm = size( PCA ,2);
  PCA = reshape( PCA , [ sz , nm ] );
  
  
  SSM = M;
  SSM.xyzm = M.xyz;
  SSM.xyzM = PCA;
  
end
