function [varargout] = meshQuality( M , varargin )
% 
% Per cell statistic
% Valid options are:
% for celltype == 3 (polyline)
%     length, l
% for celltype == 5 (triangle mesh)
%     lengths, l, edgelengths, el
%     minlength, minl
%     maxlength, maxl
%     angles, g
%     minangle, ming
%     maxangle, maxg
%     area, a
%     normal, n
%     heights, h
%     minheight, minh
%     maxheight, maxh
%     inradius, r, ir
%     circumradius, cr
%     aspectratio, ar
%     aspectfrobenius, af
%     edgeratio, er, lengthratio, lr
%     radiusratio, rr
%     relativesize, s
% for celltype == 10 (tetrahedra mesh)
%     lengths, l, edgelengths, el
%     minlength, minl
%     maxlength, maxl
%     angles, g, facangle
%     minangle, ming
%     maxangle, maxg
%     areas, a
%     volume, v
%     signedvolume, sv
%     orientation, o
%     inradius, r, ir
%     circumradius, cr
%     edgeratio, er, lengthratio, lr
%     radiusratio, rr
%     aspectratio, ar
%     relativesize, s, rs
%     heights, h
%     minheight, minh
%     maxheight, maxh
%     dihedral, d
%     mindihedral, mind
%     maxdihedral, maxd
% 

  if size( M.tri,2) > 4
    error('not implemented for cells larger than tetrahedra.');
  end
  
  M.celltype = meshCelltype( M );
  if numel( varargin ) == 0
    goods = true;
    switch M.celltype
      case 3
        EL = meshQuality( M , 'length' );
        goods = goods & EL > 0;
      case 5
        [ A , AR , AF , ER , MG , mG , RR ] = meshQuality( M , 'area' , 'aspectratio' , 'aspectfrobenius' , 'edgeratio' , 'maxangle' , 'minangle' , 'radiusratio' );
        goods = goods  &  A > 0;
        goods = goods  &  AR <= 1.3;
        goods = goods  &  AF <= 1.3;
        goods = goods  &  ER <= 1.3;
        goods = goods  &  MG >= 60 & MG <= 90;
        goods = goods  &  mG >= 30 & mG <= 60;
        goods = goods  &  RR <= 3;
      case 10
        [ V , ER , AR , mD , RR ] = meshQuality( M , 'volume' , 'edgeratio' , 'aspectratio' , 'mindihedral' , 'radiusratio' );
        goods = goods  &  V > 0;
        goods = goods  &  ER <= 3;
        goods = goods  &  AR <= 3;
        goods = goods  &  mD >= 40;
        goods = goods  &  RR <= 3;
    end
    varargout{1} = goods;
    return;
    
  elseif numel( varargin ) == 1 && isempty( varargin{1} )
    
