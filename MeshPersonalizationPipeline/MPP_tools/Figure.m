function hFig = Figure( hFig , varargin )

  if nargin < 1
    hFig = [];
  end
  if isempty( hFig ), hFig = figure; end
  
  SUBJECT_DIR = evalin( 'caller' , 'SUBJECT_DIR' );
  
  WHERE_AM_I  = 'noWhere';
  try
    WHERE_AM_I  = evalin( 'caller' , 'WHERE_AM_I'  );
  end
%   if strncmp( WHERE_AM_I , 'MPP_main:' , 9 ) 
%     WHERE_AM_I = 'MPP_main';
%   end

  set( hFig ,'Name',[ '"' , SUBJECT_DIR , '"' , '  in  ' WHERE_AM_I ] ,'NumberTitle','off',varargin{:});
  set( hFig ,'Colormap', repmat( linspace(0,1,128),3,1).' );

end

