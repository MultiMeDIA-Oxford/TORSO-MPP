function M = MeshKneading( M , XYZ , varargin )
%{

MeshKneading( Mesh , ATTRACTORS , Nits )
MeshKneading( Mesh , ATTRACTORS , Nits , PERCENTAGES )
MeshKneading( Mesh , ATTRACTORS , Nits , PERCENTAGES , LAMBDAS )
MeshKneading( Mesh , ATTRACTORS , Nits , PERCENTAGES , LAMBDAS , PullOnBoundaires )

MeshKneading( Mesh , [ 'its' , Nits ] ,
                     [ 'PERCENTAGES' , PERCENTAGES ] ,
                     [ 'LAMBDAS' , LAMBDAS ] ,
                     [ 'CLOSEST' , CLOSEST ] ,
                     [ 'SAMPLING' , SAMPLING ] ,
                     [ 'SUBDIVIDE' , SUBDIVIDE ] ,
                     [ 'SMOOTH' , SMOOTH ] ,
                     [ 'DECIMATE' , DECIMATE ] ,
                     [ 'REMESH' , REMESH ] ,
                     [ 'VERBOSE' ] ,
                     [ 'VPLOT' ] ,
                     [ 'PLOTFCN' , PLOTFCN ] );

%}

  M = Mesh( M ,0);
  %M = MeshTidy( M ,NaN,true);

  if size( XYZ ,2) ~= 3, error('only for 3d points'); end
  if size( XYZ ,1) < 4,  error('too few points?'); end

  XYZ = double( XYZ );
  XYZ( any( ~isfinite( XYZ ) ,2) ,:) = [];
  XYZ = unique( XYZ ,'rows','stable');

  
  %% DEFAULTS
  N_ITS       = 20;
  
  DECIMATE    = [];         DECIMATE_   = 20;
  SUBDIVIDE   = [];         SUBDIVIDE_  = 20;
  SMOOTH      = [];         SMOOTH_     = 20;
  REMESH      = [];         REMESH_     = 20;
  SAMPLING    = [];         SAMPLING_   = 5;
  CLOSEST     = true;
  
  PERCENTAGES = 0.2;
  LAMBDAS     = Inf;
  
  VERBOSE     = false;
  VPLOT       = false;
  PLOT_FCN    = 'defaultPLOT';
  
  
  %%
  
  for v = 1:( find( cellfun( @ischar , [varargin,' '] ) ,1)-1 )
    switch v
      case 1, if ~isempty( varargin{v} ),  N_ITS       = varargin{v}; end
      case 2, if ~isempty( varargin{v} ),  PERCENTAGES = varargin{v}; end
      case 3, if ~isempty( varargin{v} ),  LAMBDAS     = varargin{v}; end
      case 4, if ~isempty( varargin{v} ),  CLOSEST     = varargin{v}; end
      case 5
        if ~isempty( varargin{v} )
          DECIMATE_   = varargin{v};
          SUBDIVIDE_  = varargin{v};
          SMOOTH_     = varargin{v};
          REMESH_     = varargin{v};
        end
      otherwise, error('check varargin!!');
    end
  end
  varargin(1:v) = [];

  
  %% parsing N_ITS
  [varargin,~,N_ITS] = parseargs(varargin,'its','n','$DEFS$',N_ITS );
  if N_ITS <= 0, return; end

  
  %% parsing PERCENTAGES
  [varargin,~,PERCENTAGES] = parseargs(varargin,'PERCENTAGES','$DEFS$',PERCENTAGES );
  if any( PERCENTAGES <= 0 | PERCENTAGES > 1 )
    error('PERCENTAGES must be between 0 and 1.');
  end
  
  
  %% parsing LAMBDAS
  [varargin,~,LAMBDAS] = parseargs(varargin,'LAMBDAS','$DEFS$',LAMBDAS );
  
  
  %% parsing CLOSEST
  % if it a logical, it means if to pull from the boundary or not
  [varargin,~,CLOSEST   ] = parseargs(varargin,'CLOSEST',   '$DEFS$',CLOSEST    );
  if islogical( CLOSEST )
    CLOSEST = @(A,M)defCLOSEST( A , M , CLOSEST );
  end
  if ~isa( CLOSEST , 'function_handle' ), error('invalid CLOSEST'); end
  
  
  %% parsing SAMPLING
  % If it a number, it is used as minimum distance in FarthestPointSampling.
  % As a cell, the first is the action while the second the iterations when to do it.
  [varargin,~,SAMPLING  ] = parseargs(varargin,'SAMPLING',  '$DEFS$',SAMPLING   );
  if iscell( SAMPLING ), SAMPLING_ = SAMPLING{2}; SAMPLING = SAMPLING{1}; end
  if isempty( SAMPLING ), SAMPLING_ = false; SAMPLING = @(XYZ,varargin)XYZ; end
  if isnumeric( SAMPLING ), SAMPLING = @(XYZ,M)defSAMPLING( XYZ , M , SAMPLING ); end
  if ~isa( SAMPLING , 'function_handle' ), error('invalid SAMPLING'); end
  SAMPLING_ = IterationsToDoIt( SAMPLING_ , N_ITS );
  

  %% parsing DECIMATE
  % If it a number, it is the keep factor
  [varargin,~,DECIMATE  ] = parseargs(varargin,'DECIMATE',  '$DEFS$',DECIMATE   );
  if iscell( DECIMATE ), DECIMATE_ = DECIMATE{2}; DECIMATE = DECIMATE{1}; end
  if isempty( DECIMATE ), DECIMATE_ = false; DECIMATE = @()false; end
  if isnumeric( DECIMATE ), DECIMATE = @(M)defDECIMATE( M , DECIMATE ); end
  if ~isa( DECIMATE , 'function_handle' ), error('invalid DECIMATEa'); end
  DECIMATE_ = IterationsToDoIt( DECIMATE_ , N_ITS );
  
  
  %% parsing SUBDIVIDE
  % If it char (a string), it is method in MeshSubdivide
  [varargin,~,SUBDIVIDE  ] = parseargs(varargin,'SUBDIVIDE',  '$DEFS$',SUBDIVIDE   );
  if iscell( SUBDIVIDE ), SUBDIVIDE_ = SUBDIVIDE{2}; SUBDIVIDE = SUBDIVIDE{1}; end
  if isempty( SUBDIVIDE ), SUBDIVIDE_ = false; SUBDIVIDE = @()false; end
  if ischar( SUBDIVIDE ), SUBDIVIDE = @(M)defSUBDIVIDE( M , SUBDIVIDE ); end
  if ~isa( SUBDIVIDE , 'function_handle' ), error('invalid SUBDIVIDE'); end
  SUBDIVIDE_ = IterationsToDoIt( SUBDIVIDE_ , N_ITS );
  
  
  %% parsing SMOOTH
  [varargin,~,SMOOTH  ] = parseargs(varargin,'SMOOTH',  '$DEFS$',SMOOTH   );
  if iscell( SMOOTH ), SMOOTH_ = SMOOTH{2}; SMOOTH = SMOOTH{1}; end
  if isempty( SMOOTH ), SMOOTH_ = false; SMOOTH = @()false; end
  if isnumeric( SMOOTH ), SMOOTH = @(M)defSMOOTH( M , SMOOTH ); end
  if ~isa( SMOOTH , 'function_handle' ), error('invalid SMOOTH'); end
  SMOOTH_ = IterationsToDoIt( SMOOTH_ , N_ITS );


  %% parsing REMESH
  % no default remeshing... but you can provide one!
  [varargin,~,REMESH  ] = parseargs(varargin,'REMESH',  '$DEFS$',REMESH   );
  if iscell( REMESH ), REMESH_ = REMESH{2}; REMESH = REMESH{1}; end
  if isempty( REMESH ), REMESH_ = false; REMESH = @()false; end
  %if isnumeric( REMESH ), REMESH = @(M)defDECIMATE( M , REMESH ); end
  if ~isa( REMESH , 'function_handle' ), error('invalid REMESH'); end
  REMESH_ = IterationsToDoIt( REMESH_ , N_ITS );
  
  
  %% parsing VERBOSE
  [varargin,VERBOSE] = parseargs(varargin,'Verbose','$FORCE$',{true,VERBOSE} );
  if VERBOSE, vprintf = @(varargin)fprintf(varargin{:});
  else,       vprintf = @(varargin)0;
  end
  
  
  %% parsing PLOT_FNC
  [varargin,VPLOT] = parseargs(varargin,'PLOT','$FORCE$',{true,VPLOT} );
  [varargin,~,PLOT_FCN] = parseargs(varargin,'PLOTfcn','$DEFS$',PLOT_FCN );
  if isa( PLOT_FCN , 'function_handle' )
    VPLOT = true;
  end
  if ~VPLOT, PLOT_FCN = @(varargin)true; end
  hFig = [];
  if ischar( PLOT_FCN ) && isequal( PLOT_FCN ,'defaultPLOT' )
    hFig = initiate_defPLOT( M , XYZ );
    PLOT_FCN = @( M , it , mode , hFig )defPLOT( M , it , mode , hFig );
  end
  if ~isa( PLOT_FCN , 'function_handle' ), error('invalid PLOT_FCN'); end
  
  
  %% Start!!
  IT = 0; vprintf('--------------------------------------------------\niteration: %3d    (%d,%d)\n', IT ,size(M.xyz,1),size(M.tri,1));

  vprintf('*SAMPLING ... ');
  PLOT_FCN( [] , IT , 'SAMPLING' , hFig );
  A = SAMPLING( XYZ , M );
  vprintf('(%d points)\n', size( A ,1) );
  PLOT_FCN( A , IT , 'SAMPLING' , hFig );

  %vprintf('\n');
  while IT < N_ITS
    IT = IT+1; vprintf('--------------------------------------------------\niteration: %3d    (%d,%d)\n', IT ,size(M.xyz,1),size(M.tri,1));

    if DECIMATE_(min(IT,end))
      vprintf('*DECIMATE ... ');
      PLOT_FCN( [] , IT , 'DECIMATE' , hFig );
      M = DECIMATE( M );
      vprintf('(%d points , %d faces)\n', size(M.xyz,1) , size(M.tri,1) );
      PLOT_FCN( M , IT , 'DECIMATE' , hFig );
    end
    
    if SUBDIVIDE_(min(IT,end))
      vprintf('*SUBDIVIDE ... ');
      PLOT_FCN( [] , IT , 'SUBDIVIDE' , hFig );
      M = SUBDIVIDE( M );
      vprintf('(%d points , %d faces)\n', size(M.xyz,1) , size(M.tri,1) );
      PLOT_FCN( M , IT , 'SUBDIVIDE' , hFig );
    end

    if SMOOTH_(min(IT,end))
      vprintf('*SMOOTH ... ');
      PLOT_FCN( [] , IT , 'SMOOTH' , hFig );
      M = SMOOTH( M );
      vprintf('ok\n');
      PLOT_FCN( M , IT , 'SMOOTH' , hFig );
    end
    
    if REMESH_(min(IT,end))
      vprintf('*REMESH... ');
      PLOT_FCN( [] , IT , 'REMESH' , hFig );
      M = REMESH( M );
      vprintf('(%d points , %d faces)\n', size(M.xyz,1) , size(M.tri,1) );
      PLOT_FCN( M , IT , 'REMESH' , hFig );
    end
    
    if SAMPLING_(min(IT,end))
      vprintf('*SAMPLING ... ');
      PLOT_FCN( [] , IT , 'SAMPLING' , hFig );
      A = SAMPLING( XYZ ,M);
      vprintf('(%d points)\n', size( A ,1) );
      PLOT_FCN( A , IT , 'SAMPLING' , hFig );
    end
    
    vprintf('*CLOSEST ... ');
    PLOT_FCN( [] , IT , 'CLOSEST' , hFig );
    C = CLOSEST( A , M );
    vprintf('(ok)\n');
    PLOT_FCN( C , IT , 'CLOSEST' , hFig );

    if isa( PERCENTAGES , 'function_handle' ), thisPERCENTAGE = PERCENTAGES( IT );
    else,                                      thisPERCENTAGE = PERCENTAGES( min(IT,end) );
    end
    if isa( LAMBDAS , 'function_handle' ),     thisLAMBDA = LAMBDAS( IT );
    else,                                      thisLAMBDA = LAMBDAS( min(IT,end) );
    end
    if thisLAMBDA < 0   %normalize by the number of points
      thisLAMBDA = -thisLAMBDA / size( A ,1);
    end
    
    vprintf('*PULLING (prct: %g , lambda: %g) ... ',thisPERCENTAGE,thisLAMBDA);
    PLOT_FCN( [] , IT , 'PULL' , hFig );
    U = (A-C)*thisPERCENTAGE;
    %U = U + C; U = U - C;
    M.xyz = M.xyz + InterpolatingSplines( C , U , M.xyz , 'r' ,'LAMBDA' , thisLAMBDA ); %LAMBDA/size(cp,1)    
    vprintf('(ok)\n');
    PLOT_FCN( M , IT , 'PULL' , hFig );
    
  end
  
  %%
  
