function [t2,p] = hotellingst2test2( A , B , varargin )
%{

A =   rand(2,30,1);
B = 2*rand(2,20,1)+0.01;

[~,pm] = hotellingst2test2( A , B ,'mnv');disp(pm(:)')

[~,py] = hotellingst2test2( A , B ,'yao');disp(py(:)')

[~,pj] = hotellingst2test2( A , B ,'johansen');disp(pj(:)')

[~,pp] = hotellingst2test2( A , B ,'perm',5e5);disp(pp(:)')

%}


  dimC = 1;  % each row means a component of the vector
  dimS = 2;  % each subject is a column
  dimT = 3;  % each plane is a different test to be performed

  if ndims(A) ~= ndims(B)        , error('different ndims in A and B.'); end
  if ndims(A) > 3                , error('more than 3 dimensions are not allowed.'); end
  if size(A,dimC) ~= size(B,dimC), error('A and B must have the same number of components.');  end
  if size(A,dimT) ~= size(B,dimT), error('A and B have different number of test.'); end
  
  k = size( A , dimC ); 

  PERM_ = unique([dimS , dimC , 1:ndims(A)],'stable');
  OPTS_linsolve = struct('SYM',true,'POSDEF',true);
  nA = size( A , dimS ); inA = 1./nA;
  nB = size( B , dimS ); inB = 1./nB;

  for tt = 1:size(A,dimT)
    t2(1,1,tt) = T2( A(:,:,tt) , B(:,:,tt) );
  end
  
  if nargout > 1
    PVALUETYPE = 'MNV';
    [varargin,PVALUETYPE] = parseargs(varargin,'PARAMetric','mnv','$FORCE$',{'MNV',PVALUETYPE});
    [varargin,PVALUETYPE] = parseargs(varargin,'yao',             '$FORCE$',{'YAO',PVALUETYPE});
    [varargin,PVALUETYPE] = parseargs(varargin,'johansen',        '$FORCE$',{'JOHANSEN',PVALUETYPE});

    NP = 1e3;
    [varargin,i,NP] = parseargs(varargin,'PERMutation','$DEFS$',NP); if i, PVALUETYPE = 'permutation'; end

    p = NaN( size(t2) );
    switch lower(PVALUETYPE)
      case 'mnv'
        for tt = 1:numel(p)
          p(1,1,tt) = MNVtest( A(:,:,tt) , B(:,:,tt) );
        end
        
      case 'yao'
        for tt = 1:numel(p)
          p(1,1,tt) = YAOtest( A(:,:,tt) , B(:,:,tt) );
        end
        
      case 'johansen'
        I    = eye(k);
        for tt = 1:numel(p)
          p(1,1,tt) = JOHANSENtest( A(:,:,tt) , B(:,:,tt) );
        end
        
      case 'permutation'
        rand('state',0);
        SPLITS = generaSPLITS( NP , nA , nB );
    
        A = permute( A , PERM_ );
        B = permute( B , PERM_ );
        dimS  = PERM_( dimS );
        dimC  = PERM_( dimC );
        PERM_ = unique([dimS , dimC , 1:ndims(A)],'stable');
        
        for tt = 1:numel(p)
          disp(tt);
          Pfcn = permutations( cat(dimS,A(:,:,tt),B(:,:,tt)) , SPLITS , @(varargin)T2(varargin{:}) );
          p(1,1,tt) = Pfcn( t2(1,1,tt) );
        end
        
    end
  end
  
  function p = MNVtest( A , B )
    mA   = mean( A , dimS );
    SA   = SYM( cov( permute( A , PERM_ ) ,0));
    SA_  = SYM( inA * SA );
    
    mB   = mean( B , dimS );
    SB   = SYM( cov( permute( B , PERM_ ) ,0) );
    SB_  = SYM( inB * SB );
    
    d    = mA(:) - mB(:);

    S_   = SYM( SA_ + SB_ );
    iS_d = INV( S_ , d );
    t2   = d.' * iS_d;
    
    iS_  = INV( S_ );
    
    nu   = 0;
    M    = SA_ * iS_;
    nu   = nu+ ( trace( M^2 ) + trace( M )^2 )*inA;
    M    = SB_ * iS_;
    nu   = nu+ ( trace( M^2 ) + trace( M )^2 )*inB;
    nu   = (k+k^2)/nu;
    
    p    = 1 - fcdf( t2 * (nu-k+1) / (nu*k) , k , nu - k + 1 );
  end
  
  function p = JOHANSENtest( A , B )
    mA   = mean( A , dimS );
    SA   = SYM( cov( permute( A , PERM_ ) ,0));
    SA_  = SYM( inA * SA );
    
    mB   = mean( B , dimS );
    SB   = SYM( cov( permute( B , PERM_ ) ,0) );
    SB_  = SYM( inB * SB );
    
    d    = mA(:) - mB(:);

    S_   = SYM( SA_ + SB_ );
    iS_d = INV( S_ , d );
    t2   = d.' * iS_d;
    
    iSA_ = INV( SA_ );
    iSB_ = INV( SB_ );
    SS   = INV( iSA_ + iSB_  );
    
    D    = 0;
    M    = ( I - SS * iSA_ );
    D    = D+ ( trace( M^2 ) + trace( M )^2 )/(nA-1);
    M    = ( I - SS * iSB_ );
    D    = D+ ( trace( M^2 ) + trace( M )^2 )/(nB-1);
    D    = D/2;
    
    q    = k + 2*D - 6*D/(k*(k-1)+2);
    nu   = k*(k+2)/(3*D);
    
    p    = 1 - fcdf( t2 / q , k , nu );
  end

  function p = YAOtest( A , B )
    mA   = mean( A , dimS );
    SA   = SYM( cov( permute( A , PERM_ ) ,0));
    SA_  = SYM( inA * SA );
    
    mB   = mean( B , dimS );
    SB   = SYM( cov( permute( B , PERM_ ) ,0) );
    SB_  = SYM( inB * SB );
    
    d    = mA(:) - mB(:);

    S_   = SYM( SA_ + SB_ );
    iS_d = INV( S_ , d );
    t2   = d.' * iS_d;
    
    nu   = 0;
    nu   = nu+ inA * ( iS_d.' * SA_ * iS_d / t2 )^2;
    nu   = nu+ inB * ( iS_d.' * SB_ * iS_d / t2 )^2;
    nu   = 1 / nu;
    
    p    = 1 - fcdf( t2 * (nu-k+1) / (nu*k) , k , nu - k + 1 );
  end
  
  function t2 = T2( A , B )
    mA   = mean( A , dimS );
    SA   = SYM( cov( permute( A , PERM_ ) ,0));
    SA_  = SYM( inA * SA );
    
    mB   = mean( B , dimS );
    SB   = SYM( cov( permute( B , PERM_ ) ,0) );
    SB_  = SYM( inB * SB );
    
    d    = mA(:) - mB(:);

    S_   = SYM( SA_ + SB_ );
    iS_d = INV( S_ , d );
    t2   = d.' * iS_d;
  end

  function F = permutations( X , SPLITS , Tfcn )
    NP = size( SPLITS , 2 );
    ts = NaN( NP , 1 );
    for pp = 1:NP
      ts(pp) = feval( Tfcn , X( SPLITS(:,pp),:,1) , X(~SPLITS(:,pp),:,1) );
    end
    
    ts = sort( ts );
    ps = log10( linspace( 1 , (1/NP) , numel(ts) ).' );
    
    [kk,id1] = unique( ts , 'first' );
    [kk,id2] = unique( ts , 'last'  );
    e = ~( id1 == id2 ); id1 = id1(e); id2 = id2(e);
    for i = 1:numel(id1)
      ts( id2(i) ) = nextnum( ts(id2(i)) , 2 );
      ts( (id1(i)+1):(id2(i)-1) ) = NaN;
    end
    e = ~isnan( ts ); ts = ts(e); ps = ps(e);
    
    F = @(tvalue)pow10( Interp1D(ps,ts,tvalue,'linear','closest') );
  end
  
  function X = SYM( X )
    X = ( X + X.' )/2;
  end
  function X = INV( X , d )
    if nargin > 1
      X = linsolve( ( X + X.' ) , d            , OPTS_linsolve )*2;
    else
      X = linsolve( ( X + X.' ) , eye(size(X)) , OPTS_linsolve );
      X = ( X + X.' );
    end
  end

end
