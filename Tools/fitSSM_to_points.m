function [c,P,rms] = fitSSM_to_points( SSM , x , c , P , Ptype , varargin )

  PRCT            = 0.1;
  MAX_ITERATIONS  = 100;
  RANGE           = Inf;
  VERBOSE         = false;
  PLOT            = false;
  
  try, [varargin,~,PRCT] = parseargs(varargin,'PRCT','percentiles','$DEFS$',PRCT); end
  try, [varargin,~,MAX_ITERATIONS] = parseargs(varargin,'ITerations','$DEFS$',MAX_ITERATIONS); end
  try, [varargin,~,RANGE] = parseargs(varargin,'RANGE','$DEFS$',RANGE); end
  try, [varargin,VERBOSE] = parseargs(varargin,'VERBOSE','$FORCE$',{true,VERBOSE}); end
  try, [varargin,PLOT] = parseargs(varargin,'plot','$FORCE$',{true,PLOT}); end
  
  if VERBOSE
    vprintf = @(varargin)fprintf(varargin{:});
  else
    vprintf = @(varargin)0;
  end
  
  if isscalar( PRCT ) && PRCT < 0
    PRCT = geospace( 0.05 , -PRCT , MAX_ITERATIONS );
  end

  f  = functions( SSM );
  m  = f.workspace{1}.m;
  M  = f.workspace{1}.M;
  M = M(:,1:numel(c));

  m = double(m);
  M = double(M);
  c = double(c);


  S = SSM(0);
  if iscell( S )
    if ~iscell( x ), error('cell to points attempt'); end
  else
    if iscell(x), error('mesh to cell attempt'); end
    S = { S };
    x = { x };
  end
  J = numel( S );
  if numel( x ) ~= J, error('different cell sizes'); end
  

  xyz = S{1}.xyz;
  nV = size( xyz ,1);
  for j = 1:J
    if ~numel(x{j}), continue; end
    S{j} = Mesh( S{j} ,0); if ~isequal( S{j}.xyz ,xyz), error('meshes should have the same nodes'); end
    x{j} = double(x{j});
  end
  X = vertcat( x{1:J} );
  
  if PLOT
    xyz = double( transform( reshape( M*c , size(m) ) + m , P ) );
    for j = 1:J, S{j}.xyz = xyz; end
    [S,hFig] = initiate_PLOT( S , x );
  end
  
  E = cell(J,1); FR = cell(J,1); D = cell(J,1); Z = cell(J,1); T = cell(J,1);
  prev_c = NaN; prev_P = NaN; prev_rms = Inf;
  for it = 1:MAX_ITERATIONS
    xyz = double( transform( reshape( M*c , size(m) ) + m , P ) );
    
    for j = 1:J
      S{j}.xyz = xyz;  if PLOT, set( S{j}.hS , 'Vertices' , xyz ); drawnow; end

      if ~numel(x{j}), continue; end      
      if RANGE ~= 0
        [E{j},FR{j},D{j},Z{j}] = vtkClosestElement( S{j} , x{j} );
        T{j} = S{j}.tri( E{j} ,:);
      else
        [~,FR{j},D{j}] = vtkClosestElement( S{j} , x{j} );
      end
      if PLOT, set( S{j}.hC , 'Vertices' , [ x{j} ; FR{j} ] ); drawnow; end
    end
    DD  = vertcat( D{:} );
    
    rms = sqrt( mean( DD.^2 ) );
    if rms > prev_rms * 1.00001
      c = prev_c; P = prev_P;
      vprintf('Stopping. The energy went up.\n');
      break;
    end
    str = sprintf( '(%3d) rms = %.10g   90%%: %g   -  100%%: %g    prct=%.2g', it , rms , prctile( DD(:) , [90,100] ) , PRCT( min(it,end) ) );
    vprintf( '%s\n' , str );
    if PLOT, set(hFig,'Name',str); end
    

    FFR = vertcat( FR{:} );
    TO = FFR + PRCT( min(it,end) ) * ( X - FFR );
    
    if RANGE ~= 0

      EE  = vertcat( E{:} );
      ZZ  = vertcat( Z{:} );
      TT  = vertcat( T{:} );
      L = sparse( ( 1:numel(EE) ).' * [1,1,1] , TT , ZZ , numel(EE) , nV );
      Lm = L*m;
      LM = reshape( L*reshape( M , size(L,2) ,[]) , [] , size(M,2) );

      [cc,PP] = fitPDM_to_points( { LM , Lm } , TO , Ptype ,'C',c , 'RANGE',RANGE , varargin{:} );
      
      if fro2( FFR - TO ) < fro2( double( transform( reshape( LM*cc , size(Lm) ) + Lm , PP ) ) - TO )
%         break;
        vprintf('optimizing ...');
        [cc,PP] = fitPDM_to_points( { LM , Lm } , TO , Ptype ,'C',cc , 'RANGE',RANGE , varargin{:} ,'methods','o' );
        vprintf(' done.\n');
      end

    else
      
      PP = MatchPoints( TO , FFR , Ptype ); cc = c;
      PP = transform( P , PP );

    end

    if isequal( prev_c , cc ) && isequal( prev_P , PP )
      vprintf('Converged !\n');
      break;
    end
    c = cc; P = PP;
    prev_c = c; prev_P = P; prev_rms = rms;
  end

  
  
  
  if nargout > 2 || PLOT
    xyz = double( transform( reshape( M*c , size(m) ) + m , P ) );
    for j = 1:J
      S{j}.xyz = xyz;  if PLOT,  set( S{j}.hS , 'Vertices' , xyz ); drawnow; end

      if ~numel(x{j}), continue; end      
      [~,FR{j},D{j}] = vtkClosestElement( S{j} , x{j} );

      if PLOT, set( S{j}.hC , 'Vertices' , [ x{j} ; FR{j} ] ); drawnow; end
    end
    DD  = vertcat( D{:} );
    rms = sqrt( mean( DD.^2 ) );
  end
  
  
  

end


function [S,hFig] = initiate_PLOT( S , x )
    hFig = figure( 'HandleVisibility', 'on'     ,...
                    'ToolBar','figure',...
                      'IntegerHandle', 'on'     ,...
                           'NextPlot', 'add'    ,...
                        'NumberTitle', 'off'    ,...
                           'Renderer', 'openGL' ,...
                       'RendererMode', 'manual' );
    set( hFig , 'Colormap' , jet(256) );
                   
    
    for j = 1:numel(S)
      col = colorith( j );
    
      S{j}.hS = patch( 'Faces' , S{j}.tri , 'Vertices' , S{j}.xyz ,...
        'FaceAlpha',0.7,'EdgeColor','none',... %[1,1,1]*0.3,...
        'FaceColor', col ,...
        'FaceLighting' , 'gouraud' ,...
        'AmbientStrength'  , 0.3 ,...
        'DiffuseStrength' , 0.6  ,...
        'SpecularStrength' , 0.9  ,...
        'SpecularExponent' , 20 ,...
        'SpecularColorReflectance' , 1.0 );
      
      if numel( x{j} )
        S{j}.hx = line('XData',x{j}(:,1),'YData',x{j}(:,2),'ZData',x{j}(:,3),'LineWidth',1,'Color','k','LineStyle','none','Marker','o','MarkerFaceColor',col);
        
        S{j}.hC = patch( 'Vertices', [ x{j} ; x{j} ] , 'Faces' , reshape( 1:(2*size(x{j},1)) ,[],2 ),...
          'FaceColor','none','LineWidth',1,'EdgeColor',col,'Marker','.','MarkerEdgeColor','k','MarkerFaceColor','k');
      end

    end
    set(gca,'DataAspectRatio',[1 1 1]);
    axis(objbounds(gca,1.01));
    headlight
end
