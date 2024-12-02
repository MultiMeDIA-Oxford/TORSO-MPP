function I = gradient( I , varargin )
%
%   G = gradient( I )     devuelve la imagen gradiente
%                         hace diferencias centradas
%
%   G = gradient( I , [] )  devuelve la imagen gradiente exacta...
%
%   G = gradient( I , xyz )   devuelve el gradiente de la interpolacion en
%                             las coordenadas xyz
%
%   G = gradient( I , xyz , 'numeric' )   devuelve el gradiente de la interpolacion en
%                             las coordenadas xyz
%
%   G = gradient( I , X(I3D) )   devuelve una imagen gradiente
%                                en el I3D X
%
%   G = gradient( I , X(I3D) , 'numeric' )
%

%
% at( transform( gradient(I,[]) , T ) , x ) == gradient( I , transform( x , inv(T) ) )
%
% gradient( I.transform(T) , x ) == at( transform( gradient(I,[]) , T ) , x )*inv( T(1:3,1:3) )
%
% gradient( I.transform(T) , x )*T(1:3,1:3) == gradient( I , transform( x , inv(T) ) )
%
%


  I = remove_dereference( I );
  I = cleanout( I );
  [varargin,numerical] = parseargs(varargin,'Numeric'        ,'$FORCE$',{true,false} );
  
  if numel( varargin ) == 1
    X = varargin{1};
  else
    X = NaN;
  end
  
  if isnumeric( X ) && isscalar( X ) &&  isnan( X )
    
    switch I.BoundaryMode
      case {'value' , 'circular' , 'symmetric' ,'closest'}
        x = I.X;
        y = I.Y;
        z = I.Z;
      case { 'decay' }
        if numel(I.X) == 1, x = I.X;
        else,               x = [ I.X(1)-I.BoundarySize   I.X   I.X(end)+I.BoundarySize ];
        end

        if numel(I.Y) == 1, y = I.Y;
        else,               y = [ I.Y(1)-I.BoundarySize   I.Y   I.Y(end)+I.BoundarySize ];
        end

        if numel(I.Z) == 1, z = I.Z;
        else,               z = [ I.Z(1)-I.BoundarySize   I.Z   I.Z(end)+I.BoundarySize ];
        end
    end
    X = I3D('X',x,'Y',y,'Z',z,'T',I.T,'SpatialTransform',I.SpatialTransform);

    if numerical
      I = gradient( I , X , 'numeric' );
    else
      I = gradient( I , X );
    end
   
  elseif isempty( X )
    
    s = 1000;
    switch I.BoundaryMode
      case { 'value' }
        if numel(I.X) == 1, x = I.X;
        else              , x = unique( [ I.X(1)  I.X(2:end-1)+s*eps(I.X(2:end-1))  I.X(2:end-1)-s*eps(I.X(2:end-1)) I.X(end) ] );  
        end
        
        if numel(I.Y) == 1, y = I.Y;
        else              , y = unique( [ I.Y(1)  I.Y(2:end-1)+s*eps(I.Y(2:end-1))  I.Y(2:end-1)-s*eps(I.Y(2:end-1)) I.Y(end) ] );  
        end
        
        if numel(I.Z) == 1, z = I.Z;
        else              , z = unique( [ I.Z(1)  I.Z(2:end-1)+s*eps(I.Z(2:end-1))  I.Z(2:end-1)-s*eps(I.Z(2:end-1)) I.Z(end) ] );  
        end

      case { 'circular' , 'symmetric' }
        if numel(I.X) == 1, x = I.X;
        else              , x = unique( [ I.X   I.X(1:end-1)+s*eps(I.X(1:end-1))  I.X(2:end)-s*eps(I.X(2:end)) ] );  
        end
        
        if numel(I.Y) == 1, y = I.Y;
        else              , y = unique( [ I.Y   I.Y(1:end-1)+s*eps(I.Y(1:end-1))  I.Y(2:end)-s*eps(I.Y(2:end)) ] );  
        end
        
        if numel(I.Z) == 1, z = I.Z;
        else              , z = unique( [ I.Z   I.Z(1:end-1)+s*eps(I.Z(1:end-1))  I.Z(2:end)-s*eps(I.Z(2:end)) ] );  
        end
        

      case { 'decay' }
        if numel(I.X) == 1, x = I.X;
        else,               x = unique( [ I.X(1)-I.BoundarySize   I.X(1)-I.BoundarySize+s*eps(I.X(1)-I.BoundarySize)   I.X+s*eps(I.X)  I.X-s*eps(I.X)   I.X(end)+I.BoundarySize-s*eps(I.X(end)+I.BoundarySize)  I.X(end)+I.BoundarySize ] );
        end

        if numel(I.Y) == 1, y = I.Y;
        else,               y = unique( [ I.Y(1)-I.BoundarySize   I.Y(1)-I.BoundarySize+s*eps(I.Y(1)-I.BoundarySize)   I.Y+s*eps(I.Y)  I.Y-s*eps(I.Y)   I.Y(end)+I.BoundarySize-s*eps(I.Y(end)+I.BoundarySize)  I.Y(end)+I.BoundarySize ] );
        end

        if numel(I.Z) == 1, z = I.Z;
        else,               z = unique( [ I.Z(1)-I.BoundarySize   I.Z(1)-I.BoundarySize+s*eps(I.Z(1)-I.BoundarySize)   I.Z+s*eps(I.Z)  I.Z-s*eps(I.Z)   I.Z(end)+I.BoundarySize-s*eps(I.Z(end)+I.BoundarySize)  I.Z(end)+I.BoundarySize ] );
        end
    end
    X = I3D('X',x,'Y',y,'Z',z,'T',I.T,'SpatialTransform',I.SpatialTransform);

    if numerical
      I = gradient( I , X , 'numeric' );
    else
      I = gradient( I , X );
    end

    
  elseif isa( X , 'I3D' )
    
    sz = size( I.data );
    if numel(sz)<4 , sz(4) = 1; end
    sz(1) = numel(X.X);
    sz(2) = numel(X.Y);
    sz(3) = numel(X.Z);
    
    
    if numerical
      
      I.data = gradient( I , transform( ndmat(X.X,X.Y,X.Z) , X.SpatialTransform )  , 'numeric' );
      I.data = permute( I.data , [1 3:20 2] );
      
    else
    
      I.data = GridGradientOnPoints(I.data,I.X,I.Y,I.Z, ...
                  ndmat(X.X,X.Y,X.Z,'nocat') , 'nmatrix' , X.SpatialTransform , ...
                  'omatrix',I.SpatialTransform,I.BoundaryMode,I.BoundarySize );
      
    end

    I.data = reshape( I.data , [sz 3] );
    
    I.X = X.X;
    I.Y = X.Y;
    I.Z = X.Z;
    
    I.SpatialTransform = X.SpatialTransform;

    I.BoundaryMode = 'value';
    I.OutsideValue = 0;
    I.SpatialInterpolation = 'linear';
    
    I.ImageTransform = [ min(I.data(:)) 0 ; max(I.data(:)) 1 ];

  elseif isnumeric( X ) || isa( X , 'SamplePoints' )
    
    if isa( X , 'SamplePoints' )
      X = double(X);
    end

    sz = size( I.data );
    if numel(sz)<4 , sz(4) = 1; end

    if numerical

      I = cellfun( @(xyz) permute( NumericalDiff(@(x) at(I,x),xyz,'c') , [3 2 1] ) , num2cell(X(:,:),2) ,'uniformoutput',false );
      I = cell2mat( I );
      
    else
      
      I = GridGradientOnPoints(I.data,I.X,I.Y,I.Z,X(:,1:3),'omatrix',I.SpatialTransform,I.BoundaryMode,I.BoundarySize );

    end

    I = reshape( I , [size(I,1) 3 sz(4:end)] );

  end
  

  
  
  
