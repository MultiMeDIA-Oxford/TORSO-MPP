function h_ = image( I , varargin )

  isRGB = false;
  
  sz = size( I.data );
  if numel( sz ) > 5
    error('tensor images not allowed');
  end
  if numel( sz ) == 5
    if sz(5) ~= 3  ||  max( I.data(:) ) > 1 || min( I.data(:) ) < 0
      error('in vectorial image case, only RGB images are allowed.');
    end
    sz(5) = [];
    isRGB = true;
  end
  if numel( sz ) == 4
    if sz(4) > 1
      error('multi time images not allowed');
    end
    sz(4) = [];
  end
  if numel( sz ) > 3 || sum( sz > 1 ) ~= 2,
    error('The input have to be only a slice.');
  end
  
  hAxe = newplot;
  
  
  [varargin,i,range] = parseargs(varargin,'range','$DEFS$',[0 1]);
  
  
  [varargin,as_nearest] = parseargs(varargin,'NEArest','flat','$FORCE$',true);
  [varargin,as_interp ] = parseargs(varargin,'interp','lineal','$FORCE$',true);
  
  mode = lower( I.SpatialInterpolation );
  if as_nearest, mode = 'nearest'; end
  if as_interp , mode = 'lineal';  end

  switch mode
    case 'nearest'

      switch sum( 2.^find( sz==1 ) )
        case {0,8}
          DX = dualVector( I.X );
          DY = dualVector( I.Y );
        case 2
          DX = dualVector( I.Y );
          DY = dualVector( I.Z );
        case 4
          DX = dualVector( I.X );
          DY = dualVector( I.Z );
      end
      [xx,yy] = ndgrid( DX , DY );

      if isRGB
        h = surface( 'Parent', hAxe , 'XData' , xx , 'YData' , yy , 'ZData', xx*0 , ...
          'CData', double( squeeze( I.data )) , ...
          'FaceColor' , 'flat' , 'edgecolor','none' , varargin{:});
      else
        h = surface( 'Parent', hAxe , 'XData' , xx , 'YData' , yy , 'ZData', xx*0 , ...
          'CData', ( double( squeeze( ApplyContrastFunction( I.data , I.ImageTransform ) ) )*diff(range) + range(1) ) , ...
          'FaceColor' , 'flat' , 'edgecolor','none' , varargin{:} );
      end

    otherwise

      switch sum( 2.^find( sz==1 ) )
        case {0,8}
          [xx,yy] = ndgrid( I.X , I.Y );
          DX = dualVector( I.X );
          DY = dualVector( I.Y );

        case 2
          [xx,yy] = ndgrid( I.Y , I.Z );
          DX = dualVector( I.Y );
          DY = dualVector( I.Z );

        case 4
          [xx,yy] = ndgrid( I.X , I.Z );
          DX = dualVector( I.X );
          DY = dualVector( I.Z );

      end

      if isRGB
        h = surface( 'Parent', hAxe , 'XData' , xx , 'YData' , yy , 'ZData', xx*0 , ...
          'CData', double( squeeze( I.data )) , ...
          'FaceColor' , 'interp' , 'edgecolor','none' , varargin{:});
      else
        h = surface( 'Parent', hAxe , 'XData' , xx , 'YData' , yy , 'ZData', xx*0 , ...
          'CData', ( double( squeeze( ApplyContrastFunction( I.data , I.ImageTransform ) ) )*diff(range) + range(1) ) , ...
          'FaceColor' , 'interp' , 'edgecolor','none' , varargin{:});
      end

  end

  

  lw = 1;
  
  OFFSET = - 0.1 * min( [ diff( DX(:) ) ; diff( DY(:) ) ] );
  L = squeeze( I.LABELS );
  for lab = unique( L(:) )'
    if lab == 0, continue; end

    c = boundary( L == lab , DX , DY , OFFSET );
    if size(c,2) > 1,
      line('Parent',hAxe ,'XData', c(1,:) , 'YData', c(2,:) , 'Color', I.LABELS_INFO(lab).color , 'linewidth' , lw );
    end
  end

  
  if ~ishold
    axis('equal');
  end

  if nargout
    h_ = h; 
  end

end