%     error('not implemented yet');
    
    switch M.celltype
      case 3
      case 5
      case 10
        
        [ V , O , RR , EL , DI , FAC , H ] = meshQuality( M ,...
                                                          'volume' ,...
                                                          'orientation' ,...
                                                          'radiusratio' ,...
                                                          'edgelengths' ,...
                                                          'dihedral' ,...
                                                          'facangle' ,...
                                                          'heights' );
        M.triVOLUME         = V;
        M.triRELATIVE_SCALE = log2( V / mean( V ) );
        M.triORIENTATION    = O;
        M.triRADIUS_RATIO   = RR;
        M.triEDGE_RATIO     = max( EL ,[],2)./min( EL ,[],2);
        M.triMAX_DIHEDRAL   = max( DI ,[],2);
        M.triMIN_DIHEDRAL   = min( DI ,[],2);
        M.triRANGE_DIHEDRAL = M.triMAX_DIHEDRAL - M.triMIN_DIHEDRAL;
        M.triMAX_HEIGHT     = max( H , [],2);
        M.triMIN_HEIGHT     = min( H , [],2);
        M.triHEIGHT_RATIO   = M.triMAX_HEIGHT ./ M.triMIN_HEIGHT;
        
    end
    varargout{1} = M;
    
    return;
  end
  

  unitsDEGREE = true;
  
  
  P1 = []; P2 = []; P3 = []; P4 = [];
  %precomputed nodes coordinates
  if size( M.tri,2) > 0
    P1 = M.xyz( M.tri(:,1) ,:); P1(:,end+1:3) = 0;
  end
  if size( M.tri,2) > 1
    P2 = M.xyz( M.tri(:,2) ,:); P2(:,end+1:3) = 0;
  end
  if size( M.tri,2) > 2
    P3 = M.xyz( M.tri(:,3) ,:); P3(:,end+1:3) = 0;
  end
  if size( M.tri,2) > 3
    P4 = M.xyz( M.tri(:,4) ,:); P4(:,end+1:3) = 0;
  end


  fro = @(x) sqrt( sum( x.^2 ,2) );
  nor = @(x) bsxfun( @rdivide , x , sqrt( sum( x.^2 ,2) ) );
  cross = @(a,b)[ a(:,2).*b(:,3) - a(:,3).*b(:,2) ,...
                  a(:,3).*b(:,1) - a(:,1).*b(:,3) ,...
                  a(:,1).*b(:,2) - a(:,2).*b(:,1) ];
  
  L1 = []; L2 = []; L3 = []; L4 = []; L5 = []; L6 = [];
  function get_Ls, if ~isempty( L1 ), return; end
    if M.celltype >= 3
      L1 = P2 - P1;
    end
    if M.celltype >= 5
      L2 = P3 - P2;
      L3 = P1 - P3;
    end
    if M.celltype >= 10
      L4 = P4 - P1;
      L5 = P4 - P2;
      L6 = P4 - P3;
    end
  end

  E1 = []; E2 = []; E3 = []; E4 = []; E5 = []; E6 = [];
  function get_Es, if ~isempty( E1 ), return; end
    get_Ls;

    E1 = nor( L1 );
    E2 = nor( L2 );
    E3 = nor( L3 );
    E4 = nor( L4 );
    E5 = nor( L5 );
    E6 = nor( L6 );
  end

  A1 = []; A2 = []; A3 = []; A4 = [];
  function get_As, if ~isempty( A1 ), return; end
    get_Ls;
    
    if size( M.tri,2) > 2
      A1 = cross( L3 , L1 );
    end
    if size( M.tri,2) > 3
      A1 = -A1;
      A2 = cross( L1 , L5 );
      A3 = cross( L2 , L6 );
      A4 = cross( L3 , L4 );
    end
  end
  
  N1 = []; N2 = []; N3 = []; N4 = [];
  function get_Ns, if ~isempty( N1 ), return; end
    get_As;
    
  	N1 = nor( A1 );
    N2 = nor( A2 );
    N3 = nor( A3 );
    N4 = nor( A4 );
  end
  
  as = [];
  function get_as, if ~isempty( as ), return; end
    get_As;
    
    if M.celltype == 5
    	as = fro( A1 )/2;
    elseif M.celltype == 10
    	as = [ fro( A1 ) , fro( A2 ) , fro( A3 ) , fro( A4 ) ]/2;
    end
  end
  suma = [];
  function get_suma, if ~isempty( suma ), return; end
    get_as;
    
    suma = sum( as ,2);
  end

  vs = [];
  function get_vs, if ~isempty( vs ), return; end
    get_As; get_Ls;
    
    vs = - dot( A1 , L4 ,2)/6;
  end

  ls = [];
  function get_ls, if ~isempty( ls ), return; end
    get_Ls;
    
    if M.celltype == 3
      ls = fro( L1 );
    elseif M.celltype == 5
      ls = [ fro( L1 ) , fro( L2 ) , fro( L3 ) ];
    elseif M.celltype == 10
      ls = [ fro( L1 ) , fro( L2 ) , fro( L3 ) , fro( L4 ) , fro( L5 ) , fro( L6 ) ];
    end
  end
  minl = [];
  function get_minl, if ~isempty( minl ), return; end
    get_ls;
    
    minl = min( ls , [] ,2);
  end
  maxl = [];
  function get_maxl, if ~isempty( maxl ), return; end
    get_ls;
    
    maxl = max( ls , [] ,2);
  end
  suml = [];
  function get_suml, if ~isempty( suml ), return; end
    get_ls;
    
    suml = sum( ls ,2);
  end

  gs = [];
  function get_gs, if ~isempty( gs ), return; end
    get_Es;
  
    if unitsDEGREE
      g = @(a,b) 2 * atan2d( fro( a+b ) , fro( a-b ) );
    else
      g = @(a,b) 2 * atan2( fro( a+b ) , fro( a-b ) );
    end
    
    if M.celltype == 5
      gs = [ g( E1 , E3 ) , g( E1 , E2 ) , g( E2 , E3 ) ];
    elseif M.celltype == 10
      gs = [ g( E1 , E2 ) , g( E2 , E3 ) , g( E3 , E1 ) ,...
             g( E1 , E5 ) , g( E5 , E4 ) , g( E4 , E1 ) ,...
             g( E2 , E6 ) , g( E6 , E5 ) , g( E5 , E2 ) ,...
             g( E3 , E4 ) , g( E4 , E6 ) , g( E6 , E3 ) ];
    end
  end
  ming = [];
  function get_ming, if ~isempty( ming ), return; end
    get_gs;
    
    ming = min( gs , [] ,2);
  end
  maxg = [];
  function get_maxg, if ~isempty( maxg ), return; end
    get_gs;
    
    maxg = max( gs , [] ,2);
  end
  
  ds = [];
  function get_ds, if ~isempty( ds ), return; end
    get_Ns; 
    
    ON1 = N1; w = dot( ON1 , L4 ,2) > 0; if any(w),
      ON1(w,:) = -ON1(w,:); end
    ON2 = N2; w = dot( ON2 , L2 ,2) > 0; if any(w),
      ON2(w,:) = -ON2(w,:); end
    ON3 = N3; w = dot( ON3 , L3 ,2) > 0; if any(w),
      ON3(w,:) = -ON3(w,:); end
    ON4 = N4; w = dot( ON4 , L1 ,2) > 0; if any(w),
      ON4(w,:) = -ON4(w,:); end
  
    if unitsDEGREE
