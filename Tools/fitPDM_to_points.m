function [c,P,rms] = fitPDM_to_points( PDM , x , Ptype , varargin )

  persistent last_M  last_iM

  
  
  if iscell( PDM )

    M = PDM{1};
    m = PDM{2};

  elseif isa( PDM , 'function_handle' )

    f  = functions( PDM );
    m  = f.workspace{1}.m; %m = reshape( m , size(PDM(0)));
    M  = f.workspace{1}.M;

  end

  if ~isequal( size(m) , size(x) )
    error('no equal size of PDM and x');
  end

  
  methods = {'affine','iterative'};
  try, [varargin,~,methods] = parseargs(varargin,'methods','$DEFS$',methods); end
  if ~iscell( methods ), methods = { methods }; end
  
  
  nMODES = [];
  try, [varargin,~,nMODES] = parseargs(varargin,'NMODES','$DEFS$',nMODES); end
  
  c = [];
  try, [varargin,~,c] = parseargs(varargin,'C','INITial','$DEFS$',c); end
  c = c(:);

  RANGE = Inf;
  try, [varargin,~,RANGE] = parseargs(varargin,'RANGE','$DEFS$',RANGE); end

  if 0
  elseif ~isempty( nMODES ) &&  isempty( c )
    if size( M ,2) < nMODES, error('size(M,2) < nMODES'); end
    M = M(:,1:nMODES);
    c = zeros( size(M,2) ,1);
  elseif  isempty( nMODES ) &&  isempty( c )
    c = zeros( size(M,2) ,1);
  elseif ~isempty( nMODES ) && ~isempty( c )
    if size( M ,2) < nMODES, error('size(M,2) < nMODES'); end
    M = M(:,1:nMODES);
    if nMODES < numel(c)
      error('or c_initial or nMODES');
    end
    c( end+1:nMODES ) = 0;
  elseif  isempty( nMODES ) && ~isempty( c )
    nMODES = numel( c );
    if size( M ,2) < nMODES, error('size(M,2) < nMODES'); end
    M = M( : ,1:nMODES );
  end
 
  
  S = @(c)reshape( M*c , size(m) ) + m;
  nP  = size(x,1);


  
  for met = methods(:).', met = met{1};
    switch lower( met )
      case {'affine','a'}
        C = eye(nP) - ones(nP)/nP;
        Cx = bsxfun( @minus , x , mean(x,1) );
        D = Cx*pinv(Cx.'*Cx)*(Cx.'*C) - C;

        Vm = D*m; Vm = Vm(:);
        VM = reshape( D * reshape( M ,size(D,2),[] ) ,[],size(M,2) );

        if isinf( RANGE )
          c = - pinv( VM.' * VM ) * ( VM.' * Vm );
        else
          lb = zeros(size(c)) - RANGE;
          ub = zeros(size(c)) + RANGE;
          [c] = quadprog( VM'*VM , VM'*Vm ,[],[],[],[],lb,ub,[],optimset('Display','none'));
        end

      case {'iterative','i'}

        if isequal( last_M , M )
          iM = last_iM;
        else
          iM = pinv(M);
          last_M  = M; last_iM = iM;
        end
        
        it = 0;
        while 1
          it = it+1; %if it > 500, break; end
          cp = c;
          iP = MatchPoints( S(c) , x , Ptype );
          xx = bsxfun( @plus , x * iP(1:end-1,1:end-1).' , iP(1:end-1,end).' );
          c = iM * ( xx(:) - m(:) );
          if ~isinf( RANGE ), c = clamp( c , -RANGE , RANGE ); end
          dif = max( abs( cp(:) - c(:) ) );
          if ~rem(it,500), fprintf('it: %3d    ( %g )\n', it , dif ); end
          if dif == 0, break; end
          if dif < 1e-12, break; end
        end
        
      case {'optimize','o'}
        
        if isequal( lower( Ptype ) , 'gt' )

          nP  = size(x,1);
          C   = eye(nP) - ones(nP)/nP;
          Y   = C*x;
          Cm  = C*m;
          CM  = reshape( C * reshape( M ,size(C,2),[] ) ,[],size(M,2) );
          
%           p = size(Cm,1); q = size(Cm,2);
%           comm = @(m,n)sparse( reshape(1:m*n,m,n) , reshape(1:m*n,m,n)' , 1 , m*n , m*n );
%           Tp = comm( p , p ) + speye( p * p );
%           Tq = comm( q , q ) + speye( q * q );
%           TRmat = - sparse( [1 1 1] , [1 5 9] ,1,1,9 )*kron( Y.' , Y.' );
          

          c = iApplyContraints( c , RANGE );
          c = Optimize( @(c)FUN_GT( c , RANGE ) , c ,...
              'methods',{'conjugate'},...
              'ls',{'quadratic'},...
              'noplot','verbose',0,...
              struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}}) );
          c = ApplyContraints( c , RANGE );

        else
          
          if isinf( RANGE )
            c = Optimize( @(c)FUN(c) , c ,...
                'methods',{'conjugate','coordinate',4},...
                'ls',{'quadratic','golden','quadratic'},...
                'noplot','verbose',0 ,...
                struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}},'MAX_ITERATIONS',100+Inf) );
          else
            c = iApplyContraints( c , RANGE );
            c = Optimize( @(c)FUN( ApplyContraints( c , RANGE ) ) , c ,...
                'methods',{'conjugate','coordinate',4},...
                'ls',{'quadratic','golden','quadratic'},...
                'noplot','verbose',0);
            c = ApplyContraints( c , RANGE );
          end
          
        end
          
      otherwise
        error('unknown method');
    end
  end
  
  P = MatchPoints( x , S(c) , Ptype );

  if nargout > 2
    y = transform( S(c) , P );
    rms = sqrt( fro2( x - y )/nP );
  end
    
  function err = FUN( c )
    [~,~,err] = MatchPoints( x , S(c) , Ptype );
  end

  function E = FUN_GT( c , RANGE )
    if ~isinf( RANGE )
      c0 = c;
      c = RANGE * tanh( c / RANGE );
    end
    
    Z = reshape( CM * c ,size(Cm) ) + Cm;
    ZZ = Z.' * Z;

    ZY = Z.' * Y;
    T = ZY.' * ( ZZ \ ZY );
    E = - T(1) - T(5) - T(9);

    return
    
    if nargout > 1

      ZiZZ = Z/(ZZ);
      
      %NumericalDiff( @(c)FUN_GT(c,RANGE) , c0 , 'd' )
      D = TRmat * Tp * kron( ZiZZ , speye(p) ) * CM  -...
          TRmat * kron( ZiZZ , ZiZZ ) * Tq * kron( speye(q) , Z ).' * CM;
        
      if ~isinf( RANGE )
        D = D .* ( sech( c0 / RANGE ).^2.' );
      end

    end
    
  end


end

function z = iApplyContraints( z , r )
  if isinf( r ), return; end
  z = min( 20 * r , abs( r * atanh( z / r ) ) ) .* sign( z );
end
function z = ApplyContraints( z , r )
  if isinf( r ), return; end
  z = r * tanh( z / r );
end