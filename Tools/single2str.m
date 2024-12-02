function S = single2str( x , level )



  if ~isscalar( x )      , error( 'only a single real scalar number accepted.' ); end
  if ~isa( x , 'single' ), error( 'only a single number accepted.' ); end
  if imag( x ) ~= 0      , error( 'only a single real number accepted.' ); end

  if nargin < 2 , level = 9; end

  
  if isidentical( x , single(    0 ) ),  S =    '0'; return; end
  if isidentical( x , single(   -0 ) ),  S =   '-0'; return; end
  if isidentical( x , single(  NaN ) ),  S =  'NaN'; return; end
  if isidentical( x , single( -NaN ) ),  S = '-NaN'; return; end
  if isidentical( x , single(  Inf ) ),  S =  'Inf'; return; end
  if isidentical( x , single( -Inf ) ),  S = '-Inf'; return; end
  if isidentical( x , single(    1 ) ),  S =    '1'; return; end
  if isidentical( x , single(   pi ) ),  S =   'pi'; return; end
  if isidentical( x , single(  -pi ) ),  S =  '-pi'; return; end

  
  nolast = @(x) x(1:end-1);

  xx = typecast( x , 'uint8' );
  if ( isnan(x) || isinf(x) )
    S = [ 'typecast(uint8([' , nolast( sprintf('%d,',xx) ) , ']),''single'')' ];
    return;
  end


  nospaces = @(s) strrep( s , ' ' , '' );
  nobracks = @(s) strrep( strrep( s , '(' , '' ) , ')' , '' );
  

  Ss = { simple_single2str( x ) };
  
  if numel( Ss{1} ) < 4
    S = Ss{1};
    return; 
  end
  
  
  if level > 10
    y = 1/x;  if isinf(y) || isnan(y), y = 1; end
    if y < 0
      Ss{end+1} = [ '-1/' simple_single2str(-y) ];
    else
      Ss{end+1} = [  '1/' simple_single2str( y) ];
    end


    y = x/single(exp(1));  if isinf(y) || isnan(y), y = 1; end
    if y == 1
      Ss{end+1} = 'exp(1)';
    elseif y == -1
      Ss{end+1} = '-exp(1)';
    else
      Ss{end+1} = [  simple_single2str( y) '*exp(1)' ];
    end


    y = x/single(pi);  if isinf(y) || isnan(y), y = 1; end
    Ss{end+1} = [ simple_single2str(y) '*pi' ];

    
    y = x*single(exp(1));  if isinf(y) || isnan(y), y = 1; end
    if y == 1
      Ss{end+1} = '1/exp(1)';
    elseif y == -1
      Ss{end+1} = '-1/exp(1)';
    else
      Ss{end+1} = [     simple_single2str( y)  '/exp(1)' ];
    end


    y = x*x;  if isinf(y) || isnan(y), y = 1; end
    Ss{end+1} = [ 'sqrt(' simple_single2str( y)  ')' ];
    if x<0
      Ss{end} = [ '-'  Ss{end} ];
    end


    if x > 0
      y = sqrt(x);  if isinf(y) || isnan(y), y = 1; end
      Ss{end+1} = [ simple_single2str( y)  '^2' ];
    end


    y = exp(x);   if isinf(y) || isnan(y), y = 1; end
    Ss{end+1} = [ 'log(' simple_single2str( y)  ')' ];

    
    if x > 0
      y = log(x);  if isinf(y) || isnan(y), y = 1; end
      Ss{end+1} = [ 'exp(' simple_single2str( y)  ')' ];
    end

  
    y = 2^(x);  if isinf(y) || isnan(y), y = 1; end
    Ss{end+1} = [ 'log2(' simple_single2str( y)  ')' ];

    
    if x > 0
      y = log2(x);  if isinf(y) || isnan(y), y = 1; end
      Ss{end+1} = [ '2^(' simple_single2str( y)  ')' ];
      Ss{end+1} = nobracks( Ss{end} );
    end
  
  
    y = 10^(x);  if isinf(y) || isnan(y), y = 1; end
    Ss{end+1} = [ 'log10(' simple_single2str( y)  ')' ];

    
    if x > 0
      y = log10(x);  if isinf(y) || isnan(y), y = 1; end
      Ss{end+1} = [ '10^(' simple_single2str( y)  ')' ];
      Ss{end+1} = nobracks( Ss{end} );
    end

  end


  if level > 20
    for k = 0:( log10(abs(x)) )
      y1 = floor(x/10^k)*10^k; y2 = x - y1;
      Ss{end+1} = [ simple_double2str(y1) '+' simple_single2str(y2) ];

      y1 = ceil(x/10^k)*10^k; y2 = x - y1;
      Ss{end+1} = [ simple_single2str(y1) '-' simple_single2str(-y2) ];
    end  


    for k = [ primes(20) , single(pi) ]
      y = x/k; if isinf(y) || isnan(y), y = 1; end
      Ss{end+1} = [ simple_single2str(y) '*' simple_single2str(k) ];

      y = x*k; if isinf(y) || isnan(y), y = 1; end
      Ss{end+1} = [ simple_single2str(y) '/' simple_single2str(k) ];
    end
  end
  
  
  if level >= 100
    Ss{ end+1 } = inverse_calculator( x , level - 100 );
  end

  
  
  Ss = unique(Ss);
  %cellfun(@disp,  Ss)
  
  Ss = Ss( cellfun( @(s) teval(s) , Ss ) == x );
  [S,id] = min( cellfun( 'prodofsize' , Ss ) );
  S = Ss{id};
  
  
  

  

  
  
  function S = simple_single2str( x )

    S_i = sprintf('%d',x);
    if teval( S_i ) ~= x 
      S_i = [];
    end

    if  ~isempty( S_i )  &&  abs(x) < 999  &&  ~mod( x , 1)
      S = S_i;
      return;
    end

    S_0 = nospaces( sprintf('%30.20g',x) );
    

    S_d = []; S_e = []; S_f = []; S_f2 = []; S_r = []; S_r2 = []; S_s = []; S_s2 = []; S_m = []; S_m2 = [];

    if level > 0
      if abs( x ) < 1e20
        dig = 5;
        while eval(sprintf('single(%50.*f)',dig,x)) ~= x  , dig = dig+1;  end
        S_f = nospaces( sprintf('%20.*f',dig,x) );
        while teval( S_f(1:end-1) ) == x , S_f = S_f(1:end-1); end
      else
        S_f = [];
      end
      
