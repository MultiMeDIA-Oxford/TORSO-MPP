function [p_,err] = invmaketransform( T , f , p , TOL )
% 
% T = maketransform( 'rxyz',[40 30 20] ,'t',[10 20 30],'s',2 );
%
% p = invmaketransform( T , @(p) {'t',p(1:3),'rzxz',p(4:6),'s',p(7)} );
%
% [p,err] = invmaketransform( T , @(p) {'l_affine',p(8:19),'center',p(1:3),'s',p(7),'rxyz',p(4:6),'s',p(20)} );
% 
% [p,err] = invmaketransform( T , @(p) {'center',p(1:3),'rq',p(4:6),'s',p(7)} );
%

  if nargin < 3
    p = [];
  end

  if nargin < 4
    TOL = -eps(single(1));
  end
  
  if isequal( size( T ) , [3 3] )
    T(4,4) = 1;
  end
  
  if ~isequal( size( T ) , [4 4] ) && ~isempty( T )
    error('A 4x4 matrix expected');
  end
    
    
  if ischar( f )
    switch lower(f)
      case {'rxyz'}
        f = @(p) {'rxyz',p(1:3)};
        if isempty(p)
          if T(3,1) < +1
            if T(3,1) > -1
              y = asin( -T(3,1) );
              z = atan2( T(2,1) , T(1,1) );
              x = atan2( T(3,2) , T(3,3) );
            else %T(3,1)  = -1
              %Notauniquesolution:x-z = atan2( -T(2,3) , T(2,2) )
              y = +pi/2;
              z = -atan2( -T(2,3) , T(2,2) );
              x = 0;
            end
          else %T(3,1)  = +1
            %Notauniquesolution:x+z = atan2( -T(2,3) , T(2,2) )
            y = -pi/2;
            z = atan2( -T(2,3) , T(2,2) );
            x = 0;
          end
          p = [x;y;z]*180/pi;
        end
      case {'rxzy'}
        f = @(p) {'rxzy',p(1:3)};
        if isempty(p)
          if( T(2,1) < +1)
            if( T(2,1) > -1)
              z = asin( T(2,1) );
              y = atan2( -T(3,1) , T(1,1) );
              x = atan2( -T(2,3) , T(2,2) );
            else %T(2,1) = -1
              %Notauniquesolution:x-y = atan2( T(3,2) , T(3,3) )
              z = -pi/2;
              y = -atan2( T(3,2) , T(3,3) );
              x = 0;
            end
          else
            %Notauniquesolution:x+y = atan2( T(3,2) , T(3,3) )
            z = +pi/2;
            y = atan2( T(3,2) , T(3,3) );
            x = 0;
          end
          p = [x;z;y]*180/pi;
        end
      case {'ryxz'}
        f = @(p) {'ryxz',p(1:3)};
        if isempty(p)
          if( T(3,2) < +1)
            if( T(3,2)  > -1)
              x = asin( T(3,2) );
              z = atan2( -T(1,2) , T(2,2) );
              y = atan2( -T(3,1) , T(3,3) );
            else %T(3,2) = -1
              %Notauniquesolution:y-z = atan2( T(1,3) , T(1,1) )
              x = -pi/2;
              z = -atan2( T(1,3) , T(1,1) );
              y = 0;
            end
          else %T(3,2) = +1
            %Notauniquesolution:y+z = atan2( T(1,3) , T(1,1) )
            x = +pi/2;
            z = atan2( T(1,3) , T(1,1) );
            y = 0;
          end
          p = [y;x;z]*180/pi;
        end
      case {'ryzx'}
        f = @(p) {'ryzx',p(1:3)};
        if isempty(p)
          
          if( T(1,2) < +1)
            if( T(1,2) > -1)
              z = asin( -T(1,2) );
              x = atan2( T(3,2) , T(2,2) );
              y = atan2( T(1,3) , T(1,1) );
            else %T(1,2) = -1
              %Notauniquesolution:y-x = atan2( -T(3,1) , T(3,3) )
              z = +pi/2;
              x = -atan2( -T(3,1) , T(3,3) );
              y = 0;
            end
          else %T(1,2) = +1
            %Notauniquesolution:y+x = atan2( -T(3,1) , T(3,3) )
            z = -pi/2;
            x = atan2( -T(3,1) , T(3,3) );
            y = 0;
          end
          p = [y;z;x]*180/pi;
        end
      case {'rzyx'}
        f = @(p) {'rzyx',p(1:3)};
        if isempty(p)
          if T(1,3) < +1
            if T(1,3) > -1
              y = asin( T(1,3) );
              x = atan2( -T(2,3) , T(3,3) );
              z = atan2( -T(1,2) , T(1,1) );
            else %T(1,3)  = -1
              %Notauniquesolution:z-x = atan2( T(2,1) , T(2,2) )
              y = -pi/2;
              x = -atan2( T(2,1) , T(2,2) );
              z = 0;
            end
          else %T(1,3)  = +1
            %Notauniquesolution:z+x = atan2( T(2,1) , T(2,2) )
            y = +pi/2;
            x = atan2( T(2,1) , T(2,2) );
            z = 0;
          end
          p = [z;y;x]*180/pi;
        end
      case {'rzxy'}
        f = @(p) {'rzxy',p(1:3)};
        if isempty(p)
          if( T(2,3) < +1)
            if( T(2,3) > -1)
              x = asin( -T(2,3) );
              y = atan2( T(1,3) , T(3,3) );
              z = atan2( T(2,1) , T(2,2) );
            else %T(2,3) = -1
              %Notauniquesolution:z-y = atan2( -T(1,2) , T(1,1) )
              x = +pi/2;
              y = -atan2( -T(1,2) , T(1,1) );
              z = 0;
            end
          else %T(2,3) = +1
            %Notauniquesolution:z+y = atan2( -T(1,2) , T(1,1) )
            x = -pi/2;
            y = atan2( -T(1,2) , T(1,1) );
            z = 0;
          end
          p = [z;x;y]*180/pi;
        end

      case {'rxyx'}
        f = @(p) {'rxyx',p(1:3)};
        if isempty(p)
          if( T(1,1) < +1)
            if( T(1,1) > -1)
              y = acos( T(1,1) );
              x0 = atan2( T(2,1) , -T(3,1) );
              x1 = atan2( T(1,2) , T(1,3) );
            else % T(1,1)  = -1
              %%Notauniquesolution:x1-x0 = atan2( -T(2,3) , T(2,2) )
              y = pi;
              x0 = -atan2( -T(2,3) , T(2,2) );
              x1 = 0;
            end
          else % T(1,1)  = +1
            %%Notauniquesolution:x1+x0 = atan2( -T(2,3) , T(2,2) )
            y = 0;
            x0 = atan2( -T(2,3) , T(2,2) );
            x1 = 0;
          end
          p = [x1,y,x0]*180/pi;
        end
      case {'rxzx'}
        f = @(p) {'rxzx',p(1:3)};
        if isempty(p)
          if( T(1,1) < +1)
            if( T(1,1) > -1)
              z = acos( T(1,1) );
              x0 = atan2( T(3,1) , T(2,1) );
              x1 = atan2( T(1,3) , -T(1,2) );
            else % T(1,1)  = -1
              %%Notauniquesolution:x1-x0 = atan2( T(3,2) , T(3,3) )
              z = pi;
              x0 = -atan2( T(3,2) , T(3,3) );
              x1 = 0;
            end
          else % T(1,1)  = +1
            %%Notauniquesolution:x1+x0 = atan2( T(3,2) , T(3,3) )
            z = 0;
            x0 = atan2( T(3,2) , T(3,3) );
            x1 = 0;
          end
          p = [x1,z,x0]*180/pi;
        end
      case {'ryxy'}
        f = @(p) {'ryxy',p(1:3)};
        if isempty(p)
          if( T(2,2) < +1)
            if( T(2,2) > -1)
              x = acos( T(2,2) );
              y0 = atan2( T(1,2) , T(3,2) );
              y1 = atan2( T(2,1) , -T(2,3) );
            else % T(2,2)  = -1
              %%Notauniquesolution:y1-y0 = atan2( T(1,3) , T(1,1) )
              x = pi;
              y0 = -atan2( T(1,3) , T(1,1) );
              y1 = 0;
            end
          else % T(2,2)  = +1
            %%Notauniquesolution:y1+y0 = atan2( T(1,3) , T(1,1) )
            x = 0;
            y0 = atan2( T(1,3) , T(1,1) );
            y1 = 0;
          end
          p = [y1,x,y0]*180/pi;
        end
      case {'ryzy'}
        f = @(p) {'ryzy',p(1:3)};
        if isempty(p)
          if( T(2,2) < +1)
            if( T(2,2) > -1)
              z = acos( T(2,2) );
              y0 = atan2( T(3,2) , -T(1,2) );
              y1 = atan2( T(2,3) , T(2,1) );
            else % T(2,2)  = -1
              %%Notauniquesolution:y1-y0 = atan2( -T(3,1) , T(3,3) )
              z = pi;
              y0 = -atan2( -T(3,1) , T(3,3) );
              y1 = 0;
            end
          else % T(2,2)  = +1
            %%Notauniquesolution:y1+y0 = atan2( -T(3,1) , T(3,3) )
            z = 0;
            y0 = atan2( -T(3,1) , T(3,3) );
            y1 = 0;
          end
          p = [y1,z,y0]*180/pi;
        end
      case {'rzxz'}
        f = @(p) {'rzxz',p(1:3)};
        if isempty(p)
          if( T(3,3) < +1)
            if( T(3,3) > -1)
              x = acos( T(3,3) );
              z0 = atan2( T(1,3) , -T(2,3) );
              z1 = atan2( T(3,1) , T(3,2) );
            else % T(3,3)  = -1
              %%Notauniquesolution:z1-z0 = atan2( -T(1,2) , T(1,1) )
              x = pi;
              z0 = -atan2( -T(1,2) , T(1,1) );
              z1 = 0;
            end
          else % T(3,3)  = +1
            %%Notauniquesolution:z1+z0 = atan2( -T(1,2) , T(1,1) )
            x = 0;
            z0 = atan2( -T(1,2) , T(1,1) );
            z1 = 0;
          end
          p = [z1,x,z0]*180/pi;
        end
      case {'rzyz'}
        f = @(p) {'rzyz',p(1:3)};
        if isempty(p)
          if( T(3,3) < +1)
            if( T(3,3) > -1)
              y = acos( T(3,3) );
              z0 = atan2( T(2,3) , T(1,3) );
              z1 = atan2( T(3,2) , -T(3,1) );
            else % T(3,3)  = -1
              %%Notauniquesolution:z1-z0 = atan2( T(2,1) , T(2,2) )
              y = pi;
              z0 = -atan2( T(2,1) , T(2,2) );
              z1 = 0;
            end
          else % T(3,3)  = +1
            %%Notauniquesolution:z1+z0 = atan2( T(2,1) , T(2,2) )
            y = 0;
            z0 = atan2( T(2,1) , T(2,2) );
            z1 = 0;
          end
          p = [z1,y,z0]*180/pi;
        end
        
        
        
      case {'similarity','sim'}
        f = @(p) {'rxyz',p(1:3),'s',p(4),'t',p(5:7)};
        if isempty(p), p = [ 0 , 0 , 0 , det( T(1:3,1:3) )^(1/3) , T(1,4) , T(2,4) , T(3,4) ].'; end
      case {'rigid'}
        f = @(p) {'rxyz',p(1:3),'t',p(4:6)};
        if isempty(p), p = [0 , 0 , 0 , T(1,4) , T(2,4) , T(3,4) ].'; end
      case {'q'}
        f = @(p) {'q',p(1:3),'s',p(4),'t',p(5:7)};
        if isempty(p), p = [0 , 0 , 0 , det( T(1:3,1:3) )^(1/3) , T(1,4) , T(2,4) , T(3,4) ].'; end
      case {'et','t'},
        f = @(p) {'t',p(1:3)};
        if isempty(p), p = T(1:3,4); end
      case 'i',
        f = @(p) {'s',p(1)};
        if isempty(p), p = det( T(1:3,1:3) )^(1/3); end
      case 'it'
        f = @(p) {'s',p(1),'t',p(2:4)};
        if isempty(p), p = [ det( T(1:3,1:3) )^(1/3); T(1:3,4) ]; end
      case 'u',
        f = @(p) {'l_s',p(1)};
        if isempty(p), p = log( det( T(1:3,1:3) ) )/3; end
      case 'ut',
        f = @(p) {'l_s',p(1),'t',p(2:4)};
        if isempty(p), p = [ log( det( T(1:3,1:3) ) )/3 ; T(1:3,4) ]; end
      case 'f'
        f = @(p) {'s',p(1:3)};
        if isempty(p), p = svd( T(1:3,1:3) ); end
      case 'ft',
        f = @(p) {'s',p(1:3),'t',p(4:6)};
        if isempty(p), p = [ svd( T(1:3,1:3) ) ; T(1:3,4) ]; end
      case 's',
        f = @(p) {'l_s',p(1:3)};
        if isempty(p), p = log( svd( T(1:3,1:3) ) ); end
      case 'st'
        f = @(p) {'l_s',p(1:3),'t',p(4:6)};
        if isempty(p), p = [ log( svd( T(1:3,1:3) ) ); T(1:3,4) ]; end
      case 'r',
        f = @(p) {'l_xyz',p(1:3)};
        if isempty(p), p = se( real(logm( T(1:3,1:3) )) , [6;7;2] ); end
      case 'rt'
        f = @(p) {'l_xyzt',p(1:6)};
        if isempty(p), p = real( logm(T) ); p = p([7;9;2;13;14;15]); end
      case 'n'
        f = @(p) {'l_xyz',p(1:3),'s',p(4)};
        if isempty(p), p = [0;0;0; det( T(1:3,1:3) )^(1/3) ]; end
      case 'nt',
        f = @(p) {'l_xyz',p(1:3),'s',p(4),'t',p(5:7)};
        if isempty(p), p = [0;0;0; det( T(1:3,1:3) )^(1/3) ; T(1:3,4) ]; end      
      case 'm'
        f = @(p) {'l_xyzs',p(1:4)};
        if isempty(p), p = real(logm(T(1:3,1:3))); p = [ p([6;7;2]) ; trace(p)/3 ]; end
      case 'mt',
        f = @(p) {'l_xyzst',p(1:7)};
        if isempty(p), p = real(logm(T)); p = [ p([7;9;2]) ; trace(p)/3 ; p([13;14;15]) ]; end
      case 'g'
        f = @(p) {'generallinear9',p(1:9)};
        if isempty(p), p = vec( T(1:3,1:3) ); end
      case 'gt',
        f = @(p) {'generallinear',p(1:12)};
        if isempty(p), p = vec( T(1:3,:) ); end
      case 'a',
        f = @(p) {'l_affine9',p(1:9)};
        if isempty(p), p = vec( real(logm(T(1:3,1:3))) ); end
      case 'at',
        f = @(p) {'l_affine12',p(1:12)};
        if isempty(p), p = real(logm(T)); p = vec(p(1:4,:)); end
      case 'v',
        f = @(p) {'l_volumepreserving9',p(1:8)};
        if isempty(p), p = zeros(8,1); end
      case 'vt',        f = @(p) {'l_volumepreserving',p(1:11)};
        if isempty(p), p = zeros(11,1); end
      case 'p' , error('todavia no se como resolverlo!!!!');
      case 'pt', error('todavia no se como resolverlo!!!!');
      case 'l_sxyzt',
        f = @(p) {'l_sxyzt',p(1:7)};
        if isempty(p), p = real(logm(T)); p = [ trace(p)/3 ; p([7;9;2]) ; p([13;14;15]) ]; end
      case 'l_xyzt'
        f = @(p) {'l_xyzt',p(1:6)};
        if isempty(p), p = real( logm(T) ); p = p([7;9;2;13;14;15]); end
    end
    if nargin < 3
      p_ = p;
      return;
    end
  end
      

  norm2 = @(x) x(:).'*x(:);

  if isempty(p)
    while 1
      try
        tt = maketransform( f , p );
        break;
      end
      p = [ p ; 1/pi^exp(1) ];
      if numel(p) > 50
        error('!!!!!!!');
      end
    end
  else
    p = p(:);
  end

  if isempty(T)
    if nargout > 1, error('empty T'); end
    p_ = p;
    return;
  end

  ids_det = unique( [ find( abs( NumericalDiff( @(p) getE_det(p) , p     , 'i' ) ) > 1e-8 ) ...
                      find( abs( NumericalDiff( @(p) getE_det(p) , p+0.1 , 'i' ) ) > 1e-8 ) ] );
  if ~isempty(ids_det)
    E = getE_det( p );
    p(ids_det) = Optimize( @(pp) getE_det( setv( p , ids_det , pp ) ) , p(ids_det)     ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},'ls',{'quadratic','golden'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
%     if getE_det(p) == E
      p(ids_det) = Optimize( @(pp) getE_det( setv( p , ids_det , pp ) ) , p(ids_det)+0.1 ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},'ls',{'quadratic','golden'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
%     end
  end

  ids_rot = find( abs( NumericalDiff( @(p) getE_rot(p) , p     , 'i' ) ) > 1e-8 );  ids_rot = setdiff( ids_rot , ids_det );
  if ~isempty( ids_rot )
    p(ids_rot) = Optimize( @(pp) getE_rot( setv( p , ids_rot , pp ) ) , p(ids_rot) ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},'ls',{'quadratic','golden'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
  end

  ids_tra = find( abs( NumericalDiff( @(p) getE_tra(p) , p     , 'i' ) ) > 1e-8 );  ids_tra = setdiff( ids_tra , [ ids_det , ids_rot ] );
  if ~isempty( ids_tra )
    p(ids_tra) = Optimize( @(pp) getE_tra( setv( p , ids_tra , pp ) ) , p(ids_tra) ,'methods',{'quasinewton',50,'conjugate',50,'descendneg',1,'coordinate',1},'ls',{'quadratic','golden'} ,'noplot','verbose',0,struct('MAX_ITERATIONS',150,'MIN_ENERGY',1e-20));
  end
  if TOL < 0
  p = round(p*1000)/1000;
  end
  
  E = getE(p);  
  while E > abs(TOL)
    p_prev = p;
    
    p = Optimize( @(p) getE(p) , p ,'methods',{'quasinewton',200,'conjugate',200,'descendneg',1,'coordinate',1,'$BREAK$'},'ls',{'quadratic','golden'} ,'noplot','verbose',0,struct('MIN_ENERGY',1e-20));

    if isequal( p_prev , p )
      break;
    end

    E = getE(p);

  end
  if E > abs(TOL)
    warning( 'Discrepancy too high!! (%g)', E );
  end
  
%   p = ExhaustiveSearch( @(p) getE(p) , p , 10 , 3 ,'verbose');


  P = f( p );
  if nargout == 0
    for i = 1:numel(P)
      if isfloat( P{i} )
        for j = 1:numel( P{i} )
          P{i}(j) = eval( sprintf('%1.4e', P{i}(j) ) );
        end
      end
    end
    
    P = uneval( P );
    disp( P(2:end-1) );
  elseif nargout == 1
    p_ = p;
  elseif nargout == 2
    p_ = p;
    M = maketransform( P{:} );
    err = T - M;
  end
  
%   alpha = 1;
%   while alpha > 1e-12
%     [E,dE] = getE( p );
%     
%     disp( E );
% 
%     alpha = alpha*1.5;
%     while alpha > 1e-12
%       if  getE( p - alpha*dE(:) ) < E
%         break;
%       end
%       alpha = alpha/1.5;
%     end
%     
%     p = p - alpha*dE(:);
%   end
  

  function E = getE_det( p )

    M = maketransform( f , p );
    
    E = norm2( det( M(1:3,1:3) ) - det( T(1:3,1:3) ) );

  end


  function E = getE_rot( p )

    M = maketransform( f , p );
    
    E = norm2( M(1:3,1:3) - T(1:3,1:3) );

  end
  

  function E = getE_tra( p )

    M = maketransform( f , p );
    
    E = norm2( M(1:3,4) - T(1:3,4) );

  end


  function [E,dE] = getE( p )

    if nargout < 2
      M = maketransform( f , p );
      
      E = norm2( M - T );
    else
      [M,dM] = maketransform( f , p );
      
      E = norm2( M - T );

      dE = 2*vect( M - T )*dM;
      
      if numel(dE) ~= numel( p )
        dE = NumericalDiff( @(p) getE(p) , p , 'i' );
      end
    end
    
  end
  

end
