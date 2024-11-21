function [D,A] = NumericalDiff( F , x , method , varargin )

if 0

  F = @(x) expm( [x(1) 1000; x(2) 1e-6] );
  x = [1;2e-8]; F(x)

  NumericalDiff(@(z)F(z),x,'c','plot',10.^(-20:0.5:-1),'gt',d_expm([x(1) 1000; x(2) 1e-6])*[1 0;0 1;0 0;0 0] )
  
  
  d_expm([x(1) 1000; x(2) 1e-6])*[1 0;0 1;0 0;0 0] - NumericalDiff(@(z)F(z),x,'a')
  d_expm([x(1) 1000; x(2) 1e-6])*[1 0;0 1;0 0;0 0] - NumericalDiff(@(z)F(z),x,'a5')
  d_expm([x(1) 1000; x(2) 1e-6])*[1 0;0 1;0 0;0 0] - NumericalDiff(@(z)F(z),x,'a7')
  d_expm([x(1) 1000; x(2) 1e-6])*[1 0;0 1;0 0;0 0] - NumericalDiff(@(z)F(z),x,'i')
  d_expm([x(1) 1000; x(2) 1e-6])*[1 0;0 1;0 0;0 0] - NumericalDiff(@(z)F(z),x,'d')

  NumericalDiff(@(z)F(z),x,-3:3,'plot',10.^(-20:0.05:-1),'gt',d_expm([x(1) 1000; x(2) 1e-6])*[1 0;0 1;0 0;0 0] )

