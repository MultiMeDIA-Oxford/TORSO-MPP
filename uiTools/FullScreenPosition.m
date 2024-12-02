function p = FullScreenPosition()

  persistent FSpos

  if isempty(FSpos)
    h = figure('Visible','off');
    CLEAN = onCleanup( @()delete(h) );

    if 1
      set( h , 'Units','normalized','OuterPosition',[0 0 1 1]);
      set( h , 'Visible','on'); drawnow();
    else
      set( h , 'Visible','on'); drawnow(); % Required to avoid Java errors
      j = get( handle(h), 'JavaFrame');
      j.setMaximized(true); pause(0.001);
    end  

    set( h , 'Visible','off'); drawnow();

    set( h , 'Units','pixels' );
    FSpos = get( h , 'Position' );

    delete(CLEAN); drawnow();
  end
  
  p = FSpos;

end
