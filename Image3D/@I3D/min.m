function [ m , i ] = min( I , a , b )

  if     nargin == 1
    [m,i] = min( I.data(:) );

  elseif nargin==2
    if isa(a,'I3D')
      [m,i]= min( I.data , a.data );
    else
      [m,i]= min( I.data , a      );
    end
    
  elseif nargin==3
    if isa(a,'I3D')
      [m,i]= min( I.data , a.data , b );
    else
      [m,i]= min( I.data , a      , b );
    end
    
  end

end
