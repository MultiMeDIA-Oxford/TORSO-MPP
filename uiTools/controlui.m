function o = controlui( h ,varargin )
% 
% Example:
%   a= uicontrol('Type','togglebutton','callback','disp([''value: '' get(a,''Value'')])');
% 


%     LISTBOX:
%       'top' : Select the top-most element.
%       'end' : Select the last element.
%       '+'   : Select the next element.
%       '-'   : Select the previous element.
%       '.'   : Select the current element.
%       N     : Select the N-th element. Can also be an array if multi
%               selection is permitted.
%
%     POPUPMENU:
%       'top' : Select the top-most element.
%       'end' : Select the last element.
%       '+'   : Select the next element.
%       '-'   : Select the previous element.
%       '.'   : Select the current element.
%       N     : Select the N-th element.


  type= get( h , 'Type' );
  
  if strcmpi( type,'uicontrol' )
    style= get(h,'Style');
    switch lower(style)
      case {'checkbox','togglebutton'}
        i= 1;
        while i<= numel(varargin)
          switch lower( varargin{i} )
            case 'on'        , set(h,'Value',1); call(h);
            case 'off'       , set(h,'Value',0); call(h);
            case  {'toggle','.'} , 
              if strcmp(get(h,'Enable'),'on')
                set(h,'Value', ~get(h,'Value')); call(h);
              end
            case 'hide'      , set(h,'Visible','off');
            case 'show'      , set(h,'Visible','on');
            case 'focus'     , uicontrol(h);
            case 'lostfocus' , lostfocus(h);
          end
          i=i+1;
        end
        o= get(h,'Value');
      case 'pushbutton'
        i= 1;
        while i<= numel(varargin)
          switch lower( varargin{i} )
            case {'push','call','.'}      ,if strcmp(get(h,'Enable'),'on'), call(h); end
            case 'hide'      , set(h,'Visible','off');
            case 'show'      , set(h,'Visible','on');
            case 'focus'     , uicontrol(h);
            case 'lostfocus' , lostfocus(h);
          end
          i=i+1;
        end
      case 'text'
        i= 1;
        while i<= numel(varargin)
          switch lower( varargin{i} )
            case 'hide'      , set(h,'Visible','off');
            case 'show'      , set(h,'Visible','on');
            case 'focus'     , uicontrol(h);
            case 'lostfocus' , lostfocus(h);
            case {'increasefont','incrf'}, set(h,'Fontsize',get(h,'Fontsize')+1);
            case {'decreasefont','decrf'}, set(h,'Fontsize',get(h,'Fontsize')-1);
            case 'bold'      , set(h,'FontWeight','bold');
            case 'light'     , set(h,'FontWeight','light');
            case 'normal'    , set(h,'FontWeight','normal');
            case 'demi'      , set(h,'FontWeight','demi');
          end
          i=i+1;
        end
      case 'slider'
        i= 1;
        while i<= numel(varargin)
          switch lower( varargin{i} )
            case 'range'     
              set(h,'Min',min(varargin{i+1}),'Max',max(varargin{i+1}));
              i= i+1;
            case 'step'
              range= get(h,'Max')-get(h,'Min');
              if numel(varargin{i+1})==1
                varargin{i+1}= [ varargin{i+1} varargin{i+1}*10 ];
              end
              set( h, 'SliderStep', varargin{i+1}/range );
              i= i+1;

            case '+'     
              range= get(h,'Max')-get(h,'Min');
              step= get(h,'Sliderstep');
              newvalue= get(h,'Value') + range*step(1);
              newvalue= max( newvalue, get(h,'Min') );
              newvalue= min( newvalue, get(h,'Max') );
              set(h,'Value',newvalue);
              call(h);
            case '++'     
              range= get(h,'Max')-get(h,'Min');
              step= get(h,'Sliderstep');
              newvalue= get(h,'Value') + range*step(2);
              newvalue= max( newvalue, get(h,'Min') );
              newvalue= min( newvalue, get(h,'Max') );
              set(h,'Value',newvalue);
              call(h);            
            case '-'     
              range= get(h,'Max')-get(h,'Min');
              step= get(h,'Sliderstep');
              newvalue= get(h,'Value') - range*step(1);
              newvalue= max( newvalue, get(h,'Min') );
              newvalue= min( newvalue, get(h,'Max') );
              set(h,'Value',newvalue);
              call(h);
            case '--'     
              range= get(h,'Max')-get(h,'Min');
              step= get(h,'Sliderstep');
              newvalue= get(h,'Value') - range*step(2);
              newvalue= max( newvalue, get(h,'Min') );
              newvalue= min( newvalue, get(h,'Max') );
              set(h,'Value',newvalue);
              call(h);            case {'value','v'}
              set(h,'Value',varargin{i+1} );
              call(h);
              i=i+1;
            case 'tomin'
              set(h,'Value',get(h,'Min') );
              call(h);
            case 'tomax'
              set(h,'Value',get(h,'Max') );
              call(h);
              
            case {'call','.'}      , call(h);
            case 'hide'      , set(h,'Visible','off');
            case 'show'      , set(h,'Visible','on');
            case 'focus'     , uicontrol(h);
            case 'lostfocus' , lostfocus(h);
          end
          i=i+1;
        end
        o= get(h,'Value');
      case 'edit'
        i= 1;
        while i<= numel(varargin)
          switch lower( varargin{i} )
            case 'hide'      , set(h,'Visible','off');
            case 'show'      , set(h,'Visible','on');
            case 'focus'     , uicontrol(h);
            case 'lostfocus' , lostfocus(h);
            case {'v','value'}
              set(h,'value',varargin{i+1});
              call(h);
              i=i+1;
          end
          i=i+1;
        end
        o= get(h,'Value');
        
    end
  elseif strcmpi(type,'uipanel')
    i=1;
    while i<= numel(varargin)
      switch lower( varargin{i} )
        case 'hide'      
          set(h,'Visible','off');
          set( findall(h,'Type','uicontrol'),'Visible','off');
        case 'show'      
          set(h,'Visible','on');
          set( findall(h,'Type','uicontrol'),'Visible','on');
      end
      i=i+1;
    end
  else
    error('Only for uicontrols and uipanels');
  end

  
  function call(h)
    fun= get(h,'Callback');
    if ischar(fun)
      evalin('base', fun );
    elseif isa( fun ,'function_handle' )
      feval( fun , h , [] );
    elseif isa( fun ,'cell' )
      feval( fun{1} , h , [] , fun{2:end} );
    end
  end
  
end
