function M = MeshFlatten( M )

  if isnumeric( M )
    if isequal( M( 1 ,:) , M(end,:) )
      M = MeshFlatten( Mesh( M , 'ClosedContour' ) );
      M = M.xyz( [ 1:end , 1 ] ,:);
    else
      M = MeshFlatten( Mesh( M , 'contour' ) );
      M = M.xyz;
    end
    
  	return;
  end

    
    
  celltype = meshCelltype( M );
  switch celltype
    case 3
      if numel( meshSeparate( M ) ) ~= 1
        error('The MESH is a not connected polygon!');
      end
        
      [B,ids] = mesh2contours( M ); ids = ids{1};
      M.xyz( : ,3) = [];
      M.xyz(:) = NaN;

      L = fro( diff(B,1,1) , 2 );
      if isequal( B(1,:) , B(end,:) )

        R = fzero( @(R)2*sum( real(asin(L/(2*R))) ) - 2*pi , sum(L)/(2*pi) );

        t = cumsum( [ 0 ; asin( L/(2*R) ) ]*2 );
        t = t / ( t(end) / (2*pi) );

        M.xyz( ids ,:) = R * [ cos(t) , sin(t) ];
      
      else
        
        M.xyz( ids ,1) = cumsum( [ 0 ; L ] );
        M.xyz(:,2) = 0;
        
      end
  
    case 5
      method = 'lscm';
      switch lower( method )
        case {'relax'}
          B = MeshFlatten( MeshBoundary( M ) );
          M.xyz = B.xyz;
          M = MeshRelax( M );

        case {'lscm'}
          B = MeshTidy( MeshFlatten( MeshBoundary( MeshGenerateIDs( M ,'xyz' ) ) ) );
          
          Wstate = warning( 'off' , 'MATLAB:singularMatrix' ); onCLEAN = onCleanup( @()warning(Wstate) );
          
          M.xyz = lscm( M.xyz , double( M.tri ) , B.xyzID(:).' , B.xyz );
          
      end
    
  end
  
end



function [U,Q] = lscm(V,F,b,bc,Aeq,Beq,varargin)
  % LSCM Compute Least Squares Conformal Mapping for mesh
  %
  % U = lscm(V,F,b,bc)
  % U = lscm(V,F,b,bc,Aeq,Beq)
  %
  % Inputs:
  %   V  #V by dim list of rest domain positions
  %   F  #F by 3 list of triangle indices into V
  %   b  #b list of indices of constraint (boundary) vertices
  %   bc  #b by 2 list of constraint positions for b
  %   Aeq   #Aeq by 2*#V matrix of linear equality constraints {[]}
  %   Beq   #Aeq vector of linear equality constraint right-hand sides {[]}
  %   Optional:
  %     'Method' followed by one of the following:
  %        'desbrun'  "Intrinsic Parameterizations of Surface Meshes" [Desbrun
  %          et al. 2002]
  %        'levy'  "Least Squares Conformal Maps for Automatic Texture Atlas
  %          Generation" [Lévy et al. 2002]
  %        {'mullen'}  "Spectral Conformal Parameterization" [Mullen et al. 2008]
  % Outputs:
  %   U  #V by 2 list of new positions
  %   Q  #V*2 by #*2  quadratic coefficients matrix
  %
  % Note: This is the same system as takeo_asap up to a factor of 2.5
  %
  % See also: arap, takeo_arap, takeo_asap
  %


  method = 'mullen';
  % default values
  % Map of parameter names to variable names
  params_to_variables = containers.Map( ...
    {'Method'}, ...
    {'method'});
  v = 1;
  while v <= numel(varargin)
    param_name = varargin{v};
    if isKey(params_to_variables,param_name)
      assert(v+1<=numel(varargin));
      v = v+1;
      % Trick: use feval on anonymous function to use assignin to this workspace
      feval(@()assignin('caller',params_to_variables(param_name),varargin{v}));
    else
      error('Unsupported parameter: %s',varargin{v});
    end
    v=v+1;
  end


  if nargin<=4
    Aeq = [];
    Beq = [];
  end
  
  % number of vertices
  n = size(V,1);
  % number of triangles
  nt = size(F,1);
  % number of original dimensions
  dim = size(V,2);

  switch method
  case 'levy'
    % first need to convert each triangle to its orthonormal basis, if coming
    % from 3D
    assert(dim == 2);
  
    %% Indices of each triangle vertex, I, and its corresponding two neighbors, J
    %% and K
    %I = [F(:,1)];
    %J = [F(:,2)];
    %K = [F(:,3)];
  
    %X = [V(I,1) V(J,1) V(K,1)];
    %Y = [V(I,2) V(J,2) V(K,2)];
  
    %WRe = [X(:,3)-X(:,2) X(:,1)-X(:,3) X(:,2)-X(:,1)];
    %WIm = [Y(:,3)-Y(:,2) Y(:,1)-Y(:,3) Y(:,2)-Y(:,1)];
  
    %% sqrt root of twice the area of each triangle
    %dT = sqrt(doublearea(V,F));
  
    %% build M matrix, real and imaginary parts
    %II = [1:nt 1:nt 1:nt];
    %JJ = [I;J;K]';
    %VVRe = [WRe(:,1)./dT WRe(:,2)./dT WRe(:,3)./dT];
    %VVIm = [WIm(:,1)./dT WIm(:,2)./dT WIm(:,3)./dT];
  
    %WWRe = sparse(II,JJ,WRe,nt,n);
    %WWIm = sparse(II,JJ,WIm,nt,n);
    %% These look like blocks in the gradient matrix
    %MRe = sparse(II,JJ,VVRe,nt,n);
    %MIm = sparse(II,JJ,VVIm,nt,n);
  
    %% build A matrix
    %A = [MRe -MIm; MIm MRe];
  
    %% quadratic system matrix
    %Q = A'*A;
  
    % Or equivalently
  
    % compute gradient matrix
    G = grad(V,F);
  
    % Extract each coordinate's block
    Gx = G(1:nt,:);
    Gy = G(nt+(1:nt),:);
  
    % Triangle areas
    TA = repdiag(diag(sparse(doublearea(V,F))/2),2);
  
    % Build quadratic coefficients matrix
    Q = [Gx -Gy;Gy Gx]'*TA*[Gx -Gy;Gy Gx];
  
    % solve
    U = min_quad_with_fixed(Q,zeros(2*n,1),[b b+n],bc(:));
    % reshape into columns
    U = reshape(U,n,2);
  case 'mullen'
    A = vector_area_matrix(F);
    L = repdiag(cotmatrix(V,F),2);
    Q = -L - 2*A;
    U = min_quad_with_fixed(Q,zeros(2*n,1),[b b+n],bc(:),Aeq,Beq);
    % reshape into columns
    U = reshape(U,n,2);
  case 'desbrun'
    error('not implemented.');
    % This implements the Dirichlet + Chi energies but usually when people
    % refer to the [Desbrun et al. 2002] paper they mean the [Mullen et
    % al. 2008] interpretation: zero chi energy + ""natural"" boundary
    % conditions.
    lambda = 1;
    mu = 1;
    L = cotmatrix(V,F);
    % chi energy
    C = cotangent(V,F);
    l = edge_lengths(V,F);
    X = sparse( ...
      F(:,[1 2 3 1 2 3]), ...
      F(:,[2 3 1 3 1 2]), ...
      C(:,[2 3 1 3 1 2])./ ...
      l(:,[3 1 2 2 3 1]), ...
      size(V,1),size(V,1));
    Q = repdiag(lambda*L+mu*X,2);
  otherwise
    error('unsupported method: %s',method);
  end
end
function A = vector_area_matrix(F)
  % Constructs the symmetric area matrix A, s.t.  V(:)' * A * V(:) is the
  % **vector area** of the mesh (V,F).
  %
  % A = vector_area_matrix(F)
  %
  % Inputs:
  %   F  #F by 3 list of mesh faces (must be triangles)
  % Outputs:
  %   A  #Vx2 by #Vx2 area matrix
  %

  % number of vertices
  n = max(F(:));
  O = outline(F);
  % Vector area is ∫ 1 dA = ½∫∇⋅x dA
  % Apply divergence theorm ½∮ x⋅n dx
  % For a discrete (planar) surface with boundary, this is 
  %
  % ½   ∑    ∫{ij} n⋅x dx
  %  {ij}∈∂Ω 
  % 
  % Since the normal is constant along the edge use first order quadrature
  % rules:
  %
  % ½  ∑     [vi - vj]⟂ [vi + vj]/2
  %  {ij}∈∂Ω
  %
  A = sparse( ...
    [O;O(:,[2 1])+n],[O(:,[2 1])+n;O],repmat([1 -1]/4,size(O,1)*2,1),2*n,2*n);
end
function [O] = outline(F)
  % OUTLINE Find outline (boundary) edges of mesh
  %
  % [O] = outline(F)
  % 
  % Input:
  %  F  #F by polysize face list of indices
  % Output:
  %  O  #O by 2 list of outline edges
  %
  % Example:
  %   [V,F] = create_regular_grid(17,17,0,0);
  %   [O] = outline(F);
  %   % extract unique vertex indices on outline
  %   [u,m,n] = unique(O(:));
  %   % original map O = IM(O)
  %   IM = 1:size(V,1);
  %   IM(O(:)) = n;
  %   % list of vertex positions of outline
  %   OV = V(u,:);
  %   % list of edges in OV 
  %   OE = IM(O);
  %   tsurf(F,V);
  %   hold on;
  %   plot( ...
  %     [OV(OE(:,1),1) OV(OE(:,2),1)]', ...
  %     [OV(OE(:,1),2) OV(OE(:,2),2)]', ...
  %     '-','LineWidth',5);
  %   hold off;
  %

  %%
  %% This does not maintain original order
  %%
  %% Find all edges in mesh, note internal edges are repeated
  %E = sort([F(:,1) F(:,2); F(:,2) F(:,3); F(:,3) F(:,1)]')';
  %% determine uniqueness of edges
  %[u,m,n] = unique(E,'rows');
  %% determine counts for each unique edge
  %counts = accumarray(n(:), 1);
  %% extract edges that only occurred once
  %O = u(counts==1,:);

  % build directed adjacency matrix
  A = sparse(F,F(:,[2:end 1]),1);
  % Find single occurance edges
  [OI,OJ,OV] = find(A-A');
  % Maintain direction
  O = [OI(OV>0) OJ(OV>0)];%;OJ(OV<0) OI(OV<0)];

end
function L = cotmatrix(V,F)
  % COTMATRIX computes cotangent matrix (laplacian mesh operator), (mass/area
  % terms already cancelled out)
  %
  % L = cotmatrix(V,F)
  % L = cotmatrix(V,T)
  %
  % For size(F,2)==4, This is distinctly NOT following definition that appears
  % in the appendix of: ``Interactive Topology-aware Surface Reconstruction,''
  % by Sharf, A. et al
  % http://www.cs.bgu.ac.il/~asharf/Projects/InSuRe/Insure_siggraph_final.pdf
  %
  % Instead it is a purely geometric construction. Find more details in Section
  % 1.1 of "Algorithms and Interfaces for Real-Time Deformation of 2D and 3D
  % shapes" [Jacobson 2013]
  %
  % ND derivation given in "A MONOTONE FINITE ELEMENT SCHEME FOR
  % CONVECTION-DIFFUSION EQUATIONS" [Xu & ZIKATANOV 1999]
  %
  % 3D derivation given in "Aspects of unstructured grids and finite-volume
  % solvers for the Euler and Navier-Stokes equations" [Barth 1992]
  %
  %
  % Inputs:
  %   V  #V x dim matrix of vertex coordinates
  %   F  #F x simplex-size matrix of indices of triangle or tetrahedron corners
  % Outputs:
  %   L  sparse #V x #V matrix of cot weights 
  %
  % Copyright 2011, Alec Jacobson (jacobson@inf.ethz.ch), Denis Zorin
  %
  % See also: cotangent
  %

  ss = size(F,2);
  switch ss
  case 3
    %% Could just replace everything with:
    %C = cotangent(V,F);
    %L = sparse(F(:,[2 3 1]), F(:,[3 1 2]), C,size(V,1),size(V,1));
    %L = L+L';
    %L = L-diag(sum(L,2));
    
    % should change code below, so we don't need this transpose
    if(size(F,1) == 3)
      warning('F seems to be 3 by #F, it should be #F by 3');
    end
    F = F';

    % renaming indices of vertices of triangles for convenience
    i1 = F(1,:); i2 = F(2,:); i3 = F(3,:); 
    % #F x 3 matrices of triangle edge vectors, named after opposite vertices
    v1 = V(i3,:) - V(i2,:);  v2 = V(i1,:) - V(i3,:); v3 = V(i2,:) - V(i1,:);
    % computing *unsigned* areas 
    if size(V,2) == 2
        % 2d vertex data
        dblA = abs(v1(:,1).*v2(:,2)-v1(:,2).*v2(:,1));
    elseif size(V,2) == 3
        %n  = cross(v1,v2,2);  dblA  = multinorm(n,2);

        % area of parallelogram is twice area of triangle
        % area of parallelogram is || v1 x v2 || 
        n  = cross(v1,v2,2); 
        % THIS DOES MATRIX NORM!!! don't use it!!
        % dblA  = norm(n,2);

        % This does correct l2 norm of rows
        dblA = (sqrt(sum((n').^2)))';
    else 
        error('unsupported vertex dimension %d', size(V,2))
    end
    % cotangents and diagonal entries for element matrices
    cot12 = -dot(v1,v2,2)./dblA/2; cot23 = -dot(v2,v3,2)./dblA/2; cot31 = -dot(v3,v1,2)./dblA/2;
    % diag entries computed from the condition that rows of the matrix sum up to 1
    % (follows from  the element matrix formula E_{ij} = (v_i dot v_j)/4/A )
    diag1 = -cot12-cot31; diag2 = -cot12-cot23; diag3 = -cot31-cot23;
    % indices of nonzero elements in the matrix for sparse() constructor
    i = [i1 i2 i2 i3 i3 i1  i1 i2 i3];
    j = [i2 i1 i3 i2 i1 i3  i1 i2 i3];
    % values corresponding to pairs form (i,j)
    v = [cot12 cot12 cot23 cot23 cot31 cot31 diag1 diag2 diag3];
    % for repeated indices (i,j) sparse automatically sums up elements, as we
    % want
    L = sparse(i,j,v,size(V,1),size(V,1));
  case 4
    if(size(F,1) == 4 && size(F,2) ~=4)
      warning('F seems to be 4 by #F, it should be #F by 4');
    end
    % number of mesh vertices
    n = size(V,1);
    % cotangents of dihedral angles
    C = cotangent(V,F);
    %% TODO: fix cotangent to have better accuracy so this isn't necessary
    %% Zero-out almost zeros to help sparsity
    %C(abs(C)<10*eps) = 0;
    % add to entries
    L = sparse(F(:,[2 3 1 4 4 4]),F(:,[3 1 2 1 2 3]),C,n,n);
    % add in other direction
    L = L + L';
    % diagonal is minus sum of offdiagonal entries
    L = L - diag(sum(L,2));
    %% divide by factor so that regular grid laplacian matches finite-difference
    %% laplacian in interior
    %L = L./(4+2/3*sqrt(3));
    %% multiply by factor so that matches legacy laplacian in sign and
    %% "off-by-factor-of-two-ness"
    %L = L*0.5;
    % flip sign to match cotmatix.m
    if(all(diag(L)>0))
      warning('Flipping sign of cotmatrix3, so that diag is negative');
      L = -L;
    end
  end
end
function B = repdiag(A,d)
  % REPDIAG repeat a matrix along the diagonal a certain number of times, so
  % that if A is a m by n matrix and we want to repeat along the diagonal d
  % times, we get a m*d by n*d matrix B such that:
  % B( (k*m+1):(k*m+1+m-1), (k*n+1):(k*n+1+n-1)) = A 
  % for k from 0 to d-1
  %
  % B = repdiag(A,d)
  %
  % Inputs:
  %   A  m by n matrix we are repeating along the diagonal. May be dense or
  %     sparse
  %   d  number of times to repeat A along the diagonal
  % Outputs:
  %   B  m*d by n*d matrix with A repeated d times along the diagonal,
  %     will be dense or sparse to match A
  %
  % See also: kroneye
  %

  %m = size(A,1);
  %n = size(A,2);
  %if(issparse(A))
  %  [I,J,V] = find(A);
  %  BI = I;
  %  BJ = J;
  %  BV = V;
  %  for k = 2:d
  %    BI = [BI (k-1)*m+I];
  %    BJ = [BJ (k-1)*n+J];
  %    BV = [BV V];
  %  end
  %  B = sparse(BI,BJ,BV,m*d,n*d);
  %else
  %  B = zeros(m*d,n*d);
  %  for k = 0:(d-1)
  %    B( (k*m+1):(k*m+1+m-1), (k*n+1):(k*n+1+n-1)) = A;
  %  end
  %end

  % http://www.physicsforums.com/showthread.php?t=77645
  % Also slow:
  % B = kron(speye(d),A);
  % 10x faster than for loop IJV
  C = cell(d,1);
  [C{:}] = deal(A);
  B = blkdiag(C{:});


end
function [Z,F,Lambda,Lambda_known] = min_quad_with_fixed(A,B,known,Y,Aeq,Beq,F)
  % MIN_QUAD_WITH_FIXED Minimize quadratic energy Z'*A*Z + Z'*B + C with
  % constraints that Z(known) = Y, optionally also subject to the constraints
  % Aeq*Z = Beq
  % http://www.alecjacobson.com/weblog/?p=1913
  % http://www.alecjacobson.com/weblog/?p=2491
  %
  % [Z,F] = min_quad_with_fixed(A,B,known,Y)
  % [Z,F,Lambda,Lambda_known] = min_quad_with_fixed(A,B,known,Y,Aeq,Beq,F)
  %
  % Inputs:
  %   A  n by n matrix of quadratic coefficients
  %   B  n by 1 column of linear coefficients, if empty then assumed B = 0
  %   known  #known list of indices to known rows in Z
  %   Y  #known by cols list of fixed values corresponding to known rows in Z
  %   Optional:
  %     Aeq  m by n list of linear equality constraint coefficients
  %     Beq  m by 1 list of linear equality constraint constant values, if
  %       empty then assumed Beq = 0
  %     F see output
  % Outputs:
  %   Z  n by cols solution
  %   Optional:
  %     F  struct containing all information necessary to solve a prefactored
  %     system touching only B, Y, and optionally Beq
  %     Lambda  m list of values of lagrange multipliers corresponding to each
  %       row in Aeq
  %     Lambda_known  m list of values of lagrange multipliers corresponding to each
  %       known value
  %
  % Troubleshooting:
  %   'Warning: Matrix is singular to working precision' A number of things can
  %   cause this to happen:
  %     (1) Your system matrix A after removing knowns is not full rank, check
  %     condest of A and rank of A
  %     (2) Some constraints in Aeq are linearly dependent (after removing
  %     known values), check SVD of Aeq
  %   "My hessian should be symmetric, positive definite but I see that lu is
  %     being used". Check (1) and (2) above, and:
  %     (3) be sure you giving A and not accidentally -A, which would be
  %     negative definite.
  %   "My constraints are not satisfied. That is, some abs(Aeq * Z - Beq) are
  %     not zero." In the output, check F.Aeq_li. If this is false then
  %     according to QR decomposition your constraints are linearly dependent.
  %     Check that your constraints are not conflicting.  Redundant or linearly
  %     dependent constraints **equations** (including rhs) should be OK, but
  %     linearly dependent rows in Aeq with mismatching rows in Beq mean
  %     there's a conflict.
  %     
  %
  %
  % Example:
  %   % one-linear to use pcg with same prototype:
  %   min_quad_with_fixed_pcg = @(A,B,known,Y,tol,iter,fun) ...
  %     full(sparse( ...
  %       [setdiff((1:size(A,1))',known(:));known(:)],1, ...
  %       [pcg( ...
  %         A(setdiff(1:end,known),setdiff(1:end,known)), ...
  %         -(A(setdiff(1:end,known),known) * Y) - ...
  %         0.5*B(setdiff(1:end,known)),tol,iter);bc]));

  % Implementation details:
  % minimize x'Ax + x'B
  % subject to Aeq x = Beq
  %
  % This is the same as:
  % find the saddle point of x'Ax + x'B + lambda' * (Aeq * x  - Beq)
  % where lambda is a vector of lagrange multipliers, one for each of the
  % constraints (rows in Aeq)
  %
  % Then we rewrite this, combining x and lambda:
  % [x; lambda]' * [A Aeq';Aeq Z] * [x; lambda] + [x; lambda]' * [B; -2*Beq]
  %
  % Notice the -2 because lamba' * Aeq * x shows up twice in the quadratic part.
  % Then I can differentiate with respect to [x; lambda] and we get:
  % 2*[A Aeq';Aeq Z] * [x; lambda] + [B; -2*Beq]
  
  % Setting that to zero and moving the knowns to the right hand side we get:
  % [A Aeq';Aeq Z] * [x; lambda] = -0.5 * [B; -2*Beq]
  
  if nargin < 4
    Y = [];
    known = [];
  end
  if nargin < 6
    Aeq = [];
    Beq = [];
  end
  % treat empty Beq as column of zeros to match Aeq
  if isempty(Beq)
    Beq = zeros(size(Aeq,1),1);
  end
  if nargin < 7
    F = [];
  end
  
  if isempty(F) || ~isfield(F,'precomputed') || F.precomputed == false
%     if ~isempty(F)
%       warning('Precomputing');
%     end
    F = precompute(A,known,Aeq,F);
  end
  [Z,Lambda,Lambda_known] = solve(F,B,Y,Beq);

  % !!SHOULD REMOVE F AS INPUT PARAM!!
  function F = precompute(A,known,Aeq,F)
    % PRECOMPUTE perform any necessary precomputation of system including
    % factorization and preparation of right-hand side
    % 
    % F = precompute(A,known,Aeq)
    %
    % Inputs:
    %   A  n by n matrix of quadratic coefficients
    %   known  #known list of indices to known rows in Z
    %   Optional:
    %     Aeq  m by n list of linear equality constraint coefficients
    % Outputs:
    %   F  struct containing all information necessary to solve a prefactored
    %   system touching only B, Y, and optionally Beq

    % number of rows
    n = size(A,1);
    % cache problem size
    F.n = n;

    if isempty(Aeq)
      Aeq = zeros(0,n);
    end

    assert(size(A,1) == n, ...
      'Rows of system matrix (%d) != problem size (%d)',size(A,1),n);
    assert(size(A,2) == n, ...
      'Columns of system matrix (%d) != problem size (%d)',size(A,2),n);
    assert(isempty(known) || min(size(known))==1, ...
      'known indices (size: %d %d) not a 1D list',size(known));
    assert(isempty(known) || min(known) >= 1, ...
      'known indices (%d) < 1',min(known));
    assert(isempty(known) || max(known) <= n, ...
      'known indices (%d) > problem size (%d)',max(known),n);
    assert(n == size(Aeq,2), ...
      'Columns of linear constraints (%d) != problem size (%d)',size(Aeq,2),n);

    % cache known
    F.known = known;
    % get list of unknown variables including lagrange multipliers
    F.unknown = find(~sparse(1,known,true,1,n));

    Auu = A(F.unknown,F.unknown);
    % note that columns are in *original* order
    F.Ak = A(F.known,:);


    % determine if A(unknown,unknown) is symmetric and/or postive definite
    sym_measure = max(max(abs(Auu - Auu')))/max(max(abs(Auu)));
    %sym_measure = normest(Auu-Auu')./normest(Auu);
    if sym_measure > eps
      % not very symmetric
      F.Auu_sym = false;
    elseif sym_measure > 0
      % nearly symmetric but not perfectly
      F.Auu_sym = true;
    else
      
      % Either Auu is empty or sym_measure should be perfect
      assert(isempty(sym_measure) || sym_measure == 0 || max(max(abs(Auu))) == 0,'not symmetric');
      % Perfectly symmetric
      F.Auu_sym = true;
    end

    % check if there are blank constraints
    F.blank_eq = ~any(Aeq(:,F.unknown),2);
    if any(F.blank_eq)
      warning('min_quad_with_fixed:blank_eq', [ ...
        'Removing blank constraints. ' ...
        'You ought to verify that known values satisfy contsraints']);
      Aeq = Aeq(~F.blank_eq,:);
    end
    % number of linear equality constraints
    neq = size(Aeq,1);
    %assert(neq <= n,'Number of constraints (%d) > problem size (%d)',neq,n);

    % Determine if positive definite (also compute cholesky decomposition if it
    % is as a side effect)
    F.Auu_pd = false;
    if F.Auu_sym && neq == 0
      % F.S'*Auu*F.S = F.L*F.L'
      if issparse(Auu)
        [F.L,p,F.S] = chol(Auu,'lower');
      else
        [F.L,p] = chol(Auu,'lower');
        F.S = eye(size(F.L));
      end
      F.Auu_pd = p==0;
    end

    % keep track of whether original A was sparse
    A_sparse = issparse(A);

    % Determine number of linearly independent constraints
    if neq > 1 && ~(isfield(F,'force_Aeq_li') && ~isempty(F.force_Aeq_li)&& F.force_Aeq_li)
      %tic;
      % Null space substitution with QR
      [AeqTQ,AeqTR,AeqTE] = qr(Aeq(:,F.unknown)');
      nc = find(any(AeqTR,2),1,'last');
      if isempty(nc)
        nc = 0;
      end
      %fprintf('QR: %g secs\n',toc);
      assert(nc<=neq);
      F.Aeq_li = nc == neq;
    else
      F.Aeq_li = true;
    end
    if neq > 0 && isfield(F,'force_Aeq_li') && ~isempty(F.force_Aeq_li)
      F.Aeq_li = F.force_Aeq_li;
    end
    
    % Use raw Lagrange Multiplier method only if rows of Aeq are Linearly
    % Independent
    if F.Aeq_li
      % get list of lagrange multiplier indices
      F.lagrange = n+(1:neq);
      if neq > 0
        if issparse(A) && ~issparse(Aeq)
          warning('min_quad_with_fixed:sparse_system_dense_constraints', ...
          'System is sparse but constraints are not, solve will be dense');
        end
        if issparse(Aeq) && ~issparse(A)
          warning('min_quad_with_fixed:dense_system_sparse_constraints', ...
          'Constraints are sparse but system is not, solve will be dense');
        end
        Z = sparse(neq,neq);
        % append lagrange multiplier quadratic terms
        A = [A Aeq';Aeq Z];
        %assert(~issparse(Aeq) || A_sparse == issparse(A));
      end
      % precompute RHS builders
      F.preY = A([F.unknown F.lagrange],known) + ...
        A(known,[F.unknown F.lagrange])';

      % LDL has a different solve prototype
      F.ldl = false;
      % create factorization
      if F.Auu_sym
        if neq == 0 && F.Auu_pd
          % we already have F.L
          F.U = F.L';
          F.P = F.S';
          F.Q = F.S;
        else
          % LDL is faster than LU for moderate #constraints < #unknowns
          NA = A([F.unknown F.lagrange],[F.unknown F.lagrange]);
          assert(issparse(NA));
          [F.L,F.D,F.P,F.S] = ldl(NA);
          F.ldl = true;
        end
      else
        NA = A([F.unknown F.lagrange],[F.unknown F.lagrange]);
        % LU factorization of NA
        if issparse(NA)
          [F.L,F.U,F.P,F.Q] = lu(NA);
        else
          [F.L,F.U] = lu(NA);
          F.P = 1;
          F.Q = 1;
        end
      end
    else
      % We alread have CTQ,CTR,CTE
      %tic;
      % Aeq' * AeqTE = AeqTQ * AeqTR
      % AeqTE' * Aeq = AeqTR' * AeqTQ'
      % Aeq x = Beq
      % Aeq (Q2 lambda + lambda_0) = Beq
      % we know Aeq Q2 = 0 --> Aeq Q2 lambda = 0
      % Aeq lambda_0 = Beq
      % AeqTE' * Aeq lambda_0 = AeqTE' * Beq
      % AeqTR' * AeqTQ' lambda_0 = AeqTE' * Beq
      % AeqTQ' lambda_0 = AeqTR' \ (AeqTE' * Beq)
      % lambda_0 = AeqTQ * (AeqTR' \ (AeqTE' * Beq))
      % lambda_0 = Aeq \ Beq;
      % lambda_0 = AeqTQ * (AeqTR' \ (AeqTE' * Beq));
      AeqTQ1 = AeqTQ(:,1:nc);
      AeqTR1 = AeqTR(1:nc,:);
      %lambda_0 = [AeqTQ1 * (AeqTR1' \ (AeqTE' * Beq))];
      %fprintf('lambda_0: %g secs\n',toc);
      %tic;
      % Substitute x = Q2 lambda + lambda_0
      % min 0.5 x' A x - x' b
      %   results in A x = b
      % min 0.5 (Q2 lambda + lambda_0)' A (Q2 lambda + lambda_0) - (Q2 lambda + lambda_0)' b
      % min 0.5 lambda' Q2' A Q2 lambda + lambda Q2' A lambda_0 - lambda Q2' b 
      %  results in Q2' A Q2 lambda = - Q2' A lambda_0 + Q2' b
      AeqTQ2 = AeqTQ(:,(nc+1):end);
      QRAuu =  AeqTQ2' * Auu * AeqTQ2;
      %QRb = -AeqTQ2' * Auu * lambda_0 + AeqTQ2' * b;
      % precompute RHS builders
      F.preY = A(F.unknown,known) + A(known,F.unknown)';
      %fprintf('Proj: %g secs\n',toc);
      %tic;
      % QRA seems to be PSD
      [F.L,p,F.S] = chol(QRAuu,'lower');
      F.U = F.L';
      F.P = F.S';
      F.Q = F.S;
      %fprintf('Chol: %g secs\n',toc);
      % Perhaps if Auu is not PD then we need to use LDL...
      assert(p==0);
      % WHICH OF THESE ARE REALLY NECESSARY?
      F.Aeq = Aeq;
      F.AeqTQ2 = AeqTQ2;
      F.AeqTQ1 = AeqTQ1;
      F.AeqTR1 = AeqTR1;
      F.AeqTE = AeqTE;
      F.Auu = Auu;
    end
    F.precomputed = true;
  end

  function [Z,Lambda,Lambda_known] = solve(F,B,Y,Beq)
    % SOLVE  perform solve using precomputation and parameters for building
    % right-hand side that are allowed to change without changing precomputation
    %
    % Z = solve(F,B,Y,Beq)
    %
    % Inputs:
    %   F  struct containing all information necessary to solve a prefactored
    %     system touching only B, Y, and optionally Beq
    %   B  n by 1 column of linear coefficients
    %   Y  #known by cols list of fixed values corresponding to known rows in Z
    %   Optional:
    %     Beq  m by 1 list of linear equality constraint constant values
    % Outputs:
    %   Z  n by cols solution
    %   Lambda  m by cols list of lagrange multiplier *values*
    %   Lambda_known  #known by cols list of lagrange multiplier *values* for
    %     known variables
    %

    % number of known rows
    kr = numel(F.known);
    if kr == 0
      assert(isempty(Y),'Known values should not be empty');
      % force Y to have 1 column even if empty
      if size(Y,2) == 0
        Y = zeros(0,1);
      end
    end
    assert(kr == size(Y,1), ...
      'Number of knowns (%d) != rows in known values (%d)',kr, size(Y,1));
    if isempty(Y)
      % use linear coefficients to determine cols
      if isempty(B)
        if isempty(Beq)
          cols = 1;
          Beq = zeros(0,cols);
        else
          cols = size(Beq,2);
        end
        B = zeros(F.n,cols);
      else
        cols = size(B,2);
      end
      Y = zeros(0,cols);
    else
      cols = size(Y,2);
      if isempty(B)
        B = zeros(F.n,cols);
      end
    end

    if any(F.blank_eq)
      Beq = Beq(~F.blank_eq,:);
    end


    % Build system's rhs
    if F.Aeq_li
      % number of lagrange multipliers aka linear equality constraints
      neq = numel(F.lagrange);
      if neq == 0
        assert(isempty(Beq),'Constraint right-hand sides should not be empty');
        Beq = zeros(0,1);
      end

      NB = ...
        bsxfun(@plus, ...
          bsxfun(@plus,  ...
            F.preY * Y,  ...
            [B(F.unknown,:); zeros(numel(F.lagrange),size(B,2))]), ...
          [zeros(numel(F.unknown),size(Beq,2)); -2*Beq(F.lagrange-F.n,:)]);
          

      % prepare solution
      Z = zeros(F.n+neq,cols);
      Z(F.known,:) = Y;

      if F.ldl
        Z([F.unknown F.lagrange],:) = ...
          -0.5 * F.S * (F.P * (F.L'\(F.D\(F.L\(F.P' * (F.S * NB))))));
      else
        Z([F.unknown F.lagrange],:) = -0.5 * F.Q * (F.U \ (F.L \ ( F.P * NB)));
      end

      % fix any removed constraints (set Lambda to 0)
      Lambda = zeros(numel(F.blank_eq),cols);
      if neq ~= 0
        % save lagrange multipliers
        Lambda(~F.blank_eq,:) = Z(F.lagrange,:);
        % throw away lagrange multipliers
        Z = Z(1:(end-neq),:);
      end
    else
      % Adjust Aeq rhs to include known parts
      Beq = -F.Aeq(:,known)*Y + Beq;
      % Where did this -0.5 come from? Probably the same place as above.
      NB = -0.5*(B(F.unknown,:) + F.preY * Y);
      eff_Beq = F.AeqTE' * Beq;
      % can't solve rectangular system: trim (expects that constraints are not
      % contradictory)
      AeqTR1T = F.AeqTR1';
      AeqTR1T = AeqTR1T(1:size(F.AeqTQ1,2),1:size(F.AeqTQ1,2));
      eff_Beq = eff_Beq(1:size(F.AeqTQ1,2));
      lambda_0 = F.AeqTQ1 * (AeqTR1T \ eff_Beq);
      QRB = -F.AeqTQ2' * (F.Auu * lambda_0) + F.AeqTQ2' * NB;
      lambda = F.Q * (F.U \ (F.L \ ( F.P * QRB)));
      % prepare solution
      Z = zeros(F.n,cols);
      Z(F.known,:) = Y;
      Z(F.unknown) = F.AeqTQ2 * lambda + lambda_0;
      Aequ = F.Aeq(:,F.unknown);
      % http://www.math.uh.edu/~rohop/fall_06/Chapter3.pdf
      %Lambda = (F.AeqTQ1' * Aequ') \ (F.AeqTQ1' * NB - F.AeqTQ1' * F.Auu * Z(F.unknown));
      % Can't solve rectangular system
      %Lambda = F.AeqTE * (F.AeqTR1 \ (F.AeqTQ1' * NB - F.AeqTQ1' * F.Auu * Z(F.unknown)));
      % TRIM: (other linearly dependent constraints get 0s?)
      Lambda = F.AeqTE * [ ...
        (F.AeqTR1(:,1:size(F.AeqTR1,1)) \ ...
          (F.AeqTQ1' * NB - F.AeqTQ1' * F.Auu * Z(F.unknown))); ...
        zeros(size(F.AeqTE,2)-size(F.AeqTR1,1),1)
        ];
    end

    Lambda_known = -bsxfun(@plus,F.Ak * Z,0.5*B(F.known,:));
  end

end
