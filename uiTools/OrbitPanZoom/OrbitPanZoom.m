function OrbitPanZoom( fH )

  if nargin < 1
    
    fH = findobj( 0 ,'type','figure' );
    for ff = 1:numel(fH)
      if  isequal( get( fH(ff) , 'CreateFcn' ) , 'ACTIONSsetted' )
        fH(ff) = -1;
      end
    end
    fH( fH == -1 ) = [];
    
  elseif ischar( fH ) && strcmpi( fH , 'gcf' )
    
    fH = gcf;

  elseif ischar( fH ) && strcmpi( fH , 'all' )
    
    fH = findall( 0 ,'type','figure');
  
  elseif ischar( fH ) && strcmpi( fH , 'always' )
    
    set( 0 , 'DefaultFigureCreateFcn' , @(h,e)OrbitPanZoom(h) );
    disp('By default the axes have OrbitPanZoom.');
    return;
  
  elseif ischar( fH ) && strcmpi( fH , 'never' )
    
    set( 0 , 'DefaultFigureCreateFcn' , 'factory' );
    return;

  end
  
  for ff = fH(:).'
    if ishandle( ff ) && strcmp( get(ff,'type') , 'figure' )
      setACTIONS( ff , OPZ_ACTIONS );
    end
  end

end
