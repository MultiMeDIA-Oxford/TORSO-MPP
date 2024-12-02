function SSM = decimateSSM( SSM , decValue )

  fun = functions( SSM );
  m = fun.workspace{1}.m;
  M = fun.workspace{1}.M;
  M = reshape( M , [ ] , 3 * size(M,2) );

  S0 = SSM(0); if ~iscell( S0 ), S0 = { S0 }; end
  for j = 1:numel(S0)
    S0{j}.xyzm = m;
    S0{j}.xyzM = M;
    S0{j} = MeshTidy( S0{j} ,NaN,true);
  end
  
  for j = 1:numel(S0)
    try, S0{j} = MeshDecimate( S0{j} , decValue(min(end,j)) ); end
  end

  S0 = MeshAppend( S0{:} ,'kp'); try, S0 = rmfield( S0 , 'xyzPART' ); end
  S0 = MeshTidy( S0 , 0 ,true );
  m = S0.xyzm;
  M = S0.xyzM; M = reshape( M , [] ,size(M,2)/3 );


  T = S0.tri;
  L = S0.triPART;
  %SSM_explorer( @(c)struct('xyz',reshape( M(:,1:numel(c))*c(:) ,size(m))+m,'tri',T) );

  SSM = @(c)meshSeparate(struct('xyz',reshape(M(:,1:numel(c))*c(:),size(m))+m,'tri',T),L,'KeepNodes');

end
