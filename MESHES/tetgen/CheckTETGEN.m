function ok = CheckTETGEN( S , varargin )

  ok = false;

  try
    V = tetgen( S , varargin{:} );

%     vol = dot( cross( V.xyz(V.tri(:,2),:) - V.xyz(V.tri(:,1),:) ,  V.xyz(V.tri(:,3),:) - V.xyz(V.tri(:,1),:) , 2 ) ,...
%       V.xyz(V.tri(:,4),:) - V.xyz(V.tri(:,1),:) , 2 );
%     vol = sum( abs( vol ) )/6;
% 
%   %   BooleanMeshes( S , '-' , ExtractSurfaceFromTetras( V ) )
% 
%     ok = abs( MeshVolume( Mesh(S,0) ) / vol - 1 ) < 1e-5;
    ok = true;
  end
  

end
