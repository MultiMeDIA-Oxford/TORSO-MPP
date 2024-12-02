function M = ReorderNodes( M , XYZ )

%   [~,~,new_id] = unique( [ M.xyz ; XYZ ] , 'rows' , 'first' );
% 
%   
% 
%   
%   [~,usedNODES,newIDX] = unique( M.xyz , 'rows' , 'stable' );
%   if numel( usedNODES ) ~= size( M.xyz , 1 )
%     usedNODES = sort( usedNODES );
%     M.tri = newIDX( M.tri );
%     for f = Fxyz
%       M.(f{1}) = M.(f{1})(usedNODES,:);
%     end
%     if th > 0, X = X( usedNODES ,:); end
%   end  
  
  
  

  if ~isequal( M.xyz( 1:size( XYZ.xyz ,1) ,:) , XYZ.xyz )
    nnF = size( XYZ.xyz , 1 );
    M.xyz = [ XYZ.xyz ; M.xyz ];
    M.tri = [ (1:nnF).'*[1 1 1 1] ; nnF + M.tri ];
    M = MeshTidy( M , 0 , true , [1 1 1 0] );
    M.tri( 1:nnF , : ) = [];
  end

end
