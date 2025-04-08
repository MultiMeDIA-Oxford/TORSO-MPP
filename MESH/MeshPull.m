function M = MeshPull( M , XYZ , Niterations , prcts , LAMBDAS , PullOnBoundary , varargin )

  if nargin < 3 || isempty( Niterations )
    Niterations = 1;
  end
  if nargin < 4 || isempty( prcts )
    prcts = 1 - realpow( 1 - 0.99 , 1/Niterations );
  end
  if nargin < 5 || isempty( LAMBDAS )
    LAMBDAS = Inf;
  end
  if nargin < 6 || isempty( PullOnBoundary )
    PullOnBoundary = true;
  end
  

  M = MeshKneading( M , XYZ , Niterations , prcts , LAMBDAS , PullOnBoundary , varargin{:} );
  
  return;
  
  XYZ( ~all(isfinite(XYZ),2) ,:) = [];

  for it = 1:Niterations
    [d,anchors] = distanceFrom( XYZ , M , ~PullOnBoundary( min(end,it) ) );
    anchors( d < 0 ,:) = NaN;
    
    target = anchors + ( XYZ - anchors )*prcts( min(end,it) );
    
    M.xyz = M.xyz + InterpolatingSplines( anchors , target - anchors , M.xyz , 'r' , 'LAMBDA' , LAMBDAS( min(end,it) ) );
  end

end
