function [D,P] = meshGeodesicDistance( M , nodeIDS , algorithm )


  if nargin < 3, algorithm = 'dijstra'; end
  
  
  nV = size( M.xyz ,1);
  D = Inf( 0 , numel(nodeIDS) );
  switch lower(algorithm)
    case {'dijstra'}

      [ES,EL] = meshEdges( M );
      W = sparse( double( ES(:,2) ) , double( ES(:,1) ) , EL , nV , nV );

      nn = numel( nodeIDS );
      for n = 1:nn
        if nn > 20, fprintf('Node %4d of %4d\n',n,nn ); end
        [d,P] = graphshortestpath( W , nodeIDS(n) , 'Directed' , false );
        D( 1:nV ,n) = d.';
      end
      
    case {'poisson','poissonbatch'}
      if meshCelltype( M ) ~= 5, error('this algorithm is only valid for triangle meshes');   end
      

      t = 0.1;
      
      A  = meshQuality( M , 'area' );
      Ac = sparse( double(M.tri) , double(M.tri) , A * [1,1,1] , nV , nV );
      G  = meshGradient( M );
      
      LC = meshLaplaceBeltrami( M );  iLC = inverse( LC );
      U = ( Ac + t * LC );            iU  = inverse( U );

      delta = zeros(nV,1);
      
      if strcmpi( algorithm ,'poisson')
      
        nn = numel( nodeIDS );
        for n = 1:nn
          if nn > 20, fprintf('Node %4d of %4d\n',n,nn ); end

          delta( nodeIDS(n) ) = 1;
          u = iU * delta;
          delta( nodeIDS(n) ) = 0;

          g = reshape( G * u , [],3);
          h = -normalize(g,2);
          thisD = iLC * ( G.' * vec( bsxfun( @times , A , h ) ) );
          thisD = thisD - min( thisD );
          D( 1:nV ,n) = thisD;
        end
        
      elseif strcmpi( algorithm ,'poissonbatch')

          delta( nodeIDS ) = 1;
          u = iU * delta;

          g = reshape( G * u , [],3);
          h = -normalize(g,2);
          D = iLC * ( G.' * vec( bsxfun( @times , A , h ) ) );
          D = D - min( D );
        
      end

    case {'fastmarching','fm'}
  
      W = ones( nV , 1 );
      
      D = perform_geodesic_iterative( M.xyz.' , M.tri.' , W , nodeIDS , [] , 1e3 );
      
    otherwise, error('unknown ALGORITHM');
  end
end




function [ D , err ] = perform_geodesic_iterative(vertex, faces, W, I, D , niter )
% perform_geodesic_iterative - compute the geodesic on a mesh using an iterative scheme
%
%   [U,err ] = perform_geodesic_iterative(vertex, faces, W, I, options , U0 , niter );
%
%   INPUTS:
%   vertex and faces describes a mesh in arbitrary dimension.
%   W(i) is the weight (metric) at vertex indexed by i.
%   I is a list of index of starting points.
%   options.niter is the number of iteration (early quit if
%       convergence is reached)
%   options.U gives an initialization.
%
%   OUTPUT:
%   U(i) is the geodesic distance between point of index i and I.
%   err(k) is norm(U_{k+1}-U_k) where U_k is the solution at iteration k.
%       err should converge to zero.
%
%   Warning: to ensure convergence, options.U should be smaller than the
%   final solution (monotone convergence).
%
%   Copyright (c) 2011 Gabriel Peyre

  dotp = @(u,v)sum(u.*v,1);
  R     = @(u)reshape(u, [1 1 length(u)]);
  Inv1  = @(M,d)[M(2,2,:)./d -M(1,2,:)./d; -M(2,1,:)./d M(1,1,:)./d];
  Inv   = @(M)Inv1(M, M(1,1,:).*M(2,2,:) - M(1,2,:).*M(2,1,:));
  Mult  = @(M,u)[M(1,1,:).*u(1,1,:) + M(1,2,:).*u(2,1,:);  M(2,1,:).*u(1,1,:) + M(2,2,:).*u(2,1,:)];

  nV = size(vertex,2);

  i = [faces(1,:) faces(2,:) faces(3,:) ];
  j = [faces(2,:) faces(3,:) faces(1,:) ];
  k = [faces(3,:) faces(1,:) faces(2,:) ];

  err = [];
  if isempty(D), D = zeros(nV,1); end


  x  = vertex(:,i);
  x1 = vertex(:,j) - x;
  x2 = vertex(:,k) - x;
  % inner product matrix
  C = [ R(dotp(x1,x1)) , R(dotp(x1,x2)) ;...
        R(dotp(x2,x1)) , R(dotp(x2,x2)) ];
  S = Inv(C);

  % a = <S*1,1>
  a = sum(sum(S));

  w = R( W(i) );

  % edge length
  L1 = sqrt(dotp(x1,x1)); L1 = L1(:).*w(:);
  L2 = sqrt(dotp(x2,x2)); L2 = L2(:).*w(:);


  for it = 1:niter
    uj = D(j);
    uk = D(k);
    u = [R(uj); R(uk)];

    % b = <S*1,u>
    b = dotp( sum(S,2), u );
    % c = <S*u,u> - W.^2;
    c = dotp( Mult(S,u) , u ) - w.^2;
    % delta = b^2 - a*c
    delta = max( b.^2 - a.*c, 0);
    % solution
    d = (b + sqrt(delta) )./a;

    % direction of the update
    % g=X*alpha,  alpha = S*(u-d*1)
    alpha = Mult( S, u - repmat(d, 2, 1) );
    J = find( alpha(1,1,:)>0 | alpha(2,1,:)>0 );

    % update along edges

    d1 = L1 + uj(:);
    d2 = L2 + uk(:);
    d = d(:);
    d(J) = min(d1(J), d2(J));

    Du = accumarray( i' , d , [nV 1] , @min );  Du( ~Du ) = Inf;
    % boundary condition
    Du(I) = 0;
    % enforce monotony
    if min(Du-D) < -1e-5
      %  warning('Monotony problem');
    end
    
    err(it) = norm(D-Du, 'fro');
    if err(end) == 0, break; end

    % update
    D = Du;
  end
end