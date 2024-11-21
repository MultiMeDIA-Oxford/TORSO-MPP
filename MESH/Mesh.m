function M = Mesh( varargin )
% - allow to add attributes from varargin
% - allow to remove attributes from varargin


  switch numel(varargin)
    case 0
      M = struct();
      
    case 1
      M = varargin{1}; hM = M;
      if ishandle( M )
        switch lower( get( M , 'type' ) )
          case {'patch'}
            M = struct( 'xyz' , get( hM ,'Vertices' ) ,'tri', get( hM ,'Faces' ) );
            
            fc = get( hM , 'FaceColor' );
            if isnumeric( fc )
            elseif strcmp( fc , 'none' )
            elseif strcmp( fc , 'flat' )
              M.triFaceColor = get( hM , 'CData' );
            elseif strcmp( fc , 'interp' )
              M.xyzFaceColor = get( hM , 'CData' );
              M.xyzFaceColor = get( hM , 'FaceVertexCData' );
              if size( M.xyzFaceColor ,1) ~= size( M.xyz,1)
                M.xyzFaceColor = M.xyzFaceColor.';
              end
            else
              error('unknown FaceColor');
            end
            
          otherwise, error('This handle type case is not implemented yet.');
        end
      elseif isa( M , 'delaunayTriangulation' )
        M = struct( 'xyz' , M.Points , 'tri', M.ConnectivityList );
      elseif isnumeric( M )
        M = struct('xyz',M);
      elseif isstruct( M )
        if isfield( M , 'vertices' )
          M.xyz = M.vertices; M = rmfield( M , 'vertices' );
        end
        if isfield( M , 'faces' )
          M.tri = M.faces; M = rmfield( M , 'faces' );
        end
        
      else
        error('invalid input');
      end
      
    case 2
      
      V = varargin{1};
      if isstruct(V) && isfield( V , 'xyz' )
      elseif isnumeric(V)
        V = struct('xyz',V);
      elseif isstruct(V) && isfield( V , 'vertices' )
        V.xyz = V.vertices; V = rmfield( V , 'vertices' );
      else
        error('invalid input');
      end
      
      F = varargin{2};
      if ( islogical( F ) && numel( F ) == 1 ) || ...
         ( isnumeric( F ) && numel( F ) == 1 && ( F == 0 || F == 1 ) )
        
        M = Mesh( varargin{1} );
        if ~F
          for f = fieldnames( M ).',f=f{1};
            if strcmp( f , 'xyz' ), continue; end
            if strcmp( f , 'tri' ), continue; end
            if strcmp( f , 'celltype' ), continue; end
            M = rmfield( M , f );
          end
        end
        return;
        
      elseif isnumeric(F)
        F = struct('tri',F);
      elseif isstruct(F) && isfield( F , 'faces' )
        F.tri = F.faces; F = rmfield( F , 'faces' );
      elseif isstruct(F) && isfield( F , 'tri' )
      elseif ischar( F )
        switch lower( F )
          case {'delaunayn','delaunay','del','delaunaytriangulation'}
            F = delaunayn( double(V.xyz) );

          case {'convhulln','convhull','conv','convex','convexhull'}
            F = convhulln( double(V.xyz) );
            if size( F , 2 ) == 3
              F = F(:,[1,3,2] );
            end
            
          case {'contour'}
            F = [ 1:size(V.xyz,1)-1 ; 2:size(V.xyz,1) ].';
            nans = find( any( isnan( V.xyz ) ,2) );
            F( any( ismember( F , nans ) ,2) ,:) = [];
            
          case {'closecontour','closedcontour'}
            if ~isequal( V.xyz(1,:) , V.xyz(end,:) )
              warning('The contour is not originally closed.');
            else
              V.xyz(end,:) = [];
            end
            
            F = [ 1:size(V.xyz,1) ; 2:size(V.xyz,1) , 1 ].';
            nans = find( any( isnan( V.xyz ) ,2) );
            F( any( ismember( F , nans ) ,2) ,:) = [];
            
          case {'nodes'}
            F = ( 1:size(V.xyz,1) ).';
            
          otherwise, error('Not implemented yet.');
        end
        F = struct('tri',F);

      else
        error('invalid input');
      end
        
      M = struct();
      for f = Vfields(V),f=f{1}; M.(f) = V.(f); end
      for f = Ffields(F),f=f{1}; M.(f) = F.(f); end
    
    otherwise
      error('not implemented yet for more than 2 inputs.');
      
  end
  
  if ~isfield( M , 'xyz' ), M.xyz = []; end
  if ~isfield( M , 'tri' ), M.tri = []; end
  if isempty( M.xyz ), M.xyz = zeros(0,3); end
  if isempty( M.tri ), M.tri = zeros(0,3); end

  for f = fieldnames(M).',f=f{1};
    if strncmp( f , 'xyz' , 3  ), continue; end
    if strncmp( f , 'tri' , 3  ), continue; end
    if strcmp(  f , 'celltype' ), continue; end
    M = rmfield( M , f );
  end

  for f = fieldnames(M).',f=f{1};
    if isnumeric( M.(f) ) || islogical( M.(f) )
      M.(f) = double( M.(f) );
    end
  end

  nV = size( M.xyz ,1);
  for f = Vfields( M ),f=f{1};
    if      size( M.(f) ,1) == nV
    elseif  size( M.(f) ,1) >  nV
      warning( 'XYZ attribute "%s" too large. Cropping it.' , f );
      M.(f) = M.(f)( 1:nV ,:,:,:,:,:,:,:,:);
    elseif  size( M.(f) ,1) <  nV
      warning( 'XYZ attribute "%s" too short. Completing with NaNs.' , f );
      M.(f)( end+1:nV ,:,:,:,:,:,:,:,:) = NaN;
    end
  end

  nF = size( M.tri ,1);
  for f = Ffields( M ),f=f{1};
    if strcmp( f , 'celltype'), continue; end
    if      size( M.(f) ,1) == nF
    elseif  size( M.(f) ,1) >  nF
      warning( 'TRI attribute "%s" too large. Cropping it.' , f );
      M.(f) = M.(f)( 1:nF ,:,:,:,:,:,:,:,:);
    elseif  size( M.(f) ,1) <  nF
      warning( 'TRI attribute "%s" too short. Completing with NaNs.' , f );
      M.(f)( end+1:nF ,:,:,:,:,:,:,:,:) = NaN;
    end
  end

  if isfield( M , 'celltype' ) && ~isempty( M.celltype )
    if size( M.celltype ,2) ~= 1 || ~ismatrix( M.celltype )
      warning('.celltype doesn''t have the correct size.');
    end
    if numel( M.celltype ) ~= 1 && numel( M.celltype ) ~= nF
      warning('.celltype should have the same number than .tri.');
    end
    if all( M.celltype == M.celltype(1) )
      M.celltype = M.celltype(1);
    end
  else
    M.celltype = meshCelltype( M );
  end
  
  F = fieldnames(M).'; F( strcmp( F , 'celltype' ) ) = []; OF = {}; 
  w =  strcmp( F , 'xyz'   ); OF = [ OF , F(w) ]; F(w) = [];
  w = strncmp( F , 'xyz' ,3); OF = [ OF , F(w) ]; F(w) = [];
  w =  strcmp( F , 'tri'   ); OF = [ OF , F(w) ]; F(w) = [];
  w = strncmp( F , 'xyz' ,3); OF = [ OF , F(w) ]; F(w) = [];
  OF = [ OF , F ];
  OF = [ OF , 'celltype' ];
  M = orderfields( M , OF );
  
  if isequal( M.celltype , meshCelltype( rmfield( M , 'celltype' ) ) )
    M = rmfield( M , 'celltype' );
  end
    
end

function F = Vfields( M )
  F = fieldnames(M).';
  F = F( strncmp( F , 'xyz' , 3 ) );
end
function F = Ffields( M )
  F = fieldnames(M).';
  F = F( strncmp( F , 'tri' , 3 ) | strcmp( F , 'celltype' ) );
end
