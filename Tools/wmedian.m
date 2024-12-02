function m = wmedian( x , w )

  if ~isvector( x )
    warning('only vectors allowed... vectorizing!!'); 
  end

  PLOT = false;
  
  if nargin < 2 ||  isscalar( w )  ||  all( w == w(1) )
    
    x = x(:);
    
    z = isfinite( x );
    x = x( z );
    
    N = numel(x);
    
    if ~rem( N , 2 )
      J = N / 2;
      x = sortK( x , {J,J+1} );
      m = ( x(J) + x(J+1) )/2;
    else
      J = ( N+1 )/2;
      x = sortK( x , {J} );
      m = x(J);
    end
    
  else
    
    if ~isequal( size(x) , size(w) )
      error('unequal sizes x and w');
    end
    
    if any( w < 0 ), error('only non negative weights allowed'); end
    
    x = x(:);  w = w(:);
    
    z =   w ~= 0  &  isfinite( x )  &  isfinite( w );
    x = x( z );  w = w( z );
    
    N = numel(x);

    if PLOT, x_orig=x; w_orig=w; end
    
    [x,w] = sortK( {x,w} );
    
    lastX_id = 1; lastX = x( lastX_id );
    for i = 2:N
      if x( i ) == lastX
        x(i)        = NaN;
        w(lastX_id) = w(lastX_id) + w(i);
      else
        lastX_id = i; lastX = x( lastX_id );
      end
    end
    
    z = ~isnan(x);
    w = w( z );  x = x( z );
    
    if numel(x) == 1
      m = x;
      return;
    end
    
    if all( w == w(1) )
      m = wmedian( x );
      return;
    end
    
    
    cw = cumsum( w );

    J = find( cw >= cw(end)/2 - eps(0.1)*N , 1 , 'first' );
    
    slope = cw(J) - ( cw(end) - cw(J) );
    if abs( slope ) < eps(1)*N
      m = ( x(J) + x(J+1) )/2;
    elseif slope > 0
      m = x(J);
    elseif slope < 0
      error('!!!!');
    end

    
   if PLOT
      xx = unique( [ linspace( x( max(1,J-1) ) , x( min(numel(x),J+1) ) , 200 ) , ...
                     x( max(1,J-2):min(numel(x),J+2) ).'                        , ...
                     dualVector( x( max(1,J-3):min(numel(x),J+3) ).' )          ] );
      xx = unique( [ xx , linspace( x( 1 ) , x( end ) , 20 ) ] );
                     

      EE = arrayfun( @(z) sum( w_orig .* abs( x_orig - z ) ) , xx );

      figure; plot( xx , EE , '.-' );
      line( m*[1 1] , [-1 1]*1e20,'color','r','yliminclude','off');
    end    
    
  end

end
