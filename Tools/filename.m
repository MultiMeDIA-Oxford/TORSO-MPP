function [fname,ffname] = filename( file , ext )

  if nargin < 2, ext = true; end
  if isnumeric(ext) && isscalar(ext), ext = ~~ext; end
  if islogical( ext ) && ~ext, ext = ''; end
  if ischar( ext ) && numel( ext ) && ext(1) ~= '.', ext = [ '.' , ext ]; end
  
  if iscell( file )
    asCELL = true;
  else
    asCELL = false;
    file = { file };
  end

  fname = cell( size(file) );
  if nargout > 1,  ffname = cell( size(file) ); end
  for i = 1:numel(file)
    [ p , f , e ] = fileparts( file{i} );
    if 0
    elseif islogical( ext ),  ee = e;
    elseif ischar( ext ),     ee = ext;
    else,                     error('??');
    end
    fname{i} = [ f , ee ];
    if nargout > 1
      ffname{i} = fullfile( p , fname{i} );
    end
  end
  
  if ~asCELL
    fname = fname{1};
    if nargout > 1
      ffname = ffname{1};
    end
  end
  
end
