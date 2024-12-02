function [Q,R,rms] = fitSSM_to_points_new( SSM , TARGET , Q , R , Rtype , varargin )

  if iscell( SSM )
    try
      SSM = vertcat( SSM{:} );
    catch
      SSM = catstruct(1,SSM{:});
    end
  end


  nS = numel( SSM );   % SSM is an array of structs
  try
    nm  = size( SSM(1).xyzM ,3);  %number of modes
    for s = 1:nS   %for each of the SSMs
      szM = size( SSM(s).xyzM );
      if szM( 3) ~= nm, error('different number of modes'); end
      szm = size( SSM(s).xyzm );
      if ~isequal( szm(1) , szM(1) ), error('inconsistent number of points'); end
      if ~isequal( szm(2) , szM(2) ), error('inconsistent nsd'); end
    end
  catch, error('invalid SSM specification'); end


  PRCT            = 0.1;
  MAX_ITERATIONS  = 100;
  RANGE           = Inf;
  VERBOSE         = false;
  PLOT            = false;
  filterPDM       = @(x)x;
  StopIfRaise     = true;
  OptimizeIfRaise = true;
  PullFromBorder  = true;

  try, [varargin,~,PRCT] = parseargs(varargin,'pullfromBORDER','$DEFS$',PullFromBorder); end
  try, [varargin,~,PRCT] = parseargs(varargin,'PRCT','percentiles','$DEFS$',PRCT); end
  try, [varargin,~,MAX_ITERATIONS] = parseargs(varargin,'ITerations','$DEFS$',MAX_ITERATIONS); end
  try, [varargin,~,RANGE] = parseargs(varargin,'RANGE','$DEFS$',RANGE); end
  try, [varargin,VERBOSE] = parseargs(varargin,'VERBOSE','$FORCE$',{true,VERBOSE}); end
  try, [varargin,PLOT] = parseargs(varargin,'plot','$FORCE$',{true,PLOT}); end
  try, [varargin,~,filterPDM] = parseargs(varargin,'FILTER','$DEFS$',filterPDM); end
  try, [varargin,~,StopIfRaise] = parseargs(varargin,'StopIfRaise','$DEFS$',StopIfRaise); end
  try, [varargin,~,OptimizeIfRaise] = parseargs(varargin,'OptimizeIfRaise','$DEFS$',OptimizeIfRaise); end
  
  if VERBOSE
    vprintf = @(varargin)fprintf(varargin{:});
  else
    vprintf = @(varargin)0;
  end
  
  if isscalar( PRCT ) && PRCT < 0
    PRCT = geospace( 0.05 , -PRCT , MAX_ITERATIONS );
  end

  if ~iscell(TARGET), TARGET = { TARGET }; end
  if numel( TARGET ) ~= nS, error('different cell sizes'); end


  
  Q = double( Q(:) ); nQ = numel(Q);
  for s = 1:nS
    %if isempty( TARGET{s} ), continue; end
    for f = fieldnames( SSM(s) )', f = f{1};
      if isa( SSM(s).(f) ,'ndv' )
        SSM(s).(f) = [];
      end
    end
    
    if ~isfield( SSM(s) , 'tri' )
      SSM(s).tri = [];
    end
    
    SSM(s).TARGET  = TARGET{s};
    m = SSM(s).xyzm; szm = size(m);
    M = SSM(s).xyzM;
    M = M(:,:,1:nQ);
    SSM(s).xyzM = M;
    M = reshape( M , [ prod(szm) , nQ ] );
    SSM(s).QR = @(Q,R) bsxfun( @plus , ( reshape( M * Q(:) , szm ) + m ) * R(1:end-1,1:end-1).' , R(1:end-1,end).' );
  end
  %SSM( cellfun('isempty',TARGET) ) = [];
