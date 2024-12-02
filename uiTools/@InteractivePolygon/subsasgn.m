function IP = subsasgn(IP,s,in)

  if ~ishandle(IP.handle), fprintf('No existe mas.\n'); return; end

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
    case {'.arrows'}
      if numel(in) == 1, in = [in in]; end
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      IPdata.arrows(:,2) = in(:);
      setappdata( IP.handle , 'InteractivePolygon' , IPdata);
      %setVertices( IP , getVertices(IP) , 'update' );
      setVertices( IP , getVertices(IP) );
    case {'.isclose','.close'}
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      IPdata.close = in;
      setappdata( IP.handle , 'InteractivePolygon' , IPdata);
      setVertices( IP , getVertices(IP) , 'update' );
    case {'.isspline','.spline'}
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      IPdata.spline = in;
      setappdata( IP.handle , 'InteractivePolygon' , IPdata);
      setVertices( IP , getVertices(IP) , 'update' );
    case {'.vertices','.v','.V'}
      setVertices( IP , in , 'update' );
    case { '.vertices(1)','.v(1)','.V(1)' ,'.vertices(2)','.v(2)','.V(2)' }
      v = getVertices( IP );   v( s(2).subs{:} ) = in;
      setVertices( IP , v , 'update' );
    case {'(1)' }
      v = getVertices( IP );   v( s(1).subs{:}, : ) = in;
      setVertices( IP , v , 'update' );
    case {'(2)' }
      v = getVertices( IP );   v( s(1).subs{:} ) = in;
      setVertices( IP , v , 'update' );
    case {'.fcn' }
      IPdata= getappdata( IP.handle , 'InteractivePolygon' );
      IPdata.fcn = in;
      setappdata( IP.handle , 'InteractivePolygon' , IPdata);
    otherwise
      error('Invalid Access.');
  end
end
