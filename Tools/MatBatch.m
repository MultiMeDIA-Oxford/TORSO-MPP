classdef MatBatch
  properties ( Access = private , Hidden = true )
    X
  end

  methods ( Hidden = true )
    function B = MatBatch( X )
      B.X = X;
      sz = [ size(B.X,1) , size(B.X,2) ];
      B.X = reshape( B.X , [ sz , numel(B.X)/max( 1 , sz(1)*sz(2) ) ] );
    end
    
    function display( B )
      Bn = inputname(1);
      if isempty( Bn ), Bn = 'ans'; end
      fprintf('%s = \n', Bn );
      disp( B );
    end
    function disp( B )
      disp( B.X );
      fprintf('\n');
      fprintf( '%d  matrices of size %dx%d  <class: %s>\n', size( B.X , 3 ) , size( B.X , 1 ) , size( B.X , 2 ) , class( B.X ) );
    end
    function X = double( B )
      X = double( B.X );
    end
    function SS  = uneval( B )
      S = sprintf( 'MatBatch( %s )' ,...
                     uneval( B.X )  );
                    
      if nargout > 0, SS = S;
      else
        Bn = inputname(1);
        if isempty( Bn  ), fprintf('%s\n', S );
        else,              fprintf('%s = %s\n', Bn , S );
        end
      end
    end

    function [ varargout ] = subsref( B , s )
      S= [];
      
      s_orig = s;
      optional_args = {};
      for ss = 1:numel(s)
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
              otherwise, S= [S(1:end-1) '_' S(end)];
            end
        end
      end
      
      switch S
        case {'.fcn(1)','.fcn(2)','.fcn(3)','.fcn(_)'}
          varargout{1} = B;
          try
            varargout{1}.X = feval( s(2).subs{1} , B.X , s(2).subs{2:end} );
          catch LE, throw(LE); end
          
        case {'.apply(1)','.apply(2)','.apply(3)','.apply(_)'}
          try
            [ varargout{1:max(1,nargout)} ] = apply( B , s(2).subs{:} );
          catch
            try
              [ varargout{1:nargout} ] = apply( B , s(2).subs{:} );
            catch LE
              throw(LE);
            end
          end
          
        case {'.X','.x'}
          varargout{1} = B.X;
        case {'{1}'}
          try
            varargout{1} = B;
            varargout{1}.X = varargout{1}.X( : , : , s(1).subs{:} );
          catch LE
            throw(LE);
          end
          
        case {'(1)','(2)'}
          try
            fk = fake( B , true );
            n = numel( fk );
            fk = fk( s(1).subs{:} );
          catch LE
            throw(LE);
          end
          
          N = size( B.X , 3 );
          varargout{1} = B;
          varargout{1}.X = varargout{1}.X( bsxfun( @plus , fk , reshape( (0:(N-1))*n , [1 1 N] ) ) );
          
        otherwise
          s = s_orig;
          if numel(s) > 1
            
            for w = 1:numel(s)-1
              try
                [ varargout{1:nargout} ] = subsref( subsref( B , s(1:w) ) , s(w+1:end) );
                break;
              end
              if w == numel(s)-1
                try,   s_err = uneval( s );
                catch, s_err = '';
                end
                error('incorrect subreferencing:   %s' , s_err );
              end
            end
            
          else
            
            try,   s_err = uneval( s );
            catch, s_err = '';
            end
            error('incorrect subreferencing:   %s' , s_err );
            
          end
      end
    end

    
    function n = numel( B , varargin )
      n = 1;
    end
    
    %%query functions
    function varargout = end(      B , varargin ), [varargout{1:nargout}] = builtin( 'end' , B.X(:,:,1) , varargin{:} ); end
   %function varargout = length(   B , varargin ), [varargout{1:nargout}] = length(          fake(B) , varargin{:} ); end
    function varargout = size(     B , varargin ), [varargout{1:nargout}] = size(            fake(B) , varargin{:} ); end
    function varargout = ndims(    B , varargin ), [varargout{1:nargout}] = ndims(           fake(B) , varargin{:} ); end
    function varargout = isempty(  B , varargin ), [varargout{1:nargout}] = isempty(         fake(B) , varargin{:} ); end
    function varargout = isscalar( B , varargin ), [varargout{1:nargout}] = isscalar(        fake(B) , varargin{:} ); end
    function varargout = isvector( B , varargin ), [varargout{1:nargout}] = isvector(        fake(B) , varargin{:} ); end
    function varargout = iscolumn( B , varargin ), [varargout{1:nargout}] = iscolumn(        fake(B) , varargin{:} ); end
    function varargout = isrow(    B , varargin ), [varargout{1:nargout}] = isrow(           fake(B) , varargin{:} ); end
    function varargout = ismatrix( B , varargin ), [varargout{1:nargout}] = ismatrix(        fake(B) , varargin{:} ); end


    function varargout = maxnorm( A , B )
      if nargin > 1, A = A - B; end
      [ varargout{1:nargout} ] = maxnorm( A.X );
    end
    
    
    %%reorder functions
    function B = vec( B )
      B.X = reshape( B.X , [ size(B.X,1) * size(B.X,2) , 1 , size(B.X,3) ] );
    end
    function B = reshape( B , varargin )
      try,       sz = size( reshape( fake(B) , varargin{:} ) );
      catch LE,  throw(LE); end
      if numel( sz ) > 2, error('reshape must return a 2d matrix'); end
      B.X = reshape( B.X , [ sz , size( B.X , 3 ) ] );
    end
    function B = repmat( B , varargin )
      error('To be implemented');
    end
    function B = squeeze( B , varargin )
      try,       sz = size( squeeze( fake(B) , varargin{:} ) );
      catch LE,  throw(LE); end
      B.X = reshape( B.X , [ sz , size( B.X , 3 ) ] );
    end
    function B = permute(B,order)             
      error('To be implemented');
    end
    function B = ipermute(B,order)
      error('To be implemented');
    end
    
    function B = transpose(B,varargin)
      B.X = permute( B.X , [2 1 3] );
    end
    function B = ctranspose(B,varargin)
      B.X = permute( B.X , [2 1 3] );
    end
    function B = circshift(B,shiftsize)
      error('To be implemented');
    end
    function B = flipdim(B,dim)
      error('To be implemented');
    end
    function B = fliplr(B)
      try,       fliplr( fake(B) );
      catch LE,  throw(LE); end
      B.X = flipdim( B.X , 2 );
    end
    function B = flipud(B)
      try,       fliplr( fake(B) );
      catch LE,  throw(LE); end
      B.X = flipdim( B.X , 1 );
    end

    function B = vertcat( varargin )
      error('To be implemented');
    end
    function B = horzcat( varargin )
      error('To be implemented');
    end
    function B = cat( dim , B , varargin )
      error('To be implemented');
    end
    function B = diag( B , varargin )
      if isvector( fake(B) )
        try, B = apply( B , @diag , varargin{:} ); catch LE,  throw(LE); end
      else
        fk = fake( B , true ); n = numel(fk); 
        try, fk = diag( fk , varargin{:} ); catch LE, throw(LE); end

        N = size( B.X , 3 );

        B.X = B.X( bsxfun( @plus , fk , reshape( (0:(N-1))*n , [1 1 N] ) ) );
      end
    end
    function B = rot90( B )
      try,  fk = rot90( fake( B , true ) ); catch LE,  throw(LE); end
      n = numel( fk ); N = size( B.X , 3 );
      
      B.X = B.X( bsxfun( @plus , fk , reshape( (0:(N-1))*n , [1 1 N] ) ) );
    end

    
    
    
    %%overloaded operations
    %arithmetic unary operations
    function B = uplus( B ),    end
    function B = uminus( B ),   B.X = uminus( B.X );           end
    
    
    %arithmetic and element-wise binary operations
    function C = plus( A , B ),     try, C = binaryOP( A , B , @plus  );   catch LE, throw(LE); end; end
    function C = minus( A , B ),    try, C = binaryOP( A , B , @minus );   catch LE, throw(LE); end; end
    %function C = minus( A , B ),    try, C = plus( A , uminus( B ) );      catch LE, throw(LE); end; end
    function C = times( A , B ),    try, C = binaryOP( A , B , @times );   catch LE, throw(LE); end; end
    function C = rdivide( A , B ),  try, C = binaryOP( A , B , @rdivide ); catch LE, throw(LE); end; end
    function C = ldivide( A , B ),  try, C = binaryOP( A , B , @rdivide ); catch LE, throw(LE); end; end
    function C = power( A , B ),    try, C = binaryOP( A , B , @power );   catch LE, throw(LE); end; end
    %function C = max( A , B ),      try, C = binaryOP( A , B , @max  );    catch LE, throw(LE); end; end
    %function C = min( A , B ),      try, C = binaryOP( A , B , @min  );    catch LE, throw(LE); end; end
    function C = rem( A , B ),      try, C = binaryOP( A , B , @rem  );    catch LE, throw(LE); end; end
    function C = mod( A , B ),      try, C = binaryOP( A , B , @mod  );    catch LE, throw(LE); end; end
    function C = atan2( A , B ),    try, C = binaryOP( A , B , @atan2  );  catch LE, throw(LE); end; end
    function C = atan2d( A , B ),   try, C = binaryOP( A , B , @atan2d  ); catch LE, throw(LE); end; end
    function C = hypot( A , B ),    try, C = binaryOP( A , B , @hypot  );  catch LE, throw(LE); end; end
    function C = eq( A , B ),       try, C = binaryOP( A , B , @eq  );     catch LE, throw(LE); end; end
    function C = ne( A , B ),       try, C = binaryOP( A , B , @ne  );     catch LE, throw(LE); end; end
    function C = lt( A , B ),       try, C = binaryOP( A , B , @lt  );     catch LE, throw(LE); end; end
    function C = le( A , B ),       try, C = binaryOP( A , B , @le  );     catch LE, throw(LE); end; end
    function C = gt( A , B ),       try, C = binaryOP( A , B , @gt  );     catch LE, throw(LE); end; end
    function C = ge( A , B ),       try, C = binaryOP( A , B , @ge  );     catch LE, throw(LE); end; end
    function C = and( A , B ),      try, C = binaryOP( A , B , @and  );    catch LE, throw(LE); end; end
    function C = or( A , B ),       try, C = binaryOP( A , B , @or  );     catch LE, throw(LE); end; end
    function C = xor( A , B ),      try, C = binaryOP( A , B , @xor  );    catch LE, throw(LE); end; end
    

    %element-wise operations
    function B = logical( B , varargin ),     try, B.X =     logical( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = not( B , varargin ),         try, B.X =         not( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = ceil( B , varargin ),        try, B.X =        ceil( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = fix( B , varargin ),         try, B.X =         fix( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = floor( B , varargin ),       try, B.X =       floor( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = round( B , varargin ),       try, B.X =       round( B.X , varargin{:} );    catch LE, throw(LE); end; end

    function B = cos( B , varargin ),         try, B.X =         cos( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = cosd( B , varargin ),        try, B.X =        cosd( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acos( B , varargin ),        try, B.X =        acos( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acosd( B , varargin ),       try, B.X =       acosd( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = cosh( B , varargin ),        try, B.X =        cosh( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acosh( B , varargin ),       try, B.X =       acosh( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                                              
    function B = sin( B , varargin ),         try, B.X =         sin( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = asin( B , varargin ),        try, B.X =        asin( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = sind( B , varargin ),        try, B.X =        sind( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = asind( B , varargin ),       try, B.X =       asind( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = sinh( B , varargin ),        try, B.X =        sinh( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = asinh( B , varargin ),       try, B.X =       asinh( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                           
    function B = tan( B , varargin ),         try, B.X =         tan( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = atan( B , varargin ),        try, B.X =        atan( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = tand( B , varargin ),        try, B.X =        tand( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = atand( B , varargin ),       try, B.X =       atand( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = tanh( B , varargin ),        try, B.X =        tanh( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = atanh( B , varargin ),       try, B.X =       atanh( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                           
    function B = cot( B , varargin ),         try, B.X =         cot( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = cotd( B , varargin ),        try, B.X =        cotd( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acot( B , varargin ),        try, B.X =        acot( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acotd( B , varargin ),       try, B.X =       acotd( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = coth( B , varargin ),        try, B.X =        coth( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acoth( B , varargin ),       try, B.X =       acoth( B.X , varargin{:} );    catch LE, throw(LE); end; end

    function B = csc( B , varargin ),         try, B.X =         csc( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = cscd( B , varargin ),        try, B.X =        cscd( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acsc( B , varargin ),        try, B.X =        acsc( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acscd( B , varargin ),       try, B.X =       acscd( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = csch( B , varargin ),        try, B.X =        csch( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = acsch( B , varargin ),       try, B.X =       acsch( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                              
    function B = sec( B , varargin ),         try, B.X =         sec( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = secd( B , varargin ),        try, B.X =        secd( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = asec( B , varargin ),        try, B.X =        asec( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = asecd( B , varargin ),       try, B.X =       asecd( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = sech( B , varargin ),        try, B.X =        sech( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = asech( B , varargin ),       try, B.X =       asech( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                              
    function B = realsqrt( B , varargin ),    try, B.X =    realsqrt( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = sqrt( B , varargin ),        try, B.X =        sqrt( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = cbrt( B , varargin ),        try, B.X =        cbrt( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                              
    function B = pow2( B , varargin ),        try, B.X =        pow2( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = pow10( B , varargin ),       try, B.X =       pow10( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = exp( B , varargin ),         try, B.X =         exp( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = expm1( B , varargin ),       try, B.X =       expm1( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = log( B , varargin ),         try, B.X =         log( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = reallog( B , varargin ),     try, B.X =     reallog( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = log1p( B , varargin ),       try, B.X =       log1p( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = log2( B , varargin ),        try, B.X =        log2( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = log10( B , varargin ),       try, B.X =       log10( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                              
    function B = erf( B , varargin ),         try, B.X =         erf( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = erfc( B , varargin ),        try, B.X =        erfc( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = erfcx( B , varargin ),       try, B.X =       erfcx( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = erfinv( B , varargin ),      try, B.X =      erfinv( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = erfcinv( B , varargin ),     try, B.X =     erfcinv( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                              
    function B = gamma( B , varargin ),       try, B.X =       gamma( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = gammaln( B , varargin ),     try, B.X =     gammaln( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = gammainc( B , varargin ),    try, B.X =    gammainc( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = gammaincinv( B , varargin ), try, B.X = gammaincinv( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = psi( B , varargin ),         try, B.X =         psi( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = ellipke( B , varargin ),     try, B.X =     ellipke( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = expint( B , varargin ),      try, B.X =      expint( B.X , varargin{:} );    catch LE, throw(LE); end; end
                                              
    function B = abs( B , varargin ),         try, B.X =         abs( B.X , varargin{:} );    catch LE, throw(LE); end; end
    function B = sign( B , varargin ),        try, B.X =        sign( B.X , varargin{:} );    catch LE, throw(LE); end; end

    
    %%methodos con 2 argumentos
% % % mod
% % % rem
% % % airy
% % % besselh
% % % besseli
% % % besselj
% % % besselk
% % % bessely
% % % beta
% % % betainc
% % % betaln
% % % ellipj
% % % legendre

    %%metodos que faltan with dimension
% % % mean    
% % % median
% % % prctile
% % % all
% % % any
% % % sum
% % % cumsum
% % % prod
% % % cumprod
% % % var
% % % std

% % % %requieren programar
% % % norm
% % % cross
% % % dot
% % % nthroot
% % % quad


% % % bitand
% % % bitcmp
% % % bitget
% % % bitmax
% % % bitor
% % % bitset
% % % bitshift
% % % bitxor
% % % and

% % % isfinite
% % % isinf
% % % isnan
% % % isinteger
% % % islogical
% % % isnumeric
% % % issparse
    
    
    %matrix-like binary operations
    function C = mtimes( A , B )
      if isscalar( A )  ||  isscalar( B )
        C = binaryOP( A , B , @times );
        return;
      end
      
      try, [A,B] = checkOP( A , B ); catch LE,  throw(LE); end
      try,  c = feval( @mtimes , A(:,:,1) , B(:,:,1) ); catch LE,  throw(LE); end

      C = MatBatch(0); C.X = zeros( [ size(c) , max( size(A,3) , size(B,3) ) ] );
      for i = 1:size(c,1)
        for j = 1:size(c,2)
          for s = 1:size(B,1)
            C.X(i,j,:) = C.X(i,j,:) + A(i,s,:) .* B(s,j,:);
          end
        end
      end
    end
    function C = mrdivide( A , B )
      if isscalar( A )  ||  isscalar( B )
        C = binaryOP( A , B , @rdivide );
        return;
      end
      
      try, [A,B] = checkOP( A , B ); catch LE,  throw(LE); end
      try,  c = feval( @mrdivide , A(:,:,1) , B(:,:,1) ); catch LE,  throw(LE); end

      C = MatBatch(0); C.X = zeros( [ size(c) , max( size(A,3) , size(B,3) ) ] );
      for z = 1:max( size(A,3) , size(B,3) )
        C.X(:,:,z) = mrdivide( A(:,:,min(z,end)) , B(:,:,min(z,end)) );
      end
    end
    function C = mldivide( A , B )
      if isscalar( A )  ||  isscalar( B )
        C = binaryOP( A , B , @ldivide );
        return;
      end
      
      try, [A,B] = checkOP( A , B ); catch LE,  throw(LE); end
      try,  c = feval( @mldivide , A(:,:,1) , B(:,:,1) ); catch LE,  throw(LE); end

      C = MatBatch(0); C.X = zeros( [ size(c) , max( size(A,3) , size(B,3) ) ] );
      for z = 1:max( size(A,3) , size(B,3) )
        C.X(:,:,z) = mldivide( A(:,:,min(z,end)) , B(:,:,min(z,end)) );
      end
    end
    function C = mpower( A , B )
      try, [A,B] = checkOP( A , B ); catch LE,  throw(LE); end
      try,  c = feval( @mpower , A(:,:,1) , B(:,:,1) ); catch LE,  throw(LE); end

      C = MatBatch(0); C.X = zeros( [ size(c) , max( size(A,3) , size(B,3) ) ] );
      for z = 1:max( size(A,3) , size(B,3) )
        C.X(:,:,z) = mpower( A(:,:,min(z,end)) , B(:,:,min(z,end)) );
      end
    end


    %%Matrix-Unary functions
    function B = trace(B)
      fk = fake( B , true );
      try, trace( fk ); catch LE, throw(LE); end
      
      n = numel( fk ); N = size( B.X , 3 );
      fk = diag( fk , 0 );
      
      B.X = sum( B.X( bsxfun( @plus , fk , reshape( (0:(N-1))*n , [1 1 N] ) ) ) , 1 );
    end
    function B = det( B )
      if size( B.X ,1) ~= size( B.X ,2)
        error('Matrix must be square.');
      end
      B.X = recursiveDet( B.X );
      
      function D = recursiveDet( X )
        s = size( X , 1 );
        switch s
          case 1
            D = X;
          case 2
            D = X(1,1,:) .* X(2,2,:) - X(1,2,:) .* X(2,1,:);
          case 3
            D = X(1,1,:).*( X(2,2,:).*X(3,3,:) - X(2,3,:).*X(3,2,:) ) -...
                X(1,2,:).*( X(2,1,:).*X(3,3,:) - X(2,3,:).*X(3,1,:) ) +...
                X(1,3,:).*( X(2,1,:).*X(3,2,:) - X(2,2,:).*X(3,1,:) );
          otherwise
            D = 0;
            for i = 1:s
              D = D + (-1).^(i+1) * X( i , 1 ,:) .* recursiveDet( X( [ 1:(i-1) , (i+1):s ] , 2:s ,:) );
            end
        end
      end
    end
    function [ varargout ] = eig( B , varargin )
      try,
        [ varargout{1:nargout} ] = apply( B , @eig , varargin{:} );
      catch LE, throw( LE ); end
    end
    function [ varargout ] = eig3x3( B , varargin )
      try,
        [ varargout{1:nargout} ] = apply( B , @eig3x3 , varargin{:} );
      catch LE, throw( LE ); end
    end
%     function D = inv( D )
%       iD = inv( rp(D) );
%       
%       dd = - kron( iD.' , iD );
%       dd = reshape( dd * imag( D.v(:) ) , size( D.v ) );
% 
%       D.v = complex( iD , dd );
%     end
%     function D = expm( D )
%       n = size( D.v , 1 );
%       Z = zeros( [ n , n ] );
%       
%       S = expm( [ rp(D) , dp(D) ; Z , rp(D) ] );
%       D.v = complex( S( 1:n , 1:n ) , S( 1:n , (n+1):end ) );
%     end
%     function D = logm( D )
%       n = size( D.v , 1 );
%       Z = zeros( n , n );
%       
%       S = logm( [ rp(D) , dp(D) ; Z , rp(D) ] );
%       D.v = complex( S( 1:n , 1:n ) , S( 1:n , (n+1):end ) );
%     end
%     function D = sqrtm( D )
%       n = size( D.v , 1 );
%       Z = zeros( n , n );
%       
%       S = sqrtm( [ rp(D) , dp(D) ; Z , rp(D) ] );
%       D.v = complex( S( 1:n , 1:n ) , S( 1:n , (n+1):end ) );
%     end
% % % pinv
% % % eig
% % % svd
% % % chol
% % % qr
% % % qz
% % % schur
% % % lu
% % % hess
% % % null
% % % orth
% % % rank
    
  end
  

  methods ( Access = private , Hidden = true )
    function sz = siz( B )
      sz = [ size( B.X , 1 ) , size( B.X , 2 ) ];
    end
    function fk = fake( B , indexes )
      fk = B.X(:,:,1);
      if nargin > 1  && indexes
        fk(:) = 1:numel(fk);
      end
    end
    function [A,B] = checkOP( A , B )
      if       isa(A,'MatBatch'), A = A.X;
      elseif   ndims( A ) > 3, error('only 2d or 3d array are allowed.'); end
      if       isa(B,'MatBatch'), B = B.X;
      elseif   ndims( B ) > 3, error('only 2d or 3d array are allowed.'); end
      
      a = size( A , 3 );  b = size( B , 3 );
      if a ~= 1 && b ~= 1 && a ~= b, error('Third dimensions must agree.'); end
    end
    function C = binaryOP( A , B , op )
      try, [A,B] = checkOP( A , B );
      catch LE,  throw(LE); end
      
      try,  feval( op , A(:,:,1) , B(:,:,1) );
      catch LE,  throw(LE); end

      C = MatBatch(0);
      try,  C.X = bsxfun( op , A , B );
      catch LE,  throw(LE); end
    end
    function [ varargout ] = apply( B , fcn , varargin )
      try,  [ outs{1:nargout} ] = feval( fcn , B.X(:,:,1) , varargin{:} ); catch LE,  throw(LE); end

      N = size(B.X,3);
      for z = 1:N
        try
          [ outs{1:max(1,nargout)} ] = feval( fcn , B.X(:,:,z) , varargin{:} );

          for n = 1:max(1,nargout)
            if z == 1, varargout{n} = MatBatch( outs{n} );
            else,      varargout{n}.X(:,:,z) = outs{n};
            end
          end
        catch
          [ outs{1:nargout} ] = feval( fcn , B.X(:,:,z) , varargin{:} );
        end
      end
      
    end
  end
  
end
