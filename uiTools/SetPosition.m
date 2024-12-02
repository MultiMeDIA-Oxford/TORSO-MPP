function SetPosition( h , POS , fix )
  if nargin < 3, fix = false; end

  try
  oPOS = POS;
  if any( POS < 0 )
    hh = get( h , 'Parent' );
    hhOldUnits = get( hh , 'Units' );
    set( hh , 'Units' , 'pixels' );
    hhPosition = get( hh , 'Position' );
    set( hh , 'Units' , hhOldUnits );

    hhPosition = hhPosition([3 4 3 4]);
    
    POS( POS < 0 ) = hhPosition( POS < 0 ) + POS( POS < 0 );
  end
  POS = round( POS );
  hOldUnits = get( h , 'Units' );
  set( h , 'Units' , 'pixels' );
  set( h , 'Position' , POS );
  set( h , 'Units' , hOldUnits );
  end
  if fix
    matlabV = sscanf(version,'%d.%d.%d.%d.%d',5); matlabV=[100,1,1e-2,1e-9,1e-13]*[ matlabV(1:min(5,end)) ; zeros(5-numel(matlabV),1) ];
    if matlabV > 804
      setappdata( h , 'SetPosition_listener' , addlistener( get(h,'Parent') , 'SizeChanged' , @(hh,ee)SetPosition( h , oPOS , false ) ) );
    else
      setappdata( h , 'SetPosition_listener' , addlistener( get(h,'Parent') , 'Position' , 'PostSet' , @(hh,ee)SetPosition( h , oPOS , false ) ) );
    end
  end
end