end


  if nargin < 3
    method = 'adaptive';
  end
  if ~ischar( method )
    stencil = method;
    method  = 'stencil';
  end
  
  if isempty( varargin ), varargin = {[]}; end
  
  h = [];
  if ~ischar( varargin{1} )
    h = varargin{1}; varargin(1) = [];
  end

  N = numel( x );

  
  [varargin, HESSIAN ] = parseargs( varargin , 'HESSian' , '$FORCE$' , true );
  
  if ~HESSIAN
  
    [varargin,iGT,GT] = parseargs(varargin,'GroundTruth','$DEFS$',0);
    if iGT
      L = @(x) log10( abs( x(:) ) );
    else
      L = @(x) x(:);
    end

    [kk, PLOTEAR ] = parseargs( varargin , 'plot' );
    if PLOTEAR
      if numel( varargin ) > PLOTEAR  && ~ischar( varargin{PLOTEAR+1} )
        PLOTEARh = varargin{PLOTEAR+1};
        varargin( [ PLOTEAR , PLOTEAR+1 ] ) = [];
      else
        varargin( PLOTEAR ) = [];
        switch method
          case {'complex','i'},  PLOTEARh = 10.^(-18:0.5:-2);
          case {'xdouble','xd'}, PLOTEARh = 10.^(-40:1:-8);
          case {'dual','dd'},    PLOTEARh = 10.^(-2:.1:5);
          otherwise,             PLOTEARh = 10.^(-12:0.2:-1);
        end
      end
      
      switch lower(method)
        case {'s','stencil'}, method = stencil;
      end


      hFig = figure('Units','pixels','Position',[300 400 600 500],'IntegerHandle','off','NextPlot','new','NumberTitle','off','DockControls','on','WindowStyle','normal','MenuBar','figure','ToolBar','auto');
      hAxeD = axes('Parent',hFig,'Units','normalize','position',[0.1 0.4  0.88 0.55],'XScale','log');
      if iGT
        ylabel( hAxeD , 'log10 | D - GT |' );
      else
        ylabel( hAxeD , 'D' );
      end

      
      hAxeP = axes('Parent',hFig,'Units','normalize','position',[0.1 0.1  0.88 0.25],'XScale','log');
      xlabel( hAxeP , 'h' );
      ylabel( hAxeP , 'd_h D' );
      
      DD = NumericalDiff( @(z)F(z) , x , method,PLOTEARh(1) ) - GT;
      M  = size( DD , 1 );
      hDD = -ones( M , N );
      hPP = -ones( M , N );

      DD = cat( 3 , DD , NaN([M,N,numel(PLOTEARh)-1]) );
      deltah = vec( log10(PLOTEARh(3:end))-log10(PLOTEARh(1:end-2)) );
      for i = 1:M
        for j = 1:N
          c = rand(1,3);
          hDD(i,j) = line('Parent',hAxeD,'XData',PLOTEARh(:)       ,'YData',L( DD(i,j,:) ) ,'color',c,'marker','.');
          hPP(i,j) = line('Parent',hAxeP,'XData',PLOTEARh(2:end-1) ,'YData',log10(abs( ...
                        vec( DD(i,j,3:end)-DD(i,j,1:end-2) )./deltah ...
                      )) ,'color',c,'marker','.');
        end
      end


      for hh = 2:numel(PLOTEARh)
        h = PLOTEARh( hh );

        DD(:,:,hh) = NumericalDiff(@(z)F(z),x,method,h) - GT;
        for i = 1:M
          for j = 1:N
            set( hDD(i,j) ,'YData', L( DD(i,j,:) ) );
            set( hPP(i,j) ,'YData',log10(abs( ...
                        vec( DD(i,j,3:end)-DD(i,j,1:end-2) )./deltah ...
            )) );
          end
        end
        drawnow;
      end

      
      if strcmpi(method,'c') || strcmpi(method,'center')
      
        [DA,AA] = NumericalDiff(@(z)F(z),x,'adaptive');
        DA = DA - GT;
        for i = 1:M
          for j = 1:N
            hDA(i,j) = hline( L( DA(i,j) ) , 'Parent', hAxeD );
            hAA(i,j) = vline( AA(i,j) , 'Parent', hAxeD );
            hAP(i,j) = vline( AA(i,j) , 'Parent', hAxeP );
          end
        end
      
      elseif strcmpi(method,'5')

        [DA,AA] = NumericalDiff(@(z)F(z),x,'adaptive5');
        DA = DA - GT;
        for i = 1:M
          for j = 1:N
            hDA(i,j) = hline( L( DA(i,j) ) , 'Parent', hAxeD );
            hAA(i,j) = vline( AA(i,j) , 'Parent', hAxeD );
            hAP(i,j) = vline( AA(i,j) , 'Parent', hAxeP );
          end
        end
        
      else
        
        hDA = [];
        hAA = [];
        hAP = [];
        
      end

      I = eEntry('Parent',hFig,'Position',[ 0 0 100 30],'size','small','IValue',1,'Range',[1 M]);
      J = eEntry('Parent',hFig,'Position',[40 0 100 30],'size','small','IValue',1,'Range',[1 N]);

      uicontrol('Parent',hFig,'style','pushbutton','position',[100 0 40 20],'string','ALL','callback',@(h,e)showALL);

      I.callback_fcn = @(x) showIJ( x   , J.v );
      J.callback_fcn = @(x) showIJ( I.v , x   );

      linkaxes( [ hAxeD , hAxeP ] , 'x' );

      if nargout > 0, D = []; end
      return;

    end
  end
    
    
  if HESSIAN
    method = [ 'hessian_' method ];
  end
    
  switch lower(method)
    
    case {'hessian_ff'}
      if isempty(h), h = 1e-8; end
      hh = h*h;

      Fx = F(x);
      M  = numel(Fx);
      D  = NaN(M*N,N);
      
      pi = reshape( zeros(N,1) , size(x) );
      pj = reshape( zeros(N,1) , size(x) );
      for i = 1:numel(x)
        pi(i) = h;
        for j = i:numel(x)
          pj(j)  = h;
          D(i,j) = ( F(x+pj+pi) - F(x+pj) - F(x+pi) + Fx )/(hh);
          D(j,i) = D(i,j);
          pj(j)  = 0;
        end
        pi(i) = 0;
      end

    case {'hessian_cc'}
      if isempty(h), h = 1e-5; end
      hh = h*h;

      Fx = F(x);
      M  = numel(Fx);
      D  = NaN(M*N,N);
      
      pi = reshape( zeros(N,1) , size(x) );
      pj = reshape( zeros(N,1) , size(x) );
      for i = 1:numel(x)
        pi(i) = h;
        for j = i:numel(x)
          pj(j)  = h;
          D(i,j) = ( F(x-pj-pi) - F(x-pj+pi) - F(x+pj-pi) + F(x+pj+pi) )/(4*hh);
          D(j,i) = D(i,j);
          pj(j)  = 0;
        end
        pi(i) = 0;
      end
    
    
    
    case {'s','stencil'}
      p = reshape( zeros(N,1) , size(x) );
      if isempty(h), h = 1e-4; end
      
      stencil = stencil*h;
      coeffs  = generateStencil( stencil , 1 );
      
      Fx = vec( F(x) );
      M  = numel(Fx);
      D  = zeros(M,N);
      
      for j = 1:numel(x)
        p(j)   = 1;
        for c = find( coeffs &  ~stencil )
          D(:,j) = D(:,j) + coeffs(c)*Fx;
        end
        for c = find( coeffs &   stencil )
          D(:,j) = D(:,j) + coeffs(c) * vec( F( x + stencil(c)*p ) );
        end
        p(j)   = 0;
      end

    case {'xd','xdouble'}
      p = xdouble( reshape( zeros(N,1) , size(x) ) );
      if isempty(h), h = 1e-30; end

      Fx = F( xdouble(x) );
