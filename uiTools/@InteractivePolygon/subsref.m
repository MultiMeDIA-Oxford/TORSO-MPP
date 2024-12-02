function o = subsref(IP,s)
% 
% 

%   if ~ishandle(IP.handle), fprintf('No existe mas.\n'); return; end

  S= [];
  for ss=1:numel(s)
    if numel( s(ss).subs ) > 0
      S= [S s(ss).type];
      switch s(ss).type
        case '.'
          S= [S s(ss).subs];
        case {'()','{}'}
          switch numel( s(ss).subs );
            case 1,    S= [S(1:end-1) '1' S(end)];
            case 2,    S= [S(1:end-1) '2' S(end)];
            case 3,    S= [S(1:end-1) '3' S(end)];
            case 4,    S= [S(1:end-1) '4' S(end)];
            otherwise, S= [S(1:end-1) '_' S(end)];
          end
      end
    else
      S= '0';
    end
  end

  switch S
    case {'.n','.numel','.num','.numvertives'}
      o = size( getVertices( IP ), 1);
    case {'.isclose','.close'}
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      o = IPdata.close;
    case {'.isspline','.spline'}
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      o = IPdata.spline;
    case {'.handle','.grouphandle','.hggrouphandle'}
      o = IP.handle;
    case {'.verticeshandles','.vhandles'}
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      o = IPdata.vertices;
    case {'.line','.linehandle','.lhandle'}
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      o = IPdata.line;
    case {'.arrowshandle','.ahandle'}
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      o = IPdata.arrows(:,1);
    case {'.curve','.contour','.xyz'}
      o = getCurve( IP );
    case {'.curve(1)','.contour(1)','.xyz(1)'}
      o = getCurve( IP );
      o = o( s(2).subs{:} , : );
    case {'.curve(2)','.contour(2)','.xyz(2)'}
      o = getCurve( IP );
      o = o( s(2).subs{:} );
    case {'.vertices','.v','.V'}
      o = getVertices( IP );
    case { '.vertices(1)','.v(1)','.V(1)','.vertices(2)','.v(2)','.V(2)' }
      v = getVertices( IP );
      o = v( s(2).subs{:} );
    case {'(1)' }
      v = getVertices( IP );
      o = v( s(1).subs{:} , : );
    case {'(2)' }
      v = getVertices( IP );
      o = v( s(1).subs{:} );
    otherwise
      error('Invalid Access.');
  end

end