if 0
  I = randn(6,1);
  I = repmat( I3D(I),[1 3 3] );
  I.X = I.X + rand(size(I.X))/2;
  I.Y = [-1 0 1];
  I.Z = [-1 0 1];
  I.OutsideValue = 0;
  I.BoundaryMode = 'symmetric';
  I.BoundarySize = 2.5;
  
  x = unique([ -5:.1:10  I.X  I.X(1)-I.BoundarySize  I.X(end)+I.BoundarySize ]);
  x = unique( [ x x+eps(x)  x-eps(x)  x+eps(x)*1e6   x-eps(x)*1e6 ] );
  x = x';
  x(1,3)=0;
  c1 = @(x) x(:,1);
  
  subplot(2,1,1);
  plot( x(:,1) , I(x) , ':r' );
  hold on
  for p = unique([ I.X(1)-[1 2 3 4]  I.X   I.X(end)+[1 2 3 4] linspace(I.X(1)-I.BoundarySize,I.X(end)+I.BoundarySize,50) ])
    plot( p+[-1 0 1]*.05 , I([p 0 0]) + c1(     gradient(I, [p 0 0]))*[-1 0 1]*.05 , '-m' ,'linewidth',2 );
    plot( p+[-1 0 1]*.05 , I([p 0 0]) + c1( at( gradient(I),[p 0 0]))*[-1 0 1]*.05 , '.-b' );
  end
  hold off
  set(gca,'xtick',[I.X(1)-I.BoundarySize  I.X  I.X(end)+I.BoundarySize],'xgrid','on');
  
 
  subplot(2,1,2);
  plot( x(:,1) , c1( I.gradient(x) ) , 'or' ,'linewidth',1)
  hold on
  plot( x(:,1) , c1( at( I.gradient, x ) ) , 'b' )
  plot( x(:,1) , c1( at( I.gradient([]), x ) ) , 'm' ,'linewidth',3)
  plot( x(:,1) , c1( I.gradient(x,'numeric') ) , '.-y' ,'linewidth',1)
  hold off
  set(gca,'xtick',[I.X(1)-I.BoundarySize  I.X  I.X(end)+I.BoundarySize],'xgrid','on','ylim',[-2 2]);
    
