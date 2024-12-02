function updateeEntry(eE)
  
%   set( eE.slider , 'Min', eE.range(1) , ...
%                    'Max', eE.range(2) );

  value= get( eE.slider,'Value'); valueorig= value;
  value= min( [ value , eE.range(2) ] );
  value= max( [ value , eE.range(1) ] );
  
  if valueorig ~= value
    set( eE.slider ,'Value', value );
    set( eE.edit   ,'String', eE.slider2edit_fcn(value) );
    if ~isempty( eE.callback_fcn )
      eE.callback_fcn( eE.return_fcn( value ) );
    end
  end
                 
  setappdata( eE.panel , 'eEntry', eE );
end
