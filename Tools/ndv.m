classdef ndv
% NotDefinedValue class
  properties ( Access = private , Hidden = true )
  end

  methods ( Hidden = true )
    function NDV = ndv(  ) %ndv class constructor
    end

    function display( NDV )
      NDVn = inputname(1);
      if isempty( NDVn ), NDVn = 'ans'; end
      fprintf('%s =\n',NDVn);
      disp( NDV );
    end
    function disp( NDV )
      sz = sprintf( ' %d x', size(NDV) ); sz(end) = [];
      fprintf('(%s) NOT DEFINED VALUE\n', sz );
    end
    
    function C = char( NDV )
      C = 'NotVal';
    end
    function D = double( NDV )
      D = repmat( typecast( uint8( [ 78 , 111 , 116 , 86 , 97 , 108 , 248 , 255 ] ) , 'double' ) , size( NDV ) );
    end
    function S = single( NDV )
      S = repmat( typecast( uint8( [ 78 , 86 , 192 , 255 ] ) , 'single' ) , size( NDV ) );
    end
    function x = cat(dim,varargin)
      w = cellfun( @(v)isa(v,'ndv') , varargin );
      if ~all( w )
        for i = find(w)
          varargin{i} = double( varargin{i} );
        end
      end
      x = cat(dim,varargin{:});
    end
    function x = horzcat( varargin ), x = cat(2,varargin{:}); end
    function x = vertcat( varargin ), x = cat(1,varargin{:}); end
    
  end
end