end
  
  
  
  
  
  
  
  
  
  
  
end
  

%   [varargin,ondata] = parseargs( varargin , 'ondata'  , '$FORCE$', {1,0} );
%   [varargin,ondata] = parseargs( varargin , 'onimage' , '$FORCE$', {0,1} );
%   
%   switch ondata
%     case 1, I.data = double( I.data );
%     case 0, I.data = subsref( I , substruct('.','image') );
%   end

%   if size(I,5) ~= 1, error('Only for scalar images ... (for now)'); end

% 
%   if numel( varargin )
%     I = imfilter( I , varargin{:} );
%   end

%   switch lower(mode)
%     case 'centered'
%       
%       if numel(I.Z) > 1
%         D  = I.data;
%         DX =          cat( 1 , I.X(2)-I.X(1) , vec( I.X(3:end)-I.X(1:end-2) ) , I.X(end)-I.X(end-1) );
%         DY = permute( cat( 1 , I.Y(2)-I.Y(1) , vec( I.Y(3:end)-I.Y(1:end-2) ) , I.Y(end)-I.Y(end-1) ) , [ 2 1 3 4 ] );
%         DZ = permute( cat( 1 , I.Z(2)-I.Z(1) , vec( I.Z(3:end)-I.Z(1:end-2) ) , I.Z(end)-I.Z(end-1) ) , [ 2 3 1 4 ] );
% 
%         I.data = cat( 5 , cat( 1 , ( D(  2  ,:,:,:) - D(   1   ,:,:,:) )   , ...
%           ( D(3:end,:,:,:) - D(1:end-2,:,:,:) )   , ...
%           ( D( end ,:,:,:) - D( end-1 ,:,:,:) )     ...
%           )./repmat( DX , [   1   size(I,2) size(I,3) size(I,4) ] ) , ...
%           cat( 2 , ( D(:,  2  ,:,:) - D(:,   1   ,:,:) )   , ...
%           ( D(:,3:end,:,:) - D(:,1:end-2,:,:) )   , ...
%           ( D(:, end ,:,:) - D(:, end-1 ,:,:) )     ...
%           )./repmat( DY , [ size(I,1)   1   size(I,3) size(I,4) ] ) , ...
%           cat( 3 , ( D(:,:,  2  ,:) - D(:,:,   1   ,:) )   , ...
%           ( D(:,:,3:end,:) - D(:,:,1:end-2,:) )   , ...
%           ( D(:,:, end ,:) - D(:,:, end-1 ,:) )     ...
%           )./repmat( DZ , [ size(I,1) size(I,2)   1   size(I,4) ] ) );
%       else
%         D  = I.data;
%         DX =          cat( 1 , I.X(2)-I.X(1) , vec( I.X(3:end)-I.X(1:end-2) ) , I.X(end)-I.X(end-1) );
%         DY = permute( cat( 1 , I.Y(2)-I.Y(1) , vec( I.Y(3:end)-I.Y(1:end-2) ) , I.Y(end)-I.Y(end-1) ) , [ 2 1 3 4 ] );
% 
%         I.data = cat( 5 , cat( 1 , ( D(  2  ,:,:,:) - D(   1   ,:,:,:) )   , ...
%           ( D(3:end,:,:,:) - D(1:end-2,:,:,:) )   , ...
%           ( D( end ,:,:,:) - D( end-1 ,:,:,:) )     ...
%           )./repmat( DX , [   1   size(I,2) size(I,3) size(I,4) ] ) , ...
%           cat( 2 , ( D(:,  2  ,:,:) - D(:,   1   ,:,:) )   , ...
%           ( D(:,3:end,:,:) - D(:,1:end-2,:,:) )   , ...
%           ( D(:, end ,:,:) - D(:, end-1 ,:,:) )     ...
%           )./repmat( DY , [ size(I,1)   1   size(I,3) size(I,4) ] ) );
%       end
% 
%     case 'trilinear'
%       IX = I.X;
%       IY = I.Y;
%       IZ = I.Z;
%       
%       
%       I.data = double(I.data);
%       
%       X0 = IX(1:end-1); X1 = IX(2:end);
%       Y0 = IY(1:end-1); Y1 = IY(2:end);
%       Z0 = IZ(1:end-1); Z1 = IZ(2:end);
% 
%       [ X0 , Y0 , Z0 ] = ndgrid( X0 , Y0 , Z0 );
%       [ X1 , Y1 , Z1 ] = ndgrid( X1 , Y1 , Z1 );
%       D = (X0-X1).*(Y0-Y1).*(Z0-Z1);
% 
%       V000 = I.data( 1:end-1 , 1:end-1 , 1:end-1 ) ;
%       V100 = I.data( 2:end   , 1:end-1 , 1:end-1 ) ;
%       V010 = I.data( 1:end-1 , 2:end   , 1:end-1 ) ;
%       V110 = I.data( 2:end   , 2:end   , 1:end-1 ) ;
%       V001 = I.data( 1:end-1 , 1:end-1 , 2:end   ) ;
%       V101 = I.data( 2:end   , 1:end-1 , 2:end   ) ;
%       V011 = I.data( 1:end-1 , 2:end   , 2:end   ) ;
%       V111 = I.data( 2:end   , 2:end   , 2:end   ) ;
% 
% 
%       C100 = ( V011.*Y0.*Z0 - V111.*Y0.*Z0 + (-V010 + V110).*Y0.*Z1 +  ...
%               Y1.*(-V001.*Z0 + V101.*Z0 + V000.*Z1 - V100.*Z1) ) ./D;
% 
%       C010 = ( V101.*X0.*Z0 - V111.*X0.*Z0 + (-V100 + V110).*X0.*Z1 +  ...
%               X1.*(-V001.*Z0 + V011.*Z0 + V000.*Z1 - V010.*Z1)  ) ./D;
% 
%       C001 = ( V110.*X0.*Y0 - V111.*X0.*Y0 + (-V100 + V101).*X0.*Y1 +  ...
%               X1.*(-V010.*Y0 + V011.*Y0 + V000.*Y1 - V001.*Y1)  ) ./D;
% 
%       C110 = ( (V001 - V011 - V101 + V111).*Z0 + (-V000 + V010 + V100 - V110).*Z1 ) ./D;
% 
%       C101 = ( (V010 - V011 - V110 + V111).*Y0 + (-V000 + V001 + V100 - V101).*Y1 ) ./D;
% 
%       C011 = ( (V100 - V101 - V110 + V111).*X0 + (-V000 + V001 + V010 - V011).*X1 ) ./D;
% 
%       C111 = ( V000 - V001 - V010 + V011 - V100 + V101 + V110 - V111 ) ./D;
% 
% 
%       GX = sort( [ I.X    I.X(2:end-1)-eps(I.X(2:end-1)) ] );
%       GY = sort( [ I.Y    I.Y(2:end-1)-eps(I.Y(2:end-1)) ] );
%       GZ = sort( [ I.Z    I.Z(2:end-1)-eps(I.Z(2:end-1)) ] );
% 
%       
%       I = I3D( 'X',GX,'Y',GY,'Z',GZ,'spatialtransform',I.SpatialTransform );
%       I.data = repmat( I.data , [1 1 1 1 3] );
%       
%       
%       [ GX , GY , GZ ] = ndgrid( I.X , I.Y , I.Z );
%       GX = GX(:);
%       GY = GY(:);
%       GZ = GZ(:);
%       inds = sub2ind( size(C100) , getInterval(GX,IX) , getInterval(GY,IY) , getInterval(GZ,IZ) );
% 
%       I.data(:) = [ C100( inds )  +  C110( inds ) .* GY  +  C101( inds ) .* GZ  +  C111( inds ) .* GY .* GZ  ; ...
%                     C010( inds )  +  C110( inds ) .* GX  +  C011( inds ) .* GZ  +  C111( inds ) .* GX .* GZ  ; ...
%                     C001( inds )  +  C101( inds ) .* GX  +  C011( inds ) .* GY  +  C111( inds ) .* GX .* GY  ];
% 
%   end



