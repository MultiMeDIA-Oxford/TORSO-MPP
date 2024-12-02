function figurewindowstate( h , mode , varargin )
%
% figurewindowstate(h,mode): H is figure handle or a vector of figure handles
%                          modes:
%                                 'MAXimize' , 'MINimize' , 'Restore',
%                                 'Dock'     , 'UNDock'   , 'ToggleDock',
%                                 'OnTop'    , 'NotOnTop' , 'Toggleontop'
%

  switch nargin
    case 0
      h    = gcf;
      mode = 'Toggleontop';
    case 1
      if isstr(h)
        mode = h;
        h    = gcf;
      else
        mode = 'Toggleontop';
      end
  end

  while ~strcmpi( get(h,'Type'),'Figure' )
    h= get( h, 'Parent' );
  end


  switch lower(mode)
    case {'group','g'}
      name= get(h,'Name');
      if strcmp( name , '' );
        name= num2str(h);
      end
      j= get( handle(h) , 'JavaFrame' );
      j.setGroupName(['Group ' name ]);
      set( h, 'WindowStyle','docked' );
      
      for i=1:numel(varargin)
        j= get( handle(h) , 'JavaFrame' );
        j.setGroupName(['Group ' name ]);
        set( varargin{i}, 'WindowStyle','docked' );
      end
    
    case {'d','dock'}
      set( h , 'WindowStyle','dock')

    case {'und','undock'}
      set( h , 'WindowStyle','normal')

    case {'td','toggledock'}
      actual= get(h,'WindowStyle');
      switch actual
        case 'docked'
          set( h , 'WindowStyle','normal')
        case 'normal'
          set( h , 'WindowStyle','dock')
      end

    case {'ontop','ot'}
      

warnStruct=warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
jFrame = get(handle(h),'JavaFrame');
warning(warnStruct.state,'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');

jFrame_fHGxClient = jFrame.fHG1Client;
jFrame_fHGxClient.getWindow.setAlwaysOnTop(true);
      
      
%       if ~strcmp( get(gcf,'WindowStyle'),'docked')
%         w= get_w(h);
%         set(w,'AlwaysOnTop','on');
%       end

    case {'notontop','not'}
      if ~strcmp( get(gcf,'WindowStyle'),'docked')
        w= get_w(h);
        set(w,'AlwaysOnTop','off');
      end

    case {'toggleontop','t'}
      if ~strcmp( get(gcf,'WindowStyle'),'docked')
        w= get_w(h);
        actual= get(w,'AlwaysOnTop');
        switch actual
          case 'on'
            set(w,'AlwaysOnTop','off');
          case 'off'
              set(w,'AlwaysOnTop','on');
        end
      end

    case {'maximize','max'}
      if ~strcmp( get(gcf,'WindowStyle'),'docked')
        w= get_w(h);
        set( w, 'Maximized','on' );
      end

    case {'minimize','min'}
      if ~strcmp( get(gcf,'WindowStyle'),'docked')
        w= get_w(h);
        set( w, 'Minimized','on' );
      end      
    case {'restore','r'}
      if ~strcmp( get(gcf,'WindowStyle'),'docked')
        w= get_w(h);
        set( w, 'Maximized','off' );
      end
  end

  
  function w= get_w(h)  
    if ~usejava('jvm')
      error('setWindowOnTop requires Java to run.');
    end
    j = get( handle(h) , 'JavaFrame' );
    
    vers = ver('MATLAB');
    vers = vers.Version;
    vers = vers(3:end);
    vers = str2double( vers );
    if vers > 5
    	w= j.fFigureClient.getWindow;
    else
    	w = j.fClientProxy.getFrameProxy.getClientFrame;
 		end
  end

end
  
