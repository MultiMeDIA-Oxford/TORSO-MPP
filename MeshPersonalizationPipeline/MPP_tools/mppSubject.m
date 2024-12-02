function success_ = mppSubject( SD , removeRunning )

  if nargin < 2, removeRunning = false; end

  success = false;

  SD = strrep( SD , '\' , filesep );
  SD = strrep( SD , '/' , filesep );
  
  while 1
    n = numel(SD);
    SD = strrep( SD , [filesep,filesep] , filesep );
    if numel(SD) == n, break; end
  end
  while numel( SD ) && SD(end) == filesep
    SD(end) = [];
  end
  
  if ~isdir( SD )
    fprintf( 2 , 'Directory: "%s" doesn''t exist.\n' , SD );
    if ~nargout
      error( 'No directory' );
    else
      success_ = success; return;
    end
  end
  
  
  Rfile = fullfile( SD , 'RUNNING' );
  if removeRunning && isfile( Rfile )
    delete( Rfile );
  end
  if isfile( Rfile )
    fprintf(2,'RUNNING file exists for this SUBJECT ("%s").   <a href="matlab:delete(''%s'')">DELETE RUNNING FILE</a>\n' , SD , Rfile );
    if ~nargout
      error( 'Runing file exists.' );
    else
      success_ = success; return;
    end
  end
  
  assignin( 'base' , 'SUBJECT_DIR' , SD );
  evalin( 'base' , 'fprintf(''MPP  SUBJECT_DIR  set to: "%s"\n'', SUBJECT_DIR );' );
  

  try, evalin( 'base' , 'clearvars( ''MPP_ERROR''  );' ); end
  try, evalin( 'base' , 'clearvars( ''MPP_BROKEN'' );' ); end
  try, evalin( 'base' , 'clearvars( ''MPP_FORCE''  );' ); end
  try, evalin( 'base' , 'clearvars( ''WHERE_AM_I'' );' ); end
  
  
  
  switch mppBranch
    case 'hcm'
      try, evalin( 'base' , 'clearvars( ''HEART_CONTOURS_FILE'' );' ); end
      
      HEART_CONTOURS_FILE = rdir( SD , '.*\.mat$' , 0 );
      if numel( HEART_CONTOURS_FILE ) ~= 1
        warning('HEART_CONTOURS_FILE couldn''t be set');
      else
        HEART_CONTOURS_FILE = HEART_CONTOURS_FILE.name;
        HEART_CONTOURS_FILE = filename( HEART_CONTOURS_FILE );
        assignin( 'base' , 'HEART_CONTOURS_FILE' , HEART_CONTOURS_FILE );
      end
  end

  
  success = true;
  if nargout
    success_ = success;
  end
  
end
