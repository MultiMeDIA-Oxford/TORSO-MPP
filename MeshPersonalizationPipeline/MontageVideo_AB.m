function MontageVideo_AB( HC , fname )

  %preparing slices to be Aligned
  sz4 = arrayfun( @(h)size(HC{h,1},4) , 1:size(HC,1) ); msz4 = max( sz4 );
  if ~var( sz4 ) == 0
    for s = find( sz4(:).' ~= msz4 )
      try
        data = double( HC{s,1}.data );
        sz   = size( data ); sz(4) = msz4;

        while size( HC{s,1} , 4 ) < msz4, HC{s,1} = cat( 4 , HC{s,1} , HC{s,1} ); end
        HC{s,1} = HC{s,1}(:,:,:,1:msz4);
        HC{s,1}.data = idctn( resize( dctn( data ) , sz ) );
      end
    end
  end

%   V = VideoWriter( fname , 'Grayscale AVI' );
  V = VideoWriter( fname , 'MPEG-4' );
  V.FrameRate = msz4;
  %V.Quality = 100;
  open( V );

  MontageHeartSlices( HC , [] );
  delete( findall(gcf,'Type','text') );
  for t = 1:msz4
    fprintf('%d.',t);
    set( gcf ,'Name',sprintf( 'Making Video: %2d of %d',t,size(HC{1,1},4) ) );
    try
      if t > 1
        HS = HC;
        for r = 1:size(HS,1)
          try, HS{r,1} = HS{r,1}(:,:,:,t); end
        end
        MontageHeartSlices( HS(:,1) , gcf );
      end
      delete( findall(gcf,'Type','line') );
      
      frame = photoscreen( gcf );
      writeVideo( V , mean(frame,3) );
    end
  end
  fprintf('\n'); close(gcf); close(V);
end
