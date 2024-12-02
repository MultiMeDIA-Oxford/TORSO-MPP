function x = setv( x , ind , val , varargin )
% 
% x = setv( x , ind , val ) ->  x( ind{:} ) = val;  -> x
% 

  if nargin < 2, return; end
  if nargin < 3, error('too few args.'); end

  if isstruct( x )

    varargin{end+1} = ind;
    varargin{end+1} = val;
    varargin = varargin( [ end-1 , end , 1:end-2 ] );
    
    while ~isempty( varargin )
      ind = varargin{1};
      val = varargin{2};
      varargin(1:2) = [];
      
      if ~ischar( ind ), error('para modifica una struct, especificar field , value.'); end
      
      if ind(1) == '.', ind(1) = []; end
      
      eval( [ 'x.' ind ' = val;' ] );
    end
    
    
    
    while ~isempty( varargin )
      field = varargin{1}; varargin(1) = [];

      switch class(field)
        case 'char'
          value = varargin{1};  varargin(1) = [];
          x.(field) = value;

        case 'struct'
          for f = fieldnames( field )'
            x.(f{1}) = field.(f{1});
          end

      end
    end
    
  else
    try
      if iscell( ind )
        x( ind{:} ) = val;
      else
        x( ind    ) = val;
      end
    catch
      eval( [ 'x' ind ' = val; ' ] );
    end
    
  end

end