%       dihedral = @(a,b) min( asind( fro(a-b)/2 ) , asind( fro(a+b)/2 ) )*2;
%       dihedral = @(a,b) asind( fro(a-b)/2 ) *2;
      dihedral = @(a,b) acosd( -dot(a,b,2) );
    else
%       dihedral = @(a,b) min( asin( fro(a-b)/2 ) , asin( fro(a+b)/2 ) )*2;
%       dihedral = @(a,b) asin( fro(a-b)/2 ) *2;
      dihedral = @(a,b) acos( -dot(a,b,2) );
    end

    ds = [  dihedral( ON1 , ON2 ) ,...
            dihedral( ON1 , ON3 ) ,...
            dihedral( ON1 , ON4 ) ,...
            dihedral( ON2 , ON3 ) ,...
            dihedral( ON2 , ON4 ) ,...
            dihedral( ON3 , ON4 ) ];
  end
  mind = [];
  function get_mind, if ~isempty( mind ), return; end
    get_ds;
    
    mind = min( ds , [] ,2);
  end
  maxd = [];
  function get_maxd, if ~isempty( maxd ), return; end
    get_ds;
    
    maxd = max( ds , [] ,2);
  end

  varargout = cell(1,numel(varargin));
  for v = 1:numel( varargin )
    if ~ischar( varargin{v} ), error('quality property must be a string.'); end
    switch sprintf( '%s.%d' , lower(varargin{v}) , M.celltype )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case {'length.3','l.3','edgelengths.3','el.3'}
  get_ls;                    varargout{v} = ls;
      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case {'lengths.5','l.5','edgelengths.5','el.5'}
  get_ls;                    varargout{v} = ls;
