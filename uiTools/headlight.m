function h_ = headlight()

  h = camlight('headlight');
  if nargout > 0, h_ = h; end

  matlabV = sscanf(version,'%d.%d.%d.%d.%d',5); matlabV=[100,1,1e-2,1e-9,1e-13]*[ matlabV(1:min(5,end)) ; zeros(5-numel(matlabV),1) ];
  if matlabV <= 804, newListener = @(hh,prop,fcn)handle.listener(    hh , prop , 'PropertyPostSet' , fcn );
  else,              newListener = @(hh,prop,fcn)event.proplistener( hh , prop , 'PostSet'         , fcn );
  end

  LISTENERS = {};
  ha = ancestor(h,'axes');
  ha = handle( ha );

  LISTENERS{end+1} = newListener( ha , findprop( ha , 'View' )           , @(hh,e)set( h , 'Position' , get( ha , 'CameraPosition' ) ) );
  LISTENERS{end+1} = newListener( ha , findprop( ha , 'CameraPosition' ) , @(hh,e)set( h , 'Position' , get( ha , 'CameraPosition' ) ) );
%   LISTENERS{end+1} = newListener( ha , findprop( ha , 'CameraTarget' )   , @(hh,e)set( h , 'Position' , get( ha , 'CameraPosition' ) ) );
%   LISTENERS{end+1} = newListener( ha , findprop( ha , 'Projection' )     , @(hh,e)set( h , 'Position' , get( ha , 'CameraPosition' ) ) );

  setappdata( h , 'HEADLIGHT' , LISTENERS );
    
end