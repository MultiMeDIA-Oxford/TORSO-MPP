function pk = pressedkeys( B , hFig )

  if nargin > 1
    if ~ishandle( hFig ) || ~strcmp( get( hFig , 'Type' ) , 'figure' )
      error('second argument should be a handle to a figure');
    end
    pk = pressedkeys( B );
    if strcmp( get( hFig , 'SelectionType' ) , 'open' )
      for k = 1:numel( pk )
        if strncmp( pk{k} , 'BUTTON' , 6 )
          pk{k} = [ pk{k} , '0' ];
        end
      end
    end
    return;
  end


  if nargin < 1, B = 0; end
  if strcmp( B , 'demo')
    hFig = figure('WindowKeyPressFcn',';');
    t0 = uicontrol( 'Style','text','Position',[20 300-0*45 500 30] ,'FontSize',17,'HorizontalAlignment','left');
    t1 = uicontrol( 'Style','text','Position',[20 300-1*45 500 30] ,'FontSize',17,'HorizontalAlignment','left');
    t2 = uicontrol( 'Style','text','Position',[20 300-2*45 500 30] ,'FontSize',17,'HorizontalAlignment','left');
    t3 = uicontrol( 'Style','text','Position',[20 300-3*45 500 30] ,'FontSize',17,'HorizontalAlignment','left');
    t4 = uicontrol( 'Style','text','Position',[20 300-4*45 500 30] ,'FontSize',17,'HorizontalAlignment','left');
    t5 = uicontrol( 'Style','text','Position',[20 300-5*45 500 30] ,'FontSize',17,'HorizontalAlignment','left');
    switch computer
      case {'PCWIN','PCWIN64'}, pk = @(i) uneval( pressedkeys_win(i) );
      case {'GLNXA64'}        , pk = @(i) uneval( pressedkeys_linux(i) );
    end
    while ishandle(hFig)
      set(t0,'String',[ '0: ' , pk(0) ]);
      set(t1,'String',[ '1: ' , pk(1) ]);
      set(t2,'String',[ '2: ' , pk(2) ]);
      set(t3,'String',[ '3: ' , pk(3) ]);
      set(t4,'String',[ '4: ' , pk(4) ]);
      set(t5,'String',[ '5: ' , pk(5) ]);
      drawnow;
    end 
    return
  end

  persistent COMP
  if isempty( COMP )  
    COMP = computer;
    if strcmp( getenv('ComputerName') , 'MARTINA' )
      COMP = 'MARTINA';
    elseif strcmp( getenv('ComputerName') , 'ENGS-24337' )
      COMP = 'ENGS-24337';
    elseif strcmp( getenv('ComputerName') , 'ENGS-25158' )
      COMP = 'ENGS-25158';
    elseif strcmp( getenv('ComputerName') , 'CLPC316' )
      COMP = 'CLPC316';
    end
  end
  if strcmp( B , 'kkkk' )
    COMP = 'kkkk';
  end
  
  switch COMP
    case {'PCWIN','PCWIN64'}
      pk = pressedkeys_win( B );
      pk( strcmp( pk , '_255' ) ) = [];
      pk( strcmp( pk , '_231' ) ) = [];
    case {'CLPC316'}
      pk = pressedkeys_win( B );
      pk( strncmp( pk , '_' , 1 ) ) = [];
        
    case {'MARTINA'}
      pk = pressedkeys_win( B );
      if B < 2
        pk( strncmp( pk , '_'      , 1 ) ) = [];
        pk( strncmp( pk , 'NUMPAD' , 1 ) ) = [];
        pk( builtin('cellfun','isempty',pk) ) = [];
      end
      
    case {'ENGS-25158'}
      pk = pressedkeys_win( B );
      if B < 2
        pk( strncmp( pk , '_'      , 1 ) ) = [];
        pk( strncmp( pk , 'NUMPAD' , 1 ) ) = [];
        pk( builtin('cellfun','isempty',pk) ) = [];
      end
      
    case {'ENGS-24337'}
      pk = pressedkeys_win( B );
      if B < 2
        pk( strncmp( pk , '_'      , 1 ) ) = [];
      end
      
    case {'GLNXA64'}
      pk = pressedkeys_linux( B );
      
    case {'MAC'}
      error('not working on MAC, try with ''pressedK'' instead.');
      
    otherwise
      error('unknown computer: ''%s''',COMP);
  end
  
end