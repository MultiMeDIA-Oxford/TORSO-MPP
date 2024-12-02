function [x,inds] = padding( x , padsize , varargin )
%padding Pad array.
%   B = padding(A,PADSIZE)
%
%   B = padding(A,PADSIZE,DIRECTION,...) pads A in the direction
%   specified by the string DIRECTION.  DIRECTION can be one of the
%   following strings.  
%
%       String values for DIRECTION
%       'pre'         Pads before the first array element along each
%                     dimension .
%       'post'        Pads after the last array element along each
%                     dimension. 
%       'both'        Pads before the first array element and after the
%                     last array element along each dimension.
%
%   By default, DIRECTION is 'both'.
%
%     Special Cases
%     -------
%         padsize = [ 1 2 3 ; 0 4 1 ]
%               ignore DIRECTION 
%                 dim 1: 1 pre-pad , 0 post-pad
%                 dim 2: 2 pre-pad , 4 post-pad
%                 dim 3: 3 pre-pad , 1 post-pad
%   
%         padsize = -3
%               all non-singleton dims DIRECTION-pad of size 3
%         
%         padsize = -[3;5]
%             ignore DIRECTION
%               all non-singleton dims pre-pad of size 3 and post pad of size 5
%
%         padsize = { 5 , 3 ; 1 , [2 1] }
%                 dim 1: 2 pre-pad , 1 post-pad
%                 dim 5: 3 DIRECTION-pad
%
%
%   B = padding(A,PADSIZE,METHOD,...) pads array A using the
%   specified METHOD.  METHOD can be one of these strings:
%
%       String values for METHOD
%       'value',V         Pads array extending with values.
%        V                Pads array extending with values.
%       'circular'        Pads with circular repetition of elements.
%       'symmetric'       Pads array with mirror reflections of itself.
%       'symmetric2'      Pads array with mirror reflections of itself, but
%                         reflecting on the whole entry
%       'replicate'       Repeats border elements of A.
%       'repn',sz         Repeats sz-border elements of A.
%       'extend',         Linear extension of borders.
%       'decay',length    Decay to zero at distance length.
%       'lpc',order       Linear predictor of order  order.
%       'lpc',[order n]   Linear predictor of order  order using the last n
%                         observations
%       'dctinpaint'      DCT inpainting
%       'dctinpaint',its  DCT inpainting with its iterations (if not
%                           specified use 100);
%       'dctinpaint',[its v]  DCT inpainting with its iterations with
%                             boundary
%
%

  PREfun = []; POSfun = [];

  %%parsing padsize and direction
  direction = 'both';
  [varargin,direction] = parseargs(varargin,'pre'  ,'$FORCE$',{'pre' ,direction});
  [varargin,direction] = parseargs(varargin,'post' ,'$FORCE$',{'post',direction});
  [varargin,direction] = parseargs(varargin,'both' ,'$FORCE$',{'both',direction});


  avoid_singletons = false;

  if iscell( padsize )
    c = repmat( padsize , 1 , 2 );
    padsize = 0;
    for d = 1:size(c,1)
      s = c{d,2};
      if isscalar(s)
        switch direction
          case 'pre' ,  s = [ s ; 0 ];
          case 'post',  s = [ 0 ; s ];
          case 'both',  s = [ s ; s ];
        end
      end
      if numel(s) > 2, error('invalid padsize.'); end

      padsize( 1:2 , c{d,1} ) = s(:);
    end
  end
  

  if size(padsize,1) == 1
    switch direction
      case 'pre' ,  padsize = [ padsize   ; padsize*0 ];
      case 'post',  padsize = [ padsize*0 ; padsize   ];
      case 'both',  padsize = [ padsize   ; padsize   ];
    end
    avoid_singletons = true;
  elseif size(padsize,1) > 2
    error('error in padsize');
  end
  
  if size( padsize , 2 ) == 1  &&  padsize(1) < 0
    padsize = repmat( -padsize , 1 , ndims(x) );
    avoid_singletons = true;
  end
  
  padsize = double( padsize );
  if any( padsize(:) < 0 )
    error('invalid padsize. On negative -> all dims.');
  end
  
  padsize = padsize( : , 1:find( any(padsize,1) , 1 , 'last' ) );


  %%method and value, or method and parameter
  if numel(varargin) == 0
    method = 'value';
    v      = 0;
  elseif numel(varargin) == 1  &&  ( isnumeric( varargin{1} ) || islogical( varargin{1} ) ) &&  isscalar( varargin{1} )
    method = 'value';
    v      = varargin{1};
  elseif numel(varargin) == 1
    method = varargin{1};
    v      = [];
  elseif numel( varargin ) == 2
    method = varargin{1};
    v      = varargin{2};
  else
    error('misunderstanding method!!!');
  end

  v = cast( v , class(x) );
  
  
  switch lower(method)
    case {'dctinpaint','inpaint'}
      nans_p = ~isfinite(x);
      nans_v = x( nans_p );
  end
  

  %%doing the padding
  sz = size(x);
  sz( max(numel(sz),size(padsize,2)) + 1 ) = 0;
  sz( ~sz ) = 1;
  
  
  if avoid_singletons
    for d = find( sz == 1 )
      padsize([1 2],d) = 0;
    end
  end

  
  c = cell(1,numel(sz));
  c( 1:numel(sz) ) = {':'};
  inds = cell(1,ndims(x));
  for d = find( any(padsize,1) )
    n1 = padsize(1,d);
    n2 = padsize(2,d);
    inds{d} = n1 + (1:size(x,d));
    switch lower(method)
      case {'value','v','val'}
        if n1
          if isnumeric(v)
            x  = cat(d,     zeros( [ sz(1:d-1) ,  n1 , sz(d+1:end) ] , class(x) ) + v , x );
          elseif islogical(v)
            x  = cat(d,     true(  [ sz(1:d-1) ,  n1 , sz(d+1:end) ]            ) & ~~v , x );
          end
        end
        if n2
          if isnumeric(v)
            x  = cat(d, x , zeros( [ sz(1:d-1) ,  n2 , sz(d+1:end) ] , class(x)  ) + v     );
          elseif islogical(v)
            x  = cat(d, x , true(  [ sz(1:d-1) ,  n2 , sz(d+1:end) ]             ) & ~~v     );
          end
        end

      case {'replicate','rep','re'}
        x    = x(c{1:d-1},  [ ones(1,n1)   1:size(x,d)   size(x,d)*ones(1,n2) ]  ,c{d+1:end});

      case {'replicaten','repn','ren','closest'}
        if isempty(v), v = 1; end
        if numel(v) == 1, v = [v v]; end
        
        cpre  = 1:v(1);
        cpre  = cpre( mod( -n1:-1 , numel( cpre ) ) + 1 );

        cpos  = size(x,d)-v(2)+1:size(x,d);
        cpos  = cpos( mod( 0:n2-1 , numel( cpos ) ) + 1 );
        
        x     = x(c{1:d-1},  [ cpre   1:size(x,d)   cpos ]  ,c{d+1:end});
      
      case {'circular','cir','circ','per','periodic'}
        idxs  = 1:size(x,d);
        x     = x(c{1:d-1} , idxs( mod( -n1:(size(x,d)+n2-1) , numel(idxs) ) + 1 ) , c{d+1:end});
        
      case {'symmetric','symm','sym','s'}
        idxs  = [ 1:size(x,d)   size(x,d):-1:1 ];
        x     = x(c{1:d-1},  idxs( mod( -n1:(size(x,d)+n2-1) , numel(idxs) ) + 1)  ,c{d+1:end});
        
      case {'symmetric2','symm2','sym2','s2'}
        idxs  = [ 1:size(x,d)   size(x,d)-1:-1:2 ];
        x     = x(c{1:d-1},  idxs( mod( -n1:(size(x,d)+n2-1) , numel(idxs) ) + 1)  ,c{d+1:end});
        
      case {'extend','ex','ext'}
        if n1
          D = x(c{1:d-1}, min(2,size(x,d)) ,c{d+1:end}) - x(c{1:d-1}, 1 ,c{d+1:end});
          C = ipermute( (-n1:-1).' , [ d  1:d-1  d+1:ndims(x) ] );
        
          x = cat(d, bsxfun( @plus , x(c{1:d-1}, 1 ,c{d+1:end}) , bsxfun(@times,C,D) ) , x );
        end
        if n2
          D = x(c{1:d-1},  size(x,d) ,c{d+1:end}) - x(c{1:d-1},  max(size(x,d)-1,1)  ,c{d+1:end});
          C = ipermute( (1:n2).' , [ d  1:d-1  d+1:ndims(x) ] );
          
          x = cat(d, x , bsxfun( @plus , x(c{1:d-1}, size(x,d) ,c{d+1:end}) , bsxfun(@times,C,D) ) );
        end

      case {'decay','dec','tozero'}
        if isempty(v), error( 'after ''%s'' you have to specify the length', method ); end
        if numel(v) == 1, v = [v v]; end
        
        if ~isfloat(x)
          try
            x = double(x);
          catch
            x = single(x);
          end;
        end

        if n1
          D = x(c{1:d-1}, 1 ,c{d+1:end})/v(1);
          C = ipermute( (-n1:-1).' , [ d  1:d-1  d+1:ndims(x) ] );
          C = C( C > -v(1) );
          Z = n1 - numel(C);
          x = cat(d, bsxfun( @plus , x(c{1:d-1}, 1 ,c{d+1:end}) , bsxfun(@times,C,D) ) , x );
          if Z > 0
            x = cat(d, zeros([sz(1:d-1) ,  Z , sz(d+1:end)]) , x );
          end
        end
        if n2
          D = -x(c{1:d-1}, size(x,d) ,c{d+1:end})/v(2);
          C = ipermute( (1:n2).' , [ d  1:d-1  d+1:ndims(x) ] );
          C = C( C < v(2) );
          Z = n2 - numel(C);
          x = cat(d, x , bsxfun( @plus , x(c{1:d-1}, size(x,d) ,c{d+1:end}) , bsxfun(@times,C,D) ) );
          if Z > 0
            x = cat(d, x , zeros([sz(1:d-1) ,  Z , sz(d+1:end)]) );
          end
        end

        
      case {'lpc','ar'}
        if isempty(v), error( 'after ''%s'' you have to specify the order', method ); end
        
        noisefactor = 0;
        if numel(v) == 1
          order   = v;
          length  = Inf;
        elseif numel(v) == 2
          order   = v(1);
          length  = v(2);
        elseif numel(v) == 3
          order        = v(1);
          length       = v(2);
          noisefactor  = v(3);
        end

        x = permute( x , [ d  1:d-1  d+1:ndims(x) ] );
        szX = size(x); 
        x = x(:,:);
        
        xpre = zeros( n1 , size(x,2) );
        xpos = zeros( n2 , size(x,2) );
        for j = 1:size(x,2)
          if n1,   xpre(:,j) = flipdim( LPC( flipdim( x(:,j) ,1) , order , length , noisefactor , n1 ) ,1 ); end
          if n2,   xpos(:,j) =          LPC(          x(:,j)     , order , length , noisefactor , n2 );      end
        end
        x = cat(1, xpre , x , xpos );
        x = reshape( x , [ numel(x)/prod(szX(2:end))  szX(2:end) ] );
        x = ipermute( x , [ d  1:d-1  d+1:ndims(x) ] );
        
      case {'dctinpaint','inpaint'}
        if n1
          x      = cat(d,               nan( [ sz(1:d-1) ,  n1 , sz(d+1:end) ] ) , double(x) );
          nans_p = cat(d,             false( [ sz(1:d-1) ,  n1 , sz(d+1:end) ] ) , nans_p    );
        end
        if n2
          x      = cat(d, double(x) ,   nan( [ sz(1:d-1) ,  n2 , sz(d+1:end) ] )             );
          nans_p = cat(d, nans_p    , false( [ sz(1:d-1) ,  n2 , sz(d+1:end) ] )             );
        end

      case 'user'
        if isempty( PREfun ) && isempty( POSfun )
%           PREfun = @(x,COORDS,COORDSn)  orthofit( COORDS , x , polydeg(COORDS,x) , COORDSn );
%           POSfun = @(x,COORDS,COORDSn)  orthofit( COORDS , x , polydeg(COORDS,x) , COORDSn );
          
          PREfun = @(x,COORDS,COORDSn)  orthofit( COORDS(1:4) , x(1:4) , 3 , COORDSn );
          POSfun = @(x,COORDS,COORDSn)  orthofit( COORDS(end-3:end) , x(end-3:end) , 3 , COORDSn );

        end
        
        %%%
        x = permute( x , [ d  1:d-1  d+1:ndims(x) ] );
        szX = size(x); 
        x = x(:,:);
        XCOORDS    = ( 1:size(x,1) ).';
        XCOORDSpre = (-n1:-1).' + 1;
        XCOORDSpos = size(x,1) + (1:n2).';
        
        xpre = zeros( n1 , size(x,2) );
        xpos = zeros( n2 , size(x,2) );
        for j = 1:size(x,2)
          if n1,   xpre(:,j) = PREfun( x(:,j) , XCOORDS , XCOORDSpre ); end
          if n2,   xpos(:,j) = POSfun( x(:,j) , XCOORDS , XCOORDSpos ); end
        end
        x = cat(1, xpre , x , xpos );
        x = reshape( x , [ numel(x)/prod(szX(2:end))  szX(2:end) ] );
        x = ipermute( x , [ d  1:d-1  d+1:ndims(x) ] );
        %%%
        
    end
    sz(d)   = size(x,d);
  end


  
  switch lower(method)
    case {'dctinpaint','inpaint'}
      if isempty( v ), v = 100; end

      if numel(v) == 2
        for d = find( any(padsize,1) )
          if padsize(1,d), x( c{1:d-1} , 1         , c{d+1:end} ) = v(2); end
          if padsize(2,d), x( c{1:d-1} , size(x,d) , c{d+1:end} ) = v(2); end
        end
      end
      
      x = inpaintn( x , v(1) );
      x( nans_p ) = nans_v;
  end

  
  for d = 1:numel(inds)
    if isempty( inds{d} )
      inds{d} = 1:size(x,d);
    end
  end
  
  
  function EXT = LPC( X , order , length , noisefactor , NE )
    
    if size(X,2) ~= 1, error('no es un vector!!!'); end
    
    if ~isinf( length )
      X = X( end-length+ 1: end );
    end

    N = numel(X);

    order = min( order , round( N/5 ) );
    
      M = toeplitz( X(order:end-1) , X(order:-1:1) );
      b = X( order+1:end );
    
    a = pinv(M)*b;

    EXT = X; EXT( N + NE ) = 0;
    for n = 1:NE
      EXT( N + n ) = a.' * EXT( (N+n-1):-1:(N+n-order) );
    end
    EXT = EXT( N + (1:NE) );
    
    noise = shuffle( repmat( b - M*a , ceil(numel(EXT)/numel(b)) , 1 ) )*noisefactor;
    EXT = EXT + noise( 1:numel(EXT) );
    
  end
  
  
  
end
