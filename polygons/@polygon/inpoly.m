function in  = inpoly(X,P)
% function [in, on] = inpolygon(X,P)
% X: coordenadas Nx2
% P: poligono
% in: vector Nx1 Contiene 
%       1 si X esta dentro del poligono
%       0 si X esta sobre el borde del poligono
%      -1 si X esta fuera del poligono

in=zeros(size(X,1),1);
on=zeros(size(X,1),1);
for n=1:size(P.XY,1)
    [i o]=inpolygon(X(:,1),X(:,2),P.XY{n,1}(:,1),P.XY{n,1}(:,2));
    [i o]=inpolygon(X(:,1),X(:,2),P.XY{n,1}(:,1),P.XY{n,1}(:,2));
    on(o)=1;
    in(i)=in(i)+1;
end;
in=(rem(in,2)~=0);
in=2*in-1;
in(find(on))=0;
