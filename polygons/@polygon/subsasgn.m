function P = subsasgn(P,s,in)

  S= [];

  s_orig = s;
  optional_args = {};
  for ss = 1:numel(s)
%     if numel( s(ss).subs ) == 0, S= '0'; continue; end
    stype = s(ss).type;
    switch stype
      case '.'
        name = s(ss).subs;
        S = [S '.' name ];
      case {'()','{}'}
        first_opt_arg = find( cellfun( @(x) ischar(x) && ~strcmp(x,':') , s(ss).subs ) , 1 );
        if ~isempty( first_opt_arg )
          optional_args = s(ss).subs(first_opt_arg:end);
          s(ss).subs = s(ss).subs(1:first_opt_arg-1);
        end
        S = [ S stype ];
        switch numel( s(ss).subs )
          case 0,    S= [S(1:end-1) '0' S(end)];
          case 1,    S= [S(1:end-1) '1' S(end)];
          case 2,    S= [S(1:end-1) '2' S(end)];
          case 3,    S= [S(1:end-1) '3' S(end)];
          case 4,    S= [S(1:end-1) '4' S(end)];
          otherwise, S= [S(1:end-1) '_' S(end)];
        end
    end
  end

  
  switch S
    case '(1)'
          idxs = s(1).subs{1};
          o = P;
          P.XY(idxs,:) = in;
    case '(1).XY(2)'
          idxs = s(1).subs{1};
          idxs1 = s(3).subs{1};
          idxs2 = s(3).subs{2};
          P.XY{idxs,1}(idxs1,idxs2) = in;

    case '(1).XY'
          idxs = s(1).subs{1};
          P.XY{idxs,1} = in;
    
    case '(1).type'
          idxs = s(1).subs{1};
          P.XY{idxs,2} = in;
  end

end
