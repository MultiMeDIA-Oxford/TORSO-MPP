function x = idctn( x , N , type )
  if nargin < 2 || isempty(N), N = size(x); end
  if nargin < 3,               type = 2;    end

  nd = max( ndims(x) , numel(N) ) + 1;
  sz = size( x );
   N(nd) = 1;  N(  N==0 ) = 1;
  sz(nd) = 1; sz( sz==0 ) = 1;
  
  idctM = 1;
  
  for d = 1:nd
    if sz(d) == 1 && N(d) == 1, continue; end

    perm = [ d 1:d-1 d+1:nd ];  iperm( perm ) = 1:nd;
    
    x = permute( x , perm );
    x = reshape( x , sz(d) , [] );

    if sz(d) > N(d)
      x = x( 1:N(d) , : );
    elseif sz(d) < N(d)
      x( N(d) , 1 ) = 0;
    end
    sz(d) = N(d);
    
    if sz(d) > 1
      x = do_idct( x );
    end
    x = permute( reshape(x,sz(perm)) , iperm );
  end

  
  
  function x = do_idct(x)
    NN = size(x,1);
    
    switch type
      case 2
        if NN < 500
          if size( idctM , 1 ) ~= NN
            idctM = sqrt(2/NN) * cos( ( ( 2*( 0:NN-1 ) + 1 ) * ( pi / 2 / NN ) ).' * (0:NN-1) );
            idctM(:,1) = idctM(:,1) / sqrt(2);
          end
          x = idctM*x;
        else
          w = sqrt(2*NN)/2;
          w = w*exp( i*pi*(0:NN-1).'/2/NN );
          w(1) = w(1)*sqrt(2);

          x( 2:NN ,:) = x( 2:NN ,:) - i*x( NN:-1:2 ,:);
          x = real( ifft( bsxfun( @times , w , x ) ) );
          %x = real( ifft( w(:,ones(1,size(x,2))) .* x ) );   %for ML version smaller than 2007

          m = mod(NN,2);
          x( [ 1:2:( NN+m ) ( NN-m ):-2:2 ] , : ) = x;
        end
        
      case 1
        if size( idctM , 1 ) ~= NN
          idctM = sqrt(2/(NN-1)) * cos( ( (0:NN-1) * ( pi / (NN-1) )  ).'  *  ( 0:NN-1 )  );
          idctM(:,[1 end]) = idctM(:,[1 end])/sqrt(2);
          idctM([1 end],:) = idctM([1 end],:)/sqrt(2);
        end
        x = idctM*x;

      case '1no'   %dct1 (non-orthogonal) version
        if size( idctM , 1 ) ~= NN
          idctM = 2 * cos( ( 0:NN-1 ).' * ( (0:NN-1) * ( pi / (NN-1) )  ) );
          idctM(:,[1 end]) = idctM(:,[1 end])/2;
          idctM = inv( idctM );
        end
        x = idctM*x;
        
    end
  end
  
end
