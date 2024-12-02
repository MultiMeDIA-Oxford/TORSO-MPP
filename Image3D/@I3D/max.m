function [ m , i ] = max( I , a , b )

  if     nargin == 1
    [m,i] = max( I.data(:) );

  elseif nargin==2
    if isa(a,'I3D')
      [m,i]= max( I.data , a.data );
    else
      [m,i]= max( I.data , a      );
    end
    
  elseif nargin==3
    if isa(a,'I3D')
      [m,i]= max( I.data , a.data , b );
    else
      [m,i]= max( I.data , a      , b );
    end
    
  end

end
