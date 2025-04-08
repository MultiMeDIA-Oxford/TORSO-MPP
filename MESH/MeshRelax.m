function [M,W0] = MeshRelax( M , method )

if 0
M = struct('xyz',[0,0;1,0;1,1;0,1;0.5,0.1;0.9,0.5;0.5,0.9;0.1,0.5],'tri',[1,2,5;2,3,6;3,4,7;4,1,8;5,6,7;5,7,8;1,5,8;5,2,6;6,3,7;7,4,8]);
% M.xyz(5:end,:) = randn(4,2);

M = rand(3500,2); M = Mesh(M,'delaunay');

 plotMESH( M );
hplotMESH( MeshRelax(M,'minenergy') ,'nf','edgecolor','r','marker','o');
hplotMESH( MeshRelax(M,'minlaplacian') ,'nf','edgecolor','g','marker','x');

%%

tic; [Me,We] = MeshRelax(M,'minenergy'); toc
tic; [Ml,Wl] = MeshRelax(M,'minlaplacian'); toc

%%
end
  if nargin < 2, method = 'minEnergy'; end

  if all( isfinite( M.xyz( M.tri ,:) ) )
    
    M = MeshGenerateIDs( M );

    B = MeshTidy( MeshBoundary( M ) );
    f = B.xyzID;
    f = union( f , setdiff( 1:size(M.xyz,1) , M.tri(:) ) );
  
  else
  
    f = find( all( isfinite( M.xyz ) ,2) );

  end
  
  Fxyz = M.xyz(f,:);
  
  
  e = meshEdges( M ); e = double( e );

  nP = size(M.xyz,1);
  nF = size( f ,1);
  Aeq0 = sparse( 1:nF , f , 1 , nF , nP );
  Aeq = [];
  for d = 1:size( M.xyz ,2)
    Aeq = blkdiag( Aeq , Aeq0 );
  end
  beq = vec( M.xyz( f ,:) );

  
  
  switch lower( method )
    case 'minlaplacian'
      W0 = sparse( e(:,1) , e(:,2) , 1 , nP , nP );
      W0 = W0 + W0.';
      W0 = speye( nP ) - bsxfun( @rdivide , W0 , sum( W0 ,2) );
      W0(f,:) = [];
    case 'minenergy'
      nE = size(e,1);
      W0 = sparse( 1:nE , e(:,2) , 1 , nE , nP ) - sparse( 1:nE , e(:,1) , 1 , nE , nP );
  end


  
  W0 = W0.' * W0;
  W = [];
  for d = 1:size( M.xyz ,2)
    W = blkdiag( W , W0 );
  end
  
  sz = size( M.xyz );
  try
%     error('for not using optim toolbox!');
    
    %x =    quadprog( H , f  , A  , b  , Aeq           , beq           ,lb,ub,x0, options )
    M.xyz = quadprog( W , [] , [] , [] , double( Aeq ) , double( beq ) ,[],[],[], optimoptions(@quadprog,'Display','off'));
    
  catch  %for not using optim toolbox!
    
    try
      
      if isempty( which( 'min_quad_with_fixed' ) )
        addpath( 'c:\Dropbox\mTools\thirdParty\gptoolbox-master\matrix\' );
      end
      M.xyz = min_quad_with_fixed( W , [] , [] , [] , double( Aeq ) , double( beq ) );
      
    catch
    
      N = sparse( null( full( Aeq ) ) );
      b0 = Aeq\beq;

      M.xyz = - N * ( ( N.' * W * N ) \ ( N.'*W*b0 ) ) + b0;
      
    end
    
  end
    
  M.xyz = reshape( M.xyz , sz );
  M.xyz( f ,:) = Fxyz;

end