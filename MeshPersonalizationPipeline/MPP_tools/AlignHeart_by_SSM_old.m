function [TS,H,M] = AlignHeart_by_SSM( HF )

  ANNEALING_FACTOR = 2.5;

  LAS = { getPlane(HF{1,1}) , getPlane(HF{2,1}) , getPlane(HF{3,1}) };

  [Z,iZ] = getPlane( HF{end,1} );
  
  %%
  signedDistance = @(b,I)bsxfun(@times, reshape( ClosestElement( b , I.XYZ , true ) , size( I ,1:3) ) , ( ~inpoly( I ,b) * 2 - 1 ) );

  if true
    M = ConvhullMesh( cell2mat( vec( HF(:,2:end) ) ) );
    for h = 1:size(HF,1)
      if isempty( HF{h,1} ), continue; end
    %   HS{h,1} = HS{h,1}.t1;
                              d2M  = signedDistance( M                     , HF{h,1} );
      if ~isempty( HF{h,3} ), d2LV = signedDistance( HF{h,3}               , HF{h,1} );
      else,                   d2LV = 0;
      end
      if ~isempty( HF{h,4} ), d2RV = signedDistance( [ HF{h,4} ; HF{h,6} ] , HF{h,1} );
      else,                   d2RV = 0;
      end
      HF{h,1}.FIELDS.mask = d2M < 7  &  d2LV > -7  &  d2RV > -7; %imagesc( mask(:,:,1,1) )
    end
  end
  
   POSES = repmat( {eye(4)} , size(HF,1),1);
  iPOSES = repmat( {eye(4)} , size(HF,1),1);
  for h = 1:size(HF,1)
    I = HF{h,1};
    
    try, I.data( ~I.FIELDS.mask ) = NaN; end
    I = crop( I , 0 , 'mask' , ~isnan( I.data ) );
    
     POSES{h} = [ I.SpatialTransform(1:3,1:3) , I.center(:) ; 0 0 0 1 ];
    iPOSES{h} = minv( POSES{h} );
  end
  %%

  Mh_     = loadv( 'e:\Dropbox\Vigente\shared\MeshPersonalizationPipeline\HEART\HEART_MODEL.mat' , 'Mh_' );
  sM_     = getv( getv( getv( functions( Mh_ ) , '.workspace' ) , {1} ) , '.sM' );
  sMODES_ = getv( getv( getv( functions( Mh_ ) , '.workspace' ) , {1} ) , '.sMODES_' );

  LV = Mh_(0);
  LVt = LV.tri( all( LV.xyzLABEL( LV.tri ) == 0 ,2) ,:);
  LVt( all( reshape( LV.xyz( LVt ,3) ,[],3) > 40 ,2) ,:) = [];
  [a,~,c] = unique( LVt );
  LVt   = reshape( c , size(LVt) );
  w       = false(size(sM_)); w(a,:) = true;
  LVm     = reshape( sM_( w ) ,[],3);
  LVmodes = sMODES_( w(:) ,:);
  LV = struct( 'xyz' , LVm , 'tri' , LVt );
  LV.triID = ( 1:size(LV.tri,1) ).';
  LV   = MeshBoundary( LV );
  LVb  = LV.tri;
  LVbe = unique( LV.triID );


  RV = Mh_(0);
  RVt = RV.tri( all( RV.xyzLABEL( RV.tri ) == 2 ,2) ,:);
  RVt( all( reshape( RV.xyz( RVt ,3) ,[],3) > 38 ,2) ,:) = [];
  [a,~,c] = unique( RVt );
  RVt = reshape( c , size(RVt) );
  w         = false(size(sM_)); w(a,:) = true;
  RVm   = reshape( sM_( w ) ,[],3);
  RVmodes = sMODES_( w(:) ,:);
  RV = struct( 'xyz' , RVm , 'tri' , RVt );
  RV.triID = ( 1:size(RV.tri,1) ).';
  RV   = MeshBoundary( RV );
  RVb  = RV.tri;
  RVbe = unique( RV.triID );
  
  SSM  = @(q) { struct( 'tri' , LVt , 'xyz' , reshape( LVmodes(:,1:numel(q)+1)*[q(:);0] , size(LVm) ) + LVm , 'BoundaryElements' , LVbe , 'Boundary', LVb , 'percentage_of_points_on_boundary' , 0.1 ) ,...
                struct( 'tri' , RVt , 'xyz' , reshape( RVmodes(:,1:numel(q)+1)*[q(:);0] , size(RVm) ) + RVm , 'BoundaryElements' , RVbe , 'Boundary', RVb , 'percentage_of_points_on_boundary' , 0.1 ) };

  %%
  
  %CS = HS(:,[2 4]);
  CS = cell( size(HF,1) , 2 );
  for r = 1:size(HF,1)
    CS{r,1} = [ HF{r,2} ; NaN(1,3) ; HF{r,6} ; NaN(1,3) ; HF{r,7} ];
    while numel(CS{r,1}) && isnan( CS{r,1}( 1 ) ), CS{r,1}( 1 ,:) = []; end
    while numel(CS{r,1}) && isnan( CS{r,1}(end) ), CS{r,1}(end,:) = []; end
    
    if ~isempty( CS{r,1} )
      CS{r,1} = polyline( CS{r,1} );
      for p = 1:CS{r,1}.np, CS{r,1}(p) = resample( CS{r,1}(p) , '+e' , 0.1 ); end
      CS{r,1} = double( CS{r,1} );
    end

    CS{r,2} = HF{r,4};
    if ~isempty( CS{r,2} )
      CS{r,2} = polyline( CS{r,2} );
      for p = 1:CS{r,2}.np, CS{r,2}(p) = resample( CS{r,2}(p) , '+e' , 0.1 ); end
      CS{r,2} = double( CS{r,2} );
    end
  end
  
  TS = repmat( {eye(4)} , size(HF,1),1);
  H  = TS;

  T = [];  q = [];  LAMBDA = 0;
  [q,T] = fitSSM( SSM , 'l_sxyzt' , transform( CS , iZ ) , LAMBDA , q , T ); T = Z * T;
  %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) );

  T = {T}; q = {40}; LAMBDA = 0.001*ANNEALING_FACTOR^11;
  [q,T] = fitSSM( SSM , 'l_sxyzt' , CS , LAMBDA , q , T , 'range' , 5 );
  %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) );
  
  %%
  withoutContours = ~all( cellfun('isempty',HF(:,2:end)) ,2);
  for TMcase = 1:4
    printf('\n\n\n');
    printf('********************************************************\n')
    printf('(%s)  TMcase:: %d\n', datestr(now), TMcase );
    printf('**********\n')
    switch TMcase
      case 1, TModel = @(varargin)thisTModel_Translations( varargin{:} , 0.001 , LAS );                     continue;
      case 2, TModel = @(varargin)thisTModel_Translations( varargin{:} , 2     , LAS );                     continue;
      case 3, TModel = @(varargin)thisTModel_inPlaneRot_Translations( varargin{:} , 2.5/180*pi , 3 , LAS ); continue;
      case 4
        TModel = @(varargin)thisTModel_SE( varargin{:} , 5/180*pi , 4 , LAS );
        %TModel = @(varargin)thisTModel_SE( varargin{:} , 15/180*pi , 5 , LAS );
        %continue;
    end

    nITS = 1;
    if TMcase == 4, nITS = 5; end
    for it = 0:nITS
      if ~rem(it,2)
        LAMBDA = LAMBDA / ANNEALING_FACTOR;  fprintf('\n\nLAMBDA = %g\n\n\n',LAMBDA);
        T = {T};
      end
      [q,T] = fitSSM( SSM , 'l_sxyzt' , transform( CS , TS ) , LAMBDA^2 , q , T , 'range' , 5 );

      for iit = 1:3
        [TS,G] = SquareHeartSlicesToMesh( CS , TS , transform( SSM(q) , T ) , 'Transform' , @(x,T)transform(x,T) , 'POSES' , POSES ,'iPOSES', iPOSES  ,'TransformationMODEL', TModel);
        T = G * T;
        %figure; plot3d( transform( CS , TS ) , '*m','eq'); hplotMESH( transform( SSM(q) , T ) ); set( gcf , 'Name' , sprintf('it: %d    LAMBDA: %g',it,LAMBDA));
        H = [ H , TS ];
    end

