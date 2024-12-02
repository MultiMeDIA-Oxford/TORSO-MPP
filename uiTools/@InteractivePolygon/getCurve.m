function xyz = getCurve( IP , invertices )

  vertices = getVertices( IP );
  
  if nargin > 1 , vertices= vertices(invertices,:); end

  IPdata= getappdata( IP.handle , 'InteractivePolygon' );

  if IPdata.spline
    N = 20;
    xyz = [];
    if IPdata.close
      xyz = [ xyz ; bezier( vertices( [end 1:3],: ) , N ) ];
    else
      xyz = [ xyz ; bezier( vertices( [1 1:3],: ) , N ) ];
    end
    for i = 2:size( vertices,1 )-2
      xyz = [ xyz ; bezier( vertices( i-1:i+2,: ) , N ) ];
    end
    if IPdata.close
      xyz = [ xyz ; bezier( vertices( [end-2:end 1 ] ,: ) , N ) ];
      xyz = [ xyz ; bezier( vertices( [end-1 end 1 2] ,: ) , N ) ];
    else
      xyz = [ xyz ; bezier( vertices( [end-2:end end ] ,: ) , N ) ];
    end
  else
    xyz = vertices;
    if IPdata.close
      xyz = [ xyz ; xyz(1,:) ];
    end
  end

  function b = bezier( p , N )
    p1 = p(1,:); p2 = p(2,:); p3 = p(3,:); p4 = p(4,:);
    
    t1 = p1-p2; s1 = norm(t1);
    t2 = p3-p2; s2 = norm(t2);
    if s1 > 0 && s2 > 0
      t2 = t2/s2 - t1/s1; 
      t2 = t2/norm(t2)*min(s1,s2)/2;
    else
      t2 = [0 0 0];
    end
    
    t3 = p2-p3; s3 = norm(t3);
    t4 = p4-p3; s4 = norm(t4);
    if s3 > 0 && s4 > 0
      t3 = t3/s3 - t4/s4;
      t3 = t3/norm(t3)*min(s3,s4)/2;
    else
      t3 = [0 0 0];
    end

    t = linspace( 0 , 1 , N )';
    t = t(1:end-1,:);
    
    b = (1 - t).^3*p2 + 3*t.*(1 - t).^2*(t2+p2) + 3*t.^2.*(1 - t)*(t3+p3) + t.^3*p3;
    
  end
  
  
end
  
% %   slope= [];
% %   if IPdata.close
% %     vertices  = [ vertices ; vertices(1,:) ];
% % %     slope     = vertices(2,:)-vertices(end-1,:);
% % %     slope     = slope';
% % %     slope     = slope/norm(slope);
% %   end
%   if IPdata.spline
% %     d= [0; cumsum( sum(diff(vertices).^2,2) )];
% %     d= 0:size(vertices,1)-1;
% %     xyz = spline( d , [slope vertices' slope] , unique( [linspace(0,d(end),200) d] )  )';
% %     xyz(:,1) = pchip( d , vertices(:,1)' , unique( [linspace(0,d(end),200) d] )  )';
% %     xyz(:,2) = pchip( d , vertices(:,2)' , unique( [linspace(0,d(end),200) d] )  )';
% %     xyz(:,3) = pchip( d , vertices(:,3)' , unique( [linspace(0,d(end),200) d] )  )';
% 
%     if ~IPdata.close
%       p0 = vertices( 1 ,:);
%       p1 = vertices( 2 ,:) - vertices( 1 ,:);
%       p2 = vertices( 1 ,:) - vertices( 3 ,:);
%       p3 = vertices( 2 ,:);
%       xyz = bezier( p0,p1,p2,p3,100 );
%     else
%       p0 = vertices( 1 ,:);
%       p1 = vertices( 2 ,:) - vertices(end,:);
%       p2 = vertices( 1 ,:) - vertices( 3 ,:);
%       p3 = vertices( 2 ,:);
%       xyz = bezier( p0,p1,p2,p3,100 );
%     end
%     for i = 2:size( vertices,1 )-2
%       p0 = vertices( i ,:);
%       p1 = vertices(i+1,:) - vertices(i-1,:);
%       p2 = vertices( i ,:) - vertices(i+2,:);
%       p3 = vertices(i+1,:);
%       xyz = [ xyz ; bezier( p0,p1,p2,p3,100 ) ];
%     end
%     if ~IPdata.close
%       p0 = vertices(end-1,:);
%       p1 = vertices(end,:) - vertices(end-2,:);
%       p2 = vertices(end-1,:) - vertices(end,:);
%       p3 = vertices(end,:);
%       xyz = [ xyz ; bezier( p0,p1,p2,p3,100 ) ];
%     else
%       p0 = vertices(end-1,:);
%       p1 = vertices(end,:) - vertices(end-2,:);
%       p2 = vertices(end-1,:) - vertices(1,:);
%       p3 = vertices(end,:);
%       xyz = [ xyz ; bezier( p0,p1,p2,p3,100 ) ];
% 
%       p0 = vertices(end,:);
%       p1 = vertices(1,:) - vertices(end-1,:);
%       p2 = vertices(end,:) - vertices(2,:);
%       p3 = vertices( 1 ,:);
%       xyz = [ xyz ; bezier( p0,p1,p2,p3,100 ) ; xyz(1,:) ];
%     end
%     
%   else
%     xyz = vertices;
%     if IPdata.close
%       xyz = [ xyz ; xyz(1,:) ];
%     end
%   end
% 
%   function b = bezier( p0,p1,p2,p3, N )
%     t = linspace( 0 , 1 , N )';
%     t = t(1:end-1,:);
%     
%     s = norm( p0 - p3 )/2;
%     p1 = p1/norm(p1)*s; 
%     p2 = p2/norm(p2)*s;
%     
%     b = (1 - t).^3*p0 + 3*t.*(1 - t).^2*(p1+p0) + 3*t.^2.*(1 - t)*(p2+p3) + t.^3*p3;
%   end
%   
%   
% end
% 