%       Fx = F( (x) );
      M  = numel(Fx);
      D  = NaN(M,N);
      
      for j = 1:numel(x)
        p(j)   = h;
        D(:,j) = double( vec( F(x+p) - Fx )/h );
        p(j)   = 0;
      end
      
      
    case {'f','forward'}
      p = reshape( zeros(N,1) , size(x) );
      if isempty(h), h = 1.4901161193847656e-8; end

      Fx = F(x);
      M  = numel(Fx);
      D  = NaN(M,N);
      
      for j = 1:numel(x)
        p(j)   = h;
        D(:,j) = vec( F(x+p) - Fx )/h;
        p(j)   = 0;
      end

    case {'b','backward'}
      p = reshape( zeros(N,1) , size(x) );
      if isempty(h), h = 1.4901161193847656e-8; end

      Fx = F(x);
      M  = numel(Fx);
      D  = NaN(M,N);
      
      for j = 1:numel(x)
        p(j)   = h;
        D(:,j) = vec( Fx - F(x-p) )/h;
        p(j)   = 0;
      end

    case {'c','center'}
      p = reshape( zeros(N,1) , size(x) );
      if isempty(h), h = 6.055454452393343e-6; end

      p(1)   = h;
      D(:,1) = vec( -F(x-p) + F(x+p) )/(2*h);
      p(1)   = 0;
      M = size(D,1);
      
      D = cat( 2 , D , NaN(M,N-1) );
      
      for j = 2:numel(x)
        p(j)   = h;
        D(:,j) = vec( -F(x-p) + F(x+p) )/(2*h);
        p(j)   = 0;
      end

    case {'dual','d'}   %derivative with dual class
      Zr = zeros(size(x));
      Zd = zeros(size(x));
      if isempty(h), h = 1; end
      
      Zd(1) = h;
      p = dual( Zr , Zd );
      D(:,1) = vec( imag( F(x+p) ) )/h;
      Zd(1) = 0;
      M = size(D,1);
      
      D = cat( 2 , D , NaN(M,N-1) );
      
      for j = 2:numel(x)
        Zd(j) = h;
        p = dual( Zr , Zd );
        D(:,j) = vec( imag( F(x+p) ) )/h;
        Zd(j) = 0;
      end
      
    case {'complex','i'}   %complex step derivative approximation
      p = reshape( complex( zeros(N,1) , zeros(N,1) ) , size(x) );
      if isempty(h), h = 1e-15; end

      p(1)   = complex( 0 , h );
      D(:,1) = vec( imag( F(x+p) ) )/h;
      p(1)   = complex( 0 , 0 );
      M = size(D,1);
      
      D = cat( 2 , D , NaN(M,N-1) );
      
      for j = 2:numel(x)
        p(j)   = complex( 0 , h );
        D(:,j) = vec( imag( F(x+p) ) )/h;
        p(j)   = complex( 0 , 0 );
      end

    case {'5'}   %5 point stencil derivative
      p = reshape( zeros(N,1) , size(x) );
      if isempty(h), h = 7.40095979741405e-4; end
      
      p(1)   = h;
      D(:,1) = vec( F(x-2*p) - 8*F(x-p) + 8*F(x+p) - F(x+2*p) )/(12*h);
      p(1)   = 0;
      
      M = size(D,1);

      D = cat( 2 , D , NaN(M,N-1) );
      
      for j = 2:numel(x)
        p(j)   = h;
        D(:,j) = vec( F(x-2*p) - 8*F(x-p) + 8*F(x+p) - F(x+2*p) )/(12*h);
        p(j)   = 0;
      end
      
    case {'a','adaptive'}
      p = reshape( zeros(N,1) , size(x) );
      
      Fx = vec( F(x) );
      M  = numel( Fx );
      
      D  = NaN(M,N);
      A  = NaN(M,N);
      
      if isempty(h), h = 1; end
      eps3 = eps(1)^(1/3) * h;
      eps5 = eps(1)^(1/5) * h;
      
      for j=1:N
        d    = max( abs( x(j) ) , 1 ) * eps3;