%       if it > 0 && ~rem(it,4)
%         [TS,G] = AlignImages( HF(:,1) , TS ,'Levels',0,'ITERations',2,'FixedSlices', withoutContours ,'POSES',POSES,'iPOSES',iPOSES,'useMASK','FIRSTPHASE','TransformationMODEL', TModel); TS = TS(:,end);
%         T = G * T;
%         %MontageHeartSlices( transform( HF , TS ) );
%         H = [ H , TS ];
%       end

    end
  end
  M = transform( SSM(q) , T );

%   STIFFNESS = 1200;
%   for it = 1:0
%     STIFFNESS = STIFFNESS/1.025; fprintf('\n\nSTIFFNESS = %g\n\n\n',STIFFNESS);
%     
%     SURFACES = cell( size(HS,1) , size(HS,2)-1 );
%     fprintf('(Building surfaces ');
%     for c = 1:size(HS,2)-1
%       fprintf('+');
%       for r = 1:size(HS,1)
%         if isempty( HS{r,c+1} ), continue; end
%         w = [ 1:r-1 , r+1:size(HS,1) ];
%         SURFACES{r,c} = Contours2Surface_ez( transform( HS(w,c+1) , TS(w) ),...
%           'FARTHESTP_RESAMPLING',Inf,'RESOLUTION',25,...
%           'MAX_DEFORMATION_ITS',100,'FARTERPOINTS',200,...
%           'SMOOTH_STRENGTH',STIFFNESS,...
%           'blid',10,'ulid',-40);%,'plot');
% %         hplot3d( transform( HS(r,c+1) , TS(r) ) ,'m','LineWidth',3);
% %         close(gcf)
%       end
%       fprintf('\b*');
%     end
%     fprintf(')\n');
% 
%     [TS,G] = SquareHeartSlicesToMesh( HS(:,2:end) , TS , SURFACES , 'Transform' , @(x,T)transform(x,T) , 'POSES' , POSES ,'iPOSES', iPOSES  ,'TransformationMODEL', TModel);
%     %figure; plot3d( transform( HS(:,2:end) , TS ) , '*m','eq'); hplotMESH( transform( SURFACES(1,:) , G ) );
% 
%     [TS,G] = AlignImages( HS(:,1) , TS ,'Levels',0,'ITERations',2,'FixedSlices', withoutContours ,'POSES',POSES,'iPOSES',iPOSES,'useMASK','FIRSTPHASE','TransformationMODEL', TModel); TS = TS(:,end);
%     %MontageHeartSlices( transform( HS , TS ) );
% 
%     H = [ H , TS ];
%   end
    
