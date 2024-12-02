function [out,M] = CheckSelfIntersections( M , Sname )

  if nargin < 2
    [ DIR , CLEANUP ] = tmpname( 'tetgen_self_intersect_????\' , 'mkdir' );
    Sname = fullfile( DIR , 'M.smesh' );
  end

  tetgen_executable = fileparts( mfilename('fullpath') );
  if ispc, tetgen_executable = fullfile( tetgen_executable , 'tetgen1.5.1.exe' );
  else,    tetgen_executable = fullfile( tetgen_executable , 'tetgen' );
  end
  cmd = sprintf( '"%s"  -dM0/1T1e-16   "%s"' , tetgen_executable , Sname );
  
  write_SMESH( M , Sname );
  [status,result] = system( cmd );
  out = ~isempty( strfind( result , 'Found' ) );
  
  
  if nargout > 1
    if out
      fid = fopen( strrep( Sname , '.smesh' , '.1.face' ) , 'r' );
      M.tri = textscan( fid , '%*d %d %d %d %*d','HeaderLines',1,'CommentStyle','#');
      M.tri = cat(2, M.tri{:} );
      fclose( fid );
    else
      M.tri = zeros( 0,3 );
    end
  end

end
