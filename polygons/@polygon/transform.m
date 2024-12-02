function [P,dP,d2P] = transform( P , varargin )

if nargout<3
  [M,dM] = maketransform( varargin{:} );
else
  [M,dM] = maketransform( varargin{:}(1:2) );
  d2M=cell2mat(varargin{:}(3));
end;
  
%   if max( abs( M(3,[1 2 4]) ) ) > 1e-14  ||  max( abs( M([1 2 4],3) ) ) > 1e-14
%     error('a 2D transform is expected');
%   end
 
  if nargout > 1
  dP=cell([size( P.XY , 1 ),1]);    
  d2P=cell([size( P.XY , 1 ),1]); 
    for i = 1:size( P.XY , 1 )
      
    XY = ( P.XY{i,1}  );
%     dP{i} = [ bsxfun( @plus , XY * dM([ 1  5 ],:) , dM(13,:) ) ; ...
%             bsxfun( @plus , XY * dM([ 2  6 ],:) , dM(14,:) ) ];
    index=[1 2 5 6 13 14]';

       dP{i}=kron(eye(2),XY)*comm(2)*dM(index(1:4),:)+kron(dM(index(5:6),:),ones(size(XY,1),1));  
      
       if nargout > 2
        index=index*ones(1,size(d2M,2))+ones(6,1)*(0:16:16*(size(d2M,2)-1));
        d2P{i}=kron(eye(size(d2M,2)),kron(eye(2),XY)*comm(2))*d2M(vec(index(1:4,:)),:)+kron(d2M(vec((index(5:6,:))),:),ones(size(XY,1),1));  

       end;
        
    end;
    
   end;
          
   for i = 1:size( P.XY , 1 )
      P.XY{i,1} = bsxfun( @plus , P.XY{i,1} * M(1:2,1:2).' , M(1:2,4).' );
   end      
          
       

end