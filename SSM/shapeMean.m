function [ M , SA ] = shapeMean( SS , varargin )

  try
    nV  = size( SS(1).xyz ,1);
    nsd = size( SS(1).xyz ,2);
    if ~isfield( SS , 'tri' ), SS.tri = []; end
    F   = SS(1).tri;
    for s = 2:numel(SS)
      if size( SS(s).xyz ,1) ~= nV,   
        error('not equal number of vertices.'); end
      if size( SS(s).xyz ,2) ~= nsd,  
        error('not equal nsd.'); end
      if ~isequal( SS(s).tri , F ),   
        error('not equal faces.'); end
    end
  catch LE
    error('Something is wrong with the shape set.');
  end


  [varargin,~,TTYPE] = parseargs(varargin,'transform','$DEFS$','Mt');
  [varargin,AT_END_SCALE ] = parseargs(varargin,'scale' ,'$FORCE$',{true,false});
  [varargin,AT_END_ORIENT] = parseargs(varargin,'orient','$FORCE$',{true,false});

  
  nSS = numel( SS );
  SCALES = ones( nSS , 1 );
  for s = 1:nSS, SCALES(s) = fro( SS(s).xyz ); end
  SCALES = pow2( round( log2(  exp( mean( log( SCALES ) ) )  ) ) );
  sSS = SS;
  for s = 1:nSS, sSS(s).xyz = sSS(s).xyz/SCALES; end

  try
    %error('a');
    w = unique( round( linspace( 1 , nSS , 100 ) ) );
    
    M = zeros( nV * nsd , numel(w) );
    for s = 1:numel(w), M(:,s) = vec( normalize( sSS(w(s)).xyz ) ); end
    [M,~] = svd( M ,'econ');
    M = reshape( M(:,1) , [ nV , nsd ] );

    %%check orientation
    [~,~,E]  = MatchPoints( M , sSS(1).xyz , 'Mt' );

    iM = M; iM(:,1) = -iM(:,1);
    [~,~,Ei] = MatchPoints( iM , sSS(1).xyz , 'Mt' );

    if Ei < E, M = iM; end
    
    %%%
  catch
    M = sSS{1};
  end
  M = normalize( M );

  E = Inf;
  while 1
    Ep = E; Mp = M; M = 0; E = 0;
    for s = 1:nSS
      SA = align( Mp , sSS(s).xyz , TTYPE );
      E  = E + fro2( SA - Mp );
      M = M + SA;
    end
    fprintf('E: %.15g   ',E);
    M = normalize( align( Mp , normalize( M ) , TTYPE ) );

    fprintf( 'dif: %.15g\n' , maxnorm( M , Mp ) );
    if E > Ep
      fprintf('energy increased\n');
      M = Mp;
      break;
    end
    if isequal( M , Mp )
      fprintf('converged\n');
      break;
    end
  end


  if AT_END_SCALE
    MATs = zeros( nsd+1 , nsd+1 ,nSS);
    for s = 1:nSS
      MATs(:,:,s) = MatchPoints( SS(s).xyz , M , 'Mt' );
    end
    MATs = MATs( 1:nsd , 1:nsd ,:);
    if nsd == 2
      MATs = funsym2x2( MATs , [] , 'det' );
    elseif nsd == 3
      MATs = funsym3x3( MATs , [] , 'det' );
    end
    MATs = exp( mean( log(MATs) )/nsd );

    M = M * MATs;
  end
  
  if AT_END_ORIENT
    MATs = zeros( nsd+1 , nsd+1 ,nSS);
    for s = 1:nSS
      MATs(:,:,s) = MatchPoints( SS(s).xyz , M , 'Rt' );
    end
    MATs = MATs( 1:nsd , 1:nsd ,:);
    
    MATs = KarcherMean( MATs , @(U)Exp_SO(U) , @(Q)Log_SO(Q) , 'L' );

    M = M * MATs.';
  end
  

  if nargout > 1
    SA = SS;
    for s = 1:nSS
      SA(s).xyz = align( M , SS(s).xyz , TTYPE );
    end
  end

  
  M = Mesh( M , F );
  

end
function Y = normalize( Y )
  for it = 1:25
    Yp = Y;
    Y = bsxfun( @minus , Y , mean( Y , 1 ) );
    Y = Y / sqrt( Y(:).' * Y(:) );
    if isequal( Y , Yp ), break; end
  end
end

function M = align( F , M , TTYPE )
  nsd = size( F , 2);
  F(:,nsd+1:3) = 0;
  M(:,nsd+1:3) = 0;

  M = transform( M , MatchPoints( F , M , TTYPE) );
  M = M( : ,1:nsd);
end
