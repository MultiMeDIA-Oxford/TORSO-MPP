function L = intersectionLine( A , B , DELTA )

    
    if nargin > 2 && ~isempty( DELTA ) && DELTA < 0
       L =  intersectionLine( A , B, [] );
       if isempty( L ), return; end
       mL = mean( L ,1);
       L = bsxfun( @plus , bsxfun( @minus , L , mL ) * (-DELTA) , mL );
       return;
        
    end


  if isa( A , 'struct' )
    A = I3D([],'X',A.X,'Y',A.Y,'Z',0,'R',A.SpatialTransform);
  end
  if isa( A , 'I3D' )
    A = A.coords2matrix;
  elseif isa( A , 'cell' )
    A = A{2};
    try, A = rmfield( A , 'xSpatialTransform' ); end
    A = DICOMxinfo( A );
    A.SpatialTransform = A.xSpatialTransform;
    A.X = double( [ 0 , (A.Columns-1) * A.PixelSpacing(2) ] );
    A.Y = double( [ 0 , (A.Rows-1)    * A.PixelSpacing(1) ] );
  end
  
  if isa( B , 'struct' )
    B = I3D([],'X',B.X,'Y',B.Y,'Z',0,'R',B.SpatialTransform);
  end
  if isa( B , 'I3D' )
    B = B.coords2matrix;
  elseif isa( B , 'cell' )
    B = B{2};
    try, B = rmfield( B , 'xSpatialTransform' ); end
    B = DICOMxinfo( B );
    B.SpatialTransform = B.xSpatialTransform;
    B.X = double( [ 0 , (B.Columns-1) * B.PixelSpacing(2) ] );
    B.Y = double( [ 0 , (B.Rows-1)    * B.PixelSpacing(1) ] );
  end

  
  C = intersectionPlanePlane( A.SpatialTransform , B.SpatialTransform );
  if isempty( C ), L = []; return; end
  L = [ C(1:3,4).' ; C(1:3,4).' + C(1:3,3).' ];
  
  
  L = transform( L , minv( A.SpatialTransform ) );  p = L(1,:); v = L(2,:)-L(1,:);
  Ts = sort( [ -p(1)/v(1)                ,...
               ( A.X(end) - p(1) )/v(1)  ,...
               -p(2)/v(2)                ,...
               ( A.Y(end) - p(2) )/v(2) ] ).';
  Tm = ( Ts(1:end-1) + Ts(2:end) )/2;
  m  = bsxfun( @plus , p , Tm(:)*v );
  t  = find( m(:,1) >= 0 & m(:,1) <= A.X(end) & m(:,2) >= 0 & m(:,2) <= A.Y(end) );
  if isempty( t ), L = []; return; end
  L = bsxfun( @plus , p , Ts([ min(t) ; max(t)+1 ])*v );
  L = transform( L , A.SpatialTransform );

  
  
  L = transform( L , minv( B.SpatialTransform ) );  p = L(1,:); v = L(2,:)-L(1,:);
  Ts = sort( [ -p(1)/v(1)                ,...
               ( B.X(end) - p(1) )/v(1)  ,...
               -p(2)/v(2)                ,...
               ( B.Y(end) - p(2) )/v(2)  ,...
               0 , 1 ] ).';
  Ts( Ts < 0 | Ts > 1 ) = [];
  Tm = ( Ts(1:end-1) + Ts(2:end) )/2;
  m  = bsxfun( @plus , p , Tm(:)*v );
  t  = find( m(:,1) >= 0 & m(:,1) <= B.X(end) & m(:,2) >= 0 & m(:,2) <= B.Y(end) );
  if isempty( t ), L = []; return; end
  L = bsxfun( @plus , p , Ts([ min(t) ; max(t)+1 ])*v );
  L = transform( L , B.SpatialTransform );

  
  if nargin > 2 && ~isempty( DELTA ) && DELTA > 0
    CL = ( L(2,:) + L(1,:) )/2; 
    V  = L(2,:) - L(1,:);
    LL = sqrt( sum( V.^2 ) );
    V  = normalize(V);
    T  = 0:DELTA:LL; if ~rem(numel(T),2), T(end)=[]; end
    L  = T(:) * V;
    L = bsxfun( @plus, L , CL - ( L(1,:) + L(end,:) )/2 );
  end
  


end
