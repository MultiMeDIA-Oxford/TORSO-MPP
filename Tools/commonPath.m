function common = commonPath( fns )
% commonPath Find parent path from multiple subpaths
%
%   USAGE:      parpath = commonPath(subpaths)
% __________________________________________________________________________
%   SUBPATHS:   CHAR or CELL array containing strings for multiple paths
%


  if iscell(fns),
    fns = char(fns);
  end

  common = fileparts( fns(1, ~var( fns , [] , 1 ) ) );

end
