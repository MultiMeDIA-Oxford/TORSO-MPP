function v = get(eE , prop )

  switch lower(prop)
    case 'type'
      v = 'eentry';
    case 'string'
      v = get(eE.edit,'string');
    case 'value'
      v = eE.return_fcn( get( eE.slider , 'Value' ) );
    case 'text'
      v = get( findall(eE.panel,'style','text'),'string' );
      
  end
  
end
