function HS = FixHeartSlices( HS , varargin )

  RV_WIDTH = 3;
  try, RV_WIDTH = evalin('base','RV_WIDTH_'); end
  [varargin,~,RV_WIDTH] = parseargs(varargin,'RVwidth','$DEFS$',RV_WIDTH);
  
  ZGAP     = 2;

  for h = 1:size(HS,1)
      if isempty( HS{h,1} ), continue; end
    if ~isfield( HS{h,1}.INFO , 'PlaneName' )
      HS{h,1}.INFO.PlaneName = '?';
      try
        HS{h,1}.INFO.PlaneName = slicePlaneName( HS{h,1}.INFO );
      end
    end
  end
  
  tr = @(x,t)transform( x , t ) * eye(size(x,2),2);
  TR = @(x,t)transform( x * eye(size(x,2),3) , t );
  getLargest = @(P)P( argmax( P.nn ) );

  
  if ~isempty( varargin ) && isnumeric( varargin{1} )
    allHs = varargin{1}; varargin(1) = [];
  else
    allHs = 1:size(HS,1);
  end
  allHs( cellfun('isempty',HS(allHs,1)) ) = [];
  
  
  [HS{:,end+1:10}] = deal([]);
  %HS(:,8:9) = HS(:,6:7);      %LA in column 8, RA en column 9
  [HS{:,[6,7,8]}] = deal([]);
  % col - contour input - output
  %  2 - Left epi        - left epi (no septum)
  %  3 - left endo       - left endo
  %  4 - right endo      - lateral wall RV
  %  5 - LV extent       - septum
  %  6 -                 - RV epi
  %  7 -                 - left_epi/septum in long axis
  %  8 -                 - []
  %  9 - left atria      - left atria
  % 10 - rigth atria     - right atra
  % 11 - extras          - []
  
  
  for h = allHs(:).'
    if all( cellfun('isempty',HS(h,2:min(4,end))) ), continue; end
    try
      [Z,iZ] = getPlane( HS{h,1} , '+z' );
      for c = 2:size(HS,2)
        if isempty( HS{h,c} ), continue; end
        d = max( distance2Plane(  HS{h,c} , Z ) );
        if d > 1e-8
          warning('contour %d,%d seems to be out of plane. Projecting it',h,c);
          HS{h,c} = TR( tr( HS{h,c} , iZ ) , Z );
        end
      end
    end
    
    switch lower( HS{h,1}.INFO.PlaneName )
      case {'ax','?','','lvot','lvotx','3ch'}
        
        [Z,iZ] = AXplane( HS , h );
        
        %% fix LV-ENDO
        % join, orient ccw
        if ~isempty( HS{h,3} )
        L = polyline( double( tr( HS{h,3} , iZ ) ) );  L( L.n < 2 ) = [];
        
        L = join( L );
        L = close( L , 5 ); try, L = circshift( L , 'maxX' ); end
        L = orient( L );
        
        HS{h,3} = assignFrom( TR( double( L ) , Z ) , HS{h,3} );
        end
        
        %% fix LV-EPI
        % join, orient ccw
        if ~isempty( HS{h,2} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) );  L( L.n < 2 ) = [];
        
        L = join( L );
        L = close( L , 5 ); try, L = circshift( L , 'maxX' ); end
        L = orient( L );
        
        HS{h,2} = assignFrom( TR( double( L ) , Z ) , HS{h,2} );
        end

        %% fix RV-ENDO
        if ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,4} , iZ ) ) );  R( R.n < 2 ) = [];

        R = join( R );
        R = close( R , 5 ); try, R = circshift( R , 'minX' ); end
        R = orient( R );

        HS{h,4} = assignFrom( TR( double( R ) , Z ) , HS{h,4} );
        end

        %% offset RV-ENDO
        if ~isempty( HS{h,4} )
        R  = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];
        
        R  = offset( R , RV_WIDTH );
        try, R = circshift( R , 'minX' ); end
        
        
        try, R = setdiff( R , close( polyline( tr( HS{h,2} , iZ ) ) ) ); end
        
        
        R  = orient( R );
        
        HS{h,5} = TR( double( R ) , Z );
        end
        
        
        %% fix SEPTUM
        if ~isempty( HS{h,2} ) && ~isempty( HS{h,4} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];
        
        [~,~,~,r,l] = intersection( R , L );
        if ~isempty(r)

        if numel( r ) == 2
          if isclosed(R)
            R = join( R.part( [ max(r) , Inf    ] ) ,...
                      R.part( [ 1      , min(r) ] ) );
          else
            R = R.part( sort(r) );
          end
          S = L.part( flip( sort(l) ) );
        else
          R = R.part( [ 1 , r ] );
          S = L.part( [ max(l) , 1 ] );
        end          
          

        HS{h,4} = assignFrom( TR( double( R ) , Z ) , HS{h,4} );
        HS{h,6} = assignFrom( TR( double( S ) , Z ) , HS{h,2} );
        end
        end
        
        %% fix LV-EPI
        if ~isempty( HS{h,2} ) && ~isempty( HS{h,5} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        R = polyline( double( tr( HS{h,5} , iZ ) ) ); R( R.n < 2 ) = [];

        
        if isclosed( L )

          [~,~,d,l] = closestElement( L ,  R.coordinates{1}([1,end],:) );
          if all( d < 1e-4 )
          L = join( L.part( [ l(2) , Inf ] ) , L.part( [ 1 , l(1) ] ) );
          end

        else
          
          [~,~,d,l] = closestElement( L ,  R.coordinates{1}(end,:) );
          if d < 1e-4
          L = L.part( [ l , Inf ] );
          end
          
        end
        
        HS{h,2} = assignFrom( TR( double( L ) , Z ) , HS{h,2} );
        end
        
        %% fix RV-EPI
        if ~isempty( HS{h,5} ) && ~isempty( HS{h,2} ) && ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,5} , iZ ) ) ); R( R.n < 2 ) = [];
        R = orient( R );
          
        if isclosed( R )
        A = tr( HS{h,4} , iZ ); A = A(1,:);
        [~,~,~,a] = closestElement( R , A );
        R = circshift( R , 1-round(a) );
        end
        
        B = tr( HS{h,2} , iZ ); B = B(1,:);
        [~,~,d,b] = closestElement( R , B );
        if d < 1e-4
        R = R.part( [ 1 , b ] );
        end

        B = tr( HS{h,2} , iZ ); B = B(end,:);
        [~,~,d,b] = closestElement( R , B );
        if d < 1e-4
        R = R.part( [ b , Inf ] );
        end
        
        
        S = tr( HS{h,6} , iZ );
        if ~isempty( S )
        [~,~,~,s] = intersection( R , polyline(S) );
        if ~isempty(s)
        R = R.part( [ max(s) , Inf ] );
        end
        end
        
        HS{h,5} = assignFrom( TR( double( R ) , Z ) , HS{h,5} );
        end

        %% split LV-EPI
        if ~isempty( HS{h,2} ) && isempty( HS{h,5} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        
        I = L.part( [ 1 , argmin( L.coordinates{1}(:,2) ) - 1        ] );  I = TR( double( I ) ,Z);
        A = L.part( [     argmin( L.coordinates{1}(:,2) )      , Inf ] );  A = TR( double( A ) ,Z);
        
        if min( A(:,3) ) < min( I(:,3) )
            [I,A] = deal(A,I);
        end
        
        HS{h,2} = assignFrom( A , HS{h,2} );
        HS{h,7} = assignFrom( I , HS{h,2} );
        end

        
        
%         if numel( allHs ) > 4
%           [Z,iZ] = getPlane( HS{end,1} );
%           LS = transform( HS(h,:) ,iZ );
%           for c = 2:numel(LS)
%             L = LS{c};
%             if isempty( L ), continue; end
%             if ~any( L(:,3) > 0 ), continue; end
%             L = MeshClip( Mesh(L,'contour') , L(:,3) );
%             L = meshSeparate( L , 'largest' );
%             L = mesh2contours( L );
%             HS{h,c} = assignFrom( transform( double( L ) , Z ) , HS{h,c} );
%           end
%         end

        
      case {'hlax','hla'}
        [Z,iZ] = LAplane( HS , h );
        HS{h,1}.INFO.UpVector = Z(1:3,1:3)*[0;1;0];
        HS{h,5} = [];

        %% fix RA
        % join, open at top, orient ccw
        if ~isempty( HS{h,10} )
        L = polyline( double( tr( HS{h,10} , iZ ) ) ); L( L.n < 2 ) = [];
        
        L = join( L );
        L = close( L , Inf ); try, L = circshift( L , 'maxY' ); end
        L = orient( L );
        bb = bbox( L );
        
        for z = 20:100
          [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
          if numel(t) == 2; break; end
        end
        for z = z:-1:1
          [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
          if numel(t) ~= 2, z = z+1; break; end
        end
        [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
        atBottom = L.resample( 'i' , floor(min(t)):ceil(max(t)) );
        atBottom = double( atBottom );
        r = range( atBottom(:,1) ); m = (r(2)+r(1))/2; r = r(2)-r(1);
      
        atLeft = atBottom( atBottom(:,1) < m - r/6 ,:);
        [~,ord] = sort( atLeft(:,2) ,'ascend' );
        atLeft = atLeft( ord(1:min(4,numel(ord))) ,:);

        atRight = atBottom( atBottom(:,1) > m + r/6 ,:);
        [~,ord] = sort( atRight(:,2) ,'ascend' );
        atRight = atRight( ord(1:min(4,numel(ord))) ,:);

        atBottom = [ atLeft ; atRight ];
        S = wlr( { atBottom(:,1) , 1 } , atBottom(:,2) );
        r = bb(:,1); r = mean(r) + ( r - mean(r) )*2;
        out = [ r , S(1)*r + S(2) + ZGAP ];
        out = out([1 2 2 1],:);
        out(3:4,2) = bb(1,2) - 1e6*eps(bb(1,2)) - 10;
        out = close( polyline( out ) );        
        
        L = orient( getLargest( setdiff( L , out ) ) );

        HS{h,10} = assignFrom( TR( double( L ) , Z ) , HS{h,10} );
        %%
        end
                
        %% fix LA
        % join, open at top, orient ccw
        if ~isempty( HS{h,9} )
        L = polyline( double( tr( HS{h,9} , iZ ) ) ); L( L.n < 2 ) = [];
        
        L = join( L );
        L = close( L , Inf ); try, L = circshift( L , 'maxY' ); end
        L = orient( L );
        bb = bbox( L );
        
        for z = 20:100
          [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
          if numel(t) == 2; break; end
        end
        for z = z:-1:1
          [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
          if numel(t) ~= 2, z = z+1; break; end
        end
        [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
        atBottom = L.resample( 'i' , floor(min(t)):ceil(max(t)) );
        atBottom = double( atBottom );
        r = range( atBottom(:,1) ); m = (r(2)+r(1))/2; r = r(2)-r(1);
      
        atLeft = atBottom( atBottom(:,1) < m - r/6 ,:);
        [~,ord] = sort( atLeft(:,2) ,'ascend' );
        atLeft = atLeft( ord(1:min(4,numel(ord))) ,:);

        atRight = atBottom( atBottom(:,1) > m + r/6 ,:);
        [~,ord] = sort( atRight(:,2) ,'ascend' );
        atRight = atRight( ord(1:min(4,numel(ord))) ,:);

        atBottom = [ atLeft ; atRight ];
        S = wlr( { atBottom(:,1) , 1 } , atBottom(:,2) );
        r = bb(:,1); r = mean(r) + ( r - mean(r) )*2;
        out = [ r , S(1)*r + S(2) + ZGAP ];
        out = out([1 2 2 1],:);
        out(3:4,2) = bb(1,2) - 1e6*eps(bb(1,2)) - 10;
        out = close( polyline( out ) );        
        
        L = orient( getLargest( setdiff( L , out ) ) );

        HS{h,9} = assignFrom( TR( double( L ) , Z ) , HS{h,9} );
        %%
        end
        
        %% fix LV-ENDO
        % join, open at top, orient ccw
        if ~isempty( HS{h,3} )
        L = polyline( double( tr( HS{h,3} , iZ ) ) ); L( L.n < 2 ) = [];
        
        L = join( L );
        L = close( L , Inf ); try, L = circshift( L , 'minY' ); end
        L = orient( L );
        bb = bbox( L );
        
        [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , -[5;5] ] ) );
        atTop = L.resample( 'i' , floor(min(t)):ceil(max(t)) );
        atTop = double( atTop );
        r = range( atTop(:,1) ); m = (r(2)+r(1))/2; r = r(2)-r(1);
      
        atLeft = atTop( atTop(:,1) < m - r/6 ,:);
        [~,ord] = sort( atLeft(:,2) ,'descend' );
        atLeft = atLeft( ord(1:min(4,numel(ord))) ,:);

        atRight = atTop( atTop(:,1) > m + r/6 ,:);
        [~,ord] = sort( atRight(:,2) ,'descend' );
        atRight = atRight( ord(1:min(4,numel(ord))) ,:);

        atTop = [ atLeft ; atRight ];
        S = wlr( { atTop(:,1) , 1 } , atTop(:,2) );
        r = bb(:,1); r = mean(r) + ( r - mean(r) )*2;
        out = [ r , S(1)*r + S(2) - ZGAP ];
        out = out([1 2 2 1],:);
        out(3:4,2) = bb(2,2) + 1e6*eps(bb(2,2)) + 10;
        out = close( polyline( out ) );
        
        L = orient( getLargest( setdiff( L , out ) ) );

        HS{h,3} = assignFrom( TR( double( L ) , Z ) , HS{h,3} );
        end
        
        %% fix LV-EPI
        % join, orient ccw
        if ~isempty( HS{h,2} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        
        L = orient( join( L ) );
        L = L.part( [     argmax( L.coordinates{1}(1:ceil(L.nn/2),2) ) , Inf ] );
        L = L.part( [ 1 , argmax( L.coordinates{1}(ceil(L.nn/2):end,2) ) + ceil(L.nn/2) - 1 ] );
        
        HS{h,2} = assignFrom( TR( double( L ) , Z ) , HS{h,2} );
        end

        %% fix RV-ENDO
        if ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];

        R = join( R );
        R = close( R , Inf ); try, R = circshift( R , 'minX' ); end
        R = orient( R );

        HS{h,4} = assignFrom( TR( double( R ) , Z ) , HS{h,4} );
        end

        %% offset RV-ENDO
        if ~isempty( HS{h,4} )
        R  = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];
        
        R  = offset( R , RV_WIDTH );
        try, R = circshift( R , 'minX' ); end
        R = orient( R );
        
        HS{h,5} = TR( double( R ) , Z );
        end
        
        %% fix SEPTUM
        if ~isempty( HS{h,2} ) && ~isempty( HS{h,4} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];
        
        [~,~,~,r,l] = intersection( R , L );
        if ~isempty(r)
        R = join( R.part( [ max(r) , Inf    ] ) ,...
                  R.part( [ 1      , min(r) ] ) );
        R = orient( R );
                
        S = L.part( [ max(l) , 1 ] );

        HS{h,4} = assignFrom( TR( double( R ) , Z ) , HS{h,4} );
        HS{h,6} = assignFrom( TR( double( S ) , Z ) , HS{h,2} );
        end
        end

        %% fix LV-EPI
        if ~isempty( HS{h,2} ) && ~isempty( HS{h,5} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        R = polyline( double( tr( HS{h,5} , iZ ) ) ); R( R.n < 2 ) = [];

        [~,~,~,r,l] = intersection( R , L );
        if ~isempty(l)
        L = L.part( [ max(l) , Inf ] );

        HS{h,2} = assignFrom( TR( double( L ) , Z ) , HS{h,2} );
        end
        end
        
        %% open RV-ENDO
        if ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];
        
        if ~isclosed(R)
        bbR = bbox( R );
        S = polyline( double( tr( HS{h,6} , iZ ) ) );
        bbS = bbox( S );
        
        bb = polyline( [ ( bbR(1,1)*0 + bbS(1,1) )*[1;1] , bbR(:,2) ] );

        [~,~,~,r] = intersection( R , bb ); r = min(r);
        if ~isempty(r)
        R = R.part( [ min(r) , Inf ] );
        
        T = double( R.resample( 'e' , 0.1 ) );
        for t = 2:size(T,1)
          [~,~,err] = wlr( { T(1:t,1) , 1 } , T(1:t,2) );
          if max( abs( err ) ) > 2, break; end
        end
        
        [~,~,~,r] = closestElement( R , T( t ,:) );
        R = R.part( [ r , Inf ] );

        R = R.part( [ argmax( R.coordinates{1}(:,2) ) , Inf ] );
        
        
        HS{h,4} = assignFrom( TR( double( R ) , Z ) , HS{h,4} );
        end
        end
        end
        
        %% open RV-EPI
        if ~isempty( HS{h,5} ) && ~isempty( HS{h,2} ) && ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,5} , iZ ) ) ); R( R.n < 2 ) = [];
        R = orient( R );
          
        A = tr( HS{h,4} , iZ ); A = A(1,:);
        [~,~,~,a] = closestElement( R , A );
        if ~isempty( a )
        R = circshift( R , 1-round(a) );
        
        B = tr( HS{h,2} , iZ ); B = B(1,:);
        [~,~,~,b] = closestElement( R , B );
        
        R = R.part( [ 1 , b ] );

        HS{h,5} = assignFrom( TR( double( R ) , Z ) , HS{h,5} );
        end
        end
        
        HS{h,2} = flipud( HS{h,2} );
        HS{h,5} = flipud( HS{h,5} );
        
        
      case {'vlax','vla'}
        [Z,iZ] = LAplane( HS , h );
        HS{h,1}.INFO.UpVector = Z(1:3,1:3)*[0;1;0];
        HS{h,5} = [];

        %% fix LA
        % join, open at top, orient ccw
        if ~isempty( HS{h,9} )
        L = polyline( double( tr( HS{h,9} , iZ ) ) ); L( L.n < 2 ) = [];
        
        L = join( L );
        L = close( L , Inf ); try, L = circshift( L , 'maxY' ); end
        L = orient( L );
        bb = bbox( L );
        
        for z = 20:100
          [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
          if numel(t) == 2; break; end
        end
        for z = z:-1:1
          [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
          if numel(t) ~= 2, z = z+1; break; end
        end
        [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , [z;z] ] ) );
        atBottom = L.resample( 'i' , floor(min(t)):ceil(max(t)) );
        atBottom = double( atBottom );
        r = range( atBottom(:,1) ); m = (r(2)+r(1))/2; r = r(2)-r(1);
      
        atLeft = atBottom( atBottom(:,1) < m - r/6 ,:);
        [~,ord] = sort( atLeft(:,2) ,'ascend' );
        atLeft = atLeft( ord(1:min(4,numel(ord))) ,:);

        atRight = atBottom( atBottom(:,1) > m + r/6 ,:);
        [~,ord] = sort( atRight(:,2) ,'ascend' );
        atRight = atRight( ord(1:min(4,numel(ord))) ,:);

        atBottom = [ atLeft ; atRight ];
        S = wlr( { atBottom(:,1) , 1 } , atBottom(:,2) );
        r = bb(:,1); r = mean(r) + ( r - mean(r) )*2;
        out = [ r , S(1)*r + S(2) + ZGAP ];
        out = out([1 2 2 1],:);
        out(3:4,2) = bb(1,2) - 1e6*eps(bb(1,2)) - 10;
        out = close( polyline( out ) );        
        
        L = orient( getLargest( setdiff( L , out ) ) );

        HS{h,9} = assignFrom( TR( double( L ) , Z ) , HS{h,9} );
        end

        %% fix LV-EPI
        % join, orient ccw
        if ~isempty( HS{h,2} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        
        L = orient( join( L ) );
        L = L.part( [     argmax( L.coordinates{1}(1:ceil(L.nn/2),2) ) , Inf ] );
        L = L.part( [ 1 , argmax( L.coordinates{1}(ceil(L.nn/2):end,2) ) + ceil(L.nn/2) - 1 ] );
        
        HS{h,2} = assignFrom( TR( double( L ) , Z ) , HS{h,2} );
        end

        %% split LV-EPI
        % anterior part goes to HF{h,2} but inferior part goes to HF{h,7}
        if ~isempty( HS{h,2} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        
        I = L.part( [ 1 , argmin( L.coordinates{1}(:,2) ) - 1        ] );  I = TR( double( I ) ,Z);
        A = L.part( [     argmin( L.coordinates{1}(:,2) )      , Inf ] );  A = TR( double( A ) ,Z);
        
        if min( A(:,3) ) < min( I(:,3) )
            [I,A] = deal(A,I);
        end
        
        HS{h,2} = assignFrom( A , HS{h,2} );
        HS{h,7} = assignFrom( I , HS{h,2} );
        end

        %% fix LV-ENDO
        % join, open at top, orient ccw
        if ~isempty( HS{h,3} )
        L = polyline( double( tr( HS{h,3} , iZ ) ) ); L( L.n < 2 ) = [];
        
        L = orient( circshift( close( join( L ) ) , 'minY' ) ); bb = bbox( L );
        
        [~,~,~,t] = intersection( L , polyline( [ bb(:,1) , -[5;5] ] ) );
        atTop = L.resample( 'i' , floor(min(t)):ceil(max(t)) );
        atTop = double( atTop );
        r = range( atTop(:,1) ); m = (r(2)+r(1))/2; r = r(2)-r(1);
      
        atLeft = atTop( atTop(:,1) < m - r/6 ,:);
        [~,ord] = sort( atLeft(:,2) ,'descend' );
        atLeft = atLeft( ord(1:min(4,numel(ord))) ,:);

        atRight = atTop( atTop(:,1) > m + r/6 ,:);
        [~,ord] = sort( atRight(:,2) ,'descend' );
        atRight = atRight( ord(1:min(4,numel(ord))) ,:);

        atTop = [ atLeft ; atRight ];
        S = wlr( { atTop(:,1) , 1 } , atTop(:,2) );
        r = bb(:,1); r = mean(r) + ( r - mean(r) )*2;
        out = [ r , S(1)*r + S(2) - ZGAP ];
        out = out([1 2 2 1],:);
        out(3:4,2) = bb(2,2) + 1e6*eps(bb(2,2)) + 10;
        out = close( polyline( out ) );
        
        L = orient( getLargest( setdiff( L , out ) ) );

        HS{h,3} = assignFrom( TR( double( L ) , Z ) , HS{h,3} );
        end
        
        HS{h,2} = flipud( HS{h,2} );
        HS{h,7} = flipud( HS{h,7} );
        
        
      case {'rvla','rvlax'}
               %% fix RV-ENDO
        if ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];

        R = join( R , 30);
        R = close( R , 5 ); try, R = circshift( R , 'minX' ); end
        R = orient( R );

        HS{h,4} = assignFrom( TR( double( R ) , Z ) , HS{h,4} );
        end

        %% offset RV-ENDO
        if ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];

        for p = 1:R.np, R(p)  = offset( R(p) , RV_WIDTH ); end
        try, R = circshift( R , 'minX' ); end
        R = orient( R );
        
        HS{h,5} = TR( double( R ) , Z );
        end

        
      case {'sax','sa'}
        try
          [Z,iZ] = SAplane( HS , h );
        catch
          allSAs = allHs( arrayfun(@(i)strcmpi(HS{i,1}.INFO.PlaneName,'SAx'),allHs) );
          SA = cell( 1 , size(HS,2) );
          SA{1,1} = HS{h,1};
          for c = 2:size( SA ,2)
            for hh = allSAs(:).'
              SA{1,c} = [ SA{1,c} ; HS{hh,c} ];
            end
          end
          [Z,iZ] = SAplane( SA , 1 );
        end
       %HS{h,1}.INFO.UpVector = Z(1:3,1:3)*[0;1;0];
        
        %% fix LV-ENDO
        % join, close, orient ccw
        if ~isempty( HS{h,3} )
        L = polyline( double( tr( HS{h,3} , iZ ) ) ); L( L.n < 2 ) = [];
        
        L = join( L );
        L = close( L , 5 ); try, L = circshift( L , 'maxX' ); end
        L = orient( L );

        HS{h,3} = assignFrom( TR( double( L ) , Z ) , HS{h,3} );
        end
        
        %% fix LV-EPI
        % join, close, orient ccw
        if ~isempty( HS{h,2} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        L = join( L );
        L = close( L , 5 ); try, L = circshift( L , 'maxX' ); end
        L = orient( L );

        HS{h,2} = assignFrom( TR( double( L ) , Z ) , HS{h,2} );
        end

        %% fix RV-ENDO
        if ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];

        R = join( R );
        if isequal( HS{h,2}(end,:) , HS{h,2}(1,:) )
          R = close( R , Inf );
          R = transform( R ,'rz', 10); 
          try, R = circshift( R , 'minX' ); end
          R = transform( R ,'rz',-10);
          R = polyline( double(R)*eye(3,2) );
        end
        R = orient( R );

        HS{h,4} = assignFrom( TR( double( R ) , Z ) , HS{h,4} );
        end

        %% offset RV-ENDO
        if ~isempty( HS{h,4} )
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];

        R  = offset( R , RV_WIDTH );
        R = transform( R ,'rz', 10); 
        try, R = circshift( R , 'minX' ); end
        R = transform( R ,'rz',-10);
        R = polyline( double(R)*eye(3,2) );
        R = orient( R );
        
        HS{h,5} = TR( double( R ) , Z );
        end
        
        %% fix SEPTUM
        if ~isempty( HS{h,2} ) && ~isempty( HS{h,4} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        R = polyline( double( tr( HS{h,4} , iZ ) ) ); R( R.n < 2 ) = [];
        
        [~,~,~,r,l] = intersection( R , L );
        if ~isempty(r)
        if isclosed( R )
          R = join( R.part( [ max(r) , Inf    ] ) ,...
                    R.part( [ 1      , min(r) ] ) );
        else
          R = R.part( [ min(r) , max(r) ] );
        end
        S = L.part( [ max(l) min(l) ] );

        HS{h,4} = assignFrom( TR( double( R ) , Z ) , HS{h,4} );
        HS{h,6} = assignFrom( TR( double( S ) , Z ) , HS{h,2} );
        end
        end
        
        %% fix EPIs
        if ~isempty( HS{h,2} ) && ~isempty( HS{h,4} )
        L = polyline( double( tr( HS{h,2} , iZ ) ) ); L( L.n < 2 ) = [];
        R = polyline( double( tr( HS{h,5} , iZ ) ) ); R( R.n < 2 ) = [];
        
        [~,~,~,r,l] = intersection( R , L );
        if ~isempty(r)
        if isclosed( R )
          R = join( R.part( [ max(r) , Inf    ] ) ,...
                    R.part( [ 1      , min(r) ] ) );
        else
          R = R.part( sort(r) );
        end
        L = join( L.part( [ max(l) , Inf    ] ) ,...
                  L.part( [ 1      , min(l) ] ) );

        HS{h,5} = assignFrom( TR( double( R ) , Z ) , HS{h,5} );
        HS{h,2} = assignFrom( TR( double( L ) , Z ) , HS{h,2} );
        end
        end

        
    end
  end
  
  for h = allHs(:).'
    if size( HS ,2) < 7 || isempty( HS{h,7} ), continue; end
    if any( strcmp( lower( HS{h,1}.INFO.PlaneName ) , {'vla','vlax'} ) )
      continue;
    end
    A = HS{h,2};
    B = HS{h,7};

    if strcmpi( slicePlaneName( getPlane( HS{h,1} ) ) , 'vlax' )
      
      [Z,iZ] = getPlane( HS{1,1} ,'+z');
      
      At = transform( A , iZ );
      Bt = transform( B , iZ );
      
      if max( Bt(:,3) ) > max( At(:,3) )
        HS{h,2} = B;
        HS{h,7} = A;
      end
      
    else
    
      S = HS(:,6);
      S = vertcat( S{:} );

      if min(vec(ipd( A , S ))) < min(vec(ipd( B , S )))
        if any( strcmp( lower( HS{h,1}.INFO.PlaneName ) , {'vla','vlax'} ) )
          warning('swap 2 and 7 for VLA?');
        end
        HS{h,2} = B;
        HS{h,7} = A;
      end
      
    end
  end

end

function [T,iT] = SAplane( HS , h )

  [~,T] = getPlane( HS{h,1} );
  
  EPIc = NaN( size(HS,1) ,2);
  LVc  = NaN( size(HS,1) ,2);
  RVc  = NaN( size(HS,1) ,2);
  for hh = h(:).'
    if isempty( HS{hh,1} ), continue; end
    if ~strcmp( HS{hh,1}.INFO.PlaneName , 'SAx' ), continue; end
    try, EPIc(hh,:) = center( transform( HS{hh,2} , T ) ); end
    try, LVc(hh,:)  = center( transform( HS{hh,3} , T ) ); end
    try, RVc(hh,:)  = center( transform( HS{hh,4} , T ) ); end
  end
  
  EPIc( any( ~isfinite( EPIc ) ,2) ,:) = [];
  LVc(  any( ~isfinite( LVc  ) ,2) ,:) = [];
  RVc(  any( ~isfinite( RVc  ) ,2) ,:) = [];
  
  RL = fisher( RVc.' , [LVc;EPIc].' );
  RL = fisher( RVc.' , LVc.' );
  
  T = maketransform( 't2' , -mean( [ EPIc ; LVc ] ,1) , 'rz' , -atan2d( RL(2) , RL(1) ) ) * T;
  
 
  %where is the RV
  atLeft = 0; atRight = 0;
  for h = 1:size( HS ,1)
    if isempty( HS{h,1} ), continue; end
    if ~strcmp( HS{h,1}.INFO.PlaneName , 'SAx' ), continue; end
    EPI = HS{h,2};
    LV  = HS{h,3};
    RV  = HS{h,4};
    if  isempty( RV ) || ( isempty( EPI ) && isempty( LV ) ), continue; end
    Rc = center( transform( RV , T ) );
    
    if ~isempty( LV ), Lc = center( transform( LV  , T ) );
    else,              Lc = center( transform( EPI , T ) );
    end
    
    if      Rc(1) < Lc(1), atLeft  = atLeft  + 1;
    elseif  Rc(1) > Lc(1), atRight = atRight + 1;
    end
  end
  
  if atLeft < atRight
    T = diag( [ -1 , 1 , 1 , 1 ] ) * T;
  end
  
  
  Z = T(1:3,1:3) \ [0;0;1];
  if Z(3) < 0
    T = diag( [ 1 , 1 , -1 , 1 ] ) * T;
  end    
  
  
  if det( T(1:3,1:3) ) < 0
    T = diag( [ 1 , -1 , 1 , 1 ] ) * T;
  end
  
  iT = T;
  T  = minv( T );
end
function C = center( xy )
  xy = xy(:,1:2);
  xy( any( ~isfinite(xy) ,2) ,:) = [];
  
  try
    C = centroid( polygon( xy ) );
  catch
    C = mean( xy ,1);
  end
end
function [T,iT] = LAplane( HS , h )
  Z = -Inf; idBasalPlane = 0;
  for r = 1:size(HS,1)
    if isempty( HS{r,1} ), continue; end
    if ~strcmp( HS{r,1}.INFO.PlaneName , 'SAx' ), continue; end
    if any( cellfun('isempty',HS(r,2:4)) ), continue; end
    Zl = HS{r,1}.INFO.xZLevel;
    if Zl > Z, Z = Zl; idBasalPlane = r; end
  end
  BasalLine    = intersectionLine( HS{ idBasalPlane ,1} , HS{h,1} );

  [~,T] = getPlane( HS{h,1} );
  
  BL = transform( BasalLine , T )*eye(3,2); %BasalLine in 2d
  
  T = maketransform( 't2' , -mean( BL ,1) , 'rz' , -atan2d( diff( BL(:,2) ) , diff( BL(:,1) ) ) ) * T;

  if ~isempty( HS{h,4} )   &&  ~isempty( [ HS{h,2} ; HS{h,3} ] )
    leftSide  = transform( [ HS{h,2} ; HS{h,3} ] ,T);
    rightSide = transform( [ HS{h,4} ] ,T);
    if nanmean( leftSide(:,1) ) < nanmean( rightSide(:,1) )
      T = diag( [ -1 , 1 , 1 , 1 ] ) * T;
    end
  else
    CO = [ HS{h,2} ; HS{h,3} ; HS{h,4} ];
    C  = transform( CO , T );
    
    if CO( argmin( C(:,1) ) , 3 ) > CO( argmax( C(:,1) ) , 3 )
      T = diag( [ -1 , 1 , 1 , 1 ] ) * T;
    end 
  end
  
  BasalPlane = getPlane( HS{ idBasalPlane ,1} , '+z' );
  if transform( BasalPlane(1:3,3).' , T(1:3,1:3) )*[0;1;0] < 0
    T = diag( [ 1 , -1 , 1 , 1 ] ) * T;
  end
  
  try
    LX = transform( HS{h,5} , T )*eye(3,2);
    LX( argmin( LX(:,2) ) ,:) = [];
    [~,ord] = sort( LX(:,1) , 'ascend' );
    LX = LX( ord ,:);
    
    T = maketransform( 't2' , -mean( LX ,1) , 'rz' , -atan2d( diff( LX(:,2) ) , diff( LX(:,1) ) ) ) * T;
  end

  if det( T(1:3,1:3) ) < 0
    T = diag( [ 1 , 1 , -1 , 1 ] ) * T;
  end
  
  
  iT = T;
  T  = minv( T );
  
end
function X = assignFrom( X , Y , thr )
  if nargin < 3, thr = 1e-5; end

  d = ipd( X , Y );
  d( d > thr ) = Inf;
  [d,id] = min( d , [] , 2 );
  w = isfinite(d);

  X( w ,:) = Y( id(w) ,:);
end
function [T,iT] = AXplane( HS , h )
  Z = -Inf; idBasalPlane = 0;
  for r = 1:size(HS,1)
    if isempty( HS{r,1} ), continue; end
    if ~strcmp( HS{r,1}.INFO.PlaneName , 'SAx' ), continue; end
    if any( cellfun('isempty',HS(r,2:4)) ), continue; end
    Zl = HS{r,1}.INFO.xZLevel;
    if Zl > Z, Z = Zl; idBasalPlane = r; end
  end
  BasalLine    = intersectionLine( HS{ idBasalPlane ,1} , HS{h,1} );

  [~,T] = getPlane( HS{h,1} );
  
  BL = transform( BasalLine , T )*eye(3,2); %BasalLine in 2d
  
  T = maketransform( 't2' , -mean( BL ,1) , 'rz' , -atan2d( diff( BL(:,2) ) , diff( BL(:,1) ) ) ) * T;

  if ~isempty( HS{h,4} )   &&  ~isempty( [ HS{h,2} ; HS{h,3} ] )
    leftSide  = transform( [ HS{h,2} ; HS{h,3} ] ,T);
    rightSide = transform( [ HS{h,4} ] ,T);
    if nanmean( leftSide(:,1) ) < nanmean( rightSide(:,1) )
      T = diag( [ -1 , 1 , 1 , 1 ] ) * T;
    end
  else
    CO = [ HS{h,2} ; HS{h,3} ; HS{h,4} ];
    C  = transform( CO , T );
    
    if CO( argmin( C(:,1) ) , 3 ) > CO( argmax( C(:,1) ) , 3 )
      T = diag( [ -1 , 1 , 1 , 1 ] ) * T;
    end
  end
  
  BasalPlane = getPlane( HS{ idBasalPlane ,1} , '+z' );
  if transform( BasalPlane(1:3,3).' , T(1:3,1:3) )*[0;1;0] < 0
    T = diag( [ 1 , -1 , 1 , 1 ] ) * T;
  end
  
  try
    LX = transform( HS{h,5} , T )*eye(3,2);
    LX( argmin( LX(:,2) ) ,:) = [];
    [~,ord] = sort( LX(:,1) , 'ascend' );
    LX = LX( ord ,:);
    
    T = maketransform( 't2' , -mean( LX ,1) , 'rz' , -atan2d( diff( LX(:,2) ) , diff( LX(:,1) ) ) ) * T;
  end

  if det( T(1:3,1:3) ) < 0
    T = diag( [ 1 , 1 , -1 , 1 ] ) * T;
  end
  
  
  iT = T;
  T  = minv( T );
  
end
