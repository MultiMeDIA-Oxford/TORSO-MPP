function X = meshFarthestPointSampling( M , IDS , minD , maxN , Subs )


  if nargin < 3 || isempty( minD ), minD = 0;   end
  if nargin < 4 || isempty( maxN ), maxN = Inf; end
  if nargin < 4 || isempty( Subs ), Subs = Inf; end

  if nargin < 2 || isempty( IDS )
    IDS = 1;
  end
  if any( IDS < 1 )
    error('initial IDS should be all indexes (greater than zero)');
  end
  if any( IDS > size( M.xyz ,1) )
    error('initial IDS should be all valid indexes (smaller than number of nodes)');
  end
%   IDS = M.xyz( IDS(:) ,:);



  s = 0;
  while size( M.xyz ,1) < 1e6  &&  s < Subs
  	M = MeshSubdivide( M );
    s = s + 1;
  end
%   IDS = vtkClosestPoint( struct('xyz',double(M.xyz)) , double( IDS ) );


  X = FarthestPointSampling( M.xyz , IDS , minD , maxN );
  
  
end