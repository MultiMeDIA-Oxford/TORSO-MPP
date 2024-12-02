function JS = handle2javaobject( hg , salvar )

  if nargin < 2, salvar = 0; end

  hFig = ancestortool( hg , 'figure' );
  
  jFigPanel = get( get( handle(hFig) , 'JavaFrame' ) ,'FigurePanelContainer' );
  jRootPane = jFigPanel.getComponent(0).getRootPane.getTopLevelAncestor.getComponent(0);
  
  REC2NUM = @(r) [ r.getX , r.getY , r.getWidth , r.getHeight ];
  
  JS = {};
  queue = { jRootPane , [0 0 0 0] };
  while ~isempty( queue )
    obj = queue{end,1};
    JS(end+1,:) = { obj , REC2NUM( obj.getBounds ) + queue{end,2} };
    queue(end,:) = [];
    
    try
      for c = 1:obj.getComponentCount
        child = obj.getComponent(c-1);
        if ~isempty( regexp( class(child) , '.*Menu.*', 'ONCE' ) ) , continue; end
        if isa(child,'com.mathworks.mwswing.desk.DTToolBarContainer') , continue; end
        queue(end+1,:) = { child , [ JS{end,2}(1:2) 0 0 ] };
      end
    end
  end

  switch get(hg,'Type')
    case 'uicontrol'
      switch get(hg,'Style')
        case 'slider',     JS = JS( cellfun(@(j) isa(j,'com.mathworks.hg.peer.SliderPeer$MLScrollBar'  ), JS(:,1) ) ,:);
        case 'pushbutton', JS = JS( cellfun(@(j) isa(j,'com.mathworks.hg.peer.PushButtonPeer$1'        ), JS(:,1) ) ,:);
        case 'edit',       JS = JS( cellfun(@(j) isa(j,'com.mathworks.hg.peer.EditTextPeer$hgTextField'), JS(:,1) ) ,:);
        case 'text',       JS = JS( cellfun(@(j) isa(j,'com.mathworks.hg.peer.LabelPeer$1'             ), JS(:,1) ) ,:);
      end
  end
  
  POS        = cell2mat( JS(:,2) );
  POS(:, 1 ) = POS(:, 1 ) - jRootPane.getX;
  POS(:, 2 ) = POS(:, 2 ) - jRootPane.getY;
  POS(:, 2 ) = jRootPane.getHeight - POS(:,2) - POS(:,4);

  p = getposition( hg , 'pixels' );

  diffpos = abs( bsxfun( @minus , POS , p ) );

  JS = JS( all( diffpos <= 2 , 2 ) , 1 );
  
  if numel( JS ) == 1
    try,
      JS = handle( JS{1} , 'CallbackProperties' );
    catch
      JS = JS{1};
    end
  else
    
  end
  
  if ~isempty( JS ) && salvar
    setappdata( hg , 'JavaObject', JS );
  end
  
end
