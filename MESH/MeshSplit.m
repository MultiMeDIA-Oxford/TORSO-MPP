function M = MeshSplit( M , SE )

  if isscalar( SE ) && SE <= 0
    [E,~,A] = meshCellsContact( M );
    M = MeshSplit( M , E( A >= -SE ,:) );
    
    return;
    
  elseif ischar( SE ) && strcmpi( SE , 'nonmanifold' )
    [E,C] = meshCellsContact( M );
    M = MeshSplit( M , E( cellfun('prodofsize',C) > 2 ,:) );
    
    return;
  end


  if isempty( SE )
    return;
  end

  M.celltype = meshCelltype( M );
  
  switch M.celltype
    case 3
      error('not implemented for this celltype yet.');
      
    case 5
      if 0
        rand('seed',0);
        M = struct();
        M.xyz = [ rand(10,2) ];
        M.tri = delaunayn( M.xyz(1:10,:) );
        M.xyz = [ M.xyz ; bsxfun( @minus , rand(5,2) ,[1 0] ) ];
        
        M = MeshReOrderNodes( M , randperm(size(M.xyz,1)) );
        M.tri = [ M.tri ; 2 15 3 ; 4 2 13 ; 3 13 2 ];
        
        
        clf;set(gcf,'Position',[965,49,952,964])
        subplot(211);
        plot3d( M.xyz , 'o1kr7','eq')
        hplotMESH( M , 'textpoint','facealpha',0.2,'td',meshFacesConnectivity(M));
        
        
        SE = [8 4 2 15 14 10];
        % SE = [4 2 15];
        
        hplot3d( M.xyz(SE,:) , 'r2' )
        
        SE = [ SE(1:end-1).' , SE(2:end).' ];
        MM = MeshSplit( M , SE )
        
%         MM = Mesh( MeshRelax( MeshSmooth( MM ,10)  ))
        
        subplot(212);
        plot3d( MM.xyz , 'o1kr7','eq')
        hplotMESH( MM , 'textpoint','facealpha',0.2,'td',meshFacesConnectivity(MM));
        hplotMESH( MeshBoundary(MM) ,'edgecolor','r','linewidth',2)
        
        %%
      end
      
      if size( SE ,2) ~= 2
        error('splitting edges should be n x 2');
      end
      
      T = M.tri;

      nP = size( M.xyz ,1);
      Oid = ( 1:nP ).';

      a = unique( T(:) );
      Oid = Oid( a );
      a( a ) = 1:numel(a);
      T = a(T);
      SE = reshape( a(SE) , size(SE) );


      %%from Alec Jacobson's cut_edges function!!
      nT  = size(T,1);
      nT3 = 3*nT;
      F = reshape( 1:nT3 , nT , 3 );

      allE = sort( [ T(:,[2,3]); T(:,[3,1]); T(:,[1,2]) ] ,2);
      T = double( T(:) );

      [E,~,IC] = unique( allE ,'rows');
      nE = size( E ,1);

      [~,P] = setdiff( E , sort(SE,2) ,'rows');
      if size(P,1) == nE, return; end
      A = sparse( P , P , 1 , nE , nE );
      B = sparse( IC , F , 1 , nE , nT3 );
      C = sparse( F(:,[1,2,3,1,2,3]) , F(:,[2,3,1,3,1,2]) , 1 , nT3 , nT3 );
      D = sparse( F , T , 1 , nT3 , nP );

      G = ( C * ( B.' * A * B ) * C.' )  &  ( D * D.' );
      [~,J] = conncomp(G);

      F = J( F );
      Pid( J ,1) = T;
      %%thanks Alec.

      Pid = Oid( Pid );

      
    case 10
      error('not implemented for this celltype... and maybe it will never be implemented');

  end


  ID  = [ Pid ; setdiff( 1:nP , Pid ).' ];
  ord = zeros( 1 , numel(ID) );
  Z = false( 1 , numel(ID) );
  m = nP;
  for i = 1:numel(ID)
    if Z(ID(i)), m = m + 1; ord(i) = m;
    else,        ord(i) = ID(i);
    end
    Z(ord(i)) = true;
  end
  [~,ord] = sort(ord);
  F = iperm( ord , F );
  ID = ID( ord );
      
  M.tri = F;
  for f = fieldnames( M ).', f = f{1};
    if ~strncmp( f , 'xyz',3), continue; end
    M.(f) = M.(f)( ID ,:);
  end

end

function [S,C] = conncomp(G)
  % CONNCOMP Drop in replacement for graphconncomp.m from the bioinformatics
  % toobox. G is an n by n adjacency matrix, then this identifies the S
  % connected components C. This is also an order of magnitude faster.
  %
  % [S,C] = conncomp(G)
  %
  % Inputs:
  %   G  n by n adjacency matrix
  % Outputs:
  %   S  scalar number of connected components
  %   C  

  % Transpose to match graphconncomp
  G = G';

  [p,q,r] = dmperm(G+speye(size(G)));
  S = numel(r)-1;
  C = cumsum(full(sparse(1,r(1:end-1),1,1,size(G,1))));
  C(p) = C;
end

function [E,A] = inter_faces_angle( M )

  Tid = ( 1:size( M.tri ,1) ).';
  switch meshCelltype( M )
    case 3,
    case 5
      E = [ M.tri(:,[1,2]) , Tid ;...
            M.tri(:,[2,3]) , Tid ;...
            M.tri(:,[1,3]) , Tid ];
          
      E(:,1:2) = sort( E(:,1:2) ,2);
      E = sortrows( E , [1 2] );
      w = find( ~any( diff( E(:,1:2) ,1,1) ,2) );
      E(w,4) = E( w+1 ,3);
      E(w+1,:) = [];
  end
  
  E( ~E(:,end) ,:) = [];
  
  N = meshNormals( M );
  A = 2*asind( fro( N( E(:,3) ,:) - N( E(:,3) ,:) ,2)/2 );
  
  E = E(:,1:end-2);
  
end