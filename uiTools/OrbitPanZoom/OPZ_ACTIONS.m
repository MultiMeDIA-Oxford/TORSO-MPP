function ACTIONS= OPZ_ACTIONS
KEY= 'SPACE';

ACTIONS= struct('action',{},'FCN',{} ); 

ACTIONS(end+1)= struct('action',{{                         }},'FCN',  @(h,e) 1 );


% ACTIONS(end+1)= struct('action',{{ ['PRESS-'   KEY]        }},'FCN',  @(h,e) OPZ_PressKey(h,1) );
% ACTIONS(end+1)= struct('action',{{ ['RELEASE-' KEY]        }},'FCN',  @(h,e) OPZ_PressKey(h,0) );

ACTIONS(end+1)= struct('action',{{  KEY  , 'C'               }},'FCN',  @(h,e) OPZ_CurrentPosition(h) );
ACTIONS(end+1)= struct('action',{{  KEY  , 'PRESS-C'         }},'FCN',  @(h,e) OPZ_CurrentPosition(h) );


% ACTIONS(end+1)= struct('action',{{ 'PRESS-X'    KEY        }},'FCN',  @(h,e) OPZ_EditLimits(h,'X') );
% ACTIONS(end+1)= struct('action',{{ 'RELEASE-X'  KEY        }},'FCN',  @(h,e) OPZ_EditLimits(h,0)   );
% ACTIONS(end+1)= struct('action',{{ 'RELEASE-X'             }},'FCN',  @(h,e) OPZ_EditLimits(h,0)   );
% ACTIONS(end+1)= struct('action',{{ 'PRESS-Y'    KEY        }},'FCN',  @(h,e) OPZ_EditLimits(h,'Y') );
% ACTIONS(end+1)= struct('action',{{ 'RELEASE-Y'  KEY        }},'FCN',  @(h,e) OPZ_EditLimits(h,0)   );
% ACTIONS(end+1)= struct('action',{{ 'RELEASE-Y'             }},'FCN',  @(h,e) OPZ_EditLimits(h,0)   );
% ACTIONS(end+1)= struct('action',{{ 'PRESS-Z'    KEY        }},'FCN',  @(h,e) OPZ_EditLimits(h,'Z') );
% ACTIONS(end+1)= struct('action',{{ 'RELEASE-Z'  KEY        }},'FCN',  @(h,e) OPZ_EditLimits(h,0)   );
% ACTIONS(end+1)= struct('action',{{ 'RELEASE-Z'             }},'FCN',  @(h,e) OPZ_EditLimits(h,0)   );


ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-1'   KEY          }},'FCN', @(h,e) OPZ_Orbit(h) );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-3'   KEY 'W'      }},'FCN', @(h,e) OPZ_START_ZoomWindows(h) );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-2'   KEY          }},'FCN', @(h,e) OPZ_Pan(h) );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-3'   KEY          }},'FCN', @(h,e) OPZ_Zoom(h) );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-3' KEY 'LCONTROL' }},'FCN', @(h,e) OPZ_Zoom(h) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-UP'   KEY          }},'FCN', @(h,e) OPZ_WZoom(h,1/1.1) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-DOWN' KEY          }},'FCN', @(h,e) OPZ_WZoom(h, 1.1 ) );

ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-DOWN' KEY 'BUTTON1'}},'FCN', @(h,e) OPZ_Roll(  1 ) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-UP'   KEY 'BUTTON1'}},'FCN', @(h,e) OPZ_Roll( -1 ) );

ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-UP'   KEY 'X'      }},'FCN',  @(h,e) OPZ_WPan(h,'X', 0.05) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-DOWN' KEY 'X'      }},'FCN',  @(h,e) OPZ_WPan(h,'X',-0.05) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-UP'   KEY 'Y'      }},'FCN',  @(h,e) OPZ_WPan(h,'Y', 0.05) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-DOWN' KEY 'Y'      }},'FCN',  @(h,e) OPZ_WPan(h,'Y',-0.05) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-UP'   KEY 'Z'      }},'FCN',  @(h,e) OPZ_WPan(h,'Z', 0.05) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-DOWN' KEY 'Z'      }},'FCN',  @(h,e) OPZ_WPan(h,'Z',-0.05) );

ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-UP'   KEY 'X' 'LCONTROL'}},'FCN',  @(h,e) OPZ_WPan(h,'X', 0.20) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-DOWN' KEY 'X' 'LCONTROL'}},'FCN',  @(h,e) OPZ_WPan(h,'X',-0.20) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-UP'   KEY 'Y' 'LCONTROL'}},'FCN',  @(h,e) OPZ_WPan(h,'Y', 0.20) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-DOWN' KEY 'Y' 'LCONTROL'}},'FCN',  @(h,e) OPZ_WPan(h,'Y',-0.20) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-UP'   KEY 'Z' 'LCONTROL'}},'FCN',  @(h,e) OPZ_WPan(h,'Z', 0.20) );
ACTIONS(end+1)= struct('action',{{'MOUSEWHEEL-DOWN' KEY 'Z' 'LCONTROL'}},'FCN',  @(h,e) OPZ_WPan(h,'Z',-0.20) );

ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-10' KEY '3'       }},'FCN',  @(h,e) OPZ_SetView( h , '3D','TIGHT') );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-10' KEY 'Z'       }},'FCN',  @(h,e) OPZ_SetView( h , 'Z' ,'TIGHT') );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-10' KEY 'Y'       }},'FCN',  @(h,e) OPZ_SetView( h , 'Y' ,'TIGHT') );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-10' KEY 'X'       }},'FCN',  @(h,e) OPZ_SetView( h , 'X' ,'TIGHT') );

ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-10' KEY           }},'FCN',  @(h,e) OPZ_SetView(h,'NORMAL','TIGHT') );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-30' KEY           }},'FCN',  @(h,e) OPZ_SetView(h,'NORMAL','TIGHT') );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-10' KEY 'E'       }},'FCN',  @(h,e) OPZ_SetView(h,'EQUAL' ,'TIGHT') );
ACTIONS(end+1)= struct('action',{{'PRESSBUTTON-30' KEY 'E'       }},'FCN',  @(h,e) OPZ_SetView(h,'EQUAL' ,'TIGHT') );


ACTIONS(end+1)= struct('action',{{ 'PRESSBUTTON-1'   KEY 'S'  }},'FCN',  @(h,e) OPZ_Select    );
ACTIONS(end+1)= struct('action',{{ 'PRESSBUTTON-10'  KEY 'S'  }},'FCN',  @(h,e) OPZ_Select(1) );

ACTIONS(end+1)= struct('action',{{ 'PRESS-DELETE'  KEY        }},'FCN',  @(h,e) delete(findall(h,'Selected','on')) );
ACTIONS(end+1)= struct('action',{{ 'PRESSBUTTON-1' KEY   'M'  }},'FCN',  @(h,e) OPZ_MoveObjects(h) );


