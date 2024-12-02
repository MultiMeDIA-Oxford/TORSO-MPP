function HS = FixHeartSlices( HS , mode , varargin )

  if nargin < 2 || isempty( mode ), mode = 0; end

  RV_WIDTH = 3;
  [varargin,~,RV_WIDTH] = parseargs(varargin,'RVwidth','$DEFS$',RV_WIDTH);
  
  firstSA = [];
  [varargin,~,firstSA] = parseargs(varargin,'firstSA','$DEFS$',firstSA);
  if isempty( firstSA )
    firstSA = find( cellfun( @(I)isfield(I.INFO,'PlaneName') && strncmp(I.INFO.PlaneName,'SAx',3) , HS(:,1) ) ,1);
  end
  if isempty( firstSA )
    firstSA = 4;
  end
  firstSA = min( firstSA , size( HS ,1) );

  tr = @(x,t)transform( x , t ) * eye(3,2);
  TR = @(x,t)transform( x * eye(size(x,2),3) , t );

  if any( mode(:) == 1 )
    
    if size( HS , 2 ) > 4
      %fix Extents in LA
      for h = 1:firstSA-1
        EX = HS{h,5}; if isempty( EX ), continue; end

        [~,iLA] = LAplane( HS , h );
        ex = tr( EX , iLA );

        id = NaN(1,3);
        id(3) = argmin( ex(:,2) );
        ex( id(3) ,1) = Inf;
        [~,ord] = sort( ex(:,1) , 'ascend' );
        id(1:2) = ord(1:2);
        HS{h,5} = EX( id ,:);
      end
    end
    
    %fix LV ENDO in LA
    for h = 1:firstSA-1
      ENDO = HS{h,3}; if isempty( ENDO ), continue; end
      
      Zgap = 2;

      [LA,iLA] = LAplane( HS , h );
      
      endo = tr( ENDO , iLA );
  
      atTop = endo;
      atTop( atTop(:,2) >  30 ,:) = [];
      atTop( atTop(:,2) < -10 ,:) = [];
      r = range( atTop(:,1) ); m = (r(2)+r(1))/2; r = r(2)-r(1);
      
      atLeft = atTop( atTop(:,1) < m - r/6 ,:);
      [~,ord] = sort( atLeft(:,2) ,'descend' );
      atLeft = atLeft( ord(1:min(4,end)) ,:);
      
      atRight = atTop( atTop(:,1) > m + r/6 ,:);
      [~,ord] = sort( atRight(:,2) ,'descend' );
      atRight = atRight( ord(1:min(4,end)) ,:);

      atTop = [ atLeft ; atRight ];
      S = wlr( { atTop(:,1) , 1 } , atTop(:,2) );
      r = range( endo(:,1) ); r = mean(r) + ( r - mean(r) )*2;
      out = [ r.' , S(1)*r.' + S(2) - Zgap ];
      
      endo = booleanFromTop( endo , out );
      
      ENDO = assignFrom( TR( endo ,LA) , ENDO , 1e-5 );
      HS{h,3} = ENDO;
    end

    %fix LV EPI in LA
    for h = 1:firstSA-1
      EPI = HS{h,2}; if isempty( EPI ), continue; end
      
      Zgap = 1;

      [LA,iLA] = LAplane( HS , h );
      
      epi = tr( EPI , iLA );
  
      atTop = epi;
      atTop( atTop(:,2) >  30 ,:) = [];
      atTop( atTop(:,2) < -10 ,:) = [];
      r = range( atTop(:,1) ); m = (r(2)+r(1))/2; r = r(2)-r(1);
      
      atLeft = atTop( atTop(:,1) < m - r/6 ,:);
      [~,ord] = sort( atLeft(:,2) ,'descend' );
      atLeft = atLeft( ord(1:min(4,end)) ,:);
      
      atRight = atTop( atTop(:,1) > m + r/6 ,:);
      [~,ord] = sort( atRight(:,2) ,'descend' );
      atRight = atRight( ord(1:min(4,end)) ,:);

      atTop = [ atLeft ; atRight ];
      S = wlr( { atTop(:,1) , 1 } , atTop(:,2) );
      r = range( epi(:,1) ); r = mean(r) + ( r - mean(r) )*2;
      out = [ r.' , S(1)*r.' + S(2) - Zgap ];
      
      epi = booleanFromTop( epi , out );
      
      EPI = assignFrom( TR( epi ,LA) , EPI , 1e-5 );
      HS{h,2} = EPI;
    end

    %fix RV in HLA
    for h = 1:firstSA-1
      RV = HS{h,4}; if isempty( RV ), continue; end
      LV = HS{h,2}; if isempty( LV ), continue; end
      
      [LA,iLA] = LAplane( HS , h );
      
      rv = tr( RV , iLA );
      lv = tr( LV , iLA );
  
      rvl = boolean_setdiff( rv , lv );
      rvs = boolean_intersect( rv , lv );

      rvl(1:10,:) = [];
      ms = NaN( size(rvl,1) , 1); ms(1) = 0;
      for p = 2:size(rvl,1)
        [reg,~,res] = wlr( {rvl(1:p,1),1} , rvl(1:p,2) );
        ms(p) = mean( res.^2 );
        if ms(p) > 0.1, break; end
      end
      P = find( isnan(ms) , 1 );
      rvl( 1:P-1 ,:) = [];
      %plot3d( RV ); hplot3d( RL , '.-r' );
    
      rv = [ rvl ; NaN NaN ; rvs ];
      
      RV = assignFrom( TR( rv ,LA) , RV , 1e-5 );
      HS{h,4} = RV;
    end
    
    %fix SAs
    for h = firstSA:size(HS,1)
      [SA,iSA] = SAplane( HS , h );
      for c = 2:4
        CO = HS{h,c}; if isempty( CO ), continue; end

        co = tr( CO ,iSA);
        co = CleanSegments( co );
        co = OrientSegments( co );
        co = circshift( co , [ 1-argmax(co(:,2)) , 0] );

        CO = assignFrom( TR( co ,SA) , CO , 1e-5 );
        
        HS{h,c} = CO;
      end

      RV = HS{h,4}; if isempty( RV ), continue; end
      LV = HS{h,2}; if isempty( LV ), continue; end
      
      rv = tr( RV , iSA );
      lv = tr( LV , iSA );
  
      rvl = boolean_setdiff( rv , lv );
      rvs = boolean_intersect( rv , lv );
      
      rv = [ rvl ; NaN NaN ; rvs ];
      RV = assignFrom( TR( rv ,SA) , RV , 1e-5 );

      
      lvl = boolean_setdiff( lv , rv );
      lvs = boolean_intersect( lv , rv );
      
      lv = [ lvl ; NaN NaN ; lvs ];
      LV = assignFrom( TR( lv ,SA) , LV , 1e-5 );
      
      
