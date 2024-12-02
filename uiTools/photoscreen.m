function I = photoscreen( hFig , varargin )

% I = export_fig(hFig,'-nocrop');

% return;


  if nargin < 1, hFig = []; end
  if isempty( hFig ), hFig = gcf; end
  if ~ishandle( hFig ) || ~isequal( get(hFig,'Type') , 'figure' )
    error('no handle a figura');
  end
  
  [varargin,i,FILTER] = parseargs( varargin , 'Filter','$DEFS$', 0   );
  [varargin,  WHITE ] = parseargs( varargin , 'White','$FORCE$', {true,false} );
  [varargin,  noUI  ] = parseargs( varargin , 'noUI','$FORCE$', {true,false} );
  [varargin,  LSMOOTHING ] = parseargs( varargin , 'smoothing','$FORCE$', {true,false} );
  [varargin,  X2 ] = parseargs( varargin , 'x2','$FORCE$', {true,false} );
  

  FUNITS = get( hFig , 'Units' ); set( hFig , 'Units' , 'pixels' );
  FPOS = get( hFig , 'Position' );
  if X2
    set( hFig , 'Position' , [ FPOS(1:2) , FPOS(3:4) * 4 ] );
  end
  
  FC = get(hFig,'color');
  hWHITE = 0;
  if WHITE
    set(hFig,'color',[1 1 1]);
    hWHITE = axes( 'Parent',hFig,'Units','normalized','Position',[-1 -1 3 3],'Color',[1 1 1]);
    uistack( hWHITE , 'bottom' );
  end

  if noUI
    for u = [ vec( findall(hFig,'type','uicontrol') ).' , vec( findall(hFig,'type','uipanel') ).' ]
      set( u , 'position', get( u , 'position' ) - [2000 , 2000 , 0 , 0] );
    end
  end
  
  
%   try
%     j= get( handle(hFig) , 'JavaFrame' );
%     showWindow( j.fFigureClient.getWindow.getSpecifiedTitle.toCharArray );
%   catch, figure(hFig); pause(0.1);
%   end

  hs2smooth = [];
  if LSMOOTHING
    w = warning('off','MATLAB:hg:willberemoved');
    for h = findall( hFig )'
      try
        if strcmp( get( h , 'LineSmoothing' ) ,'off' )
          hs2smooth = [ hs2smooth ; h ];
        end
      end
    end
    %hs2smooth = findall( hFig , 'LineSmoothing','off' );
    warning(w);
  end
  set( hs2smooth , 'LineSmoothing' , 'on' );


  builtin('drawnow','expose'); builtin('drawnow','update'); pause(0.0001);
  
  patches = findall( hFig , 'Type' , 'patch' );
  for p = patches(:).'
    try, get( p , 'UpdateOutline' ); end
  end

  builtin( 'drawnow' , 'expose' );
  builtin( 'drawnow' , 'update' );
  builtin( 'pause'   ,  0.001   );
  
  
  I = [];
  if isempty(I), try
      [fname,CLEANER] = tmpname( 'photo_****.png','mkfile');
      export_fig( hFig , fname ,'-png','-nocrop');
      I = imread( fname );
  end; end
  if isempty(I), try, I = getframe( hFig ); I = I.cdata; end; end


  if ~isempty( hs2smooth )
    set( hs2smooth , 'LineSmoothing' , 'off' );
  end
  
  set(hFig,'color',FC);
  if ~isequal( hWHITE , 0 ), delete( hWHITE ); end
  if noUI
    for u = [ vec( findall(hFig,'type','uicontrol') ).' , vec( findall(hFig,'type','uipanel') ).' ]
      set( u , 'position', get( u , 'position' ) + [2000 , 2000 , 0 , 0] );
    end
  end


  set( hFig , 'Position' , FPOS    );
  set( hFig , 'Units'    , FUNITS  );
  
  
  
  I = double(I)/255;
  if FILTER
    FILTER = gaussianKernel( -10:10 , -10:10 , 'std' , FILTER );
    FILTER = FILTER / sum( FILTER(:) );
    FILTER = FILTER / sum( FILTER(:) );
    FILTER = FILTER / sum( FILTER(:) );
    
    I = imfilter( I , FILTER , 'same' , 'replicate' );
    I(I>1) = 1;
    I(I<0) = 0;
  end
  
  
end
