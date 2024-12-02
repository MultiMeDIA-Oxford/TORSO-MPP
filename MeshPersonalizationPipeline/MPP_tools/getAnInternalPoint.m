function p = getAnInternalPoint( V )

  p = mean( V.xyz( V.tri( 1 ,:) ,:) ,1);


%   w = 1:min( 1000 , size(V.tri,1) );
%   F = [ V.tri(w,[2 3 4]) ; V.tri(w,[1 3 4]) ; V.tri(w,[1 2 4]) ; V.tri(w,[1 2 3]) ];
  






%   try
%     M = Mesh(M);
%     while size(M.tri,1) > 1000
%       M = vtkQuadricDecimation( M ,'SetTargetReduction', 1 - 1000/size(M.tri,1) );
%     end
%   end
%   V = tetgen( M );
% 
%   vv = meshQuality( V , 'volume');
%   p = mean( V.xyz( V.tri( argmax(vv) ,:) ,:) ,1);

  
%   faces = [ V.tri(:,[2 3 4]) ; V.tri(:,[1 3 4]) ; V.tri(:,[1 2 4]) ; V.tri(:,[1 2 3]) ]; 
%   
%   faces = sort( faces , 2 );
%   
%   f = 1;
%   while 1
%     F = faces( f , : );
%     if ismember( F , faces( (f+1):end , : ) , 'rows' )
%       break;
%     end
%     f = f+1;
%   end
%   
%   p = ( V.xyz( F(1), : ) + V.xyz( F(2), : ) + V.xyz( F(3), : ) )/3;

end
