function A = mergestruct( A , B , mode )

  if ~isstruct(A) || ~isstruct(B)
    error('mergestruct  struct_A  and  struct_B. Both inputs must be struct.');
  end
  if numel(A) ~= 1 || numel(B) ~= 1
    error('both struct must be 1x1.');
  end
  
  if nargin < 3, mode = '<<'; end

  switch mode
    case '<<', OVER = true;
    case '>>', OVER = true;   C = B; B = A; A = C;
    case '<',  OVER = false;
    case '>',  OVER = false;  C = B; B = A; A = C;
    otherwise, error('mode should be ''>'', ''>>'', ''<'', ''<<''.');
  end
  
  fn = fieldnames(B);
  for f = 1:numel(fn)
    if OVER || ~isfield( A , fn{f} )
      A.(fn{f}) = B.(fn{f});
    end
  end

end