end

function OUT = thisTModel_InPlaneTranslations( ACTION , IN , iZ , Z )
  switch lower( ACTION )
    case 'applyconstraints'
      OUT = IN;
    case 'parameter2matrix'
      OUT =  Z * [ eye(3) , [ IN(:) ; 0 ] ; 0 , 0 , 0 , 1 ] * iZ;   
    case 'matrix2parameter'
      TT = iZ * IN * Z;
      OUT = TT(1:2,4);
    case 'precenter'
      OUT = eye(4);
  end
end
function OUT = thisTModel_Translations( ACTION , IN , iZ , Z , TZrange , LAS )
  TZ  = @(x)BoundsConstraint( x ,  -TZrange ,  TZrange );
  switch lower( ACTION )
    case 'applyconstraints'
      isLA = IS_LA( iZ , LAS );
      
      OUT = IN(:);
      if ~isLA, OUT(3) = TZ( OUT(3) ); end

    case 'parameter2matrix'
      isLA = IS_LA( iZ , LAS );

      if ~isLA, IN(3) = TZ( IN(3) ); end
      OUT =  Z * [ eye(3) , IN(:) ; 0 , 0 , 0 , 1 ] * iZ;

    case 'matrix2parameter'
      isLA = IS_LA( iZ , LAS );

      H = iZ * IN * Z;
      OUT = H(1:3,4);
      if ~isLA, OUT(3) = iBoundsConstraint( OUT(3) , TZ  ); end

    case 'precenter'
      n = numel( IN );
      
      isLA = false(1,n);
      for r = 1:n, isLA(r) = IS_LA( iZ{r} , LAS ); end
      W = double( ~isLA );
      
      G = {};
      
      Ts = computeTs( IN , eye(4) , Z , iZ );
      fprintf('T  before precenter: '); fprintf(' %g ' , Ts ); fprintf('(%g)',max(abs(Ts))); fprintf('\n');
      for it = 1:15
        g = bestT( IN , Z , iZ , it );
        G{end+1,1} = [eye(3),g(:);0 0 0 1];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      Ts = computeTs( IN , eye(4) , Z , iZ );
      fprintf('T  after  precenter: '); fprintf(' %g ' , Ts ); fprintf('(%g)',max(abs(Ts))); fprintf('\n');


      TZs = computeTZs( IN , eye(4) , Z , iZ );
      fprintf('TZ  before precenter: '); fprintf(' %g ' , TZs ); fprintf('(%g)',max(abs(W.*TZs))); fprintf('\n');
      for it = 1:15
        g = bestTZ( IN , Z , iZ , W , it );
        G{end+1,1} = [eye(3),g(:);0 0 0 1];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      TZs = computeTZs( IN , eye(4) , Z , iZ );
      fprintf('TZ  after  precenter: '); fprintf(' %g ' , TZs ); fprintf('(%g)',max(abs(W.*TZs))); fprintf('\n');
      if any( W .* TZs < -(1+1e5*eps(1))*TZrange ) ||...
         any( W .* TZs >  (1+1e5*eps(1))*TZrange )
        warning('Current TZs out of TZrange.');
      end
      
      OUT = eye(4);
      for r = 1:numel( G )
        OUT = G{r} * OUT;
      end
      
  end

