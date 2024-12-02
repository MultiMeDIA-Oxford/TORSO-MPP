function iM = minv( M )

  if iscell(M)
    iM = M;
    for m = 1:numel(M)
      iM{m} = minv( M{m} );
    end
    return;
  end

  if ~ismatrix( M ), error('Input must be 2-D.'); end
  if size( M , 1 ) ~= size( M , 2 ), error('Matrix must be square.'); end
    
  if isempty( M ), iM = []; return; end
  
  s = size( M , 1 );
  
  if 0
    
  elseif maxnorm( M.' * M  - eye(s) ) < 1e-20
    
    iM = M.';
    
  elseif ~any( M(end,1:end-1) ) && M(end,end) == 1
    
    iM = minv( M(1:end-1 , 1:end-1 ) );
    iM = [ iM , - iM * M( 1:end-1 ,end ) ; M(end,:) ];
    
  else
  
    iM = ( ( eye(s) / M ) + ( M \ eye(s) ) )/2;
    
  end

  
%         try
%           H = linsolve( H , eye(4) ); %inv( H );    %eye(4) / H;
%         catch
%           H = inv( H );
%         end
  
  
end
