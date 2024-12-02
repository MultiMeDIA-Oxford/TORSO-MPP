function [q,d,E] = qrd( M )
%
% QuasiRotation-Diagonal decomposition
%
%   minimize  norm( log( svd(q) ) )
%   s.t.      q*d == M           ==>  q == M*inv(d)
%

%{

asymm = @(x) (x-x.')/2;
M = expm( asymm(randn(3)) )*diag([3,300.01,2])*expm( asymm(randn(3)/100) );
tic; [q,d,e] = qrd(M), toc, svd(q)
maxnorm(q*d-M),
[ svd(M)/det(M)^(1/size(M,1)) , ones(3,1)*det(M)^(1/size(M,1))  ,    svd(q),diag(d) ]
[ norm( log( svd(M)/det(M)^(1/1/size(M,1)) ) ) ,norm(log(svd(q)))]

%}

  [q,u] = qr(M);
  if maxnorm( u - diag(diag(u)) ) < 5e-8
    d  = diag(diag(u));
    return;
  end

  
  N = size(M,1);

  if N > 4 || 0

    %derivative of M*diag(d) with respect to d
    d_Md_d = zeros(N*N,N);
    for c=1:N, d_Md_d( (c-1)*N+(1:N) , c ) = M(:,c); end

    %derivative of  L-mean(L) with respect to L
    d_Lm_L = eye(N) - ones(N,N)/N;
    
    E = Inf;
    for k = -1:2^( ceil(N/2) )
      if      k == -1,    d = 1./diag(u);
      elseif  k ==  0,    d = svd( M );
      else,               d = randn(N,1);
      end
      d = Optimize( ...
            @(d) energy(d) ,...
            d              ,...
            'methods',{'quasinewton','coordinate',1}  ,...
            'ls',{'backtracking','golden'}          , ...
            struct(                    ...
              'MAX_TIME',1/4          ,...
              'MIN_ENERGY',1e-9       ,...
              'VERBOSE',0             ,...
              'SAVE_IN_BASE',false    ,...
              'PLOT',false            ,...
              'VERBOSE_FILE',[]       ,...
              'CLEAN_VERBOSE_FILE' ,false ) );

      this_E = energy( d );
      %fprintf( '%.20g\n', this_E );
      if this_E < E, E = this_E; D = d; end
      if E < 1e-8, break; end
    end
  
  else
    
    [D,E] = ExhaustiveSearch( @(d) energy_ex(d) , zeros(N,1) , 1 , 4 ,'maxTime',2);

  end

  q  = M*diag( D );
  d  = 1./D;
  
  for k = 1:4
    dq = realpow( abs( det(q) ), 1/N );
    if dq == 1, break; end
    q  = q/dq;
    d  = d*dq;
  end

  c = find( d < 0 );
  q(:,c) = -q(:,c);
  d(  c) = -d(  c);
  
  d = diag(d);

%   if nargout < 1
%     fprintf( '%.20g\n' , maxnorm(q*d - M) );
%   end
  
  if nargout < 2
    q = diag(d);
  end

  
  function e = energy_ex( d )
      try
        L = log( sqrt( abs( funsym3x3( bsxfun(@times,M,permute(d,[3 2 1])) , 'xtx','eigval' ) ) ) );
      catch
          L = log( sqrt( sort( eig( abs( M.'*M ) ) ,'descend' )));
      end
    Lm = bsxfun( @minus , L , mean(L,1) );
    e = nonans( vec( sum( Lm.^2 , 1 ) ) , Inf );

%     S = svd( bsxfun( @times , M , d(:)' ) , 'econ' );
%     L  = log( S.' ); 
%     Lm = L - mean(L);
%     e  = Lm*Lm(:);
  end
  
  
  function [e,deriv] = energy( d )
    [U,S,V] = svd( bsxfun( @times , M , d(:)' ) , 'econ' );
    S  = diag( S ).';
    L  = log( S ); 
    Lm = L - mean(L);
    e  = Lm*Lm(:);
    
    if nargout > 1
      deriv = 2 * ( Lm * d_Lm_L ) ./ S *...
              reshape( bsxfun( @times , permute( U , [2 1 3] ) , permute( V , [2 3 1] ) ) , [] , N*N ) *...
              d_Md_d;
      
%       deriv_n = NumericalDiff( @(d) energy(d) , d ,'5' );
%       fprintf('%e\n',maxnorm(deriv_n-deriv));
%       deriv = deriv_n;
    end
    
  end

end



%{

n2 = @(x) x(:).'*x(:);
nomean = @(x) x-mean(x);
energy = @(d,M) n2( nomean( log( svd( M*diag(d) ) ) ) );

dd1 = linspace( 90.00 , 176.0 , 251 );
dd2 = linspace( 0.423 , 1.000 , 251 );
dd3 = linspace( 150.0 , 350.0 , 251 );
ddds = ndmat_mx( dd1,dd2,dd3 );
Es = zeros(size(ddds,1),1); for i=1:size(ddds,1), Es(i) = energy( ddds(i,:) , M ); end
[minE,id]=min(Es); minE
[exX,exE] = ExhaustiveSearch( @(x) energy(x,M) ,[dd1([1 end]);dd2([1 end]);dd3([1 end])] )

image3( reshape( Es ,[numel(dd1) numel(dd2) numel(dd3)]) ,'facemode','texture' ); caxis(range(Es))
hold on
plot3( val2ind( dd1 , ddds(id,1) ) , val2ind( dd2 , ddds(id,2) ) , val2ind( dd3 , ddds(id,3) ) , '*r' )
hold off
hold on
plot3( val2ind( dd1 , exX(1) ) , val2ind( dd2 , exX(2) ) , val2ind( dd3 , exX(3) ) , '*g' )
hold off


[q3 ,d3 ,e3 ,D3 ] = qrd(M, 3);
[q5 ,d5 ,e5 ,D5 ] = qrd(M, 5);
[q7 ,d7 ,e7 ,D7 ] = qrd(M, 7);
[q11,d11,e11,D11] = qrd(M,11);
[q15,d15,e15,D15] = qrd(M,15);
[q35,d35,e35,D35] = qrd(M,35);
[q55,d55,e55,D55] = qrd(M,55);
[q95,d95,e95,D95] = qrd(M,95);

%}


