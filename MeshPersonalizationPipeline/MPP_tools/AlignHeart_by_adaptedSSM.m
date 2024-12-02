function [TS,q,T] = AlignHeart_by_adaptedSSM( HC , TS , SSM , q , T , varargin )

  if nargin < 2, TS = []; end

  Nits              = 5;
  [varargin,~,Nits] = parseargs(varargin,'Nits','$DEFS$',Nits);

  energyFCN = @(d)sqrt( mean( d(:).^2 ) );
  [varargin,~,energyFCN] = parseargs(varargin,'energyFCN','$DEFS$',energyFCN);
  
  Qrange = 5;
  [varargin,~,Qrange] = parseargs(varargin,'qrange','$DEFS$',Qrange);
    
  Rrange = 7;
  [varargin,~,Rrange] = parseargs(varargin,'rrange','$DEFS$',Rrange);
  
  TZrange = 4;
  [varargin,~,TZrange] = parseargs(varargin,'tzrange','$DEFS$',TZrange);
  
  %%
  HC = MaskHeart( HC );
  
   POSES = repmat( {eye(4)} , size(HC,1),1);
  iPOSES = repmat( {eye(4)} , size(HC,1),1);
  for r = 1:size(HC,1)
    I = HC{r,1}; if isempty( I ), continue; end
    I = crop( I , 0 , 'mask',I.FIELDS.Hmask );
    c = I.center(:);
    
     POSES{r} = [ I.SpatialTransform(1:3,1:3) , c ; 0 0 0 1 ];
    iPOSES{r} = minv( POSES{r} );
  end
              
  %%
  
  printf( struct('resetIndentationLevel',0) );printf( struct('setIndentationLevel',0) ); %printf( struct('setIndentationLevel',-1) );
  
  CS = HC(:,2:end);

  if isempty( TS )
    TS = repmat( {eye(4)} , size(HC,1),1);
  end

  %%

  CSTS = transform( CS , TS );
  for c = 1:size(CSTS,2), CSTS{1,c} = vertcat( CSTS{:,c} ); end;
  CSTS(2:end,:) = [];

  initialFactor = 0.9;
  [varargin,~,initialFactor] = parseargs(varargin,'initialFactor','$DEFS$',initialFactor);
  
  if any( max(abs(q)) > Qrange * initialFactor )
    q = q / max(abs(q)) * Qrange * initialFactor;
  end
  q = clamp( q , -Qrange * initialFactor , Qrange * initialFactor );
  [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 't'  ,'methods',{'o'} ,'ITerations',  5 ,'PRCT',-0.8,'RANGE',0 );  %,'plot'); close(gcf);drawnow
  [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 'Gt' ,'methods',{'o'} ,'ITerations',  5 ,'PRCT',-0.8,'RANGE',0 );  %,'plot'); close(gcf);drawnow
  [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 'Gt' ,'methods',{'o'} ,'ITerations',  5 ,'PRCT',-0.8,'RANGE',Qrange * initialFactor );  %,'plot'); close(gcf);drawnow
  [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 'Gt' ,'methods',{'o'} ,'ITerations', 50 ,'PRCT',-0.8,'RANGE',Qrange * initialFactor );  %,'plot'); close(gcf);drawnow
  [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 't'  ,'methods',{'o'} ,'ITerations', 10 ,'PRCT',-0.8,'RANGE',0 );  %,'plot'); close(gcf);drawnow
  [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 'Gt' ,'methods',{'o'} ,'ITerations', 10 ,'PRCT',-0.8,'RANGE',0 );  %,'plot'); close(gcf);drawnow
  
  %%
  
  for it = 1:Nits
    TModel = @(varargin)thisTModel_SE( varargin{:} , Rrange(min(it,end)) , TZrange(min(it,end)) );

    for iit = 0:0
      printf('>>>> Alignning contours to shape in iteration %2d(%d)\n', it , iit );
      [TS,G] = SquareHeartSlicesToMesh( CS , TS , transform( SSM(q) , T ).' , 'Transform' , @(x,T)transform(x,T) , 'POSES' , POSES ,'iPOSES', iPOSES  ,'TransformationMODEL', TModel,'energyfcn',@(X,S)ENER(X,S,energyFCN) ,varargin{:});
      T = G * T;
      %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) );
    end

    CSTS = transform( CS , TS );
    for c = 1:size(CSTS,2), CSTS{1,c} = vertcat( CSTS{:,c} ); end;
    CSTS(2:end,:) = [];

    [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 't'  ,'methods',{'o'} ,'ITerations',  5 ,'PRCT',-0.8,'RANGE',0 );  %,'plot'); close(gcf);drawnow
    [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 'Gt' ,'methods',{'o'} ,'ITerations',  5 ,'PRCT',-0.8,'RANGE',0 );  %,'plot'); close(gcf);drawnow
    [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 'Gt' ,'methods',{'o'} ,'ITerations', 50 ,'PRCT',-0.8,'RANGE',Qrange );  %,'plot'); close(gcf);drawnow
    [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 't'  ,'methods',{'o'} ,'ITerations', 10 ,'PRCT',-0.8,'RANGE',0 );  %,'plot'); close(gcf);drawnow
    [q,T] = fitSSM_to_points( SSM , CSTS , q , T , 'Gt' ,'methods',{'o'} ,'ITerations', 10 ,'PRCT',-0.8,'RANGE',0 );  %,'plot'); close(gcf);drawnow
    %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) );
  end
    
