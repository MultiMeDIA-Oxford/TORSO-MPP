function S = dispcapture( in )
  fmt = get(0,'FormatSpacing');
  set(0,'FormatSpacing','compact');
  S = evalc('disp(in)');
  set(0,'FormatSpacing',fmt)
  if ~isempty(S)
    S = textscan(S,'%s','delimiter','\n','whitespace','');
    S = S{1}; 
  end
  
  Nspaces = Inf;
  for i=1:numel(S)
    s = find( ~isspace(S{i}) );
    s = s(1);
    if Nspaces > s
      Nspaces = s;
    end
  end

  for i=1:numel(S)
    s = S{i};
    S{i} = s(Nspaces:end);
  end
  
  
end
