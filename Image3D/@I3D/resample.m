function I = resample( I , in , varargin )
% 
%     I = resample( I , in , 'anchor' , anchor )
%
%   anchor could be, a 3D point inside the original grid. in local
%         coordinates
%
%   anchor could be '0' or '1' for the point 1,1,1
%   anchor could be 'end'      for the point end,end,end
%   anchor could be 'center'   for the central point
% 
% 
%  if  in = []       do nothing
% 
%  case cell  in = { nx , ny , nz }
%  
%     if  in = { x }   -->  in = { x , x , x }
%
%     if  nx  is char  
%         nx = Interp1D( I.X(:) , 1:numel(I.X) , 1:1/nX:numel(I.X) )
% 
% 
%   case char
%     in = 'NumberOfVoxels_of_an_isotropic_grid(anchored in anchor)'
%   
%     if  in  > 0
%         max isotropic grid with no more than IN voxels
% 
%     if  in  < 0
%         max isotropic grid with union original grid with no more than IN
%         
% 
%   case 1, 2 or 3 numbers
%     in = [ x y z ]
%
%     if  in = [ x ]   -->  in = [ x x x ]
%     if  in = [ x y ] -->  in = [ x y 0 ]
%    
%     if x = 0, NaN or Inf, original grid
% 
%     if x > 0, equispaced grid with size x (anchored in anchor)
%
%     if x < 0, x points equispaced betwen grid(1) and grid(end)
%               anchor ignored!!
%

  I = remove_dereference( I );
  I.GRID_PROPERTIES = [];

  c = 'c';
  [varargin,i,c] = parseargs(varargin,'anchor','$DEFS$',c);
  if ischar( c )
    switch lower(c)
      case {'0','1'}
        c = [ I.X(1) , I.Y(1) , I.Z(1) ];
      case {'end'}
        c = [ I.X(end) , I.Y(end) , I.Z(end) ];
      case {'c','center'}
        c = [ mean( I.X([1 end]) ) , mean( I.Y([1 end]) ) , mean( I.Z([1 end]) ) ];
      otherwise
        error('incorrect anchor');
    end
  end
  if numel(c) ~= 3, error('incorrect anchor'); end
  if c(1) < I.X( 1 ), error('anchor 1 , smaller than minimum'); end
  if c(1) > I.X(end), error('anchor 1 , greater than minimum'); end
  if c(2) < I.Y( 1 ), error('anchor 2 , smaller than minimum'); end
  if c(2) > I.Y(end), error('anchor 2 , greater than minimum'); end
  if c(3) < I.Z( 1 ), error('anchor 3 , smaller than minimum'); end
  if c(3) > I.Z(end), error('anchor 3 , greater than minimum'); end

  if isempty( in ), return; end

  if iscell( in )
  
    if numel( in ) == 1
      in = repmat( in , 1,3 );
    end
    nX = in{1};
    nY = in{2};
    nZ = in{3};
    
    if ischar( nX )
      nX = str2double( nX );
      nX = Interp1D( I.X(:) , 1:numel(I.X) , 1:1/nX:numel(I.X) ,'linear' );
    end
    
    if ischar( nY )
      nY = str2double( nY );
      nY = Interp1D( I.Y(:) , 1:numel(I.Y) , 1:1/nY:numel(I.Y) ,'linear' );
    end

    if ischar( nZ )
      nZ = str2double( nZ );
      nZ = Interp1D( I.Z(:) , 1:numel(I.Z) , 1:1/nZ:numel(I.Z) ,'linear' );
    end

  elseif ischar( in )
    
    in = str2double( in );

    d = [ ( I.X(end) - I.X(1) ) , ( I.Y(end) - I.Y(1) ) , ( I.Z(end) - I.Z(1) ) ]*2;
    d( ~d ) = [];
    
    
    if in > 0

      x = fzero( @(x) prod( ceil( d/x ) ) - in , realpow( prod(d)/in , 1/numel(d) ) );

      NV = @(x) numel( unique( [ I.X([1 end]) c(1):x:I.X(end)   c(1):-x:I.X(1) ] ) )*...
                numel( unique( [ I.Y([1 end]) c(2):x:I.Y(end)   c(2):-x:I.Y(1) ] ) )*...
                numel( unique( [ I.Z([1 end]) c(3):x:I.Z(end)   c(3):-x:I.Z(1) ] ) );

      x = fzero( @(x) NV(x) - in , x );
      while NV(x) > in,      x = x*1.000001  ;    end
      while NV(x) < in,      x = x/1.00000001;    end
      if    NV(x) > in,      x = x*1.00000001;    end

      nX = unique( [ I.X([1 end])  c(1):x:I.X(end)   c(1):-x:I.X(1) ] );
      nY = unique( [ I.Y([1 end])  c(2):x:I.Y(end)   c(2):-x:I.Y(1) ] );
      nZ = unique( [ I.Z([1 end])  c(3):x:I.Z(end)   c(3):-x:I.Z(1) ] );
      
    elseif in < 0
      
      in = -in;

      if  numel(I.X)*numel(I.Y)*numel(I.Z) >= in
        return;
      end
      
      x = fzero( @(x) prod( ceil( d/x ) ) - in , realpow( prod(d)/in , 1/numel(d) ) );

      NV = @(x) numel( unique( [ I.X   c(1):x:I.X(end)   c(1):-x:I.X(1) ] ) )*...
                numel( unique( [ I.Y   c(2):x:I.Y(end)   c(2):-x:I.Y(1) ] ) )*...
                numel( unique( [ I.Z   c(3):x:I.Z(end)   c(3):-x:I.Z(1) ] ) );

      x = fzero( @(x) NV(x) - in , x );
      while NV(x) > in,      x = x*1.000001  ;    end
      while NV(x) < in,      x = x/1.00000001;    end
      if    NV(x) > in,      x = x*1.00000001;    end

      nX = unique( [ I.X   c(1):x:I.X(end)   c(1):-x:I.X(1) ] );
      nY = unique( [ I.Y   c(2):x:I.Y(end)   c(2):-x:I.Y(1) ] );
      nZ = unique( [ I.Z   c(3):x:I.Z(end)   c(3):-x:I.Z(1) ] );

    else
      
      error(' ''zero''  not allowed ' );

    end
    
  else

    if numel( in ) == 1, in = [in in in]; end
    if numel( in ) == 2, in(3) = 0;       end
    if numel( in )  > 3, error('to much dims'); end

    in( isnan(in) | isinf(in) ) = 0;

    if in(1) == 0
      nX = I.X;
    elseif in(1) < 0
      nX = linspace( I.X(1) , I.X(end) , -in(1) );
      nX( 1 ) = I.X( 1 );
      nX(end) = I.X(end);
    else
      nX = unique( [ I.X([1 end]) c(1):in(1):I.X(end)   c(1):-in(1):I.X(1) ] );
    end

    if in(2) == 0
      nY = I.Y;
    elseif in(2) < 0
      nY = linspace( I.Y(1) , I.Y(end) , -in(2) );
      nY( 1 ) = I.Y( 1 );
      nY(end) = I.Y(end);
    else
      nY = unique( [ I.Y([1 end]) c(2):in(2):I.Y(end)   c(2):-in(2):I.Y(1) ] );
    end

    if in(3) == 0
      nZ = I.Z;
    elseif in(3) < 0
      nZ = linspace( I.Z(1) , I.Z(end) , -in(3) );
      nZ( 1 ) = I.Z( 1 );
      nZ(end) = I.Z(end);
    else
      nZ = unique( [ I.Z([1 end]) c(3):in(3):I.Z(end)   c(3):-in(3):I.Z(1) ] );
    end
    
  end

  ST = I.SpatialTransform;
  
  I.SpatialTransform = eye(4);
  
  I = at( I , I3D([],'X',unique(nX),'Y',unique(nY),'Z',unique(nZ)) , varargin{:} );

  I.SpatialTransform = ST;

end
