function TS = InPlaneAlignImages( HS , varargin )

  RangeTX = 20;
  try, [varargin,~,RangeTX] = parseargs(varargin,'RangetX','$DEFS$',RangeTX); end
  
  RangeTY = 20;
  try, [varargin,~,RangeTY] = parseargs(varargin,'RangetY','$DEFS$',RangeTY); end
  
  RangeRZ = 10;
  try, [varargin,~,RangeRZ] = parseargs(varargin,'RangerZ','$DEFS$',RangeRZ); end
  

  STRATEGY = [ 8 , 7 , 2 ];
  
  vprintf = @(varargin)fprintf(varargin{:});

  DX = 0.5;

  HS = HS(:,1);
  N = size( HS ,1);

  %%

  TIMEPHASES = true;
  try, [varargin,TIMEPHASES] = parseargs(varargin,'TIMEPHASES','$FORCE$',{true,TIMEPHASES});  end
  try, [varargin,TIMEPHASES] = parseargs(varargin,'FIRSTPHASE','$FORCE$',{false,TIMEPHASES}); end
  
  if ~TIMEPHASES
    for r = 1:N
      try, HS{r} = HS{r}.t1; end
    end
  else
    %preparing slices to be Aligned
    sz4 = arrayfun( @(h)size(HS{h},4) , 1:N );
    if      var( sz4 ) == 0
    elseif  any( sz4 == 1 )
      
      %error('an static image cannot be aligned to cine ones!');
      warning('an static image cannot be aligned to cine ones! Switching to use the first phase only.');
      for r = 1:N
        try, HS{r} = HS{r}.t1; end
      end
      
    else
      msz4 = max( sz4 );
      for s = find( sz4(:).' ~= msz4 )
        data = double( HS{s}.data );
        sz   = size( data ); sz(4) = msz4;
        
        while size( HS{s} , 4 ) < msz4, HS{s} = cat( 4 , HS{s} , HS{s} ); end
        HS{s} = HS{s}(:,:,:,1:msz4);

        HS{s}.data = idctn( resize( dctn( data ) , sz ) );
      end
    end
  end
  
  %%
  
  
  TS = repmat( {eye(4)} , [ N , 1 ] );
  for r = 1:N
    if ~isequal( TS{r} , eye(4) ) && ~isempty( HS{r,1} )
      HS{r,1} = transform( HS{r,1} , TS{r} );
    end
  end
  


  %%
  
  GKERNEL = 0;
  try, [varargin,~,GKERNEL] = parseargs(varargin,'GKernel','$DEFS$',GKERNEL); end

  USEMASK = false;
  try, [varargin,USEMASK] = parseargs(varargin,'useMASK','$FORCE$',{true,USEMASK}); end

  for r = 1:N
    if isempty( HS{r,1} ), continue; end
    M = HS{r,1};
    M.data = double( M.data );
    
    if GKERNEL
      w = isnan( M.data );
      M.data = nonans( M.data , 'euclidean' );
      
      xc = 0:mean(diff(M.X)):max(mean(diff(M.X))*5,4*GKERNEL); xc = [ -fliplr(xc(2:end)) , xc ];
      yc = 0:mean(diff(M.Y)):max(mean(diff(M.Y))*5,4*GKERNEL); yc = [ -fliplr(yc(2:end)) , yc ];
      
      G = gaussianKernel( xc  , yc , 's' , GKERNEL , 'normalize' );
      M.data = imfilter( M.data , G , 'replicate' );
      M.data(w) = NaN;
    end
  
    if USEMASK  && isstruct( M.FIELDS ) && isfield( M.FIELDS , 'Hmask' )
      M.data( expand( ~M.FIELDS.Hmask , size( M ) ) ) = NaN;
    end
    
    M = crop( M , 1 , 'mask' , isfinite( M.data ) );
    M.data(  [1 end],:,:,:) = NaN;
    M.data(:,[1 end],:,:,:) = NaN;
    
    HS{r,1} = M;
    HS{r,1}  = HS{r,1}.centerGrid;
    oHS{r,1} = HS{r,1}.SpatialTransform;
  end
  %%  

  FIXED = [];
  try, [varargin,~,FIXED] = parseargs(varargin,'fixed','$DEFS$',FIXED); end
  
  ORDER = 1:N;
  for r = ORDER(:).'
    if any( r == FIXED ), continue; end
    if isempty( HS{r,1} ), continue; end
    vprintf('InPlaneAlignment from Images, slice %2d ... ', r );
    %%

    M = HS{r,1};
    
    XYZ = []; V = [];
    for s = setdiff( 1:N , r )
      if isempty( HS{s,1} ), continue; end

      if ipd( M.SpatialTransform(1:3,3).' , HS{s}.SpatialTransform(1:3,3).' , 'normal') < 1e-4, continue; end
      il = intersectionLine( M , HS{s} , DX );
      if isempty( il ), continue; end
      v  = at( HS{s} , il , 'closest','outside_value',NaN,'linear' );
      w = any( isfinite(v) ,2);
      il = il(w,:);
      if size( il ,1) < 20/DX, continue; end
      v  =  v(w,:);
      
      XYZ = [XYZ ; il ];
      V   = [ V ; v ];
    end
    np = size( XYZ ,1);
    if np < 30
      vprintf(' too few to do!\n');
      continue;
    end
    
    
    oT = M.SpatialTransform; ioT = minv( oT );
    M = transform( M , ioT );
    XYZ = transform( XYZ , ioT ); XYZ(:,3) = 0;

    if 0
    figure
    image3( M.t1 ); view(2); zlim([-2 2])
    hold on
    [~,ord] = sort( V(:,1) , 'descend' );
    cline( XYZ(ord,:) , V(ord,1) , 'Marker','o','EdgeColor','none','markeredgecolor','none');
    hold off
    end
    
    %%
    
    RX = RangeTX;
    RY = RangeTY;
    RZ = RangeRZ;
    XYR = [0 0 0];
    
    bestE = Inf; bestT = eye(4);
    for it = 1:STRATEGY(1)
      vprintf('+');
      TXs = linspace( XYR(1)-RX , XYR(1)+RX , STRATEGY(2) );  RX = RX/STRATEGY(3);
      TYs = linspace( XYR(2)-RY , XYR(2)+RY , STRATEGY(2) );  RY = RY/STRATEGY(3);
      RZs = linspace( XYR(3)-RZ , XYR(3)+RZ , STRATEGY(2) );  RZ = RZ/STRATEGY(3);
      
      XYs = ndmat( unique( TXs ) , unique( TYs ) );
      [~,ord] = sort( fro2( bsxfun(@minus,XYs,XYR(1:2)) ,2) ); XYs = XYs(ord,:);
      RZs = unique( RZs ); [~,ord] = sort( abs( RZs - XYR(3) ) ); RZs = RZs(ord);
      
      
      for z = RZs(:).'
        T = maketransform( 'rz' , z );
        
        for xy = 1:size(XYs,1)
          T([1 2],4) = XYs(xy,:);
          
          v = InterpPointsOn3DGrid( M.data , M.X , M.Y , 0 , XYZ , 'nmatrix' , T , 'closest' , '*linear' );
          
          E = 1 - NCC( v , V );
          if E < bestE
            bestE = E;
            bestT = T;
            XYR   = [ XYs(xy,:) , z ];
          end
        end
      end
    end
    
    %%
    bestT = minv( bestT );
    
    M = transform( M , bestT );
    
    if 0
    figure
    image3( M.t1 ); view(2); zlim([-2 2])
    hold on
    [~,ord] = sort( V(:,1) , 'descend' );
    cline( XYZ(ord,:) , V(ord,1) , 'Marker','o','EdgeColor','none','markeredgecolor','none');
    hold off
    end
    
    M = transform( M , oT );
    
    HS{r,1} = M;
    TS{r,1} = HS{r,1}.SpatialTransform / oHS{r,1};
  
    vprintf(' done.\n');
  end

end
function E = NCC( A , B )

  E = 0;

  A = A(:); B = B(:);
  w = isfinite( A ) & isfinite( B );
  if ~any(w), return; end
  
  A = A(w); A = A - mean(A); A = A/std(A);
  B = B(w); B = B - mean(B); B = B/std(B);

  E = A(:).' * B(:) / ( numel(A) );
  if ~isfinite( E )
    E = 0;
  end
end