%       S_f2 = num2strexact( x );
%       while teval( S_f2( 1:end-1 ) ) == x
%         S_f2 = S_f2( 1:end-1 );
%       end
%       if teval( S_f2 ) ~= x , S_f2 = []; end
    end
    
    
    if level > 1
      dig = 5;
      while eval( sprintf('single(%50.*e)',dig,x) ) ~= x, dig = dig+1;   end
      S_e = nospaces( sprintf('%50.*e',dig,x) );
      S_e = regexprep( S_e , '0+e' , 'e' );
      S_e = regexprep( S_e , 'e\+' , 'e' );
      S_e = regexprep( S_e , 'e0+' , 'e' );
      S_e = regexprep( S_e , 'e\-0+' , 'e-' );
      S_e = regexprep( S_e , 'e$' , '' );
    end
    
    
    if level > 2
      S_r = []; S_r2 = [];
      if abs(x) < 1e16
        S_r = nospaces( rat( x ,0 ) ); 
        S_r = regexprep( S_r , '^-?0[\+-]' , '' );
        if teval( S_r ) == x
          S_r2 = nobracks( S_r );
          if teval( S_r2 ) ~= x
            S_r2 = [];
          end
        else
          S_r = [];
        end
      end
    end
    
    
    if level > 3
      S_s = []; S_s2 = [];
      if abs(x) < 1e16
        S_s = nospaces( rats( x ,0 ) );
        if teval( S_s ) == x
          S_s2 = nobracks( S_s );
          if teval( S_s2 ) ~= x
            S_s2 = [];
          end
        else
          S_s = [];
        end
      end
    end
    

    if level > 4
      S_m = nospaces( char( sym( x , 'r' )) );
      if teval( S_m ) == x
        S_m2 = nobracks( S_m );
        if teval( S_m2 ) ~= x
          S_m2 = [];
        end
      else
        S_m = []; S_m2 = [];
      end
    end


    numels = [ numel(S_i) numel(S_0) numel(S_d) numel(S_e) numel(S_f) numel(S_f2) numel(S_r) numel(S_r2)  numel(S_s) numel(S_s2) numel(S_m) numel(S_m2) ];
    numels( ~numels ) = 100;
    
    [s,id] = min( numels );
    switch id
      case  1, S = S_i;
      case  2, S = S_0;
      case  3, S = S_d;
      case  4, S = S_e;
      case  5, S = S_f;
      case  6, S = S_f2;
      case  7, S = S_r;
      case  8, S = S_r2;
      case  9, S = S_s;
      case 10, S = S_s2;
      case 11, S = S_m;
      case 12, S = S_m2;
    end

  end

  
  function evv = teval( ev )
    evv = Inf;
    try, evv = single(eval(ev)); end
  end
  


end
