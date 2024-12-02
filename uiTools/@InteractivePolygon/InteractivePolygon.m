function IP = InteractivePolygon( varargin )
% I=zeros(200,250);
% im= imagesc(I);
% xy= ndmat( 1:size(I,2) , 1:size(I,1) );
% fun  = @(IP) set(im,'CData', reshape( checkinside(IP,xy) , fliplr(size(get(im,'CData'))) )' );
% cons = @(xyz,varargin) min( max(xyz,[10 NaN 0]) , [NaN NaN 0] );
% 
% IP= InteractivePolygon( [10 10; 15 50; 40 40; 40 15] , 'fcn',fun,'constrain',cons );
% axis image
% 
%
% IP= InteractivePolygon( [0 0; 0.25 0.5; 1 1] , 'AV','function', 'AL','function' );
% IP.close  = 0;
% IP.spline = 0;
%
  
  [varargin,i,parent]= parseargs(varargin,'parent','$DEFS$',gca);
  IP.handle = hggroup( 'Parent', parent );
  IP = class( IP , 'InteractivePolygon' );
  
  [varargin,i,AV]= parseargs(varargin,'ActionsonVertices','actionsonvertice','$DEFS$','def');
  if ischar( AV )
    switch lower(AV)
      case {'def'}
AV        = struct('action',{},'FCN',{},'menu',{});
AV(end+1) = struct('action',{{'BUTTON30' 'LSHIFT'}},'FCN',@(IP,v) deleteVertice(IP,v)  ,'menu','Delete'  );
AV(end+1) = struct('action',{{'BUTTON1'          }},'FCN',@(IP,v) AV_move(IP,v)        ,'menu','_Move'   );
AV(end+1) = struct('action',{{'BUTTON1' 'LSHIFT' }},'FCN',@(IP,v) AV_deform(IP,v)      ,'menu','Deform'  );
AV(end+1) = struct('action',{{'BUTTON1' 'S'      }},'FCN',@(IP,v) AV_scale(IP,v)       ,'menu','Scale'   );
AV(end+1) = struct('action',{{'BUTTON1' 'R'      }},'FCN',@(IP,v) AV_rotate(IP,v)      ,'menu','Rotate'  );
AV(end+1) = struct('action',{{'kk'               }},'FCN',@(IP,v) AV_setcoordinates(IP,v) ,'menu','_Set'  );
AV(end+1) = struct('action',{{'BUTTON1' 'C'      }},'FCN',@(IP,v) AL_cut(IP,v)         ,'menu',''   );
      case {'function'}
AV        = struct('action',{},'FCN',{},'menu',{});
AV(end+1) = struct('action',{{'BUTTON30' 'LSHIFT'}},'FCN',@(IP,v) deleteVertice(IP,v)  ,'menu','Delete'  );
AV(end+1) = struct('action',{{'BUTTON1'          }},'FCN',@(IP,v) AV_moveAsFunction(IP,v) ,'menu','_Move'   );
AV(end+1) = struct('action',{{'kk'               }},'FCN',@(IP,v) AV_setcoordinates(IP,v) ,'menu','_Set'  );
    end
  end
  IPdata.AV = AV;

  [varargin,i,AL]= parseargs(varargin,'ActionsonLine','actionsonpolygon','$DEFS$','def');
  if ischar( AL )
    switch lower(AL)
      case {'def'}
AL        = struct('action',{},'FCN',{},'menu',{});
AL(end+1) = struct('action',{{'BUTTON10'         }},'FCN',@(IP) insertVertice(IP)  ,'menu','Insert'  );
AL(end+1) = struct('action',{{'BUTTON10' 'LSHIFT'}},'FCN',@(IP) insertVertice(IP)  ,'menu',''        );
AL(end+1) = struct('action',{{'BUTTON1'          }},'FCN',@(IP) AL_move(IP)        ,'menu','_Move'   );
AL(end+1) = struct('action',{{'BUTTON1' 'LSHIFT' }},'FCN',@(IP) AL_deform(IP)      ,'menu','Deform'  );
AL(end+1) = struct('action',{{'kk'               }},'FCN',@(IP) subsasgn(IP,substruct('.','spline'),~subsref(IP,substruct('.','spline'))) ...
                                                                                   ,'menu','_Spline-Line' );
AL(end+1) = struct('action',{{'kk'               }},'FCN',@(IP) subsasgn(IP,substruct('.','close' ),~subsref(IP,substruct('.','close' ))) ...
                                                                                   ,'menu','Open-Close' );
AL(end+1) = struct('action',{{'BUTTON30' 'LSHIFT'    }},'FCN', @(IP) resample( IP )    ,'menu','_Resample' );
AL(end+1) = struct('action',{{'BUTTON30' '2' 'LSHIFT'}},'FCN', @(IP) resample(IP,length(IP)*2) ,'menu','' );             % Resample*2
AL(end+1) = struct('action',{{'BUTTON30' '3' 'LSHIFT'}},'FCN', @(IP) resample(IP,length(IP)*3) ,'menu','' );             % Resample*3
AL(end+1) = struct('action',{{'BUTTON30' '2' 'LSHIFT' 'A'}},'FCN', @(IP) resample(IP,max(2,round(length(IP)/2))) ,'menu','' );  % Resample/2
AL(end+1) = struct('action',{{'BUTTON30' '3' 'LSHIFT' 'A'}},'FCN', @(IP) resample(IP,max(2,round(length(IP)/3))) ,'menu','' );  % Resample/3
AL(end+1) = struct('action',{{'BUTTON1' 'C'      }},'FCN',@(IP) AL_cut(IP)       ,'menu',''   );
      case {'function'}
AL        = struct('action',{},'FCN',{},'menu',{});
AL(end+1) = struct('action',{{'BUTTON10'         }},'FCN',@(IP) insertVertice(IP)  ,'menu','Insert'  );
AL(end+1) = struct('action',{{'BUTTON10' 'LSHIFT'}},'FCN',@(IP) insertVertice(IP)  ,'menu',''        );
AL(end+1) = struct('action',{{'BUTTON1'          }},'FCN',@(IP) AL_moveX(IP)       ,'menu',''   );
AL(end+1) = struct('action',{{'kk'               }},'FCN',@(IP) subsasgn(IP,substruct('.','spline'),~subsref(IP,substruct('.','spline'))) ,'menu','_Spline-Line' );
    end
  end
  IPdata.AL = AL;

  [varargin,i,fcn]= parseargs(varargin,'callback','fcn','$DEFS$',@(x) 1);
  IPdata.fcn       = fcn;

  [varargin,i,constrain]= parseargs(varargin,'constrain' );
  IPdata.constrain = constrain;
  
  [varargin,i,isclose]= parseargs(varargin,'isclose', '$DEFS$' ,1 );
  [varargin,  isclose]= parseargs(varargin,'CLOSEd' , '$FORCE$',{1,isclose} );
  [varargin,  isclose]= parseargs(varargin,'OPENed' , '$FORCE$',{0,isclose} );
  IPdata.close     = isclose;

  [varargin,i,isspline]= parseargs(varargin,'isspline','$DEFS$',0);
  [varargin,  isspline]= parseargs(varargin,'spline','curved','$FORCE$',{1,isspline});
  [varargin,  isspline]= parseargs(varargin,'line','polygon','straight' ,'$FORCE$',{0,isspline});
  IPdata.spline    = isspline;


  [varargin,i,ARROWS_SCALE]= parseargs(varargin,'arrows','$DEFS$',0);
  if numel( ARROWS_SCALE ) == 1, ARROWS_SCALE = ARROWS_SCALE*[1 1]; end

  
  [varargin,i,resamplear]= parseargs(varargin,'resample' );
  
  IPdata.vertices  = [];
  IPdata.line      = line('Parent',IP.handle,'XData',0,'YData',0,'ZData',0,'Marker','none','Linestyle','-','Color',[1 0 0] );
  IPdata.arrows(1,1) = hgtransform('Visible','off');  IPdata.arrows(1,2) = ARROWS_SCALE(1);
  IPdata.arrows(2,1) = hgtransform('Visible','off');  IPdata.arrows(2,2) = ARROWS_SCALE(2);
  
  setappdata( IP.handle , 'InteractivePolygon' , IPdata );
  
  patch('vertices',[0 0 0;-1 0.3 0;-1 -0.3 0],'faces',[1 2 3],'facecolor','k','edgecolor','k','parent',IPdata.arrows(1,1));
  patch('vertices',[0 0 0;-1 0.3 0;-1 -0.3 0],'faces',[1 2 3],'facecolor','k','edgecolor','k','parent',IPdata.arrows(2,1));

  if numel(varargin)<1
    vertices = [0 0 0; 1 0 0; 0 1 0];
  else
    vertices = varargin{1};
  end
  if size(vertices,2) < 3, vertices(:,3)=0; end
  setVertices( IP , vertices );

  curve= getCurve( IP );
  set(IPdata.line,'XData',curve(:,1),'YData',curve(:,2),'ZData',curve(:,3));
  updateArrows( IP , IPdata );
  ACTIONSonLINE( IP );

%   if ~isempty(resamplear)
%     resample(IP,resamplear);
%   end


end
