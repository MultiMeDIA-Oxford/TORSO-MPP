function p= getposition( h , varargin )

  [varargin,units]= parseargs(varargin,'Pixels','pix','pixel' ,'$FORCE$',{'pixels'    ,0     } );
  [varargin,units]= parseargs(varargin,'Normalized','nor'     ,'$FORCE$',{'normalized',units } );
  
  [varargin,local]= parseargs(varargin,'local');
  
  if units
    for i=1:numel(h)
      oldU{i} = get(h(i),'Units');
      set(h(i),'Units',units);
    end
  end
  
  p= get( h ,'Position' );
  
  if units
    for i=1:numel(h)
      set(h(i),'Units',oldU{i});
    end
  end

  if ~local
    parent= get(h,'Parent');
    if ~strcmp( get(parent,'Type') , 'figure' )
      p(1:2) = p(1:2) + getposition( parent , 1:2 ,'pixels' );
    end
  end

  if numel(varargin)
    p = p( varargin{:} );
  end
  
end
