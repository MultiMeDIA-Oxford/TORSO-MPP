function idx = end( I , k , n )

  if ~isempty( I.data )  &&  ~iscell( I.data )
    idx = builtin( 'end' , I.data , k , n );
  else
    switch k
      case 1, idx = max(numel(I.X),1);
      case 2, idx = max(numel(I.Y),1);
      case 3, idx = max(numel(I.Z),1);
      case 4, idx = max(numel(I.T),1);
      case 5, idx = 1;
    end
  end

end

% function idx = end( I , k , n )
% 
%   idx = size( I.data , k );
% 
% end
