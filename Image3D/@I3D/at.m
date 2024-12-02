function o = at( I , in , varargin )

  if ~isa( I , 'I3D' )
    error('interpolating where???');
  end
  
  if ~I.isGPU
    
    if      isa( in , 'I3D' )

      o = COPYcontainer( I , in , varargin{:} );
      
      if isempty( I.data ) || iscell( I.data )
        o.data = [];
      else
        [varargin,aliasing] = parseargs(varargin,'ALIASing','$FORCE$',true);
        if aliasing, I = spatialScale(I,in,'circular'); end

        o.data = Interp3DGridOn3DGrid( ...
                    I.data , I.X , I.Y , I.Z , ...
                    in.X , in.Y , in.Z , ...
                    'omatrix', I.SpatialTransform , ...
                    'nmatrix', in.SpatialTransform , ...
                    I.SpatialInterpolation , ...
                    'outside_value' , I.OutsideValue , ...
                    I.BoundaryMode  , I.BoundarySize , ...
                    varargin{:} ...
                    );
      end

      if in.isGPU, in.data = parallel.gpu.GPUArray( in ); end

    elseif  isnumeric( in ) || isa( in , 'parallel.gpu.GPUArray' ) || isa( in , 'SamplePoints' )

      if isa( in , 'SamplePoints' ),          in = double( in ); end
      if size(in,2) ~= 3,                     error('I3D:BadPoints','Invalid calling  at ,  you need 3 columns.' ); end

      if isempty( I.data ) || iscell( I.data ),  o = zeros( size(in,1) , 1 );
      else
        o = InterpPointsOn3DGrid( ...
                  I.data , I.X , I.Y , I.Z , ...
                  gather( in )         , ...
                  'omatrix' , I.SpatialTransform , ...
                  I.SpatialInterpolation  , ...
                  'outside_value' , I.OutsideValue , ...
                  I.BoundaryMode , I.BoundarySize , ...
                  varargin{:} );
      end
      
    elseif  iscell( in )
      
      if isempty( I.data ) || iscell( I.data )
        o.data = [];
      else
        if numel( in ) == 4,       nMATRIX = in{4};
        elseif numel( in ) ~= 3,   error('I3D:BadPoints','Incorrect calling'); 
        else,                      nMATRIX = [];
        end
        o = Interp3DGridOn3DGrid( ...
                    I.data , I.X , I.Y , I.Z , ...
                    gather( in{1} ), gather( in{2} ) , gather( in{3} ) , ...
                    'omatrix', I.SpatialTransform , ...
                    'nmatrix', gather( nMATRIX )  , ...
                    I.SpatialInterpolation , ...
                    'outside_value' , I.OutsideValue , ...
                    I.BoundaryMode  , I.BoundarySize , ...
                    varargin{:} );
      end

    else
      error('error calling at(  I3D ,  %s )', class( in ) );
    end

    
  else

    nMATRIX = NaN;
    if numel( varargin ) == 2 && ischar( varargin{1} ) && ...
        ( strcmp( lower(varargin{1}) , 'nm'      )   ||...
          strcmp( lower(varargin{1}) , 'nmatrix' )   ||...
          strcmp( lower(varargin{1}) , 'nmat'    )   )
      nMATRIX = varargin{2};
      varargin(1:2) = [];
    end
    
    if numel( varargin )
      error('on GPU I3Ds no se pueden cambiar los attributos de interpolation' );
    end

    CLASSUNDER = classUnderlying( I.data ); CLASSUNDER = CLASSUNDER(1);
    
    if      isa( in , 'I3D' )
      o = COPYcontainer( I , in , varargin );
      GridX = ceil( numel(in.X) / 16 );
      GridY = ceil( numel(in.Y)*numel(in.Z) /16 );
      if( ( GridX > 65535) || (GridY > 65535) )
          error('GPU I3D: Dimensiones maximas del Grid, numelX < 1048560 && (numelY*numelZ) < 1048560.');
      end

      
      if in.isGPU

        if      CLASSUNDER == 'd'
	        I.GPUvars.GRID_dINTERPOLATION_KERNEL.GridSize        = [ GridX , GridY ];
          %o.data = double( o.data );
          o.data = parallel.gpu.GPUArray.zeros( numel(I.X) , numel(I.Y) , numel(I.Z) , 'double' );
          o.data = feval( I.GPUvars.GRID_dINTERPOLATION_KERNEL , I.data ,...
                           in.GPUvars.dX , in.GPUvars.nX ,...
                           in.GPUvars.dY , in.GPUvars.nY ,...
                           in.GPUvars.dZ , in.GPUvars.nZ ,...
                           in.GPUvars.dSpatialTransform  ,...
                           o.data );
        elseif  CLASSUNDER == 's'
	        I.GPUvars.GRID_fINTERPOLATION_KERNEL.GridSize        = [ GridX , GridY ];
          %o.data = single( o.data );
          o.data = parallel.gpu.GPUArray.zeros( numel(I.X) , numel(I.Y) , numel(I.Z) , 'single' );
          o.data = feval( I.GPUvars.GRID_fINTERPOLATION_KERNEL , I.data ,...
                           in.GPUvars.fX , in.GPUvars.nX ,...
                           in.GPUvars.fY , in.GPUvars.nY ,...
                           in.GPUvars.fZ , in.GPUvars.nZ ,...
                           in.GPUvars.fSpatialTransform  ,...
                           o.data );
        end

      else
        
        if      CLASSUNDER == 'd'
	        I.GPUvars.GRID_dINTERPOLATION_KERNEL.GridSize        = [ GridX , GridY ];
          o.data = parallel.gpu.GPUArray.zeros( [ numel(in.X) , numel(in.Y) , numel(in.Z) , 1 ] , 'double' );
          o.data = feval( I.GPUvars.GRID_dINTERPOLATION_KERNEL , I.data ,...
                     double( in.X ) , uint32( numel( in.X ) ) ,...
                     double( in.Y ) , uint32( numel( in.Y ) ) ,...
                     double( in.Z ) , uint32( numel( in.Z ) ) ,...
                     double( in.SpatialTransform ) ,...
                     o.data );
        elseif  CLASSUNDER == 's'
	        I.GPUvars.GRID_fINTERPOLATION_KERNEL.GridSize        = [ GridX , GridY ];
          o.data = parallel.gpu.GPUArray.zeros( [ numel(in.X) , numel(in.Y) , numel(in.Z) , 1 ] , 'single' );
          o.data = feval( I.GPUvars.GRID_INTERPOLATION_KERNEL , I.data ,...
                     single( in.X ) , uint32( numel( in.X ) ) ,...
                     single( in.Y ) , uint32( numel( in.Y ) ) ,...
                     single( in.Z ) , uint32( numel( in.Z ) ) ,...
                     single( in.SpatialTransform ) ,...
                     o.data );
        end
        o.data = gather( o.data );

      end

    elseif  isnumeric( in ) || isa( in , 'parallel.gpu.GPUArray' )
      
      if size(in,2) ~= 3, error('I3D:BadPoints','Invalid calling  at ,  you need 3 columns.'); end
      
      %Calculo de los tamaños de
      nBlocks = ceil( size(in,1) / prod(I.GPUvars.POINTS_dINTERPOLATION_KERNEL.ThreadBlockSize));
      dGridX = ceil( sqrt( nBlocks ) );
      dGridY = ceil( nBlocks/dGridX );
      nBlocks = ceil( size(in,1) / prod(I.GPUvars.POINTS_fINTERPOLATION_KERNEL.ThreadBlockSize));
      fGridX = ceil( sqrt( nBlocks ) );
      fGridY = ceil( nBlocks/fGridX );

      if     CLASSUNDER == 'd'

        I.GPUvars.POINTS_dINTERPOLATION_KERNEL.GridSize        = [ dGridX , dGridY ];
  
        o = parallel.gpu.GPUArray.zeros( [ size(in,1) , 1 ] , 'double' );
