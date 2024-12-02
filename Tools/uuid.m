function uid = uuid( sub )

  try
    uid = char(java.util.UUID.randomUUID());
  catch
    if ispc
      uid = [ num2str(feature('timing','cpucount')) , num2str(feature('timing','wintimeofday'))  , num2str(feature('getpid')) ];
    elseif isunix
      uid = [ num2str(feature('timing','cpucount')) , num2str(feature('timing','unixtimeofday')) , num2str(feature('getpid')) ];
    else
      %type feature('timing') to know options
      uid = [ num2str(feature('timing','cpucount')) , num2str(feature('getpid')) ];
    end
    
    try
      uid = [ uid , strrep( strtrim( num2mstr( abs( trandn ) ) ) , '.' ,'') ];
    end
      
    uid = uid( randperm(numel(uid)) );
    
    uid = repmat( uid , 1 , ceil(32/numel(uid)) );
    
    uid = [ shuffle(uid(1:8)) , '-' , shuffle(uid(9:12)) , '-' , shuffle(uid(13:16)) , '-' , shuffle(uid(17:20)) , '-' , shuffle(uid(21:32)) ];
  end
  
  if nargin > 0
    uid = uuid(1:sub);
  end
  
  function x = shuffle(x)
    x = x( randperm(numel(x)) );
    n = round( 1 + rand(1)*(numel(x)-1) * 0.56 );
    x( 1:n ) = ceil( rand(1,n)*6 ) + 96;
    x = x( randperm(numel(x)) );
  end

end