end
function C = defCLOSEST( A , M , PullOnBoundaries )
  [d,C] = distanceFrom( A , M , ~PullOnBoundaries );
  C( d < 0 ,:) = NaN;
end
function A = defSAMPLING( XYZ , M , FPSopts )
  persistent lastA
  persistent lastXYZ
  persistent lastM
  persistent lastID
  
  if isequal( XYZ , lastXYZ )     &&...
     isequal( M.xyz , lastM.xyz ) &&...
     isequal( M.tri , lastM.tri )
    ID = lastID;
  else
    [~,~,d] = vtkClosestElement( M , XYZ );
    [~,ID] = max( d );
    lastXYZ = XYZ;
    lastM   = M;
  end
  
  if lastID == ID
    A = lastA;
    return;
  end
  lastID = ID;
  
  if ~iscell( FPSopts )
    if FPSopts < 0
      FPSopts = { 0 , -FPSopts };
    else
      FPSopts = { FPSopts };
    end
  end
  
%   fprintf( '  SAMPLED!! ' );
  A = FarthestPointSampling( XYZ , ID , FPSopts{:} );

  lastA   = A;

end
function M = defSUBDIVIDE( M , method )
  M = MeshTidy( M ,0,true );
  try
    M = MeshSubdivide( M , method );
  catch
    warning('"%s" Subdivision failed.! using a Linear Subdivision.', method);
    M = MeshSubdivide( M , 'default' );
  end
