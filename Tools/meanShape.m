function M = meanShape( S , varargin )

  [varargin,i,TTYPE] = parseargs(varargin,'transform','$DEFS$','Mt');

  [varargin,AT_END_SCALE ] = parseargs(varargin,'scale' ,'$FORCE$',{true,false});
  [varargin,AT_END_ORIENT] = parseargs(varargin,'orient','$FORCE$',{true,false});


  if ~iscell( S )
    S = arrayfun( @(z)S(:,:,z) , 1:size(S,3) , 'UniformOutput' , false );
  end
  
  
  SCALE = exp( mean( log( cellfun( @(x)fro(x) , S ) ) ) );
  SCALE = pow2( round( log2( SCALE ) ) );
  for i = 1:numel(S), S{i} = S{i}/SCALE; end

  
  SN = cell(size(S));
  try
    %error('a');
    w = unique( round( linspace( 1 , numel(S) , 100 ) ) );
    
    M = zeros( numel( S{1} ) , numel(w) );
    for i = 1:numel(w), M(:,i) = vec( normalize( S{w(i)} ) ); end
    [M,s] = svd( M ,'econ');
    M = reshape( M(:,1) , [] , 3 );

    %%check orientation
    facesCH = convhulln( S{1} );
    if MeshVolume( struct('xyz',M,'tri',facesCH) ,'noorient','noclean' ) *  MeshVolume( struct('xyz',S{1},'tri',facesCH) ,'noorient','noclean' ) < 0
      M(:,3) = - M(:,3);
    end
    %%%
  catch
    M = S{1};
  end

  M = normalize( M );

  E = Inf;
  while 1
    Eprev = E;
    MM = 0; E = 0;
    for i = 1:numel(S)
      SS = S{i};
      SS = transform( SS , MatchPoints( M , SS , TTYPE) );
      E  = E + fro2( SS - M );
      MM = MM + SS;
    end
    fprintf('E: %.15g   ',E);
    MM = normalize( MM );
    MM = transform( MM , MatchPoints( M , MM , TTYPE ) );
    MM = normalize( MM );

    fprintf( 'dif: %.15g\n' , maxnorm( MM , M ) );
    if E >= Eprev || isequal( MM , M )
      break;
    end
    M = MM;
  end
  for i = 1:numel(S), S{i} = S{i}*SCALE; end

  
%   if 0
%     M = Optimize( @(M)ener(normalize(M)) , M , 'methods',{'conjugate','coordinate',1} );
%   end
%   function EE = ener( M )
%     EE = 0;
%     for ii = 1:numel(S)
%       SS = S{ii};
%       SS = transform( SS , MatchPoints( M , SS , TTYPE) );
%       EE  = EE + fro2( SS - M );
%     end
%   end
  
  
  if AT_END_SCALE
    SS = zeros(4,4,numel(S));
    for i = 1:numel(S)
      SS(:,:,i) = MatchPoints( S{i} , M , 'Mt' );
    end
    SS = SS(1:3,1:3,:);
    SS = funsym3x3( SS , [] , 'det' );
    SS = cbrt( SS(:) );
    
    SS = exp( mean( log(SS) ) );

    M = M * SS;
  end
  
  if AT_END_ORIENT
    SS = zeros(4,4,numel(S));
    for i = 1:numel(S)
      SS(:,:,i) = MatchPoints( S{i} , M , 'Rt' );
    end
    SS = SS(1:3,1:3,:);
    
    SS = KarcherMean( SS , @(U)Exp_SO(U) , @(Q)Log_SO(Q) , 'L' );

    M = M * SS.';
  end
  
%   if ORIENT
%     SS = zeros(4,4,numel(S));
%     for i = 1:numel(S)
%       SS(:,:,i) = MatchPoints( S{i} , M , 'Mt' );
%     end
%     
%     SS = KarcherMean( SS , @(U)Exp_SIM(U) , @(Q)Log_SIM(Q) , 'L' );
% 
%     M = bsxfun( @plus , M*SS(1:3,1:3).' , SS(1:3,4).' );
%   end
  
  
  
  

  function Y = normalize( Y )
    for it = 1:25
      Yp = Y;
      Y = bsxfun( @minus , Y , mean( Y , 1 ) );
      Y = Y / sqrt( Y(:).' * Y(:) );
      if isequal( Y , Yp ), break; end
    end
  end
  
  
end
