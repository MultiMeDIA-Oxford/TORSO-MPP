function X = safecat(d,varargin)

  JUST   = 'left';
  NANval = NaN;
  if iscell(d)
    if numel(d) > 2, NANval = d{3}; end
    if numel(d) > 1, JUST = d{2};   end
    d = d{1};
  end

  try
    X = cat(d,varargin{:});
    if iscell(X), error('1'); end
  catch
    
    So = zeros( numel( varargin ) , 20 );
    
    So = cellfun( @(x)siz(x) , varargin , 'UniformOutput',false );
    S = max( cell2mat( So(:) ) , [] , 1 );
    S = num2cell( S ); S{d} = [];
    
    for v = 1:numel(varargin)
      if iscell( varargin{v} ) && numel( varargin{v} ) == 1 && numel( varargin{v}{1} ) == 1
        %consider it as a gap
        varargin{v} = zeros( [ S{1:d-1} , varargin{v}{1} , S{d+1:end} ] , 'like', NANval ) + NANval;
      end
      switch class( NANval )
        case {'double'},  varargin{v} =  double( varargin{v} );
        case {'single'},  varargin{v} =  single( varargin{v} );
        case {'int64'},   varargin{v} =   int64( varargin{v} );
        case {'uint64'},  varargin{v} =  uint64( varargin{v} );
        case {'int32'},   varargin{v} =   int32( varargin{v} );
        case {'uint32'},  varargin{v} =  uint32( varargin{v} );
        case {'int16'},   varargin{v} =   int16( varargin{v} );
        case {'uint16'},  varargin{v} =  uint16( varargin{v} );
        case {'int8'},    varargin{v} =    int8( varargin{v} );
        case {'uint8'},   varargin{v} =   uint8( varargin{v} );
        case {'logical'}, varargin{v} = logical( varargin{v} );
        case {'char'},    varargin{v} =    char( varargin{v} );
      end
      
      varargin{v} = resize( varargin{v} , S{:} , { NANval } );
      
      switch lower(JUST)
        case {'left','l'}
        case {'right','r'}
          C = siz(varargin{v}) - So{v};
          varargin{v} = circshift( varargin{v} , C );
        case {'center','c'}
          C = floor( ( siz(varargin{v}) - So{v} )/2 );
          varargin{v} = circshift( varargin{v} , C );
      end
      
      
    end
    
    X = cat(d,varargin{:});
  end

end
function sz = siz( x )
  sz = size(x); sz(end+1:20) = 1;
end