end
function M = defSMOOTH( M , its )
  M = MeshSmooth( M , its , 'vtk' , 'lambda' , 0.1 );
end
function M = defDECIMATE( M , tr )
  M = vtkQuadricDecimation( M , 'SetTargetReduction' , 1 - tr );
end
function hFig = initiate_defPLOT( M , XYZ )
    hFig = figure( 'HandleVisibility', 'on'     ,...
                            'ToolBar', 'figure' ,...
                      'IntegerHandle', 'on'     ,...
                           'NextPlot', 'add'    ,...
                        'NumberTitle', 'off'    ,...
                           'Renderer', 'openGL' ,...
                       'RendererMode', 'manual' );
    set( hFig , 'Colormap' , jet(256) );
                     
    hM = patch( 'Faces' , M.tri , 'Vertices' , M.xyz ,...
       'FaceAlpha',0.8,'EdgeColor','none',... %[1,1,1]*0.3,...
       'FaceColor',[1 1 1]*0.6 + [.6 .75 .75]*0 ,...
       'FaceLighting' , 'gouraud' ,...
       'AmbientStrength'  , 0.3 ,...
       'DiffuseStrength' , 0.6  ,...
       'SpecularStrength' , 0.9  ,...
       'SpecularExponent' , 20 ,...
       'SpecularColorReflectance' , 1.0 ,...
       'Tag','mesh' );
  
    line('XData',XYZ(:,1),'YData',XYZ(:,2),'ZData',XYZ(:,3),'LineWidth',1,'Color','r','LineStyle','none','Marker','.',...
         'Tag','xyz');

    set(gca,'DataAspectRatio',[1 1 1]);
    axis(objbounds(get(hM,'Parent'),1.3));
    headlight
