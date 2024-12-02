function M = isoboundary( I , value , varargin )

  if nargin < 2 || isempty( value )
    value = 0.25;
  end

  if  isempty( I.data ), error('the image have to be a non empty image'); end
  if ~islogical( I.data )  &&  ~isequal( unique( I.data(:) ) , [0;1] )
    error('the image have to be a logical image');
  end

  if value < 0 || value > 1
    error('value has to be within (0,1)');
  end
  
  I = cleanout( I , 'labels','info','others','fields','landmarks','pointer','meshes','contours');
  I = crop( I , 1 );

  [varargin,i,offset] = parseargs(varargin,'offset','$DEFS$',[]);

  if isempty( offset )
    offset = min( [ diff( dualVector(I.X) ) , diff( dualVector(I.Y) ) , diff( dualVector(I.Z) ) ] );
    offset = offset/10;
  end
  
  M = boundary( I ,  offset );
  
  M = RemeshOnSurface( M , I , 'isovalue' , value , 'maxIT' , 5 , varargin{:} );
  
end
