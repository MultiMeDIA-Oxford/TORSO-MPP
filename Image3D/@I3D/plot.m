function h_ = plot( I , varargin )

  if sum( size( I , 1:3 ) ~= 1 ) ~= 1
    error('only 1D images allowed');
  end
  if size( I , 1 ) == 1
    error('preferentemente la image debe estar en la primer dimension');
  end
  if prod( size(I,4:100) ) ~= 1
    I.data = I.data(:,:,:,1);
%     error('por ahora, solo para imagenes escalares');
  end
  
  switch I.SpatialInterpolation
    case 'nearest'
      xx = unique( [ I.X dualVector( I.X )] );
      xx = unique( [ xx + eps(xx) , xx - eps(xx) ] );
    case 'cubic'
      xx = unique( [ I.X   linspace( I.X(1) , I.X(end) , 1000 ) ] );
    otherwise
      xx = I.X;
  end
  b = max( I.BoundarySize , (I.X(end)-I.X(1))/min(5,numel(I.X)) )*1.2;
  xx = unique([ linspace( I.X(1) - b , I.X(end) + b , 1000 ) , xx ]);

  yy = Interp1D( I.data , I.X , xx ,I.SpatialInterpolation,I.BoundaryMode,I.BoundarySize,'outside_value',I.OutsideValue);
%   yy = Interp3DGridOn3DGrid( repmat( I.data , [1 3 3] ), I.X , [-1 0 1] , [-1 0 1] , xx , 0 , 0 , ...
%             I.SpatialInterpolation ,...
%             'outside_value',I.OutsideValue ,...
%             I.BoundaryMode , I.BoundarySize );

    
  hp = plot( xx , yy , varargin{:} ,'marker','none');
  if strcmp( get(hp,'linestyle') , 'none' ), set( hp , 'linestyle',':'); end
  h = hggroup('Parent',get(hp,'Parent'));
  set(hp,'Parent',h);
  

  line(I.X,I.data,'marker','o','markersize',3,'markerfacecolor',get(hp,'color'),'color',get(hp,'color'),'line','none','Parent',h);
  
  
  xx = dualVector( I.X );
  yy = Interp1D( I.data , I.X , xx ,I.SpatialInterpolation,I.BoundaryMode,I.BoundarySize,'outside_value',I.OutsideValue);
  
  line(xx,yy,'marker','o','markersize',2,'markerfacecolor',[.5 .5 .5],'color',[.3 .3 .3],'line','none','Parent',h);
  
  children = get(h,'children');
  set(h,'children',children([3 1 2]));
  
  
  if nargout > 0
    h_ = h;
  end
  
