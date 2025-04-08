function [v,c,IT] = MeshVolume( M , varargin )
% 
% M.xyz= randn(1000,3);
% M.xyz = bsxfun(@rdivide,M.xyz,sqrt(sum(M.xyz.^2,2)));
% M.tri = convhulln( M.xyz );
% MeshVolume( M ) / (4/3*pi)
% 

  M = Mesh( M ,0);

  [varargin,CLEAN ] = parseargs(varargin,'noclean' ,'$FORCE$',{false,true});
  [varargin,ORIENT] = parseargs(varargin,'noorient','$FORCE$',{false,true});

  if CLEAN
    M = MeshTidy( M ,0,true);

    bounds = MeshBoundary( M );
    if isfield( bounds , 'tri' ) && size( bounds.tri ,1) > 0, warning('MESH look open. try with vtkFillHolesFilter'); end
  end
  

  if ORIENT
    M = MeshFixCellOrientation( M );
  end
  
  
  N = cross( ( M.xyz(M.tri(:,2),:) - M.xyz(M.tri(:,1),:) ) , ( M.xyz(M.tri(:,3),:) - M.xyz(M.tri(:,2),:) ) , 2 );
  A = sqrt( sum( N.^2 , 2 ) );
  N = bsxfun( @rdivide , N , A );
  A = A/2;
  


  %v = vtkMassProperties( M , 'GetVolume' );
  
  v =  sum(  ( M.xyz( M.tri(:,1),: ) + M.xyz( M.tri(:,2),: ) + M.xyz( M.tri(:,3),: ) ) .* N , 2 );
  v = 2*sum( v .* A )/( 3 * factorial(3) );

%   ISC = {};
%   disp([5 4 3]); 
%   disp( moment( [ 5 4 3] ) );
%   disp([3 4 5]); moment( [ 3 4 5] );

%   uneval([ moment([2 0 0]) moment([1 1 0]) moment([1 0 1]) ;
%     0               moment([0 2 0]) moment([0 1 1]) ;
%     0               0               moment([0 0 2]) ])

  if nargout > 1
    c = [ moment([1 0 0]) ,  moment([0 1 0]) , moment([0 0 1]) ];
    c = c/v;
  end
  
  
  [varargin,CENTER ] = parseargs(varargin,'center' ,'$FORCE$',{true,false});
  if CENTER
    M.xyz = bsxfun( @minus , M.xyz , c(:).' );
  end
  if nargout > 2
    IT = [ moment([2 0 0])/2 ,  moment([1 1 0])   , moment([1 0 1])   ;...
           0                 ,  moment([0 2 0])/2 , moment([0 1 1])   ;...
           0                 ,  0                 , moment([0 0 2])/2 ];
    IT = IT + IT.';
  end

  
  function mo = moment( pqr )
    p1 = pqr(1);  p2 = pqr(2);  p3 = pqr(3);
    P = p1 + p2 + p3;

    N_P = bsxfun( @rdivide , N , [p1 p2 p3]+1 );
    
    mo = zeros( size(M.tri,1) , 1 );
    
    for k1 = 0:p1,  for k2 = 0:p2,  for k3 = 0:p3

          K  = k1 + k2 + k3;
          
          Is = zeros( size(M.tri,1) , 1 );
          for j1 = 0:k1,   for j2 = 0:k2,   for j3 = 0:k3
                J  = j1 + j2 + j3;
                
%                 if any( cellfun( @(s) isequal(s,[j1 j2 j3 k1 k2 k3 P]) , ISC ) )
%                   disp( [j1 j2 j3 k1 k2 k3 P] );
%                 else
%                   ISC{end+1} = [j1 j2 j3 k1 k2 k3 P];
%                 end
                
                Is = Is + comb( [k1 k2 k3] , [j1 j2 j3] ) * factorial( J ) * factorial( K - J ) * ...
                              prod( bsxfun( @power , M.xyz( M.tri(:,1) , : ) , [    j1      j2      j3 ] ) , 2 ) .* ...
                              prod( bsxfun( @power , M.xyz( M.tri(:,2) , : ) , [ k1-j1 , k2-j2 , k3-j3 ] ) , 2 ) .* ...
                              sum( N_P .*  (   M.xyz( M.tri(:,1),: ) * ( 1 + J     ) + ...
                                               M.xyz( M.tri(:,2),: ) * ( 1 - J + K ) + ...
                                               M.xyz( M.tri(:,3),: ) * ( 1 + P - K ) ) , 2 );

          end,  end, end

          mo = mo + comb( [p1 p2 p3] , [k1 k2 k3] ) * factorial( P - K ) * Is .* ...
                     prod( bsxfun( @power , M.xyz( M.tri(:,3) , : ) , [ p1-k1 , p2-k2 , p3-k3 ] ) , 2 );
                   
    end,  end,  end

    mo = 2*sum( mo .* A )/( 3 * factorial( P + 3 ) );
    
    function C = comb( P , K )
      C = nchoosek( P(1) , K(1) ) * nchoosek( P(2) , K(2) ) * nchoosek( P(3) , K(3) );
    end
  end

end
