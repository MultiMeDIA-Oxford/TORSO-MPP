function [varargout] = executeInBEAT( cmd , varargin )

[ cmdFile , CLEANER ] = tmpname( 'remote_command_????' , 'mkfile' );

fid = fopen( cmdFile , 'w' );
fprintf( fid , '%s\n' , cmd );
fclose(fid);


cmd = '"c:\Program Files\Internet\PUTTY.EXE"';
cmd = sprintf('%s -ssh -2 -l engs1508 -pw %s -m "%s" beat.cs.ox.ac.uk' , cmd , [42,49,51,69,66,1,1,0,2]+'0' , cmdFile );
% eval(['!' cmd])

[varargout{1:nargout}] = system( cmd , varargin{:} );

end
