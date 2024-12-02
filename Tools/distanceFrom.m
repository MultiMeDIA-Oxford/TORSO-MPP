function [d,cp,eid,bc] = distanceFrom( xyz , M , getBOUNDARY , QUIET )
% 
%   [d,cp] = distanceFrom( xyz , M , true );
% 
% 

  persistent storedBOUNDARIES
  if isempty( storedBOUNDARIES ), storedBOUNDARIES = cell(0,3); end

  if nargin < 3 || isempty( getBOUNDARY ), getBOUNDARY = false; end
  if nargin < 4, QUIET = false; end

  if ~isstruct( M ), getBOUNDARY = false; end
  
  try, M.tri = double( M.tri ); end
  if getBOUNDARY
    b = find( cellfun( 'prodofsize' , storedBOUNDARIES(:,1) ) == numel( M.tri ) );
    b = b( arrayfun( @(c)isequal( storedBOUNDARIES{c,1} , M.tri ) , b ) );

    if ~isempty( b )
      b = b(1);
      BOUNDARYelements = storedBOUNDARIES{b,2};
      BOUNDARYedges    = storedBOUNDARIES{b,3};
    else
      BOUNDARYedges = MeshBoundary( M.tri );
      BOUNDARYedges = sort( BOUNDARYedges ,2);
      u = unique( BOUNDARYedges );
      BOUNDARYedges( end + (1:numel(u)) , 2 ) = u;
      BOUNDARYedges = sortrows( BOUNDARYedges );
      
      BOUNDARYelements = any( ismember(  M.tri , u ) ,2);
      
      b = size( storedBOUNDARIES ,1) + 1;
      storedBOUNDARIES{b,1} = M.tri;
      storedBOUNDARIES{b,2} = BOUNDARYelements;
      storedBOUNDARIES{b,3} = BOUNDARYedges;
    end
  end

  
  if getBOUNDARY && ~any( BOUNDARYelements ), getBOUNDARY = false; end
  getBC = getBOUNDARY || nargout > 3;
  
  if     0
  elseif isstruct( M )  &&  meshCelltype( M ) == 5
    
    M = struct( 'xyz' , double(M.xyz) , 'tri' , M.tri );
    nxyz = size( xyz , 1 );
    
    if nxyz < 5e5
      if getBC,  [ eid , cp , d , bc ] = vtkClosestElement( M , double( xyz ) );
      else,      [ eid , cp , d      ] = vtkClosestElement( M , double( xyz ) );
      end
    else
      eid = NaN( nxyz , 1 );
      cp  = NaN( nxyz , 3 );
      d   = NaN( nxyz , 1 );
      if getBC
      bc  = NaN( nxyz , 3 );
      end
      
      bunchSize = 1e5;
      
      vtkClosestElement( [] , [] );
      vtkClosestElement( M );
      for e = 1:bunchSize:nxyz
        w = e + ( 0:bunchSize-1 ); w = w( w <= nxyz );
        if getBC, [ eid(w,1) , cp(w,:) , d(w,1) , bc(w,:) ] = vtkClosestElement( double( xyz(w,:) ) );
        else,     [ eid(w,1) , cp(w,:) , d(w,1)           ] = vtkClosestElement( double( xyz(w,:) ) );
        end
        if ~QUIET
          fprintf('(%9d - %9d   of   %9d)  %g %% done\n' , w(1) , w(end) , nxyz , w(end)/nxyz * 100 );
        end
      end
      vtkClosestElement( [] , [] );
    end
      
    
    if getBOUNDARY
      e = BOUNDARYelements( eid );
      if ~any( e ), return; end
      
      b = bc > 1e-8;
      b( ~e ,:) = false;
      b( all(b,2) ,:) = false;
      b = M.tri(eid,:) .* b;
      b = sort( b ,2);
      b = b(:,2:3);
      
      e = find( ~~b(:,2) );
      e = e( ismember( b(e,:) , BOUNDARYedges ,'rows' ) );
      d( e ) = -d( e );
    end
    
  elseif isnumeric( M )  &&  size( M ,2) == 3
    
    try
      [~,cp,d] = vtkClosestPoint( struct('xyz',double(M)) , double( xyz ) );
    catch
      [n,d] = knnsearch( double(M) , double(xyz) ,'K',1);
      cp = M(n,:);
    end
    
  elseif isa( M , 'polyline' )
    
    %[ ~ , cp , d ] = closestElement( M , xyz );
    [ ~ , cp , d ] = ClosestElement( double( M ) , double( xyz ) );
    %[ ~ , cp , d ] = closestElement( M , double(xyz) );
    
%     error('not implemented yet');
    
  end



end
