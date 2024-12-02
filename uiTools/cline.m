function h_ = cline( varargin )


if 0
  t=linspace(0,4*pi,71).';
  X = cos(t);
  Y = sin(t);
  Z = t;
  C = t.^2;

  close; cline( [ X , Y , Z , C ]  ,'marker','s','edgecolor','none'); colormap jet
  close; cline( [ X , Y ,     C ]  ,'marker','s','edgecolor','none'); colormap jet

  C = rand(numel(X),3);

  close; cline( [ X , Y , Z] , C ,'marker','s','edgecolor','none'); colormap jet
  close; cline( [ X , Y ]    , C ,'marker','s','edgecolor','none'); colormap jet
  close; cline(   X ,          Y ,'marker','s','edgecolor','none'); colormap jet

  close; cline(   X , Y , Z , C  ,'marker','s','edgecolor','none'); colormap jet
  close; cline(   X , Y ,     C  ,'marker','s','edgecolor','none'); colormap jet
  
  %%
end


  fs = find( cellfun(@ischar,varargin) , 1 ); if isempty(fs), fs = numel(varargin)+1; end
  inputs = varargin( 1:fs-1 );
  varargin( 1:fs-1 ) = [];
  varargin = getLinespec( varargin );


  parent = [];
  try, [~,~,parent] = parseargs( varargin , 'parent','$DEFS$',parent); end
  if isempty( parent ), parent = gca; end
  cax = ancestor( parent , 'axes' );
  cax = newplot(cax);

  switch numel( inputs )
    case 0, error('no data to plot!')
    case 1
      if      size( inputs{1} ,2) == 4
        X = inputs{1}(:,1);
        Y = inputs{1}(:,2);
        Z = inputs{1}(:,3);
        C = inputs{1}(:,4);
      elseif  size( inputs{1} ,2) == 3
        X = inputs{1}(:,1);
        Y = inputs{1}(:,2);
        Z = [];
        C = inputs{1}(:,3);
      else, error('[X Y Z C] or [X Y C] were expected.');
      end
    case 2
      if      size( inputs{1} ,2) == 3
        X = inputs{1}(:,1);
        Y = inputs{1}(:,2);
        Z = inputs{1}(:,3);
      elseif  size( inputs{1} ,2) == 2
        X = inputs{1}(:,1);
        Y = inputs{1}(:,2);
        Z = [];
      elseif  size( inputs{1} ,2) == 1
        X = inputs{1};
        Y = inputs{2};
        Z = [];
        C = [];
      else, error('[X Y Z],[C] or [X Y],[C] or [X],[Y] were expected.');
      end
      C = inputs{2};
    case 3
      X = inputs{1};
      Y = inputs{2};
      Z = [];
      C = inputs{3};
    case 4
      X = inputs{1};
      Y = inputs{2};
      Z = inputs{3};
      C = inputs{4};
    otherwise, error('too much inputs to plot');
  end
  if isempty( X ), error('no X?'); end
  if isempty( Y ), error('no Y?'); end
  if isempty( C )
    C = Z;
    if isempty( C ), C = Y; end
  end
  if isempty( Z ), Z = zeros( size(X) ); end
  n = numel(X);
  C = reshape( C , [ n , numel(C)/n ] );
  
  V = [ X(:) , Y(:) , Z(:) ];
  F = [ 1:(n-1) ; 2:n ].';
  try
    h = patch( 'Vertices', V , 'Faces' , F , 'EdgeColor' , 'interp' , 'MarkerFaceColor' , 'flat' ,'FaceColor' , 'none' , 'CData' , C ,...
               'FaceVertexCData' , C ,...
                varargin{:} );
    
    %autos
    varargin( ~cellfun(@ischar,varargin) ) = [];
    if ~any( strcmpi( varargin , 'MarkerEdgeColor' ) )
      if      strcmp( get(h,'Marker') , '.' )
        set( h , 'MarkerEdgeColor' , 'flat' );
      else
        set( h , 'MarkerEdgeColor' , 'k' );
      end
    end
    if ~any( strcmpi( varargin , 'EdgeColor' ) )
      if ~strcmp( get(h,'Marker') , 'none' )
        set( h , 'EdgeColor' , 'none' );
      end
    end
  catch
    error('some error!!');
  end
  if max(abs(Z(:))) > 0 && ~ishold( ancestor( h , 'axes' ) ), view(3); end
  if nargout, h_ = h; end

end
