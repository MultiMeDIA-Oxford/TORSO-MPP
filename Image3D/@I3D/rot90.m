function [I,bestENERGY] = rot90( I , varargin )

  if isa( varargin{1} ,'function_handle' )
    E = varargin{1};
    bestROT = ''; bestENERGY = E( I );
    rots = {'i';'j';'k';'ii';'ij';'ik';'ji';'jj';'kj';'kk';'iii';'iij';'iik';'iji';'ijj';'ikk';'jii';'jjj';'kkk';'iiij';'iiji';'ijii';'ijjj'};
    for r = 1:numel( rots )
      Ir = rot90( I , rots{r} );
      ENERGY = E( Ir );
      if ENERGY < bestENERGY
        bestROT = rots{r}; bestENERGY = ENERGY;
      end
    end
    I = bestROT;
    return;
  end

  if isa( varargin{1} , 'I3D' )
    T = varargin{1}; varargin(1) = [];

    I = cleanout( I );
    
    I.data = I.data(:,:,:,1);
    T.data = T.data(:,:,:,1);
    
    LI = min( [ I.X(end)-I.X(1) , I.Y(end)-I.Y(1) , I.Z(end)-I.Z(1) ] );
    LT = min( [ T.X(end)-T.X(1) , T.Y(end)-T.Y(1) , T.Z(end)-T.Z(1) ] );
    
    
    if isempty( varargin )
      N = 50;
    else
      N = varargin{1}; varargin(1) = [];
    end
    
    L = min( LI , LT )/N;
    
    nG = ( ( 1:N ) - 1 )*L;
    nG = nG - mean( nG([1 end]) );
    
    cI = [ mean( I.X([1 end]) ) , mean( I.Y([1 end]) ) , mean( I.Z([1 end]) ) ];
    I = resample( I , { nG + cI(1) , nG + cI(2) , nG + cI(3) } );
    I.data = double( I.data );

    cT = [ mean( T.X([1 end]) ) , mean( T.Y([1 end]) ) , mean( T.Z([1 end]) ) ];
    T = resample( T , { nG + cT(1) , nG + cT(2) , nG + cT(3) } );
    T.data = double( T.data );
    
    
    E= @(A,B) -abs( sum( nonans( A.data(:) .* B.data(:) ) ) );
    %E= @(A,B) sum( nonans( A.data(:)  - B.data(:) ).^2 );
    
    bestENERGY = E( T , I );
    bestROT    = '';

    rots = {'i';'j';'k';'ii';'ij';'ik';'ji';'jj';'kj';'kk';'iii';'iij';'iik';'iji';'ijj';'ikk';'jii';'jjj';'kkk';'iiij';'iiji';'ijii';'ijjj'};
    for r = 1:numel( rots )
      Ir = rot90( I , rots{r} );
      
      ENERGY = E( T , Ir );

      if ENERGY < bestENERGY
        bestENERGY = ENERGY;
        bestROT = rots{r};
      end
    end
    
    I = bestROT;
    
    return;
  end

  
  if isnumeric( varargin{1} ) && ( is3dtform( varargin{1} ) || isequal( size( varargin{1} ) ,[3 3] ) ) 
    T = varargin{1}; varargin(1) = [];
  
    E = @(I) norm(I.SpatialTransform(1:3,1:3) - T(1:3,1:3),'fro');
