function [X,C] = mesh2contours( B )

  asMESH = true;
  if ~isstruct( B )
    asMESH = false;
    B = struct( 'tri' , B , 'xyz' , zeros( max(B(:)) , 3 , 0 ) );
  end


  B.celltype = meshCelltype( B );
  if B.celltype ~= 3, error('only valid for polyline mesh type (celltype = 3).'); end

  T = B.tri;
  C = cell(0,1);

%   if 1
    
    T = T.';
    R = NaN( 1 , 2*numel(T) );
    while ~isempty( T )
      MB = MeshBoundary( T.' );
      if isempty( MB ), l = T(1);
      else,             l = MB(1);
      end
      
      N = 1; R(1) = l;
      while 1
        e = find( T == l ,1);
        if isempty( e ), break; end
        i = e - realpow( -1 , e );
        l = T( i );
        N = N+1; R(N) = l;
        T( [ e , i ] ) = 0;
      end
  
      C{end+1,1} = R(1:N);
      if ~any(T(:)), break; end
      T( : , ~T(1,:) ) = [];
    end
    
%   else
%     
%     while ~isempty( T )
% 
%       valence = accumarray( T(:) , 1 );
%                         LN = find( valence == 1 , 1 );
%       if isempty( LN ), LN = find( valence , 1 ); end
% 
%       ids = LN;
%       for direction = [ 1 , -1 ];
%         LN = ids(end);
%         while 1
%           e = find( any( T == LN ,2) ,1);
%           if isempty( e ), break; end
%           E = T(e,:); T(e,:) = [];
%           LN = setdiff( E , LN );
%           ids = [ ids , LN ];
%         end
% 
%         ids = ids( end:-1:1 );
%       end
% 
%       C{end+1,1} = ids;
%     end
%     
%   end
  
  n = cellfun( 'prodofsize' , C );
  [~,ord] = sort( n , 'descend' );
  C = C(ord);
  
  if asMESH
    X = B.xyz( C{1} ,:);
    for c = 2:numel(C)
      X(end+1,:) = NaN;
      X = [ X ; B.xyz( C{c} ,:) ];
    end
  else
    X = C;
  end

end
