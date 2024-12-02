function [p,v] = intersectionLine( A , B )

  nA = ( cross( A(1:3,1) , A(1:3,2) ) );
  nB = ( cross( B(1:3,1) , B(1:3,2) ) );

  V  = normalize( cross( nA , nB ) );
  v  = ( A(1:3,1:3) \ V(:) ).'; v = v(1:2);
  if v(1) < 0, v = -v; end

  M = ( B \ A );
  p = pinv( [ M(3,1:2) ; v ] ) * [ - M(3,4) ; 0 ]; p = p(1:2).';

%   Ts = [ -p(1)/v(1)                ,...
%          ( A.X(end) - p(1) )/v(1)  ,...
%          -p(2)/v(2)                ,...
%          ( A.Y(end) - p(2) )/v(2) ];
%   Ts = sort( Ts );
% 
%   Tm = ( Ts(1:end-1) + Ts(2:end) )/2;
%   m  = bsxfun( @plus , p , Tm(:)*v );
%   i  = find( m(:,1) >= 0 & m(:,1) <= A.X(end) & m(:,2) >= 0 & m(:,2) <= A.Y(end) , 1 );
% 
%   if isempty( i ), L = []; return; end
%   Ts = Ts([i,i+1]);
%   
%   L = bsxfun( @plus , p , Ts(:)*v );
%   L(:,3) = 0;
%   
%   L = transform( L , A.SpatialTransform );
%   
%   
%   if nargin > 2 && DELTA > 0
%     V = L(2,:) - L(1,:);
%     T = 0:DELTA:sqrt( sum(V.^2) );
%     V = normalize(V);
%     L = bsxfun( @plus , L(1,:) , T(:) * V );
%   end
%   
% 
%   return
% 
%   close all;vline([0,A.X(end)]);hline([0,A.Y(end)]);
%   axis([ -10 , A.X(end)+10 , -10 , A.Y(end)+ 10 ]);
%   axis equal;
% 
%   hL = line( NaN , NaN ,'color','r' );
%   hT = line( NaN , NaN ,'color','k','marker','o','linestyle','none' );
%   hB = line( NaN , NaN ,'color','b','linewidth',2 );
%   h1 = line( NaN , NaN ,'color','k','marker','o','linestyle','none','markerfacecolor','g' );
%   hp = line( 1,1,'color',[0 0 0],'marker','o' ,'markerfacecolor','r','markersize',10);
%   dragableobject( hp , @(h)fun( [ get(h,'XData'),get(h,'YData') ] ) );
% 
% 
%     function fun(p)
%       v = getv( p );
% 
%       t0 = -10;
%       t1 =  20;
% 
%       set( hL , 'XData' , p(1) + [t0;t1]*v(1) ,...
%                 'YData' , p(2) + [t0;t1]*v(2) );
% 
% 
%   tA = -p(1)/v(1);
%   tB = ( A.X(end) - p(1) )/v(1);
%   tC = -p(2)/v(2);
%   tD = ( A.Y(end) - p(2) )/v(2);
%   Ts = sort( [ tA , tB , tC , tD ] );
% 
%       set( hT , 'XData' , p(1) + Ts(:)*v(1) ,...
%                 'YData' , p(2) + Ts(:)*v(2) );
% 
%   Tm = ( Ts(1:end-1) + Ts(2:end) )/2;
%   m = bsxfun( @plus , p , Tm(:)*v );
%   i = find( m(:,1) >= 0 & m(:,1) <= A.X(end) & m(:,2) >= 0 & m(:,2) <= A.Y(end) , 1 );
% 
%   if isempty( i )
%     t0 = NaN; t1 = NaN;
%   else
%     t0 = Ts( i ); t1 = Ts( i+1 );
%   end  
% 
% 
% 
%       set( hB , 'XData' , p(1) + [t0;t1]*v(1) ,...
%                 'YData' , p(2) + [t0;t1]*v(2) );
% 
%   if any( [t0,t1] == tA )
%     t = tA;
%   % elseif any( [t0,t1] == tC )
%   %   t = tC;
%   else
%     t = min([t0,t1]);
%   end
% 
%       set( h1 , 'XData' , p(1) + [t]*v(1) ,...
%                 'YData' , p(2) + [t]*v(2) );
%     end
%     function v = getv( p )
%       v = [ p(2) , -p(1) ];
%       v = normalize( v );
%       if v(1) < 0, v = -v; end
%     end

end
