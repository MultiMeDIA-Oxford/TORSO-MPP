classdef dual
  properties ( Access = public , Hidden = false )
    v;
  end

  methods ( Access = public )
    M = skewmatrix( m );
  end
  methods ( Hidden = true )
    function D = dual( r , d ) %dual class constructor
      if nargin == 0
        D.v = complex( 0 , 0 );
        return;
      end
      if nargin == 1
        try,   D.v = complex( real(r) , imag(r));
        catch, D.v = complex( r , 0 );
        end
        return;
      end
      if nargin < 2, d = 0;   end
      if nargin < 1, r = 0;   end

      if ~isfloat( r )       , error('real part must be float.'); end
      if any( imag(  r(:) ) ), error('complex in real part.'); end
      if any( isnan( r(:) ) ), error('NaNs    in real part.'); end
      if any( isinf( r(:) ) ), error('INFs    in real part.'); end
      if ~isfloat( d )       , error('dual part must be float.'); end
      if any( imag(  d(:) ) ), error('complex in dual part.'); end
      if any( isnan( d(:) ) ), error('NaNs    in dual part.'); end
      if any( isinf( d(:) ) ), error('INFs    in dual part.'); end
      D.v = complex( double(r) , double(d) );
    end

    
    
    
    function n = numel(D,varargin)
      n = numel( D.v , varargin{:} );
      n = 1;
    end
    function D = subsref( D , S )
      switch S(1).type
        case '()'
          D.v = subsref( D.v , S(1) );
          S(1) = [];
        case '.'
          switch S(1).subs
            case {'data','v','complex'}      , D = D.v;
            case {'r','real','rp','realpart'}, D = real(D.v);
            case {'d','dual','dp','dualpart'}, D = imag(D.v);
            case {'numel'}                   , D = numel(D.v);
            otherwise, error('invalid subsref');
          end
          S(1) = [];
        case '{}'
          S(1).type = '()';
          D = subsref( imag(D.v) , S(1) );
          S(1) = [];
        otherwise
          uneval( varargin );
          error('subsref ??');
      end
      if numel(S),  D = subsref( D , S ); end
    end
    function D = subsasgn( D , S , in )
      switch S(1).type
        case '()'
          if isa( in , 'dual' )
            in = in.v;
          elseif isfloat( in ) && ~any( imag( in(:) ) )
            in = complex( in , 0 );
          else
            error('incorrect filling');
          end
          D.v = subsasgn( D.v , S , in );

        case '{}'
          r = real( D.v );
          d = imag( D.v );
          if isfloat(in) && isempty( in )
            S(1).type = '()';
            r = subsasgn( r , S , in );
            d = subsasgn( d , S , in );
          elseif isfloat( in ) && ~any( imag( in(:) ) )
            S(1).type = '()';
            d = subsasgn( d , S , in );
            if ~isequal( size(r) , size(d) )
              w = num2cell( size(d) );
              r( w{:} ) = 0;
            end
          else
            error('incorrect filling');
          end
          D.v = complex( r , d );

        case '.'
          r = real( D.v );
          d = imag( D.v );
          switch S(1).subs
            case {'r','real','rp','realpart'}
              if isfloat(in) && isempty( in )
                r = subsasgn( r , S(2:end) , in );
                d = subsasgn( d , S(2:end) , in );
              elseif isfloat(in)
                r = subsasgn( r , S(2:end) , in );
                if ~isequal( size(r) , size(d) )
                  w = num2cell( size(r) );
                  d( w{:} ) = 0;
                end
              else
                error('incorrect filling');
              end
            case {'d','dual','dp','dualpart'}
              if isfloat(in) && isempty( in )
                r = subsasgn( r , S(2:end) , in );
                d = subsasgn( d , S(2:end) , in );
              elseif isfloat(in)
                d = subsasgn( d , S(2:end) , in );
                if ~isequal( size(r) , size(d) )
                  w = num2cell( size(d) );
                  r( w{:} ) = 0;
                end
              else
                error('incorrect filling');
              end
            otherwise, error('invalid subsref');
          end          
          D.v = complex( r , d );
          
        otherwise, error('subsasgn ??');
      end
    end
    
    function disp( D )
      if isempty( D.v )
        fprintf('empty dual\n');
      else
        str = builtin( 'evalc' , 'disp( complex( rp(D) , dp(D) ) )' );
        str = builtin( 'strrep' , str , 'i' , 'd' );
        str = regexprep( str , ' ([\+-]) (\s*)([0-9\.\+-ef]*)d' , ' $1 $3d$2' );
        
        bold = true;
        boldB = ''; boldE = '';
        try
          if matlab.internal.display.isHot() && bold
            boldB = getString(message('MATLAB:table:localizedStrings:StrongBegin'));
            boldE = getString(message('MATLAB:table:localizedStrings:StrongEnd'));
          end
        catch
          boldB = '<strong>'; boldE = '</strong>';
        end
 
        str = builtin( 'strrep' , str , 'd' , [ boldB , 'd' , boldE ] );
      
        
        
        fprintf('%s', str );
      end
    end
    function display( D )
      Dn = inputname(1);
      if isempty( Dn ), Dn = 'ans'; end
      fprintf('%s =\n',Dn); disp( D );
    end
    
    function c = complex( D ),  c = complex( rp(D) , dp(D) ); end
    function r = double( D ),   r = rp(D);                    end
    function r = real( D ),     r = rp(D);                    end
    function r = realpart( D ), r = rp(D);                    end
    function d = imag( D ),     d = dp(D);                    end
    function d = dualpart( D ), d = dp(D);                    end
    function d = dpart( D ),    d = dp(D);                    end
    
    function out = isdual( D )
      if isa(D,'dual'), out = true; else, out = false; end
    end
    function out = isidentical( A , B )
      out = false;
      if ~isa(A,'dual'),   return; end
      if ~isa(B,'dual'),   return; end
      if ~isequal( A.v , B.v ), return; end
      out = true;
    end
    function out = isequal( A , B )
      switch areDUALS( A , B )
        case '00', error('why here?');
        case '01', out = isequal(    A  , rp(B) );
        case '10', out = isequal( rp(A) ,    B  );
        case '11', out = isequal( rp(A) , rp(B) );
      end      
    end
    function SS  = uneval( D )
      SS = sprintf( 'dual( %s , %s )', uneval( rp(D) ) , uneval( dp(D) ) );
    end
      
    %%query functions
    function varargout = end( D , varargin )     , [varargout{1:nargout}] = builtin( 'end' , D.v , varargin{:} ); end    
    function varargout = size( D , varargin )    , [varargout{1:nargout}] = size( D.v , varargin{:} );            end
    function varargout = length(D,varargin)      , [varargout{1:nargout}] = length( D.v , varargin{:} );          end
    function varargout = ndims(D,varargin)       , [varargout{1:nargout}] = ndims( D.v , varargin{:} );           end
    function varargout = isvector(D,varargin)    , [varargout{1:nargout}] = isvector( D.v , varargin{:} );        end
    function varargout = isscalar(D,varargin)    , [varargout{1:nargout}] = isscalar( D.v , varargin{:} );        end
    function varargout = isempty(D,varargin)     , [varargout{1:nargout}] = isempty( D.v , varargin{:} );         end
    

    %%reorder functions
    function D = full( D , varargin )            , D.v = full( D.v , varargin{:} );       end
    function D = conj(D,varargin)                ,                                        end
    function D = reshape( D , varargin )         , D.v = reshape( D.v , varargin{:} );    end
    function D = repmat( D , varargin )          , D.v = repmat( D.v , varargin{:} );     end
    function D = vec( D , varargin )             , D.v = vec( D.v , varargin{:} );        end
    function D = diag(D,varargin)                , D.v = diag( D.v , varargin{:} );       end
    function D = permute(D,varargin)             , D.v = permute( D.v , varargin{:} );    end
    function D = ipermute(D,varargin)            , D.v = ipermute( D.v , varargin{:} );   end
    function D = circshift(D,varargin)           , D.v = circshift( D.v , varargin{:} );  end
    function D = flipdim(D,varargin)             , D.v = flipdim( D.v , varargin{:} );    end
    function D = fliplr(D,varargin)              , D.v = fliplr( D.v , varargin{:} );     end
    function D = flipud(D,varargin)              , D.v = flipud( D.v , varargin{:} );     end
    function D = rot90(D,varargin)               , D.v = rot90( D.v , varargin{:} );      end
    function D = shiftdim(D,varargin)            , D.v = shiftdim( D.v , varargin{:} );   end
    function D = squeeze(D,varargin)             , D.v = squeeze( D.v , varargin{:} );    end
    function D = transpose(D,varargin)           , D.v = transpose( D.v , varargin{:} );  end
    function D = ctranspose(D,varargin)          , D.v = transpose( D.v , varargin{:} );  end
    function D = tril(D,varargin)                , D.v = tril( D.v , varargin{:} );       end
    function D = triu(D,varargin)                , D.v = triu( D.v , varargin{:} );       end

    function D = cat( dim , varargin )
      for i = 1:numel(varargin)
        switch class( varargin{i} )
          case 'dual'
            varargin{i} = double( varargin{i}.v );
          case {'double','single'}
            varargin{i} = double( varargin{i}   );
          otherwise
            error('only floats can be concatenated with duals');
        end
      end
      D = dual; D.v = cat(dim, varargin{:} );
    end
    function D = horzcat( varargin )             , D = cat(2,varargin{:});                end
    function D = vertcat( varargin )             , D = cat(1,varargin{:});                end
    function D = blkdiag( varargin )
      for i = 1:numel(varargin)
        switch class( varargin{i} )
          case 'dual'
            varargin{i} = double( varargin{i}.v );
          case {'double','single'}
            varargin{i} = double( varargin{i}   );
          otherwise
            error('only floats can be concatenated with duals');
        end
      end
      D = dual; D.v = blkdiag( varargin{:} );
    end

    
    %%Elementwise-Unary functions
    function D = uplus(D,varargin)               , D.v = uplus( D.v , varargin{:} );  end
    function D = uminus(D,varargin)              , D.v = uminus( D.v , varargin{:} ); end

    function D = cos( D )
      D.v = complex( cos( rp(D) ) , - dp(D) .* sin( rp(D) ) );
    end
    function D = cosd( D )
      D.v = complex( cosd( rp(D) ) , -dp(D) .* sind( rp(D) ) * (pi/180) );
    end
    function D = acos( D )
      if ~check_pred(D, @(d)d(:)<1 , @(d)d(:)>-1 )
        error('ACOS: real values must be  ( < 1 and > -1 ) to allow perturbations.');
      end
      D.v = complex( acos( rp(D) ) , - dp(D) ./ sqrt( 1 - rp(D).^2 ) );
      D   = fix_nonumbers( D );
    end
    function D = acosd( D )
      if ~check_pred(D, @(d)d(:)<1 , @(d)d(:)>-1 )
        error('ACOSD: real values must be  ( < 1 and > -1 ) to allow perturbations.');
      end
      D.v = complex( acosd( rp(D) ) , - dp(D) ./ sqrt( 1 - rp(D).^2 ) * (180/pi) );
      D   = fix_nonumbers( D );
    end
    function D = cosh( D )
      D.v = complex( cosh( rp(D) ) , dp(D) .* sinh( rp(D) ) );
    end
    function D = acosh( D )
      if ~check_pred(D, @(d)d>1 )
        error('ACOSH: real values must be  ( > 1 ) to allow perturbations.');
      end
      D.v = complex( acosh( rp(D) ) , dp(D) ./ sqrt( rp(D).^2 - 1 )  );
      D   = fix_nonumbers( D );
    end

    function D = sin( D )
      D.v = complex( sin( rp(D) ) ,  dp(D) .* cos( rp(D) ) );
    end
    function D = asin( D )
      if ~check_pred(D, @(d)d(:)<=1 , @(d)d(:)>=-1 )
        error('ASIN: real values must be  ( < 1 and > -1 ) to allow perturbations.');
      end
      D.v = complex( asin( rp(D) ) , dp(D) ./ sqrt( 1 - rp(D).^2 ) );
      D   = fix_nonumbers( D );
    end
    function D = sind( D )
      D.v = complex( sind( rp(D) ) , dp(D) .* cosd( rp(D) ) * (pi/180) );
    end
    function D = asind( D )
      if ~check_pred(D, @(d)d(:)<1 , @(d)d(:)>-1 )
        error('ASIND: real values must be  ( < 1 and > -1 ) to allow perturbations.');
      end
      D.v = complex( asind( rp(D) ) , dp(D) ./ sqrt( 1 - rp(D).^2 ) * (180/pi) );
      D   = fix_nonumbers( D );
    end
    function D = sinh( D )
      D.v = complex( sinh( rp(D) ) , dp(D) .* cosh( rp(D) ) );
    end
    function D = asinh( D )
      D.v = complex( asinh( rp(D) ) , dp(D) ./ sqrt( rp(D).^2 + 1 )  );
      D   = fix_nonumbers( D );
    end
    
    function D = tan( D )
      if ~check_pred(D, @(d)mod( d(:)/pi*2 , 2 ) ~= 1 )
        error('TAN: real values must be ( ~= (odd)*pi/2 ) to allow perturbations.');
      end
      D.v = complex( tan( rp(D) ) , dp(D) .* sec( rp(D) ).^2 );
      D   = fix_nonumbers( D );
    end
    function D = atan( D )
      D.v = complex( atan( rp(D) ) , dp(D) ./ ( 1 + rp(D).^2 ) );
    end
    function D = tand( D )
      if ~check_pred(D, @(d)mod( d(:)/90 , 2 ) ~= 1 )
        error('TAND: real values must be ( ~= (odd)*90 ) to allow perturbations.');
      end
      D.v = complex( tand( rp(D) ) , dp(D) .* secd( rp(D) ).^2 * (pi/180) );
      D   = fix_nonumbers( D );
    end
    function D = atand( D )
      D.v = complex( atand( rp(D) ) , dp(D) ./ ( 1 + rp(D).^2 ) * (180/pi) );
    end
    function D = tanh( D )
      D.v = complex( tanh( rp(D) ) , dp(D) .* sech( rp(D) ).^2 );
    end
    function D = atanh( D )
      if ~check_pred(D, @(d)d(:)<1 , @(d)d(:)>-1 )
        error('ATANH: real values must be  ( < 1 and > -1 ) to allow perturbations.');
      end
      D.v = complex( atanh( rp(D) ) , dp(D) ./ ( 1 - rp(D).^2 ) );
      D   = fix_nonumbers( D );
    end

    function D = cot( D )
      if ~check_pred(D, @(d)mod( d(:)/pi , 1 ) ~= 0 )
        error('COT: real values must be ( ~= (k)*pi ) to allow perturbations.');
      end
      D.v = complex( cot( rp(D) ) , - dp(D) .* csc( rp(D) ).^2 );
    end
    function D = cotd( D )
      if ~check_pred(D, @(d)mod( d(:)/180 , 1 ) ~= 0 )
        error('COTD: real values must be ( ~= (k)*180 ) to allow perturbations.');
      end
      D.v = complex( cotd( rp(D) ) , -dp(D) .* cscd( rp(D) ).^2 * (pi/180) );
    end
    function D = acot( D )
      if ~check_pred(D, @(d)d~=0 )
        error('ACOT: real values must be ( ~= 0 ) to allow perturbations.');
      end
      D.v = complex( acot( rp(D) ) , - dp(D) ./ ( 1 + rp(D).^2 )  );
    end
    function D = acotd( D )
      if ~check_pred(D, @(d)d~=0 )
        error('ACOTD: real values must be ( ~= 0 ) to allow perturbations.');
      end
      D.v = complex( acotd( rp(D) ) , - dp(D) ./ ( 1 + rp(D).^2 ) * (180/pi)  );
    end
    function D = coth( D )
      if ~check_pred(D, @(d)d~=0 )
        error('COTH: real values must be ( ~= 0 ) to allow perturbations.');
      end
      D.v = complex( coth( rp(D) ) , - dp(D) .* csch( rp(D) ).^2  );
    end
    function D = acoth( D )
      if ~check_pred(D, @(d)d<-1 | d>1 )
        error('ACOTH: real values must be ( < -1 and > 1 ) to allow perturbations.');
      end
      D.v = complex( acoth( rp(D) ) , dp(D) ./ ( 1 - rp(D).^2 ) );
    end

    function D = csc( D )
      if ~check_pred(D, @(d)mod( d(:)/pi , 1 ) ~= 0 )
        error('CSC: real values must be ( ~= (k)*pi ) to allow perturbations.');
      end
      D.v = complex( csc( rp(D) ) , - dp(D) .* cot( rp(D) ) .* csc( rp(D) ) );
    end
    function D = cscd( D )
      if ~check_pred(D, @(d)mod( d(:)/180 , 1 ) ~= 0 )
        error('CSCD: real values must be ( ~= (k)*180 ) to allow perturbations.');
      end
      D.v = complex( cscd( rp(D) ) , -dp(D) .* cotd( rp(D) ) .* cscd( rp(D) ) * (pi/180) );
    end
    
    
    function D = sqrt( D )
      if ~check_pred( D , @(d)d( ~~dp(D) )>0 )
        error('SQRT: real values must be ( > 0 ) to allow perturbations.');
      end
      S = sqrt( rp(D) );
      D.v = complex( S , dp(D) ./ S / 2 );
      D   = fix_nonumbers( D );
    end
    function D = realsqrt( D )
      if ~check_pred(D, @(d)d(:)>0 )
        error('REALSQRT: real values must be ( > 0 ) to allow perturbations.');
      end
      S = realsqrt( rp(D) );
      D.v = complex( S , dp(D) ./ S / 2 );
      D   = fix_nonumbers( D );
    end
    function D = cbrt( D )
      if ~check_pred(D, @(d)d(:)>0 )
        error('CBRT: real values must be ( > 0 ) to allow perturbations.');
      end
      S = cbrt( rp(D) );
      D.v = complex( S , dp(D) ./ S.^2 / 3 );
      D   = fix_nonumbers( D );
    end

    function D = pow2( D )
      S = pow2( rp(D) );
      D.v = complex( S , dp(D) .* S * log(2) );
    end
    function D = pow10( D )
      S = pow10( rp(D) );
      D.v = complex( S , dp(D) .* S * log(10) );
    end
    
    function D = exp( D )
      S = exp( rp(D) );
      D.v = complex( S ,  dp(D) .* S );
    end
    function D = expm1( D )
      D.v = complex( expm1( rp(D) ) ,  dp(D) .* exp( rp(D) ) );
    end
    function D = log( D )
      if ~check_pred(D, @(d)d(:)>0 )
        error('LOG: real values must be ( > 0 ) to allow perturbations.');
      end
      D.v = complex( log( rp(D) ) , dp(D) ./ rp(D) );
      D   = fix_nonumbers( D );
    end
    function D = reallog( D )
      if ~check_pred(D, @(d)d(:)>0 )
        error('REALLOG: real values must be ( > 0 ) to allow perturbations.');
      end
      D.v = complex( reallog( rp(D) ) , dp(D) ./ rp(D) );
      D   = fix_nonumbers( D );
    end
    function D = log1p( D )
      if ~check_pred(D, @(d)d(:)>-1 )
        error('LOG1P: real values must be ( > -1 ) to allow perturbations.');
      end
      D.v = complex( log1p( rp(D) ) , dp(D) ./ ( 1 + rp(D) ) );
    end
    function D = log2( D )
      if ~check_pred(D, @(d)d(:)>0 )
        error('LOG2: real values must be ( > 0 ) to allow perturbations.');
      end
      D.v = complex( log2( rp(D) ) , dp(D) ./ rp(D) / log(2) );
      D   = fix_nonumbers( D );
    end
    function D = log10( D )
      if ~check_pred(D, @(d)d(:)>0 )
        error('LOG10: real values must be ( > 0 ) to allow perturbations.');
      end
      D.v = complex( log2( rp(D) ) , dp(D) ./ rp(D) / log(10) );
      D   = fix_nonumbers( D );
    end
    function D = erf( D )
      D.v = complex( erf( rp(D) ) ,     dp(D) .* exp( -rp(D).^2 ) * 2 / sqrt(pi) );
    end
    function D = erfc( D )
      D.v = complex( erfc( rp(D) ) ,  - dp(D) .* exp( -rp(D).^2 ) * 2 / sqrt(pi) );
    end
    function D = erfcx( D )
      S = erfcx( rp(D) );
      D.v = complex( S , 2 * dp(D) .* ( S .* rp(D) - (1/sqrt(pi)) )  );
    end
    function D = erfinv( D )
      if ~check_pred(D, @(d)d(:)<1 , @(d)d(:)>-1 )
        error('ERFINV: real values must be  ( < 1 and > -1 ) to allow perturbations.');
      end
      S = erfinv( rp(D) );
      D.v = complex( S , dp(D) .* exp( S.^2 ) * sqrt(pi)/2 );
    end
    function D = erfcinv( D )
      if ~check_pred(D, @(d)d(:)<2 , @(d)d(:)>0 )
        error('ERFCINV: real values must be  ( < 2 and > 0 ) to allow perturbations.');
      end
      S = erfcinv( rp(D) );
      D.v = complex( S , - dp(D) .* exp( S.^2 ) * sqrt(pi)/2 );
    end
    function D = gamma( D )
      if ~check_pred(D, @(d)( d(:)<=0 & ~mod(d(:),1) ) )
        error('GAMMA: real values must be  ( > 0 or not integer ) to allow perturbations.');
      end
      S = gamma( rp(D) );
      D.v = complex( S , dp(D) .* S .* psi( rp(D) ) );
      D   = fix_nonumbers( D );
    end
    function D = gammaln( D )
       if ~check_pred(D, @(d)d(:)>0 )
        error('GAMMALN: real values must be  ( > 0 ) to allow perturbations.');
      end
      D.v = complex( gammaln( rp(D) ) , dp(D) .* psi( rp(D) ) );
      D   = fix_nonumbers( D );
    end

    
    %%Elementwise-Binary functions
    function D = plus( A , B )
      A = dual(A); B = dual(B);
      
      D = dual; D.v = A.v + B.v;
    end
    function D = minus( A , B )
      A = dual(A); B = dual(B);
      
      D = dual; D.v = A.v - B.v;
    end
    function D = times( A , B )
      A = dual(A); B = dual(B);
      
      D = dual; D.v = complex( rp(A) .* rp(B) , rp(A) .* dp(B) + dp(A) .* rp(B) ); 
    end
    function D = rdivide( A , B )
      A = dual(A); B = dual(B);
      if ~check_pred(B, @(d)d~=0 )
        error('RDIVIDE: real values must be  ( ~= 0 ) to allow perturbations.');
      end

      %D = dual; D.v = complex( rdivide( rp(A) , rp(B) ) , - rp(A) .* dp(B) ./ rp(B).^2  +  rdivide( dp(A) , rp(B) ) );
      D = A .* hadamard_inv( B );
      D = fix_nonumbers( D );
    end
    function D = ldivide( A , B )
      A = dual(A); B = dual(B);
      if ~check_pred(A, @(d)d~=0 )
        error('LDIVIDE: real values must be  ( ~= 0 ) to allow perturbations.');
      end

      %D = dual; D.v = complex( ldivide( rp(A) , rp(B) ) , - rp(B) .* dp( A ) ./ rp(A).^2 + ldivide( rp(A) , dp(B) ) );
      D = hadamard_inv( A ) .* B;
      D = fix_nonumbers( D );
    end
    function D = power( A , B )
      A = dual(A); B = dual(B);

      S = power( rp(A) , rp(B) );
      if any( imag(S(:)) ), error('POWER: some complex results in real.'); end
      
      S1 = power( rp(A) , rp(B)-1 );
      dA = rp(B) .* dp(A);
      dB = rp(A) .* log( rp(A) ) .* dp(B);
      w = ( ~dp(B) | false( size(dB) ) ) | ~rp(A);
      dB( w ) = 0;
      if any( imag(dB(:)) ), error('POWER: some complex results in deriv.'); end
      D = dual; D.v = complex( S , S1 .* ( dA + dB ) );
    end
    function D = realpow( A , B )
      D = power( A , B );
    end
    function D = bsxfun( F , A , B )
      switch func2str(F)
        case {'plus','minus','times','rdivide','ldivide','power'}
        case {'atan2','atan2d','hypot'}
          error('niy');
        case {'max','min','rem','mod','eq','ne','lt','le','gt','ge','and','or','xor'}
          error('not allowed function to propagate perturbations');
        otherwise
          error('not valid function for bsxfun');
      end
      
      szD = max( ndims(A) , ndims(B) );
      szA = size( A ); szA( end+1:szD ) = 1;
      szB = size( B ); szB( end+1:szD ) = 1;
      szD = max( szA , szB );
      if any( szA( szA ~= szD ) ~= 1 ) || any( szB( szB ~= szD ) ~= 1 )
        error('Non-singleton dimensions of the two input arrays must match each other.');
      end
      A = dual(A); B = dual(B);
      
      A.v = repmat( A.v , szD ./ szA );
      B.v = repmat( B.v , szD ./ szB );
      
      D = F( A , B );
    end
    
    
    %%Array unary
    function D = sum(     D , varargin )  , D.v = sum( D.v , varargin{:} );    end
    function D = cumsum(  D , varargin )  , D.v = cumsum( D.v , varargin{:} ); end
    function D = mean(    D , varargin )  , D.v = mean( D.v , varargin{:} );   end
    function D = diff(    D , varargin )  , D.v = diff( D.v , varargin{:} );   end
    function D = cumprod( D , dim )
      sz = size( D.v );
      if nargin < 2, dim = find( [ sz , 2 ] > 1 , 1 ); end
      sz(end+1:dim) = 1;
      
      perm = [ 1:dim-1 , dim+1:numel(sz) , dim ];
      D.v = permute( D.v , perm ); sz = sz(perm);
      D.v = reshape( D.v , [ prod( sz(1:end-1) ) , sz(end) ] );
      
      C = dual( D.v(:,1) );
      for j = 2:sz(end)
        C = C .* D.v(:,j);
        D.v(:,j) = C.v;
      end
      
      D.v = reshape( D.v , sz );
      D.v = ipermute( D.v , perm );
    end
    function D = prod(    D , dim )
      sz = size( D.v );
      if nargin < 2, dim = find( [ sz , 2 ] > 1 , 1 ); end
      
      D = cumprod( D , dim );
      
      inds = arrayfun( @(n)1:n , size(D.v) , 'UniformOutput', false );
      inds{ dim } = size( D.v , dim );
      D.v = D.v( inds{:} );
    end
    function D = fro2( D ,dim)
      if nargin < 2
        D.v = complex( sum( real( D.v(:) ).^2 ) , 2 * sum( imag( D.v(:) ) .* real( D.v(:) ) ) );
      else      
        D.v = complex( sum( real( D.v ).^2 ,dim) , 2 * sum( imag( D.v ) .* real( D.v ) ,dim) );
      end
    end
    function D = fro( D ,varargin)
      D = sqrt( fro2( D ,varargin{:} ) );
    end
    

    %%Matrix-Unary functions
    function D = trace(D,varargin)               , D.v = trace( D.v , varargin{:} );  end
    function D = det(D)
      detD = det( rp(D) );
      
      iD = eye(size(D.v,1)) / real( D.v.' );
      dd = iD(:).' * imag( D.v(:) );
      
      D.v = complex( detD , detD * dd );
    end
    function D = inv( D )
      iD = inv( rp(D) );
      
      dd = - kron( iD.' , iD );
      dd = reshape( dd * imag( D.v(:) ) , size( D.v ) );

      D.v = complex( iD , dd );
    end
    function D = expm( D )
      n = size( D.v , 1 );
      Z = zeros( [ n , n ] );
      
      S = expm( [ rp(D) , dp(D) ; Z , rp(D) ] );
      D.v = complex( S( 1:n , 1:n ) , S( 1:n , (n+1):end ) );
    end
    function D = logm( D )
      n = size( D.v , 1 );
      Z = zeros( n , n );
      
      S = logm( [ rp(D) , dp(D) ; Z , rp(D) ] );
      D.v = complex( S( 1:n , 1:n ) , S( 1:n , (n+1):end ) );
    end
    function D = sqrtm( D )
      n = size( D.v , 1 );
      Z = zeros( n , n );
      
      S = sqrtm( [ rp(D) , dp(D) ; Z , rp(D) ] );
      D.v = complex( S( 1:n , 1:n ) , S( 1:n , (n+1):end ) );
    end

    
    %%Matrix-binary functions
    function D = mtimes( A , B )
      A = dual(A);
      B = dual(B);
      if ~is2D( A ) || ~is2D( B ), error('only 2D matrices allowed'); end
      if isscalar( A.v ), D = times( A , B ); return; end
      if isscalar( B.v ), D = times( A , B ); return; end
      
      zA = zeros( size( A.v ) );
      zB = zeros( size( B.v ) );
      
      P = [ real( A.v ) , imag( A.v ) ; zA , real( A.v ) ] * [ real( B.v ) , imag( B.v ) ; zB , real( B.v ) ];
      D = dual;
      D.v = complex( P( 1:size(A.v,1) , 1:size(B.v,2) ) , P( 1:size(A.v,1) , (size(B.v,2)+1):end ) );
    end
    function P = mpower( D , n )
      if isa( n , 'dual' ), error('exponente dual?'); end
      if mod(n,1), error('por ahora solo exponentes enteros'); end
      if n == 0, P = dual( rp(D)^0 ); return; end
        
      P = D;
      for i = 2:abs(n), P = P * D; end
      if n < 0, P = inv( P ); end
    end
    function D = mrdivide(A,B)      , D = A * inv( B );                end
    function D = mldivide(A,B)      , D = inv( A ) * B;                end
    function D = kron( X , Y )
      X = dual( X );
      Y = dual( Y );

      K  = kron( real( X.v ) , real( Y.v ) );

      d1 = reshape( d_kron_1( real(X.v) , real(Y.v) ) * imag( X.v(:) ) , size( K ) );
      d2 = reshape( d_kron_2( real(X.v) , real(Y.v) ) * imag( Y.v(:) ) , size( K ) );

      D = dual;
      D.v = complex( K , d1 + d2 );
    end

    function D = abs(D)
      w = rp(D) < 0;
      D.v(w) = -D.v(w);
    end
    function D = ipd( A , B )
      if isempty( B ), B = A; end
      A = dual(A); B = dual(B);
      
      A.v = permute( A.v , [1 3 2] );
      B.v = permute( B.v , [3 1 2] );
      D = sqrt( sum( bsxfun(@minus,A,B).^2 ,3) );
    end
    function D = min( A , B )
      A = dual(A); B = dual(B);
      
      w = rp(A) > rp(B);
      A.v( w ) = B.v( w );
      
      D = A;
    end
    function out       = isfinite(D,varargin)    , out = true; end
    function w = lt( A , B )
      A = dual(A); B = dual(B);
      w = lt( rp(A) , rp(B) );
    end
    function D = pinv( D )
      D = inv( D.' * D ) * D.';
    end
    
    
    
    %%metodos que faltan
% % % csc             sec
% % % acsc            asec
% % % cscd            secd
% % % acscd           asecd
% % % csch            sech
% % % acsch           asech
% % % 
% % % atan2
% % % angle
% % % 
% % % 
% % % trapz
% % % cumtrapz
% % % 
% % % %de dudosa rigurosidad
% % % abs
% % % fft
% % % fftn
% % % filter
% % % hypot
% % % ifft
% % % ifftn
% % % max
% % % min
% % % nnz
% % % nonzeros
% % % sign
% % % sort
% % % issorted
% % % ilu
% % % ldl
% % % find
% % % le
% % % lt
% % % eq
% % % ge
% % % gt
% % % ne
% % % median
% % % prctile
% % % all
% % % any
% % % 
% % % %funciones de matrices
% % % pinv
% % % linsolve
% % % eig
% % % svd
% % % chol
% % % rcond
% % % qr
% % % qz
% % % schur
% % % lu
% % % hess
% % % 
% % % %requieren programar
% % % var
% % % std
% % % conv2
% % % norm
% % % 
% % % 
% % % 
% % % 
% % % %otras
% % % imfilter
% % % accumarray
% % % arrayfun
% % % cross
% % % dot
% % % idivide
% % % sortrows
% % % toeplitz
% % % vander
% % % wilkinson
% % % compan
% % % hankel
% % % hilb
% % % invhilb
% % % cond
% % % condeig
% % % normest
% % % null
% % % orth
% % % rank
% % % rref
% % % condest
% % % lscov
% % % lsqnonneg
% % % luinc
% % % cdf2rdf
% % % eigs
% % % gsvd
% % % poly
% % % polyeig
% % % rsf2csf
% % % svds
% % % cholinc
% % % planerot
% % % nthroot
% % % cplxpair
% % % unwrap
% % % ceil
% % % fix
% % % floor
% % % mod
% % % rem
% % % round
% % % conv
% % % deconv
% % % polyder
% % % polyfit
% % % polyint
% % % polyval
% % % polyvalm
% % % residue
% % % roots
% % % fzero
% % % dblquad
% % % quad
% % % quadgk
% % % quadl
% % % quadv
% % % triplequad
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
% % % ellipke
% % % expint
% % % legendre
% % % psi
% % % corrcoef
% % % cov
% % % mode
% % % convn
% % % detrend
% % % filter2
% % % interp1
% % % interp2
% % % interp3
% % % interpn
% % % fft2
% % % fftshift
% % % fftw
% % % ifft2
% % % ifftshift
% % % del2
% % % gradient
% % % class
% % % intwarning
% % % double
% % % int8
% % % int16
% % % int32
% % % int64
% % % single
% % % uint8
% % % uint16
% % % uint32
% % % uint64
% % % <
% % % <=
% % % >
% % % >=
% % % ==
% % % ~=
% % % &&
% % % ||
% % % &
% % % |
% % % ~
% % % bitand
% % % bitcmp
% % % bitget
% % % bitmax
% % % bitor
% % % bitset
% % % bitshift
% % % bitxor
% % % and
% % % iskeyword
% % % isvarname
% % % logical
% % % not
% % % or
% % % true
% % % xor
% % % intersect
% % % ismember
% % % setdiff
% % % setxor
% % % union
% % % unique
% % % echo
% % % loadobj
% % % saveobj
% % % plot
% % % line
% % % patch
% % % rectangle
% % % surface
% % % methods
% % % methodsview
% % % colon
% % % linspace
% % % gammainc
% % % 
% % % 
% % % isequalwithequalnans
% % % isfloat
% % % isinf
% % % isinteger
% % % islogical
% % % isnan
% % % isnumeric
% % % issparse
% % % isreal
% % % fieldnames
% % % getfield
% % % isfield
% % % isstruct
% % % orderfields
% % % rmfield
% % % setfield
    
  end
  
  
  
  methods ( Access = private , Hidden = true )
    function r = rp( varargin )
      if     nargin == 0                 , r = [];
      elseif nargin > 1                  , r = cellfun( @rp , varargin    ,'UniformOutput',false);
      elseif iscell( varargin{1} )       , r = cellfun( @rp , varargin{1} ,'UniformOutput',false);
      elseif isa( varargin{1} , 'dual' ) , r = double( real( varargin{1}.v ) );
      else                               , r = double( varargin{1} );
      end
    end
    function d = dp( varargin )
      if     nargin == 0                 , d = [];
      elseif nargin > 1                  , d = cellfun( @dp , varargin    ,'UniformOutput',false);
      elseif iscell( varargin{1} )       , d = cellfun( @dp , varargin{1} ,'UniformOutput',false);
      elseif isa( varargin{1} , 'dual' ) , d = double( imag( varargin{1}.v ) );
      else                               , d = zeros( size( varargin{1} ) );
      end
    end
    function out = areDUALS( varargin )
      out = cellfun( @(D)isa(D,'dual') , varargin );
      out = char( out(:).' + 48 );
    end
    function out = is2D( D )
      out = false;
      if isa( D , 'dual' ), D = D.v; end
      if ndims( D ) > 2, return; end
      out = true;
    end
    function out = issq( D )
      out = false;
      if isa( D , 'dual' ), D = D.v; end
      if ndims( D ) > 2, return; end
      if size( D , 1 ) ~= size( D , 2 ), return; end
      out = true;
    end
    function D = hadamard_inv( D )
      S = 1 ./ rp(D);
      D.v = complex( S , - dp(D) .* ( S.^2 ) );
    end
    function D = fix_nonumbers( D )
      d = imag( D.v );
      D.v( isnan(d) ) = 0;
      D.v( isinf(d) & d > 0 ) =  3.4028235677973362e38;
      D.v( isinf(d) & d < 0 ) = -3.4028235677973362e38;
    end      
    function out = check_pred( D , varargin )
      out = false;
      d = real( D.v );
      for i = 1:numel(varargin)
        if ~all( feval( varargin{i} , d ) )
          return;
        end
      end
      out = true;
    end
  end
    
end
