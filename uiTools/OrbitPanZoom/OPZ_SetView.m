function OPZ_SetView( h , varargin )

  if strcmp( get(h,'Type') , 'axes' )
    aa = h;
  else
    aa = ancestortool( hittest , 'axes' );
  end
  
  if numel(varargin) > 1
    for i = 1:numel(varargin)
      OPZ_SetView( aa , varargin{i} );
    end
    return;
  else
    d = varargin{1};
  end
    
  if strcmpi(get(aa,'Type'),'root'), return; end
  
  switch lower(d)
    case 'x', set( aa , 'View',[90 0]);
      
    case 'y', set( aa , 'View',[0 0]);
      
    case 'z', set( aa , 'View',[0 90]);
      
    case '3d'
%       set(aa ,'XColor',[.65 0 0],'YColor',[0 .65 0],'ZColor',[0 0 .65]);
      set(aa , 'View',[-37.5 30]);
      
    case 'normal'
      set(aa, 'PlotBoxAspectRatioMode','auto' , ...
              'DataAspectRatioMode'   ,'auto' , ...
              'CameraViewAngleMode'   ,'auto' );
      
    case 'equal'
      set( aa , 'DataAspectRatio',[1 1 1] );
      
    case 'tight'
      limits = objbounds( aa );
      
      xl = tightLim( limits(1:2) , 'X' );
      yl = tightLim( limits(3:4) , 'Y' );
      zl = tightLim( limits(5:6) , 'Z' );
      
      set(aa,'XLim', xl );
      set(aa,'YLim', yl );
      set(aa,'ZLim', zl );
 
      if all( get(aa,'DataAspectRatio') == [1 1 1] )
        OPZ_SetView( aa , 'warptofill' );
      end
      
    case 'warptofill'
      if ~is3daxes(aa)
        pos = getposition( aa ,'Pixel' );
        pos = pos(3:4);
        
        [vi,h,v]= viewfrom( aa );
        hl= get( aa ,[h 'Lim']);
        vl= get( aa ,[v 'Lim']);
        D = [ diff(hl) diff(vl) ];
        center = [ mean(hl) mean(vl) ];
        D = pos*max( D./pos )/2;
        
        set( aa ,[h 'Lim'] , center(1)+[-1 1]*D(1)   ,...
          [v 'Lim'] , center(2)+[-1 1]*D(2)   );
      end
      
  end

  
  
  function L = tightLim( L , n )
    s = 1.1;
    if all( isfinite(L) ) && L(2) > L(1)
      if strcmp(get(aa,[n,'Scale']),'log')
        L = clamp( L , eps(0) , maxnum );
        L = exp( centerscale( log( L ) , s ) );
        L = clamp( L , eps(0) , maxnum );
      else
        L = centerscale( L , s );
      end
    else
      L = get(aa,[n,'Lim']);
    end
  end
  
end
