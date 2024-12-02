function FCN = CleanFH( FCN )

  FCN_str_____ = func2str(FCN);
  FCN_tokens__ = regexp( FCN_str_____ , '(\<[A-Za-z][A-Za-z0-9_]*\>)','tokens' );
  FCN_tokens__ = unique( cellfun(@(t)t{1},FCN_tokens__,'UniformOutput',false) );
  
  FCN_fcns____ = functions(FCN);

  FCN_W1______ = FCN_fcns____.workspace{1};
  for FCN_var______ = fieldnames(FCN_W1______).'
    if ~ismember( FCN_var______{1} , FCN_tokens__ )
      continue;
    end
    eval( sprintf('%s = FCN_W1______.%s;', FCN_var______{1} , FCN_var______{1} ) );
  end

%   clearvars('-except','FCN_str_____');
  FCN = eval(FCN_str_____);
  clearvars('-except','FCN');
end
