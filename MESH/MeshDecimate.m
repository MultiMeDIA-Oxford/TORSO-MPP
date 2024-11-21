function MD = MeshDecimate( M ,varargin)
  
  if meshCelltype( M ) ~= 5, error('only for triangle meshes (for the moment)'); end

  M = MeshTidy( M ,NaN,true);
  M0 = M;
  
  
  ALGORITHM = 'vtkQuadricDecimation';
  TARGET = 1/10;  %target is in the number of triangles
  EXTRA_SUBS = 0;
  
  while ~isempty( varargin )
    if isnumeric( varargin{1} )
      TARGET = varargin{1}; varargin(1) = [];
    elseif ischar( varargin{1} )
      key = varargin{1}; varargin(1) = [];
      switch lower(key)
        case {'vtkq','vtkquadric','vtkquadricdecimation'}
          ALGORITHM = 'vtkQuadricDecimation';
        case {'extrasubdivisions'}
          EXTRA_SUBS = varargin{1}; varargin(1) = [];
        otherwise
          error('not implemented option');
      end
    else
      error('invalid option');
    end
  end
  
  if     0
  elseif ~mod( TARGET ,1) && TARGET >  1          %TARGETing the number of faces
  elseif ~mod( TARGET ,1) && TARGET < -1          %TARGETing the number of vertices
  elseif TARGET > 0 && TARGET <= 1                %TARGETing the proportion of faces
    TARGET = ceil( TARGET * size( M.tri ,1) );
  elseif TARGET < 0 && TARGET >= -1               %TARGETing the proportion of vertices
    TARGET = -ceil( -TARGET * size( M.xyz ,1) );
  else
    error('invalid TARGET');
  end

  M = struct('xyz',double(M.xyz),'tri',double(M.tri));
%   M = MeshTidy( M ,NaN,true);
  
  if      TARGET > 0
    while size( M.tri ,1) < TARGET
      M  = MeshSubdivide( M ,'butterfly' );
      %M0 = MeshSubdivide( M0 );
    end
  elseif  TARGET < 0
    while size( M.xyz ,1) < -TARGET
      M  = MeshSubdivide( M ,'butterfly' );
      %M0 = MeshSubdivide( M0 );
    end
  end
  
  for s = 1:EXTRA_SUBS
    M  = MeshSubdivide( M ,'butterfly' );
  end
    
  switch ALGORITHM
    case 'vtkQuadricDecimation'
      if     TARGET > 0
        N = @(M)size(M.tri,1) - TARGET;
        P = TARGET / size( M.tri ,1);
      elseif TARGET < 0
        N = @(M)size(M.xyz,1) + TARGET;
        P = TARGET / size( M.xyz ,1);
      end
      P = 1-P;
      
      P = fzero( @(p)N( Mesh( vtkQuadricDecimation( M ,'SetTargetReduction',p) ) ) ,P);
      MD = Mesh( vtkQuadricDecimation( M , 'SetTargetReduction' , P ) );
      
      MD.tri = cast( MD.tri ,'like',M0.tri);
      
      %TODO, sample the XYZ atts on the new vertices
      F = fieldnames( M0 );
      F(   strcmp( F , 'xyz' ) ) = [];
      F( ~strncmp( F , 'xyz' , 3 ) ) = [];
      if numel( F )
        [ e , cp , ~ , bc ] = vtkClosestElement( M , MD.xyz );
        K = sparse( repmat( (1:size(MD.xyz,1)) ,1,3) , M.tri(e,:) , bc , size( MD.xyz ,1) , size( M.xyz ,1) );
        %maxnorm( K * double( M0.xyz ) , cp )
        for f = F(:).', f = f{1};
          if ~isnumeric( M0.(f) ), continue; end
          sz = size( M0.(f) );
          MD.(f) = K * double( M0.(f)(:,:) );
          MD.(f) = reshape( MD.(f) , [ size( MD.xyz ,1) , sz(2:end) ] );
        end
      end
      
    otherwise
      error('unknow ALGORITHM');
  end
  
end
