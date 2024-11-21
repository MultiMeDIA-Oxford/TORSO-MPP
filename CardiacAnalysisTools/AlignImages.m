function [TS,GG] = AlignImages( HS , varargin )

  GG = eye(4);
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

  
  LEVELS = [ geospace( 5 , 0.5 , 3 ) , 0 ];
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
  
  
  args      = { 'Transform'     , @( I , T )transform( I , T ) ,...
                'EnergyPerPair' , @(A,B) 1 - NCC(A,B) ,...
                'EnergyperRow'  , @(R)nanmean(R) ,...
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
  
  args = [ args , 'TModel' , ...
  {@(varargin)TModel_inPlaneRot_outPlaneRot_Translations( varargin{:} , 'RZrange',15,'RHOrange',5,'TZrange',3/1000,'TXrange',20/1000,'TYrange',20/1000 )}];
  
  
  TIMEPHASES = true;
  [varargin,TIMEPHASES] = parseargs(varargin,'TIMEPHASES','$FORCE$',{true,TIMEPHASES});
  [varargin,TIMEPHASES] = parseargs(varargin,'FIRSTPHASE','$FORCE$',{false,TIMEPHASES});
  
  if ~TIMEPHASES
    for r = 1:size( HS , 1 )
      HS{r,1} = HS{r,1}.t1;
    end
  else
    %preparing slices to be Aligned
    sz4 = arrayfun( @(h)size(HS{h},4) , find( Cid ) );
    if      var( sz4 ) == 0
    elseif  any( sz4 == 1 )
      error('an static image cannot be aligned to cine ones!');
    else
      msz4 = max( sz4 );
      for s = find( sz4(:).' ~= msz4 )
        data = double( HS{s}.data );
        sz   = size( data ); sz(4) = msz4;
        data = idctn( resize( data , sz ) );

        while size( HS{s} , 4 ) < msz4
          HS{s} = cat( 4 , HS{s} , HS{s} );
        end
        HS{s} = HS{s}(:,:,:,1:msz4);
        HS{s}.data = data;
      end
    end
  end

  USEMASK = false;
  [varargin,USEMASK] = parseargs(varargin,'useMASK','$FORCE$',{true,USEMASK});
  
  

  %preparing contours to be Aligned
  TT  = TS( Cid ,end);
  AI  = ArrangeImagePairs( transform( HS(Cid,:) , TT ) );
  for r = 1:size( AI ,1)
    AI(r,:) = transform( AI(r,:) , minv( TT{r} ) );
  end
  
  
  for l = 1:nL
    tAI = AI;
    for a = 1:numel( tAI )
      if isempty( tAI{a} ), continue; end
      if 1
        I = tAI{a};
        
        I.data = double( I.data );
        
        if LEVELS(l) ~= 0
          w = isnan( I.data );
          I.data = nonans( I.data , 'euclidean' );
          xc = 0:mean(diff(I.X)):max(mean(diff(I.X))*5,4*LEVELS(l)); xc = [ -fliplr(xc(2:end)) , xc ];
          yc = 0:mean(diff(I.Y)):max(mean(diff(I.Y))*5,4*LEVELS(l)); yc = [ -fliplr(yc(2:end)) , yc ];
          G = gaussianKernel( xc  , yc , 's' , LEVELS(l) , 'normalize' );
          I.data = imfilter( I.data , G , 'replicate' );
          I.data(w) = NaN;
        end
        
        try, if USEMASK, I.data( ~I.FIELDS.mask ) = NaN; end; end
        I = crop( I , 0 , 'mask' , ~isnan( I.data ) );
        
        tAI{a} = I;
      end
    end
    for it = 1:ITERATIONS(l)
      fprintf( '\n' );
      fprintf( '------------------------------------------------------\n' );
      fprintf( 'Aligning at resolution: %+0.03f  (iteration: %3d of %d)\n' , LEVELS(l) , it , ITERATIONS(l) );
      fprintf( '......................................................\n\n' );
      
      h_init = TS( Cid , end );
      [h,preCENTER] = SquareHeartSlices( tAI , h_init , args{:} );  GG = preCENTER * GG;
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
function E = NCC( A , B )
  L = intersectionLine( A , B , 0.1 );
  E = 0;
  
  if numel(L) < 30, return; end
  
  AL = A(L,'closest'); AL = AL(:);
  BL = B(L,'closest'); BL = BL(:);
  w = isfinite( AL ) & isfinite( BL ); if sum(w) < 15, return; end
  
  AL = AL(w); AL = AL - mean(AL); AL = AL/std(AL);
  BL = BL(w); BL = BL - mean(BL); BL = BL/std(BL);

  E = AL(:).' * BL(:) / ( numel(AL) - 1 );
  if ~isfinite( E )
    E = 0;
    return;
  end
end
