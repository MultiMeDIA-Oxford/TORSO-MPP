function Y_ = isit( x , varargin )

%   ERR = struct('message','mensaje 1','identifier','isit:err');
  ERR = [];
  if isstruct( varargin{end} )
    ERR = varargin{end};
    varargin(end) = [];
    
    if isfield( ERR , 'msg' ), ERR.message    = ERR.msg; ERR = rmfield( ERR , 'msg' ); end
    if isfield( ERR , 'm'   ), ERR.message    = ERR.m;   ERR = rmfield( ERR , 'm'   ); end
    if isfield( ERR , 'id'  ), ERR.identifier = ERR.id;  ERR = rmfield( ERR , 'id'  ); end
  end

  
  Y = true;
  i = 1;
  while i <= numel( varargin )
    C = varargin{i}; i = i+1;

    if iscell( C )
    elseif ischar(C)
      C = { C };
      switch lower( C{1} )
        case {'ndims','numel','nrows','nrow','ncols','ncol','ncolumns'}
          C{2} = varargin{i}; i = i+1;
        case {'size','sz'}
          C{2} = varargin{i}; i = i+1;
        case {'~=','==','<','>','>=','<='}
          C{2} = varargin{i}; i = i+1;
        case {'range','in'}
          C{2} = varargin{i}; i = i+1;
      end
    else
      error('no entiendo');
    end

    MSG = '';
    c = 1;
    YY = false;
    while c <= numel(C)
      thisMSG = '';
      Q = C{c}; c = c+1;
      if ~ischar(Q), error('se esperaba una question char'); end
      switch lower(Q)
