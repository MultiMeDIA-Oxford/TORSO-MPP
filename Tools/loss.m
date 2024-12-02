function X = loss( ind , varargin )

  if islogical( ind )
    error('indexes are expected in first argument');
  end


  if numel( varargin ) == 0
    sz = [ max( max( ind(:) ) , 1) , 1 ];
  elseif numel( varargin ) == 1
    sz = varargin{1};
    sz = [ sz(:) ; 1 ].';
  elseif all( cellfun('prodofsize',varargin) == 1 )
    sz = [ varargin{:} ];
  else
    error('incorrect specification of sz.');
  end

  X = false( sz );
  try
    X( ind ) = true;
  catch
    error('incorrect indices.');
  end

end
