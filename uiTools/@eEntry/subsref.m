function o = subsref(eE,s)
% 
% 

  ntypes= numel(s);
  if ntypes > 2, error('Invalid Access (at 1).'); end
  
  switch s(1).type
    case '.'
      switch s(1).subs
        case {'value','v','Value','V'}
          try
            o = eE.return_fcn( get( eE.slider , 'Value' ) );
          catch
            o = 0;
          end
        case {'range'}
          o = eE.range;
        case 'slider'
          o = eE.slider;
        case 'edit'
          o = eE.edit;
        case 'panel'
          o = eE.panel;
        case 'step'
          step = get( eE.slider , 'SliderStep');
          o = step(1)*( eE.range(2) - eE.range(1) );

        case 'callback_fcn'
          o = eE.callback_fcn;

        case 'CallBack'
          value = get( eE.slider , 'value');
    
          if ~isempty( eE.callback_fcn )
            eE.callback_fcn( eE.return_fcn( value ));
          end

        case {'UP','DOWN','BIGUP','BIGDOWN'}
          step = get( eE.slider , 'SliderStep');
          step = step(1)*( eE.range(2) - eE.range(1) );
          
          switch s(1).subs
            case 'UP'
              
            case 'DOWN'
              step= -step;
            case 'BIGUP'
              step= 10*step;
            case 'BIGDOWN'
              step= -10*step;
          end
          
          value = get( eE.slider , 'Value' );
          value = value + step;

          value= min( [ value , eE.range(2) ] );
          value= max( [ value , eE.range(1) ] );
    
          set( eE.slider ,'Value' , value );
          set( eE.edit   ,'String', eE.slider2edit_fcn(value) );
          if ~isempty( eE.callback_fcn )
            eE.callback_fcn( eE.return_fcn( value ));
          end
         
      end
      
    otherwise
      error('Invalid Access.');
  end
end