%     E = @(I) norm( reallogm( linsolve( T(1:3,1:3) , I.SpatialTransform(1:3,1:3) ) ) , 'fro' );
%     E = @(I) Log_GL( T(1:3,1:3) \ I.SpatialTransform(1:3,1:3) );
    I = rot90( cleanout( cleanout( I ) , 'data' ) , E );
    return;
  end

  if ~isempty( fieldnames( I.CONTOURS ) ), error('I3D with contours, not implemented yet.'); end

  dims = cell2mat( varargin );
  
  if numel(dims) && strcmp( dims(1) , '-' )
    dims = regexprep(regexprep(regexprep( fliplr( dims(2:end) ) ,'i','iii'),'j','jjj'),'k','kkk');
  end
  
  ndim = numel(dims)+1;
  while ndim ~= numel(dims)
    ndim = numel(dims);
    
    dims = regexprep( dims , 'iiii'  , ''     );
    dims = regexprep( dims , 'jjjj'  , ''     );
    dims = regexprep( dims , 'kkkk'  , ''     );
    dims = regexprep( dims , 'jik'   , 'i'    );
    dims = regexprep( dims , 'kji'   , 'j'    );
    dims = regexprep( dims , 'ikj'   , 'k'    );
    dims = regexprep( dims , 'jk'    , 'ij'   );
    dims = regexprep( dims , 'ki'    , 'ij'   );
    dims = regexprep( dims , 'ijk'   , 'iij'  );
    dims = regexprep( dims , 'iki'   , 'iij'  );
    dims = regexprep( dims , 'jij'   , 'iji'  );
    dims = regexprep( dims , 'jji'   , 'ikk'  );
    dims = regexprep( dims , 'jjk'   , 'iji'  );
    dims = regexprep( dims , 'jki'   , 'iji'  );
    dims = regexprep( dims , 'jkj'   , 'ijj'  );
    dims = regexprep( dims , 'jkk'   , 'iij'  );
    dims = regexprep( dims , 'kii'   , 'iji'  );
    dims = regexprep( dims , 'kij'   , 'ijj'  );
    dims = regexprep( dims , 'kik'   , 'iij'  );
    dims = regexprep( dims , 'kjj'   , 'iik'  );
    dims = regexprep( dims , 'kjk'   , 'ijj'  );
    dims = regexprep( dims , 'kki'   , 'ijj'  );
    dims = regexprep( dims , 'kkj'   , 'jii'  );
    dims = regexprep( dims , 'iijj'  , 'kk'   );
    dims = regexprep( dims , 'jjii'  , 'kk'   );
    dims = regexprep( dims , 'iikk'  , 'jj'   );
    dims = regexprep( dims , 'kkii'  , 'jj'   );
    dims = regexprep( dims , 'jjkk'  , 'ii'   );
    dims = regexprep( dims , 'kkjj'  , 'ii'   );
    dims = regexprep( dims , 'iiik'  , 'kj'   );
    dims = regexprep( dims , 'ikkk'  , 'ji'   );
    dims = regexprep( dims , 'jiii'  , 'kj'   );
    dims = regexprep( dims , 'jiij'  , 'ii'   );
    dims = regexprep( dims , 'jiik'  , 'ijjj' );
    dims = regexprep( dims , 'iiiji' , 'kkk'  );
    dims = regexprep( dims , 'iijii' , 'jjj'  );
    
  end
  
%   disp( dims );
  
  LS = subsref( I , substruct('.','LANDMARKS') );
  for d = dims(:)'
    O = transform( [I.X(1) I.Y(1) I.Z(1)] , I.SpatialTransform );
    switch lower( d )
      case {'k'}
        newX = I.Y;
        newY = I.X;
        
        I.X = newX; I.X = I.X(end) - I.X(end:-1:1) + I.X(1);
        I.Y = newY;

        I.SpatialTransform = I.SpatialTransform*maketransform('rz',-90);
        On = transform( [I.X(end) I.Y(1) I.Z(1)] , I.SpatialTransform );
        I.SpatialTransform(1:3,4) = I.SpatialTransform(1:3,4) - ( On(:) - O(:) );
    
        I = DATA_action( I , [ '@(X) flipdim(permute(X,' uneval([2,1,3,4:ndims(I.data)]) ,'),1)' ] );
        
        I.LABELS = flipdim( permute( I.LABELS , [2 1 3 4:ndims(I.LABELS)] ) , 1 );
        if ~isempty( I.FIELDS ), for fn = fieldnames(I.FIELDS)', if isnumeric( I.FIELDS.(fn{1}) ) || islogical( I.FIELDS.(fn{1}) )
          I.FIELDS.(fn{1}) = flipdim( permute( I.FIELDS.(fn{1}) , [2 1 3 4:ndims(I.LABELS)] ) , 1 );
        end; end; end
        
        
      case {'i'}
        newY = I.Z;
        newZ = I.Y;
        
        I.Y = newY; I.Y = I.Y(end) - I.Y(end:-1:1) + I.Y(1);
        I.Z = newZ;

        I.SpatialTransform = I.SpatialTransform*maketransform('rx',-90);
        On = transform( [I.X(1) I.Y(end) I.Z(1)] , I.SpatialTransform );
        I.SpatialTransform(1:3,4) = I.SpatialTransform(1:3,4) - ( On(:) - O(:) );
    
        I = DATA_action( I , [ '@(X) flipdim(permute(X,' uneval([1,3,2,4:ndims(I.data)]) ,'),2)' ] );

        I.LABELS = flipdim( permute( I.LABELS , [1 3 2 4:ndims(I.LABELS)] ) , 2 );
        if ~isempty( I.FIELDS ), for fn = fieldnames(I.FIELDS)', if isnumeric( I.FIELDS.(fn{1}) ) || islogical( I.FIELDS.(fn{1}) )
          I.FIELDS.(fn{1}) = flipdim( permute( I.FIELDS.(fn{1}) , [1 3 2 4:ndims(I.LABELS)] ) , 2 );
        end; end; end
        
      case {'j'}
        newX = I.Z;
        newZ = I.X;
        
        I.X = newX; I.X = I.X(end) - I.X(end:-1:1) + I.X(1);
        I.Z = newZ;

        I.SpatialTransform = I.SpatialTransform*maketransform('ry',90);
        On = transform( [I.X(end) I.Y(1) I.Z(1)] , I.SpatialTransform );
        I.SpatialTransform(1:3,4) = I.SpatialTransform(1:3,4) - ( On(:) - O(:) );
    
        I = DATA_action( I , [ '@(X) flipdim(permute(X,' uneval([3,2,1,4:ndims(I.data)]) ,'),1)' ] );

        I.LABELS = flipdim( permute( I.LABELS , [3 2 1 4:ndims(I.LABELS)] ) , 1 );
        if ~isempty( I.FIELDS ), for fn = fieldnames(I.FIELDS)', if isnumeric( I.FIELDS.(fn{1}) ) || islogical( I.FIELDS.(fn{1}) )
          I.FIELDS.(fn{1}) = flipdim( permute( I.FIELDS.(fn{1}) , [3 2 1 4:ndims(I.LABELS)] ) , 1 );
        end; end; end

      otherwise
        error('I3D:rot90InvalidDirection','Invalid rotation direction.');
    end
  
  end

  if ~isempty( LS )
    I = subsasgn( I , substruct('.','LANDMARKS') , LS );
  end


  
  
  