%       
%       
%     % EPI is arranged as:
%     %   -Superior insertion point through Inferior insertion point via the
%     %    lateral free wall of the left ventricle.
%     %   -NaN NaN;
%     %   -Inferior insertion point (again, repeated) through the Superior 
%     %    insertion point via the setpal wall.
%     EPI = [ CleanSegments( [ S ; EPI( (asp1):end ,:) ; EPI( 1:ai ,:) ; I ] ) ;...
%             NaN NaN ; ...
%             CleanSegments( [ I ; EPI( (aip1):as ,:) ; S ] ) ];
% 
%     % EPI is arranged as:
%     %   -Inferior insertion point through Superior insertion point via the
%     %    lateral free wall of the right ventricle.
%     %   -NaN NaN;
%     %   -Superior insertion point (again, repeated) through the Inferior 
%     %    insertion point via the setpal wall.
%     RV = [ CleanSegments( [ I ; RV( (bip1):end ,:) ; RV( 1:bs ,:) ; S ] ) ;...
%            NaN NaN ; ...
%            CleanSegments( [ S ; RV( (bsp1):bi ,:) ; I ] ) ];
      
      HS{h,2} = LV;
      HS{h,4} = RV;
    end
  end
    
  if any( mode(:) == 2 )
    for h = 1:firstSA-1
      %EPI analysis
      RV = HS{h,4};
      LV = HS{h,2};

      if      0
      elseif  isempty( LV ) &&  isempty( RV )
      elseif ~isempty( LV ) &&  isempty( RV )
      elseif  isempty( LV ) && ~isempty( RV )
        [LA,iLA] = LAplane( HS , h );

        rv = CleanSegments( tr( RV , iLA ) );
        out = [ rv( 1 ,:) ;
                rv(end,:) ];

        rvo = offset( polygon( rv ) , RV_WIDTH , 'round' );
        rvo = rvo( argmax( arrayfun( @(i)size(rvo(i).XY,1) , 1:size(rvo,1) ) ) );
        rvo = rvo.XY;
        rvo = booleanFromTop( rvo , out );

        epir = rvo;

        EPI = TR( [ epir ; NaN NaN ; NaN NaN ] ,LA);
        HS{h,2} = EPI;
      elseif ~isempty( LV ) && ~isempty( RV )
        [LA,iLA] = LAplane( HS , h );

        rv = CleanSegments( tr( RV , iLA ) );
        lv = CleanSegments( tr( LV , iLA ) );
        out = [ lv( 1 ,:) ;
                rv(end,:) ;
                lv( 1 ,:) + 5*( lv(end,:) - lv( 1 ,:) ) ;
                rv(end,:) + 5*( rv( 1 ,:) - rv(end,:) ) ];

        rvo = offset( polygon( rv ) , RV_WIDTH , 'round' );
        rvo = rvo( argmax( arrayfun( @(i)size(rvo(i).XY,1) , 1:size(rvo,1) ) ) );
        rvo = rvo.XY;
        rvo = booleanFromTop( rvo , out );

        epir = boolean_setdiff( rvo , lv  );
        [~,~,w] = ClosestElement( [ rvo ; NaN NaN ], ( epir( 1:end-1 ,:) + epir( 2:end ,:) )/2 );
        epir( 1:find( w > 1e-8 , 1 , 'last' ) ,:) = [];


        epil = boolean_setdiff( lv  , rvo );
        [~,~,w] = ClosestElement( [ lv ; NaN NaN ], ( epil( 1:end-1 ,:) + epil( 2:end ,:) )/2 );
        epil( find( w > 1e-8 , 1 )+1:end ,:) = [];

        EPI = TR( [ epir ; NaN NaN ; epil ] ,LA);
        EPI = assignFrom( EPI , LV , 1e-5 );
        HS{h,2} = EPI;

        %RV analysis
        rvl = boolean_setdiff( rv , lv );
        [~,~,w] = ClosestElement( [ rv ; NaN NaN ], ( rvl( 1:end-1 ,:) + rvl( 2:end ,:) )/2 );
        rvl( 1:find( w > 1e-8 , 1 , 'last' ) ,:) = [];

        rvs = boolean_intersect( lv , rv );

        R  = TR( [ rvl ; NaN NaN ; flip( rvs ,1) ] , LA );

        R = assignFrom( R , LV , 1e-5 );
        R = assignFrom( R , RV , 1e-5 );

        HS{h,4} = R;
      end
    end
    
    %%nothing to do with VLA
    %%nothing to do with LVOT

    %%SAs
    for h = firstSA:size(HS,1)
      if isempty( HS{h,2} ) || isempty( HS{h,4} ), continue; end
      
      %EPI analysis
      [SA,iSA] = SAplane( HS , h );

      RV = HS{h,4};
      LV = HS{h,2};

      rv = CleanSegments( tr( RV , iSA ) );
      lv = CleanSegments( tr( LV , iSA ) );
      
      rvo = offset( polygon( rv ) , RV_WIDTH , 'round' );
      rvo = rvo( argmax( arrayfun( @(i)size(rvo(i).XY,1) , 1:size(rvo,1) ) ) );
      rvo = rvo.XY;
    
      epir = boolean_setdiff( rvo , lv  );
      epil = boolean_setdiff( lv  , rvo );
      
      EPI = TR( [ epir ; NaN NaN ; epil ] ,SA);
      EPI = assignFrom( EPI , LV , 1e-5 );
      HS{h,2} = EPI;
      
      %RV analysis
      rvl = boolean_setdiff( rv , lv );
      rvs = boolean_intersect( lv , rv );
      
      R  = TR( [ rvl ; NaN NaN ; flip( rvs ,1) ] , SA );
      
      R = assignFrom( R , LV , 1e-5 );
      R = assignFrom( R , RV , 1e-5 );
      
      HS{h,4} = R;
    end
  end
  
  if any( mode(:) == 3 )
    HS = HS(:,1:min(4,end));
    for h = 1:size(HS,1)
      try
        Contour2Segments( HS{h,2} , 2 );
        HS{h,5} = Contour2Segments( HS{h,2} , 1 );
        HS{h,2} = Contour2Segments( HS{h,2} , 2 );
      end
    end
    try, HS{1,2} = flip( HS{1,2} ,1); end
    try, HS{1,5} = flip( HS{1,5} ,1); end
    for h = 1:size(HS,1)
      try
        Contour2Segments( HS{h,4} , 2 );
        HS{h,6} = Contour2Segments( HS{h,4} , 2 );
        HS{h,4} = Contour2Segments( HS{h,4} , 1 );
      end
    end
    for h = 1:size(HS,1)
      for c = 2:size(HS,2)
        if isempty( HS{h,c} ), continue; end
        HS{h,c} = CleanSegments( HS{h,c} );
      end
    end
  end
  
  if any( mode(:) == 4 )
    for h = 1:size(HS,1)
      HS{h,2} = vertcat( HS{h,[2 5]} );
      HS{h,4} = vertcat( HS{h,[4 6]} );
    end
    HS(:,5:end) = [];
  end
  
