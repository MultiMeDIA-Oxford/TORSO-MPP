function addtext( eE , S , varargin )

    pos = get(eE.panel,'Position');

    t = uicontrol('Parent', eE.panel , 'units','pixels','style','text','horizontalAlignment','left',...
      'fontunits','pixels',...
      'fontsize', get( eE.edit , 'fontsize' ) ,...
      'Position',[2 3 1 pos(4)-7],'string',S,varargin{:} );
    ext = get( t , 'Extent' ); ext= ext(3)+1;
    
    pos = get(t,'Position');
    set( t , 'position',[pos(1) pos(2) pos(3)+ext pos(4)]);
    ext = get(t,'Position'); ext= ext(3)+1;
    
    pos = get(eE.panel , 'Position');
    set( eE.panel , 'Position',[pos(1) pos(2) pos(3)+ext+1 pos(4)]);
    pos = get(eE.edit , 'Position');
    set( eE.edit , 'Position',[pos(1)+ext pos(2) pos(3) pos(4)]);
    pos = get(eE.slider , 'Position');
    set( eE.slider , 'Position',[pos(1)+ext pos(2) pos(3) pos(4)]);
  
end
