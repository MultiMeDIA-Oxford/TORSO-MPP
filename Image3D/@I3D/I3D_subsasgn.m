function I = I3D_subsasgn(I,s,in)

  S= [];
  for ss=1:numel(s)
    if numel( s(ss).subs ) == 0, S = '0'; end
    stype = s(ss).type;
    switch stype
      case '.'
        name = s(ss).subs;
        S = [S '.' name ];
      case {'()','{}'}
        S = [ S stype ];
        switch numel( s(ss).subs );
          case 0,    S= [S(1:end-1) '0' S(end)];
          case 1,    S= [S(1:end-1) '1' S(end)];
          case 2,    S= [S(1:end-1) '2' S(end)];
          case 3,    S= [S(1:end-1) '3' S(end)];
          case 4,    S= [S(1:end-1) '4' S(end)];
          otherwise, S= [S(1:end-1) '_' S(end)];
        end
    end
  end

  if strncmp(S,'.CONTOUR.',9)
    contourcase= S(10:end);
    S = '.CONTOUR.';
  end
  if strncmp(S,'.INFO.',6)
    infocase= S(7:end);
    S = '.INFO.';
  end
  if strncmp(S,'.OTHERS.',8)
    otherscase= S(9:end);
    S = '.OTHERS.';
  end
  if strncmp(S,'.FIELDS.',8)
    fieldscase= S(9:end);
    S = '.FIELDS.';
  end
  if strncmp(S,'.GRID_PROPERTIES.',14)
    prescase= S(15:end);
    S = '.GRID_PROPERTIES.';
  end
  

  
  switch S
      
%       case  '.GPUvars.POINTS_INTERPOLATION_KERNEL.GridSize'
%           I.GPUvars.POINTS_INTERPOLATION_KERNEL.GridSize = in;

%       case  '.GPUvars.POINTS_INTERPOLATION_KERNEL.ThreadBlockSize'
%           I.GPUvars.POINTS_INTERPOLATION_KERNEL.ThreadBlockSize = in;