%   SSM = rmfield( SSM , setdiff( fieldnames( SSM ) , {'xyz','tri','TARGET','QR','xyzm','xyzM'} ) );
  
  SSM = updateSSM( SSM , Q , R );
  if PLOT
    [SSM,hFig] = initiate_PLOT( SSM );
    CLEANUP = onCleanup( @()delete(hFig) );
  end
  
  prev_Q = NaN; prev_R = NaN; prev_rms = Inf;
  for it = 1:MAX_ITERATIONS
    thisPRCT = PRCT( min(it,end) );
    
    PDM = QueryPDM( SSM );
    if ~PullFromBorder
      PDM = MeshRemoveNodes( PDM , PDM.xyzD2TARGET < 0 );
    end
    try
      PDM = filterPDM( PDM );
    catch
      error('Error in filterPDM function.');
    end
    [rms,D] = computeRMS( PDM );

    if StopIfRaise && rms > prev_rms * 1.00001
      Q = prev_Q; R = prev_R;
      vprintf('Stopping. The energy went up.\n');
      break;
    end
    str = sprintf( '(%3d) rms = %.10g   90%%: %g   -  100%%: %g    prct=%.2g    (RANGE: %g)', it , rms , prctile( D , [90,100] ) , thisPRCT , RANGE );

    vprintf( '%s\n' , str );
    if PLOT, set(hFig,'Name',str); end
    
    %attractor points;
    A = PDM.xyz  +  thisPRCT * ( PDM.xyzTARGET - PDM.xyz );
    try
      set( SSM(1).hA ,'XData',A(:,1),'YData',A(:,2) ,'ZData',A(:,3) ); drawnow();
    catch
      try, set( SSM(1).hA ,'XData',A(:,1),'YData',A(:,2) ); drawnow(); end
    end

    if RANGE ~= 0

      [QQ,RR] = fitPDM_to_points_new( PDM , A , Rtype , 'Q' , Q , 'RANGE' , RANGE , varargin{:} );

      if OptimizeIfRaise
        rrmmss = computeRMS( updatePDM( PDM , QQ , RR ) );
        if rms < rrmmss
          vprintf('optimizing ... ( %.10g --> %.10g --> ',rms,rrmmss);
          [QQ,RR] = fitPDM_to_points_new( PDM , A , Rtype , 'Q' , Q , 'RANGE' , RANGE , varargin{:} ,'methods','o' );
          rrmmss = computeRMS( updatePDM( PDM , QQ , RR ) );
          vprintf(' %.10g ) done.\n',rrmmss);
        end
      end
      
    else
      
      RR = MatchPoints( A , PDM.xyz , Rtype ); QQ = Q;
      RR = transform( R , RR );

    end
    
    if isequal( prev_Q , QQ ) && isequal( prev_R , RR )
      vprintf('Converged! (or stucked!)\n');
      break;
    end
    Q = QQ; R = RR;

    SSM = updateSSM( SSM , Q , R );
    prev_Q = Q; prev_R = R; prev_rms = rms;
  end
  
  if nargout > 2
    rms = computeRMS( QueryPDM( updateSSM( SSM , Q , R , false ) , false ) );
  end

end


