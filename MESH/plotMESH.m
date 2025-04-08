function hg_ = plotMESH( M , varargin )
%
% plotmesh( mesh , 'Text'
%                  'NumberPoints'
%                  'NumberElements'
%                  'PointData'     , data_values_on_points
%                  'TriangleData'  , data_values_on_triangles  ('FaceData')
%                  'LABELS'  , NamedLMKS (a cell)
%
%

  varargin = getLinespec( varargin );
  if iscell( M )
    hg(1) = plotMESH( M{1} , 'FaceColor',colorith(1) , varargin{:} );
    for m = 2:numel(M)
      if isempty( M{m} ), continue; end
      hg(m) = hplotMESH( M{m} , 'FaceColor',colorith(m) , varargin{:} );
    end
    
    cax = ancestor(hg(1),'axes');
    if ~ishold( cax )
      bounds = single( objbounds( hg ) );
      bounds(1) = bounds(1) - 1000*eps( bounds(1) );
      bounds(2) = bounds(2) + 1000*eps( bounds(2) );
      bounds(3) = bounds(3) - 1000*eps( bounds(3) );
      bounds(4) = bounds(4) + 1000*eps( bounds(4) );
      bounds(5) = bounds(5) - 1000*eps( bounds(5) );
      bounds(6) = bounds(6) + 1000*eps( bounds(6) );
      bounds = double( bounds );

      set( cax , 'XLim' , bounds(1:2) , 'YLim' , bounds(3:4) , 'ZLim' , bounds(5:6) );
    end
    for h = 1:numel(hg)
      try, get( hg , 'UpdateOutline' ); end
    end
    
  
  
    if nargout > 0, hg_ = hg; end
    return;
  end

  PATCHI = true;
  try
  [varargin,PATCHI] = parseargs(varargin,'patchi','$FORCE$',{true ,PATCHI});
  [varargin,PATCHI] = parseargs(varargin,'patch' ,'$FORCE$',{false,PATCHI});
  catch 
  end
  if ~isstruct( M ) && numel( varargin ) && isnumeric( varargin{1} )
    M = struct( 'xyz' , M , 'tri' , varargin{1} );
    varargin(1) = [];
  elseif ~isstruct( M )
    M = struct( 'xyz' , M , 'tri' , delaunayn( M ) );
  end

  if isfield( M , 'vertices' ), M.xyz = M.vertices; end
  if isfield( M , 'faces' ),    M.tri = M.faces;    end
  nsd = size( M ,2);
  M.xyz(:,end+1:3) = 0;

  defOPTS = { 'EdgeColor'       , [0 0 0] ,...
              'FaceAlpha'       , 1 ,...
              'FaceColor'       , [ 0.6 , 0.75 , 0.75 ] };

  if size( M.tri ,1) > 1000 && nsd > 2
    defOPTS = [ defOPTS , { 'EdgeColor' } , { 'none' } ];
  end

%   for f = fieldnames( M )
%     switch lower( f{1} )
%       case {'facecolor','color'}, defOPTS = [ defOPTS , 'FaceColor' , M.(f{1}) ];
%       case {'edgecolor'},         defOPTS = [ defOPTS , 'EdgeColor' , M.(f{1}) ];
%       case {'facealpha','alpha'}, defOPTS = [ defOPTS , 'FaceAlpha' , M.(f{1}) ];
% 
%     end
%   end
  
  %options included in the fields of M, such as M.color = 'r';
  mOPTS = {};
  for f = fieldnames( M ).'
    if any( strcmpi( f{1} , {'AmbientStrength';'BackFaceLighting';'Clipping';'DiffuseStrength';'EdgeAlpha';'EdgeColor';'EdgeLighting';'FaceAlpha';'FaceColor';'FaceLighting';'HandleVisibility';'HitTest';'Interruptible';'LineStyle';'LineWidth';'Marker';'MarkerEdgeColor';'MarkerFaceColor';'MarkerSize';'NormalMode';'SpecularColorReflectance';'SpecularExponent';'SpecularStrength';'UserData';'VertexNormals';'Visible';'EraseMode';'FaceOffsetBias';'FaceOffsetFactor';'LineSmoothing';'XLimInclude';'YLimInclude';'ZLimInclude'} ) )
      mOPTS = [ mOPTS , { lower( f{1} ) } , { M.(f{1}) } ];
    elseif strcmpi( f{1} , 'Color' )
      mOPTS = [ mOPTS , { 'FaceColor' } , { M.(f{1}) } ];
    end
  end


  if      size( M.tri , 2 ) == 2
    try
      EDGECOLOR = [0 0 0];
      [varargin,z,EDGECOLOR] = parseargs(varargin,'edgecolor','color','$DEFS$',EDGECOLOR);
      if z, varargin = [ varargin , { 'EdgeColor' } , { EDGECOLOR } ]; end
    end
  elseif  size( M.tri , 2 ) == 3
    try
      FACECOLOR = [ 0.6 , 0.75 , 0.75 ];
      [varargin,z,FACECOLOR] = parseargs(varargin,'facecolor','color','$DEFS$',FACECOLOR);
      if z, varargin = [ varargin , { 'FaceColor' } , { FACECOLOR } ]; end
    end
  end

  eIDS = [];
  try, [varargin,z, eIDS  ] = parseargs( varargin,'elements'                ,'$DEFS$', eIDS ); end
  if isempty( eIDS ), eIDS = true( size( M.tri ,1) , 1); end

  eDATA = [];
  try, [varargin,z, eDATA ] = parseargs( varargin,'TriangleData','FaceData' ,'$DEFS$',eDATA); end
  pDATA = [];
  try, [varargin,z, pDATA ] = parseargs( varargin,'PointData','VerticesData','VERTEXData' ,'$DEFS$',pDATA); end

  if ischar( pDATA ), pDATA = M.(['xyz',pDATA]); end
  if ischar( eDATA ), eDATA = M.(['tri',eDATA]); end


  
  
  TEXTO = false; TEXTO_point = false;  TEXTO_cell  = false;
  try, [varargin, TEXTO       ] = parseargs( varargin,'text'       ,'$FORCE$',{true,TEXTO} ); end
  if TEXTO, TEXTO_point = true; TEXTO_cell  = true; end
  try, [varargin, TEXTO_point ] = parseargs( varargin,'textpoint' ,'$FORCE$',{true,TEXTO_point} ); end
  try, [varargin,~,TEXTO_point_ids ] = parseargs( varargin,'textpointid'  ,'$DEFS$',[] );  end
  try, [varargin, TEXTO_cell  ] = parseargs( varargin,'textcell'  ,'$FORCE$',{true,TEXTO_cell} );  end
  try, [varargin,~,TEXTO_cell_ids ] = parseargs( varargin,'textcellid'  ,'$DEFS$',[] );  end
 

  try
    [varargin,z] = parseargs(varargin,'NoEdge','$FORCE$');
    if z, varargin = [ varargin , { 'EdgeColor' } , { 'none' } ]; end
  catch 
      varargin( strcmpi(varargin,'noedge') | strcmpi(varargin,'ne') ) = [];
  end

  try
    [varargin,z] = parseargs(varargin,'NoFace','$FORCE$');
    if z, varargin = [ varargin , { 'FaceColor' } , { 'none' } ]; end
  end

  try
    [varargin,z,WIRE] = parseargs(varargin,'WIREframe','$DEFS$',[0 0 0]);
    if z, varargin = [ varargin , { 'FaceColor' } , { 'none' } , { 'EdgeColor' } , { WIRE } ]; end
  end

  try
    [varargin,z] = parseargs(varargin,'gouraud','$FORCE$');
    if z, varargin = [ varargin , { 'FaceLighting' } , { 'gouraud' } ]; end
  end

%   try
%     [varargin,z] = parseargs(varargin,'flat','$FORCE$');
%     if z, varargin = [ varargin , { 'FaceLighting' } , { 'flat' } ]; end
%   end
  
  try
    [varargin,z] = parseargs(varargin,'nolight','$FORCE$');
    if z, varargin = [ varargin , { 'FaceLighting' } , { 'none' } ]; end
  end
  
  try
  [varargin,z] = parseargs(varargin,'ambient','$FORCE$');
  if z, varargin = [ varargin , { 'AmbientStrength' } , { 1 } ,...
                                { 'DiffuseStrength' } , { 0 } ,...
                                { 'SpecularStrength' } , { 0 } ,...
                                { 'SpecularExponent' } , { 0 } ,...
                                { 'SpecularColorReflectance' } , { 0 } ]; end
  end

  try
  [varargin,z] = parseargs(varargin,'shiny','$FORCE$');
  if z, varargin = [ varargin , { 'AmbientStrength' } , { 0.3 } ,...
                                { 'DiffuseStrength' } , { 0.6 } ,...
                                { 'SpecularStrength' } , { 0.9 } ,...
                                { 'SpecularExponent' } , { 20 } ,...
                                { 'SpecularColorReflectance' } , { 1.0 } ]; end
  end

  try
  [varargin,z] = parseargs(varargin,'dull','$FORCE$');
  if z, varargin = [ varargin , { 'AmbientStrength' } , { 0.3 } ,...
                                { 'DiffuseStrength' } , { 0.8 } ,...
                                { 'SpecularStrength' } , { 0.9 } ,...
                                { 'SpecularExponent' } , { 10 } ,...
                                { 'SpecularColorReflectance' } , { 1.0 } ]; end
  end

  try
  [varargin,z] = parseargs(varargin,'metal','$FORCE$');
  if z, varargin = [ varargin , { 'AmbientStrength' } , { 0.3 } ,...
                                { 'DiffuseStrength' } , { 0.3 } ,...
                                { 'SpecularStrength' } , { 1.0 } ,...
                                { 'SpecularExponent' } , { 25 } ,...
                                { 'SpecularColorReflectance' } , { 0.5 } ]; end
  end

  parent = [];
  try, [~,~,parent] = parseargs( varargin , 'parent','$DEFS$',parent); end
  if isempty( parent ), parent = gca; end
  cax = ancestor( parent , 'axes' );
  cax = newplot(cax);

  
  
  [varargin,~,LABELS] = parseargs(varargin,'LABELS','$DEFS$',{});
  
  
  


  %%%Fix zeros in tri
  while any( ~M.tri(:) )
    w = find( ~M.tri(:) );
    try M.tri(w) = M.tri( w - size( M.tri,1) ); catch, M.tri(w) = M.tri(abs(w - size( M.tri,1)) ); end
  end

  if PATCHI
    try
      hg = patchi( 'vertices', double( M.xyz(:,1:3) ) , 'faces', double( M.tri(eIDS,:) ) ,...
                  defOPTS{:} , mOPTS{:} , varargin{:} );
    catch
      hg = patch( 'vertices', double( M.xyz(:,1:3) ) , 'faces', double( M.tri(eIDS,:) ) ,...
                  defOPTS{:} , mOPTS{:} , varargin{:} );
    end
  else
      hg = patch( 'vertices', double( M.xyz(:,1:3) ) , 'faces', double( M.tri(eIDS,:) ) ,...
                  defOPTS{:} , mOPTS{:} , varargin{:} );
  end
  if nargout > 0, hg_ = hg; end
  

  HandlesToDelete = {};

  if size( pDATA ,2) == 1
    set( hg , 'FaceColor' , 'interp' , 'FaceVertexCData' , double( pDATA ) );
  end
  if size( pDATA ,2) == 3
    
    arrows_starts = double( M.xyz );
    arrows_ends   = arrows_starts + double( pDATA );
    
    arrows = permute( cat(3,arrows_starts,arrows_ends,NaN(size(arrows_ends))) , [3,1,2] );
    arrows = reshape( arrows , [ numel( arrows )/3 , 3 ] );
    
    QV = line( 'Parent' , get(hg,'Parent') , 'XData' , arrows(:,1) , 'YData' , arrows(:,2) , 'ZData' , arrows(:,3) );
    
    HandlesToDelete{end+1} = QV;

  elseif size( pDATA ,2) == 2
    
    arrows_starts = double( M.xyz );
    if size( arrows_starts ,2) == 2
      arrows_starts(:,3) = 0;
    end
    if max( abs( arrows_starts(:,3) ) ) > 0
      error('cannot add pDATA');
    end
    pDATA(:,3) = 0;
    arrows_ends   = arrows_starts + double( pDATA );
    
    arrows = permute( cat(3,arrows_starts,arrows_ends,NaN(size(arrows_ends))) , [3,1,2] );
    arrows = reshape( arrows , [ numel( arrows )/3 , 3 ] );
    
    QV = line( 'Parent' , get(hg,'Parent') , 'XData' , arrows(:,1) , 'YData' , arrows(:,2) , 'ZData' , arrows(:,3) );
    
    HandlesToDelete{end+1} = QV;
    
  end
  
  
  if size( eDATA ,2) == 1
    set( hg , 'FaceColor' , 'flat' , 'CData' , double( eDATA( eIDS ,:) ) );
  end
  if size( eDATA ,2) == 3
    
    arrows_starts = meshFacesCenter( M );
    arrows_ends   = arrows_starts + double( eDATA );
    
    arrows_starts = arrows_starts( eIDS ,:);
    arrows_ends   = arrows_ends( eIDS ,:);
    
    arrows = permute( cat(3,arrows_starts,arrows_ends,NaN(size(arrows_ends))) , [3,1,2] );
    arrows = reshape( arrows , [ numel( arrows )/3 , 3 ] );
    
    QV = line( 'Parent' , get(hg,'Parent') , 'XData' , arrows(:,1) , 'YData' , arrows(:,2) , 'ZData' , arrows(:,3) );
    
    HandlesToDelete{end+1} = QV;
  end


  if TEXTO_point
    txyz = M.xyz; txyz(:,end+1:3) = 0; txyz(:,end+1:4) = ( 1:size(M.xyz,1) ).';
%     txyz(:,1:2) = txyz(:,1:2) + (0.1+rand( size(txyz,1) ,2))/30;
    if ~isempty( TEXTO_point_ids ), txyz = txyz( TEXTO_point_ids ,:); end
    hT = text( txyz(:,1) , txyz(:,2) , txyz(:,3) , ...
      arrayfun( @num2str , txyz(:,4) , 'un' , 0 ) ,...
      'Parent' , get(hg,'Parent') , ...
      'HorizontalAlignment','c','VerticalAlignment','m','FontWeight','demi',...
      'BackgroundColor',[1 1 0],'EdgeColor','k','Margin',3 );
    HandlesToDelete{end+1} = hT;
  end
  
  if TEXTO_cell
    txyz = meshFacesCenter( M ); txyz(:,end+1:4) = ( 1:size(M.tri,1) ).';
    if ~isempty( TEXTO_cell_ids ), txyz = txyz( TEXTO_cell_ids ,:); end
    hT = text( txyz(:,1) , txyz(:,2) , txyz(:,3) , ...
      arrayfun( @num2str , txyz(:,4) , 'un' , 0 ) ,...
      'Parent' , get(hg,'Parent') , ...
      'HorizontalAlignment','c','VerticalAlignment','m','FontWeight','bold',...
      'BackgroundColor',[0 1 1],'EdgeColor','k','Margin',3,'Color','r' );
    HandlesToDelete{end+1} = hT;
  end
    
  
  
  if ~isempty( LABELS )
    
    pids = find( ~cellfun( 'isempty' , LABELS ) );
    for p = pids(:).'
    
      ha = 'left';
      if strncmp( LABELS{p} , 'R_' , 2 )
        ha = 'right';
      end
      
      HandlesToDelete{end+1} = text( M.xyz( p ,1) , M.xyz( p ,2) , M.xyz( p ,3) ,LABELS{p} ,...
        'BackgroundColor' , [0 1 1] ,...
                  'Color' , [0 0 0] ,...
              'EdgeColor' , [1 1 1]*0.5 ,...
               'FontSize' , 10 ,...
             'FontWeight' , 'bold' ,...
    'HorizontalAlignment' , ha ,...
            'Interpreter' , 'none' ,...
                 'Margin' , 4 ,...
      'VerticalAlignment' , 'bottom' ,...
      'ButtonDownFcn' , @(h,e)clickOnLabel( h ) );
    
    HandlesToDelete{end+1} = line( M.xyz( p ,1) , M.xyz( p ,2) , M.xyz( p ,3) ,'Marker','o','MarkerEdgeColor','k','MarkerFaceColor',[1 .5 0],...
      'Hittest','on','MarkerSize',15 , 'ButtonDownFcn' , @(h,e)clickOnLabel(HandlesToDelete{end} ) );
    
    end
    
  end
  
  function clickOnLabel( h )
    set( h , 'Visible', onoff( ~onoff( h , 'Visible' ) ) );
    pk = pressedkeys( 3 );
    if pk == 1
      set( h , 'HorizontalAlignment','left' );
    elseif pk == 4
      set( h , 'HorizontalAlignment','right' );
    end
  end
  
  
  

  if ~isempty( HandlesToDelete )
    set( hg , 'DeleteFcn' , @(h,e)safe_delete( HandlesToDelete ) );
  end

  if ~ishold( cax )
    if     size( M.xyz , 2 ) < 3 || max( M.xyz(:,3) )-min( M.xyz(:,3) ) < 1e-6
              view(0,90);
    elseif max( M.xyz(:,1) )-min( M.xyz(:,1) ) < 1e-6
              view(90,0);
    elseif max( M.xyz(:,2) )-min( M.xyz(:,2) ) < 1e-6
              view(0,0);
    else
              view(3);
    end
    set( cax , 'DataAspectRatio' , [1 1 1] );

    bounds = objbounds( hg ,1,true);
    bounds = single( bounds );
    bounds(1) = bounds(1) - 1000*eps( bounds(1) );
    bounds(2) = bounds(2) + 1000*eps( bounds(2) );
    bounds(3) = bounds(3) - 1000*eps( bounds(3) );
    bounds(4) = bounds(4) + 1000*eps( bounds(4) );
    bounds(5) = bounds(5) - 1000*eps( bounds(5) );
    bounds(6) = bounds(6) + 1000*eps( bounds(6) );
    bounds = double( bounds );
    
    set( cax , 'XLim' , bounds(1:2) , 'YLim' , bounds(3:4) , 'ZLim' , bounds(5:6) );
  end
  try, get( hg , 'UpdateOutline' ); end
  


  function safe_delete( h )
    for p = 1:numel( h )
      try
        delete( h{p} );
      end
    end
  end





  
end