%     case  '.GPUvars.POINTS_INTERPOLATION_KERNEL.nReg'
%       I.GPUvars.POINTS_INTERPOLATION_KERNEL.nReg = in;

    case {'.CONTOUR.'}
      if isempty( in )
        I.CONTOURS = rmfield( I.CONTOURS , contourcase );
      else
        C = in;
        if ~isfloat( C ) || ~ismatrix( C ) || size( C ,2) ~= 3
          error('3D coordinates (as rows) were expected.');
        end
        C = double( C );
        C = transform( C , minv( I.SpatialTransform ) );
        if numel( I.Z ) == 1 && I.Z == 0
          dz = max( abs(C(:,3)) );
          if dz > 1e-6
            warning('Contour points don''t lie on the image plane (%g).', dz );
          else
            C(:,3) = 0;
          end
        end
        I.CONTOURS.(contourcase) = C;
      end
      
    case {'.CONTOUR(1)'}
      if numel( s(2).subs ) > 1, error('a single number is expected.'); end
      if numel( s(2).subs{1} ) > 1, error('a single number is expected.'); end
      if numel( s(2).subs{1} ) <= 0, error('a natural number is expected.'); end
      if mod( s(2).subs{1} ,1), error('an integer number is expected.'); end
      contourcase = sprintf('C%06d',s(2).subs{:});
      
      if isempty( in )
        I.CONTOURS = rmfield( I.CONTOURS , contourcase );
      else
        C = in;
        if ~isfloat( C ) || ~ismatrix( C ) || size( C ,2) ~= 3
          error('3D coordinates (as rows) were expected.');
        end
        C = double( C );
        C = transform( C , minv( I.SpatialTransform ) );
        if numel( I.Z ) == 1 && I.Z == 0
          dz = max( abs(C(:,3)) );
          if dz > 1e-6
            warning('Contour points don''t lie on the image plane (%g).', dz );
          else
            C(:,3) = 0;
          end
        end
        I.CONTOURS.(contourcase) = C;
      end
          
    case {'.MESH{1}'}
      if numel( s(2).subs{1} ) > 1, error('on mesh at each time'); end
      I.MESHES{ s(2).subs{:} } = in;

    case {'.MESH'}
      if isempty( in )
        I.MESHES = {};
      else
        if numel(I.MESHES) > 1, warning('MESHES will be replaced with the input'); end
        I.MESHES = { in };
      end

    case {'.MESHES'}
      if isempty( in )
        I.MESHES = {};
      else
        error('use MESHES{i}');
      end

    case {'.LANDMARKS'}
      if isempty( in )
        I.LANDMARKS = [];
        return;
      end
      switch class(in)
        case {'single','double'}
          if ndims(in) ~= 2  ||  size(in,2) ~= 3
            error('landmarks has to be Nx3 float data');
          end
          if isreal( in )
            %%si es real lo inserta como coordenadas globales
            %%es decir, el usuario los especifica en coordenadas globales
            %%y se guardan en coordenadas relativas
            I.LANDMARKS = transform( double( in ) , inv( I.SpatialTransform ) );   
          else
            %%si es imag lo inserta como vienen
            I.LANDMARKS = double( imag( in ));
            %%al pedir I.LANDMARKS con subsref, los transforma antes de
            %%devolverlos
          end
      end
    
    case {'.LANDMARKSlocal'}
      switch class(in)
        case {'single','double'}
          if ndims(in) ~= 2  ||  size(in,2) ~= 3
            error('landmarks has to be Nx3 float data');
          end
          I.LANDMARKS = double( in );
      end
      
    
    case {'.SpatialInterpolation' '.spatialinterpolation' }
      switch lower(in)
        case {'nearest' 'nea' 'n'}, I.SpatialInterpolation = 'nearest';
        case {'linear'  'lin' 'l'}, I.SpatialInterpolation = 'linear';
        case {'cubic'   'cub' 'c'}, I.SpatialInterpolation = 'cubic';
        case {'sinc'          's'}, I.SpatialInterpolation = 'sinc';
        otherwise
          error('Only allowed , ''nearest'',''linear'',''cubic'',''sinc''');
      end
      if I.isGPU, I = toGPU( I ); end
        
    case {'.TemporalInterpolation' }
      switch lower(in)
        case {'constant' 'con' 'c' }, I.TemporalInterpolation = 'constant';
        case {'linear'   'lin' 'l' }, I.TemporalInterpolation = 'linear';
        case {'cubic'    'cub'     }, I.TemporalInterpolation = 'cubic';
        otherwise
          error('Only allowed , ''constant'' , ''linear'' , ''cubic''');
      end

    case {'.DiscreteSpatialStencil' }
      switch lower(in)
        case {'subdifferential' 'sub' },        I.DiscreteSpatialStencil = 'subdifferential';
        case {'quadratic' 'qu' 'q' },           I.DiscreteSpatialStencil = 'quadratic';
        case {'centered' 'center' 'cen' 'c' },  I.DiscreteSpatialStencil = 'centered';
        case {'forward' 'f' },                  I.DiscreteSpatialStencil = 'forward';
        case {'backward' 'b' },                 I.DiscreteSpatialStencil = 'backward';
        otherwise
          error('Only allowed , ''centered'' , ''forward'' , ''backward'' , ''subdifferential'' , ''quadratic'' ');
      end

    case {'.DiscreteTemporalStencil' }
      switch lower(in)
        case {'subdifferential' 'sub' },        I.DiscreteTemporalStencil = 'subdifferential';
        case {'quadratic' 'qu' 'q' },           I.DiscreteSpatialStencil = 'quadratic';
        case {'centered' 'center' 'cen' 'c' },  I.DiscreteTemporalStencil = 'centered';
        case {'forward' 'f' },                  I.DiscreteTemporalStencil = 'forward';
        case {'backward' 'b' },                 I.DiscreteTemporalStencil = 'backward';
        otherwise
          error('Only allowed , ''centered'' , ''forward'' , ''backward'' , ''subdifferential'' , ''quadratic'' ');
      end

    case {'.BoundaryMode' '.boundarymode' }
      switch lower(in)
        case {'extrapolation_value' 'value' 'v'}, I.BoundaryMode = 'value';
        case {'symmetric'           'sym'   's'}, I.BoundaryMode = 'symmetric';
        case {'closest'                        }, I.BoundaryMode = 'closest';
        case {'circular'     'circ' 'cir'   'c' ...
              'periodic'            'per'   'p'}, I.BoundaryMode = 'circular';
        case {'decay_to_zero' 'tozero' 'zero' ...
                               'decay' 'd' 'z' }, I.BoundaryMode = 'decay';
        otherwise
          error('Only allowed , ''value'',''symmetric'',''circular'',''decay'',''closest''');
      end
      if I.isGPU, I = toGPU( I ); end

    case {'.BoundarySize' '.boundarysize' }
      %if isscalar(in), in = [0 0 0 0 0 0]+in; end
      %if numel(in) ~= 6, error('1 or 6 numbers expected'); end
      %I.BoundarySize = double( in(:).' );
      
      if ~isempty(in) && isscalar(in) && in >= 0
        I.BoundarySize = in;
      else
        error('a positive scalar expected.');
      end
      
      if I.isGPU
        BS = double( [0;0;0;0;0;0] + I.BoundarySize(:) ).';
        I.GPUvars.POINTS_fINTERPOLATION_KERNEL.setConstantMemory( 'BoundarySize' , single(BS) );
        I.GPUvars.POINTS_dINTERPOLATION_KERNEL.setConstantMemory( 'BoundarySize' , double(BS) );
        I.GPUvars.GRID_fINTERPOLATION_KERNEL.setConstantMemory( 'BoundarySize' , single(BS) );
        I.GPUvars.GRID_dINTERPOLATION_KERNEL.setConstantMemory( 'BoundarySize' , double(BS) );
      end

    case {'.OutsideValue' '.outsidevalue' }
      if ~isscalar(in)
        error('an scalar expected.');
      end
      I.OutsideValue = in;

      if I.isGPU
        I.GPUvars.POINTS_fINTERPOLATION_KERNEL.setConstantMemory( 'fOutsideValue' , single(I.OutsideValue) );
        I.GPUvars.POINTS_dINTERPOLATION_KERNEL.setConstantMemory( 'dOutsideValue' , double(I.OutsideValue) );
        I.GPUvars.GRID_fINTERPOLATION_KERNEL.setConstantMemory( 'fOutsideValue' , single(I.OutsideValue) );
        I.GPUvars.GRID_dINTERPOLATION_KERNEL.setConstantMemory( 'dOutsideValue' , double(I.OutsideValue) );
      end

    
    case {'.SpatialTransform' '.spatialtransform' }
      if ~isequal( size(in) , [4 4] )
         error('I3D:InvalidSpatialTransformMatrix','The SpatialTransform has to be an 4x4 matrix');
      end
      if ~isequal( in(4,:) , [0 0 0 1] )
         error('I3D:SpatialTransform','The SpatialTransform is not an homogeneous affine transform.');
      end
      for m = 1:numel(I.MESHES)
        M = I.MESHES{m};
        if isstruct( M ) && isfield( M , 'xyz' )
          M.xyz = transform( M.xyz , in / I.SpatialTransform );
        end
        I.MESHES{m} = M;
      end
      
      
      I.SpatialTransform = in;
      if I.isGPU
        %iOM = ( I.SpatialTransform \ eye(4) );
        iOM = inv4x4(I.SpatialTransform);
        I.GPUvars.POINTS_fINTERPOLATION_KERNEL.setConstantMemory( 'fiOM' , single(iOM) );
        I.GPUvars.POINTS_dINTERPOLATION_KERNEL.setConstantMemory( 'diOM' , double(iOM) );
        I.GPUvars.GRID_fINTERPOLATION_KERNEL.setConstantMemory( 'fiOM' , single(iOM) );
        I.GPUvars.GRID_dINTERPOLATION_KERNEL.setConstantMemory( 'diOM' , double(iOM) );
        I.GPUvars.fSpatialTransform = single( I.SpatialTransform );
        I.GPUvars.dSpatialTransform = double( I.SpatialTransform );
      end
    
      
    case { '.SpatialTransform(1)' '.spatialtransform(1)' '.SpatialTransform(2)' '.spatialtransform(2)'}
      M = I.SpatialTransform;
      M( s(2).subs{:} ) = in;
      if ~isequal( size(M) , [4 4] )
         error('I3D:InvalidSpatialTransformMatrix','The SpatialTransform has to be an 4x4 matrix');
      end
      if ~isequal( M(4,:) , [0 0 0 1] )
         error('I3D:SpatialTransform','The SpatialTransform is not an homogeneous affine transform.');
      end  
      I.SpatialTransform = M;
      if I.isGPU
        %iOM = ( I.SpatialTransform \ eye(4) );
        iOM = inv4x4(I.SpatialTransform);
        I.GPUvars.POINTS_fINTERPOLATION_KERNEL.setConstantMemory( 'fiOM' , single(iOM) );
        I.GPUvars.POINTS_dINTERPOLATION_KERNEL.setConstantMemory( 'diOM' , double(iOM) );
        I.GPUvars.GRID_fINTERPOLATION_KERNEL.setConstantMemory( 'fiOM' , single(iOM) );
        I.GPUvars.GRID_dINTERPOLATION_KERNEL.setConstantMemory( 'diOM' , double(iOM) );
        I.GPUvars.fSpatialTransform = single( I.SpatialTransform );
        I.GPUvars.dSpatialTransform = double( I.SpatialTransform );
      end

      
    case {'.ImageTransform' '.imagetransform' }
      if  isempty(in) || ( numel(in)==1 && isnan(in) )
        in = [ double(min(I.data(:))) 0 ; double(max(I.data(:))) 1];
      end
      if isscalar( in ) && in >= 0 && in < 50
        I.ImageTransform   = [ double( prctile(I.data(:),in) ) , 0 ; double( prctile(I.data(:),100-in) ) , 1 ];
      elseif ~any(isnan(in(:))) && ~any(isinf(in(:))) && size(in,2) == 2 && size(in,1) > 1 && ndims(in) == 2
        I.ImageTransform   = double( in );
      else
        error('You have to enter an nx2 (n>=2) matrix or an scalar.'); 
      end
      if ~issorted( I.ImageTransform(:,1) )
        error('I3D:ImageTransform','The ImageTransform image values has to be increasing.'); 
      end
      

    case {'.ImageTransform(1)' '.imagetransform(1)' '.ImageTransform(2)' '.imagetransform(2)'}
      M = I.ImageTransform;
      M( s(2).subs{:} ) = in;
      if ndims(M) ~= 2 || size(M,2) ~= 2 || size(M,1) < 2 || any(isnan(M(:)))
        error('ImageTransform has to be an nx2 (n>=2) matrix.'); 
      end 
      I.ImageTransform   = double( M );
    
    
    case {'.INFO' }    ,      I.INFO = in;

    case {'.INFO.' }
      try
        I.INFO = subsasgn( I.INFO , s(2:end) , in );
      catch
        I.INFO.(infocase) = in;
      end
      
    case {'.OTHERS' }  ,  
      if ~isstruct(in), error('Solamente permite estructuras.'); end
      I.OTHERS = in;
      if ~numel(fieldnames(I.OTHERS))
        I.OTHERS = [];
      end
    case {'.OTHERS.' }
      try
        I.OTHERS = subsasgn( I.OTHERS , s(2:end) , in );
      catch
        I.OTHERS.(otherscase) = in;
      end

    case {'.GRID_PROPERTIES' }  ,      I.GRID_PROPERTIES = in;
    case {'.GRID_PROPERTIES.' }
      try
        I.GRID_PROPERTIES = subsasgn( I.GRID_PROPERTIES , s(2:end) , in );
      catch
        I.GRID_PROPERTIES.(prescase) = in;
      end


    case {'.FIELDS'  }
      if isempty( in )
        I.FIELDS = [];
      else
        error('call .FIELDS.f_name');
      end
      
      
    case {'.FIELD(1)'}
      if numel( s(2).subs ) > 1, error('a single number is expected.'); end
      if numel( s(2).subs{1} ) > 1, error('a single number is expected.'); end
      if numel( s(2).subs{1} ) <= 0, error('a natural number is expected.'); end
      if mod( s(2).subs{1} ,1), error('an integer number is expected.'); end
      fieldscase = sprintf('F%06d',s(2).subs{:});
      
      if isempty( in )

        if isfield( I.FIELDS , fieldscase )
          I.FIELDS = rmfield( I.FIELDS , fieldscase );
          if isempty( fieldnames( I.FIELDS ) )
            I.FIELDS = [];
          end
        end

      elseif isnumeric(in) || islogical(in)

        if   size(in,1) ~= numel(I.X) || ...
             size(in,2) ~= numel(I.Y) || ...
             size(in,3) ~= numel(I.Z) 
          error('I3D:IncorrectFieldSize','The Field have an invalid size.');
        end
        I.FIELDS.(fieldscase) = in;

      elseif isa(in,'I3D')

        if isempty( in.data ), error('The input has empty data.'); end
        
        %in = cleanout( in , 'LABELS','INFO','OTHERS','FIELDS','LANDMARKS','MESHES', , 'warnings' );
        
        I.FIELDS.(fieldscase) = in;
          
      else

        error('Invalid assigment. Only  numeric  arrays and  I3D objects.');

      end
      
      
    case {'.FIELDS.' }

      if numel(s) > 2

        I.FIELDS.(s(2).subs) = subsasgn( I.FIELDS.(s(2).subs) , s(3:end) , in );
        
        if size( I.FIELDS.(s(2).subs) , 1 ) ~= numel(I.X) || ...
           size( I.FIELDS.(s(2).subs) , 2 ) ~= numel(I.Y) || ...
           size( I.FIELDS.(s(2).subs) , 3 ) ~= numel(I.Z) 
          error('I3D:IncorrectFieldSize','The Field have an invalid size.');
        end
        return;

      end
      
      if isempty( in )

        if isfield( I.FIELDS , fieldscase )
          I.FIELDS = rmfield( I.FIELDS , fieldscase );
          if isempty( fieldnames( I.FIELDS ) )
            I.FIELDS = [];
          end
        end

      elseif isnumeric(in) || islogical(in)

        if   size(in,1) ~= numel(I.X) || ...
             size(in,2) ~= numel(I.Y) || ...
             size(in,3) ~= numel(I.Z) 
          error('I3D:IncorrectFieldSize','The Field have an invalid size.');
        end
        I.FIELDS.(fieldscase) = in;

      elseif isa(in,'I3D')

        if isempty( in.data ), error('The input has empty data.'); end
        
        %in = cleanout( in , 'LABELS','INFO','OTHERS','FIELDS','LANDMARKS','MESHES', , 'warnings' );
        
        I.FIELDS.(fieldscase) = in;
          
      else

        error('Invalid assigment. Only  numeric  arrays and  I3D objects.');

      end
    
    
    case '.X'
      if isempty(in), error('Incorrect, you can not remove all the coordinates.'); end
      if numel(I.X) ~= numel(in), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if size(I.data,1) ~= numel(in), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if ~issorted(in), error('I3D:NotSortedCoordinates','X coordinates are not in increasing order.'); end
      I.X = double( in(:) ).';
      I.GRID_PROPERTIES = [];
      if I.isGPU, I = toGPU( I ); end
    case '.Y'
      if isempty(in), error('Incorrect, you can not remove all the coordinates.'); end
      if numel(I.Y) ~= numel(in), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if size(I.data,2) ~= numel(in), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if ~issorted(in), error('I3D:NotSortedCoordinates','Y coordinates are not in increasing order.'); end
      I.Y = double( in(:) ).'; 
      I.GRID_PROPERTIES = [];
      if I.isGPU, I = toGPU( I ); end
    case '.Z'
      if isempty(in), error('Incorrect, you can not remove all the coordinates.'); end
      if numel(I.Z) ~= numel(in), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if size(I.data,3) ~= numel(in), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if ~issorted(in), error('I3D:NotSortedCoordinates','Z coordinates are not in increasing order.'); end
      I.Z = double( in(:) ).'; 
      I.GRID_PROPERTIES = [];
      if I.isGPU, I = toGPU( I ); end
    case '.T'
      if isempty(in), error('Incorrect, you can not remove all the coordinates.'); end
      if numel(I.T) ~= numel(in), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if size(I.data,4) ~= numel(in), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if ~issorted(in), error('I3D:NotSortedCoordinates','T coordinates are not in increasing order.'); end
      I.T = double( in(:) ).'; 
      if I.isGPU, I = toGPU( I ); end

      
      
    case '.X(1)'
      x = I.X;
      x( s(2).subs{:} ) = in;
      x = double( x(:) )';
      if isempty(x), error('Incorrect, you can not remove all the coordinates.'); end
      if numel(I.X) ~= numel(x), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if size(I.data,1) ~= numel(x), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if ~issorted(x), error('I3D:NotSortedCoordinates','X coordinates are not in increasing order.'); end
      I.X = x;
      I.GRID_PROPERTIES = [];
      if I.isGPU, I = toGPU( I ); end
    case '.Y(1)'
      x = I.Y;
      x( s(2).subs{:} ) = in;
      x = double( x(:) )';
      if isempty(x), error('Incorrect, you can not remove all the coordinates.'); end
      if numel(I.Y) ~= numel(x), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if size(I.data,2) ~= numel(x), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if ~issorted(x), error('I3D:NotSortedCoordinates','Y coordinates are not in increasing order.'); end
      I.Y = x;
      I.GRID_PROPERTIES = [];
      if I.isGPU, I = toGPU( I ); end
    case '.Z(1)'
      x = I.Z;
      x( s(2).subs{:} ) = in;
      x = double( x(:) )';
      if isempty(x), error('Incorrect, you can not remove all the coordinates.'); end
      if numel(I.Z) ~= numel(x), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if size(I.data,3) ~= numel(x), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if ~issorted(x), error('I3D:NotSortedCoordinates','Z coordinates are not in increasing order.'); end
      I.Z = x;
      I.GRID_PROPERTIES = [];
      if I.isGPU, I = toGPU( I ); end
    case '.T(1)'
      x = I.T;
      x( s(2).subs{:} ) = in;
      x = double( x(:) )';
      if isempty(x), error('Incorrect, you can not remove all the coordinates.'); end
      if numel(I.T) ~= numel(x), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if size(I.data,4) ~= numel(x), error('I3D:IncorrectSize','Incorrect, you can not change the size.'); end
      if ~issorted(x), error('I3D:NotSortedCoordinates','T coordinates are not in increasing order.'); end
      I.T = x;
      if I.isGPU, I = toGPU( I ); end
      
    
    case {'.data' }
      if ischar(in), error('char data not allowed'); end
      
      if isa( in , 'I3D' )
        in = in.data;
      end
      
      if ~I.isGPU

        if isempty(in)
          I.POINTER = {''};
          I.data = [];
        elseif isempty( I.data )   &&  isscalar( in )
          I.POINTER = {''};
          I = DATA_action( I , ['@(X) zeros(' uneval([numel(I.X),numel(I.Y),numel(I.Z),numel(I.T),1]) ',' uneval(class(in)) , ')+' uneval(in)] );
        elseif iscell( in )

          error('no!!! to include dereferences use ... I.set(''POINTER'',{...})');
          I.data = in;

        else
          if size(in,1) ~= numel(I.X), error('Invalid data size.'); end
          if size(in,2) ~= numel(I.Y), error('Invalid data size.'); end
          if size(in,3) ~= numel(I.Z), error('Invalid data size.'); end
          if size(in,4) ~= numel(I.T), error('Invalid data size.'); end

          I = remove_dereference( I );
          I.data = in;
        end

      else %GPU case
        
        sz = size(in); sz(end+1:10) = 1;
        
        if sz(1) ~= numel(I.X), error('Invalid data size.'); end
        if sz(2) ~= numel(I.Y), error('Invalid data size.'); end
        if sz(3) ~= numel(I.Z), error('Invalid data size.'); end
        if sz(4) ~= numel(I.T), error('Invalid data size.'); end

        if prod( sz(4:end) ) ~= 1, error('en GPU solamente imagenes scalar'); end

        I = remove_dereference( I );
        
        if isa( in , 'parallel.gpu.GPUArray' ) && strcmp( classUnderlying(in) , 'single' )
          I.data = in;
        elseif isa( in , 'single' )
          try
            I.data = gpuArray( in );
          catch
            error('no se pudo asignar data');
          end
        else
          error('como I3D esta en GPU, solamente se permiten singles.');
        end
        
      end

    case {'.data(1)' '.data(3)' '.data(4)' '.data(_)'}
      if ischar(in), error('char data not allowed'); end
      if isempty(in), error('Empty data not allowed'); end

      if numel(s(2).subs) == 1 && ischar( s(2).subs{1} ) && strcmp(s(2).subs{1},':') && isscalar(in)
        
        I.POINTER = {''};
        I = DATA_action( I , ['@(X) zeros(' uneval([numel(I.X),numel(I.Y),numel(I.Z),numel(I.T),size(I.data,5),size(I.data,6),size(I.data,7),size(I.data,8)]) ',' uneval(class(in)) , ')+' uneval(in)] );
        
      else
        
        I = remove_dereference( I );

        if isempty( I.data ) || iscell( I.data )
          if islogical( in )
            I.data = false( [numel(I.X) numel(I.Y) numel(I.Z) numel(I.T) 1] );
          else
            I.data = zeros( [numel(I.X) numel(I.Y) numel(I.Z) numel(I.T) 1] , class(in) );
          end
        end

        I.data( s(2).subs{:} ) = in;

      end
      
      
      if size(I.data,1) ~= numel(I.X), error('I3D:IncorrectSize','discrepancy size in X!!!'); end
      if size(I.data,2) ~= numel(I.Y), error('I3D:IncorrectSize','discrepancy size in Y!!!'); end
      if size(I.data,3) ~= numel(I.Z), error('I3D:IncorrectSize','discrepancy size in Z!!!'); end
      if size(I.data,4) ~= numel(I.T), error('I3D:IncorrectSize','discrepancy size in T!!!'); end
      
      if I.isGPU
        I = toGPU( I ); 
      end
      
    
    case {'.LABELS' }
      if isempty(in)
        I.LABELS_INFO = struct('description',{},'alpha',{},'color',{},'state',{});
        I.LABELS      = uint16([]);
      elseif isnumeric( in ) || islogical( in )
        I.LABELS = uint16( in );
        if size(I.LABELS,1) ~= numel(I.X), error('I3D:LabelsIncorrectSize','discrepancy size in X!!!'); end
        if size(I.LABELS,2) ~= numel(I.Y), error('I3D:LabelsIncorrectSize','discrepancy size in Y!!!'); end
        if size(I.LABELS,3) ~= numel(I.Z), error('I3D:LabelsIncorrectSize','discrepancy size in Z!!!'); end
        if size(I.LABELS,4) ~= numel(I.T), error('I3D:LabelsIncorrectSize','discrepancy size in T!!!'); end
        if size(I.LABELS,5) ~= 1         , error('I3D:LabelsIncorrectSize','only scalar LABELS allowed!!!'); end
        I= fixLABELS(I);
      else
        error( 'no se que asginar');
      end
      
    case {'.LABELS(1)' '.LABELS(3)' '.LABELS(4)' }
      if isempty(in), in = uint16(0); end
      
      if isempty(I.LABELS)
        I.LABELS = zeros( [numel(I.X) numel(I.Y) numel(I.Z) ] , 'uint16' );
      end
      
      I.LABELS( s(2).subs{:} ) = uint16( in );
      if size(I.LABELS,1) ~= numel(I.X), error('I3D:LabelsIncorrectSize','discrepancy size in X!!!'); end
      if size(I.LABELS,2) ~= numel(I.Y), error('I3D:LabelsIncorrectSize','discrepancy size in Y!!!'); end
      if size(I.LABELS,3) ~= numel(I.Z), error('I3D:LabelsIncorrectSize','discrepancy size in Z!!!'); end
      if size(I.LABELS,4) ~= numel(I.T), error('I3D:LabelsIncorrectSize','discrepancy size in T!!!'); end
      if size(I.LABELS,5) ~= 1         , error('I3D:LabelsIncorrectSize','only scalar LABELS allowed!!!'); end
      I= fixLABELS(I);


    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    case '{1}.description'
      if ~ischar(in), error('description has to be an string.'); end
      I.LABELS_INFO(s(1).subs{:}).description = in;
    case '{1}.color'
      if ischar(in), in= colorname2rgb(in); end
      if ~all(size(in)==[1 3]), error('color has to be a 1x3 numeric value or a valid colorname'); end
      I.LABELS_INFO(s(1).subs{:}).color = in;


    case '{1}.state'
      if ~(in==1 || in==0), error('state have to be 0 or 1.'); end
      I.LABELS_INFO(s(1).subs{:}).state =in;
    case '{1}.alpha'
      if ~(isscalar(in) && in>=0 && in<=1), error('alpha has to be a scalar in [0,1].'); end
      I.LABELS_INFO(s(1).subs{:}).alpha =in;

    case {'.LABELS_INFO'}
      I.LABELS_INFO = in;
      I= fixLABELS(I);


      
    otherwise
      fprintf('nothing to do calling : %s\n' , S );
      error('Incorrect subsasgn in I3D');

  end
  

  function I = fixLABELS( I )
    maxL= double(max( I.LABELS(:) ));
    for l = (numel( I.LABELS_INFO )+1):maxL
      I= add_label( I );
    end
  end
  
end



  
  
  
%   switch s(1).type
%     case '.'
%       fieldname = s(1).subs;
%       switch fieldname
%         case 'LABELS'  
%           i = ':'; j = ':'; k = ':'; t = ':'; done= 0;
%           if      numel(s) == 1
%             
%           elseif strcmp(s(2).type,'{}') && numel(s(2).subs)==1
%             xyz = s(2).subs{1};
%             i= val2ind( I.X , xyz(:,1) );
%             j= val2ind( I.Y , xyz(:,2) );
%             k= val2ind( I.Z , xyz(:,3) );
%           elseif  strcmp(s(2).type,'{}') && numel(s(2).subs)==2
%             t = s(2).subs{2};
%             xyz = s(2).subs{1};
%             i= val2ind( I.X , xyz(:,1) );
%             j= val2ind( I.Y , xyz(:,2) );
%             k= val2ind( I.Z , xyz(:,3) );
%           elseif  strcmp(s(2).type,'()') && numel(s(2).subs)==1 && ~isa( s(2).subs , 'logical' )
%             mask= s(2).subs;
%             mask= mask{1};
%             L= I.LABELS;
%             L(mask) = in;
%             I.LABELS = L;
%             done= 1;
%           elseif  strcmp(s(2).type,'()') && numel(s(2).subs)==1 && isa( s(2).subs , 'logical' )
%             xyz = s(2).subs{1};
%             xyz= transform( xyz, inv(I.SpatialTransform),'rows');
%             i= val2ind( I.X , xyz(:,1) );
%             j= val2ind( I.Y , xyz(:,2) );
%             k= val2ind( I.Z , xyz(:,3) );
%           elseif  strcmp(s(2).type,'()') && numel(s(2).subs)==2
%             t = s(2).subs{2};
%             xyz = s(2).subs{1};
%             xyz= transform( xyz, inv(I.SpatialTransform),'rows');
%             i= val2ind( I.X , xyz(:,1) );
%             j= val2ind( I.Y , xyz(:,2) );
%             k= val2ind( I.Z , xyz(:,3) );
%           elseif  strcmp(s(2).type,'()') && numel(s(2).subs)==3
%             i = s(2).subs{1};
%             j = s(2).subs{2};
%             k = s(2).subs{3};
%           elseif  strcmp(s(2).type,'()') && numel(s(2).subs)==4
%             i = s(2).subs{1};
%             j = s(2).subs{2};
%             k = s(2).subs{3};
%             t = s(2).subs{3};
%           else
%             error('Invalid Asign (at 3)');
%           end
%           
%           if isempty( in )
%             I.LABELS =[];
%           else
%             in = uint16(in);
%             maxin= max( in(:) );
%             for l= numel( I.LABELS_INFO )+1:maxin
%               I= add_label( I );
%             end
%             if ~done
%               I.LABELS(i(:),j(:),k(:),t(:)) =in;
%             end
%           end
%       end      
