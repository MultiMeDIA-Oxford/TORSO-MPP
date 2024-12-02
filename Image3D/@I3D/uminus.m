function I = uminus( I )

  I = DATA_action( I , '@(X) uminus(X)' );

%  switch class( I.data )
%    case {'uint8'}
%      if  max( I.data(:) ) > intmax('int8')
%        I = DATA_action( I , @(X) uminus(int16(X)) );
%      else
%        I = DATA_action( I , @(X) uminus(X) );
%      end
%    
%    case {'uint16'}
%      if  max( I.data(:) ) > intmax('int16')
%        I = DATA_action( I , @(X) uminus(int32(X)) );
%      else
%        I = DATA_action( I , @(X) uminus(X) );
%      end
%
%    case {'uint32'}
%      if  max( I.data(:) ) > intmax('int32')
%        I = DATA_action( I , @(X) uminus(tofloat(X)) );
%      else
%        I = DATA_action( I , @(X) uminus(X) );
%      end
%    
%    case {'uint64'}
%      if  max( I.data(:) ) > intmax('int64')
%        I = DATA_action( I , @(X) uminus(tofloat(X)) );
%      else
%        I = DATA_action( I , @(X) uminus(X) );
%      end
%    
%    otherwise
%      I = DATA_action( I , @(X) uminus(X) );
%    
%  end

end
