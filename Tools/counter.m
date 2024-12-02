function c = counter( x )
  
  if isvector( x )
    [~,~,u] = unique( x );
  else
    [~,~,u] = unique( x ,'rows');
  end
  
  c = accumarray( u ,1);
  c = c(u);

end
