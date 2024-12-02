function [P,E,R] = wlr( X , Y , W , costFun , tune )
% 
% 
%   [p,e,res] = wlr( X , Y , W , costFun , tune )
% 
%   Weighted Linear Regression
% 
%                  _ 
%     P = argmin   \   w_i  * c(  X_i * P   -  Y_i  )
%                  /
%                  -
%
%   where costFun   c(x) = x^2  by default
%
if 0
%%  
  X = (1:5).';
  Y = X*3 + 5; Y = Y + 10*randn(size(Y));
  plot( X , Y , '.r' );
  
  mh = wlr( { X , 1 } , Y , [] , 'lad' );
  xline( mh )
  
%%  
end
  
  if nargin < 5               , tune    = [];    end
  if nargin < 4               , costFun = 'sse'; end
  if nargin < 3 || isempty(W) , W       = 1;     end

  N = numel(Y);
  Y = Y(:);
  
  if isscalar( W )
    D = true(N,1);
  else
    if numel( W ) ~= N
      error('incorrect size in W');
    end
    W = W(:);
    D = isfinite(W) & ( W ~= 0 );
  end
  
  D = D & isfinite( Y );
  
  
  if ~iscell(X)
    X = {X};
  end

  
  NP = 0;
  for d = 1:numel(X)
    if isvector( X{d} )
      X{d} = X{d}(:);
    end
    if ~isscalar( X{d} ) && size( X{d},1 ) ~= N
      error('incorrect sizes in X');
    end
    NP = NP + size(X{d},2);
    
    D = D & all( isfinite(X{d}) , 2 );
  end

  
  ND = sum( D );
  if ~ND, error('no valid domain'); end
  
  
  if ND ~= N
    if ~isscalar( W ), W = W(D); end
    for d = 1:numel(X)
      if ~isscalar( X{d} ), X{d} = X{d}(D,:); end
    end
    Y = Y(D);
  end
  if ~isscalar(W)  &&  all( W == W(1) ), W = W(1); end
  
  
  if ND < NP, warning('more parameters than points!!!'); end
  
  

  if ischar( costFun )

    switch lower(costFun)
      case {'sad','lad'}
        COST_FUN = @(r,tune) abs( r );
      
        f  = [ zeros(1,NP) ,  ones(1,ND*2) ];
        LB = [  -inf(1,NP) , zeros(1,ND*2) ];
        UB = [];
        A  = getMatrixX( X );
        A  = [ A , eye(ND) , -eye(ND) ];
        
        [P,fval,exitflag,output,lambda] = linprog( f , [] , [] , A , Y , LB , UB );

        P = P(1:NP);
        
        
      case {'maxnorm'}
        COST_FUN = @(r,tune) maxnorm( r );
        
        f = [ zeros(1,NP) , 1 , 1].';
        LB = [-Inf(1,NP) , 0 , 0];
        UB = [];
        
        A  = getMatrixX( X );
        [P,fval,exitflag,output,lambda] = linprog( f ,...
                 [ A , -ones(ND,1) , zeros(ND,1) ; -A , zeros(ND,1) , -ones(ND,1) ] ,...
                 [ Y ; -Y ] , [] , [] , LB , UB );

        P = P(1:NP);
        
      case {'sse','sq','lsq','ssd'}
        COST_FUN = @(r,tune) r.^2;
        P = weighted_least_squares( X , Y , W );
        
      case {'lower'}
        COST_FUN = @(r,tune) setv( r.^2 , r < 0 , 1e9 );
        
% %         if isscalar(W), W = ones(ND,1)*W; end
% %         H   = blkdiag( zeros(NP) , diag(W) );
% %         A   = [zeros(ND,NP),-eye(ND)];
% %         b   = zeros(ND,1);
% %         Aeq = [getMatrixX( X ),eye(ND)];
% %         beq = Y;
% 
% %         H   = linOP( @(au) W .* au(NP+(1:ND)) , [ND,NP+ND] );
% %         A   = linOP( @(au) -au(NP+(1:ND)) , [ND,NP+ND] );
% %         b   = zeros(ND,1);
% %         Aeq = linOP( @(au) getMatrixX( X )*au(1:NP) + au(NP+(1:ND)) , [ND,NP+ND] );
% %         beq = Y;
% 
%         H   = sparse( NP+(1:ND) , NP+(1:ND) , W(:) );
%         A   = sparse( 1:ND , NP+(1:ND) , -1 );
%         b   = zeros(ND,1);
%         Aeq = [ getMatrixX( X ) , speye(ND) ];
%         beq = Y;
% 
%         
%         [au,fval,exitflag,output,lambda] = ...
%              quadprog( H , zeros(NP+ND,1) ,...
%                        A   , b , Aeq , beq                                 ,...
%                        [],[],[]                                            ,...
%                        optimset(  'LargeScale','off'    ,...
%                                   'Display' ,'off'      ,...
%                                   'Diagnostics','off'   ,...
%                                   'MaxIter',1e5                            )...
%                      );
% 
% %         if exitflag ~= 1
% %           warning('WLR:lower','aparently not converged');
% %           uneval(exitflag);
% %           uneval(output);  
% %         end
% 
%         P = au(1:NP);

        
        
        A  = getMatrixX( X );
        sW = sqrt(W);
        [P,resnorm,residual,exitflag,output,lambda] = ...
               lsqlin( bsxfun( @times , sW , A ) , bsxfun( @times , sW , Y ) ,...
                       A , Y , [] , [] , [] , [] , [] , ...
                       optimset(  'LargeScale','off'    ,...
                                  'Display' ,'off'      ,...
                                  'Diagnostics','off'   ,...
                                  'MaxIter',1e5         )...
                     );