%         d    = abs( x(j) ) * eps3;
        p(j) = d;
        D1   = vec( F(x+p) - F(x-p) )/(2*d);
        p(j) = 0;
        
        d    = max( abs( x(j) ) , 1 ) * eps5;
%         d    = abs( x(j) ) * eps5;
        p(j) = d;
        D3   = vec( - F(x-2*p) + 2*F(x-p) - 2*F(x+p) + F(x+2*p)  )/( 2*d^3 );
        p(j) = 0;

        for it = 1:10
          A(:,j) = 5.14223539198791e-6 * ( ( abs( Fx ) + abs( x(j) * D1 ) )./max( eps , abs( D3 ) ) ).^(1/3);
          for i = find( D1 ~= D(:,j) ).'
            p(j) = A(i,j);
            if A(i,j) == 0
              R    = Fx*0;
            else
              R    = vec( F(x+p) - F(x-p) )/( 2*A(i,j) );
            end
            if ~all(isfinite(R))
              R    = Fx*0;
            end
            D(i,j) = R(i);
            p(j) = 0;
          end
          if isequal( D1 , D(:,j) ), break; end
          D1 = D(:,j);
        end
        
      end

    case {'a5','adaptive5'}
      p = reshape( zeros(N,1) , size(x) );
      
      Fx = vec( F(x) );
      M  = numel( Fx );
      
      D  = NaN(M,N);
      A  = NaN(M,N);
      
      if isempty(h), h = 1; end
      eps5 = eps(1)^(1/5) * h;
      eps7 = eps(1)^(1/7) * h;
      
      for j=1:N
        d    = max( abs( x(j) ) , 1 ) * eps5;
        p(j) = d;
        D1   = vec( F(x-2*p) - 8*F(x-p) + 8*F(x+p) - F(x+2*p) )/(12*d);
        p(j) = 0;
        
        d    = max( abs( x(j) ) , 1 ) * eps7;
        p(j) = d;
        D5   = vec( -F(x-3*p) + 4*F(x-2*p) - 5*F(x-p) + 5*F(x+p) - 4*F(x+2*p) + F(x+3*p)  )/( 2*d^5 );
        p(j) = 0;

        for it = 1:10
          A(:,j) = 8.54949099450734e-4 * ( ( abs( Fx ) + abs( x(j) * D1 ) )./max( eps , abs( D5 ) ) ).^(1/5);
          for i = find( D1 ~= D(:,j) ).'
            p(j) = A(i,j);
            
            if A(i,j) == 0
              R    = Fx*0;
            else
              R    = vec( F(x-2*p) - 8*F(x-p) + 8*F(x+p) - F(x+2*p) )/(12*A(i,j));
            end
            if ~all(isfinite(R))
              R    = Fx*0;
            end
            
            D(i,j) = R(i);
            p(j) = 0;
          end
          if isequal( D1 , D(:,j) ), break; end
          D1 = D(:,j);
        end
        
      end
      
    case {'a7','adaptive7'}
      p = reshape( zeros(N,1) , size(x) );
      
      Fx = vec( F(x) );
      M  = numel( Fx );
      
      D  = NaN(M,N);
      A  = NaN(M,N);
      
      if isempty(h), h = 1; end
      eps7 = eps(1)^(1/7) * h;
      eps9 = eps(1)^(1/9) * h;
      
      for j=1:N
        d    = max( abs( x(j) ) , 1 ) * eps7;
        p(j) = d;
        D1   = vec( -F(x-3*p) + 9*F(x-2*p) - 45*F(x-p) + 45*F(x+p) - 9*F(x+2*p) + F(x+3*p) )/(60*d);
        p(j) = 0;
        
        d    = max( abs( x(j) ) , 1 ) * eps9;
        p(j) = d;
        D7   = vec( -F(x-4*p) + 6*F(x-3*p) - 14*F(x-2*p) + 14*F(x-p) - 14*F(x+p) + 14*F(x+2*p) - 6*F(x+3*p) + F(x+4*p) )/( 2*d^7 );
        p(j) = 0;

        for it = 1:10
          A(:,j) = 7.70909150071805e-3 * ( ( abs( Fx ) + abs( x(j) * D1 ) )./max( eps , abs( D7 ) ) ).^(1/7);
          for i = find( D1 ~= D(:,j) ).'
            p(j) = A(i,j);
            
            if A(i,j) == 0
              R    = Fx*0;
            else
              R    = vec( -F(x-3*p) + 9*F(x-2*p) - 45*F(x-p) + 45*F(x+p) - 9*F(x+2*p) + F(x+3*p) )/(60*A(i,j));
            end
            if ~all(isfinite(R))
              R    = Fx*0;
            end
            
            D(i,j) = R(i);
            p(j) = 0;
          end
          if isequal( D1 , D(:,j) ), break; end
          D1 = D(:,j);
        end
        
      end      
      
      
    case {'vpa'}
      if isempty(h), h = 1e-20; end
      
      h = vpa(h,25);
      x = vpa(x,25);

      Fx = F( x );
      M  = numel(Fx);
      D  = NaN(M,N);
      
      for j = 1:numel(x)
        xp     = x;
        xp(j)  = xp(j) + h;
        D(:,j) = double( vec( F(xp) - Fx )/h );
      end
      
    otherwise
      error('unknow method');
      
  end
      
