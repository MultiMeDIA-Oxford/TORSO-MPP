function S = ssmApply( SSM , varargin )

  J = numel( SSM );
  try
    nm  = size( SSM(1).xyzM ,3);
    for j = 1:J
      if size( SSM(j).xyzM ,3) ~= nm, error('different number of modes'); end
      m = SSM(j).xyzm;
      M = SSM(j).xyzM;
      sz = size( SSM(j).xyzm );
      if ~isequal( sz(1) , size( M , 1) ), error('inconsistent number of points'); end
      if ~isequal( sz(2) , size( M , 2) ), error('inconsistent nnsd'); end
      M = reshape( M , [ prod(sz) , numel(M)/prod(sz) ] );
      m = reshape( m , [ prod(sz) , 1 ] );
      SSM(j).xyzfun = @(q) reshape( M(:,1:numel(q)+1)*[q(:);0] + m , sz );
    end
  catch
    error('invalid SSM specification');
  end
  
  nsd = size( SSM(1).xyz ,2);
  Q = 0;
  R = eye(nsd+1,nsd+1);

  if 0
  elseif numel( varargin ) == 0
    
    if isfield( SSM , 'Q' ), Q = SSM(1).Q; end
    if isfield( SSM , 'R' )
      R = SSM(1).R;
    elseif isfield( SSM , 'P' )
      warning('should be R instead than P.');
      R = SSM(1).P;
    end
    
  elseif numel( varargin ) == 1 && isa( varargin{1} , 'function_handle' )
    
    [Q,R] = feval( varargin{1} );

  elseif numel( varargin ) == 2
    
    Q = varargin{1};
    R = varargin{2};

  else
    error('unknown input' );
  end

  
  for j = J:-1:1
    m = SSM(j).xyzm; sz = size(m);
    M = SSM(j).xyzM;

    M = reshape( M , [ prod(sz) , numel( M )/prod(sz) ] );
    M = reshape( M( : , 1:numel(Q) ) * Q(:) , size(m) ) + m;

    M( end+5 ,:) = 0;
    M = transform( M , R );
    M( end-4:end ,:) = [];

    SS = SSM(j);
    SS.xyz = M;
    SS = rmfield( SS , 'xyzm' );
    SS = rmfield( SS , 'xyzM' );
    SS = rmfield( SS , 'xyzfun' );
    
    S(j) = SS;
  end


end