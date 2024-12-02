function setVertices( IP , vertices , update )

  IPdata= getappdata(IP.handle ,'InteractivePolygon');

  n= size( vertices , 1 );
  for i=1:n
    if i>numel(IPdata.vertices)
      IPdata.vertices(i)= line('Parent',IP.handle,'XData',0,'YData',0,'ZData',0,'Marker','o','MarkerSize',7,'MarkerFaceColor',[0 1 1]);
      ACTIONSonVERTICES( IP , IPdata.vertices(i) );
    end
    try
      vertices(i,:) = IPdata.constrain( vertices(i,:) , IP , i );
    end
    
    set( IPdata.vertices(i) , 'XData' , vertices(i,1) );
    set( IPdata.vertices(i) , 'YData' , vertices(i,2) );
    set( IPdata.vertices(i) , 'ZData' , vertices(i,3) );
  end
  set( IPdata.vertices(1),'MarkerFaceColor',[1 0 0] );
  set( IPdata.vertices(2),'MarkerFaceColor',[0 1 0] );

  try
    delete( IPdata.vertices(n+1:end) );
    IPdata.vertices(n+1:end) = [];
  end
  
  setappdata(IP.handle,'InteractivePolygon',IPdata);
  
  if nargin > 2
    xyz= getCurve( IP );
    set( IPdata.line , 'XData',xyz(:,1),'YData',xyz(:,2),'ZData',xyz(:,3) );
    
    updateArrows( IP , IPdata );
    
    if strcmpi(update,'update')
      feval( IPdata.fcn , IP );
    end
  end
  
end
