function [q,T] = fitSSM( SSM_ , T_ , Y , LAMBDA , q , T , varargin )


  initialT_its = 3;
  refineT_its  = 5;
  FarthestPointDistance = 2;
  optimQ_its   = 10;

  RANGE = 4;
  [varargin,~,RANGE] = parseargs(varargin,'range','$DEFS$',RANGE);

  if nargin < 4 || isempty(LAMBDA), LAMBDA = []; end
  if nargin < 5 || isempty(q),      q = {0};     end
  if nargin < 6 || isempty(T),      T = [];      end
  if isempty( LAMBDA ), LAMBDA = 0; end

  t0 = invmaketransform( eye(4) , T_ );

  printf( struct('increaseIndentationLevel',[]) ); CLEANUP = onCleanup( @()printf(struct('decreaseIndentationLevel',[])) );
  vprintf = @(varargin)printf(varargin{:});
  
  if ~iscell( Y ), Y = { Y }; end
  
  if size( Y , 1 ) > 1
    vprintf('\|-Resampling contours with FarthestPointSampling ...');
    %plot3d( Y , '-b' );
    for c = 1:size(Y,2)
      Y{1,c} = vertcat( Y{:,c} ); [ Y{2:end,c} ] = deal([]);
      Y{1,c} = FarthestPointSampling( Y{1,c} , 1 , FarthestPointDistance , Inf );
    end
    Y = Y(1,:);
    vprintf(' \b done.\n');
    %hplot3d( Y , '.r' );
  end
  
  if ~iscell( SSM_( 0 ) )
    SSM_ = @(varargin){ SSM_(varargin{:}) };
  end
  
  ENERGYfcn = @(X,S)ENER( X , S );
  try, [varargin,~,ENERGYfcn] = parseargs( varargin , 'energyfcn','$DEFS$', ENERGYfcn ); end
  
  
  
  allY = vertcat( Y{:} );
  CY = ( max( allY , [] , 1 ) + min( allY , [] , 1 ) )/2;
  Y = transform( Y , 't' , -CY );
  
  
  if iscell(q)
    Nq = q{1};
    q  = [];
  else
    Nq = numel(q);
  end
  
  Mq = SSM_( q );
  if isempty( T )
    vprintf('\|¯Compute the initial rigid T ...\n');
    C = [];
    for c = 1:numel( Mq ), C = [ C ; Mq{c}.xyz ]; end
    T = [ eye(3) , -mean( C , 1 ).' ; 0 0 0 1 ];
    
    for it = 0:initialT_its
      vprintf('\|-  iteration: %d of %d\n',it, initialT_its );
      if it == 0

        s = ExhaustiveSearch( @(s)ENERGYfcn( Y , transform( Mq , T , 'l_s', s ) ) , 0 , 1 , 7 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 'l_s' , s ); T = Tt * T;
        vprintf('      scale: %g\n', exp(s) );

        r = ExhaustiveSearch( @(r)ENERGYfcn( Y , transform( Mq , T , 'rz', r ) ) , 0 , 160 , 21 ,'maxITERATIONS' , 20 );
        Tt = maketransform( 'rz' , r ); T = Tt * T;
        vprintf(' z rotation: %g degrees\n', r );

        t = ExhaustiveSearch( @(t)ENERGYfcn( Y , transform( Mq , T , 't', t ) ) , [0;0;0] , 5 , 3 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 't', t ); T = Tt * T;
        vprintf('translation: %g , %g , %g\n', t );

        vprintf('\n' );
        
      else
      
        s = ExhaustiveSearch( @(s)ENERGYfcn( Y , transform( Mq , T , 'l_s', s ) ) , 0 , 0.5 , 5 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 'l_s' , s ); T = Tt * T;
        vprintf('      scale: %g\n', exp(s) );

        r = ExhaustiveSearch( @(r)ENERGYfcn( Y , transform( Mq , T , 'rz', r ) ) , 0 , 20 , 11 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 'rz' , r ); T = Tt * T;
        vprintf(' z rotation: %g degrees\n', r );

        t = ExhaustiveSearch( @(t)ENERGYfcn( Y , transform( Mq , T , 't', t ) ) , [0;0;0] , 5 , 3 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 't', t ); T = Tt * T;
        vprintf('translation: %g , %g , %g\n', t );

        vprintf('\n' );

        if abs(s) < 0.1 && abs(r) < 1 && max(abs(t)) < 1
          vprintf('No enough improvements. BREAKING\n');
          break;
        end
      
      end
    end
    %plot3d( Y , '*m','eq'); hplotMESH( transform( Mq , T ) );
    vprintf('\|_Initial rigid T done: T = %s\n' , uneval(T) );
    
  elseif iscell( T )
    vprintf('\|¯Refining the initial rigid T ...\n');
    
    T = T{1};
    T = maketransform( 't' , -CY ) * T;
    for it = 1:refineT_its
      vprintf('\|-   iteration: %d of %d\n',it, refineT_its );

      s = 0; r = 0; t = 0;
      
      if     isequal( T_ , 'l_sxyzt' )
        s = ExhaustiveSearch( @(s)ENERGYfcn( Y , transform( Mq , T , 'l_s', s ) ) , 0 , 0.1 , 5 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 'l_s' , s ); T = Tt * T;
        vprintf('       scale: %g\n', exp(s) );

        r = ExhaustiveSearch( @(r)ENERGYfcn( Y , transform( Mq , T , 'l_xyz', r ) ) , [0;0;0] , 0.1 , 3 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 'l_xyz' , r ); T = Tt * T;
        vprintf('xyz rotation: %g , %g , %g\n', r );

        t = ExhaustiveSearch( @(t)ENERGYfcn( Y , transform( Mq , T , 't', t ) ) , [0;0;0] , 1 , 3 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 't', t ); T = Tt * T;
        vprintf(' translation: %g , %g , %g\n', t );
      elseif isequal( T_ , 'l_xyzt' )
        r = ExhaustiveSearch( @(r)ENERGYfcn( Y , transform( Mq , T , 'l_xyz', r ) ) , [0;0;0] , 0.1 , 3 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 'l_xyz' , r ); T = Tt * T;
        vprintf('xyz rotation: %g , %g , %g\n', r );

        t = ExhaustiveSearch( @(t)ENERGYfcn( Y , transform( Mq , T , 't', t ) ) , [0;0;0] , 1 , 3 ,'maxITERATIONS' , 10 );
        Tt = maketransform( 't', t ); T = Tt * T;
        vprintf(' translation: %g , %g , %g\n', t );
%       elseif numel( t0 ) == 4
%         t = ExhaustiveSearch( @(t)ENERGYfcn( Y , transform( Mq , T , 't', t ) ) , [0;0;0] , 1 , 3 ,'maxITERATIONS' , 10 );
%         Tt = maketransform( 't', t ); T = Tt * T;
%         vprintf(' translation: %g , %g , %g\n', t );
% 
%         r = ExhaustiveSearch( @(r)ENERGYfcn( Y , transform( Mq , T , T_ , [r;0;0;0] ) ) , 0 , 1 , 3 ,'maxITERATIONS' , 10 );
%         Tt = maketransform( T_ , [r;0;0;0] ); T = Tt * T;
%         vprintf('r: %g\n', r );
      end

      vprintf('\n' );

      if abs(s) < 1e-6 && max(abs(r)) < 1e-6 && max(abs(t)) < 1e-6
        vprintf('No enough improvements. BREAKING\n');
        break;
      end
    end
    vprintf('\|_Refining T done: T = %s\n' , uneval(T) );

  else

    T = maketransform( 't' , -CY ) * T;
    
  end

  
  q = iApplyContraints( q , RANGE );
  
  while 1
    if numel( q ) < Nq, q = [ q ; 0 ]; end
    vprintf('\|¯Optimizing for %3d q coefficients.\n', numel( q ) );
    
    for it = 1:optimQ_its

      vprintf('Transformation part ...\n');
      printf( struct('increaseIndentationLevel',[]) );
      while 1
        t = Optimize( @(t)ENERGYfcn( Y , transform( Mq , T , T_ , t ) ) , t0 , 'methods',{'conjugate'},...
          'ls',{'quadratic'},struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}},'MAX_ITERATIONS',5),'noplot','verbose',0);
        Tt = maketransform( T_ , t ); T = Tt * T;

        MagRot = fro2( Tt - eye(4) );
        vprintf( 'Transformation Magnitud: %g' , MagRot );
        if MagRot < 1e-3
          vprintf( ' \b (too small, breaking).\n' );
          break;
        end
        vprintf( ' \b\n' );
      end
      vprintf('T = %s\n' , uneval(T) );
      printf( struct('decreaseIndentationLevel',[]) );

      qq = q;
      
      ENER = @(p) ENERGYfcn( Y , transform( SSM_(p) , T ) )^2  +  LAMBDA^2 * p(:).'*p(:);
      q = Optimize( @(q)ENER( ApplyContraints(q , RANGE ) ) , q , 'methods',{'conjugate'},...
          'ls',{'quadratic'},struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}},'MAX_ITERATIONS',25),'noplot','verbose',0);
      
      Mq = SSM_( ApplyContraints( q , RANGE ) );
      e = ENERGYfcn( Y , transform( Mq , T ) );
      vprintf( '(it: %2d) e: (%s) - [%d] q = %s\n' , it , uneval(e), numel(q), uneval( ApplyContraints( q , RANGE ) ) );

      if isequal( qq , q )
        vprintf('stucked...\n');
        break;
      end
    end
    %plot3d( Y , '*m','eq'); hplotMESH( transform( Mq , T ) );
    if numel( q ) == Nq
      vprintf('\|_**** DONE *************\n');
      break;
    end
  end
  T = [ eye(3) , CY(:) ; 0 0 0 1 ] * T;
  %plot3d( transform(Y,'t',CY) , '*m','eq'); hplotMESH( transform( Mq , T ) );
  
  q = ApplyContraints( q , RANGE );
  
end
function E = ENER( X , S )
  if iscell( X )
    E = 0;
    for c = 1:numel(X)
      E = E + ENER( X{c} , S{c} );
    end
    return;
  end
  if isempty(X), E = 0; return; end

  [e,~,d] = vtkClosestElement( S , X );
  if isfield( S , 'BoundaryElements' )  &&  ~isempty( S.BoundaryElements )
    w   = ismember( e , S.BoundaryElements );
    d2S  = d( ~w );
    d2Be = d( w );
    X2Be = X( w ,:);
    d2B = ClosestElement( struct('xyz',S.xyz,'tri',S.Boundary) , X2Be , true );
    
    w = abs( d2B - d2Be ) < 1e-8;
    try, if sum(w) > ( numel( d2S ) + sum(~w) ) * S.percentage_of_points_on_boundary
        w = [];
    end; end
    d2Be( w ) = [];
    
    d = [ d2S ; d2Be ];
  end

  p = 2;
  E = realpow( sum( realpow( d(:) ,p) )/numel(d) ,1/p);
end

function z = iApplyContraints( z , r )
  z = min( 20 * r , abs( r * atanh( z / r ) ) ) .* sign( z );
end
function z = ApplyContraints( z , r )
  z = r * tanh( z / r );
end
