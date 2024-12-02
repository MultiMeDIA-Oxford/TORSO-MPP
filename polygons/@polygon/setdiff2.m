function A = setdiff2( A , B )
  
  
  indcA=find(cell2mat(A.XY(:,2))==0);
  CA=polygon(A.XY(indcA,:));
  A.XY(indcA,:)=[];

  indcB=find(cell2mat(B.XY(:,2))==0);
%   CB=polygon(B.XY(indcB,:)); % No las necesito, restar una curva no hace nada (de momento)
  B.XY(indcB,:)=[];
  
  A.XY = polygon_mx( A.XY , B.XY , 'difference' );
   
  for i=1:size(CA.XY,1)
  
              dif1=polygon_mx( solidifycurve(CA.XY{i,1},[1e-6,0]) , B.XY , 'difference' );
              dif2=polygon_mx( solidifycurve(CA.XY{i,1},[0,1e-6]) , B.XY , 'difference' );


              for j=1:size(dif2,1) 

               for k=1:size(dif1,1)
                try
                [c, ia, ib] = intersect(roundn(dif2{j,1},-8),roundn(dif1{k,1},-8),'rows');

                catch
                    keyboard
                end

                if ~isempty(c)
                     curve=dif2{j,1}(sort(ia),:);
                     pini=find(~ismember(curve,CA.XY{:,1},'rows'),2);

                     if (~isempty(pini))
                             if (~isequal(pini,[1 size(curve,1)]'))  % Si no estan ordenados
                                 curve=circshift(curve,-pini(1));
                             end;
                             aux=orientate_polygon(polygon(dif2{j,:}));
                             [kk,loc]=ismember(curve,cell2mat(aux.XY(:,1)),'rows');
                             if ismember(-1,diff(loc,1,1))
                                     curve=flipud(curve);
                             end;

                     end
                    
                    if isequal(CA.XY{i,1}(1,:),CA.XY{i,1}(end,:)) && ...
                    isequal(sort(curve),sort(CA.XY{i,1}(1:end-1,:)))
                            A.XY=[A.XY;{[CA.XY{i,1}],[0]}];
                    else
                            A.XY=[A.XY;{[curve] [0]}];
                    end;
                end;

              end
          
          
          end;
 
  

end