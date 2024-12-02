function v = getLinespec( v )

  % ADDED BY BEN( 05/03/2018)
  if isempty( v ), return; end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%

  if iscell( v )
    if ischar( v{1} )
      try
        out = getLinespec( v{1} );
        v(1) = [];
        v = [ out , v ];
      end
    end
    return;
  end


  Color           = [];
  LineStyle       = [];
  Marker          = [];
  LineWidth       = [];
  MarkerFaceColor = [];
  MarkerEdgeColor = [];
  MarkerSize      = [];
  FaceAlpha       = [];
  XLimInclude     = [];
  YLimInclude     = [];
  ZLimInclude     = [];

  v = regexprep( v , '[\s_]*$' , '' );
  while ~isempty( v )
    v = regexprep( v , '^[\s_]*' , '' );
    
    n = numel(v);

    tk = regexp( v ,'^([0-9]+\.[0-9]+|\.[0-9]+|[0-9]+)','tokens','once');
    if ~isempty(tk)
      setNumber(tk{1});
      v(1:numel(tk{1})) = [];
      continue; 
    end

    tk = regexp( v ,'^\[(\s*[0-9]+\.[0-9]+\s*|\s*\.[0-9]+|\.[0-9]+|[0-9]+\s*)\]','tokens','once');
    if ~isempty(tk)
      setFaceAlpha(tk{1});
      v(1:numel(tk{1})+2) = [];
      continue; 
    end

    tk = regexp( v ,'^gray(\d+)','tokens','once');
    if ~isempty( tk )
      v(1:numel(tk{1})+4) = [];
      setColor( [1,1,1]*str2double(tk{1})/10^numel(tk{1}) );
      continue;
    end

    if isv('xinf'), 	    setLimInclude('x'); continue; end
    if isv('yinf'), 	    setLimInclude('y'); continue; end
    if isv('zinf'), 	    setLimInclude('z'); continue; end
    if isv('inf'), 	      setLimInclude('');  continue; end

    if isv('r'),          setColor('r'); continue; end
    if isv('red'),        setColor('r'); continue; end
    if isv('g'),          setColor('g'); continue; end
    if isv('green'),      setColor('g'); continue; end
    if isv('b'),          setColor('b'); continue; end
    if isv('blue'),       setColor('b'); continue; end
    if isv('c'),          setColor('c'); continue; end
    if isv('cyan'),       setColor('c'); continue; end
    if isv('m'),          setColor('m'); continue; end
    if isv('magenta'),    setColor('m'); continue; end
    if isv('y'),          setColor('y'); continue; end
    if isv('yellow'),     setColor('y'); continue; end
    if isv('k'),          setColor('k'); continue; end
    if isv('black'),      setColor('k'); continue; end
    if isv('w'),          setColor('w'); continue; end
    if isv('white'),      setColor('w'); continue; end

    if isv('orange'),     setColor([1,0.5,0]); continue; end
    
    %if isv('none'),       setLineStyle('none'); continue; end
    if isv('--'),         setLineStyle('--'); continue; end
    if isv('-.'),	        setLineStyle('-.'); continue; end
    if isv('-'), 	        setLineStyle('-'); continue; end
    if isv(':'), 	        setLineStyle(':'); continue; end

    if isv('+'),          setMarker('+'); continue; end
    if isv('o'),          setMarker('o'); continue; end
    if isv('*'),          setMarker('*'); continue; end
    if isv('.'),          setMarker('.'); continue; end
    if isv('x'),          setMarker('x'); continue; end
    if isv('square'),     setMarker('s'); continue; end
    if isv('s'),          setMarker('s'); continue; end
    if isv('diamond'),    setMarker('d'); continue; end
    if isv('d'),          setMarker('d'); continue; end
    if isv('^'),          setMarker('^'); continue; end
    if isv('v'),          setMarker('v'); continue; end
    if isv('>'),          setMarker('>'); continue; end
    if isv('<'),          setMarker('<'); continue; end
    if isv('hexagram'),   setMarker('h'); continue; end
    if isv('h'),          setMarker('h'); continue; end
    if isv('pentagram'),  setMarker('p'); continue; end
    if isv('p'),          setMarker('p'); continue; end


