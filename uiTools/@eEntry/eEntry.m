function eE = eEntry( varargin )
%   eEntry( 'PARENT' , gcf
%           'RANGE'  , [0  1]
%           'STEP'   , 1
%           'POSITION', [10 10 0 26]
%           'IVALUE', mean(range) (initial value)
% 
%           'ReturnFcn', @(x) x
%                   (a function to compute the value)
%           'CallBack', []  
%                   (the function called every time the value change)
%                   (it function get the ReturnFcn value)
%           'slider2edit', @(x) sprintf('%g',x)
%                   (from slider 2 text_edit)
%           'edit2slider', @(s) string2number(s)
%                   (from text_edit 2 slider)
%                   (the callback is called at return events or
%                       up-down arrows)
% 
%   Example;
%       E= E= eEntry('Parent',gcf,'Callback',@(x) disp(x) );
%       set(E.panel ,'Position',[20 20 50 18]);
%       set(E.edit  ,'Position',[1  1  38 16]);
%       set(E.panel ,'Position',[39 1  10 16]);
% 
% 

  [varargin,i,eE.range      ] = parseargs( varargin,'range'    ,'$DEFS$',[0 1] );
  [varargin,i,step          ] = parseargs( varargin,'step'     ,'$DEFS$',1 );
  [varargin,i,parent        ] = parseargs( varargin,'parent'   ,'$DEFS$',gcf);
  [varargin,i,position      ] = parseargs( varargin,'position' ,'$DEFS$',[10 10 1 26]);
  [varargin,i,initial_value ] = parseargs( varargin,'ivalue'   ,'$DEFS$',(eE.range(1)+eE.range(2))/2 );
  [varargin,i,tooltipstring ] = parseargs( varargin,'tooltipstring','$DEFS$','' );

  [varargin,i,tamanio       ] = parseargs( varargin,'size'   ,'$DEFS$','normal' );
  [varargin,tamanio       ] = parseargs( varargin,'normal' ,'$FORCE$',{'normal',tamanio} );
  [varargin,tamanio       ] = parseargs( varargin,'medium' ,'$FORCE$',{'medium',tamanio} );
  [varargin,tamanio       ] = parseargs( varargin,'large'  ,'$FORCE$',{'large',tamanio} );
  [varargin,tamanio       ] = parseargs( varargin,'small'  ,'$FORCE$',{'small',tamanio} );
  [varargin,tamanio       ] = parseargs( varargin,'tiny'   ,'$FORCE$',{'tiny',tamanio} );

  [varargin,i,eE.callback_fcn    ] = parseargs( varargin,'callback');  
  [varargin,i,eE.return_fcn      ] = parseargs( varargin,'returnfcn'   ,'$DEFS$',@(x) x );
  [varargin,i,eE.slider2edit_fcn ] = parseargs( varargin,'slider2edit' ,'$DEFS$',@(x) sprintf('%g',x) );
  [varargin,i,eE.edit2slider_fcn ] = parseargs( varargin,'edit2slider' ,'$DEFS$',@(s) string2number(s) );

  if numel( varargin ) > 0
    fprintf('Invalid entries: '); disp( varargin(:) );
  end
  
  switch tamanio
    case 'normal'
      position(3:4) = [227 26];
      panel_opts  = {'position', position };
      edit_opts   = {'position', [3 3 120 20]};
      slider_opts = {'position', [124 3 100 20]};
    case 'tiny'
      position(3:4) = [28 16];
      panel_opts  = {'position', position };
      edit_opts   = {'position', [ 1  1 17 13],'fontunits','pixels','fontsize',9};
      slider_opts = {'position', [18  1  8 12]};
    case 'small'
      position(3:4) = [38 20];
      panel_opts  = {'position', position };
      edit_opts   = {'position', [ 1  2 25 16],'fontunits','pixels','fontsize',9};
      slider_opts = {'position', [26  2 10 15]};
  end
  
  
  
  
  eE.panel  =   uipanel( 'Parent', parent  ,'Units', 'pixels',...
                         'BorderType','Beveledout' ,...
                         panel_opts{:} ...
                       );
                 
%                          'KeyPress' , @updateslider , ...
  eE.edit   = uicontrol( 'Style','edit', ...
                         'Parent', eE.panel, ...
                         'units', 'pixels',...
                         'string', eE.slider2edit_fcn( initial_value ) ,...
                         'ToolTipString', tooltipstring , ...
                         'HorizontalAlignment','center' ,...
                         edit_opts{:} ...
                       );

  eE.slider = uicontrol( 'Style','slider',...
                         'Parent', eE.panel, ...
                         'units', 'pixels',...
                         'ToolTipString', tooltipstring , ...
                         'Value', initial_value ,...
                         slider_opts{:} ...
                       );

  if eE.range(2)>eE.range(1)
    set( eE.slider , 'Min', eE.range(1) , ...
                     'Max', eE.range(2) , ...
                     'SliderStep', step*[1 10]/( eE.range(2) - eE.range(1) ) );
  else
    set( eE.slider , 'Min', -10000000 , ...
                     'Max', +10000000 , ...
                     'Visible', 'off' );
  end

  set(eE.slider,'CallBack', @(h,e) updateslider(eE) );
  set(eE.edit  ,'CallBack', @(h,e) updateedit(eE)   );
  
  eE= class( eE , 'eEntry' );
  setappdata(eE.panel,'eEntry', eE );

  function updateedit( eE )
    lostfocus( ancestortool( eE.panel ));
    eE = getappdata( eE.panel , 'eEntry');

    value = eE.edit2slider_fcn( get( eE.edit , 'String' ) );
    
    if value < eE.range(1), value= eE.range(1); end
    if value > eE.range(2), value= eE.range(2); end
    
    set( eE.slider , 'Value', value );
    set( eE.edit ,'String', eE.slider2edit_fcn(value) );

    if ~isempty( eE.callback_fcn ) && ~isempty( get(eE.slider,'Callback') )
      eE.callback_fcn( eE.return_fcn( value ) );
    end
  end

  function updateslider( eE )
    lostfocus( ancestor( eE.panel , 'figure' ));
    eE = getappdata( eE.panel , 'eEntry');

    value = get( eE.slider , 'Value' );
    
    set( eE.edit ,'String', eE.slider2edit_fcn(value) );

    if ~isempty( eE.callback_fcn )
      eE.callback_fcn( eE.return_fcn( value ) );
    end
  end    
    
%     
%     update= 0;
%     if isempty(e)
%       string = get( eE.edit,'String' );
%       value  = eE.edit2slider_fcn(string);
%       update = 1;
%     else
%       value = get( eE.slider,'Value' );
%       step  = get( eE.slider,'SliderStep' );
%       step  = step(1)*( eE.range(2)-eE.range(1) );
%       if      strcmp(e.Key,'uparrow')
%         value  = value + step;
%         update = 1;
%       elseif  strcmp(e.Key,'downarrow')
%         value  = value - step;
%         update = 1;
%       elseif  strcmp(e.Key,'pageup')
%         value  = value + 10*step;
%         update = 1;
%       elseif  strcmp(e.Key,'pagedown')
%         value  = value - 10*step;
%         update = 1;
%       end
%     end
% 
%     if update
%       value= min( [ value , eE.range(2) ] );
%       value= max( [ value , eE.range(1) ] );
%       set( eE.slider ,'Value', value );
%       set( eE.edit   ,'String', eE.slider2edit_fcn(value) );
%       if ~isempty( eE.callback_fcn )
%         eE.callback_fcn( eE.return_fcn( value ) );
%       end
%     end
  
%   end

end
