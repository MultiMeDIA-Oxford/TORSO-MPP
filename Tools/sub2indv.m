function ind = sub2indv( sz , sub )
%SUBV2IND   Linear ind from subscript vector.
% SUBV2IND(SIZ,SUB) returns an equivalent single ind corresponding to a
% subscript vector for an array of size SIZ.
% If SUB is a matrix, with subscript vectors as rows, then the result is a 
% column vector.
%
% This is the opposite of IND2SUBV, so that
%   SUBV2IND(SIZ,IND2SUBV(SIZ,IND)) == IND.
%

  sz       = sz(:);
  sub(:,end+1:numel(sz)) = 1;
  
  cum_size = [ 1 ; cumprod( sz(1:end-1) ) ];
  
  sub      = sub - 1;
  ind      = sub * cum_size ;
  
  ind      = ind + 1;

end
