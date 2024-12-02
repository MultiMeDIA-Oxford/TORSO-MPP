function B = mppBranch( b )

  MPP_version = '';
  if isempty( MPP_version ), try, MPP_version = evalin( 'caller' , 'MPP_version' ); end; end
  if isempty( MPP_version ), try, MPP_version = evalin( 'base' , 'MPP_version' ); end; end
  if isempty( MPP_version )
    mppOption   VERSION
    MPP_version = VERSION;
  end
  if isempty( MPP_version )
    B = '';
    return;
  end
  
  MPP_branch = MPP_version( 1:find(MPP_version==':')-1 );
  
  if nargin
    B = strcmpi( MPP_branch , b );
  else
    B = lower( MPP_branch );
  end
  
end