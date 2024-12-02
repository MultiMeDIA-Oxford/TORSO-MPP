function fn = Fullfile( varargin )

  try,   SUBJECT_DIR = evalin( 'base' , 'SUBJECT_DIR' );
  catch, SUBJECT_DIR = '';
  end

  fn = fullfile( SUBJECT_DIR , varargin{:} );
  fn = strrep( fn , '/'  , filesep );
  fn = strrep( fn , '\'  , filesep );
  
end

