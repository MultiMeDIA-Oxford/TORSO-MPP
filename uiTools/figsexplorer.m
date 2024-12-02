function figsexplorer(h)
  if nargin < 1
    h = gcf;
  end
  hFig = ancestortool(h,'figure');
  
  if ~any( strcmp( import , 'javax.swing.*' ) )
    import javax.swing.*;
  end
  
  f = figure('Units', 'pixels', 'Position',[0 80 300 740],...
             'NumberTitle', 'off'      ,...
             'name',['Figs: ' , Name(h) ] ,...
             'Toolbar', 'none'         ,...
             'IntegerHandle','off'     ,...
             'Menu','none'             );

  switch getfield( ver('MATLAB') , 'Version' )
    case '8.1'
      UITreeNode = @(varargin) uitreenode( 'v0' , varargin{:} );
      UITree     = @(varargin)     uitree( 'v0' , varargin{:} );
    otherwise
      UITreeNode = @(varargin) uitreenode( varargin{:} );
      UITree     = @(varargin)     uitree( varargin{:} );
  end
           
  root = UITreeNode( h , Name(h) , [] , isempty( allchild( h ) ) );

  tree = UITree(f, 'ExpandFcn', @ExpandNodeFcn, 'Root', root );
  drawnow expose;
  set( tree , 'Units', 'normalized'  );
  set( tree , 'position', [0 0 1 1]  );
  set( tree , 'NodeSelectedCallback'  , @NodeSelectedFcn  );
  tree.expand(root);
%   ExpandAll(tree,root);
  try, figurewindowstate(f,'ontop'); end

  function NodeSelectedFcn( tree , ev )
    pk = pressedkeys(false);
    if isequal( pk , {'LCONTROL'} )
      ExpandAll( tree , ev.getCurrentNode );
      return;
    end
    
    h = ev.getCurrentNode.getValue;
    if isequal( pk , {'LSHIFT'} )
      inspect( h );
    end
    
    %figure( hFig );
    set( hFig , 'CurrentObject', h );
    BlinkUI( h , [] , 10 , 0.05 );
  end

  function ExpandAll( tree , N )
    tree.expand(N);
    drawnow;
    for nn= 1:N.getChildCount
      ExpandAll( tree , N.getChildAt(nn-1) );
    end
  end

  function name= Name( h )
    name = get( h , 'Type' );
    switch name
      case 'figure'    , addToName( num2str(h)           ,'()');
      case 'uimenu'    , addToName( get(h,'Label')       ,'()');
      case 'line'      , addToName( get(h,'DisplayName') ,'()');
      case 'text'      , addToName( ['.',get(h,'string'),'.']      ,'<>');
    end
    addToName( get( h , 'tag' ) , '[]' );
    
    function addToName( n , bra )
      if ~isempty(n) && ischar(n)
        switch bra
          case '()', name = sprintf('%s  ( %s )',name,n);
          case '[]', name = sprintf('%s  [ %s ]',name,n);
          case '<>', name = sprintf('%s  <%s>',name,n);
          case '.' , name = sprintf('%s.%s',name,n);
          case ':' , name = sprintf('%s:%s',name,n);
        end
      end
    end
  end


  function nodes = ExpandNodeFcn( tree , h )
    children = allchild(h);
    if numel( children )
      for cc = numel(children):-1:1
        c = children(cc);
        nodes(cc) = UITreeNode( c , Name(c) , '' , isempty( allchild( c ) ) );
      end
    else
      nodes = [];
    end
  end

end