case {'minlength.5','minl.5'}
  get_minl;                  varargout{v} = minl;
case {'maxlength.5','maxl.5'}
  get_maxl;                  varargout{v} = maxl;
case {'angles.5','g.5'}
  get_gs;                    varargout{v} = gs;
case {'minangle.5','ming.5'}
  get_ming;                  varargout{v} = ming;
case {'maxangle.5','maxg.5'}
  get_maxg;                  varargout{v} = maxg;
case {'area.5','a.5'}
  get_as;                    varargout{v} = as;
case {'normal.5','n.5'}
  get_Ns;                    varargout{v} = N1;
case {'heights.5','h.5'}
  get_as; get_ls;            varargout{v} = bsxfun( @rdivide , as , ls )*2;
case {'minheight.5','minh.5'}
  get_as; get_ls;            varargout{v} = min( bsxfun( @rdivide , as , ls ) , [] , 2 )*2;
case {'maxheight.5','maxh.5'}
  get_as; get_ls;            varargout{v} = max( bsxfun( @rdivide , as , ls ) , [] , 2 )*2;
case {'inradius.5','r.5','ir.5','in.5'}
  get_as; get_suml;          varargout{v} = 2 * as ./ suml;
case {'circumradius.5','cr.5','circumr.5'}
  get_as; get_ls;            varargout{v} = prod( ls ,2) ./ ( 4 * as );
case {'aspectratio.5','ar.5'}
  get_as; get_suml; get_maxl; varargout{v} = ( maxl .* suml ) ./ ( 4 * sqrt(3) * as );
case {'aspectfrobenius.5','af.5'}
  get_as; get_ls;            varargout{v} = sum( ls.^2 ,2) ./ ( 4 * sqrt(3) * as );
case {'edgeratio.5','er.5','lengthratio.5','lr.5'}
  get_minl; get_maxl;        varargout{v} = maxl ./ minl;
case {'radiusratio.5','rr.5'}
  get_ls; get_as; get_suml;

  varargout{v} = ( prod( ls , 2 ) ./ ( 4 * as ) )./...
                 ( 2 * as ./ suml               )/2;
case {'relativesize.5','s.5','rs.5'}
  get_as;
  
  r = as ./ mean( as );
  varargout{v} = min( r , 1./r );
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case {'lengths.10','l.10','edgelengths.10','el.10'}
  get_ls;                    varargout{v} = ls;
case {'minlength.10','minl.10'}
  get_minl;                  varargout{v} = minl;
case {'maxlength.10','maxl.10'}
  get_maxl;                  varargout{v} = maxl;
case {'angles.10','g.10','facangle.10'}
  get_gs;                    varargout{v} = gs;
case {'minangle.10','ming.10'}
  get_ming;                  varargout{v} = ming;
case {'maxangle.10','maxg.10'}
  get_maxg;                  varargout{v} = maxg;
case {'areas.10','a.10'}
  get_as;                    varargout{v} = as;
case {'volume.10','v.10'}
  get_vs;                    varargout{v} = abs( vs );
case {'signedvolume.10','sv.10'}
  get_vs;                    varargout{v} = vs;
case {'orientation.10','o.10'}
  get_vs;                    varargout{v} = sign( vs );
case {'inradius.10','r.10','ir.10'}
  get_suma; get_vs;          varargout{v} = 3 * abs(vs) ./ suma;