%   if true
%     try, HS{1,1}.INFO.SpatialTransform = LAplane( HS , 1 ); end
%     try, HS{2,1}.INFO.SpatialTransform = LAplane( HS , 2 ); end
%     for h = 4:size(HS,1)
%       try, HS{h,1}.INFO.SpatialTransform = SAplane( HS , h ); end
%     end
%   end

end

function [T,iT] = SAplane( HS , h )

  [~,T] = getPlane( HS{h,1} );
  
  EPIc = NaN( size(HS,1) ,2);
  LVc = NaN( size(HS,1) ,2);
  RVc = NaN( size(HS,1) ,2);
  for h = 4:size(HS ,1)
    try, EPIc(h,:) = center( transform( HS{h,2} , T ) ); end
    try, LVc(h,:)  = center( transform( HS{h,3} , T ) ); end
    try, RVc(h,:)  = center( transform( HS{h,4} , T ) ); end
  end
  
  EPIc( any( ~isfinite( EPIc ) ,2) ,:) = [];
  LVc(  any( ~isfinite( LVc  ) ,2) ,:) = [];
  RVc(  any( ~isfinite( RVc  ) ,2) ,:) = [];
  

  RL = fisher( RVc.' , [LVc;EPIc].' );
  
  T = maketransform( 't2' , -mean( [ EPIc ; LVc ] ,1) , 'rz' , -atan2d( RL(2) , RL(1) ) ) * T;
  

  
  
  %where is the RV
  atLeft = 0; atRight = 0;
  for h = 4:size(HS ,1)
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
  
