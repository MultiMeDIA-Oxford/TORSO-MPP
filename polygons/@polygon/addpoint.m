function B=addpoint(A,est,X,pos);
% B=addpoint(A,est,X,pos);
% A: Poligono
% est: numero de estructura
% pos: posicion en la que se añade
% X: nuevo punto (x,y) a añadir

if est>size(A.XY,1)||est<1
    error('Incorrect number of estructure');
end;
if pos>(size(A.XY{est,1},1)+1)||pos<1
    error('Incorrect position');
end;
B=A;
B.XY{est,1}(1:pos-1,:)=A.XY{est,1}(1:pos-1,:);
B.XY{est,1}(pos,:)=X;
B.XY{est,1}(pos+1:size(A.XY{est,1})+1,:)=A.XY{est,1}(pos:size(A.XY{est,1}),:);