%   [varargin,isos]= parseargs(varargin,'labels','isosurfaces','ISOsurface' ,'$FORCE$',1 );
%   [varargin,mode]= parseargs(varargin,'flat','$FORCE$', 'flat' );
%   [varargin,mode]= parseargs(varargin,'interp','$FORCE$',{'interp','flat'});
% 
%   sz= size(I);
%   if sz(4)>1
%     if isos
%       h = plot( subsref(I,substruct('()',{':',':',':',1})) , mode , 'iso' );
%     else
%       h = plot( subsref(I,substruct('()',{':',':',':',1})) , mode );
%     end
%     return;
%   end
%   
%   if       sz(1)==1, idx={1 ':' ':'};
%   elseif   sz(2)==1, idx={':' 1 ':'};
%   elseif   sz(3)==1, idx={':' ':' 1};  
%   else
%     h(1)= plot( subsref(I,substruct('()',{round(sz(1)/2),':',':'} )) , mode );
%     X = eEntry( 'Range',[1 sz(1)], 'Step',1, 'IValue', round(sz(1)/2) , ...
%                 'Position' ,[0 52 227 26], 'ReturnFcn',@(x) round(x) , ...
%                 'callback' ,@(x) plot( subsref(I,substruct('()',{x,':',':'}) ) , h(1) , mode ) ) ;
%     X.continuous = 1;
%     
%     h(2)= plot( subsref(I,substruct('()',{':',round(sz(2)/2),':'} )) , mode );
%     Y = eEntry( 'Range',[1 sz(2)], 'Step',1, 'IValue', round(sz(2)/2) , ...
%                 'Position' ,[0 26 227 26], 'ReturnFcn',@(x) round(x) , ...
%                 'callback' ,@(x) plot( subsref(I,substruct('()',{':',x,':'}) ) , h(2) , mode ) ) ;
%     Y.continuous = 1;
% 
%     h(3)= plot( subsref(I,substruct('()',{':',':',round(sz(3)/2)} )) , mode );
%     Z = eEntry( 'Range',[1 sz(3)], 'Step',1, 'IValue', round(sz(3)/2) , ...
%                 'Position' ,[0 0 227 26], 'ReturnFcn',@(x) round(x) , ...
%                 'callback' ,@(x) plot( subsref(I,substruct('()',{':',':',x}) ) , h(3) , mode ) ) ;
%     Z.continuous = 1;
% 
%     if isos
%       for i=1:numel( I.LABELS_INFO )
%         if I.LABELS_INFO(i).state && any( I.LABELS(:) == i )
%           try
% %             fc= reducepatch( isosurface( I.X , I.Y , I.Z , permute( I.LABELS==i , [2 1 3] ), 0.5 ) , 0.10 );
%             fc= isosurface( I.X , I.Y , I.Z , permute( I.LABELS==i , [2 1 3] ), 0.5 );
%             fc.vertices= transform( fc.vertices , I.SpatialTransform , 'rows' );
%             h(3+i)= patch( 'Vertices',fc.vertices,'Faces',fc.faces,...
%                            'EdgeColor','none' ,...
%                            'FaceColor', I.LABELS_INFO(i).color ,...
%                            'FaceAlpha', I.LABELS_INFO(i).alpha ,...
%                            'Tag', I.LABELS_INFO(i).description );
%           catch
%             h(3+i)= -1;
%           end
%         else
%           h(3+i)= -2;
%         end
%       end
%     end
%               
%     ACTIONS= struct('action',{},'FCN',{} ); 
%     ACTIONS(end+1)= struct('action',{{ 'MOUSEWHEEL-UP'              }},'FCN', @(h,e) ChangeIndex(+1) );
%     ACTIONS(end+1)= struct('action',{{ 'MOUSEWHEEL-DOWN'            }},'FCN', @(h,e) ChangeIndex(-1) );
%     ACTIONS(end+1)= struct('action',{{ 'MOUSEWHEEL-UP'   'LCONTROL' }},'FCN', @(h,e) ChangeAlpha(+0.1) );
%     ACTIONS(end+1)= struct('action',{{ 'MOUSEWHEEL-DOWN' 'LCONTROL' }},'FCN', @(h,e) ChangeAlpha(-0.1) );
%     setACTIONS( gcf , ACTIONS );
%     
%     set(gca,'Color','none');
%     axis equal;
%     view(3);
%     colormap gray;
%     
%     return;
%   end
%   
%   if numel( varargin )
%     h= varargin{1};
%     if ~ishandle(h) || ~strcmp( get(h,'Type'),'surface')
%       error('h has to be a handle to a surface objects.');
%     end
%   else
%     h= surface('XData',1,'YData',1,'ZData',1,'CData',1,'FaceColor','flat','EdgeColor','none');
%   end
% 
%   switch lower(mode)
%     case 'flat'
%       set( h, 'XData', squeeze( subsref(I,substruct('.','DXX','()',idx)) ) ,...
%               'YData', squeeze( subsref(I,substruct('.','DYY','()',idx)) ) ,...
%               'ZData', squeeze( subsref(I,substruct('.','DZZ','()',idx)) ) ,...
%               'CData', double( squeeze( I.data ) )  );
%     case 'interp'
%       set( h, 'FaceColor','interp',...
%               'XData', squeeze( subsref(I,substruct('.','XX','()',idx)) ) ,...
%               'YData', squeeze( subsref(I,substruct('.','YY','()',idx)) ) ,...
%               'ZData', squeeze( subsref(I,substruct('.','ZZ','()',idx)) ) ,...
%               'CData', double( squeeze( I.data ) )  );
%   end
% 
%   
%   function ChangeIndex(v)
%     obj= hittest;
%     switch obj
%       case h(1)
%         if    v > 0, controlui(X.slider,'>');
%         else,        controlui(X.slider,'<');  end
%       case h(2)
%         if    v > 0, controlui(Y.slider,'>');
%         else,        controlui(Y.slider,'<');  end
%       case h(3)
%         if    v > 0, controlui(Z.slider,'>');
%         else,        controlui(Z.slider,'<');  end
%     end
%   end
%   function ChangeAlpha(v)
%     obj= hittest;
%     a  = get(obj,'FaceAlpha');
%     set(obj,'FaceAlpha', delimit(a+v,0,1) );
%   end
  
end