function [SSM,hFig] = initiate_PLOT( SSM )
  hFig = figure( 'HandleVisibility', 'on'     ,...
    'ToolBar','figure',...
    'IntegerHandle', 'on'     ,...
    'NextPlot', 'add'    ,...
    'NumberTitle', 'off'    ,...
    'Renderer', 'openGL' ,...
    'RendererMode', 'manual' );
  set( hFig , 'Colormap' , jet(256) );


  for s = 1:numel(SSM)
    col = colorith(s);

    SSM(s).hS = patch( 'Faces' , SSM(s).tri , 'Vertices' , SSM(s).xyz ,'EdgeColor','none');
    switch size( SSM(s).tri ,2)
      case 0
        set( SSM(s).hS ,...
          'Faces' , ( 1:size(SSM(s).xyz,1) ).' ,...
          'Marker','d','MarkerSize',8,'MarkerFaceColor',col,'MarkerEdgeColor','k','lineWidth',1);
        
      case 1
        set( SSM(s).hS ,...
          'Marker','o','MarkerSize',12,'MarkerFaceColor','none','MarkerEdgeColor',col,'lineWidth',2);
        %               'Marker','o','MarkerSize',10,'MarkerFaceColor',col,'MarkerEdgeColor','k');
      case 2
        set( SSM(s).hS ,...
          'Marker','h','MarkerSize',4,'MarkerFaceColor','k','MarkerEdgeColor','k',...
          'EdgeColor',col,'LineWidth',2);
      case 3
        set( SSM(s).hS ,...
          'FaceAlpha',0.7,... %[1,1,1]*0.3,...
          'FaceColor', col ,...
          'FaceLighting' , 'gouraud' ,...
          'AmbientStrength'  , 0.3 ,...
          'DiffuseStrength' , 0.6  ,...
          'SpecularStrength' , 0.9  ,...
          'SpecularExponent' , 20 ,...
          'SpecularColorReflectance' , 1.0 );
    end

    TARGET = SSM(s).TARGET;
    if ~isempty(TARGET)
      TARGET(:,end+1:3) = 0;
      SSM(s).hTARGET = line('XData',TARGET(:,1),'YData',TARGET(:,2),'ZData',TARGET(:,3),'LineWidth',1,'Color','k','LineStyle','none','Marker','o','MarkerFaceColor',col,'MarkerSize',4);
    end

    if isempty( SSM(s).tri )
      CP = SSM(s).xyz;
    else
      [~,CP] = ClosestElement( SSM(s) , TARGET );
    end
    
    SSM(s).hC = patch( 'Vertices', [ ] , 'Faces' , [] ,...
      'FaceColor','none','LineWidth',1,'EdgeColor',col,'Marker','none','MarkerEdgeColor',[1 1 1]*0.5,'MarkerFaceColor',[1 1 1]*0.5);
    
    try
      set( SSM(s).hC , 'Vertices', [ TARGET ; CP ] , 'Faces' , reshape( 1:(2*size(TARGET,1)) ,[],2 ) )
    end
    
  end
  SSM(1).hA = line('XData',NaN,'YData',NaN,'LineWidth',1,'Color','k','LineStyle','none','Marker','o','MarkerSize',6,'MarkerFaceColor','k');

  set(gca,'DataAspectRatio',[1 1 1]);
  lims = objbounds(gca,1.05);
  %lims = lims(1:4);
  axis(gca, lims );
  headlight;
end
function PDM = QueryPDM( SSM , PLOT )
  if nargin < 2, PLOT = true; end
  PDM = cell( numel(SSM) ,1);
  for s = 1:numel( SSM )
    SSM(s).xyzCP = SSM(s).xyz;
    [PDM{s},d] = MeshQuery( SSM(s) , SSM(s).TARGET ,'closest');
    PDM{s}.xyz = PDM{s}.xyzCP;  PDM{s} = rmfield( PDM{s} , 'xyzCP' );
    PDM{s}.xyzTARGET = SSM(s).TARGET;
    PDM{s}.xyzD2TARGET = d;

    if PLOT && isfield( SSM(s) , 'hC' ) && ~isempty( PDM{s}.xyz )
      set( SSM(s).hC , 'Vertices', [ PDM{s}.xyz ; PDM{s}.xyzTARGET ] ); drawnow;
    end
  end
  PDM = MeshAppend( PDM{:} );
%   PDM = rmfield( PDM , setdiff( fieldnames(PDM) , {'xyz','xyzm','xyzM','xyzTARGET'} ) );
end
function [rms,D] = computeRMS( D )
  if ~isnumeric( D )
    D = D.xyz - D.xyzTARGET;
    D = D.^2;
    D = sqrt( sum( D ,2) );
  end
  rms = sqrt( sum( D.^2 ) );
end
function SSM = updateSSM( SSM , Q , R , PLOT )
  if nargin < 4, PLOT = true; end
  for s = 1:numel(SSM)
    SSM(s).xyz = SSM(s).QR(Q,R);
    if PLOT && isfield( SSM , 'hS' )
      set( SSM(s).hS , 'Vertices' , SSM(s).xyz ); drawnow;
    end
  end
end
function PDM = updatePDM( PDM , Q , R )
  m = PDM.xyzm;
  M = reshape( PDM.xyzM , [ size( m ,1) * size( m ,2) , numel(Q) ] );
  PDM.xyz = reshape( M*Q(:) , size( m ) ) + m;
  PDM.xyz = bsxfun( @plus , PDM.xyz * R(1:end-1,1:end-1).' , R(1:end-1,end).' );
end




