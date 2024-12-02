function SS = touppercasefields( S )

  if isempty( S ), S = struct(); end
  if ~isstruct(S), error('it only work on a struct');        end

  SS = struct;
  
  fns = fieldnames( S );
  for f = 1:numel(fns)
    for i = 1:numel(S)
      SS(i).( upper(fns{f}) ) = S(i).( fns{f} );
    end
  end
      
end