end

function OUT = thisTModel_SE( ACTION , IN , iZ , Z , R , TZ )
  switch lower( ACTION )
    case 'applyconstraints'
      OUT = IN(:);

      OUT(3) = BoundsConstraint( OUT(3) , TZ );
      OUT(6) = BoundsConstraint( OUT(6) ,  R );
      
    case 'parameter2matrix'
      IN(3) = BoundsConstraint( IN(3) , TZ );
      IN(6) = BoundsConstraint( IN(6) ,  R );

      t = IN(1:3);
      r = IN(4:6);
      r(3) = r(3) / 180 * pi;
      r = rodrigues( aer2xyz( r ) );
      
      OUT = Z * [ r , t(:) ; 0 , 0 , 0 , 1 ] * iZ;
      
    case 'matrix2parameter'
      H = iZ * IN * Z;
      
      t = H(1:3,4);
      t(3) = iBoundsConstraint( t(3) , TZ );
      if ( BoundsConstraint( t(3) , TZ ) - H(3,4) )^2 > 1e-15
        t(3) = Optimize( @(z)( ( BoundsConstraint( z , TZ ) - H(3,4) ).^2 ) ,...
          t(3) ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden','quadratic'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
      end
      
      r = logmrot( H(1:3,1:3) );
      r = xyz2aer( [ r(3,2) , r(1,3) , r(2,1) ] );
      r(3) = r(3) / pi * 180;
      r(3) = iBoundsConstraint( r(3) , R );
      if fro2( rodrigues( aer2xyz( [ r(1) , r(2) , BoundsConstraint( r(3) , R ) / 180 * pi ] ) ) - H(1:3,1:3)  ) > 1e-15
        r = Optimize( @(r)fro2( rodrigues( aer2xyz( [ r(1) , r(2) , BoundsConstraint( r(3) , R ) / 180 * pi ] ) ) - H(1:3,1:3)  ) ,...
          r ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-15));
        %BoundsConstraint( r(3) ,R ) - acosd( ( trace( H(1:3,1:3) ) - 1 )/2 )
      end

      OUT = [ t(:) ; r(:) ];
    
    case 'precenter'
      n = numel( IN );
      
      W = ones( 1 , n );
      
      G = {};
      
      
      Rs = computeRs( IN , eye(4) , Z , iZ );
      printf('Rs  before precenter: '); printf(' \b %g ' , Rs ); printf(' \b(%g)',max(abs(Rs))); printf(' \b\n');
      for it = 1:5

        g = ExhaustiveSearch( @(r)max( abs( computeRs( IN , maketransform('l_xyz',r ) , Z , iZ ) ) ),[0;0;0] , 1 , 3 ,'maxITERATIONS' , 50 );
        G{end+1,1} = maketransform( 'l_xyz' , g );
        for r = 1:n, IN{r} = G{end} * IN{r}; end

        g = ExhaustiveSearch( @(r)max( abs( computeRs( IN , maketransform('rxyz',r ) , Z , iZ ) ) ),[0;0;0] , 1 , 3 ,'maxITERATIONS' , 50 );
        G{end+1,1} = maketransform( 'rxyz' , g );
        for r = 1:n, IN{r} = G{end} * IN{r}; end

        if maxnorm( G{end-1} - eye(4) ) < 1e-8  &&  maxnorm( G{end} - eye(4) ) < 1e-8 , break; end
      end
      Rs = computeRs( IN , eye(4) , Z , iZ );
      printf('Rs  after  precenter: '); printf(' \b %g ' , Rs ); printf(' \b(%g)',max(abs(Rs))); printf(' \b\n');
      
      
      Ts = computeTs( IN , eye(4) , Z , iZ );
      printf('T   before precenter: '); printf(' \b %g ' , Ts ); printf(' \b(%g)',max(abs(Ts))); printf(' \b\n');
      for it = 1:15
        g = bestT( IN , Z , iZ , it );
        G{end+1,1} = [ eye(3) , g(:) ; 0 , 0 , 0 , 1 ];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      Ts = computeTs( IN , eye(4) , Z , iZ );
      printf('T   after  precenter: '); printf(' \b %g ' , Ts ); printf(' \b(%g)',max(abs(Ts))); printf(' \b\n');


      TZs = computeTZs( IN , eye(4) , Z , iZ );
      printf('TZ  before precenter: '); printf(' \b %g ' , TZs ); printf(' \b(%g)',max(abs(TZs))); printf(' \b\n');
      for it = 1:15
        g = bestTZ( IN , Z , iZ , W , it );
        G{end+1,1} = [ eye(3) , g(:) ; 0 , 0 , 0 , 1 ];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      TZs = computeTZs( IN , eye(4) , Z , iZ );
      printf('TZ  after  precenter: '); printf(' \b %g ' , TZs ); printf(' \b(%g)',max(abs(TZs))); printf(' \b\n');
