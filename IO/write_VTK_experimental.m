function write_VTK( M , fname , varargin )

  if size( M.tri ,2) == 3 && ~isfield( M , 'celltype' )
    write_VTK_POLYDATA( M , fname , varargin{:} );
  else
    write_VTK_UNSTRUCTURED_GRID_experimental( M , fname , varargin{:} );
  end

end
