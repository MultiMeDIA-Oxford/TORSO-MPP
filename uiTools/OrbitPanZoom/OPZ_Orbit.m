function OPZ_Orbit( h , aa )
  if nargin<2 || isempty(aa)
    aa= ancestortool( hittest , 'axes' );
  end
  
  if aa && is3daxes(aa)
%     set(aa,'XColor',[.65 0 0],'YColor',[0 .65 0],'ZColor',[0 0 .65] );
%       'DataAspectRatio',[1 1 1]);
%     axis(aa,'e qual');

    STORED_STATE = setACTIONS( h , 'save' );

    oldUNITS= get(h,'Units');
    set( h , 'Units' , 'pixels' );  

    set(h,'KeyPressFcn',';');
    set(h,'WindowButtonMotionFcn',@(h,e) ORBIT    );
    set(h,'WindowButtonUpFcn'    ,@(h,e) STOP_ORBIT );

    Ctarget = get(aa,'cameratarget');
    FigurePoint = get( h  ,'CurrentPoint');
  end

  function ORBIT
     newFPoint= get(h,'CurrentPoint');

    D= (newFPoint-FigurePoint)/100; 
    
    pos     = get(aa,'CameraPosition');
    up      = get(aa,'CameraUpVector');
    camera  = pos-Ctarget;
    vec       = cross(camera,up );
    vec       = vec/norm(vec);
    CUV       = [camera;up  ;vec]*R([0 0 1],D(1));
    CUV       = CUV*R(CUV(3,:),D(2));

    set(aa,'CameraPosition', CUV(1,:)+Ctarget );
    set(aa,'CameraUpVector', CUV(2,:) );
    set(aa,'CameraTarget', Ctarget );

%     lights = findall(aa,'type','light','Style','local');
%     if ~isempty( lights )
%       set( lights(1) , 'Position', get(aa,'CameraPosition') );
%     end
    
    FigurePoint = newFPoint;
  end  

  function r= R(vec,ang)
    r= expm( ang*[     0  -vec(3)  vec(2) ;...
                   vec(3)      0  -vec(1) ;
                  -vec(2)  vec(1)      0  ] );
  end
  
  function STOP_ORBIT
    setACTIONS( h , 'restore' , STORED_STATE );
    try
      set(h,'Units',oldUNITS);
    end
    try
      delete(AnnotationAxes);
    end
    
  end

end
