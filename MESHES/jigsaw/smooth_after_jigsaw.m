function M = smooth_after_jigsaw( M , T , maxD , varargin )

  if nargin < 3 || isempty( maxD )
    E = [ M.tri(:,1) , M.tri(:,2) ; M.tri(:,2) , M.tri(:,3) ; M.tri(:,1) , M.tri(:,1) ];
    E = sort( E , 2 );
    E = unique( E , 'rows' );
    EL = sum( ( M.xyz( E(:,2) , : ) - M.xyz( E(:,1) , : ) ).^2 , 2 );
    EL = median( EL );
    EL = sqrt( EL );
    maxD = EL;
  end
  
  T = Mesh( T ,0);
  M = Mesh( M );
  %[~,~,distance] = vtkClosestElement( T , M.xyz );

  nIT = 1000;
  TotalIT = 0;
  
  vtkClosestElement( T ); CLEANUP = onCleanup( @() vtkClosestElement( [] , [] ) );
  
  while nIT >= 1
    Mp = M.xyz;
    M = vtkSmoothPolyDataFilter( M , ...
            'SetNumberOfIterations'   , nIT ,  ...
            'SetFeatureEdgeSmoothing' , false ,...
            'SetBoundarySmoothing'    , false ,...
            'SetGenerateErrorScalars' , false ,...
            'SetGenerateErrorVectors' , false , varargin{:} );
    [~,~,distance] = vtkClosestElement( M.xyz );
%     disp( [nIT max( distance )] )
    if max( distance ) >= maxD
      nIT = round( nIT / 2.1 );
      M.xyz = Mp;
    else
      TotalIT = TotalIT + nIT;
      nIT = round( nIT * 1.5 );
    end
  end
%   TotalIT


end
