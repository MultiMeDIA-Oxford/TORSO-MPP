function MS = meshSeparate( M , varargin )
% - allow to use a field to separate (on nodes or on faces)

  KeepNodes = false;
  try,[varargin,KeepNodes] = parseargs(varargin,'KeepNodes','$FORCE$',{true,KeepNodes}); end
  


  if numel( varargin ) && ischar( varargin{1} ) && ...
     strncmp( varargin{1} , 'tri' , 3 ) && ...
     isfield( M , varargin{1} )
     
   fc = M.(varargin{1}); varargin(1) = [];
   [~,~,fc] = unique( fc );
    
    MS = cell(0);
    for s = unique( fc(:) ).'
      MS{end+1,1} = MeshRemoveFaces( M , fc ~= s );
      if ~KeepNodes, MS{end} = MeshTidy( MS{end} ,NaN,false); end
    end
    
  elseif numel( varargin ) && isnumeric( varargin{1} ) && ...
         numel( varargin{1} ) == size( M.tri , 1 );
     
   fc = varargin{1}; varargin(1) = [];
   [~,~,fc] = unique( fc );
    
    MS = cell(0);
    for s = unique( fc(:) ).'
      MS{end+1,1} = MeshRemoveFaces( M , fc ~= s );
      if ~KeepNodes, MS{end,1} = MeshTidy( MS{end} ,NaN,false); end
    end
    
  else
    
    BYCELLS = true;
    if BYCELLS
      fc = meshFacesConnectivity( M.tri );

      MS = cell(0);
      for s = unique( fc(:) ).'
        MS{end+1,1} = MeshRemoveFaces( M , fc ~= s );
        if ~KeepNodes, MS{end} = MeshTidy( MS{end} ,NaN,false); end
      end
    else
      nc = meshNodesConnectivity( M );

      MS = cell(0);
      for s = unique( nc ).'
        MS{end+1,1} = MeshTidy( MeshRemoveNodes( M , nc ~= s ) ,NaN,false);
      end
    end
    
  end

  while numel(varargin)
    op = varargin{1}; varargin(1) = [];
    switch lower( op )
      case {'maxx','minx','maxy','miny','maxz','minz'}
        if numel( varargin )
          error('no further options are allowed after minC/maxC.');
        end
        ord = zeros(size(MS));
        for s = 1:numel(MS)
          x = MS{s}.xyz( MS{s}.tri(:) ,:);
          switch lower( op )
            case 'minx', ord(s) =  min(x(:,1));
            case 'maxx', ord(s) = -max(x(:,1));
            case 'miny', ord(s) =  min(x(:,2));
            case 'maxy', ord(s) = -max(x(:,2));
            case 'minz', ord(s) =  min(x(:,3));
            case 'maxz', ord(s) = -max(x(:,3));
          end
        end
        [~,ord] = min( ord );
        MS = MS{ ord };
        return;

      case {'largest'}
        if numel( varargin )
          error('no further options are allowed after LARGEST.');
        end
        ord = zeros(size(MS));
        for s = 1:numel(MS)
          ord(s) = size( MS{s}.tri ,1);
        end
        [~,ord] = max( ord );
        MS = MS{ ord };
        return;
        
      
      case {'remove','delete'}
        w = varargin{1}; varargin(1) = [];
        if ~isa( w , 'function_handle' ), error('a predicate was expected'); end

        for s = 1:numel(MS)
          if feval( w , MS{s} ), MS{s} = []; end    
        end
        MS( cellfun('isempty',MS) ) = [];
      
      case {'sort','order'}
        w = varargin{1}; varargin(1) = [];
        if ~isa( w , 'function_handle' ), error('a scalar function was expected'); end

        ord = zeros(size(MS));
        for s = 1:numel(MS)
          ord(s) = feval( w , MS{s} );
        end
        [~,ord] = sort( ord );
        MS = MS(ord);
        
      case 'select'
        w = varargin{1}; varargin(1) = [];
        if isnumeric( w )
          w( w <= 0 ) = numel( MS ) + w( w <= 0 );
        elseif isa( w , 'function_handle')
          ww = false( numel(MS) ,1);
          for s = 1:numel(MS)
            ww(s) = feval( w , MS{s} );
          end
          if ~islogical( ww )
            error('function for the selection should return logicals');
          end
          w = find(ww);
          
        else
          error('unknown selection type');
        end
        
        MS = MS( w );
        
      case {'combine','append'}
        
        MS = MeshAppend( MS{:} );
        return;

      otherwise
        error('unknown operation');
    end
  end


end