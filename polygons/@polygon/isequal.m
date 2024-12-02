function eq=isequal(A,B)
eq=isempty(polygon_mx( A.XY , B.XY , 'xor')); 
% eq=true;
% if size(A,1)~=size(B,1)
%     eq=false; return;
% else for i=1:size(A,1)
%         if cell2mat(A.XY(i,2))~=cell2mat(B.XY(i,2))
%             eq=false; return;
%         elseif not(isequal(cell2mat(A.XY(i,1)),cell2mat(B.XY(i,1))))
%             eq=false; return;
%         end;
%     end;
% end;