if 0
  
%%
  rots = char( ndmat([0 1 2 3],[0 1 2 3],[0 1 2 3],[0 1 2 3],[0 1 2 3],[0 1 2 3],[0 1 2 3]) + 'h' );
  rots = mat2cell( rots , ones(size(rots,1),1) , size(rots,2) );

  rots = cellfun( @(r) strrep(r,'h','')    , rots , 'uniformoutput',false );
  rots = rots( ~cellfun( 'isempty' , rots ) );

  for i = 1:10
    rots = cellfun( @(r) strrep(r,'iiii',''   ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jjjj',''   ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kkkk',''   ) , rots , 'uniformoutput',false );
    
    rots = cellfun( @(r) strrep(r,'jik','i'   ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kji','j'   ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'ikj','k'   ) , rots , 'uniformoutput',false );
    
    rots = cellfun( @(r) strrep(r,'jk' ,'ij'  ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'ki' ,'ij'  ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'ijk','iij' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'iki','iij' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jij','iji' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jji','ikk' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jjk','iji' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jki','iji' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jkj','ijj' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jkk','iij' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kii','iji' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kij','ijj' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kik','iij' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kjj','iik' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kjk','ijj' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kki','ijj' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kkj','jii' ) , rots , 'uniformoutput',false );

    rots = cellfun( @(r) strrep(r,'iijj','kk' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jjii','kk' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'iikk','jj' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kkii','jj' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jjkk','ii' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'kkjj','ii' ) , rots , 'uniformoutput',false );

    rots = cellfun( @(r) strrep(r,'iiik','kj' ) , rots , 'uniformoutput',false );

    rots = cellfun( @(r) strrep(r,'ikkk','ji' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jiii','kj' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jiij','ii' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'jiik','ijjj' ) , rots , 'uniformoutput',false );
    

    rots = cellfun( @(r) strrep(r,'iiiji','kkk' ) , rots , 'uniformoutput',false );
    rots = cellfun( @(r) strrep(r,'iijii','jjj' ) , rots , 'uniformoutput',false );
    
    rots = rots( ~cellfun( 'isempty' , rots ) );
    rots = unique( rots );
  end
  [n,or] = sort( cellfun( @(r) numel(r) , rots ) );
  rots = rots( or )

  %%

%   clc
%   for i = 1:numel(rots)
%     r1 = rots{i};
%     for j = 1:i-1 %i+1:numel(rots)]
%       r2 = rots{j};
%       if isequal( double( rot90( I , r1 ) ) , double( rot90( I , r2 ) ) )
%         disp( [ r1  ' --> ' r2 ] );
%       end
%     end
%   end


  rots = {'i';'j';'k';'ii';'ij';'ik';'ji';'jj';'kj';'kk';'iii';'iij';'iik';'iji';'ijj';'ikk';'jii';'jjj';'kkk';'iiij';'iiji';'ijii';'ijjj'};
  
  best_error = Inf;
  for r = rots.'
    disp(r{1});
    Ir = rot90( I , r{1} );
    if ~isequal( size( A , 1:3 ) , size( Ir , 1:3 ) ), continue; end
    
    this_error = var( vec( double(Ir) - double(A) ) );
    if best_error > this_error
      best_error = this_error;
      best_rot = r{1};
    end
    if best_error < 1e-8, break; end
  end
  best_rot
  
end
  
  
end



