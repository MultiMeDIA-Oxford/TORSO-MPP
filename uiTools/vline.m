function h_ = vline( x , varargin )

  [varargin,STACK_AT_BOTTOM] = parseargs( varargin , 'bottom','$FORCE$',{true,false} );
  varargin = getLinespec( varargin );

  h = line(0,0,'xliminclude','on','yliminclude','off','color',0.7*[1 1 1],'linestyle','--',varargin{:});


  set( h , 'ydata' , vec( [-1e30;-1e10;-1e-5;-1e-20;0;1e-20;1e-5;1e10;1e30;NaN]*ones(1,numel(x)) ) ,...
           'xdata' , vec( [    1;    1;    1;     1;1;    1;   1;   1;   1;  1]* x(:).'          ) );

  if STACK_AT_BOTTOM
    ch = get( get(h,'Parent') , 'Children' );
    ch = ch(:);
    ch = [ h ; setdiff( ch , h ) ];
    set( get(h,'Parent') , 'Children' , ch );
  end
  
  if nargout > 0
    h_ = h;
  end
         
end
