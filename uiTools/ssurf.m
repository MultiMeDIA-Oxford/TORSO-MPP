function h_ = ssurf( X , Y , Z , varargin )
% 
% scattered surface
% 
% ssurf( X , Y , Z , 'Delaunay' )
% ssurf( X , Y , Z , 'Voronoi'   )
% ssurf( X , Y , Z , patchOptions )
% patchHandle  = ssurf( X , Y , Z , C , patchOptions )
% 
% 
%{

x = randn(1,3500);
y = randn(1,3500);

%[x,y] = ndgrid(-2:0.2:2,-2:0.2:2);
%x = x + rand(size(x))/2;
%y = y + rand(size(y))/2;

z = peaks(x,y)/5;

% ssurf(x,y,z,-z,'voronoi'); colormap jet
ssurf(x,y,z,-z);
hold on
ssurf(x,y,z,'facecolor','none','marker','o','markerfacecolor','flat')
hold off
camlight; lighting gouraud; colormap jet; material dull
axis equal

%}


  C = Z;
  if numel(varargin) && ~ischar( varargin{1} )
    C = varargin{1};
    varargin(1) = [];
  end
  
  if numel(X) ~= numel(Y) || numel(X) ~= numel(Z) || numel(X) ~= numel(C)
    error('inconsistent sizes');
  end
  

  

  % use nextplot unless user specified an axes handle in pv pairs
  [varargin,hadParentAsPVPair,cax] = parseargs(varargin,'parent','$DEFS$',[]);
  if isempty(cax) || ~hadParentAsPVPair
      if ~isempty(cax) && ~isa(handle(cax),'hg.axes')
          parax = cax;
          cax = ancestor(cax,'Axes');
          hold_state = true;
      else
          cax = newplot(cax);
          parax = cax;
          hold_state = ishold(cax);
      end
  else
      cax = newplot(cax);
      parax = cax;
      hold_state = ishold(cax);
  end
  

  TYPE = 'delaunay';
  [varargin,TYPE] = parseargs( varargin,'Delaunay' ,'$FORCE$',{'delaunay',TYPE} );
  [varargin,TYPE] = parseargs( varargin,'Voronoi'  ,'$FORCE$',{'voronoi',TYPE}  );

  
  switch TYPE
    case 'delaunay'
      faces = delaunayn( [ X(:) , Y(:) ] );
      
      h = patch( 'parent',parax,'vertices',[ X(:) , Y(:) , Z(:) ],'faces',faces , 'cdata', C(:) ,...
                 'edgecolor','none','facecolor','interp',varargin{:});
      
    case 'voronoi'
      [vertices,faces] = voronoin( [ X(:) , Y(:) ] );
      
      vertices( vertices( : , 1 ) < min( X(:) ) , : ) = NaN;
      vertices( vertices( : , 1 ) > max( X(:) ) , : ) = NaN;
      vertices( vertices( : , 2 ) < min( Y(:) ) , : ) = NaN;
      vertices( vertices( : , 2 ) > max( Y(:) ) , : ) = NaN;
      

      h = hggroup( 'parent' , parax );
      for f = 1:numel(faces)
        if any( isnan( vertices( faces{f} , 1 ) ) ), continue; end
        
        patch( vertices( faces{f} , 1 ) , vertices( faces{f} , 2 ) , Z(f)*ones(numel(faces{f}),1) , C(f) , 'parent',h,'facecolor','flat',varargin{:} );
        
        
        posiblesVecinos = find( Z < Z(f) );
        if isempty( posiblesVecinos ), continue; end

        for e = 1:numel( faces{f} )
          edge(1) = faces{f}( e );
          if e == numel( faces{f} )
            edge(2) = faces{f}(   1 );
          else
            edge(2) = faces{f}( e+1 );
          end
            
          edge = sort( edge );
          
          for vv = posiblesVecinos(:).'
            if sum( ismembc( faces{vv} , edge ) ) == 2
              patch( [ vertices( edge(1) , 1 ) ; vertices( edge(2) , 1 ) ; vertices( edge(2) , 1 ) ; vertices( edge(1) , 1 ) ] ,...
                     [ vertices( edge(1) , 2 ) ; vertices( edge(2) , 2 ) ; vertices( edge(2) , 2 ) ; vertices( edge(1) , 2 ) ] ,...
                     [ Z(f) ; Z(f) ; Z(vv) ; Z(vv) ] ,...
                     [ C(f) ; C(f) ; C(vv) ; C(vv) ] ,...
                     'parent',h,'facecolor','interp' );
              break;
            end
          end
          
        end
        
      end
      

      
  end

  if nargout>0, h_ = h; end
  
  
  if ~hold_state
      view(cax,3);
      grid(cax,'on');
  end

end

