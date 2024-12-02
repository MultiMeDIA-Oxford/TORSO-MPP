function sub = ind2subv( sz , ind )
% 
% IND2SUBV   Subscript vector from linear ind.
% 
% IND2SUBV(SIZ,IND) returns a vector of the equivalent subscript values 
% corresponding to a single ind into an array of size SIZ.
% If IND is a vector, then the result is a matrix, with subscript vectors
% as rows.
% 

  ind = ind(:);
  ind = ind - 1;

  cum_size = cumprod( sz(:).' );
  sub = bsxfun( @rem , ind , cum_size );
  cum_size = [ 1 cum_size(1:end-1) ];

  sub = bsxfun( @rdivide , sub , cum_size );
  sub = fix( sub ) + 1;

%    ind = ind(:);
%    [sub{1:numel(sz)}] = ind2sub( sz , ind );
%    sub = cell2mat( sub );


end
