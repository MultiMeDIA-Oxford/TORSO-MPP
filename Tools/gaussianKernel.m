function K= gaussianKernel( varargin )
%
%   K= GaussianKernel( -30:30 , 'sigma',s );
%   K= GaussianKernel( -3:3 , -3:3 , 'sigma',s );
%   K= GaussianKernel( -3:3 , -3:3 , -3:3 , 'sigma',s );
%

  [varargin,i,S ]= parseargs(varargin,'Std','sigma','$DEFS$',1);
  [varargin,i,C ]= parseargs(varargin,'COVariance' );
  
  [varargin,i,tol    ]= parseargs(varargin,'TOLerance','t','$DEFS$', 0*eps(1e3) );
  [varargin,normalize]= parseargs(varargin,'NORMal','Normalize','$FORCE$', true );
  
  ndims= numel( varargin );
  if isempty( C )
    if numel(S)==1
      S = repmat( S , 1 , ndims );
    end
    C = diag( S.^2 );
  end
  
  coords = ndmat( varargin{:} );

  K = sum( coords' .* ( inv(C) * coords' ) , 1 );
  K = exp( - K/2 )/sqrt( det(C) * (2*pi)^ndims );
  K = reshape( K , [ cellfun( @(x) numel(x) , varargin )  1 ] );
  
  if tol > 0
    K = reduceKernel( K , tol );
  end  

  
  if normalize
    K= K/sum(K(:));
  end

end
