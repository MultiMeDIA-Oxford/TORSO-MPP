function lev=orientation(P)
% function lev=orientation(P)
% P: coordenadas poligono Nx2
% lev: true si orientacion levogira

% if ~iscell(P)
    
       [kk,b]=max(P(:,1));
       a=mod(b-2,size(P,1))+1;
       while isequal(P(a,:),P(b,:))
           a=mod(a-2,size(P,1))+1;
       end;
       c=mod(b,size(P,1))+1;
       while isequal(P(c,:),P(b,:))
           c=mod(c,size(P,1))+1;
       end;
       
       
       points=P([a b c],:);
        
        v=diff(points,1,1)./repmat(sqrt(sum(diff(points,1,1).^2,2)),1,2);
        v=sum(v,1);
        lev=atan2(v(2),v(1))>0;
   