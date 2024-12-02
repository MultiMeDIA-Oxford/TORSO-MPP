function h = imagesc( I , varargin )

  BCOLOR = [];
  [varargin,~,BCOLOR] = parseargs(varargin,'BoundaryColor','BoundaryCOLOR','$DEFS$', BCOLOR );
  if isempty( BCOLOR ), BCOLOR = 'none'; end


  if size( I ,3) ~= 1
    error('imagesc can be used only on an I3D with a single slice');
  end

  xyz = ndmat( dualV( I.X ) , dualV( I.Y ) , I.Z );
  xyz = bsxfun( @plus , xyz * I.SpatialTransform( 1:3 , 1:3 ).' , I.SpatialTransform( 1:3 , 4 ).' );
  
  sz = [ numel( I.X )+1 , numel( I.Y )+1 , numel( I.Z ) ];
  
  
  h = surface( 'XData', reshape( xyz(:,1) ,sz) ,...
               'YData', reshape( xyz(:,2) ,sz) ,...
               'ZData', reshape( xyz(:,3) ,sz) ,...
               'CData', double( permute( I.data , [1 2 5 3 4] ) ) ,...
               'EdgeColor','none' ,...
               'FaceColor','flat' ,...
               'FaceLighting' , 'none' ,...
               varargin{:} );
%              'AmbientStrength', 1 ,...
%              'DiffuseStrength', 0 ,...
%     'SpecularColorReflectance', 1 ,...
%             'SpecularExponent', 1 ,...
%             'SpecularStrength', 0 ,...
             
             
  if ~strcmp( BCOLOR , 'none' )
    xyz = ndmat( range( dualV( I.X ) ) , range( dualV( I.Y ) ) , I.Z );
    xyz = bsxfun( @plus , xyz * I.SpatialTransform( 1:3 , 1:3 ).' , I.SpatialTransform( 1:3 , 4 ).' );

    h(2,1) = surface( 'XData', reshape( xyz(:,1) ,[2 2]) ,...
                   'YData', reshape( xyz(:,2) ,[2 2]) ,...
                   'ZData', reshape( xyz(:,3) ,[2 2]) ,...
                   'EdgeColor', BCOLOR ,...
                   'FaceColor','none' );    
  end
             
             
  return;

  if     size(I,1) == 1
    I  = permute( I , [3 2 1] );
  elseif size(I,2) == 1
    I  = permute( I , [3 1 2] );
  end

  IM = I.data(:,:,1,1,1);
  
  IC = ImageContainer( IM , 'IT' , I.ImageTransform );
  
  IC.hgs.K = eEntry( 'Parent', IC.hgs.ToolsPanel   ,...
                     'ReturnFcn',@(x) round(x)               ,...
                     'slider2edit',@(x) sprintf('k: %d',round(x) )   ,...
                     'Range',[1 size(I,3)],'IValue',1               ,...
                     'Step' , 1                              ,...
                     'callback',@(x) Update     );
                   
  set( IC.hgs.K.panel ,'Position',[ 10 200 130 20] );
  set( IC.hgs.K.edit  ,'Position',[  1   1  47 16] );
  set( IC.hgs.K.slider,'Position',[ 48   1  80 16] );


  IC.hgs.T = eEntry( 'Parent', IC.hgs.ToolsPanel   ,...
                     'ReturnFcn',@(x) round(x)               ,...
                     'slider2edit',@(x) sprintf('t: %d',round(x))   ,...
                     'Range',[1 size(I,4)],'IValue',1               ,...
                     'Step' , 1                              ,...
                     'callback',@(x) Update     );
  set( IC.hgs.T.panel ,'Position',[ 10 180 130 20] );
  set( IC.hgs.T.edit  ,'Position',[  1   1  47 16] );
  set( IC.hgs.T.slider,'Position',[ 48   1  80 16] );

  
  IC.hgs.C = eEntry( 'Parent', IC.hgs.ToolsPanel   ,...
                     'ReturnFcn',@(x) round(x)               ,...
                     'slider2edit',@(x) sprintf('c: %d',round(x))   ,...
                     'Range',[1 size(I,5)],'IValue',1               ,...
                     'Step' , 1                              ,...
                     'callback',@(x) Update     );
  set( IC.hgs.C.panel ,'Position',[ 10 160 130 20] );
  set( IC.hgs.C.edit  ,'Position',[  1   1  47 16] );
  set( IC.hgs.C.slider,'Position',[ 48   1  80 16] );
  
  
  if size(I,3) > 1
    IC.hgs.K.v = round( size(I,3)/2 );
  else
    IC.hgs.K.v = 1;
  end

%   IC.hgs.K.continuous  = 1;
%   IC.hgs.T.continuous  = 1;
%   IC.hgs.C.continuous  = 1;
  

  IC.K = @K;
  function o=K(x)
    if nargin<1
      o= IC.hgs.K.v;
      return;
    end
    if ischar(x)
      if x == '+'
        if IC.hgs.K.v == size(I,3)
          IC.hgs.K.v = 1;
        else
          IC.hgs.K.v = IC.hgs.K.v + 1;
        end
      end
      if x == '-'
        if IC.hgs.K.v == 1
          IC.hgs.K.v = size(I,3);
        else
          IC.hgs.K.v = IC.hgs.K.v - 1;
        end
      end
    elseif isscalar(x)
      IC.hgs.K.v = x;
    else
      disp('error..??..');
    end
  end
  
  IC.T = @T;
  function o=T(x)
    if nargin<1
      o= IC.hgs.T.v;
      return;
    end
    if ischar(x)
      if x == '+'
        if IC.hgs.T.v == size(I,4)
          IC.hgs.T.v = 1;
        else
          IC.hgs.T.v = IC.hgs.T.v + 1;
        end
      end
      if x == '-'
        if IC.hgs.T.v == 1
          IC.hgs.T.v = size(I,4);
        else
          IC.hgs.T.v = IC.hgs.T.v - 1;
        end
      end
    elseif isscalar(x)
      IC.hgs.T.v = x;
    else
      disp('error..??..');
    end
  end
  
  function Update
    xlim = get(IC.hgs.HistogramAxes,'xlim');
    IC.Image( I.data(:,:,IC.hgs.K.v,IC.hgs.T.v,IC.hgs.C.v) , 0 );
    set(IC.hgs.HistogramAxes,'xlim',xlim);
  end



ACTIONS= struct('action',{},'FCN',{} );
ACTIONS(end+1)= struct('action',{{ 'MOUSEWHEEL-UP'   }},'FCN',  @(h,e) K('+') );
ACTIONS(end+1)= struct('action',{{ 'MOUSEWHEEL-DOWN' }},'FCN',  @(h,e) K('-') );
ACTIONS(end+1)= struct('action',{{ 'PRESS-UP'        }},'FCN',  @(h,e) K('+') );
ACTIONS(end+1)= struct('action',{{ 'PRESS-DOWN'      }},'FCN',  @(h,e) K('-') );
ACTIONS(end+1)= struct('action',{{ 'PRESS-RIGHT'     }},'FCN',  @(h,e) T('+') );
ACTIONS(end+1)= struct('action',{{ 'PRESS-LEFT'      }},'FCN',  @(h,e) T('-') );
setACTIONS( IC.hgs.Fig , ACTIONS )

end
function y = dualV(x)
    try
        y = dualVector( x );
    catch
        x = x(:);
        y =  [  x(1) - ( x(2) - x(1) )/2 ;  ( x(1:end-1) + x(2:end) )/2 ; x(end) + ( x(end) - x(end-1) )/2 ];
        y = y.';
    end
end
