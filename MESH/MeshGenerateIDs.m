function [M,IDSname] = MeshGenerateIDs( M , varargin )

  
%   temp = false;
  if nargin < 2

    onNODES = true;
    onCELLS  = true;
    temp = false;
  
  else
    
    onNODES = false;
    onCELLS  = false;
    for v = varargin(:).'
      if any( strcmpi( v{1} , {'nodes','n','v','xyz'} ) )
        onNODES = true; temp = false;
      elseif any( strcmpi( v{1} , {'faces','cells','f','tri'} ) )
        onCELLS  = true; temp = false;
      elseif any( strcmpi( v{1} , {'nodes_','n_','v_','xyz_'} ) )
        onNODES = true; temp = true;
      elseif any( strcmpi( v{1} , {'faces_','cells_','f_','tri_'} ) )
        onCELLS  = true; temp = true;
      else
        error( 'unknown option ''%s''' , v{1} );
      end
    end
    
  end

  if temp
    if onNODES && onCELLS
      error('only one temporary can be generated at this time');
    end
    if onNODES
      IDSname = 'xyzIDS_';
      while isfield( M , IDSname );
        IDSname = [ IDSname , char( rand(1)*( 'z'-'a') +'a' ) ];
      end
      M.(IDSname) = ( 1:size(M.xyz,1) ).';
    end
    if onCELLS
      IDSname = 'triIDS_';
      while isfield( M , IDSname );
        IDSname = [ IDSname , char( rand(1)*( 'z'-'a') +'a' ) ];
      end
      M.(IDSname) = ( 1:size(M.tri,1) ).';
    end

    return;
  end
  
  
  
  if onNODES
    M.xyzID = ( 1:size( M.xyz ,1) ).';
%   elseif isfield( M , 'xyzID' )
%     M = rmfield( M , 'xyzID' );
  end
  if onCELLS
    M.triID = ( 1:size( M.tri ,1) ).';
%   elseif isfield( M , 'triID' )
%     M = rmfield( M , 'triID' );
  end

end