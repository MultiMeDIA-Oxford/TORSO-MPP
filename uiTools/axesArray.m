function hs = axesArray( sz , varargin )

  DefAxPos = get(0,'defaultaxesposition');
  L = DefAxPos(1);
  B = DefAxPos(2);
  R = 1 - L - DefAxPos(3);
  T = 1 - B - DefAxPos(4);

  H = 0.05;
  V = 0.05;
  
  if numel(varargin) && ~ischar( varargin{1} )
    LRBTHV = varargin{1}; varargin(1) = [];
    LRBTHV(end+1:6) = LRBTHV(end);
    L = LRBTHV(1);
    R = LRBTHV(2);
    B = LRBTHV(3);
    T = LRBTHV(4);
    H = LRBTHV(5);
    V = LRBTHV(6);
  end
  
  
  [varargin,~,L] = parseargs(varargin , 'atLeft'   ,'left'   ,'$DEFS$',L );
  [varargin,~,R] = parseargs(varargin , 'atRight'  ,'right'  ,'$DEFS$',R );
  [varargin,~,B] = parseargs(varargin , 'atBottom' ,'bottom' ,'$DEFS$',B );
  [varargin,~,T] = parseargs(varargin , 'atTop'    ,'top'    ,'$DEFS$',T );
  
  [varargin,~,H] = parseargs(varargin , 'Horizontal' ,'horizontalseparation' ,'$DEFS$',H );
  [varargin,~,V] = parseargs(varargin , 'Vertical'   ,'verticalseparation'   ,'$DEFS$',V );
  
  UNITS = 'normal';
  [varargin,UNITS] = parseargs(varargin,'normal' ,'$FORCE$',{'normal',UNITS});
  [varargin,UNITS] = parseargs(varargin,'pixels' ,'$FORCE$',{'pixels',UNITS});
  
  if      strcmpi( UNITS , 'normal' );
    h = ( 1 - B - T - (sz(1)-1)*V )/sz(1);
    w = ( 1 - L - R - (sz(2)-1)*H )/sz(2);
  elseif  strcmpi( UNITS , 'pixels' )
    
    figpos = get( gcf , 'Position' );
    h = ( figpos(4) - B - T - ( sz(1)-1 )*V )/sz(1);
    w = ( figpos(3) - L - R - ( sz(2)-1 )*H )/sz(2);
    
  end

  hs = zeros( sz );
  for y = 1:sz(1)
    for x = 1:sz(2)
      hs(y,x) = axes('Units',UNITS,'Position', [ L + (x-1)*(w+H) , B + (sz(1)-y)*(h+V) , w , h ],varargin{:});
      if y ~= sz(1), set( hs(y,x) , 'xticklabel', '' ); end
      if x ~= 1    , set( hs(y,x) , 'yticklabel', '' ); end
    end
  end
  
end

