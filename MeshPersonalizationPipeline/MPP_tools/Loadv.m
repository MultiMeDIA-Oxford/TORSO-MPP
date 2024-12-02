function [ varargout ] = Loadv( fn , varargin )


  SUBJECT_DIR = evalin( 'base' , 'SUBJECT_DIR' );
  fn = fullfile( SUBJECT_DIR , 'mpp' , fn );
  
  
  try, checkBEAT( fn ); end;  %to ensure BEAThostname is on
  
  if nargin == 1
    Vn = loadv( fn );
    if numel( Vn ) == 1
      try
        fprintf('Loading  ');
        fprintf(' ''%s''  ', Vn(1).name );
        fprintf('from "%s" ...',fn);
        [ varargout{1:nargout} ] = loadv( fn , Vn(1).name );
        fprintf(' OK.\n');
      catch LE
        fprintf(' error loading file\n');
        rethrow( LE );
      end
    else
      fprintf('error loading a single variable from file\n');
    end
    return;
  end
  
  
  
  
  oldW = warning( 'off' , 'MATLAB:load:variableNotFound' );
  CLEANout = onCleanup( @()warning(oldW) );
  try
    fprintf('Loading  ');
    fprintf(' ''%s''  ', varargin{:} );
    fprintf('from "%s" ...',fn);
    [ varargout{1:nargout} ] = loadv( fn , varargin{:} );
    fprintf(' OK.\n');
  catch LE
    fprintf(' error loading file\n');
    rethrow( LE );
  end
  
end

