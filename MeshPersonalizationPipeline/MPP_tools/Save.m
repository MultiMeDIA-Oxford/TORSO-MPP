function Save( fn , varargin )

  VERBOSE = true;
  if islogical( varargin{end} )
    VERBOSE = varargin{end};
    varargin(end) = [];
  end

  SUBJECT_DIR = evalin( 'caller' , 'SUBJECT_DIR' );

  fn = fullfile( SUBJECT_DIR , 'mpp' , fn );
  
  try, checkBEAT( fn ); end; %to ensure BEAThostname is on
  
  if ~isdir( fullfile( SUBJECT_DIR , 'mpp' ) )
    mkdir( fullfile( SUBJECT_DIR , 'mpp' ) );
  end
  
  if isfile( fn )
    fprintf( 'Backuping file "%s" ...' , fn );
    try
      movefile( fn , [ fn , '.bak' ] );
      fprintf(' OK\n');
    catch
      fprintf(' some error backuping!\n');
    end
  end
  
  if VERBOSE
    fprintf( 'saving variables: ' );
    fprintf( ' ''%s''  ' , varargin{:} );
    fprintf(  '  in file "%s" ...' , fn );
  end
  
  
%   START = now;
  evalin( 'caller' , sprintf( 'save( %s , %s )' , uneval( fn ) , uneval( varargin{:} ) ) );

  if VERBOSE
    fprintf( ' OK.\n\n' );
  end
  
%   try
%     d = dir( fn );
%     if etime( START , d.datenum ) > 10
%       error('some problem happened saving.');
%     end
%   catch
%     error('some problem happened saving.');
%   end

end

