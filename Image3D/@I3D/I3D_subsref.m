function o = I3D_subsref( I , s )

  S= [];

  s_orig = s;
  optional_args = {};
  for ss = 1:numel(s)
    if numel( s(ss).subs ) == 0, S= '0'; continue; end
    stype = s(ss).type;
    switch stype
      case '.'
        name = s(ss).subs;
        S = [S '.' name ];
      case {'()','{}'}
        first_opt_arg = find( cellfun( @(x) ischar(x) && ~strcmp(x,':') , s(ss).subs ) , 1 );
        if ~isempty( first_opt_arg )
          optional_args = s(ss).subs(first_opt_arg:end);
          s(ss).subs = s(ss).subs(1:first_opt_arg-1);
        end
        S = [ S stype ];
        switch numel( s(ss).subs )
          case 0,    S= [S(1:end-1) '0' S(end)];
          case 1,    S= [S(1:end-1) '1' S(end)];
          case 2,    S= [S(1:end-1) '2' S(end)];
          case 3,    S= [S(1:end-1) '3' S(end)];
          case 4,    S= [S(1:end-1) '4' S(end)];
          otherwise, S= [S(1:end-1) '_' S(end)];
        end
    end
  end
  if strncmp(S,'.f.',3)
    fname_more = S(4:end);
    fname_more = regexp( fname_more , '(\<\w*\>)(\(.*\)|\{.*\}|\.\<\w*\>|$)*' , 'tokens' );
    fname_more = fname_more{1};
    fname = fname_more{1};
    S = [ '.f.' fname_more{2} ];
  end
  if strncmp(S,'.F.',3)
    fname = S(4:end);
    S = '.F.';
  end
  if strncmp(S,'.CONTOUR.',9)
    contourcase= S(10:end);
    S = '.CONTOUR.';
  end  
  switch S
    case {'.isGPU'}
      o = I.isGPU;

    case {'.GPUvars'}
      o = I.GPUvars;

    case {'.CONTOURS'}
      o = I.CONTOURS;
      
    case {'.CONTOUR.'}
      if ~isfield( I.CONTOURS , contourcase )
        error('Contour  ''%s'', doesn''t exist.' , contourcase );
      end
      o = transform( I.CONTOURS.(contourcase) , I.SpatialTransform );
      
    case {'.CONTOUR(1)'}
      if numel( s(2).subs ) > 1, error('a single number is expected.'); end
      if numel( s(2).subs{1} ) > 1, error('a single number is expected.'); end
      if numel( s(2).subs{1} ) <= 0, error('a natural number is expected.'); end
      if mod( s(2).subs{1} ,1), error('an integer number is expected.'); end
      contourcase = sprintf('C%06d',s(2).subs{:});
      if ~isfield( I.CONTOURS , contourcase )
        error('Contour  ''%s'', doesn''t exist.' , contourcase );
      end
      o = transform( I.CONTOURS.(contourcase) , I.SpatialTransform );
      
    case {'.MESH{1}'}
      if numel( s(2).subs{1} ) > 1, error('on mesh at each time'); end
      if s(2).subs{1} > numel( I.MESHES )
        o = [];
        return;
      end
      o = I.MESHES{ s(2).subs{1} };

    case {'.MESHES'}
      o = I.MESHES;

    case {'.POINTER'}
      if nargout 
        o = I.POINTER;
      else
        if ~isempty( I.POINTER )
          C = I.POINTER;
          for c = 1:numel(C)
            switch class( C{c} )
              case 'char'
                fprintf( '     #read        ''%s''\n' , C{c} );
              case 'function_handle'
                fprintf( '     #apply       %s\n' , func2str( C{c} ) );
              case 'cell'
                fprintf( '     #apply       %s\n' , C{c}{1} );
            end
          end
        end
      end
      

    case {'.matrix2coords'}  %%move most the information of the spatial transform to the coordinates
                             %%leaving SpatialTransform as rotation as
                             %%posible and the coordinates will have the
                             %%voxels sizes
      
      o = I;
      
%%%%%%%version before april 2015
%       o.SpatialTransform(1:3,4) = o.SpatialTransform(1:3,4) + o.SpatialTransform(1:3,1:3)*[o.X(1);o.Y(1);o.Z(1)];
%       o.X = o.X - o.X(1);
%       o.Y = o.Y - o.Y(1);
%       o.Z = o.Z - o.Z(1);
%%%%%%

%%%%%%%version after april 2015
      t = o.SpatialTransform(1:3,1:3)\o.SpatialTransform(1:3,4);
      o.X = o.X + t(1);
      o.Y = o.Y + t(2);
      o.Z = o.Z + t(3);
      o.SpatialTransform(1:3,4) = 0;
%%%%%%

      [q,d] = qrd( o.SpatialTransform(1:3,1:3) );
      d = diag(d);
      if d(1)<0, d(1)=-d(1);q=q*diag([-1  1  1]); end
      if d(2)<0, d(2)=-d(2);q=q*diag([ 1 -1  1]); end
      if d(3)<0, d(3)=-d(3);q=q*diag([ 1  1 -1]); end
      
      
      o.SpatialTransform( 1:3,1:3 ) = q;
      o.X = o.X*d(1);
      o.Y = o.Y*d(2);
      o.Z = o.Z*d(3);
      
      bb_err = maxnorm( ...
          transform( ndmat_mx( I.X([1 end]) , I.Y([1 end]) , I.Z([1 end]) ) , I.SpatialTransform ) - ...
          transform( ndmat_mx( o.X([1 end]) , o.Y([1 end]) , o.Z([1 end]) ) , o.SpatialTransform ) );
      if bb_err > 2e-5
        error('mal transformada!!!   (%g)', bb_err );
      end
    
      LS = subsref( I , substruct('.','LANDMARKS') );
      if ~isempty( LS )
        o = subsasgn( o , substruct('.','LANDMARKS') , LS );
      end
      
      
      for c = fieldnames( I.CONTOURS ).', c = c{1};
        C = transform( I.CONTOURS.(c) , I.SpatialTransform );
        o = subsasgn( o , substruct('.','CONTOUR','.',c) , C );
      end
      
               
      %if ~isempty( I.MESHES ), warning('cuidado con las MESHES!!'); end
      
      if det( o.SpatialTransform( 1:3,1:3 ) ) < 0
        o = flipdim( o , 'k' );
      end
      
      if o.isGPU, o = toGPU( o ); end
      
      
    case {'.coords2matrix'}  %%move all the information of the coordinates to spatial transform
      
      o = I;
      
      o.SpatialTransform(1:3,4) = o.SpatialTransform(1:3,4) + o.SpatialTransform(1:3,1:3)*[o.X(1);o.Y(1);o.Z(1)];
      o.X = o.X - o.X(1);
      o.Y = o.Y - o.Y(1);
      o.Z = o.Z - o.Z(1);

      
      dx = mean(diff(o.X)); if isnan(dx), dx = 1; end
      dy = mean(diff(o.Y)); if isnan(dy), dy = 1; end
      dz = mean(diff(o.Z)); if isnan(dz), dz = 1; end
      
      h = [ dx ; dy ; dz ; 1 ];
      o.SpatialTransform = o.SpatialTransform*diag(h);
      o.X = o.X / h(1);
      o.Y = o.Y / h(2);
      o.Z = o.Z / h(3);
      
      if maxnorm( ...
          transform( ndmat_mx( I.X([1 end]) , I.Y([1 end]) , I.Z([1 end]) ) , I.SpatialTransform ) - ...
          transform( ndmat_mx( o.X([1 end]) , o.Y([1 end]) , o.Z([1 end]) ) , o.SpatialTransform ) ) > 1e-6
        error('mal transformada!!!');
      end
    
      LS = subsref( I , substruct('.','LANDMARKS') );
      if ~isempty( LS )
        o = subsasgn( o , substruct('.','LANDMARKS') , LS );
      end

      
      for c = fieldnames( I.CONTOURS ).', c = c{1};
        C = transform( I.CONTOURS.(c) , I.SpatialTransform );
        o = subsasgn( o , substruct('.','CONTOUR','.',c) , C );
      end
      
      %if ~isempty( I.MESHES ), warning('cuidado con las MESHES!!'); end

      if o.isGPU, o = toGPU( o ); end
      

    case {'.coords2matrix_noScale'}  %%move all the information of the coordinates to spatial transform
      
      o = I;
      
      o.SpatialTransform(1:3,4) = o.SpatialTransform(1:3,4) + o.SpatialTransform(1:3,1:3)*[o.X(1);o.Y(1);o.Z(1)];
      o.X = o.X - o.X(1);
      o.Y = o.Y - o.Y(1);
      o.Z = o.Z - o.Z(1);

      
      if maxnorm( ...
          transform( ndmat_mx( I.X([1 end]) , I.Y([1 end]) , I.Z([1 end]) ) , I.SpatialTransform ) - ...
          transform( ndmat_mx( o.X([1 end]) , o.Y([1 end]) , o.Z([1 end]) ) , o.SpatialTransform ) ) > 1e-9
        error('mal transformada!!!');
      end
    
      LS = subsref( I , substruct('.','LANDMARKS') );
      if ~isempty( LS )
        o = subsasgn( o , substruct('.','LANDMARKS') , LS );
      end

      
      for c = fieldnames( I.CONTOURS ).', c = c{1};
        C = transform( I.CONTOURS.(c) , I.SpatialTransform );
        o = subsasgn( o , substruct('.','CONTOUR','.',c) , C );
      end
      
      
      if ~isempty( I.MESHES ), warning('cuidado con las MESHES!!'); end

      if o.isGPU, o = toGPU( o ); end
      

    case {'.centerGrid'}  
      
      X0 = transform( [ I.X(1) , I.Y(1) , I.Z(1) ] , I.SpatialTransform );

      o = I;
      
      o.X = o.X - mean( range( o.X ) );
      o.Y = o.Y - mean( range( o.Y ) );
      o.Z = o.Z - mean( range( o.Z ) );

      d = transform( [ o.X(1) , o.Y(1) , o.Z(1) ] , I.SpatialTransform ) - X0;
      o.SpatialTransform(1:3,4) =  o.SpatialTransform(1:3,4) - d(:);

      
      if maxnorm( ...
          transform( ndmat_mx( I.X([1 end]) , I.Y([1 end]) , I.Z([1 end]) ) , I.SpatialTransform ) - ...
          transform( ndmat_mx( o.X([1 end]) , o.Y([1 end]) , o.Z([1 end]) ) , o.SpatialTransform ) ) > 1e-6
        error('mal transformada!!!');
      end
    
      LS = subsref( I , substruct('.','LANDMARKS') );
      if ~isempty( LS )
        o = subsasgn( o , substruct('.','LANDMARKS') , LS );
      end

      for c = fieldnames( I.CONTOURS ).', c = c{1};
        C = transform( I.CONTOURS.(c) , I.SpatialTransform );
        o = subsasgn( o , substruct('.','CONTOUR','.',c) , C );
      end
      
      %if ~isempty( I.MESHES ), warning('cuidado con las MESHES!!'); end
      
    case {'.setLABELS(1)'}
      L = s(2).subs{1};
      
