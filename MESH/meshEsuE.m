function L = meshEsuE( T , asCell , byMODE )
  if nargin < 2 || isempty( asCell )
    asCell = false;
  end
  if nargin < 3, byMODE = 'bynode'; end
  
  if isstruct( T )
    T = T.tri;
  end
  
  nT = size( T ,1);
  
  if isnumeric(byMODE)
    switch byMODE
      case 1, byMODE = 'bynode';
      case 2, byMODE = 'byedge';
      case 3, byMODE = 'byface';
      otherwise, error('incorrect byMODE option');
    end
  elseif numel(byMODE) == 1
    switch lower(byMODE)
      case 'n', byMODE = 'bynode';
      case 'v', byMODE = 'bynode';
      case 'e', byMODE = 'byedge';
      case 'f', byMODE = 'byface';
      otherwise, error('no well specified byMODE option');
    end
  end
  
  switch lower( byMODE )
    case {'bynode','node','bynodes','nodes','byvertices','vertices','byvertice','vertice'}
      ESUP = meshEsuP( T , false );

      F = sparse( [] , [] , [] , 0 , nT );
      for c = 1:size(T,2)
        F = [ F ; ESUP( : , T(:,c) ) ];
      end  

      [I,J] = find( F );
      I = rem( I-1 , nT ) + 1;

      if asCell
        w = J == I;
        J(w) = []; I(w) = [];
        IJ = unique( [ J , I ] ,'rows' );

        L = accumarray( IJ(:,1) , IJ(:,2) , [nT,1] , @(x){x} );
      else
        w = J <= I;
        J(w) = []; I(w) = [];
        IJ = unique( [ J , I ] ,'rows' );

        L = sparse( IJ(:,1) , IJ(:,2) , true , nT , nT );
        L = L | L.';
      end
      
    case {'byedge','edge','byedges','edges'}
      E = [];
      for i = 1:size( T , 2 )
        for j = i+1:size( T , 2 )
          E = [ E ; T(:,[i j]) ];
        end
      end
      E = sort( E , 2 );
      
      Tid = ( 1:nT ).';
      E = [ E , repmat( Tid , [ size(E,1)/nT , 1 ] ) ];
      %[~,ord] = sort( E(:,3) ); E = E(ord,:);
      [~,~,c]=unique( E(:,1:2),'rows' );
      R = find( accumarray(c,1) > 1 );
      
      if asCell
        
        L = cell( nT ,1);
        for r = R(:).'
          fs = E( c==r ,3);
          for i = 1:numel(fs)
            for j = [ 1:i-1 , i+1:numel(fs) ]
              L{fs(i)} = [ L{fs(i)} , fs(j) ];
            end
          end
        end
        
      else
        
        L = sparse( [] , [] , [] , nT , nT );
        for r = R(:).'
          fs = E( c==r ,3);
          for i = 1:numel(fs)
            L( fs([ 1:i-1 , i+1:numel(fs) ]) , fs(i) ) = true;
          end
        end
        L = L | L.';
        
      end
      
    case {'byface','face','byfaces','faces'}
      error('not implemented yet');
      
    otherwise
      error('unknow byMODE');
  end
    
end
