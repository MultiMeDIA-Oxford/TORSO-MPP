function [Q,R,rms] = fitPDM_to_points_new( PDM , TARGET , Rtype , varargin )

  persistent last_M  last_iM

  if 0
  elseif isa( PDM , 'struct' )
    
    m = PDM.xyzm;
    M = PDM.xyzM; M = reshape( M , [ numel(m) , numel(M)/numel(m) ] );
  
  elseif iscell( PDM )

    M = PDM{1};
    m = PDM{2};

  elseif isa( PDM , 'function_handle' )

    f  = functions( PDM );
    m  = f.workspace{1}.m; %m = reshape( m , size(PDM(0)));
    M  = f.workspace{1}.M;
    
  end

  if ~isequal( size(m) , size(TARGET) )
    error('no equal size of PDM and TARGET.');
  end

  
  methods = {'affine','iterative'};
  try, [varargin,~,methods] = parseargs(varargin,'methods','$DEFS$',methods); end
  if ~iscell( methods ), methods = { methods }; end
  
  
  nMODES = [];
  try, [varargin,~,nMODES] = parseargs(varargin,'NMODES','$DEFS$',nMODES); end
  
  Q = [];
  try, [varargin,~,Q] = parseargs(varargin,'Q','INITial','$DEFS$',Q); end
  Q = Q(:);

  RANGE = Inf;
  try, [varargin,~,RANGE] = parseargs(varargin,'RANGE','$DEFS$',RANGE); end
  
  
  MAX_ITS = 5e3;
  try, [varargin,~,MAX_ITS] = parseargs(varargin,'maxITS','$DEFS$',MAX_ITS); end
  

  if 0
  elseif ~isempty( nMODES ) &&  isempty( Q )
    if size( M ,2) < nMODES, error('size(M,2) < nMODES'); end
    M = M(:,1:nMODES);
    Q = zeros( size(M,2) ,1);
  elseif  isempty( nMODES ) &&  isempty( Q )
    Q = zeros( size(M,2) ,1);
  elseif ~isempty( nMODES ) && ~isempty( Q )
    if size( M ,2) < nMODES, error('size(M,2) < nMODES'); end
    M = M(:,1:nMODES);
    if nMODES < numel(Q)
      error('or c_initial or nMODES');
    end
    Q( end+1:nMODES ) = 0;
  elseif  isempty( nMODES ) && ~isempty( Q )
    nMODES = numel( Q );
    if size( M ,2) < nMODES, error('size(M,2) < nMODES'); end
    M = M( : ,1:nMODES );
  end
 
  w = all( isfinite( TARGET ) ,2);
  if ~all(w)
    TARGET = TARGET( w ,:);
    M = reshape( M , [ size(m) , size(M,2) ] );
    M = M( w ,:,:);
    m = m( w ,:);
    M = reshape( M , [ size(m,1) * size(m,2) , size(M,3) ] );
  end
  
  
  S = @(Q)reshape( M*Q , size(m) ) + m;
  nP  = size(TARGET,1);


  
  for met = methods(:).', met = met{1};
    switch lower( met )
      case {'affine','a'}
        C = eye(nP) - ones(nP)/nP;
        Cx = bsxfun( @minus , TARGET , mean(TARGET,1) );
        D = Cx*pinv(Cx.'*Cx)*(Cx.'*C) - C;

        Vm = D*m; Vm = Vm(:);
        VM = reshape( D * reshape( M ,size(D,2),[] ) ,[],size(M,2) );

        if isinf( RANGE )
          Q = - pinv( VM.' * VM ) * ( VM.' * Vm );
        else
          lb = zeros(size(Q)) - RANGE;
          ub = zeros(size(Q)) + RANGE;
          [Q] = quadprog( VM'*VM , VM'*Vm ,[],[],[],[],lb,ub,[],optimset('Display','none'));
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
          it = it+1;
          if it > MAX_ITS, break; end
          cp = Q;
          iP = MatchPoints( S(Q) , TARGET , Rtype );
          xx = bsxfun( @plus , TARGET * iP(1:end-1,1:end-1).' , iP(1:end-1,end).' );
          Q = iM * ( xx(:) - m(:) );
          if ~isinf( RANGE ), Q = clamp( Q , -RANGE , RANGE ); end
          dif = max( abs( cp(:) - Q(:) ) );
          if ~rem(it,500), fprintf('it: %3d    ( %g )\n', it , dif ); end
          if dif == 0, break; end
          if dif < 1e-12, break; end
          if it > 1e5, break; end
        end
        
      case {'optimize','o'}
        
        if isequal( lower( Rtype ) , 'gt' )

          nP  = size(TARGET,1);
          C   = eye(nP) - ones(nP)/nP;
          Y   = C*TARGET;
          Cm  = C*m;
          CM  = reshape( C * reshape( M ,size(C,2),[] ) ,[],size(M,2) );
          
%           p = size(Cm,1); q = size(Cm,2);
%           comm = @(m,n)sparse( reshape(1:m*n,m,n) , reshape(1:m*n,m,n)' , 1 , m*n , m*n );
%           Tp = comm( p , p ) + speye( p * p );
%           Tq = comm( q , q ) + speye( q * q );
%           TRmat = - sparse( [1 1 1] , [1 5 9] ,1,1,9 )*kron( Y.' , Y.' );
          

          Q = iApplyContraints( Q , RANGE );
          Q = Optimize( @(c)FUN_GT( c , RANGE ) , Q ,...
              'methods',{'conjugate'},...
              'ls',{'quadratic'},...
              'noplot','verbose',0,...
              struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}}) );
          Q = ApplyContraints( Q , RANGE );

        else
          
          if isinf( RANGE )
            Q = Optimize( @(c)FUN(c) , Q ,...
                'methods',{'conjugate','coordinate',4},...
                'ls',{'quadratic','golden','quadratic'},...
                'noplot','verbose',0 ,...
                struct('COMPUTE_NUMERICAL_JACOBIAN',{{'f'}},'MAX_ITERATIONS',100+Inf) );
          else
            Q = iApplyContraints( Q , RANGE );
            Q = Optimize( @(c)FUN( ApplyContraints( c , RANGE ) ) , Q ,...
                'methods',{'conjugate','coordinate',4},...
                'ls',{'quadratic','golden','quadratic'},...
                'noplot','verbose',0);
            Q = ApplyContraints( Q , RANGE );
          end
          
        end
          
      otherwise
        error('unknown method');
    end
  end
  
  R = MatchPoints( TARGET , S(Q) , Rtype );

  if nargout > 2
    y = transform( S(Q) , R );
    rms = sqrt( fro2( TARGET - y )/nP );
  end
    
  function err = FUN( c )
    [~,~,err] = MatchPoints( TARGET , S(c) , Rtype );
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