% Ernesto's function for linear discriminant analysis
% (M) are comments by Marta
function [w,p,rel] = fisher( varargin )

  TYPE = 'intra';
  if ischar( varargin{end} )
    TYPE = varargin{end};
    varargin(end) = [];
  end

  % each subject is a column
  dim = 2;

  C = numel( varargin );
  if nargout > 1 && C > 2, error('no p-value can be computed with more than 2 classes'); end

  n = cellfun( @(x)size(x,dim) , varargin );
  m = cellfun( @(x)mean(x,dim) , varargin , 'UniformOutput',false );
  c = cellfun( @(x)cov(x.',1)  , varargin , 'UniformOutput',false );

  switch lower(TYPE)
    case 'intra'
      
      % compute mean of entire population (M)
      x = m{1}*n(1);
      for i = 2:C
        x = x + m{i}*n(i);
      end
      x = x / sum(n);
      
      % compute variance between means of each population (M)
      SB = n(1)*( m{1} - x )*( m{1} - x ).';
      for i = 2:C
        SB = SB + n(i)*( m{i} - x )*( m{i} - x ).';
      end
      SB = ( SB + SB.' )/2;
      
      % compute variance for each population (M)
      SW = n(1)*c{1};
      for i = 2:C
        SW = SW + n(i)*c{i};
      end
      SW = ( SW + SW.' )/2;
      
      
% maximize ( w'*SB*w )/( w'*SW*w )
% is equivalent to
% minimize -w'*SB*w , subject to w'*SW*w == 1
%
% lagrangian:  -w.'*SB*w - d * w'*SW'w , where d is a lagrange mult.
% then  w'*SB = d*w'*SW =>  SB*w = d * SW * w   (SB and SW) are sym.
%                   SW^-1 * SB*w = d * w 

%   [w,d] = eig( SB , SW );

%   SW * w = d * SB * w
%   SB = U.' * U
%   v = U * w  => w = inv(U)*v
%   SW * inv(U) * v = d * U.' * v
%   inv( U.' ) * SW * inv( U ) * v = d * v
%   with the advantage that ( U.' \ SB / U ) is sym, therefore eigs exists.
      
      U = chol( SW );
      M = U.' \ SB / U;
      M = (M+M.')/2;
      [w,d] = eig( M );
      [~,d] = sort( abs( diag(d) ) ,'descend');
      w = w(:,d);
      
      w = U \ w(:,1:C-1);
      
    case 'maxt'
      if C > 2, error('only valid for 2 classes'); end
      
      SW = n(1)/(n(1)-1)*c{1}*n(2) + n(2)/(n(2)-1)*c{2}*n(1);
      SW = ( SW + SW.' )/2;
      
      w = SW \ (m{1}-m{2});

    case 'minp'
      if C > 2, error('only valid for 2 classes'); end
      
      SW = n(1)/(n(1)-1)*c{1}*n(2) + n(2)/(n(2)-1)*c{2}*n(1);
      SW = ( SW + SW.' )/2;
      w = SW \ (m{1}-m{2});
      w = w / sqrt(sum(w.^2));
      [~,d] = max(abs(w));
      if w(d) < 0, w = -w; end
      z = [ w(1:d-1) ; w(d+1:end) ];
      
      w = Optimize( @(z)computeP(z,d,varargin{1},varargin{2}) , z ,...
        'methods',{'conjugate','descend'},'noplot','verbose',0);

      nw = sum(w.^2);
      if nw < 1, nw = sqrt( 1 - nw );
      else     , nw = 0;
      end
      w = [ w(1:d-1) ; nw ; w(d:end) ];

  end
  
  w = w / sqrt(sum( w(:,1).^2 ));
  if w(1) < 0, w = -w; end
  
  if nargout > 1
    A = w.'*varargin{1};
    B = w.'*varargin{2};
    
    [~,p] = studentsttest2( A , B , 'param','unequal' );
  end
  if nargout > 2
    if C > 2, error('only valid for 2 classes'); end
    
    % ratio of distance between projected class means and projected
    % variance
    rel = ( w.' * SB * w ) / ( w.' * SW * w );
  end

  
  function p = computeP( w , d , A , B )
    nw = sum(w.^2);
    if nw < 1, nw = sqrt( 1 - nw );
    else     , nw = 0;
    end
    w = [ w(1:d-1) ; nw ; w(d:end) ];
    w = w / sqrt(sum(w.^2));
    [~,p] = studentsttest2( w.'*A , w.'*B , 'param','unequal' );
  end
  
end
