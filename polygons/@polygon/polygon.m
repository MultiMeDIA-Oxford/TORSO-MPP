function P = polygon( XY , varargin )

  if ischar( XY )
    DEF = 200;
    [varargin,i,DEF] = parseargs(varargin,'DEF','$DEFS$',DEF);
    
    INF = 1e20;
    
    switch lower( XY )
      case {'c','circle'}
        t = linspace( 0 , 2*pi , DEF+1 );
        t = t(1:end-1).';
        XY = [ cos(t) , sin(t) ];
        
      case {'sq','square','box'}
        XY = [0 0;1 0; 1 1; 0 1];
        
      case {'centeredbox','cbox'}
        XY = [0 0;1 0; 1 1; 0 1]-0.5;

      case {'t','triangle'}
        XY = [0 0 ; 1 0; 0 1];
        
      case {'eq','teq','equilateraltriangle'}
        XY = [ -0.5 0 ; 0.5 0 ; 0  sqrt(3)/2 ];
        
      case {'semiplaney','sy','semiplaney+','sy+'}
        XY = [ -INF 0 ; INF 0 ; INF INF ; -INF INF ];
        
      case {'semiplanex','sx','semiplanex+','sx+'}
        XY = [ 0 -INF ; INF -INF ; INF INF ; 0 INF ];
        
      case {'semiplaney-','sy-'}
        XY = [ -INF -INF ; INF -INF ; INF 0 ; -INF 0 ];
        
      case {'semiplanex-','sx-'}
        XY = [ -INF -INF ; 0 -INF ; 0 INF ; -INF INF ];
        
      otherwise
        error('unknow shape');
    end
    
    P.XY = { XY , 1 };
  elseif iscell( XY )
    
    if size(XY,2) ~= 2, error('se esperaba contours_x_2'); end
    
    solids = find( cell2mat( XY(:,2) ) ==  1 );
    holes  = find( cell2mat( XY(:,2) ) == -1 );
    curves = find( cell2mat( XY(:,2) ) ==  0 );
    
    
    P.XY = XY( [ solids(:) ; holes(:) ; curves(:) ], :);
    
  else
    
    if ndims( XY ) > 2,     error('ndims( XY ) > 2');     end
    if size( XY , 2 ) ~= 2, error('size( XY , 2 ) ~= 2'); end
    if size( XY , 1 ) < 3,  error('size( XY , 1 ) < 3');  end

    %hay que chequear que no hay 2 puntos consecutivos iguales, y si los hay
    %quitarlos por las dudas y ver si quedan al menos 3 puntos!!!.

    XY = double( XY );
    
    P.XY = { XY , 1 };
    
  end
  
  
  P = class(P,'polygon');

end
