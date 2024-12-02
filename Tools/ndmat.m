function C = ndmat( varargin )
%
% create a n-dimensional grid
%
% ndmat( x0:x1 , y0:y1 , z0:z1 , w0:w1 , ..., ['Sort'] )
% ndmat( x0:x1 , y0:y1 , z0:z1 , w0:w1 , ..., ['nocat'] )
% ndmat( x0:x1 , y0:y1 , z0:z1 , w0:w1 , ..., ['ascell'] )
%
% ndmat( { dimx dimy ... dimz } )
%   goes from 1:dimx , 1:dimy ....
%
%

  LINES = 0;
  try, [varargin,~,LINES]= parseargs( varargin,'lines' , '$DEFS$', LINES ); end
  
  if LINES ~= 0
    C = [];
    for v = 1:numel( varargin )
      if LINES < 0, L = min( varargin{v} ):-LINES:max( varargin{v} );
      else,         L = linspace( min( varargin{v} ) , max( varargin{v} ) , LINES );
      end
      L = unique( [ L , varargin{v} ] );
      L = [ L , NaN ];
      
      V = ndmat( varargin{ [ 1:v-1 , v+1:end ] } );
      LL = [];
      LL(:,v) = L(:);
      for k = 1:size( V , 1 )
        for c = 1:size( V , 2 )
          if c < v, LL(:, c ) = V(k,c);
          else,     LL(:,c+1) = V(k,c);
          end
        end
        C = [ C ; LL ];
      end
    end
    return;
  end
  


  ORDENAR = false;
  try, [varargin,ORDENAR]= parseargs( varargin,'Sort'            , '$FORCE$',{true,ORDENAR}); end

  NOCAT = false;
  try, [varargin,NOCAT  ]= parseargs( varargin,'nocat'           , '$FORCE$',{true,NOCAT}); end
  
  ASCELLS = false;
  try, [varargin,ASCELLS]= parseargs( varargin,'asCELL','asCELLS', '$FORCE$',{true,ASCELLS}); end
  
  COMP = [];
  try, [varargin,i,COMP ]= parseargs( varargin,'Comp','$DEFS$',COMP); end

  if iscell( varargin{1} )
    varargin = cellfun( @(x) 1:x , varargin{1} , 'UniformOutput',false );
  end
  ndims= numel( varargin );


  if ORDENAR
    varargin = cellfun( @(x) sort( x(:) ) , varargin , 'UniformOutput',false );
  else
    varargin = cellfun( @(x)       x(:)   , varargin , 'UniformOutput',false );
  end
  
  if ndims == 1
    C = varargin;
  else
    [ C{1:ndims} ]= ndgrid( varargin{:} );
  end


  if ~isempty(COMP)
    C = C{COMP};
    return;
  end


  if NOCAT && ~ASCELLS
    C = cat( ndims+1 , C{:} );
  elseif NOCAT && ASCELLS
    
  elseif ~NOCAT && ~ASCELLS
    C = cellfun( @(x) x(:) , C ,'UniformOutput',false );
    C = cat( 2 , C{:} );
  elseif ~NOCAT && ASCELLS
    C = cellfun( @(x) x(:) , C ,'UniformOutput',false );
    C = cat( 2 , C{:} );
    C = mat2cell( C , ones( size(C,1) , 1) , size(C,2) );
  end

  
  
end
