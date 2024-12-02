function hg_ = plot( P , varargin )

  hAxe = newplot;
  
  varargin = getLinespec( varargin );
  
  faceopts_idxs = find( cellfun( @(s) strncmpi(s,'face',4) , varargin ) );
  faceopts_idxs = unique( [ faceopts_idxs , faceopts_idxs+1 ] );
  faceopts      = varargin( faceopts_idxs );
  varargin( faceopts_idxs ) = [];
  for i = 1:2:numel( faceopts )
    switch lower(faceopts{i})
      case {'faceedgecolor','faceedgealpha','faceerasemode',...
            'facelinestyle','facelinewidth','facemarker',...
            'facemarkeredgecolor','facemarkerfacecolor',...
            'facemarkersize','faceclipping','facehittest'}
        faceopts{i} = faceopts{i}(5:end);
    end
  end
  
  
  
  lineopts_idxs = find( cellfun( @(s) strncmpi(s,'line',4) , varargin ) );
  lineopts_idxs = unique( [ lineopts_idxs , lineopts_idxs+1 ] );
  lineopts      = varargin( lineopts_idxs );
%   if ~isempty( V_lstyle ), lineopts = [ 'linestyle' , V_lstyle , lineopts ]; end
  varargin( lineopts_idxs ) = [];
  for i = 1:2:numel( lineopts )
    switch lower(lineopts{i})
      case {'linecolor','lineerasemode','linemarker',...
            'linemarkersize','linemarkeredgecolor',...
            'linemarkerfacecolor','lineclipping','linehittest'}
        lineopts{i} = lineopts{i}(5:end);
    end
  end
  
  
%   if ~isempty( V_color  ), varargin = [ 'color',  V_color  , varargin ]; end
%   if ~isempty( V_marker ), varargin = [ 'marker', V_marker , varargin ]; end
  
  COLOR = [ 0 0 1 ];
  for i = 1:2:numel( varargin )
    %if ~ischar( varargin{i} ), continue; end
    switch lower(varargin{i})
      case {'marker','markersize','markeredgecolor','markerfacecolor','linestyle'}
        lineopts = [ lineopts , varargin{i} , varargin{i+1} ];
        varargin{i } = [];
        varargin{i+1} = [];
      case {'color'}
        COLOR = varargin{i+1};
        varargin{i } = [];
        varargin{i+1} = [];
    end
  end
  
  varargin = varargin( ~cellfun( 'isempty', varargin ) );
  
  
  indc=find(cell2mat(P.XY(:,2))==0);
  C=P.XY(indc,:);
  P.XY(indc,:)=[];
  
  
  
  [PP,S] = polygon_mx( P.XY );
  
  hg = hgtransform( varargin{:} );
  
  
  hl = line('parent',hg,'color',COLOR);
  COLOR = get(hl,'color');
  delete(hl);
  faceCOLOR = hsv2rgb( max( rgb2hsv( COLOR ) .* [1 0.2 1] , [0 0 0.5] ) );

  
  V = [];
  F = [];
  for i = 1:size(S,1)
    NV = size( V , 1 );
    V = [ V ; S{i} ];
    F = [ F ;  bsxfun( @plus , ( 1:(size(S{i},1)-2) ).' , NV+[0 1 2] ) ];
  end

  V(:,3) = 0;
  

  patch('Parent',hg,'vertices',V,'faces',F,'facecolor',faceCOLOR,'edgecolor','none',faceopts{:} );  

  
  solids = [];
  holes  = [];
  
  for i = 1:size(P.XY,1)
    switch P.XY{i,2}
      case  1, solids = [ solids ; NaN NaN ; P.XY{i,1}([1:end 1],:) ];
      case -1, holes  = [ holes  ; NaN NaN ; P.XY{i,1}([1:end 1],:) ];
      
    end
  end
  if ~isempty( solids )
    l=line('Parent',hg, 'XData',solids(:,1),'YData',solids(:,2),'color',COLOR,'linewidth',2,'linestyle','-',lineopts{:} );
    set(l,'handlevisibility','off');
  end
  if ~isempty( holes )
    line('Parent',hg, 'XData',holes(:,1) ,'YData',holes(:,2) ,'color',COLOR,'linewidth',2,'linestyle','--',lineopts{:} );
    set(l,'handlevisibility','off');
  end


  curves = [];
  for i = 1:size(C,1)
      curves = [ curves ; NaN NaN ; C{i,1}];
  end  
  
  if ~isempty( curves )
    line('Parent',hg, 'XData',curves(:,1),'YData',curves(:,2),'color',COLOR,'linewidth',2,'linestyle','-',lineopts{:} );
  end
  
  
  if ~ishold(hAxe), axis(hAxe, 'equal'); end

  if nargout, hg_ = hg; end
 
end