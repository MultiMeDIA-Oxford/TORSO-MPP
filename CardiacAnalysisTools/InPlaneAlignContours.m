function TS = InPlaneAlignContours( HS , varargin )

  RangeTX = 20;
  try, [varargin,~,RangeTX] = parseargs(varargin,'RangetX','$DEFS$',RangeTX); end
  
  RangeTY = 20;
  try, [varargin,~,RangeTY] = parseargs(varargin,'RangetY','$DEFS$',RangeTY); end
  
  RangeRZ = 10;
  try, [varargin,~,RangeRZ] = parseargs(varargin,'RangerZ','$DEFS$',RangeRZ); end
  
  VERBOSE = true;
  [varargin,~,VERBOSE] = parseargs(varargin,'VERBOSE','$DEFS$',VERBOSE); 

  STRATEGY = [ 8 , 7 , 2 ];
  

  vprintf = @(varargin)fprintf(varargin{:});

  HS = HS(:, 1:min(end,6) );
  N = size( HS ,1);
  
  %%
  
  TS = repmat( {eye(4)} , [ N , 1 ] );
  for r = 1:N
    if isempty( HS{r,1} ), continue; end
    HS{r,1}  = HS{r,1}.centerGrid;
    oHS{r,1} = HS{r,1}.SpatialTransform;
  end
  
  %%  

  FIXED = [];
  try, [varargin,~,FIXED] = parseargs(varargin,'fixed','$DEFS$',FIXED); end
  
  tr = @(x,T)bsxfun( @plus , x*T(1:2,1:2).' , T(1:2,4).' );
  ORDER = 1:N;
  for r = ORDER(:).'
    if any( r == FIXED ), continue; end
    if all( cellfun('isempty', HS(r,2:end)) ), continue; end
    if VERBOSE, vprintf('InPlaneAlignment from Contours, slice %2d ... ', r ); end

    %%
    
    M = HS( r ,:);
    
    XYZ = cell( 1 , size( HS ,2) );
    for s = setdiff( 1:N , r )
      if isempty( HS{s,1} ), continue; end
      if ipd( M{1,1}.SpatialTransform(1:3,3).' , HS{s,1}.SpatialTransform(1:3,3).' , 'normal') < 1e-4, continue; end
      for c = 2:size( HS ,2)
        if isempty( HS{s,c} ) || isempty( M{1,c} ), continue; end
        XYZ{1,c} = [ XYZ{1,c} ; meshSlice( HS{s,c} , M{1,1} ) ];
      end
    end
    np = sum( cellfun(@(x)size(x,1),XYZ(:,2:end)) );
    if np < 2
      vprintf(' too few to do!\n');
      continue;
    end
    
    
    oT  = M{1,1}.SpatialTransform; ioT = minv( oT );
    M   = transform( M , ioT );    for c = 2:size(HS,2), try, M{1,c}(:,3) = []; end; end
    XYZ = transform( XYZ , ioT );  for c = 2:size(HS,2), try, XYZ{1,c}(:,3) = []; end; end
    
    Cid = find( ~cellfun('isempty',XYZ(2:end)) & ~cellfun('isempty',M(2:end)) ) + 1; Cid = Cid(:).';
    if isempty( Cid )
      vprintf(' nothing to do\n');
      continue;
    end

    if 0
figure;
imagesc( M{1,1}.t1 );axis('equal');caxis( centerscale(caxis,1.5) )
for c = 2:size(HS,2)
  hplot3d( M{1,c}   ,'-','Color',colorith(c) );
  hplot3d( XYZ{1,c} ,'ok','MarkerFaceColor',colorith(c) );
end
axis(objbounds(findall(gca,'Type','line'),1.2)*eye(6,4));
    end
    
    %%
    
    RX = RangeTX;
    RY = RangeTY;
    RZ = RangeRZ;
    XYR = [0 0 0];
    
    bestE = Inf; bestT = eye(4);
    for it = 1:STRATEGY(1)
     if VERBOSE,  vprintf('+'); end
      TXs = linspace( XYR(1)-RX , XYR(1)+RX , STRATEGY(2) );  RX = RX/STRATEGY(3);
      TYs = linspace( XYR(2)-RY , XYR(2)+RY , STRATEGY(2) );  RY = RY/STRATEGY(3);
      RZs = linspace( XYR(3)-RZ , XYR(3)+RZ , STRATEGY(2) );  RZ = RZ/STRATEGY(3);
      
      XYs = ndmat( unique( TXs ) , unique( TYs ) );
      [~,ord] = sort( fro2( bsxfun(@minus,XYs,XYR(1:2)) ,2) ); XYs = XYs(ord,:);
      RZs = unique( RZs ); [~,ord] = sort( abs( RZs - XYR(3) ) ); RZs = RZs(ord);
      
      
      for z = RZs(:).'
        T = maketransform( 'rz' , z );
        
        for xy = 1:size(XYs,1)
          T([1,2],4) = XYs(xy,:);
          
          E = 0;
          for c = Cid
            [~,~,d] = distancePoint2Segments( tr( XYZ{1,c} ,T) , M{1,c} );
%             if numel(d) > 5, d = sort(d); d(end-3:end) = []; end
            E = E + sum( d.^2 );
          end
          
          if E < bestE
            bestE = E;
            bestT = T;
            XYR   = [ XYs(xy,:) , z ];
          end
        end
      end
    end
    
    %%
    bestT = minv( bestT );
    
    if 0
      figure;
      plot3d( transform( HS(r,2:end) , ioT ) , 'b' ,'eq');
      for c = Cid, rc = rand(1,3);
        hplot3d( tr( M{1,c} , bestT ) ,'color',rc,'LineWidth',2);
        hplot3d( XYZ(:,c) , 'or' ,'Color','k','MarkerFaceColor',rc,'MarkerSize',9);
      end
      view(2)
      %himage3( transform( M{1,1}.t1 , bestT ) ); zlim([-1 1]);
      %%
    end
    
    for c = 2:size(HS,2)
      if isempty( M{1,c} ), continue; end
      M{1,c}(:,end+1:3) = 0;
    end
    
    HS(r,:) = transform( M , bestT , oT );

    TS{r,1} = HS{r,1}.SpatialTransform / oHS{r,1};
    
  
    if VERBOSE, vprintf(' done.\n'); end
  end
    if ~VERBOSE, vprintf(' Inplane Alignment done.\n'); end
end