%       if isa(L,'I3D'), L = L.data; end
      
      if isempty( L )
        error('use cleanout');
      elseif isa( L , 'I3D' )
        L = cleanout(L,'info','others','fields','landmarks','meshes','pointer','data','contours');
        L = at( L , I );
        I.LABELS = L.LABELS;
        I.LABELS_INFO = L.LABELS_INFO;
      elseif isnumeric( L ) || islogical( L )
        I.LABELS = uint16( L );
        if size(I.LABELS,1) ~= numel(I.X), error('I3D:LabelsIncorrectSize','discrepancy size in X!!!'); end
        if size(I.LABELS,2) ~= numel(I.Y), error('I3D:LabelsIncorrectSize','discrepancy size in Y!!!'); end
        if size(I.LABELS,3) ~= numel(I.Z), error('I3D:LabelsIncorrectSize','discrepancy size in Z!!!'); end
        if size(I.LABELS,4) ~= numel(I.T), error('I3D:LabelsIncorrectSize','discrepancy size in T!!!'); end
        if size(I.LABELS,5) ~= 1         , error('I3D:LabelsIncorrectSize','only scalar LABELS allowed!!!'); end
        I= fixLABELS(I);
      end
      o = I;
      
    
    case {'.IJK(1)'}
      if size(s(2).subs{1},2) ~= 3, error('Invalid Access at %s you need 3 columns.' , S ); end
      o = transform(  s(2).subs{1}  ,inv(I.SpatialTransform),'rows');
      o = [ val2ind( I.X , o(:,1) , 'sorted' ) , val2ind( I.Y , o(:,2) , 'sorted' ) , val2ind( I.Z , o(:,3) , 'sorted' ) ];
      
    case {'.c','.container'}
      o = I;
      o.POINTER = {''};
      o.data   = [];
      o.LABELS = [];
      o.INFO   = [];
      o.FIELDS = [];
      o.OTHERS = [];
      o.GRID_PROPERTIES = [];
      o.LANDMARKS = [];
      o.CONTOURS = struct();
      o.MESHES = {};
      o.ImageTransform = [0 0;1 1];
    


    case {'.nLABELS'}
      if any( I.LABELS(:) )
        L = false(1,65535);
        L( I.LABELS( ~~I.LABELS ) ) = true;
        L = find(L);
        o = numel( L );
      else
        o = 0;
      end
    
    case {'.uLABELS'}
      if any( I.LABELS(:) )
        L = false(1,65535);
        L( I.LABELS( ~~I.LABELS ) ) = true;
        o = find(L);
      else
        o = [];
      end

    case {'.INFO' '.info'}
      o = I.INFO;
    case {'.OTHERS'}
      o = I.OTHERS;
    case {'.GRID_PROPERTIES' }
      o = I.GRID_PROPERTIES;
      
      
    %%interpolation weights
    case {'.weights(1)'}
      points = s(2).subs{1};
      
      if ~isnumeric( points ) ||  size(points,2) ~= 3
        error('[nP x 3] points expected');
      end
      
      o = InterpOn3DGrid( zeros([numel(I.X),numel(I.Y),numel(I.Z),1,1,0],'double') ,...
                  I.X , I.Y , I.Z , points                                 ,...
                  'omatrix', I.SpatialTransform                            ,...
                  I.SpatialInterpolation                                   ,...
                  'outside_value' , I.OutsideValue                         ,...
                  I.BoundaryMode  , I.BoundarySize                         ,...
                  'weights'                                                ,...
                  optional_args{:} );
     
      
      
    %%access to data
    case {'.DATA'}                               % I.data
      o= I.data;
    case {'.data'}                               % I.data
      o= I.data;
      if iscell(o), o = {}; end
    case {'.data(1)'}                            % I.data(:)   I.data(564)
      if isempty( I.data ) && ~iscell( I.data )
        o = [];
      elseif iscell( I.data )
        if ischar( s(2).subs{1} ) && strcmp( s(2).subs{1} , ':' )
          o = I.data;
        else
          error('only  '':''  allowed for dereferenced images');
        end
      else
        if ~ischar( s(2).subs{1} ) && ~islogical( s(2).subs{1} )
          s(2).subs = cellfun( @(x) round(x) , s(2).subs , 'UniformOutput',false );
        end
        o= I.data( s(2).subs{:} );
      end
    case {'.data(3)' '.data(4)' '.data(_)' }      % I.data(1,2,3)   I.data(1,2,3,4) I.data(1,2,3,4,1:2)
%       ndim = max( ndims(I.data) , 4 );
%       [ ii{1:numel(s(2).subs)} ] = ndgrid( s(2).subs{:} );
%       [ s(2).subs{1:ndim} ] = ind2sub( size(I.data) , sub2ind( size(I.data) , ii{:} ) );

      s(2).subs = complete( s(2).subs );

      if any( s(2).subs{1} > numel(I.X) ), error('I3D:InvalidSubsref','error in I3D/subsref ''%s''. Be care to use ''end''.',S); end
      if any( s(2).subs{2} > numel(I.Y) ), error('I3D:InvalidSubsref','error in I3D/subsref ''%s''. Be care to use ''end''.',S); end
      if any( s(2).subs{3} > numel(I.Z) ), error('I3D:InvalidSubsref','error in I3D/subsref ''%s''. Be care to use ''end''.',S); end
      if any( s(2).subs{4} > numel(I.T) ), error('I3D:InvalidSubsref','error in I3D/subsref ''%s''. Be care to use ''end''.',S); end
      
