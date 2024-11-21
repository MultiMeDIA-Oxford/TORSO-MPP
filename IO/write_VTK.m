function write_VTK( M , fname , varargin )

%   M = Mesh(M);
  if size( M.tri ,2) == 3 && ~isfield( M , 'celltype' ) 
    write_VTK_POLYDATA( M , fname , varargin{:} );
  else
    write_VTK_UNSTRUCTURED_GRID( M , fname , varargin{:} );
  end

end