end
function defPLOT( M , it , mode , hFig )
  set( hFig , 'Name' , sprintf('%4d - %s',it,mode) );
  if isempty( M )
    set( hFig , 'Name' , [ get( hFig , 'Name' ) , ' .... ' ] );
    drawnow('expose');
    return;
  end
  hAX = get( hFig , 'CurrentAxes' );
  switch upper( mode )
    case {'CLOSEST'}
      h = findall( hAX ,'Tag','closest_points' );

      v = get(h,'Vertices');
      v( 1:size(M,1) ,:) = M;
      set(h,'Vertices',v);
    case {'SAMPLING'}
      delete( findall( hAX ,'Tag','attractor_points' ) )
      line('Parent',hAX,'XData',M(:,1),'YData',M(:,2),'ZData',M(:,3),'LineWidth',1,...
        'Color','k','LineStyle','none','Marker','o',...
        'MarkerSize',7,...
        'Tag','attractor_points','MarkerFaceColor','b');
      
      delete( findall( hAX , 'Tag','closest_points' ) );
      v = [M;M];
      f = reshape( 1:(2*size(M,1)) ,[],2 );
      patch('Parent',hAX,'Vertices',v,'Faces',f,'Tag','closest_points',...
        'EdgeColor','k','Marker','.','LineWidth',2);
    case { 'SUBDIVIDE' , 'SMOOTH' , 'DECIMATE' , 'PULL' , 'REMESH' }
      hM = findall( hAX ,'Tag','mesh' );
      set( hM , 'Vertices', M.xyz , 'Faces' , M.tri );
  end
  drawnow();
end
function x = IterationsToDoIt( x , N )
  if isempty( x )
    x = false( 2 ,1);
  elseif numel(x)==1 && isnumeric( x )
    x = 0:x:(N-x);
    x( x < 1 ) = [];
  end
  x = x(:).';
  if ~islogical( x ), x = loss( x ); end
  x([1,end+1]) = false;

  if ~islogical( x ), error('invalid specification of iterations.'); end
end