case {'circumradius.10','cr.10','circumr.10'}
  get_vs; get_ls; get_As;
  
  varargout{v} = fro( bsxfun( @times , ls(:,4).^2 , A1 ) + ...
                      bsxfun( @times , ls(:,3).^2 , A2 ) + ...
                      bsxfun( @times , ls(:,1).^2 , A4 ) ) ./ ( 12 * abs(vs) );
case {'edgeratio.10','er.10','lengthratio.10','lr.10'}
  get_minl; get_maxl;        varargout{v} = maxl ./ minl;
case {'radiusratio.10','rr.10'}
  get_ls; get_As; get_suma; get_vs;

  varargout{v} = ( fro( bsxfun( @times , ls(:,4).^2 , A1 ) + ...
                        bsxfun( @times , ls(:,3).^2 , A2 ) + ...
                        bsxfun( @times , ls(:,1).^2 , A4 ) ) ./ ( 12 * abs(vs) ) )./...
                 ( 3 * abs(vs) ./ suma )/3;
case {'aspectratio.10','ar.10'}
  get_vs; get_maxl; get_suma;
  
  varargout{v} = ( maxl .* suma ) ./ ( 6 * sqrt(6) * abs(vs) );
case {'relativesize.10','s.10','rs.10'}
  get_vs;
  
  r = vs ./ mean( vs );
  varargout{v} = min( r , 1./r );
case {'heights.10','h.10'}
  get_vs; get_as;            varargout{v} = bsxfun( @rdivide , vs , as )*3;
case {'minheight.10','minh.10'}
  get_vs; get_as;            varargout{v} = min( bsxfun( @rdivide , vs , as ) , [] , 2 )*3;
case {'maxheight.10','maxh.10'}
  get_vs; get_as;            varargout{v} = max( bsxfun( @rdivide , vs , as ) , [] , 2 )*3;
case {'dihedral.10','d.10'}
  get_ds;                    varargout{v} = ds;
case {'mindihedral.10','mind.10'}
  get_mind;                  varargout{v} = mind;
case {'maxdihedral.10','maxd.10'}
  get_maxd;                  varargout{v} = maxd;
  
case {'not implemented'}  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  

%         case {'aspectbeta.10'}
% 
%         case {'aspectgamma.10'}%OK
%           V = dot( cross( L3 , L1 ) , L4 ,2)/6;
% 
%           varargout{v} = sqrt( ( l1.^2 + l2.^2 + l3.^2 + l4.^2 + l5.^2 + l6.^2 )/6 ).^3 * sqrt(2) ./ ( 12 * V );
% 
%         case {'aspectfrobenius.10'}
% 
% 
%         case {'collapseratio.10'}
%           H = @(A,b) abs( dot(A,b,2) ./ fro( A ) );
%           h0 = H( cross( L2 , L5 ) , L1 );
%           h1 = H( cross( L3 , L4 ) , L1 );
%           h2 = H( cross( L1 , L4 ) , L2 );
%           h3 = H( cross( L1 , L2 ) , L4 );
%           
%           varargout{v} = min( [ h0 ./ max( [ l2 , l5 , l6 ] , [] , 2 ) ,...
%                                 h1 ./ max( [ l3 , l4 , l6 ] , [] , 2 ) ,...
%                                 h2 ./ max( [ l1 , l4 , l5 ] , [] , 2 ) ,...
%                                 h3 ./ max( [ l1 , l2 , l3 ] , [] , 2 ) ] , [] , 2 );
%           
%         case {'condition.10'}
% 
%         case {'distortion.10'}
% 
%         case {'jacobian.10'} %OK
%           varargout{v} = dot( cross( L3 , L1 ) , L4 ,2);
% 
%         case {'scaledjacobian.10'}
% 
%         case {'shape.10'}
% 
%         case {'shapeandsize.10'}
%           
%         case {'aspectdelta.10'}
% 

      otherwise, error('invalid property "%s" for celltype %d (or not implemented yet! :P).',varargin{v},M.celltype);
    end
    
  end
          





end