%     nd = ndims( I.data );
%     if nd <= 4, nd = 4; end
%     dims = repmat( {':'} , 1 , nd-3 );
%     
%     nd = nd+1;
%     
%     I.data = double(I.data);
% 
%     nX = size(I.data,1);
%     nY = size(I.data,2);
%     nZ = size(I.data,3);
%     
%     iX0 = 1:nX;
%     iY0 = 1:nY;
%     iZ0 = 1:nZ;
%     switch I.BoundaryMode
%       case 'circular'
%         iX_1 = [ nX  1:nX-2  nX-1 ];
%         iX1  = [ 2   3:nX    1    ];
%         Xb = I.X(iX0) - I.X(iX_1);
%         Xf = I.X(iX1) - I.X(iX0 );
%         Xc = I.X(iX1) - I.X(iX_1);
%         
%         iY_1 = [ nY  1:nY-2  nY-1 ]; iY0  = [ 1  2:nY-1  nY   ]; iY1  = [ 2  3:nY    1   ];
%         Yb = I.Y(iY0) - I.Y(iY_1); Yf = I.Y(iY1) - I.Y(iY0 ); Yc = I.Y(iY1) - I.Y(iY_1);
%         
%         iZ_1 = [ nZ  1:nZ-2  nZ-1 ]; iZ0  = [ 1  2:nZ-1  nZ   ]; iZ1  = [ 2  3:nZ     1   ];
%         Zb = I.Z(iZ0) - I.Z(iZ_1); Zf = I.Z(iZ1) - I.Z(iZ0 ); Zc = I.Z(iZ1) - I.Z(iZ_1);
% 
%       case 'symmetric'
%         iX1 = [ 2 3:nX nX-1 ]; iX2 = [ 2 1:nX-2 nX-1 ];
%         iY1 = [ 2 3:nY nY-1 ]; iY2 = [ 2 1:nY-2 nY-1 ];
%         iZ1 = [ 2 3:nZ nZ-1 ]; iZ2 = [ 2 1:nZ-2 nZ-1 ];
% 
%       case {'value' 'decay' }
%         iX_1 = [ 1  1:nX-2  nX-1 ];
%         iX1  = [ 2  3:nX    nX   ];
%         Xb = I.X(iX0) - I.X(iX_1); Xb(end) = Xb(end)/2;
%         Xf = I.X(iX1) - I.X(iX0 ); Xf( 1 ) = Xf( 1 )/2;
%         
%         iY_1 = [ 1  1:nY-2  nY-1 ];
%         iY1  = [ 2  3:nY    nY   ];
%         Yb = I.Y(iY0) - I.Y(iY_1); Yb(end) = Yb(end)/2;
%         Yf = I.Y(iY1) - I.Y(iY0 ); Yf( 1 ) = Yf( 1 )/2;
%         
%         iZ_1 = [ 1  1:nZ-2  nZ-1 ];
%         iZ1  = [ 2  3:nZ    nZ   ];
%         Zb = I.Z(iZ0) - I.Z(iZ_1); Zb(end) = Zb(end)/2;
%         Zf = I.Z(iZ1) - I.Z(iZ0 ); Zf( 1 ) = Zf( 1 )/2;
% 
%         I.OutsideValue = 0;
%     end
%     Xb(Xb==0)=Inf; Xf(Xf==0)=Inf;
%     Yb(Yb==0)=Inf; Yf(Yf==0)=Inf;
%     Zb(Zb==0)=Inf; Zf(Zf==0)=Inf;
%     
%     I.data = cat( nd , ...
%         bsxfun(@rdivide, I.data(iX0,:,:,dims{:}) - I.data(iX_1,:,:,dims{:}) ,permute(Xb(:),[1 2 3])) ...
%       + bsxfun(@rdivide, I.data(iX1,:,:,dims{:}) - I.data(iX0 ,:,:,dims{:}) ,permute(Xf(:),[1 2 3])) ...
%     , ...
%         bsxfun(@rdivide, I.data(:,iY0,:,dims{:}) - I.data(:,iY_1,:,dims{:}) ,permute(Yb(:),[2 1 3])) ...
%       + bsxfun(@rdivide, I.data(:,iY1,:,dims{:}) - I.data(:,iY0 ,:,dims{:}) ,permute(Yf(:),[2 1 3])) ...
%     , ...
%         bsxfun(@rdivide, I.data(:,:,iZ0,dims{:}) - I.data(:,:,iZ_1,dims{:}) ,permute(Zb(:),[2 3 1])) ...
%       + bsxfun(@rdivide, I.data(:,:,iZ1,dims{:}) - I.data(:,:,iZ0 ,dims{:}) ,permute(Zf(:),[2 3 1])) ...
%     )/2;
% 
%     I.data(:) = reshape( I.data , [] , 3 )* inv( I.SpatialTransform(1:3,1:3) );
%   
%     I.ImageTransform = [ min(I.data(:)) 0 ; max(I.data(:)) 1 ];



