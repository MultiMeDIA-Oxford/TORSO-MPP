function [M,E] = KarcherMean( Xs , M , EXP_fun , LOG_fun , invariance )

  VERBOSE = false;


  if nargin < 5, invariance = 'L'; end
  if ~ischar( invariance ), error('invariance  must be ''L''  or  ''R''.'); end
  invariance = upper( invariance(1) );
  if invariance ~= 'L'  &&  invariance ~= 'R', error('invariance  must be ''L''  or  ''R''.'); end

  

  if nargin < 3, error('use  KarcherMean( Xs , M , EXP_fun , LOG_fun )  or  KarcherMean( Xs , EXP_fun , LOG_fun )'); end
  if isa( M , 'function_handle' )
    if nargin > 3, invariance = LOG_fun; end
    LOG_fun = EXP_fun;
    EXP_fun = M;
    M       = [];
  end


  
  
  
  if any( ~isfinite( M(:) ) ) || det(M) < 0
    M = [];
  end

  W = 1;
  if iscell( Xs )
    W  = Xs{2};
    Xs = Xs{1};
  end

  N = size( Xs , 3 );

  if isscalar(W), W = ones(N,1)*W; end
  if numel(W) ~= N, error('size  weigths  do not coincide with number of instances'); end
  W = vec(W,3);
  
  z  = ~isfinite( W ) | ~W;
  W(z) = [];
  Xs(:,:,z) = [];

  N = size( Xs , 3 );
  
  V = zeros( size( Xs ) );
  D = zeros( size( W  ) );
  
  id = 0;
  if isempty( M )
    if var( W ) == 0
      
      M = Xs(:,:,1);
      for n = 2:N
        [dd,U] = LOG( M , Xs(:,:,n) );
        M      = EXP( M , 1/n * U );
      end
      
    else

      [id,id] = max( W );
      M = Xs(:,:,id);

    end
  end
  for n = [ 1:(id-1) , (id+1):N ], [ D(n) , V(:,:,n) ] = LOG( M , Xs(:,:,n) ); end, E = sum( D.^2 .* W );
  E0 = E;
  vprintf('E0        : %20.20g\n',E);
  
  alpha = 0.9;
  while 1
    G = 2 * sum( bsxfun( @times , V , W ) , 3 )/sum(W(:));
    Mp = M;     Ep = E;
    
    vprintf('E_start_ls: %20.20g\n',E);
    
    alpha = alpha / 0.9;
    while 1
      M = EXP( Mp , alpha * G );
      if isequal( M , Mp ), vprintf('M == Mp,  break bt\n'); break;  end
      
      for n = 1:N, [ D(n) , V(:,:,n) ] = LOG( M , Xs(:,:,n) ); end, E = sum( D.^2 .* W );
      vprintf('bt          %20.20g   ( %20.20g )\n',E,alpha);

      if E < Ep, vprintf('E < Ep,  break bt\n'); break; end

      alpha = alpha * 0.75;
      if alpha < 1e-8,
        vprintf('alpha < 1e-14,  fast reduce\n');
        alpha = alpha / 0.75 * 0.1;
      end
%       if alpha < 1e-14,
%         vprintf('alpha < 1e-14,  break bt\n');
%         M = Mp;
%         break; 
%       end
    end
    
    
    
    
    vprintf('E_start_ex: %20.20g\n',E);

    Ebt = E; Mbt = M; Vbt = V; alpha = alpha*0.5;
    while 1
      M = EXP( Mp , alpha * G );
      if isequal( M , Mbt ), vprintf('M == Mbt,  break ex\n'); break;  end
      
      for n = 1:N, [ D(n) , V(:,:,n) ] = LOG( M , Xs(:,:,n) ); end, E = sum( D.^2 .* W );
      vprintf('ex          %20.20g   ( %20.20g )\n',E,alpha);

      if E >= Ebt, vprintf('E >= Ebt,  break ex\n'); break; end
      Ebt = E; Mbt = M; Vbt = V; alpha = alpha*0.5;
    end
    E = Ebt; M = Mbt; V = Vbt; alpha = alpha/0.5;
    
    
    
    vprintf('E_end_ls  : %20.20g       %4.18g%%\n\n',E,E/Ep*100);

    if isequal( M , Mp ), vprintf('stucked,  break all\n'); break; end

  end

  vprintf('E_final   : %20.20g       %4.18g%%\n\n',E,E/E0*100);

  
  
  function Q = EXP( A , VV )
    if      invariance == 'L'
      Q = A * EXP_fun( A \ VV     );
    elseif  invariance == 'R'
      Q =     EXP_fun(     VV / A ) * A;
    end
  end

  function [d,VV] = LOG( A , B )
    if      invariance == 'L'
      [ d , VV ] = LOG_fun( A \ B     );
      VV = A * VV;
    elseif  invariance == 'R'
      [ d , VV ] = LOG_fun(     B / A );
      VV = VV * A;
    end
  end
  function vprintf( varargin )
    if VERBOSE
      fprintf( varargin{:} );
    end
  end

  
end
