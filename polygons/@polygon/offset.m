function PO = offset( P , d , varargin )

  if ~isscalar( d ), error('d should be a scalar'); end
  
  MODE = 'straight';
  [varargin,MODE] = parseargs(varargin,'ROUNDed','$FORCE$',{'round'    ,MODE});
  [varargin,MODE] = parseargs(varargin,'straight','$FORCE$',{'straight',MODE});

  PO = P;
  if d == 0, return; end

  if strcmp( MODE , 'round' )
    t = linspace( 0 , 360 , 50 ).'; t(end) = [];
    cs = cosd(t)*d;
    sn = sind(t)*d;
  end
  
  
  B = {};
  for i = 1:size( P.XY , 1 )
    nP = [NaN , NaN];
    XY = P.XY{i,1};
    if isequal( XY(1,:) , XY(end,:) ), XY(end,:) = []; end
    XY( ~sum( diff(XY,1,1).^2 , 2 ) ,:) = [];
    
    L = size( XY ,1);
    pid = @(i)mod( i , L ) + 1;
    for s = 0:L-1
      S = P.XY{i,1}( pid(s-1:s+2) , : );
      N = normalize( diff( S , 1 , 1 )*[0 1;-1 0] , 2 );

      switch MODE
        case 'straight'
          SU = S(2:3,:) + d*[1;1]*N(2,:);
          SD = S(2:3,:) - d*[1;1]*N(2,:);
          
          N2 = [1;1]*S(2,:) + [0;1]*(N(1,:) + N(2,:));
          N3 = [1;1]*S(3,:) + [0;1]*(N(2,:) + N(3,:));
          
          B{end+1,1} = [ S(1,:) ; intersect( SD , N2 ) ; intersect( SD , N3 ) ; S(4,:) ; intersect( SU , N3 ) ; intersect( SU , N2 ) ];
        case 'round'
          C = [ cs + S(2,1) , sn + S(2,2) ; cs + S(3,1) , sn + S(3,2) ];
          C = C( unique( vec(convhulln(C).') ,'stable' ) , : );
          
          B{end+1,1} = C;          
      end
      
    end

    BB = { B{1} , 1 }; B(1) = [];
    while numel(B)
      try
        BB = polygon_mx( BB , { B{1} , 1 } ,'union' );
        B(1) = [];
      catch
        B = B([2:end 1]);
      end
    end
    
    if d > 0
      PO.XY = polygon_mx( PO.XY , BB , 'union' );
    else
      PO.XY = polygon_mx( PO.XY , BB , 'difference' );
    end
    
  end


  function xy = intersect( ab , cd )
    uv = [ diff(ab,1,1).' , diff(cd,1,1).' ] \ ( cd(1,:) - ab(1,:) ).';
    xy = ( ( ab(1,:) + uv(1)*diff(ab,1,1) ) +  ( cd(1,:) - uv(2)*diff(cd,1,1) ) )/2;
    if 1
      [md,cp] = min( sum( bsxfun( @minus , nP , xy ).^2 , 2 ) );

      if md < 1e-9
        xy = nP(cp,:);
      else
        nP = [ nP ; xy ];
      end
    end
  end
  
end