%       case 'mp'             %multiple precision or high precision approximation
%                             %centered stencil and output as double
%         nBits = 2000;
%         if ~isempty( varargin ), nBits = varargin{1}; varargin(1) = []; end
% 
%         hexp  = 100;
%         if ~isempty( varargin ), hexp  = varargin{1}; varargin(1) = []; end
% 
%         hexp = -abs( hexp );
% 
%         x = mp(x,nBits);
%         h = mp(10,nBits)^hexp;
%         for i = 1:numel(x)
%           hi = x*0; hi(i) = h;
%           D(:,i) = vec( double( ( -F(x-hi) + F(x+hi)  )/(2*h) ) );
%         end
% 
%       case 'mpf'            %multiple precision or high precision approximation
%                             %forwar stencil and output as double
%         nBits = 2000;
%         if ~isempty( varargin ), nBits = varargin{1}; varargin(1) = []; end
% 
%         hexp  = 100;
%         if ~isempty( varargin ), hexp  = varargin{1}; varargin(1) = []; end
% 
%         hexp = -abs( hexp );
% 
%         x = mp(x,nBits);
%         h = mp(10,nBits)^hexp;
%         Fx = F(x);
%         for i = 1:numel(x)
%           hi = x*0; hi(i) = h;
%           D(:,i) = vec( double( ( -Fx + F(x+hi)  )/h ) );
%         end
% 
%       case 'mpmpf'          %multiple precision or high precision approximation
%                             %forward stencil and output as mp
%         nBits = 2000;
%         if ~isempty( varargin ), nBits = varargin{1}; varargin(1) = []; end
% 
%         hexp  = 100;
%         if ~isempty( varargin ), hexp  = varargin{1}; varargin(1) = []; end
% 
%         hexp = -abs( hexp );
% 
%         x = mp(x,nBits);
%         h = mp(10,nBits)^hexp;
%         Fx = F(x);
%         for i = 1:numel(x)
%           hi = x*0; hi(i) = h;
%           D(:,i) = vec( ( -Fx + F(x+hi)  )/h );
%         end
% 
%     end
%   else
%     switch lower(method)
% 
% 
%       case {'complex','i'}   %complex step derivative approximation
%         I = sqrt(-1);
%         
%         h1 = eps(1);
%         if ~isempty( varargin ), h1 = varargin{1}; varargin(1) = []; end
% 
%         h2 = sqrt(eps(1));
%         if ~isempty( varargin ), h2 = varargin{1}; varargin(1) = []; end
%         
%         for i = 1:numel(x)
%           hi = x*0; hi(i) = I*h1;
%           Fx = F(x+hi);
%           for j = i:numel(x)
%             hj = x*0; hj(j)= h2;
% %             D(i,j) = imag( F(x+hi+hj) - F(x+hi-hj) )/(2*h1*h2);
%             D(i,j) = imag( -Fx + F(x+hj+hi) )/(h1*h2);
%             D(j,i) = D(i,j);
%           end
%         end
% 
% 
%       case {'mp'}
%         nBits = 2000;
%         if ~isempty( varargin ), nBits = varargin{1}; varargin(1) = []; end
% 
%         hexp  = 100;
%         if ~isempty( varargin ), hexp  = varargin{1}; varargin(1) = []; end
% 
%         hexp = -abs( hexp );
% 
%         h = mp(10,nBits)^hexp;
% 
%         x  = mp(x,nBits);
%         Fx = F(mp(x,nBits));
%         for i = 1:numel(x)
%           hi = x*0; hi(i)= h;
%           for j = i:numel(x)
%             disp([i j]);
%             hj = x*0; hj(j)= h;
%             D(i,j) = double( ( F(hj+hi+x) - F(hj+x) - F(hi+x) + Fx )/(h*h) );
%             D(j,i) = D(i,j);
%           end
%         end
% 
%     end
%   end


  function x = vec(x)
    x = x(:);
    try, x = full(x); end
  end

  function showIJ( i , j )
    set( hDD , 'visible' , 'off' );
    set( hPP , 'visible' , 'off' );
    set( hDA , 'visible' , 'off' );
    set( hAA , 'visible' , 'off' );
    set( hAP , 'visible' , 'off' );

    set( [ hDD(i,j) , hPP(i,j) ] , 'Visible','on' );
    if ~isempty( hAA )
      set( [ hDA(i,j) , hAA(i,j) , hAP(i,j) ] , 'Visible','on' );
    end
    
    xl = range( get(hDD(i,j),'XData') );
    set( hAxeD , 'XLim', xl ,...
                 'YLim', centerscale( range( get(hDD(i,j),'YData') ) , 1.2 ) );
    
    set( hAxeP , 'XLim', xl ,...
                 'YLim', centerscale( range( get(hPP(i,j),'YData') ) , 1.2 ) );
               
    if isequal( size(GT) , [ M , N ] )
      set( hFig , 'Name', sprintf('Deriv  F(%d)  with respect to  x(%d)     (GT: %.8e)', i,j,GT(i,j) ) );
    else
      set( hFig , 'Name', sprintf('Deriv  F(%d)  with respect to  x(%d)', i,j) );
    end
  end

  function showALL
    set( hDD , 'visible' , 'on' );
    set( hPP , 'visible' , 'on' );
    set( hDA , 'visible' , 'on' );
    set( hAA , 'visible' , 'on' );
    set( hAP , 'visible' , 'on' );
    
    set( hFig , 'Name', '' );
  end

  
end
