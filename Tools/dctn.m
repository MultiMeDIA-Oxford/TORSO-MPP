function x = dctn( x , N , type )
  if nargin < 2 || isempty(N), N = size(x); end
  if nargin < 3,               type = 2;    end

  nd = max( ndims(x) , numel(N) ) + 1;
  sz = size( x );
   N(nd) = 1;  N(  N==0 ) = 1;
  sz(nd) = 1; sz( sz==0 ) = 1;

  dctM = 1;
  
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
      x = do_dct( x );
    end

    x = permute( reshape(x,sz(perm)) , iperm );
  end


  function x = do_dct( x )
    NN = size(x,1);
    
    switch type
      case 2
        if NN < 500
          if size( dctM , 1 ) ~= NN
            dctM = sqrt(2/NN) * cos( (0:NN-1).' * ( ( 2*( 0:NN-1 ) + 1 ) * ( pi / 2 / NN ) ) );
            dctM(1,:) = dctM(1,:) / sqrt(2);
          end
          x = dctM*x;
        else
          w    = 2/sqrt(2*NN);
          w    = w*exp( -i*pi*(0:NN-1).'/2/NN );
          w(1) = w(1)/sqrt(2);

          m = mod(NN,2);
          x = x( [ 1:2:( NN+m ) ( NN-m ):-2:2 ] ,:);
          x = real( bsxfun( @times , w  , fft( x ) ) );
          %x = real( w(:,ones(1,size(x,2))) .* fft( x ) );   %for ML version smaller than 2007
        end

      case 1
        if size( dctM , 1 ) ~= NN
          dctM = sqrt(2/(NN-1)) * cos( ( 0:NN-1 ).' * ( (0:NN-1) * ( pi / (NN-1) )  ) );
          dctM(:,[1 end]) = dctM(:,[1 end])/sqrt(2);
          dctM([1 end],:) = dctM([1 end],:)/sqrt(2);
        end
        x = dctM*x;

      case '1no'   %dct1 (non-orthogonal) version
        if size( dctM , 1 ) ~= NN
          dctM = 2 * cos( ( 0:NN-1 ).' * ( (0:NN-1) * ( pi / (NN-1) )  ) );
          dctM(:,[1 end]) = dctM(:,[1 end])/2;
        end
        x = dctM*x;
        
    end
    
  end
  
end
