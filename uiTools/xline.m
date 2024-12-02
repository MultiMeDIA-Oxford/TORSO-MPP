function handle_ = xline( L , varargin )


  
  
  if iscell( L )
    handle = L{1};
    L = L{2};
  else
    handle = [];
  end
    
  
  if numel( L ) == 2    % L = [ m , h ]  y = m*x + h    si m es inf --> error
    R = 1e20;

    m = L(1);
    if ~isfinite( m ), error('no infinite slope allowed'); end
    
    h = L(2);
    
%     R = xdouble(R); m = xdouble(m); h = xdouble(h);
    
    D   = sqrt( m*m*R + R -  h*h );
    mh  = m*h;
    mD  = m*D;
    den = 1/(1+m*m);
    
    X1 = - ( mh + D )*den;     Y1 = ( h - mD )*den;
    X2 = - ( mh - D )*den;     Y2 = ( h + mD )*den;
    
  elseif numel( L ) == 4  % L = [ x0 y0 vx vy ]
    
    R = geospace(1e-10,1e20,100);
    varargin = [ varargin , 'marker','none' ];
    
    [varargin,RAY] = parseargs(varargin,'ray','$FORCE$',{true,false});
    if RAY, R = [ 0 , R ];
    else  , R = [ -fliplr(R) , 0 , R ];
    end
      
    X1 = L(1) + R*L(3);
    Y1 = L(2) + R*L(4);

    X2 = [];
    Y2 = [];
  end
    
    
  X1 = double(X1);  Y1 = double(Y1);
  X2 = double(X2);  Y2 = double(Y2);
  
  if isempty( handle )
    varargin = getLinespec( varargin );
    
    handle = line(0,0,'xliminclude','off','yliminclude','off','color',0.7*[1 1 1],'linestyle','--',varargin{:});
  end

  set( handle , 'xdata' , [X1 X2].' , 'ydata' , [Y1 Y2].' );

  if nargout > 0
    handle_ = handle;
  end
         
end