%%%%%%%%%%%%%%%
          %No se porque pero si se invoca asi (double( in )), se agota la
          %memoria del device...
%         o = feval( I.GPUvars.POINTS_dINTERPOLATION_KERNEL , I.data ,...
%                    double( in ) , uint32( size(in,1) ) , double( nMATRIX )  ,...
%                    o );
        o = feval( I.GPUvars.POINTS_dINTERPOLATION_KERNEL , I.data ,...
                   ( in ) , uint32( size(in,1) ) , double( nMATRIX )  ,...
                   o );
                   
      elseif CLASSUNDER == 's'
        I.GPUvars.POINTS_fINTERPOLATION_KERNEL.GridSize        = [ fGridX , fGridY ];
  
        o = parallel.gpu.GPUArray.zeros( [ size(in,1) , 1 ] , 'single' );
        o = feval( I.GPUvars.POINTS_fINTERPOLATION_KERNEL , I.data  ,...
                   single( in ) ,  uint32( size(in,1) ) , single( nMATRIX ) ,...
                   o );  
      end

    elseif  iscell( in )
      
      if numel( in ) == 4,       nMATRIX = in{4};
      elseif numel( in ) ~= 3,   error('I3D:BadPoints','Incorrect calling'); 
      end
      
      GridX = ceil( numel(in{1}) /16);
      GridY = ceil( numel(in{2})*numel(in{3}) /16);
      if( ( GridX > 65535) || (GridY > 65535) )
          error('GPU I3D: Dimensiones maximas del Grid, numelX < 1048560 && (numelY*numelZ) < 1048560.');
      end
      
      
      if     CLASSUNDER == 'd'
      
        %I.GPUvars.GRID_dINTERPOLATION_KERNEL.ThreadBlockSize = [ 16 , 16 , 1 ];
        I.GPUvars.GRID_dINTERPOLATION_KERNEL.GridSize        = [ GridX , GridY ];

        o = parallel.gpu.GPUArray.zeros( [ numel(in{1}) , numel(in{2}) , numel(in{3}) , 1 ] , 'double' );
        o = feval( I.GPUvars.GRID_dINTERPOLATION_KERNEL , I.data ,...
                   double( in{1} ) , uint32( numel( in{1} ) ) ,...
                   double( in{2} ) , uint32( numel( in{2} ) ) ,...
                   double( in{3} ) , uint32( numel( in{3} ) ) ,...
                   double( nMATRIX ) ,...
                   o );

      elseif CLASSUNDER == 's'
      
        %I.GPUvars.GRID_fINTERPOLATION_KERNEL.ThreadBlockSize = [ 16 , 16 , 1 ];
        I.GPUvars.GRID_fINTERPOLATION_KERNEL.GridSize        = [ GridX , GridY ];

        o = parallel.gpu.GPUArray.zeros( [ numel(in{1}) , numel(in{2}) , numel(in{3}) , 1 ] , 'single' );
        o = feval( I.GPUvars.GRID_fINTERPOLATION_KERNEL , I.data ,...
                   single( in{1} ) , uint32( numel( in{1} ) ) ,...
                   single( in{2} ) , uint32( numel( in{2} ) ) ,...
                   single( in{3} ) , uint32( numel( in{3} ) ) ,...
                   single( nMATRIX ) ,...
                   o );

      end
               
    else
      error('error calling at(  GPU:I3D ,  %s )', class( in ) );
    end      
      
  end


  
  
  function o = COPYcontainer( I , in , varargin )
      % %                     X  -> in
      % %                     Y  -> in
      % %                     Z  -> in
      % %      SpatialTransform  -> in
      % %       GRID_PROPERTIES  -> in
      % %                  data  -> I.data interpolated en in
      % %                LABELS  -> I.LABELS interpolated en in
      % %                FIELDS  -> numericos: I  interpolated en in ,  I3d:  los mismos
      % %                     T  -> I
      % %           LABELS_INFO  -> I
      % %        ImageTransform  -> I
      % %  SpatialInterpolation  -> I
      % %          BoundaryMode  -> I
      % %          BoundarySize  -> I
      % %          OutsideValue  -> I
      % % TemporalInterpolation  -> I
      % %             LANDMARKS  -> I
      % %              CONTOURS  -> []
      % %                MESHES  -> []
      % %                  INFO  -> I
      % %                OTHERS  -> I

      o   = remove_dereference( I );
      if ~isempty( o.LANDMARKS )
        o.LANDMARKS = transform( o.LANDMARKS , inv( in.SpatialTransform )*o.SpatialTransform );
      end

      o.SpatialTransform  = in.SpatialTransform;
      o.X                 = in.X;
      o.Y                 = in.Y;
      o.Z                 = in.Z;
      o.GRID_PROPERTIES   = in.GRID_PROPERTIES;
      o.CONTOURS          = struct();
      o.MESHES            = [];
      o.isGPU             = in.isGPU;
      o.GPUvars           = in.GPUvars;
    

      if isempty( I.LABELS )  %||  ~any(I.LABELS(:))
        o.LABELS = [];
      elseif any(I.LABELS(:))
        o.LABELS = uint16( Interp3DGridOn3DGrid( ...
                I.LABELS , I.X , I.Y , I.Z , ...
                in.X , in.Y , in.Z , ...
                'omatrix', I.SpatialTransform , ...
                'nmatrix', in.SpatialTransform , ...
                varargin{:} , ...
                'nearest' , ...
                'outside_value' , 0 , ...
                'value' ) ...
                );
      else
        o.LABELS = zeros( [ numel(o.X) , numel(o.Y) , numel(o.Z) , numel(o.T) ] ,'uint16');
      end

      if ~isempty( I.FIELDS )
        for fn = fieldnames(I.FIELDS)'
          if isnumeric( I.FIELDS.(fn{1}) )

            o.FIELDS.(fn{1}) = Interp3DGridOn3DGrid( ...
                                  I.FIELDS.(fn{1}) , I.X , I.Y , I.Z , ...
                                  in.X , in.Y , in.Z , ...
                                  'omatrix', I.SpatialTransform  , ...
                                  'nmatrix', in.SpatialTransform , ...
                                  I.SpatialInterpolation , ...
                                  'outside_value' , I.OutsideValue , ...
                                  I.BoundaryMode  , I.BoundarySize , ...
                                  varargin{:} );

          elseif islogical( I.FIELDS.(fn{1}) )

            o.FIELDS.(fn{1}) = logical( Interp3DGridOn3DGrid( ...
                                  I.FIELDS.(fn{1}) , I.X , I.Y , I.Z , ...
                                  in.X , in.Y , in.Z , ...
                                  'omatrix', I.SpatialTransform  , ...
                                  'nmatrix', in.SpatialTransform , ...
                                  iff( strcmp( I.BoundaryMode , 'decay' ) , 'value', I.BoundaryMode ) , I.BoundarySize , ...
                                  varargin{:}     ,...
                                  'nearest'       , ...
                                  'outside_value' , 0 ...
                                  ));

          end
        end
      end
      
    
  end


end
function x = gather(x)

  if isa( x , 'parallel.gpu.GPUArray' )
    x = gather( x );
  end

end
