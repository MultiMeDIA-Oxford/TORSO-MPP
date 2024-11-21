function V = meshF2V( M , F , mode )

  if nargin < 3, mode = 'area'; end
  
  nF = size( M.tri ,1);
  nS = size( M.tri ,2);
  nV = size( M.xyz ,1);
 

  if isa( F , 'function_handle' )
    try, F = feval( F , M ); catch
    try, F = feval( F , M.tri ); catch
      error('invalid function to evaluate on mesh');
    end; end
  elseif ischar( F )
    try, F = M.(['tri',F]); catch
    try, F = M.(F); catch
      error('invalid attribute name.');
    end; end
  end
  if size( F ,1) ~= nF
    error('invalid per-faces-field');
  end

  sz = size( F );
  sz(1) = nV;
  F = F(:,:);
  
  if ischar( mode )

    N = []; W = [];
    switch lower(mode)
      case {'s','sum'}
        W = 1;
        N = 1;

      case {'m','mean','average'}
        W = 1;
        N = accumarray(  M.tri(:) , 1 );

      case {'l','length'}
        if meshCelltype(M) ~= 3, error('invalid weighting for the celltype'); end
        W = meshQuality( M , 'length' );
        N = 1;

      case {'nl','nlength','normalizedl','normalizedlength'}
        if meshCelltype(M) ~= 3, error('invalid weighting for the celltype'); end
        W = meshQuality( M , 'length' );

      case {'a','area'}
        if meshCelltype(M) ~= 5, error('invalid weighting for the celltype'); end
        W = meshQuality( M , 'area' );
        N = 1;

      case {'na','narea','normalizeda','normalizedarea'}
        if meshCelltype(M) ~= 5, error('invalid weighting for the celltype'); end
        W = meshQuality( M , 'area' );

      case {'v','vol','volume'}
        if meshCelltype(M) ~= 10, error('invalid weighting for the celltype'); end
        W = meshQuality( M , 'volume' );
        N = 1;

      case {'nv','nvol','nvolume','normalizedv','normalizedvol','normalizedvolume'}
        if meshCelltype(M) ~= 10, error('invalid weighting for the celltype'); end
        W = meshQuality( M , 'volume' );

      case {'g','angles'}
        if meshCelltype(M) ~= 5, error('invalid weighting for the celltype'); end
        W = meshQuality( M , 'angles' );
        N = 1;

      otherwise, error('invalid weighting option');
    end

    if     isempty( W )
    elseif issparse( W ) && size( W ,2) == nT && size( W ,1) == nV
      V = W * F;
      if isempty(N), N = sum( W ,2); end
    elseif isscalar( W )
      Tid = ( 1:nF ).';
      W = sparse( M.tri , repmat( Tid ,nS,1) , W ,nV,nF);
      V = W * F;
      if isempty(N), N = sum( W ,2); end
    elseif size( W ,1) == nF
      Tid = ( 1:nF ).';
      W = repmat(W,1,nS/size(W,2));
      W = sparse( double(M.tri) , repmat( double(Tid) ,nS,1) , W ,nV,nF);
      V = W * F;
      if isempty(N), N = sum( W ,2); end
    else
      error('incorrect W matrix');
    end
    
    %if required, normalized by N
    if 0
    elseif isscalar( N ) && N == 1
    elseif size( N ,1) == nV && size( N ,2) == 2 && all( N == 1 )
    elseif size( N ,1) == nV && size( N ,2) == 1
      V = bsxfun( @rdivide , V , N );
    elseif isscalar( N )
      V = V * (1/N);
    else
      error('incorrect normalization step');
    end
    
  elseif isa( mode , 'function_handle' )
    
    nC = size( F ,2);
    V = NaN( nV , nC );
    for c = 1:nC
      V(:,c) = accumarray( M.tri(:) , repmat( F(:,c) ,nS,1) , [nV,1] , mode );
    end
    
  end
  
  V = reshape( V , sz );
end
