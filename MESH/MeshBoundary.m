function M = MeshBoundary( M )

  asMESH = true;
  if ~isstruct( M )
    asMESH = false;
    M = struct('tri',M);
  end
%   if ~isfield( M , 'xyz' )
%     M.xyz = zeros( 0 , 3 );
%   end
  
  M.celltype = meshCelltype( M );

  
  switch M.celltype
    case 3
      allF = [ M.tri(:,1) ; M.tri(:,2) ];
      IDXs = repmat( (1:size(M.tri,1)).' ,[1 2] ); IDXs = IDXs(:);
      F    = allF;
      [u,~,c] = unique( F );
      c = accumarray( c(:) , 1);
      u = u( c == 1 ,:);
      w = ismember( F , u );
      IDXs  = IDXs(w);
      M.tri = allF( w ,:);

      M.celltype = 3;
    
    case 5
      allF = [ M.tri(:,[1,2]) ; M.tri(:,[2,3]) ; M.tri(:,[3,1]) ];
      IDXs = repmat( (1:size(M.tri,1)).' ,[1 3] ); IDXs = IDXs(:);
      F    = sort( allF ,2);
      [u,~,c] = unique( F , 'rows' );
      c = accumarray( c(:) , 1);
      u = u( c == 1 ,:);
      w = ismember( F , u , 'rows' );
      IDXs  = IDXs(w);
      M.tri = allF( w ,:);

      M.celltype = 3;
      
      
    case 10
      allF = [ M.tri(:,[2,3,4]) ; M.tri(:,[4,3,1]) ; M.tri(:,[1,2,4]) ; M.tri(:,[1,3,2]) ];
      IDXs = repmat( (1:size(M.tri,1)).' ,[1 4] ); IDXs = IDXs(:);
      F    = sort( allF ,2);
      [u,~,c] = unique( F , 'rows' );
      c = accumarray( c(:) , 1);
      u = u( c == 1 ,:);
      w = ismember( F , u , 'rows' );
      IDXs  = IDXs(w);
      M.tri = allF( w ,:);
      
      M.celltype = 5;
      
      
  end
  
  if asMESH

    for f = fieldnames(M).'
      if ~strncmp( f{1} , 'tri' , 3 ) || strcmp( f{1} , 'tri' ), continue; end
      M.( f{1} ) = M.( f{1} )( IDXs ,:,:,:,:,:,:);
    end
    if      M.celltype == 5
      M = rmfield( M ,'celltype' );
    elseif  M.celltype == 3
      M = rmfield( M ,'celltype' );
    end
  
  else
    
    M = M.tri;
  
  end

end
