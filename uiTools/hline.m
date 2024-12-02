function h_ = hline( y , varargin )

  [varargin,STACK_AT_BOTTOM] = parseargs( varargin , 'bottom','$FORCE$',{true,false} );
  varargin = getLinespec( varargin );

  h = line(0,0,'xliminclude','off','yliminclude','on','color',0.7*[1 1 1],'linestyle','--',varargin{:});


  set( h , 'xdata' , vec( [-1e30;-1e10;-1e-5;-1e-20;0;1e-20;1e-5;1e10;1e30;NaN]*ones(1,numel(y)) ) ,...
           'ydata' , vec( [    1;    1;    1;     1;1;    1;   1;   1;   1;  1]* y(:).'          ) );

  if STACK_AT_BOTTOM
    ch = get( get(h,'Parent') , 'Children' );
    ch = ch(:);
    ch = [ setdiff( ch , h ) ; h ];
    set( get(h,'Parent') , 'Children' , ch );  end
         
  if nargout > 0
    h_ = h;
  end
         
end

