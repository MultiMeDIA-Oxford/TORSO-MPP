function [ x , o ] = uniquens( x )
%
% unique no sort   , it preserve the order of the unique elements
%
%

  [u,o] = unique( x , 'first' );
  
  o = sort(o);
  x = x( o );

%   x = x(:)';
%   
%   i = 1;
%   if iscell(x)
%     while i < numel(x)
%       x( i + find( cellfun( @(y) isequal( y , x{i} ) , x(i+1:end) ) ) ) = [];
%       i = i+1;
%     end
%   else
%     while i < numel(x)
%       x( i + find( x(i+1:end)==x(i) ) ) = [];
%       i = i+1;
%     end
%   end  


end
