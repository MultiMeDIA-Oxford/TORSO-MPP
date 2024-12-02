function eE = subsasgn(eE,s,in)
% 
% 

  ntypes= numel(s);
  if ntypes > 2, error('Invalid Access (at 1).'); end
  
  switch s(1).type
    case '.'
      switch s(1).subs
        case {'callback_fcn'}
          eE.callback_fcn = in;
          setappdata(eE.panel,'eEntry', eE );

          
        case {'continuous' }
          drawnow;
          js = handle2javaobject( eE.slider );
          if ~iscell( js )
            js = {js};
          end
          for i=1:numel(js)
            try
              jsi = handle( js{i} , 'callbackproperties');
              if in
                jsi.AdjustmentValueChangedCallback = get(eE.slider,'Callback');
                set(eE.slider,'Callback','');
                set( eE.slider ,'UserData', jsi );
              else
                jsi.AdjustmentValueChangedCallback = '';
              end
            end
          end
        case {'value','v','Value','V'}
          value =in;
          value= min( [ value , eE.range(2) ] );
          value= max( [ value , eE.range(1) ] );
    
          try
            set( eE.slider ,'Value' , value ); 
            set( eE.edit   ,'String', eE.slider2edit_fcn(value) );
          end
          if ~isempty( eE.callback_fcn )
            eE.callback_fcn( eE.return_fcn( value ));
          end
        case {'v_no_callback'}
          value =in;
          value= min( [ value , eE.range(2) ] );
          value= max( [ value , eE.range(1) ] );
    
          try
            set( eE.slider ,'Value' , value ); 
            set( eE.edit   ,'String', eE.slider2edit_fcn(value) );
          end
        case {'range_no_callback'}
          eE.range(:) = in(:);
          if eE.range(2) > eE.range(1)
            set( eE.slider , 'Min', eE.range(1) , 'Max', eE.range(2) , 'Enable' , 'on' );
          else
            set( eE.slider , 'Enable' , 'off' )
          end
        case {'range'}
          eE.range(:) = in(:);
          if eE.range(2) > eE.range(1)
            set( eE.slider , 'Min', eE.range(1) , 'Max', eE.range(2) , 'Enable' , 'on' );
          else
            set( eE.slider , 'Enable' , 'off' )
          end
          updateeEntry(eE);
        case 'step'
          if eE.range(2) > eE.range(1)
            set( eE.slider , 'SliderStep', [1 10]*in/( eE.range(2) - eE.range(1) ) , 'Enable' , 'on' );
          else
            set( eE.slider , 'Enable' , 'off' )
          end
          
      end
      
    otherwise
      error('Invalid Access.');
  end
end