%         case {'rowstochastic'}
%         case {'columnstochastic'}
%         case {'doublestochastic'}
%         case {'circulant'}
%         case {'permutation'}
%         case {'orthogonal'}
%         case {'unitary'}
%         case {'singular'}
%         case {'orientationpreserving'}
%         case {'scalarmat'}
%         case {'linspace'}
%         case {'geospace'}
%         case {'triangular'}
%         case {'lower','tril'}
%         case {'upper','triu'}
%         case {'symmetric'}
%         case {'skew','skewsymmetric'}
%         case {'semiposdef'}
%         case {'spd'}
%         case {'sorted','monotone'}
%         case {'strictmonotone'}
%         case {'increasing'}
%         case {'nonincreasing'}  %avoid NaNs
%         case {'strictincreasing'}
%         case {'decreasing'}
%         case {'nondecreasing'}  %avoid NaNs
%         case {'strictdecreasing'}
%         case {'idempotent'}
%         case {'nilpotent'}
%         case {'unipotent'}
%         case {'diagonalizable'}

        case {'posdef'}
          YY = isnumeric( x );
          if ~YY, thisMSG = 'be  ''numeric''';
          else
            YY = ndims( x ) == 2;
            if ~YY, thisMSG = 'be  ''2d''';
            else
              YY = size(x,1) == size(x,2);
              if ~YY, thisMSG = 'be  square';
              else
                x = double(x) + double(x).';
                try
                  x = chol(x);
                  YY = true;
                catch
                  YY = false;
                end
                if ~YY, thisMSG = sprintf('be positive definite'); end
              end
            end
          end
          
        
        
        
        case {'double','float64'}
          YY = isa( x , 'double' );
          if ~YY, thisMSG = sprintf('be of class  ''double''  but it is ''%s''',class(x)); end

        case {'single','float32'}
          YY = isa( x , 'single' );
          if ~YY, thisMSG = sprintf('be of class  ''single''  but it is ''%s''',class(x)); end
        
        case {'int64','long','integer64'}
          YY = isa( x , 'int64' );
          if ~YY, thisMSG = sprintf('be of class  ''int64''  but it is ''%s''',class(x)); end
        
        case {'uint64','ulong','uinteger64'}
          YY = isa( x , 'uint64' );
          if ~YY, thisMSG = sprintf('be of class  ''uint64''  but it is ''%s''',class(x)); end
        
        case {'int32','int','integer32'}
          YY = isa( x , 'int32' );
          if ~YY, thisMSG = sprintf('be of class  ''int32''  but it is ''%s''',class(x)); end
        
        case {'uint32','uint','uinteger32'}
          YY = isa( x , 'uint32' );
          if ~YY, thisMSG = sprintf('be of class  ''uint32''  but it is ''%s''',class(x)); end
        
        case {'int16','short','integer16'}
          YY = isa( x , 'int16' );
          if ~YY, thisMSG = sprintf('be of class  ''int16''  but it is ''%s''',class(x)); end
        
        case {'uint16','ushort','uinteger16'}
          YY = isa( x , 'uint16' );
          if ~YY, thisMSG = sprintf('be of class  ''uint16''  but it is ''%s''',class(x)); end
        
        case {'int8','integer8'}
          YY = isa( x , 'int8' );
          if ~YY, thisMSG = sprintf('be of class  ''int8''  but it is ''%s''',class(x)); end
        
        case {'uint8','uinteger8'}
          YY = isa( x , 'uint8' );
          if ~YY, thisMSG = sprintf('be of class  ''uint8''  but it is ''%s''',class(x)); end
        
        case {'char'}
          YY = ischar( x );
          if ~YY, thisMSG = sprintf('be of class  ''char''  but it is ''%s''',class(x)); end
        
        case {'logical','logic'}
          YY = islogical( x );
          if ~YY, thisMSG = sprintf('be  ''logical''  but it is ''%s''',class(x)); end
        
        case {'cell'}
          YY = iscell( x );
          if ~YY, thisMSG = sprintf('be a  ''cell''  but it is ''%s''',class(x)); end
        
        case {'struct'}
          YY = isstruct( x );
          if ~YY, thisMSG = sprintf('be a  ''struct''  but it is ''%s''',class(x)); end
        
        case {'function_handle','fhandle','@'}
          YY = isa( x , 'function_handle' );
          if ~YY, thisMSG = sprintf('be a  ''function_handle''  but it is ''%s''',class(x)); end

        case {'array'}
          YY = ( isnumeric( x ) || islogical( x ) );
          if ~YY, thisMSG = sprintf('be an  ''array''  but it is ''%s''',class(x)); end

        case {'float'}
          YY = isfloat( x );
          if ~YY, thisMSG = sprintf('be a ''single'' or ''double''  but it is ''%s''',class(x)); end

        case {'integer'}
          YY = isinteger( x );
          if ~YY, thisMSG = sprintf('be an  ''integer''  array but it is ''%s''',class(x)); end

        case {'i8','integer8'}
          YY = isa( x , 'int8' ) || isa( x , 'uint8' );
          if ~YY, thisMSG = sprintf('be an  ''int8'' or ''uint8'' but it is ''%s''',class(x)); end

        case {'i16','integer16'}
          YY = isa( x , 'int16' ) || isa( x , 'uint16' );
          if ~YY, thisMSG = sprintf('be an  ''int16'' or ''uint16'' but it is ''%s''',class(x)); end

        case {'i32','integer32'}
          YY = isa( x , 'int32' ) || isa( x , 'uint32' );
          if ~YY, thisMSG = sprintf('be an  ''int32'' or ''uint32'' but it is ''%s''',class(x)); end

        case {'i64','integer64'}
          YY = isa( x , 'int64' ) || isa( x , 'uint64' );
          if ~YY, thisMSG = sprintf('be an  ''int64'' or ''uint64'' but it is ''%s''',class(x)); end

        case {'numeric'}
          YY = isnumeric( x );
          if ~YY, thisMSG = sprintf('be  ''numeric''  but it is ''%s''',class(x)); end

        case {'scalar'}
          YY = ( isnumeric( x ) || islogical( x ) ) && numel(x) == 1;
          if ~YY, thisMSG = 'be a numeric or logical scalar'; end

        case {'nonscalar'}
          YY = ( isnumeric( x ) || islogical( x ) ) && numel(x) > 1;
          if ~YY, thisMSG = 'be a numeric or logical and have more than 1 element'; end

        case {'empty'}
          YY = isempty(x);
          if ~YY, thisMSG = 'be empty'; end

        case {'nonempty','~empty'}
          YY = ~isempty(x);
          if ~YY, thisMSG = sprintf('be non-empty but it have %d elements',numel(x)); end

        case {'emptya','emptyarray','[]'}
          YY = ( isnumeric( x ) || islogical( x ) ) && isempty(x);
          if ~YY, thisMSG = 'be an empty array'; end

        case {'nonemptya','nonemptyarray','~emptya','~emptyarray','~[]'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~isempty(x);
          if ~YY, thisMSG = 'be a non-empty array'; end

        case {'emptycell','{}'}
          YY = iscell( x ) && isempty(x);
          if ~YY, thisMSG = 'be an empty cell'; end

        case {'nonemptycell','~emptycell','~{}'}
          YY = iscell( x ) && ~isempty(x);
          if ~YY, thisMSG = 'be a non-empty cell'; end

        case {'vector'}
          YY = ndims( x ) <= 2  &&  ( size( x , 2 ) == 1 || size( x , 1 ) == 1 );
          if ~YY, thisMSG = sprintf('be a vector but have size %s',size2str(x)); end
          
        case {'row'}
          YY = ndims( x ) <= 2  &&  size( x , 1 ) == 1;
          if ~YY, thisMSG = sprintf('be a single row but have size %s',size2str(x)); end
          
        case {'1d','column','col'}
          YY = ndims( x ) <= 2  &&  size( x , 2 ) == 1;
          if ~YY, thisMSG = sprintf('be a single column but have size %s',size2str(x)); end
          
        case {'2d','rect','rectangular'}
          YY = ndims( x ) == 2;
          if ~YY, thisMSG = sprintf('be  2d  but have %d dims',ndims(x)); end
          
        case {'p2d','proper2d','properrect','properrectangular'}
          YY = ndims( x ) == 2 && all( size(x) > 1 );
          if ~YY, thisMSG = sprintf('be a proper 2d  but have size %s',size2str(x)); end

        case {'sq','square'}
          YY = ndims( x ) == 2 && size( x , 1 ) == size( x , 2 );
          if ~YY, thisMSG = sprintf('be a 2d square but have size %s',size2str(x)); end

        case {'psq','propersq','propersquare'}
          YY = ndims( x ) == 2 && size( x , 1 ) == size( x , 2 ) && size( x , 1 ) > 1;
          if ~YY, thisMSG = sprintf('be a proper 2d square but have size %s',size2str(x)); end

        case {'3d'}
          YY = ndims( x ) <= 3;
          if ~YY, thisMSG = sprintf('be  3d  but have %d dims',ndims(x)); end

        case {'p3d','proper3d'}
          YY = ndims( x ) == 3 && all( size(x) > 1 );
          if ~YY, thisMSG = sprintf('be a proper  3d  but have size %s',size2str(x)); end

        case {'4d'}
          YY = ndims( x ) <= 4;
          if ~YY, thisMSG = sprintf('be  4d  but have %d dims',ndims(x)); end

        case {'p4d','proper4d'}
          YY = ndims( x ) == 4 && all( size(x) > 1 );
          if ~YY, thisMSG = sprintf('be a proper  4d  but have size %s',size2str(x)); end

        case {'5d'}
          YY = ndims( x ) <= 5;
          if ~YY, thisMSG = sprintf('be  5d  but have %d dims',ndims(x)); end

        case {'p5d','proper5d'}
          YY = ndims( x ) == 5 && all( size(x) > 1 );
          if ~YY, thisMSG = sprintf('be a proper  5d  but have size %s',size2str(x)); end

        case {'6d'}
          YY = ndims( x ) <= 6;
          if ~YY, thisMSG = sprintf('be  6d  but have %d dims',ndims(x)); end

        case {'p6d','proper6d'}
          YY = ndims( x ) == 6 && all( size(x) > 1 );
          if ~YY, thisMSG = sprintf('be a proper  6d  but have size %s',size2str(x)); end

        case {'7d'}
          YY = ndims( x ) <= 7;
          if ~YY, thisMSG = sprintf('be  7d  but have %d dims',ndims(x)); end

        case {'p7d','proper7d'}
          YY = ndims( x ) == 7 && all( size(x) > 1 );
          if ~YY, thisMSG = sprintf('be a proper  7d  but have size %s',size2str(x)); end


        case {'1x2'}
          YY = isequal( size(x) , [1 2] );
          if ~YY, thisMSG = sprintf('be 1x2 but have size %s',size2str(x)); end
          
        case {'2x1'}
          YY = isequal( size(x) , [2 1] );
          if ~YY, thisMSG = sprintf('be 2x1 but have size %s',size2str(x)); end

        case {'2x2'}
          YY = isequal( size(x) , [2 2] );
          if ~YY, thisMSG = sprintf('be 2x2 but have size %s',size2str(x)); end

        case {'3x3'}
          YY = isequal( size(x) , [3 3] );
          if ~YY, thisMSG = sprintf('be 3x3 but have size %s',size2str(x)); end

        case {'1x3'}
          YY = isequal( size(x) , [1 3] );
          if ~YY, thisMSG = sprintf('be 1x3 but have size %s',size2str(x)); end

        case {'3x1'}
          YY = isequal( size(x) , [3 1] );
          if ~YY, thisMSG = sprintf('be 3x1 but have size %s',size2str(x)); end

        case {'4x4'}
          YY = isequal( size(x) , [4 4] );
          if ~YY, thisMSG = sprintf('be 4x4 but have size %s',size2str(x)); end

        case {'sparse'}
          YY = ( isnumeric( x ) || islogical( x ) ) && issparse( x );
          if ~YY, thisMSG = 'be sparse'; end

        case {'full','nonsparse'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~issparse( x );
          if ~YY, thisMSG = 'be full (non-sparse)'; end

        case {'logicalsparse','logsparse','lsparse'}
          YY = islogical( x ) && issparse( x );
          if ~YY, thisMSG = 'be logical and sparse'; end

        case {'logicalfull','logfull','lfull','logicalnonsparse','lognonsparse','lnonsparse'}
          YY = islogical( x ) && ~issparse( x );
          if ~YY, thisMSG = 'be logical and full (non-sparse)'; end

        case {'numericsparse','numsparse','nsparse'}
          YY = isnumeric( x ) && issparse( x );
          if ~YY, thisMSG = 'be numeric and sparse'; end

        case {'numericfull','numfull','nfull','numericnonsparse','numnonsparse','nnonsparse'}
          YY = isnumeric( x ) && ~issparse( x );
          if ~YY, thisMSG = 'be numeric and full (non-sparse)'; end

        case {'real'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ( isreal( x ) || ~any( imag(x(:))) );
          if ~YY, thisMSG = 'be real (it can be complex but zero imag part)'; end

        case {'properreal','preal'}
          YY = ( isnumeric( x ) || islogical( x ) ) &&   isreal( x );
          if ~YY, thisMSG = 'be real'; end

        case {'complex'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~isreal( x );
          if ~YY, thisMSG = 'be not-real'; end

        case {'propercomplex','pcomplex'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~isreal( x ) && any( imag( x(:) ) );
          if ~YY, thisMSG = 'be imag part non real'; end

        case {'imag'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~isreal( x ) && any( imag( x(:) ) ) && ~any( real( x(:) ) );
          if ~YY, thisMSG = 'be pure imaginary (real part equal to zero and non zero imag)'; end

        case {'finite'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( isfinite( x(:) ) );
          if ~YY, thisMSG = 'be an array and all elements finite'; end

        case {'nonan','nonans'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~any( isnan( x(:) ) );
          if ~YY, thisMSG = 'be an array and all elements different of nan'; end

        case {'inf'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( isinf( x(:) ) );
          if ~YY, thisMSG = 'be an array and all elements infinite'; end

        case {'+inf'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( isinf( x(:) ) ) && all( x(:) > 0 );
          if ~YY, thisMSG = 'be an array and all elements positive infinite'; end

        case {'-inf'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( isinf( x(:) ) ) && all( x(:) < 0 );
          if ~YY, thisMSG = 'be an array and all elements negative infinite'; end

        case {'rounded','round'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~any( rem( x(:) , 1 ) );
          if ~YY, thisMSG = 'be an array and all elements represent integer numbers'; end

        case {'binary','zero-one'}
          YY = ( isnumeric( x ) || islogical( x ) ) && isequal( x , ~~x );
          if ~YY, thisMSG = 'be an array and all elements 0 or 1'; end

        case {'zero','zeros','0'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( ~x(:) );
          if ~YY, thisMSG = 'be an array and all elements 0'; end

        case {'nonzero'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( ~~x(:) );
          if ~YY, thisMSG = 'be an array and all elements nonzero'; end

        case {'pos','positive'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( x(:) > 0 );
          if ~YY, thisMSG = 'be an array and all elements greater than 0'; end

        case {'neg','negative'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( x(:) < 0 );
          if ~YY, thisMSG = 'be an array and all elements smaller than 0'; end

        case {'nonneg','nonnegative'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( x(:) >= 0 );
          if ~YY, thisMSG = 'be an array and all elements non-negative'; end

        case {'nonpos','nonpositive'}
          YY = ( isnumeric( x ) || islogical( x ) ) && all( x(:) <= 0 );
          if ~YY, thisMSG = 'be an array and all elements non-positive'; end

        case {'even'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~any( rem( x(:) , 2 ) );
          if ~YY, thisMSG = 'be an array and all elements even'; end

        case {'odd'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ~any( rem( x(:)+1 , 2 ) );
          if ~YY, thisMSG = 'be an array and all elements odd'; end

        case {'diag'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ndims( x ) == 2 && isequal( diag(diag(x)) , x );
          if ~YY, thisMSG = 'be a diagonal array'; end

        case {'eye'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ndims( x ) == 2 && isequal( eye(size(x)) , x );
          if ~YY, thisMSG = 'be a identity array'; end

        case {'peye','propereye'}
          YY = ( isnumeric( x ) || islogical( x ) ) && ndims( x ) == 2 && size(x,1) == size(x,2) && isequal( eye(size(x)) , x );
          if ~YY, thisMSG = 'be a proper identity array'; end

        otherwise
          try
            VAL = C{c}; c = c+1;
          catch
            error('or unrecognized question or a comparator value is expected');
          end
          switch lower(Q)
            case {'ndims'}
              if numel(VAL) ~= 1 && numel(VAL) ~= 2, error('a scalar value or [min max] was expected'); end
              YY = compare( ndims(x) , VAL );
              if      ~YY  &&  numel(VAL) == 1, thisMSG = sprintf('have %d dimmensions but have %d',VAL,ndims(x) );
              elseif  ~YY  &&  numel(VAL) == 2, thisMSG = sprintf('have between %d and %d dimmensions but have %d',VAL(1),VAL(2),ndims(x) );
              end
              
            case {'numel'}
              if numel(VAL) ~= 1 && numel(VAL) ~= 2, error('a scalar value or [min max] was expected'); end
              YY = compare( numel(x) , VAL );
              if      ~YY  &&  numel(VAL) == 1, thisMSG = sprintf('have %d number of elements but have %d',VAL,numel(x) );
              elseif  ~YY  &&  numel(VAL) == 2, thisMSG = sprintf('have between %d and %d number of elements but have %d',VAL(1),VAL(2),numel(x) );
              end

            case {'nrow','nrows'}
              if numel(VAL) ~= 1 && numel(VAL) ~= 2, error('a scalar value or [min max] was expected'); end
              YY = ndims(x) == 2 && compare( size(x,1) , VAL );
              if      ~YY  &&  numel(VAL) == 1, thisMSG = sprintf('have %d rows but have a size %s',VAL,size2str(x) );
              elseif  ~YY  &&  numel(VAL) == 2, thisMSG = sprintf('have between %d and %d rows but have a size %s',VAL(1),VAL(2),size2str(x) );
              end

            case {'ncol','ncols','ncolumns'}
              if numel(VAL) ~= 1 && numel(VAL) ~= 2, error('a scalar value or [min max] was expected'); end
              YY = ndims(x) == 2 && compare( size(x,2) , VAL );
              if      ~YY  &&  numel(VAL) == 1, thisMSG = sprintf('have %d columns but have a size %s',VAL,size2str(x) );
              elseif  ~YY  &&  numel(VAL) == 2, thisMSG = sprintf('have between %d and %d columns but have a size %s',VAL(1),VAL(2),size2str(x) );
              end

            case {'size','sz'}
              if ~isvector( VAL ), error('a vector was expected'); end
              sz = size(x);
               sz( (end+1):max(numel(sz),numel(VAL)) ) = 1;
              VAL( (end+1):max(numel(sz),numel(VAL)) ) = 1;
              YY = true;
              for d = find( ~isnan( VAL ) )
                YY = YY & sz(d) == VAL(d);
                if ~YY, break; end
              end
              if ~YY
                VAL = strrep( sprintf(' %d x',VAL) , 'NaN' , '...' );
                VAL = sprintf( '( %s)', VAL(1:end-1) );
                thisMSG = sprintf('have size  %s  but have size %s',VAL,size2str(x) );
              end

            case {'=='}
              elementWiseComparison( @eq , lower(Q) );
              
            case {'~='}
              elementWiseComparison( @ne , lower(Q) );
              
            case {'>'}
              elementWiseComparison( @gt , lower(Q) );
              
            case {'>='}
              elementWiseComparison( @ge , lower(Q) );
              
            case {'<'}
              elementWiseComparison( @lt , lower(Q) );
              
            case {'<='}
              elementWiseComparison( @le , lower(Q) );
              
            case {'range','in'}
              if numel(VAL) ~= 2, error('[min max] was expected'); end
              if VAL(2) <= VAL(1), error('[min max] was expected'); end
              YY = isnumeric( x ) || islogical( x );
              if ~YY, thisMSG = 'be  ''numeric''  or  ''logical''';
              else
                YY  = all( x(:) >= VAL(1) ) && all( x(:) <= VAL(2) );
                if ~YY, thisMSG = sprintf('have all its elements between  %s  and  %s',uneval( VAL(1) ), uneval( VAL(2) ) ); end
              end

            otherwise
              error('unrecognized question');
          end
      end
      
      if      isempty( MSG )  &&  ~isempty( thisMSG )
        MSG = sprintf(  'it must:   %s\n',    thisMSG);
      elseif ~isempty( MSG )  &&  ~isempty( thisMSG )
        MSG = sprintf('%s     or:   %s\n',MSG,thisMSG);
      end
      
      if YY, break; end
    end

    Y = YY & Y;
    if ~Y
      if isstruct( ERR )
        ERR.message = sprintf('%s\n%s',ERR.message,MSG);
        
        rethrow( ERR );
      end
      
      break;
    end
  end


  if nargout
    Y_ = Y;
  elseif ~Y
    fprintf('does not fulfill the conditions:\n');
    fprintf('%s',MSG);
  else
    fprintf('OK\n');
  end
  
  
  
  function R = compare( a , b )
    if      numel( a ) == 1  &&  numel( b ) == 1
      R = a == b;
    elseif  numel( a ) == 1  &&  numel( b ) == 2
      R = a >= b(1) && a >= b(2);
    else
      error('porque estoy aqui??');
    end
  end

  function s = size2str( x )
    s = sprintf(' %d x',size(x));
    s = [ '(' , s(1:end-1) , ')' ];
  end

  function elementWiseComparison( func , funcSTR )
    YY = isnumeric( x ) || islogical( x );
    if ~YY
      thisMSG = 'be  ''numeric''  or  ''logical''';
    else
      try
        YY = all( func( x(:) , VAL ) );
        if ~YY
          if isscalar( VAL )
            thisMSG = sprintf('have all values %s  %s',funcSTR,uneval(VAL));
          else
            thisMSG = sprintf('have all values %s (the comparator value)',funcSTR);
          end
        end
      catch
        YY = false;
        thisMSG = sprintf('be able to be compared with a %s array',size2str(VAL));
      end
    end
  end

end
