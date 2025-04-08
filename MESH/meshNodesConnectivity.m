function C = meshNodesConnectivity( M )

  V = [];
  if isstruct( M )
    nX = size( M.xyz ,1);
    for f = fieldnames( M ).', f = f{1};
      if  strcmp(  f , 'xyz' ),      continue; end
      if ~strncmp( f , 'xyz' , 3 ),  continue; end
      thisV = M.(f); thisV = thisV(:,:);
      thisV(:, all( bsxfun( @eq , thisV , thisV(1,:) ) ,1) ) = [];
      V = [ V , thisV ];
    end
    M = M.tri;
  else
    nX = max( M(:) );
  end

  E = meshEdges( M ).';
  
  C = zeros( nX , 1 ) - 1;
  C( E(:) ) = 0;
  c = 1;
  while 1
    E( : , all( C(E) ,1) ) = [];
    G = find( ~C , 1 ); if isempty( G ), break; end
    C( G ) = c;
    if ~isempty(V)
      v = all( bsxfun( @eq , V , V( G ,:) ) ,2);
    end
    while ~isempty( G )
      G = find( myISMEMBER( E , G ) );
      G = G - realpow( -1 , G );
      G = E( G );
      if ~isempty(V)
        G( ~v(G) ) = [];
      end
      
      G( ~~C(G) ) = [];
      C( G ) = c;
    end
    c = c+1;
  end

end
function lia = myISMEMBER( a , b )
  done = false;
  if numel(b) == 1
    lia = a == b;
    done = true;
  end
  
  if ~done, b = sort(b(:)); end
  if ~done, try, lia = builtin('_ismemberoneoutput',a,b); done = true; end; end
  if ~done, try, lia = builtin('_ismemberhelper',a,b);    done = true; end; end
  if ~done, lia = ismember( a , b ); end
end



