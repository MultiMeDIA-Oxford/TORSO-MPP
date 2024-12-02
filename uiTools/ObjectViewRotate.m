function ObjectViewRotate( hO )
if 0
%%
  close all
  h = surf(peaks);
  set( h , 'ButtonDownFcn' , @(h,e)ObjectViewRotate(h) );
%%
end

  mode = pressedkeys(3);
  if mode ~= 1 && mode ~= 4 && mode ~= 2, return; end


%   disp('clik');
  hAxe = ancestor( hO , 'axes' );
  hFig = ancestor( hAxe , 'figure' );
  
  FP = get( hFig , 'CurrentPoint' );
  
  
  oldSTATE = SuspendFigure( hFig , 'WindowKeyPressFcn' , @(h,e)0 , 'WindowButtonDownFcn' , @(h,e)0 , 'WindowButtonUpFcn' , @(h,e)STOP() );
  switch mode
    case 1
      originalCT = get( hAxe ,'cameratarget');
      set( hFig , 'WindowButtonMotionFcn' , @(h,e)ORBIT() );
    case 2
      set( hFig , 'WindowButtonMotionFcn' , @(h,e)PAN()  );
    case 4
      originalCV = get( hAxe , 'CameraView' );
      set( hFig , 'WindowButtonMotionFcn' , @(h,e)ZOOM()  );
  end
  
  
  function ORBIT()
    if ~pressedkeys(3), STOP; end
    nFP = get(hFig,'CurrentPoint');

    d = ( nFP - FP )/100; 
    
    Cup     = get(hAxe,'CameraUpVector');
    Cpos    = get(hAxe,'CameraPosition') - originalCT;
    u       = cross(Cpos,Cup );
    u       = u/sqrt( u(:).'*u(:) );
    CUV     = [ Cpos ; Cup ; u ] * rodrigues( [0 0 1] , d(1) );
    CUV     = CUV * rodrigues( CUV(3,:) , d(2) );

    set(hAxe,'CameraPosition', CUV(1,:) + originalCT );
    set(hAxe,'CameraUpVector', CUV(2,:) );
    %set(hAxe,'CameraTarget', originalCT );

    FP = nFP;
  end
  function ZOOM()
    if ~pressedkeys(3), STOP; end
%     disp('zooming');

    nFP = get( hFig ,'CurrentPoint');
    d   = nFP(2) - FP(2);
    set( hAxe , 'CameraView' , originalCV );

    camzoom( hAxe , exp(d/100) );
  end
  function PAN()
    if ~pressedkeys(3), STOP; end
%     disp('paning');
 
    nFP = get(hFig,'CurrentPoint');
    d = nFP - FP; 
    d = -d/20;
    campan( hAxe , d(1) , d(2) , 'camera' );
    FP = nFP;
  end
  function STOP()
%     disp('unclick');
    RestoreFigure( hFig , oldSTATE );
%     disp('done');
  end

end
function oldSTATE = SuspendFigure( h , varargin )
  oldSTATE.WindowButtonDownFcn    = get( h , 'WindowButtonDownFcn'   ); set( h , 'WindowButtonDownFcn'   , '' );
  oldSTATE.WindowScrollWheelFcn   = get( h , 'WindowScrollWheelFcn'  ); set( h , 'WindowScrollWheelFcn'  , '' );
  oldSTATE.WindowKeyReleaseFcn    = get( h , 'WindowKeyReleaseFcn'   ); set( h , 'WindowKeyReleaseFcn'   , '' );
  oldSTATE.WindowKeyPressFcn      = get( h , 'WindowKeyPressFcn'     ); set( h , 'WindowKeyPressFcn'     , '' );
  oldSTATE.WindowButtonMotionFcn  = get( h , 'WindowButtonMotionFcn' ); set( h , 'WindowButtonMotionFcn' , '' );
  oldSTATE.WindowButtonUpFcn      = get( h , 'WindowButtonUpFcn'     ); set( h , 'WindowButtonUpFcn'     , '' );

  for v = 1:2:numel(varargin)
    if 0
    else
      set( h , varargin{v} , varargin{v+1} );
    end
  end
end
function RestoreFigure( h , oldSTATE )
  set( h , 'WindowButtonMotionFcn' , oldSTATE.WindowButtonMotionFcn  );
  set( h , 'WindowKeyReleaseFcn'   , oldSTATE.WindowKeyReleaseFcn    );
  set( h , 'WindowKeyPressFcn'     , oldSTATE.WindowKeyPressFcn      );
  set( h , 'WindowButtonDownFcn'   , oldSTATE.WindowButtonDownFcn    );
  set( h , 'WindowButtonUpFcn'     , oldSTATE.WindowButtonUpFcn      );
  set( h , 'WindowScrollWheelFcn'  , oldSTATE.WindowScrollWheelFcn   );
end