%         uneval(output);
                   
                   

      
    end

  elseif isa( costFun , 'function_handle' )
    error('not implemented yet');
  else
    error('invalid costFun');
  end
  

  
  
  
  
  if nargout > 1

    lastX = 0;
    for d = 1:numel(X)
      NX = size(X{d},2);
    
      Y = Y - X{d}*P( lastX+(1:NX) );
      
      lastX = lastX + NX;
    end
    
    if nargout > 2
      R = Y;
    end

    Y = COST_FUN( Y ,tune);
    E = safesum( W .* Y );
    
  end
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  function P = weighted_least_squares( X , Y , W )

      M =   inf( NP , NP );
    RHS = zeros( NP , 1  );

    if isscalar( W )

      lastX = 0;
      for d = 1:numel( X )
        NX = size( X{d} , 2 );

        if isscalar( X{d} )

          lastJ = 0;
          for j = 1:d
            NJ = size( X{j} , 2 );
            if isscalar( X{j} ), M( lastJ+ 1     , lastX+ 1     ) = ND * X{j}       * X{d};
            else               , M( lastJ+(1:NJ) , lastX+ 1     ) = sum( X{j} , 1 ) * X{d};
            end
            lastJ = lastJ + NJ;
          end

          RHS( lastX+ 1     ) = sum( Y ) * X{d};

        else

          lastJ = 0;
          for j = 1:d
            NJ = size( X{j} , 2 );
            if isscalar( X{j} ), M( lastJ+ 1     , lastX+(1:NX) ) = X{j}   * sum( X{d} , 1 );
            else               , M( lastJ+(1:NJ) , lastX+(1:NX) ) = X{j}.' *      X{d}      ;
            end
            lastJ = lastJ + NJ;
          end

          RHS( lastX+(1:NX) ) = Y.' * X{d};

        end

        lastX = lastX + NX;
      end

    else
    
      sW = [];
      lastX = 0;
      for d = 1:numel( X )
        NX = size( X{d} , 2 );

        if isscalar( X{d} )

          if isempty( sW ), sW = sum( W ); end

          lastJ = 0;
          for j = 1:d
            NJ = size( X{j} , 2 );
            if isscalar( X{j} ), M( lastJ+ 1     , lastX+ 1     ) =      X{j}   * sW  * X{d};
            else               , M( lastJ+(1:NJ) , lastX+ 1     ) =   (  X{j}.' * W  )* X{d};
            end
            lastJ = lastJ + NJ;
          end

          RHS( lastX+ 1     ) = ( Y.' * W ) * X{d};

        else

          WX = bsxfun( @times , W , X{d} );

          lastJ = 0;
          for j = 1:d
            NJ = size( X{j} , 2 );
            if isscalar( X{j} ), M( lastJ+ 1     , lastX+(1:NX) ) = X{j}   * sum( WX , 1 );
            else               , M( lastJ+(1:NJ) , lastX+(1:NX) ) = X{j}.' *      WX      ;
            end
            lastJ = lastJ + NJ;
          end

          RHS( lastX+(1:NX) ) = Y.' * WX;

        end

        lastX = lastX + NX;
      end

    end


    for i=1:NP, for j=1:i, if isinf( M(i,j) ), M(i,j) = M(j,i); end; end; end
    
    %         [ M , RHS(:)+NaN , RHS(:) ]

    try
      
      P = inverse(M) * RHS(:);
      
    catch
    
      setWarning( 'off' , 'MATLAB:nearlySingularMatrix' );
      setWarning( 'off' , 'MATLAB:singularMatrix' );
      setWarning( 'off' , 'MATLAB:illConditionedMatrix' );

      P = linsolve( M , RHS(:) , struct('SYM',true) );

      %[kk1,kk2]=lastwarn; disp(kk2)

      restoreWarning(     'MATLAB:nearlySingularMatrix' );
      restoreWarning(     'MATLAB:singularMatrix' );
      restoreWarning(     'MATLAB:illConditionedMatrix' );
      
    end
    
  end
  
  
  function XX = getMatrixX( X )
    
    XX = zeros( ND , NP );
    
    lastJ = 0;
    for d = 1:numel( X )
      XX(:,lastJ+(1:size(X{d},2))) = X{d};
      lastJ = lastJ + size( X{d} , 2 );
    end
        
  end


  
  
  function s = safesum( x )
    x = x(:);
    x = x( x ~= 0 );
    
    s = sum( x );
  end

  
end
