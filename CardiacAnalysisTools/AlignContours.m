function TS = AlignContours( HS , varargin )

  nRows = size( HS , 1 );

  TS = [];
  if ~isempty(varargin) && ~ischar( varargin{1} )
    TS = varargin{1};
    varargin(1) = [];
  end
  if isempty( TS )
    TS = repmat( {eye(4)} , nRows , 1 );
  elseif size( TS ,1) ~= nRows
    error('one initial transformation per row were expected');
  end
  
  
  LEVELS = [20 15 10 5 2 1];
  [varargin,~,LEVELS] = parseargs(varargin,'levels','$DEFS$',LEVELS);
  nL = numel( LEVELS );

  ITERATIONS = 3;
  [varargin,~,ITERATIONS] = parseargs(varargin,'ITERations','$DEFS$',ITERATIONS);
  ITERATIONS = ITERATIONS(:);
  if numel( ITERATIONS ) < nL, ITERATIONS( end+1:nL ) = ITERATIONS(end); end
  

  FIXED_SLICES = [];
  [varargin,~,FIXED_SLICES] = parseargs(varargin,'FixedSlices','$DEFS$',FIXED_SLICES);
  if ~islogical( FIXED_SLICES )
    FIXED_SLICES = full( sparse( FIXED_SLICES , 1 , true , nRows , 1 ) );
  end
  FIXED_SLICES = FIXED_SLICES(:);
  if numel( FIXED_SLICES ) ~= nRows
    error('incorrect FIXED_SLICES specification');
  end

  provided_POSES = [];
  [varargin,~,provided_POSES] = parseargs(varargin,'POSES','$DEFS$',provided_POSES);
  provided_iPOSES = [];
  [varargin,~,provided_iPOSES] = parseargs(varargin,'IPOSES','$DEFS$',provided_iPOSES);
  
  
  FLIP = false;
  [varargin,FLIP] = parseargs(varargin,'flip','$FORCE$',{true,FLIP});
  
  if FLIP
    HS              = flip( HS ,1);
    TS              = flip( TS ,1);
    FIXED_SLICES    = flip( FIXED_SLICES    ,1);
    provided_POSES  = flip( provided_POSES  ,1);
    provided_iPOSES = flip( provided_iPOSES ,1);
  end
  
  
  args = { 'Transform'     , @( XYZ , T )bsxfun( @plus , XYZ * T(1:3,1:3).' , T(1:3,4).' ) ,...
           'EnergyPerPair' , @(A,B)DistancePolyline2Polyline( A , B )^2 ,...
           'EnergyperRow'  , @(R)sum(nonans(R)) ,...
           'GlobalEnergy'  , @(R)sum(R) ,...
           'SliceSelector' , @(E)argmax( nanmean(E,2) ) ,...
           'verbose' , 'preCENTER' };
  args = [ args , varargin ];

  Cid = ~all( cellfun( 'isempty' , HS ) ,2);

  FIXED_SLICES = FIXED_SLICES( Cid , : );
  args = [ args , 'FixedSlices' , FIXED_SLICES ];

  try, provided_POSES = provided_POSES( Cid , : ); end
  args = [ args , 'POSES' , { provided_POSES } ];

  try, provided_iPOSES = provided_iPOSES( Cid , : ); end
  args = [ args , 'iPOSES' , { provided_iPOSES } ];
  
  
  %preparing contours to be Aligned
  TT  = TS( Cid ,end);
  AC  = ArrangeContourPairs( transform( HS(Cid,:) , TT ) );
  for r = 1:size( AC ,1)
    AC(r,:) = transform( AC(r,:) , minv( TT{r} ) );
  end
  
  
  for l = 1:nL
    tAC = AC;
    for a = 1:numel( AC )
      if isempty( AC{a} ), continue; end
      tAC{a} = AC{a}( unique( [ 1:LEVELS(l):end , end ] ) ,:);
    end
    for it = 1:ITERATIONS(l)
      fprintf( '\n' );
      fprintf( '------------------------------------------------------\n' );
      fprintf( 'Aligning at resolution: %3d  (iteration: %3d of %d)\n' , LEVELS(l) , it , ITERATIONS(l) );
      fprintf( '......................................................\n\n' );
      
      h_init = TS( Cid , end );
      [h,~,~,preCENTER] = SquareHeartSlices( tAC , h_init , args{:} );
      STUCKED = false;
      if isequal( cell2mat( h(:,end) ) , cell2mat( h_init(:) ) )
        STUCKED = true;
      end
      if STUCKED
        fprintf( 'STUCKED, going to next level...\n' );
        break;
      end
      
      hh = cell( nRows , size(h,2) );
      hh( ~Cid , : ) = repmat( transform( TS(~Cid,end) , preCENTER ) , 1 , size(h,2) );
      hh(  Cid , : ) = h;
      TS = [ TS , hh ];
    end
  end    

  if FLIP
    TS     = flip( TS , 1 );
  end  
end