%   try,    C = centroid( polygon( xy ) );
%   catch,
    C = mean( xy ,1);
%   end
end
function [T,iT] = LAplane( HS , h )

  idBasalPlane = find( all( ~cellfun('isempty',HS(:,2:4)) ,2) , 1 , 'last' );
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

    d = ipd( X , Y );
    d( d > thr ) = Inf;
    [d,id] = min( d , [] , 2 );
    w = isfinite(d);
    
    X( w ,:) = Y( id(w) ,:);

end
function C = booleanFromTop( A , TOP )
  [~,ord] = sort( TOP(:,1) , 'ascend' );
  TOP = TOP(ord,:);
  m = -Inf;
  m = max( m , max( A(:,2) ) );
  m = max( m , max( TOP(:,2) ) );
  m = m + max( diff( range(A(:,2)) ) , eps(m)*1e8 );
  
  TOP = [ TOP ; TOP(end,1) , m ; TOP(1,1) , m ];
  
  C = boolean_setdiff( A , TOP );
end
function C = boolean_setdiff( A , B )
  A = CleanSegments( A(:,1:2) );
  B = CleanSegments( B(:,1:2) );

  C = setdiff( polygon( A ) , polygon( B ) );
  C = C( argmax( arrayfun( @(i)size(C(i).XY,1) , 1:size(C,1) ) ) );
  C = OrientSegments( C.XY );

  [~,~,C(:,3)] = ClosestElement( B , C );
  try
    w = inpoly( C(:,1:2).' , B.' );
  catch
    w = inpolygon( C(:,1) , C(:,2) , B(:,1) , B(:,2) );
  end
  C( ~~w ,3) = -1;

  C = circshift( C , [1-max( 3 , min( size(C,1)-3 , argmax(C(:,3)) ) ) , 0 ] );
  w = find( C(:,3) <= 1e-8 );
  if ~isempty( w )
    C = C( [ w(end):end , 1:w(1) ] ,1:2);
  end
  C = C(:,1:2);
end
function C = boolean_intersect( A , B )
  A = CleanSegments( A(:,1:2) );
  B = CleanSegments( B(:,1:2) );

  C = setdiff( polygon( B ) , polygon( A ) );
  C = C( argmax( arrayfun( @(i)size(C(i).XY,1) , 1:size(C,1) ) ) );
  C = flip( OrientSegments( C.XY ) , 1 );

  [~,~,C(:,3)] = ClosestElement( A , C );

  C = circshift( C , [1-argmax(C(:,3)) , 0 ] );
  w = find( C(:,3) > 1e-8 );
  C = C(:,1:2);
  C( w , :)=[];
end
function X = CleanSegments( X )
  X( any( ~isfinite(X) ,2) ,:) = [];
  while 1
    l2 = find( sum( diff( X( [1:end 1] ,:) ,1,1).^2 ,2) == 0 );
    if isempty( l2+1 ), break; end
    X( l2 ,:) = [];
  end
end