end
function OUT = thisTModel_inPlaneRot_Translations( ACTION , IN , iZ , Z , RZrange , TZrange , LAS )
  TZ = @(x)BoundsConstraint( x ,  -TZrange ,  TZrange );
  RZ = @(x)BoundsConstraint( x ,  -RZrange ,  RZrange );
  switch lower( ACTION )
    case 'applyconstraints'
      %Tx, Ty, Tz, RZ
      isLA = IS_LA( iZ , LAS );
      
      OUT = IN(:);
      if ~isLA, OUT(3) = TZ( OUT(3) ); end
      OUT(4) = RZ( OUT(4) );
      
    case 'parameter2matrix'
      %Tx, Ty, Tz, RZ
      isLA = IS_LA( iZ , LAS );

      if ~isLA, IN(3) = TZ( IN(3) ); end
      a = RZ( IN(4) );
      r = [ cos(a) , -sin(a) , 0 ; sin(a) , cos(a) , 0 ; 0 , 0 , 1 ];
      
      t = IN(1:3);
      
      OUT = Z * [ r , t(:) ; 0 , 0 , 0 , 1 ] * iZ;
      
    case 'matrix2parameter'
      isLA = IS_LA( iZ , LAS );

      H = iZ * IN * Z;
      
      p = [ H(1:3,4) ; real(acos( max(min(H(1,1),1),-1) )) * sign( H(2,1) ) ];
      if ~isLA
        p(3) = iBoundsConstraint( p(3) , TZ  );
        p(3) = Optimize( @(p)( ( TZ(p) - H(3,4) ).^2 ) ,...
          p(3) ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden','quadratic'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
      end

      p(4) = iBoundsConstraint( p(4) , RZ );
      r = @(a)[ cos(a) , -sin(a) ; sin(a) , cos(a) ];
      p(4) = Optimize( @(a)fro2( r( RZ(a) ) - H(1:2,1:2) ) ,...
          p(4) ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden','quadratic'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
      
      OUT = p(:);
    
    case 'precenter'
      n = numel( IN );
      
      isLA = false(1,n);
      for r = 1:n, isLA(r) = IS_LA( iZ{r} , LAS ); end
      W = double( ~isLA );
      
      G = {};
      
      Ts = computeTs( IN , eye(4) , Z , iZ );
      fprintf('T  before precenter: '); fprintf(' %g ' , Ts ); fprintf('(%g)',max(abs(Ts))); fprintf('\n');
      for it = 1:15
        g = bestT( IN , Z , iZ , it );
        G{end+1,1} = [eye(3),g(:);0 0 0 1];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      Ts = computeTs( IN , eye(4) , Z , iZ );
      fprintf('T  after  precenter: '); fprintf(' %g ' , Ts ); fprintf('(%g)',max(abs(Ts))); fprintf('\n');


      TZs = computeTZs( IN , eye(4) , Z , iZ );
      fprintf('TZ  before precenter: '); fprintf(' %g ' , TZs ); fprintf('(%g)',max(abs(W.*TZs))); fprintf('\n');
      for it = 1:15
        g = bestTZ( IN , Z , iZ , W , it );
        G{end+1,1} = [eye(3),g(:);0 0 0 1];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      TZs = computeTZs( IN , eye(4) , Z , iZ );
      fprintf('TZ  after  precenter: '); fprintf(' %g ' , TZs ); fprintf('(%g)',max(abs(W.*TZs))); fprintf('\n');
      if any( W .* TZs < -(1+1e5*eps(1))*TZrange ) ||...
         any( W .* TZs >  (1+1e5*eps(1))*TZrange )
        warning('Current TZs out of TZrange.');
      end

      
      OUT = eye(4);
      for r = 1:numel( G )
        OUT = G{r} * OUT;
      end
  end

end
function OUT = thisTModel_SE( ACTION , IN , iZ , Z , Rrange , TZrange , LAS )
  TZ = @(x)BoundsConstraint( x ,  -TZrange ,  TZrange );
  R  = @(x)BoundsConstraint( x ,  -Rrange  ,  Rrange  );
  switch lower( ACTION )
    case 'applyconstraints'
      %Tx, Ty, Tz, Raz, Eel, Rmag
      isLA = IS_LA( iZ , LAS );
      
      OUT = IN(:);
      if ~isLA, OUT(3) = TZ( OUT(3) ); end
      OUT(6) = R( OUT(6) );
      
    case 'parameter2matrix'
      %Tx, Ty, Tz, Raz, Eel, Rmag
      isLA = IS_LA( iZ , LAS );

      if ~isLA, IN(3) = TZ( IN(3) ); end
      IN(6) = R( IN(6) );

      t = IN(1:3);
      r = IN(4:6);
      r = rodrigues( aer2xyz( r ) );
      
      OUT = Z * [ r , t(:) ; 0 , 0 , 0 , 1 ] * iZ;
      
    case 'matrix2parameter'
      isLA = IS_LA( iZ , LAS );

      H = iZ * IN * Z;
      
      t = H(1:3,4);
      if ~isLA
        t(3) = iBoundsConstraint( t(3) , TZ  );
        t(3) = Optimize( @(p)( ( TZ(p) - H(3,4) ).^2 ) ,...
          t(3) ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
          'ls',{'quadratic','golden','quadratic'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
      end
      
      r = logmrot( H(1:3,1:3) );
      r = xyz2aer( [ r(3,2) , r(1,3) , r(2,1) ] );
      r(3) = iBoundsConstraint( r(3) , R  );
      r = Optimize( @(r)fro2( rodrigues( aer2xyz( [r(1) r(2) R(r(3))] ) ) - H(1:3,1:3)  ) ,...
        r ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},...
        'ls',{'quadratic','golden'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-15));
      
      OUT = [ t(:) ; r(:) ];
    
    case 'precenter'
      n = numel( IN );
      
      isLA = false(1,n);
      for r = 1:n, isLA(r) = IS_LA( iZ{r} , LAS ); end
      fprintf('isLA: '); fprintf(' %d ', isLA ); fprintf('\n');
      W = double( ~isLA );
      
      G = {};
      
      
      Rs = computeRs( IN , eye(4) , Z , iZ );
      fprintf('Rs  before precenter: '); fprintf(' %g ' , Rs ); fprintf('(%g)',max(abs(Rs))); fprintf('\n');
      for it = 1:15
        if rem(it,2)
          g = ExhaustiveSearch( @(r)max( abs( computeRs( IN , maketransform('l_xyz',r ) , Z , iZ ) ) ),[0;0;0] , 1 , 3 ,'maxITERATIONS' , 50 );
          G{end+1,1} = maketransform( 'l_xyz' , g );
        else
          g = ExhaustiveSearch( @(r)max( abs( computeRs( IN , maketransform('rxyz',r ) , Z , iZ ) ) ),[0;0;0] , 1 , 3 ,'maxITERATIONS' , 50 );
          G{end+1,1} = maketransform( 'rxyz' , g );
        end
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if maxnorm( G{end} - eye(4) ) < 1e-8, break; end
      end
      Rs = computeRs( IN , eye(4) , Z , iZ );
      fprintf('Rs  after  precenter: '); fprintf(' %g ' , Rs ); fprintf('(%g)',max(abs(Rs))); fprintf('\n');
      
      
      Ts = computeTs( IN , eye(4) , Z , iZ );
      fprintf('T  before precenter: '); fprintf(' %g ' , Ts ); fprintf('(%g)',max(abs(Ts))); fprintf('\n');
      for it = 1:15
        g = bestT( IN , Z , iZ , it );
        G{end+1,1} = [eye(3),g(:);0 0 0 1];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      Ts = computeTs( IN , eye(4) , Z , iZ );
      fprintf('T  after  precenter: '); fprintf(' %g ' , Ts ); fprintf('(%g)',max(abs(Ts))); fprintf('\n');


      TZs = computeTZs( IN , eye(4) , Z , iZ );
      fprintf('TZ  before precenter: '); fprintf(' %g ' , TZs ); fprintf('(%g)',max(abs(W.*TZs))); fprintf('\n');
      for it = 1:15
        g = bestTZ( IN , Z , iZ , W , it );
        G{end+1,1} = [eye(3),g(:);0 0 0 1];
        for r = 1:n, IN{r} = G{end} * IN{r}; end
        if max( abs(g) ) < 1e-8, break; end
      end
      TZs = computeTZs( IN , eye(4) , Z , iZ );
      fprintf('TZ  after  precenter: '); fprintf(' %g ' , TZs ); fprintf('(%g)',max(abs(W.*TZs))); fprintf('\n');
      if any( W .* TZs < -(1+1e5*eps(1))*TZrange ) ||...
         any( W .* TZs >  (1+1e5*eps(1))*TZrange )
        warning('Current TZs out of TZrange.');
      end

      
      OUT = eye(4);
      for r = 1:numel( G )
        OUT = G{r} * OUT;
      end
  end

end



function isLA = IS_LA( iZ , LAS )
  for l = 1:numel(LAS)
    H = iZ*LAS{l};
    if maxnorm( abs( H(1:3,3) ) - [0;0;1] ) < 1e-8 && abs( H(3,4) ) < 1e-8
      isLA = true;
      return;
    end
  end
  isLA = false;
end
function z = BoundsConstraint( z , lb , ub )
  if lb > ub
    error('lb must be lower than ub');
  end
  if lb == ub
    z = lb; return;
  end
  if isinf(lb) && isinf(ub)
    return;
  end
  if isinf(lb)
    z = ub - exp(z); return;
  end
  if isinf(ub)
    z = lb + exp(z); return;
  end
  z = ( lb + ub )/2 + ( ub - lb )/2*tanh( 2 * z / ( ub - lb ) );
end
function z = iBoundsConstraint( z , f )
  lb = f(-Inf);
  ub = f(+Inf);
  
  if isinf( lb ) && isinf( ub ), return; end

  if     z <= lb, z = -10*(ub-lb);
  elseif z >= ub, z =  10*(ub-lb);
  else
    z = atanh( ( 2*z - lb - ub )/( ub - lb ) )*( ub - lb )/2;
  end
  if isinf( z ) && z > 0, z =  10*(ub-lb); end
  if isinf( z ) && z < 0, z = -10*(ub-lb); end
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
    p = real( acos( max(min(p,1),-1) ) );

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