%       if any( TZs < -(1+1e5*eps(1))*TZ ) ||...
%          any( TZs >  (1+1e5*eps(1))*TZ )
%         warning('Current TZs out of TZrange.');
%       end


      SE = @(p)maketransform('rxyz',p(1:3),'t',p(4:6));
      for it = 1:10
        g = Optimize( @(p)abs(max( ...
          [ abs( computeTZs( IN , SE(p) , Z , iZ ) ) / TZ ,...
            abs( computeRs(  IN , SE(p) , Z , iZ ) ) / R ] ...
          )),[0;0;0;0;0;0] ,...
          'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden','quadratic'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150) );

        G{end+1,1} = SE(g);
        for r = 1:n, IN{r} = G{end} * IN{r}; end
      end

      Rs = computeRs( IN , eye(4) , Z , iZ );
      printf('*Rs after  precenter: '); printf(' \b %g ' , Rs ); printf(' \b(%g)',max(abs(Rs))); printf(' \b\n');
      TZs = computeTZs( IN , eye(4) , Z , iZ );
      printf('*TZ after  precenter: '); printf(' \b %g ' , TZs ); printf(' \b(%g)',max(abs(TZs))); printf(' \b\n');

      
      
      
      
      OUT = eye(4);
      for r = 1:numel( G )
        OUT = G{r} * OUT;
      end
  end

end



function z = BoundsConstraint( z , r )
  z = r * tanh( z / r );
end
function z = iBoundsConstraint( z , r )
  z = min( 20 * r , abs( r * atanh( z / r ) ) ) .* sign( z );
end