%     if numel(v) && v(1) == ' ', v(1) = []; end
%     if numel(v) && v(1) == '_', v(1) = []; end
    if n == numel(v), error('stucked'); end
  end
  
  function setLimInclude( c )
    if isempty( c )
      setLimInclude( 'x' );
      setLimInclude( 'y' );
      setLimInclude( 'z' );
      return;
    end
    switch lower( c )
      case 'x'
        if isempty( XLimInclude )
          XLimInclude = 'off';
        else, error('Too many XLimInclude assignations.');
        end
      case 'y'
        if isempty( YLimInclude )
          YLimInclude = 'off';
        else, error('Too many YLimInclude assignations.');
        end
      case 'z'
        if isempty( ZLimInclude )
          ZLimInclude = 'off';
        else, error('Too many ZLimInclude assignations.');
        end
    end    
  end
  
  function setColor(str)
    if isempty( Color )
      Color = str;
    elseif isempty( MarkerFaceColor )
      MarkerFaceColor = str;
    elseif isempty( MarkerEdgeColor )
      MarkerEdgeColor = str;
    else, error('Too many Color assignments.');
    end
  end
  function setMarker(str)
    if isempty( Marker )
      Marker = str;
    else, error('Too many Marker assignments.');
    end
  end
  function setLineStyle(str)
    if isempty( LineStyle )
      LineStyle = str;
    else, error('Too many LineStyle assignments.');
    end
  end
  function setFaceAlpha(str)
    if isempty( FaceAlpha )
      FaceAlpha = str2double(str);
    else, error('Too many FaceAlpha assignments.');
    end
  end
  function setNumber(str)
    if isempty( LineWidth )
      LineWidth = str2double(str);
    elseif isempty( MarkerSize)
      MarkerSize = str2double(str);
    elseif isempty( FaceAlpha )
      FaceAlpha = str2double(str);
    else, error('Too many Number assignments.');
    end
  end
  function o = isv( str )
    o = strncmpi( v , str , numel(str) );
    if o
      v(1:numel(str)) = [];
    end
  end

  if isempty( LineStyle ) && ~isempty( Marker )
    LineStyle = 'none';
  end

  out = {};
  if ~isempty( Color ), out = [ out , 'Color', Color ]; end
  if ~isempty( LineStyle ), out = [ out , 'LineStyle', LineStyle ]; end
  if ~isempty( Marker ), out = [ out , 'Marker', Marker ]; end
  if ~isempty( LineWidth ) & LineWidth , out = [ out , 'LineWidth', LineWidth ]; end
  if ~isempty( MarkerFaceColor ), out = [ out , 'MarkerFaceColor', MarkerFaceColor ]; end
  if ~isempty( MarkerEdgeColor ), out = [ out , 'MarkerEdgeColor', MarkerEdgeColor ]; end
  if ~isempty( MarkerSize ) & MarkerSize , out = [ out , 'MarkerSize', MarkerSize ]; end
  if ~isempty( FaceAlpha ), out = [ out , 'FaceAlpha', FaceAlpha ]; end
  if ~isempty( XLimInclude ), out = [ out , 'XLimInclude', XLimInclude ]; end
  if ~isempty( YLimInclude ), out = [ out , 'YLimInclude', YLimInclude ]; end
  if ~isempty( ZLimInclude ), out = [ out , 'ZLimInclude', ZLimInclude ]; end

  v = out;
  
  return;
  
  

  if ~iscell(v), v = {v}; end

  V_lstyle = ''; V_color = ''; V_marker = '';

  if numel(v) && ischar( v{1} )
    [V_lstyle,V_color,V_marker,msg] = colstyle( v{1} );
    if isempty( msg ), v(1) = []; end
  end
  if ~isempty(V_marker), v = [ 'Marker',    V_marker , v ]; end
  if ~isempty(V_lstyle), v = [ 'LineStyle', V_lstyle , v ]; end
  if ~isempty(V_color )
%     switch lower(V_color)
%       case 'r', V_color = [1 0 0];
%       case 'g', V_color = [0 1 0];
%     end
    
    v = [ 'Color',     V_color  , v ]; 
  end


end

