function M = inpoly( I , varargin )

  sz = size( I );
  M = zeros( sz( 1:3 ) , 'uint32' );

   T = I.SpatialTransform;
  iT = minv( T );
  
  
  %xyz = ndmat( I.X , I.Y , I.Z );
  XYZ = transform( ndmat( I.X , I.Y , I.Z ) , T );

  for v = 1:numel( varargin )
    C = varargin{v}; if isempty( C ), continue; end
    
    m = false( prod(sz),1 );
    if     false
    elseif isempty( C ), continue;
    elseif isnumeric( C )  %contour case
      
      C(:,end+1:3) = 0;
      c = transform( C , iT );
      
      ijk = [ val2ind( I.X , c(:,1) , 'sorted' ) , val2ind( I.Y , c(:,2) , 'sorted' ) , val2ind( I.Z , c(:,3) , 'sorted' ) ];
      ijk( any( ~isfinite(c) ,2) ,:) = [];
      
      onPlane = find( var( ijk , 1 ) == 0 );
      if numel( onPlane ) == 1;
        [Z,iZ] = getPlane( C );
        c = transform( C , iZ );
        c( any(~isfinite(c),2) ,:) = [];
        xyz = transform( XYZ , iZ );
        
        w = abs( xyz(:,3) ) < max( mean( diff( I.(char('X'+onPlane-1)) ) )/2 , 1 );
        
        try
          m(w) = inpoly( xyz(w,1:2).' , c(:,1:2).' );
        catch
          m(w) = inpolygon( xyz(w,1) , xyz(w,2) , c(:,1) , c(:,2) );
        end
      else
        error('Contour %d cannot be processed since it does not lie on a single plane.');
      end
      
    elseif isstruct( C ) && isfield( C , 'xyz' ) && isfield( C , 'tri' )
      
      m = ~~InsideMesh( Mesh(C,0) , XYZ );
      

    else
      error('unknown type of input');
    end
    M(m) = M(m) + 2^(v-1);
  end

  M = repmat( M , [1 , 1 , 1 , sz(4:end) ] );
end
