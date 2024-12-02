function checkBEAT( fn )

  persistent BEAT

  try
    useTIMER = true;

    if nargin < 1 || isempty( fn ), return; end

    if isempty( BEAT ), BEAT = getoption( 'BEAThost' , 'CardiacPersonalizationStudy_dir' ); end
    if isempty( BEAT ), return; end
    if ~isequal( strfind( fn , BEAT ) ,1), return; end



    T = timerfindall('Tag','BEATtimer');
    if numel( dir(BEAT) ) == 0
      if ~isempty( T )
        stop( T ); delete( T ); T = [];
      end

      SSHexe = getoption('SSHFS','executable');

      MAXtries = 3; it = 0;
      while 1, it = it + 1;
        if it > MAXtries
          error('after several attempts, the system cannot connect the BEAT server.');
        end
        fprintf('trying mounting BEAT at "%s" ...', BEAT );
        [a,b] = system( [ 'taskkill /im ', filename( SSHexe ) , ' /f'] );  pause(1);
        [a,b] = system( [ '"' , SSHexe , '" &' ]);                         pause(5);
                       %"C:\Program Files (x86)\WinSshFS\WinSshFS.exe"
        if numel( dir(BEAT) ) == 0, fprintf(' failed.\n'); continue; end
        fprintf(' BEAT mounted at "%s"\n', BEAT ); break;
      end
    end

    if useTIMER && isempty( T )
      fn = fullfile( BEAT , 'timer.timer' );
      start( ...
        timer('BusyMode','drop' ,...
              'ExecutionMode','fixedSpacing',...
              'Period',300,...
              'TimerFcn',@(h,e)printf(+fn,'%s@%s at %s\n',getUSER,getHOSTNAME,datestr(now,'dd/mm HH:MM')),...
              'Tag','BEATtimer',...
              'ObjectVisibility','off'));
      executeInBEAT( [ 'chmod ug+rw /data/CardiacPersonalizationStudy/' , fn ] );
    end
  end  

end


