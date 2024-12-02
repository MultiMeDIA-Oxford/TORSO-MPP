function n = string2number( s , i )

  if nargin < 2, i = -1; end

  n = str2double(s);
  if ~isnan(n), return; end
  
  s = regexp(s,'[^0-9]*([+-]?(?:[0-9]+\.?[0-9]*|[0-9]*\.?[0-9]+)(?:[eE][+-]?[0-9]+)?)','tokens');
  if isempty( s ), return; end
  
  if i == -1, s = s{end};
  else,       s = s{i};
  end
  
  n = str2double( s );

%   n= str2double(s);
%   if ~isnumeric(n) || isnan(n)
%     n= sscanf( s, '%*s%f%*s');
%   end
%   if ischar(n)
%     i=1;
%     while i < numel(s)
%       if s(i) == '.' || ~isnan( str2double(s(i) ) )
%         s= s(i:end);
%         i= Inf;
%       end
%       i=i+1;
%     end
%     n= sscanf( s, '%f%*s');
%   end
  
end