function g = bestT( IN , Z , iZ , it )
  n = numel( IN );
  T = zeros(3*n,1); R = zeros(3*n,3);
  for r = 1:n
    T( ( 3*(r-1)+1 ):( 3*r ) ,1) = iZ{r}(1:3,1:3) * IN{r}(1:3,1:3) * Z{r}(1:3,4) + iZ{r}(1:3,1:3) * IN{r}(1:3,4) + iZ{r}(1:3,4);
    R( ( 3*(r-1)+1 ):( 3*r ) ,:) = iZ{r}(1:3,1:3);
  end

  if rem(it,2)
    g = Optimize(         @(g)maxnorm( fro2( reshape( T + R*g ,3,[]) ,1) ) ,[0;0;0], 'methods',{'conjugate','coordinate',1},'verbose',0,'noplot' );
  else
    g = ExhaustiveSearch( @(g)maxnorm( fro2( reshape( T + R*g ,3,[]) ,1) ) ,[0;0;0], 1 , 3 ,'maxTIME' , 20 );
  end
end
function g = bestTZ( IN , Z , iZ , W , it )
  n = numel( IN );
  
  T = zeros(n,1); R = zeros(n,3);
  for r = 1:n
    T(r,:) = iZ{r}(3,1:3) * IN{r}(1:3,1:3) * Z{r}(1:3,4) + iZ{r}(3,1:3) * IN{r}(1:3,4) + iZ{r}(3,4);
    R(r,:) = iZ{r}(3,1:3);
  end
  
  w = ~~W;
  T = T(w,:);
  R = R(w,:);
  W = W(w);

  T = diag(W) * T;
  R = diag(W) * R;

  if rem(it,2)
    g = Optimize(         @(g)maxnorm(( R*g + T ))+fro(g)/1e6,[0;0;0],'methods',{'conjugate','coordinate',1},'verbose',0,'noplot');
  else
    g = ExhaustiveSearch( @(g)maxnorm(( R*g + T ))+fro(g)/1e4,[0;0;0], 1 , 3 ,'maxTIME' , 20 );
  end
end
function Ts = computeTs( MS , G , Z , iZ )
  n = numel( MS );
  Ts = zeros( 1 , n );
  for r = 1:n
    H = iZ{r} * G * MS{r} * Z{r};
    Ts(r) = sqrt( H(1,4)^2 + H(2,4)^2 + H(3,4)^2 );
  end
end
function TZs = computeTZs( MS , G , Z , iZ )
  n = numel( MS );
  TZs = zeros( 1 , n );
  for r = 1:n
    H = iZ{r} * G * MS{r} * Z{r};
    TZs(r) = H(3,4);
  end
end
function Rs = computeRs( MS , G , Z , iZ )
  n = numel( MS );
  Rs = zeros( 1 , n );
  for r = 1:n
    H = iZ{r} * G * MS{r} * Z{r};

    p = ( H(1,1) + H(2,2) + H(3,3) - 1 )/2;
    p = real( acosd( max(min(p,1),-1) ) );

    Rs(r) = abs(p);
  end
end
function xyz = aer2xyz( aer )
  z = aer(3) .* sin( aer(2) );
  c = aer(3) .* cos( aer(2) );
  x = c .* cos( aer(1) );
  y = c .* sin( aer(1) );
  xyz = [ x , y , z ];
end
function aer = xyz2aer( xyz )
  h = hypot( xyz(1) , xyz(2) );
  r = hypot( h      , xyz(3) );
  e = atan2( xyz(3) , h      );
  a = atan2( xyz(2) , xyz(1) );
  
  aer = [ a , e , r ];
end


function E = ENER( X , S , energyFCN )
  if ~iscell( X ), X = {X}; end
  if ~iscell( S ), S = {S}; end
  
  D = [];
  for c = 1:numel(X)
    if isempty( X{c} ), continue; end
    if isempty( S{c} ), continue; end
    [~,cp,d] = vtkClosestElement( S{c} , X{c} );
    D = [ D ; d(:) ];
  end
  E = energyFCN( D );
end
