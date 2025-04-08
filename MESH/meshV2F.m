function F = meshV2F( M , V , mode )

  if nargin < 3, mode = 'area'; end
  
  nF = size( M.tri ,1);
  nS = size( M.tri ,2);
  nV = size( M.xyz ,1);
 
  if isa( V , 'function_handle' )
    try, V = feval( V , M ); catch
    try, V = feval( V , M.xyz ); catch
      error('invalid function to evaluate on mesh');
    end; end
  elseif ischar( V )
    try, V = M.(['xyz',V]); catch
    try, V = M.(V); catch
      error('invalid attribute name.');
    end; end
  end
  if size( V ,1) ~= nV
    error('invalid per-vertices-field');
  end

  sz = size( V );
  sz(1) = nF;
  V = V(:,:);
  
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
    elseif issparse( W ) && size( W ,2) == nT && size( W ,1) == nF
      F = W * V;
      if isempty(N), N = sum( W ,2); end
    elseif isscalar( W )
      Tid = ( 1:nF ).';
      W = sparse( M.tri , repmat( Tid ,nS,1) , W ,nV,nF);
      F = W * V;
      if isempty(N), N = sum( W ,2); end
    elseif size( W ,1) == nF
      Tid = ( 1:nF ).';
      W = repmat(W,1,nS/size(W,2));
      W = sparse( M.tri , repmat( Tid ,nS,1) , W ,nV,nF);
      F = W * V;
      if isempty(N), N = sum( W ,2); end
    else
      error('incorrect W matrix');
    end
    
    %if required, normalized by N
    if 0
    elseif isscalar( N ) && N == 1
    elseif size( N ,1) == nV && size( N ,2) == 2 && all( N == 1 )
    elseif size( N ,1) == nV && size( N ,2) == 1
      F = bsxfun( @rdivide , F , N );
    elseif isscalar( N )
      F = F * (1/N);
    else
      error('incorrect normalization step');
    end
    
  elseif isa( mode , 'function_handle' )

    nC = size( V ,2);
    F = NaN( nF , nC );
    
    Fid = ( 1:nF ).';
    Fid = repmat( Fid , nS , 1 );
    
    for c = 1:nC
      F(:,c) = accumarray( Fid , V( M.tri(:) ,c) , [nF,1] , mode );
    end
    
  end
  
  F = reshape( F , sz );
end
