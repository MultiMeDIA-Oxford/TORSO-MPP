function OPZ_Select( i )

  h = hittest;
  hFig = ancestortool(h,'figure');

  if ~strcmp( get(h,'Type') , 'figure' )

    if onoff(h,'Selected')
      set( h , 'Selected','off' );
    else
      set( h , 'Selected','on' , 'SelectionHighlight','on' );
    end
    
    BlinkUI( h , [] , 3 , 0.05 );
    set( hFig , 'CurrentObject' , h );
  end
  
  if nargin > 0
    inspect( h );
  end

end