%       %%cuidado con los ends ... se evaluan antes en el campo data que en el I3D
%       disp( s(2).subs );
%       cellfun( @(x) disp(x(:)') , s(2).subs )
      
      if isempty( I.data ) || iscell( I.data )
        o = zeros( [ numel( s(1).subs{1} ) , numel( s(1).subs{2} ) , numel( s(1).subs{3} ) , numel( s(1).subs{4} ) ] );
      else
        try,    o = I.data( s(2).subs{:} );
        catch,  error('I3D:InvalidSubsref','error in I3D/subsref ''%s''. Be care to use ''end''.',S);
        end
      end

    %%properties
    case {'.SpatialTransform' '.spatialtransform'}         ,      o = I.SpatialTransform;

    case {'.ImageTransform' '.imagetransform' }            ,      o = I.ImageTransform;

    case {'.SpatialInterpolation' '.spatialinterpolation' },      o = I.SpatialInterpolation;

    case {'.BoundaryMode' '.boundarymode' }                ,      o = I.BoundaryMode;

    case {'.BoundarySize' '.boundarysize' }                ,      o = I.BoundarySize;

    case {'.OutsideValue' '.outsidevalue' }                ,      o = I.OutsideValue;

    case {'.DiscreteSpatialStencil' }                      ,      o = I.DiscreteSpatialStencil;

    case {'.TemporalInterpolation'   }                     ,      o = I.TemporalInterpolation;
      
    case {'.DiscreteTemporalStencil' }                     ,      o = I.DiscreteTemporalStencil;

    %%time
    case '.T'        ,      o = double( I.T(:).' );                                   
    case '.T{1}'     ,      o = val2ind( I.T , s(2).subs{:} , 'sorted' );        
    case {'.deltaT' },      o = diff( I.T(:).' ); if isempty( o ), o = 1; end
      
    %%on Defined Coordinates
    case {'.C(1)','.C{1}'}
      d = s(2).subs{1};
      switch d
        case 1, o= double( I.X(:).' );
        case 2, o= double( I.Y(:).' );
        case 3, o= double( I.Z(:).' );
        case 4, o= double( I.T(:).' );
        otherwise
          error('d must be lover than 5');
      end
    
    case '.X',      o= double( I.X(:).' );                               % I.X
    case '.Y',      o= double( I.Y(:).' );                                   
    case '.Z',      o= double( I.Z(:).' );                                   

    case '.X(1)'     % I.X(idxs)  if idxs == -Inf -> I.X(1)-BoundarySize
      o= double( I.X(:).' );

      s = s(2).subs;
      if numel(s) < 1 || ( ischar( s{1} ) && s{1} == ':' ), s{1} = 1:numel(I.X); end
      if iscell(s), s = s{1}; end
      
      if any( s < 1          & ~isinf(s) ), warning('I3D:invalidIndex','indexes , smaller than 1.');        end
      if any( s > numel(I.X) & ~isinf(s) ), warning('I3D:invalidIndex','indexes , larger than size(I.X).'); end
      s( ( s > numel(I.X) | s < 1 ) & ~isinf(s) ) = [];
      
      infs_pos = isinf(s) & s > 0;
      infs_neg = isinf(s) & s < 0;
      s( infs_pos | infs_neg ) = 1;
      
      o = o(s);
      o( infs_pos ) = I.X(end) + I.BoundarySize;
      o( infs_neg ) = I.X( 1 ) - I.BoundarySize;
    case '.Y(1)'
      o= double( I.Y(:)' );

      s = s(2).subs;
      if numel(s) < 1 || ( ischar( s{1} ) && s{1} == ':' ), s{1} = 1:numel(I.Y); end
      if iscell(s), s = s{1}; end
      
      if any( s < 1          & ~isinf(s) ), warning('I3D:invalidIndex','indexes , smaller than 1.');        end
      if any( s > numel(I.Y) & ~isinf(s) ), warning('I3D:invalidIndex','indexes , larger than size(I.Y).'); end
      s( ( s > numel(I.Y) | s < 1 ) & ~isinf(s) ) = [];
      
      infs_pos = isinf(s) & s > 0;
      infs_neg = isinf(s) & s < 0;
      s( infs_pos | infs_neg ) = 1;
      
      o = o(s);
      o( infs_pos ) = I.Y(end) + I.BoundarySize;
      o( infs_neg ) = I.Y( 1 ) - I.BoundarySize;
    case '.Z(1)'
      o= double( I.Z(:)' );

      s = s(2).subs;
      if numel(s) < 1 || ( ischar( s{1} ) && s{1} == ':' ), s{1} = 1:numel(I.Z); end
      if iscell(s), s = s{1}; end
      
      if any( s < 1          & ~isinf(s) ), warning('I3D:invalidIndex','indexes , smaller than 1.');        end
      if any( s > numel(I.Z) & ~isinf(s) ), warning('I3D:invalidIndex','indexes , larger than size(I.Z).'); end
      s( ( s > numel(I.Z) | s < 1 ) & ~isinf(s) ) = [];
      
      infs_pos = isinf(s) & s > 0;
      infs_neg = isinf(s) & s < 0;
      s( infs_pos | infs_neg ) = 1;
      
      o = o(s);
      o( infs_pos ) = I.Z(end) + I.BoundarySize;
      o( infs_neg ) = I.Z( 1 ) - I.BoundarySize;
      
      
    case '.X{1}',   o = val2ind( I.X(:).' , s(2).subs{:} , 'sorted' );        % return the indices!!!    %%try yourself  I.X( I.X{[2 1 3 3.6]} )
    case '.Y{1}',   o = val2ind( I.Y(:).' , s(2).subs{:} , 'sorted' );        
    case '.Z{1}',   o = val2ind( I.Z(:).' , s(2).subs{:} , 'sorted' );        

    case '.DX',     o= dualVector( I.X(:).' );                             % I.X
    case '.DY',     o= dualVector( I.Y(:).' );                             
    case '.DZ',     o= dualVector( I.Z(:).' );                             
      
    case {'.deltaX' },      o = diff( I.X(:).' ); if isempty( o ), o = 1; end
    case {'.deltaY' },      o = diff( I.Y(:).' ); if isempty( o ), o = 1; end
    case {'.deltaZ' },      o = diff( I.Z(:).' ); if isempty( o ), o = 1; end
      
    case '.X(0)'
      [optional_args,i,every] = parseargs( optional_args , 'Every' ,'$DEFS$',0 );
      if every
        n = numel(I.X);
        o = Interp1D( I.X(:) , 1:n , 1:every:n ,'linear',optional_args{:}).';
        o = o(:).';
      else, error('I3D:subsref','only allowed ''e'' every');
      end
    case '.Y(0)'
      [optional_args,i,every] = parseargs( optional_args , 'Every' ,'$DEFS$',0 );
      if every
        n = numel(I.Y);
        o = Interp1D( I.Y(:) , 1:n , 1:every:n ,'linear',optional_args{:}).';
        o = o(:).';
      else, error('I3D:subsref','only allowed ''e'' every');
      end
    case '.Z(0)'
      [optional_args,i,every] = parseargs( optional_args , 'Every' ,'$DEFS$',0 );
      if every
        n = numel(I.Z);
        o = Interp1D( I.Z(:) , 1:n , 1:every:n ,'linear',optional_args{:}).';
        o = o(:).';
      else, error('I3D:subsref','only allowed ''e'' every');
      end
      
      
    case {'.center'}
      o = [ mean([I.X(1) I.X(end)])  mean([I.Y(1) I.Y(end)])  mean([I.Z(1) I.Z(end)]) ];
      o = transform( o , I.SpatialTransform , 'rows');
      
    %%GRIDs
    %%coordenadas transformadas
    case {'.XYZ'}
      o = ndmat_mx( I.X , I.Y , I.Z );
      o = transform( o , I.SpatialTransform , 'rows');
    case {'.XYZh'}
      o = ndmat_mx( I.X , I.Y , I.Z );
      o = transform( o , I.SpatialTransform , 'rows');
      o(:,4) = 1;
    case {'.XYZ(3)'}
      o= ndmat_mx( I.X(s(2).subs{1}) , I.Y(s(2).subs{2}) , I.Z(s(2).subs{3}) );
      o = transform( o , I.SpatialTransform , 'rows');
    case {'.XYZh(3)'}
      o = ndmat_mx( I.X(s(2).subs{1}) , I.Y(s(2).subs{2}) , I.Z(s(2).subs{3}) );
      o = transform( o , I.SpatialTransform , 'rows');
      o(:,4) = 1;
    case '.XYZ(1)'                           % I.XYZ( [i1 j1 z1 ; i2 j2 k2 ] )
      if     islogical( s(2).subs{1} )  ||  size(s(2).subs{1},2) == 1
        o = ndmat_mx( I.X , I.Y , I.Z );
        o = o( s(2).subs{1} , : );
        o = transform( o , I.SpatialTransform , 'rows');
      elseif size(s(2).subs{1},2) == 3
        o = s(2).subs{1};
        o = transform( [ vec(I.X(o(:,1))) , vec(I.Y(o(:,2))) , vec(I.Z(o(:,3))) ] , I.SpatialTransform , 'rows');
      else
        error('Invalid Access at %s you need 3 columns.' , S );
      end
    case '.XYZh(1)'
      if     islogical( s(2).subs{1} )  ||  size(s(2).subs{1},2) == 1
        o = ndmat_mx( I.X , I.Y , I.Z );
        o = o( s(2).subs{1} , : );
        o = transform( o , I.SpatialTransform , 'rows');
      elseif size(s(2).subs{1},2) == 3
        o = s(2).subs{1};
        o = transform( [ vec(I.X(o(:,1))) , vec(I.Y(o(:,2))) , vec(I.Z(o(:,3))) ] , I.SpatialTransform , 'rows');
      else
        error('Invalid Access at %s you need 3 columns.' , S );
      end
      o(:,4) = 1;

    case '.XX',     o= subsref(I,substruct('.','XYZ')); o= reshape(o(:,1),[numel(I.X) numel(I.Y) numel(I.Z)]);
    case '.YY',     o= subsref(I,substruct('.','XYZ')); o= reshape(o(:,2),[numel(I.X) numel(I.Y) numel(I.Z)]);
    case '.ZZ',     o= subsref(I,substruct('.','XYZ')); o= reshape(o(:,3),[numel(I.X) numel(I.Y) numel(I.Z)]);
    case '.XX(3)'
      o= subsref(I,substruct('.','XYZ','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X); else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y); else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z); else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,1),[ni nj nk]);
    case '.YY(3)'
      o= subsref(I,substruct('.','XYZ','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X); else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y); else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z); else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,2),[ni nj nk]);
    case '.ZZ(3)'
      o= subsref(I,substruct('.','XYZ','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X); else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y); else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z); else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,3),[ni nj nk]);


    %%coordenadas sin transformar
    case {'.GRID' '.CXYZ'}
      o = ndmat_mx( I.X , I.Y , I.Z );
      
    case {'.GRIDh' '.CXYZh'}
      o = ndmat_mx( I.X , I.Y , I.Z );
      o(:,4) = 1;
      
    case {'.GRID(3)' '.CXYZ(3)'}               % I.GRID(1:3,1:4,1:5)  
      o = ndmat_mx( I.X(s(2).subs{1}) , I.Y(s(2).subs{2}) , I.Z(s(2).subs{3}) );

    case {'.GRIDh(3)' '.CXYZh(3)'}
      o = ndma_mx( I.X(s(2).subs{1}) , I.Y(s(2).subs{2}) , I.Z(s(2).subs{3}) );
      o(:,4) = 1;
      
    case {'.GRID(1)' '.CXYZ(1)'}               % I.GRID( [i1 j1 z1 ; i2 j2 k2 ] )   
      if     islogical( s(2).subs{1} )  ||  size(s(2).subs{1},2) == 1
        o = ndmat_mx( I.X , I.Y , I.Z );
        o = o( s(2).subs{1} , : );
      elseif size(s(2).subs{1},2) == 3
        o = s(2).subs{1};
        o = [ vec(I.X(o(:,1))) , vec(I.Y(o(:,2))) , vec(I.Z(o(:,3))) ];
      else
        error('Invalid Access at %s you need 3 columns.' , S );
      end

    case {'.GRIDh(1)' '.CXYZh(1)'}
      if     islogical( s(2).subs{1} )  ||  size(s(2).subs{1},2) == 1
        o = ndmat_mx( I.X , I.Y , I.Z );
        o = o( s(2).subs{1} , : );
      elseif size(s(2).subs{1},2) == 3
        o = s(2).subs{1};
        o = [ vec(I.X(o(:,1))) , vec(I.Y(o(:,2))) , vec(I.Z(o(:,3))) ];
      else
        error('Invalid Access at %s you need 3 columns.' , S );
      end
      o(:,4) = 1;

    case '.CXX',     o= subsref(I,substruct('.','GRID')); o= reshape(o(:,1),[numel(I.X) numel(I.Y) numel(I.Z)]);
    case '.CYY',     o= subsref(I,substruct('.','GRID')); o= reshape(o(:,2),[numel(I.X) numel(I.Y) numel(I.Z)]);
    case '.CZZ',     o= subsref(I,substruct('.','GRID')); o= reshape(o(:,3),[numel(I.X) numel(I.Y) numel(I.Z)]);
    case '.CXX(3)'
      o= subsref(I,substruct('.','GRID','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X); else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y); else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z); else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,1),[ni nj nk]);
    case '.CYY(3)'
      o= subsref(I,substruct('.','GRID','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X); else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y); else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z); else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,2),[ni nj nk]);
    case '.CZZ(3)'
      o= subsref(I,substruct('.','GRID','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X); else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y); else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z); else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,3),[ni nj nk]);


    %%coordenadas duales transformadas
    case '.DXYZ'
      o = ndmat_mx( dualVector(I.X) , dualVector(I.Y) , dualVector(I.Z) );
      o = transform( o , I.SpatialTransform , 'rows');
    case '.DXYZ(3)'     
      x= dualVector(I.X); y= dualVector(I.Y); z=dualVector(I.Z);
      o = ndmat_mx( x(s(2).subs{1}) , y(s(2).subs{2}) , z(s(2).subs{3}) );
      o = transform( o , I.SpatialTransform , 'rows');
      
    case '.DXX',     o= subsref(I,substruct('.','DXYZ')); o= reshape(o(:,1),[numel(I.X) numel(I.Y) numel(I.Z)]+1);
    case '.DYY',     o= subsref(I,substruct('.','DXYZ')); o= reshape(o(:,2),[numel(I.X) numel(I.Y) numel(I.Z)]+1);
    case '.DZZ',     o= subsref(I,substruct('.','DXYZ')); o= reshape(o(:,3),[numel(I.X) numel(I.Y) numel(I.Z)]+1);
    case '.DXX(3)'
      o= subsref(I,substruct('.','DXYZ','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X)+1; else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y)+1; else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z)+1; else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,1),[ni nj nk]);
    case '.DYY(3)'
      o= subsref(I,substruct('.','DXYZ','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X)+1; else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y)+1; else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z)+1; else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,2),[ni nj nk]);
    case '.DZZ(3)'
      o= subsref(I,substruct('.','DXYZ','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X)+1; else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y)+1; else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z)+1; else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,3),[ni nj nk]);

      
    %%coordenadas duales sin transformar
    case {'.DGRID' '.DCXYZ'}
      o = ndmat_mx( dualVector(I.X) , dualVector(I.Y) , dualVector(I.Z) );

    case {'.DGRID(3)' '.DCXYZ(3)'}
      x= dualVector(I.X); y= dualVector(I.Y); z=dualVector(I.Z);
      o = ndmat_mx( x(s(2).subs{1}) , y(s(2).subs{2}) , z(s(2).subs{3}) );


    case '.DCXX',     o= subsref(I,substruct('.','DGRID')); o= reshape(o(:,1),[numel(I.X) numel(I.Y) numel(I.Z)]+1);
    case '.DCYY',     o= subsref(I,substruct('.','DGRID')); o= reshape(o(:,2),[numel(I.X) numel(I.Y) numel(I.Z)]+1);
    case '.DCZZ',     o= subsref(I,substruct('.','DGRID')); o= reshape(o(:,3),[numel(I.X) numel(I.Y) numel(I.Z)]+1);
    case '.DCXX(3)'
      o= subsref(I,substruct('.','DGRID','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X)+1; else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y)+1; else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z)+1; else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,1),[ni nj nk]);
    case '.DCYY(3)'  
      o= subsref(I,substruct('.','DGRID','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X)+1; else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y)+1; else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z)+1; else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,2),[ni nj nk]);
    case '.DCZZ(3)'
      o= subsref(I,substruct('.','DGRID','()',s(2).subs)); 
      if iscolon(s(2).subs{1}), ni= numel(I.X)+1; else, ni= numel(s(2).subs{1}); end; 
      if iscolon(s(2).subs{2}), nj= numel(I.Y)+1; else, nj= numel(s(2).subs{2}); end; 
      if iscolon(s(2).subs{3}), nk= numel(I.Z)+1; else, nk= numel(s(2).subs{3}); end; 
      o= reshape(o(:,3),[ni nj nk]);
      
    %%more on GRIDs  
    case '.XYZ{1}'                           % try yourself         I.XYZ(I.XYZ{[12.6 1 1;15.1 2 1]})
      if size(s(2).subs{1},2) ~= 3, error('Invalid Access at %s you need 3 columns.' , S ); end
      o = transform(  s(2).subs{1}  ,inv(I.SpatialTransform),'rows');
      o= [ val2ind( I.X , o(:,1) , 'sorted' ) , val2ind( I.Y , o(:,2) , 'sorted' ) , val2ind( I.Z , o(:,3) , 'sorted' ) ];
    case {'.GRID{1}' '.CXYZ{1}'}   % I.GRID{ [x y z; x2 y2 z3;...] }
      if size(s(2).subs{1},2) ~= 3, error('Invalid Access at %s you need 3 columns.' , S ); end
      o = s(2).subs{1};
      o = [ val2ind( I.X , o(:,1) , 'sorted' ) , val2ind( I.Y , o(:,2) , 'sorted' ) , val2ind( I.Z , o(:,3) , 'sorted' ) ];
    case {'.ID'}
      o = ndmat_mx( I.X , I.Y , I.Z );
      o = reshape( transform( o , I.SpatialTransform , 'rows') , [ numel(I.X) , numel(I.Y) , numel(I.Z) , 3] );
    case {'.IDENTITY2D'}

      if numel(I.Z) ~= 1 || I.Z ~= 0, error('it is not a 2D image'); end
      if ~isequal( I.SpatialTransform(:,3) , [0;0;1;0] ) || ...
         ~isequal( I.SpatialTransform(3,:) , [0,0,1,0] )
        error('it is a 3d rotated 2D image');
      end
      
      o = I;
      o.POINTER = {''};
      o.data   = [];
      o.LABELS = [];
      o.INFO   = [];
      o.OTHERS = [];
      o.FIELDS = [];
      o.LANDMARKS = [];
      o.CONTOURS = struct();
      o.MESHES = {};
      
      o = DATA_action( o , [ '@(X) ' ...
            'reshape(transform(ndmat_mx( ' uneval( I.X , I.Y ) '),' ...
            uneval( I.SpatialTransform ) ',''rows2d''),['                 ...
            uneval( numel(I.X) , numel(I.Y) , 1 , 1 , 2 ) '])' ] );
          
      o.ImageTransform = [ min(o.data(:)) 0 ; max(o.data(:)) 1 ];
      
      
    case {'.IDENTITY'}
      o = I;
      o.POINTER = {''};
      o.data   = [];
      o.LABELS = [];
      o.INFO   = [];
      o.OTHERS = [];
      o.FIELDS = [];
      o.LANDMARKS = [];
      o.CONTOURS = struct();
      o.MESHES = {};
      
      o = DATA_action( o , [ '@(X) ' ...
            'reshape(transform(ndmat_mx( ' uneval( I.X , I.Y , I.Z ) '),' ...
            uneval( I.SpatialTransform ) ',''rows''),['                 ...
            uneval( numel(I.X) , numel(I.Y) , numel(I.Z) , 1 , 3 ) '])' ] );
          
      o.ImageTransform = [ min(o.data(:)) 0 ; max(o.data(:)) 1 ];

    case {'.ID(3)'}
      indx = s(2).subs{1};
      indy = s(2).subs{2};
      indz = s(2).subs{3};
      o = ndmat_nx( I.X(indx) , I.Y(indy) , I.Z(indz) );
      o = reshape( transform( o , I.SpatialTransform , 'rows') , [ numel(indx) , numel(indy) , numel(indz) , 3] );
    case '.IDgrid'
      o = ndmat_mx( I.X , I.Y , I.Z );
      o = reshape( o , [ numel(I.X) , numel(I.Y) , numel(I.Z) , 3] );
    case '.IDgrid(3)'                           % I.GRID(1:3,1:4,1:5)  
      indx = s(2).subs{1};
      indy = s(2).subs{2};
      indz = s(2).subs{3};
      o = ndmat_nx( I.X(indx) , I.Y(indy) , I.Z(indz) );
      o = reshape( o , [ numel(indx) , numel(indy) , numel(indz) , 3] );
      
    %%subimage
    case {'.c1'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',1} ) );
    case {'.c2'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',2} ) );
    case {'.c3'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',3} ) );
    case {'.c4'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',4} ) );
    case {'.c5'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',5} ) );
    case {'.c6'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',6} ) );
    case {'.c(1)'},o = I3D_subsref( I , substruct('()',{':',':',':',':',s(2).subs{1}} ) );
      
    case {'.c1_1'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',1,1} ) );
    case {'.c1_2'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',1,2} ) );
    case {'.c1_3'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',1,3} ) );
      
    case {'.c2_1'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',2,1} ) );
    case {'.c2_2'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',2,2} ) );
    case {'.c2_3'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',2,3} ) );

    case {'.c3_1'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',3,1} ) );
    case {'.c3_2'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',3,2} ) );
    case {'.c3_3'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',3,3} ) );
    case {'.c(2)'},  o = I3D_subsref( I , substruct('()',{':',':',':',':',s(2).subs{1},s(2).subs{2}} ) );

    case {'.t1' },  o = I3D_subsref( I , substruct('()',{':',':',':',1} ) );
    case {'.t2' },  o = I3D_subsref( I , substruct('()',{':',':',':',2} ) );
    case {'.t3' },  o = I3D_subsref( I , substruct('()',{':',':',':',3} ) );
    case {'.t4' },  o = I3D_subsref( I , substruct('()',{':',':',':',4} ) );
    case {'.t5' },  o = I3D_subsref( I , substruct('()',{':',':',':',5} ) );
    case {'.t6' },  o = I3D_subsref( I , substruct('()',{':',':',':',6} ) );
    case {'.t7' },  o = I3D_subsref( I , substruct('()',{':',':',':',7} ) );
    case {'.t8' },  o = I3D_subsref( I , substruct('()',{':',':',':',8} ) );
    case {'.t9' },  o = I3D_subsref( I , substruct('()',{':',':',':',9} ) );
    case {'.t10'},  o = I3D_subsref( I , substruct('()',{':',':',':',10} ) );
    case {'.t11'},  o = I3D_subsref( I , substruct('()',{':',':',':',11} ) );
    case {'.t12'},  o = I3D_subsref( I , substruct('()',{':',':',':',12} ) );
    case {'.t13'},  o = I3D_subsref( I , substruct('()',{':',':',':',13} ) );
    case {'.t14'},  o = I3D_subsref( I , substruct('()',{':',':',':',14} ) );
    case {'.t15'},  o = I3D_subsref( I , substruct('()',{':',':',':',15} ) );
    case {'.t16'},  o = I3D_subsref( I , substruct('()',{':',':',':',16} ) );
    case {'.t17'},  o = I3D_subsref( I , substruct('()',{':',':',':',17} ) );
    case {'.t18'},  o = I3D_subsref( I , substruct('()',{':',':',':',18} ) );
    case {'.t19'},  o = I3D_subsref( I , substruct('()',{':',':',':',19} ) );
    case {'.t20'},  o = I3D_subsref( I , substruct('()',{':',':',':',20} ) );
    case {'.t(1)'}, o = I3D_subsref( I , substruct('()',{':',':',':',s(2).subs{1}} ) );
    
    
    case {'(3)' '(4)' '(_)'}
      ss = complete( s(1).subs );
      
      
      
      
      for d = {'i' 'j' 'k' 't'}
        switch d{1}
          case 'i'
            if islogical( ss{1} )
              if numel(ss{1}) > numel(I.X), error('invalidIndex at ''i''.'); end
            else
              if any( ss{1} < 1          ), warning('I3D:invalidIndex','indexes at coordinate ''i'' , smaller than 1.');        end
              if any( ss{1} > numel(I.X) ), warning('I3D:invalidIndex','indexes at coordinate ''i'' , larger than size(I.X).'); end
              ss{1}( ss{1} > numel(I.X) | ss{1} < 1 ) = [];
            end
          case 'j'
            if islogical( ss{2} )
              if numel(ss{2}) > numel(I.Y), error('invalidIndex at ''j''.'); end
            else
              if any( ss{2} < 1          ), warning('I3D:invalidIndex','indexes at coordinate ''j'' , smaller than 1.');        end
              if any( ss{2} > numel(I.Y) ), warning('I3D:invalidIndex','indexes at coordinate ''j'' , larger than size(I.Y).'); end
              ss{2}( ss{2} > numel(I.Y) | ss{2} < 1 ) = [];
            end
          case 'k'
            if islogical( ss{3} )
              if numel(ss{3}) > numel(I.Z), error('invalidIndex at ''k''.'); end
            else
              if any( ss{3} < 1          ), warning('I3D:invalidIndex','indexes at coordinate ''k'' , smaller than 1.');        end
              if any( ss{3} > numel(I.Z) ), warning('I3D:invalidIndex','indexes at coordinate ''k'' , larger than size(I.Z).'); end
              ss{3}( ss{3} > numel(I.Z) | ss{3} < 1 ) = [];
            end
          case 't'
            if islogical( ss{4} )
              if numel(ss{4}) > numel(I.T), error('invalidIndex at ''t''.'); end
            else
              if any( ss{4} < 1          ), warning('I3D:invalidIndex','indexes at coordinate ''t'' , smaller than 1.');        end
              if any( ss{4} > numel(I.T) ), warning('I3D:invalidIndex','indexes at coordinate ''t'' , larger than size(I.T).'); end
              ss{4}( ss{4} > numel(I.T) | ss{4} < 1 ) = [];
            end
        end            
      end

      o        = I;
      if iscell( o.data ), o.data = []; end
      if ~isempty( o.data   )
        %o.data   = o.data(   ss{:} );
        o = DATA_action( o , [ '@(X) X(' uneval( ss{:} ) ')' ] );
      end
      if ~isempty( o.LABELS ), o.LABELS = o.LABELS( ss{1:4} ); end
      o.X      = o.X( ss{1} ); o.X = double( o.X(:).' );
      o.Y      = o.Y( ss{2} ); o.Y = double( o.Y(:).' );
      o.Z      = o.Z( ss{3} ); o.Z = double( o.Z(:).' );
      o.T      = o.T( ss{4} ); o.T = double( o.T(:).' );

      if ~isempty( o.FIELDS )
        for fn = fieldnames(o.FIELDS)'
          if isa( o.FIELDS.(fn{1}) , 'I3D' ), continue; end
          try
              o.FIELDS.( fn{1} ) = o.FIELDS.( fn{1} )( ss{ : },:,:,:,:,:,:,:,:,: );
          catch
            try
              o.FIELDS.( fn{1} ) = o.FIELDS.( fn{1} )( ss{1:4},:,:,:,:,:,:,:,:,: );
            catch
              o.FIELDS.( fn{1} ) = o.FIELDS.( fn{1} )( ss{1:3},:,:,:,:,:,:,:,:,: );
            end
          end
        end
      end
      
      
      if ~isempty( o.GRID_PROPERTIES )  &&  isstruct( o.GRID_PROPERTIES )
        for gp = fieldnames(o.GRID_PROPERTIES)'
          if ~isscalar( o.GRID_PROPERTIES.( gp{1} ) )
            o.GRID_PROPERTIES.( gp{1} ) = o.GRID_PROPERTIES.( gp{1} )( ss{1} , ss{2} , ss{3} );
          end
        end
      end
      
      if o.isGPU, o = toGPU( o ); end
      

    %%interpolations
    case {'(1)'}
      if ischar( s(1).subs{1} ) && strcmp( s(1).subs{1} , ':' )
        o = I.data(:);
      elseif ~isa(s(1).subs{1}, 'I3D') && islogical( s(1).subs{1} )
        o = I.data( s(1).subs{1} );
      else
        o = at( I , s(1).subs{1} , optional_args{:} );
      end
      
    case {'(2)'}    % I( xyz , time )
      o = at( subsref( I , substruct('()',{':',':',':',s(1).subs{2}}) ) , ...
              s(1).subs{1} , optional_args{:} );
      
      
      
    %%landmarks
    case {'.LANDMARKSlocal'}
      if isempty( I.LANDMARKS )
        o = [];
        return;
      end
      
      switch class( I.LANDMARKS )
        case 'double'
          if size( I.LANDMARKS , 2 ) ~= 3, warning( 'I3D:Landmarks','Invalid Landmarks. It have to be a Nx3 matrix.'); end
          o = I.LANDMARKS;
      end

    case {'.LANDMARKS'}
      if isempty( I.LANDMARKS )
        o = [];
        return;
      end
      
      switch class( I.LANDMARKS )
        case 'double'
          if size( I.LANDMARKS , 2 ) ~= 3, warning( 'I3D:Landmarks','Invalid Landmarks. It have to be a Nx3 matrix.'); end
          o = transform( I.LANDMARKS , I.SpatialTransform );
      end

%     case {'.LANDMARKSh'}
%       if numel( I.LANDMARKS )
%         if size( I.LANDMARKS ~= 3 ), warning( 'I3D:Landmarks','Invalid Landmarks. It have to be a Nx3 matrix.'); end
%         o = transform( I.LANDMARKS , I.SpatialTransform );
%         o(:,4) = 1;
%       else
%         o = [];
%       end

    %%fields
    case {'.FIELDS'}
      o = I.FIELDS;

    case {'.F(1)'}
      if numel( s(2).subs ) > 1, error('a single number is expected.'); end
      if numel( s(2).subs{1} ) > 1, error('a single number is expected.'); end
      if numel( s(2).subs{1} ) <= 0, error('a natural number is expected.'); end
      if mod( s(2).subs{1} ,1), error('an integer number is expected.'); end
      fname = sprintf('F%06d',s(2).subs{:});

      if isfield( I.FIELDS , fname )
        if isnumeric( I.FIELDS.(fname) )  || islogical( I.FIELDS.(fname) )
          o = remove_dereference( I );
          o.FIELDS = [];
          o.data = I.FIELDS.(fname);
          o.T = 1:size( o.data , 4 );
        elseif isa( I.FIELDS.(fname) , 'I3D' )
          o = I.FIELDS.(fname);
        end
      else
        error('I3D:InvalidFieldName','Inexist Field Name ( ''%s'' )' , fname );
      end
      
    case {'.F.'}   %%devuelve el field 'fname' en su propio container
      if isfield( I.FIELDS , fname )
        if isnumeric( I.FIELDS.(fname) )  || islogical( I.FIELDS.(fname) )
          o = remove_dereference( I );
          o.FIELDS = [];
          o.data = I.FIELDS.(fname);
          o.T = 1:size( o.data , 4 );
        elseif isa( I.FIELDS.(fname) , 'I3D' )
          o = I.FIELDS.(fname);
        end
      else
        error('I3D:InvalidFieldName','Inexist Field Name ( ''%s'' )' , fname );
      end

    case {'.f.'}   %%devuelve el field 'fname' en el container de I
      if ~isfield( I.FIELDS , fname ), error('I3D:InvalidFieldName','Inexist Field Name ( ''%s'' )',fname ); end
      o = remove_dereference( I );
      o.FIELDS = [];
      if isnumeric( I.FIELDS.(fname) ) || islogical( I.FIELDS.(fname) )
        o.data = I.FIELDS.(fname);
        o.T = 1:size( o.data , 4 );
      elseif isa( I.FIELDS.(fname) , 'I3D' )
        o = at( I.FIELDS.(fname) , I );
        % %                     X  -> I
        % %                     Y  -> I
        % %                     Z  -> I
        % %      SpatialTransform  -> I
        % %                  data  -> I.FIELDS.(fname)  interpolated  in I
        % %        ImageTransform  -> I.FIELDS.(fname)
        % %                     T  -> I.FIELDS.(fname).T
        % %  SpatialInterpolation  -> I.FIELDS.(fname)
        % %          BoundaryMode  -> I.FIELDS.(fname)
        % %          BoundarySize  -> I.FIELDS.(fname)
        % %          OutsideValue  -> I.FIELDS.(fname)
        % % TemporalInterpolation  -> I.FIELDS.(fname)
        % %                LABELS  -> I
        % %           LABELS_INFO  -> I
        % %             LANDMARKS  -> I
        % %                MESHES  -> I
        % %                  INFO  -> I.FIELDS.(fname)
        % %                OTHERS  -> I.FIELDS.(fname)
        % %                FIELDS  -> no deberia tener
        o.LABELS      = I.LABELS;
        o.LABELS_INFO = I.LABELS_INFO;
        o.LANDMARKS   = I.LANDMARKS;
        o.CONTOURS    = I.CONTOURS;
        o.MESHES      = I.MESHES;
        o.INFO        = I.FIELDS.(fname).INFO;
        o.OTHERS      = I.FIELDS.(fname).OTHERS;
        
      end

%     case { '.f.(3)' '.f.(4)' '.f.(_)' }
%       if ~isfield( I.FIELDS , fname ), error('I3D:InvalidFieldName','Inexist Field Name ( ''%s'' )',fname ); end
%       o = I;
%       o.FIELDS = [];
%       if isnumeric( I.FIELDS.(fname) )
%         o.data = I.FIELDS.(fname);
%         o.T = 1:size( o.data , 4 );
%       elseif isa( I.FIELDS.(fname) , 'I3D' )
%         o = at( I.FIELDS.(fname) , I );
%       end
      
%     case { '.f.(3).data' '.f.(4).data' '.f.(_).data' }
%       if ~isfield( I.FIELDS , fname ), error('I3D:InvalidFieldName','Inexist Field Name ( ''%s'' )',fname ); end
%       ss = complete( s(3).subs );
%       
%       if isnumeric( I.FIELDS.(fname) )
%         o = I.FIELDS.(fname)(ss{1:3},:,:,:,:,:,:,:,:);
%       elseif isa( I.FIELDS.(fname) , 'I3D' )
%         o = at( I.FIELDS.(fname) , { I.X(ss{1}) , I.Y(ss{2}) , I.Z(ss{3}) , I.SpatialTransform } );
%         o = o( :,:,:, s(3).subs{4:end} );
%       end

    case { '.f..data(3)' '.f..data(4)' '.f..data(_)' }
      if ~isfield( I.FIELDS , fname ), error('I3D:InvalidFieldName','Inexist Field Name ( ''%s'' )',fname ); end
      ss = complete( s(4).subs );
      
      if isnumeric( I.FIELDS.(fname) ) ||  islogical( I.FIELDS.(fname) )
        o = I.FIELDS.(fname)(ss{1:3},:,:,:,:,:,:,:,:);
      elseif isa( I.FIELDS.(fname) , 'I3D' )
        o = at( I.FIELDS.(fname) , { I.X(ss{1}) , I.Y(ss{2}) , I.Z(ss{3}) , I.SpatialTransform } );
        o = o( :,:,:, s(4).subs{4:end} );
      end

      
    %%labels
    case {'.LABELS'}
      o = I.LABELS;

    case '.LABELS(1)'
      if     islogical( s(2).subs{1} )  ||  size(s(2).subs{1},2) == 1
        o = I.LABELS( s(2).subs{:} );
      elseif size(s(2).subs{1},2) == 3   % I.LABELS([x1 y1 z1;x2 y2 z2])
        if size(s(2).subs{1},2) ~= 3, error('Invalid Access at %s you need 3 columns.' , S ); end
        o = s(2).subs{1};
        o = transform(o,inv(I.SpatialTransform),'rows');
        i = val2ind( I.X , o(:,1) , 'sorted' );
        j = val2ind( I.Y , o(:,2) , 'sorted' );
        o = val2ind( I.Z , o(:,3) , 'sorted' );
        o = I.LABELS( i(:),j(:),o(:),':' );
      else
        error('Invalid Access at %s you need 3 columns.' , S );
      end
    
    
    case '.LABELS(2)'                          % I.LABELS([x1 y1 z1;x2 y2 z2],t)
      if size(s(2).subs{1},2) ~= 3, error('Invalid Access at %s you need 3 columns.' , S ); end
      t = s(2).subs{2};
      o = s(2).subs{1};
      o = transform(o,inv(I.SpatialTransform),'rows');
      i = val2ind( I.X , o(:,1) , 'sorted' );
      j = val2ind( I.Y , o(:,2) , 'sorted' );
      o = val2ind( I.Z , o(:,3) , 'sorted' );
      o = I.LABELS(i(:),j(:),o(:),t);

    case '.LABELS{1}'                         
      error('creia que esto no se usaba nunca!!! ... probarlo.');
      if size(s(2).subs{1},2) ~= 3, error('Invalid Access at %s you need 3 columns.' , S ); end
      o = s(2).subs{1};
      i = val2ind( I.X , o(:,1) , 'sorted' );
      j = val2ind( I.Y , o(:,2) , 'sorted' );
      o = val2ind( I.Z , o(:,3) , 'sorted' );
      o = I.LABELS(i(:),j(:),o(:),':');

    case '.LABELS{2}'                         
      error('creia que esto no se usaba nunca!!! ... probarlo.');
      if size(s(2).subs{1},2) ~= 3, error('Invalid Access at %s you need 3 columns.' , S ); end
      t = s(2).subs{2};
      o = s(2).subs{1};
      i = val2ind( I.X , o(:,1) , 'sorted' );
      j = val2ind( I.Y , o(:,2) , 'sorted' );
      o = val2ind( I.Z , o(:,3) , 'sorted' );
      o = I.LABELS(i(:),j(:),o(:),t);

    case {'.LABELS(3)' '.LABELS(4)'}           % I.LABELS(3,2,4)   I.LABELS(3,2,4,1)
      s(2).subs= complete( s(2).subs );
      s(2).subs = s(2).subs(1:4);
      
      if isempty( I.LABELS )
        o= zeros( [ numel(s(2).subs{1}) , numel(s(2).subs{2}) , numel(s(2).subs{3}) , numel(s(2).subs{4}) ] , 'uint16' );
      else
        o= I.LABELS( s(2).subs{:} );
      end

    case {'.L' '.LabelsAsData' '.L2D' '.D2L'}
      o = remove_dereference( I );
      Ls              = o.LABELS;
      if iscell(o.data), 
        o.LABELS = []; 
      else
        o = subsasgn( o , substruct('.','LABELS') , uint16( o.data ) );
      end
      o.data          = Ls;
      o.SpatialInterpolation = 'nearest';
      o.BoundaryMode  = 'value';
      o.OutsideValue  = 0;

    case {'.LabelsInfo' '.LABELS_INFO'}
      o= I.LABELS_INFO;

    case {'{0}','{1}'}                         %I{1}  I{:}
      if ~isempty(s(1).subs) && iscolon( s(1).subs{1} )

        o= I.LABELS ~= 0;

      elseif ~isempty(s(1).subs) && islogical( s(1).subs{1} )

        bits = s(1).subs{1};
        if ~isvector(bits) || numel(bits) ~= 8
          error('unknown syntax');
        end
        allLABELS = unique( I.LABELS );
        B = allLABELS(:);
        B = dec2bin( B ) == '1';
        B = B( : , end:-1:1 );
        B(:,end+1:8) = false;
        B = B( : , bits );
        allLABELS = allLABELS( any(B,2) );
        
        o= ismembc( double( I.LABELS ) , double( allLABELS ) );
        
      else

        if ~isempty(s(1).subs)
          allLABELS = unique( double( s(1).subs{1} ) );
        else
          allLABELS = [];
        end
        for j = 1:numel( optional_args )
          str = optional_args{j};
          allLABELS = [ allLABELS ; find( strcmp( { I.LABELS_INFO.description } , str ) ) ];
        end
        allLABELS = unique( allLABELS );
        
        o= ismembc( double( I.LABELS ) , allLABELS );

      end

    case {'{1}.description' '{1}.color' '{1}.alpha' '{1}.state'}    %I{1}.description         %%try yourself   cell2mat( I{:}.color )
      if iscolon( s(1).subs{1} )
        [o{1:numel(I.LABELS_INFO),1}] = I.LABELS_INFO(:).(s(2).subs);
      else
        o= I.LABELS_INFO( s(1).subs{1} ).(s(2).subs);
      end
    case {'.description' '.color' '.alpha' '.state'}                 %I.description  I.color       %%try yourself   cell2mat( I.color )
      [o{1:numel(I.LABELS_INFO),1}] = I.LABELS_INFO(:).(s(1).subs);
      
      

%     case {'.set(0)'}   %%usar con cuidado!!! no verfica nada!!!
%       o = set( I , optional_args{:} );



      
%     case {'.resample(1)'}
%       D = s(2).subs{:};
%       if isscalar(D), D = [D D D]; end
%       if numel(D) < 3, D = [D 0]; end
%       D = abs(D);
%       if ~isnan(D(1)) && D(1)~=0 && numel(I.X)>1
%         p1 = I.X( 1 ) - ( I.X( 2 ) - I.X(  1  ) )/2;
%         p2 = I.X(end) + ( I.X(end) - I.X(end-1) )/2;
%         nX = p1:D(1):p2;
%         nX = nX - ( nX(end) + nX(1) )/2 + ( p1+p2 )/2;
%       else
%         nX = I.X;
%       end
%       
%       if ~isnan(D(2)) && D(2)~=0 && numel(I.Y)>1
%         p1 = I.Y( 1 ) - ( I.Y( 2 ) - I.Y(  1  ) )/2;
%         p2 = I.Y(end) + ( I.Y(end) - I.Y(end-1) )/2;
%         nY = p1:D(2):p2;
%         nY = nY - ( nY(end) + nY(1) )/2 + ( p1+p2 )/2;
%       else
%         nY = I.Y;
%       end
%       
%       if ~isnan(D(3)) && D(3)~=0 && numel(I.Z)>1
%         p1 = I.Z( 1 ) - ( I.Z( 2 ) - I.Z(  1  ) )/2;
%         p2 = I.Z(end) + ( I.Z(end) - I.Z(end-1) )/2;
%         nZ = p1:D(3):p2;
%         nZ = nZ - ( nZ(end) + nZ(1) )/2 + ( p1+p2 )/2;
%       else
%         nZ = I.Z;
%       end
%       
%       o   = I;
%       o.X = nX;
%       o.Y = nY;
%       o.Z = nZ;
%       o.data = Interp3DGridOn3DGrid( I.data   , I.X , I.Y , I.Z , nX , nY , nZ , ...
%                                      I.SpatialInterpolation , ...
%                                      'outside_value' , I.OutsideValue , ...
%                                      I.BoundaryMode , I.BoundarySize , ...
%                                      optional_args{:} );
%       if any( I.LABELS(:) )
%         o.LABELS = uint16( ...
%                  Interp3DGridOn3DGrid( I.LABELS , I.X , I.Y , I.Z , nX , nY , nZ , ...
%                               'nearest' , ...
%                               'outside_value' , 0 , ...
%                               'value' ) ...
%                           );
%       else
%         o.LABELS = zeros([size(o.data,1) size(o.data,2) size(o.data,3) size(o.data,4)],'uint16');
%       end
    
      
    
      
      
      
      
      
      
      
      
    case {'(0)'}
      [optional_args,i,every] = parseargs( optional_args , 'Every','$DEFS$',0 );
      if every
        if isscalar( every ), every = [ every every every]; end
        o = subsref( I , substruct('()', { ...
                                           subsref( I , substruct('.','X','()',{'every',every(1)} ) ),...
                                           subsref( I , substruct('.','Y','()',{'every',every(2)} ) ),...
                                           subsref( I , substruct('.','Z','()',{'every',every(3)} ) ),...
                                           'interp' , optional_args{:} } ) );
      else, error('only allowed ''e'' every');
      end
      

      
      
    case {'.image'}
      o = ApplyContrastFunction( I.data , I.ImageTransform );
    case {'.image(1)'}
      o = ApplyContrastFunction( I.data , s(2).subs{:} );
    case {'.image(3)' '.image(4)' '.image(_)'}
      o = ApplyContrastFunction( I.data( s(2).subs{:} ) , I.ImageTransform );



    case { '.normalize' '.normalize(1)' '.IMAGE' '.IMAGE(1)' }
      if numel(s) == 1, IM = I.ImageTransform;
      else,             IM = s(2).subs{:};
      end
      o = I;
      %o.data = ApplyContrastFunction( I.data , IM );
      o = DATA_action( o , ['@(X) ApplyContrastFunction(X,' uneval(IM) ')'] );
      o.ImageTransform = [0 0;1 1];

    case {'.transfer(1)'}
      in = s(2).subs{:};
      if ~isa(in,'I3D'), error('An I3D was expected.'); end
      
      o = remove_dereference( I );
      
      if isempty( o.data )
        o.data = NaN( [ numel( I.X ) , numel( I.Y ) , numel( I.Z ) , numel( I.T ) , 1 ] );
      end

      [a,b] = ismember( I3D_subsref(  o , substruct('.','XYZ') ) ,...
                        I3D_subsref( in , substruct('.','XYZ') ) ,...
                        'rows' );
      o.data(a) = in.data( b(~~b) );
      
      
      
      
      
    case {'.filldata(1)','.fill(1)'}
      in = s(2).subs{:};
      if ischar(in), error('char data not allowed'); end
      
      o = remove_dereference( I );
      if       ( isnumeric( in ) || islogical( in ) )  && isvector( in )

        d = numel( in );
        d = d/( numel(I.X) * numel(I.Y) * numel(I.Z) * numel(I.T) );
        if mod(d,1), error( 'number of elements has to be multiple of %d*%d*%d*%d (%d)', ...
              numel(I.X) , numel(I.Y) , numel(I.Z) , numel(I.T) , numel(I.X)*numel(I.Y)*numel(I.Z)*numel(I.T) ); end

        o.data = reshape( s(2).subs{:} , [numel(I.X) numel(I.Y) numel(I.Z) numel(I.T)  d ] );

      elseif  ( isnumeric( in ) || islogical( in ) )  && ~isvector( in )

        if size( in , 1 ) ~= numel(I.X), error( 'size on dim 1 do not coincide' ); end
        if size( in , 2 ) ~= numel(I.Y), error( 'size on dim 2 do not coincide' ); end
        if size( in , 3 ) ~= numel(I.Z), error( 'size on dim 3 do not coincide' ); end
        if size( in , 4 ) ~= numel(I.T), error( 'size on dim 4 do not coincide' ); end
        
        o.data = in;
        
      elseif isa( in , 'I3D' )

        if isempty( in.data ), error( 'to fill with an empty data, use cleanup(''data'')' ); end
        if size( in.data , 1 ) ~= numel(I.X), error( 'size on dim 1 do not coincide' ); end
        if size( in.data , 2 ) ~= numel(I.Y), error( 'size on dim 2 do not coincide' ); end
        if size( in.data , 3 ) ~= numel(I.Z), error( 'size on dim 3 do not coincide' ); end
        if size( in.data , 4 ) ~= numel(I.T), error( 'size on dim 4 do not coincide' ); end

        o.data = in.data;

      end

    case {'.filldata(2)','.fill(2)'}     % I.fill( 1:10 , 0 )   coloca 0 en el I.data(1:10)
      in    = s(2).subs{2};
      if ischar(in), error('char data not allowed'); end

      where = s(2).subs{1};
      
      if isa( in , 'I3D' )
        in = in.data;
      end

      o = remove_dereference( I );
      if isempty( I.data )
        o.data  = zeros( [ numel(I.X) numel(I.Y) numel(I.Z) numel(I.T) 1 ] , class( in ) );
      end
      o.data( where ) = in;
        
    case {'.numel'}
      o = numel( I.data );
      
      
    case {'.basis(1)','.basis(2)','.basis(3)','.basis(4)','.basis(5)','.basis(_)'}
      b_idx = s(2).subs;
      o = remove_dereference( cleanout( I ) );
      
      o.data = zeros([numel(I.X) numel(I.Y) numel(I.Z) numel(I.T) max(1,size(I.data,5)) max(1,size(I.data,6)) max(1,size(I.data,7)) max(1,size(I.data,8))]);
      
      o.data( b_idx{:} ) = 1;
      
      
      
      
      
      
      
      
      
      
%%% functions as methods!!
%     case {'.cast' '.cast(0)' '.cast(1)' '.cast(2)' '.cast(3)' '.cast(4)' '.cast(_)'}
%       if numel(s) > 1,      o = cast( I , s(2).subs{:} , optional_args{:} );
%       else                  o = cast( I , optional_args{:});
%       end
%       
%     case {'.gradient' '.gradient(0)' '.gradient(1)' '.gradient(2)' '.gradient(3)' '.gradient(4)' '.gradient(_)'}
%       if numel(s) > 1,      o = gradient( I , s(2).subs{:} , optional_args{:} );
%       else                  o = gradient( I , optional_args{:});
%       end
% 
%     case {'.imfilter' '.imfilter(0)' '.imfilter(1)' '.imfilter(2)' '.imfilter(3)' '.imfilter(4)' '.imfilter(_)'}
%       if numel(s) > 1,      o = imfilter( I , s(2).subs{:} , optional_args{:} );
%       else                  o = imfilter( I , optional_args{:});
%       end
% 
%     case {'.spatialScale' '.spatialScale(0)' '.spatialScale(1)' '.spatialScale(2)' '.spatialScale(3)' '.spatialScale(4)' '.spatialScale(_)'}
%       if numel(s) > 1,      o = spatialScale( I , s(2).subs{:} , optional_args{:} );
%       else                  o = spatialScale( I , optional_args{:});
%       end
% 
%     case {'.transform' '.transform(0)' '.transform(1)' '.transform(2)' '.transform(3)' '.transform(4)' '.transform(_)'}
%       if numel(s) > 1,      o = transform( I , s(2).subs{:} , optional_args{:} );
%       else                  o = transform( I , optional_args{:});
%       end
%       
%     case {'.reduceimage' '.reduceimage(0)' '.reduceimage(1)' '.reduceimage(2)' '.reduceimage(3)' '.reduceimage(4)' '.reduceimage(_)'}
%       if numel(s) > 1,      o = reduceimage( I , s(2).subs{:} , optional_args{:} );
%       else                  o = reduceimage( I , optional_args{:});
%       end
      
      
    otherwise
      
%       if      isequal( s(1).type , '.' ) && ismethod( I , s(1).subs ) && numel( s ) == 1
%         
%         o = feval( s(1).subs , I );
% 
%       elseif  isequal( s(1).type , '.' ) && ismethod( I , s(1).subs ) && isequal( s(2).type , '()' )
%         
%         o = feval( s(1).subs , I , s(2).subs{:} , optional_args{:} );
%         
%       else
%         o = I;
%         for ss = 1:numel(s_orig)
%           o = subsref( o , s_orig(ss) );
%         end
%         
%       end

      if  numel( s ) == 1  && strcmp( s(1).type , '.' ) && ismethod( I , s(1).subs )

        o = feval( s(1).subs , I );
        
      elseif  numel( s ) == 2  && strcmp( s(1).type , '.' ) && ismethod( I , s(1).subs ) && strcmp( s(2).type , '()' )

         o = feval( s(1).subs , I , s(2).subs{:} , optional_args{:} );
        
      else
        
        o = subsref( subsref( I , s_orig(1:end-1) ) , s_orig(end) );
        
      end
      
  end
  
  function s = complete(s)
    if numel(s) < 1 || ( ischar( s{1} ) && s{1} == ':' ), s{1} = true( [ 1 , numel(I.X) ] ); end
    if numel(s) < 2 || ( ischar( s{2} ) && s{2} == ':' ), s{2} = true( [ 1 , numel(I.Y) ] ); end
    if numel(s) < 3 || ( ischar( s{3} ) && s{3} == ':' ), s{3} = true( [ 1 , numel(I.Z) ] ); end
    if numel(s) < 4 || ( ischar( s{4} ) && s{4} == ':' ), s{4} = true( [ 1 , numel(I.T) ] ); end
    if numel(s) < 5 || ( ischar( s{5} ) && s{5} == ':' ), s{5} = true( [ 1 , size(I.data,5)  ] ); end
    
    for d = 5:ndims( I.data )
      if numel(s) < d || ( ischar( s{d} ) && s{d} == ':' ), s{d} = true( [ 1 , size( I.data , d ) ] ); end
    end
    
    for d = 1:numel( s )
      if islogical( s{d} ), continue; end
      s{d} = round( s{d} );
    end
  end

  function x= iscolon(s)
    x=0;
    if ischar(s) && strcmp( s , ':' )
      x = 1;
    end
  end


  function I = fixLABELS( I )
    maxL= double(max( I.LABELS(:) ));
    for l = (numel( I.LABELS_INFO )+1):maxL
      I= add_label( I );
    end
  end

end



%     case '.X(1)',   o= I.X( s(2).subs{:} );                   % I.X([1 2 3:2:5 end])
%     case '.DX(1)',  o= dualVector(I.X); o=o( s(2).subs{:} );        % I.DX([1 2 3:2:5 end])
%     case '.Y(1)',   o= I.Y( s(2).subs{:} );                   
%     case '.DY(1)',  o= dualVector(I.Y); o=o( s(2).subs{:} );        
%     case '.Z(1)',   o= I.Z( s(2).subs{:} );                   
%     case '.DZ(1)',  o= dualVector(I.Z); o=o( s(2).subs{:} );        
%     case '.T(1)',   o= I.T( s(2).subs{:} );                   

%     case {'.DeltaX(1)' '.DELTAX(1)' '.deltaX(1)' '.Deltax(1)' '.deltax(1)' '.DELTAx(1)'}
%       o = diff( I.X ); if isempty( o ), o = 1; end
%       o = o( s(2).subs{:} );
%     case {'.DeltaY(1)' '.DELTAY(1)' '.deltaY(1)' '.Deltay(1)' '.deltay(1)' '.DELTAy(1)'}
%       o = diff( I.Y ); if isempty( o ), o = 1; end
%       o = o( s(2).subs{:} );
%     case {'.DeltaZ(1)' '.DELTAZ(1)' '.deltaZ(1)' '.Deltaz(1)' '.deltaz(1)' '.DELTAz(1)'}
%       o = diff( I.Z ); if isempty( o ), o = 1; end
%       o = o( s(2).subs{:} );
%     case {'.DeltaT(1)' '.DELTAT(1)' '.deltat(1)' '.Deltat(1)' '.deltat(1)' '.DELTAt(1)'}
%       o = diff( I.T ); if isempty( o ), o = 1; end
%       o = o( s(2).subs{:} );








%   function [dx,dy,dz]= dualDef( x , y , z )
%     paddims = [1 2 3];
%     if size(x,1)==1 , 
%       x = cat(1,x,x); 
%       y = cat(1,y,y); 
%       z = cat(1,z,z); 
%       paddims( paddims == 1 ) = [];
%     end
%     if size(x,2)==1 , 
%       x = cat(2,x,x); 
%       y = cat(2,y,y); 
%       z = cat(2,z,z); 
%       paddims( paddims == 2 ) = [];
%     end
%     if size(x,3)==1 , 
%       x = cat(3,x,x); 
%       y = cat(3,y,y); 
%       z = cat(3,z,z); 
%       paddims( paddims == 3 ) = [];
%     end
%     
%     dx=( x( 1:end-1 , 1:end-1 , 1:end-1 ) + ...
%          x( 2:end   , 1:end-1 , 1:end-1 ) + ...
%          x( 1:end-1 , 2:end   , 1:end-1 ) + ...
%          x( 2:end   , 2:end   , 1:end-1 ) + ...
%          x( 1:end-1 , 1:end-1 , 2:end   ) + ...
%          x( 2:end   , 1:end-1 , 2:end   ) + ...
%          x( 1:end-1 , 2:end   , 2:end   ) + ...
%          x( 2:end   , 2:end   , 2:end   ) )/8;
% 
%     dy=( y( 1:end-1 , 1:end-1 , 1:end-1 ) + ...
%          y( 2:end   , 1:end-1 , 1:end-1 ) + ...
%          y( 1:end-1 , 2:end   , 1:end-1 ) + ...
%          y( 2:end   , 2:end   , 1:end-1 ) + ...
%          y( 1:end-1 , 1:end-1 , 2:end   ) + ...
%          y( 2:end   , 1:end-1 , 2:end   ) + ...
%          y( 1:end-1 , 2:end   , 2:end   ) + ...
%          y( 2:end   , 2:end   , 2:end   ) )/8;
% 
%     dz=( z( 1:end-1 , 1:end-1 , 1:end-1 ) + ...
%          z( 2:end   , 1:end-1 , 1:end-1 ) + ...
%          z( 1:end-1 , 2:end   , 1:end-1 ) + ...
%          z( 2:end   , 2:end   , 1:end-1 ) + ...
%          z( 1:end-1 , 1:end-1 , 2:end   ) + ...
%          z( 2:end   , 1:end-1 , 2:end   ) + ...
%          z( 1:end-1 , 2:end   , 2:end   ) + ...
%          z( 2:end   , 2:end   , 2:end   ) )/8;
% 
%     dx = padding(dx,paddims,[-1 1],'extend');
%     dy = padding(dy,paddims,[-1 1],'extend');
%     dz = padding(dz,paddims,[-1 1],'extend');
%     
%   end








































% 
%     case {'.deformedimage{2}(3)' '.deformedimage{2}(4)' '.deformedimage{2}(_)' '.defimage{2}(3)' '.defimage{2}(4)' '.defimage{2}(_)'}
%       t1 = s(2).subs{1}; t1 = t1(1);
%       t2 = s(2).subs{2}; t2 = t2(1);
%       s(3).subs{end+1} = 1;
%       DF = I.DeformationField{t1,t2};
%       if ~isempty( DF )
%         DF = DF(s(3).subs{1:3},1:3) + ndmat( I.X(s(3).subs{1}) , I.Y(s(3).subs{2}) , I.Z(s(3).subs{3}) , 'nocat' );
%         o = InterpPointsOn3DGrid( double( I.data(:,:,:,s(3).subs{4:end} )), I.X , I.Y , I.Z , double( DF ) );
%         o = reshape( o , size(DF(:,:,:,1)) );
%       else
%         o = I.data( s(3).subs{:} );
%       end
%       o = ApplyContrastFunction( o , I.ImageTransform );
%       
%     case {'.deformedimage{3}(3)' '.deformedimage{3}(4)' '.deformedimage{3}(_)' '.defimage{3}(3)' '.defimage{3}(4)' '.defimage{3}(_)'}
%       t1 = s(2).subs{1}; t1 = t1(1);
%       t2 = s(2).subs{2}; t2 = t2(1);
%       alpha = s(2).subs{3};
%       s(3).subs{end+1} = 1;
%       DF = I.DeformationField{t1,t2} * alpha;
%       if ~isempty( DF )
%         DF = DF(s(3).subs{1:3},1:3) + ndmat( I.X(s(3).subs{1}) , I.Y(s(3).subs{2}) , I.Z(s(3).subs{3}) , 'nocat' );
%         o = InterpPointsOn3DGrid( double( I.data(:,:,:,s(3).subs{4:end} )), I.X , I.Y , I.Z , double( DF ) );
%         o = reshape( o , size(DF(:,:,:,1)) );
%       else
%         o = I.data( s(3).subs{:} );
%       end
%       o = ApplyContrastFunction( o , I.ImageTransform );
% 
%       
%     case {'.invdeformedimage{2}(3)' '.invdeformedimage{2}(4)' '.invdeformedimage{2}(_)' '.invdefimage{2}(3)' '.invdefimage{2}(4)' '.invdefimage{2}(_)'}
%       t1 = s(2).subs{1}; t1 = t1(1);
%       t2 = s(2).subs{2}; t2 = t2(1);
%       s(3).subs{end+1} = 1;
%       DF = I.invDeformationField{t1,t2};
%       if ~isempty( DF )
%         DF = DF(s(3).subs{1:3},1:3) + ndmat( I.X(s(3).subs{1}) , I.Y(s(3).subs{2}) , I.Z(s(3).subs{3}) , 'nocat' );
%         o = InterpPointsOn3DGrid( double( I.data(:,:,:,s(3).subs{4:end} )), I.X , I.Y , I.Z , double( DF ) );
%         o = reshape( o , size(DF(:,:,:,1)) );
%       else
%         o = I.data( s(3).subs{:} );
%       end
%       o = ApplyContrastFunction( o , I.ImageTransform );
%       
%     case {'.invdeformedimage{3}(3)' '.invdeformedimage{3}(4)' '.invdeformedimage{3}(_)' '.invdefimage{3}(3)' '.invdefimage{3}(4)' '.invdefimage{3}(_)'}
%       t1 = s(2).subs{1}; t1 = t1(1);
%       t2 = s(2).subs{2}; t2 = t2(1);
%       alpha = s(2).subs{3};
%       s(3).subs{end+1} = 1;
%       DF = I.invDeformationField{t1,t2} * alpha;
%       if ~isempty( DF )
%         DF = DF(s(3).subs{1:3},1:3) + ndmat( I.X(s(3).subs{1}) , I.Y(s(3).subs{2}) , I.Z(s(3).subs{3}) , 'nocat' );
%         o = InterpPointsOn3DGrid( double( I.data(:,:,:,s(3).subs{4:end} )), I.X , I.Y , I.Z , double( DF ) );
%         o = reshape( o , size(DF(:,:,:,1)) );
%       else
%         o = I.data( s(3).subs{:} );
%       end
%       o = ApplyContrastFunction( o , I.ImageTransform );
% 
%     case {'.DeformationField{2}'}
%       try,     o = I.DeformationField{ s(2).subs{:} };
%       catch,   o = [];      end
%     case {'.DeformationField{2}(1)' '.DeformationField{2}(3)' '.DeformationField{2}(4)'}
%       try,     o = I.DeformationField{ s(2).subs{:} }( s(3).subs{:} );
%       catch,   o = [];      end
% 
%     case {'.invDeformationField{2}'}
%       try,     o = I.invDeformationField{ s(2).subs{:} };
%       catch,   o = [];      end
%     case {'.invDeformationField{2}(1)' '.invDeformationField{2}(3)' '.invDeformationField{2}(4)'}
%       try,     o = I.invDeformationField{ s(2).subs{:} }( s(3).subs{:} );
%       catch,   o = [];      end

%     case '(G1)'
%       if size(s(1).subs{1},2) ~= 3, error('Invalid Access at %s you need 3 columns.' , S ); end
%       xyz = s(1).subs{:};
%       [xs,ys,zs] = ndgrid( I.X , I.Y , I.Z );
% 
%       data= double(I.data);
%       if size( xs , 3 ) == 1, xs= cat( 3,xs,xs,xs ); end
%       if size( ys , 3 ) == 1, ys= cat( 3,ys,ys,ys ); end
%       if size( zs , 3 ) == 1, zs= cat( 3,zs-1,zs,zs+1 ); end
%       if size(data, 3 ) == 1, data= cat( 3,data,data,data ); end
%       sz= size(data); sz= sz(4:end);
%       for d=1:prod(sz)
%         o(:,d) = interp3(ys,xs,zs,data(:,:,:,d),xyz(:,2),xyz(:,1),xyz(:,3),I.SpatialInterpolation);
%       end
