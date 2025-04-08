function [M,w] = MeshFixCellOrientation( M , f )

%   USE_VTK = false;
  USE_VTK = true;

  if nargin < 2, f = []; end

  switch meshCelltype( M )
    case 3
      error('not implemented yet.');
      
    case 5
      
      M0 = M;
      M = MeshGenerateIDs( Mesh(M,0) , 'tri' );
      w = NaN( size( M.tri ,1) ,1);
      M = meshSeparate( M );
      
      for m = 1:numel(M)
        w( M{m}.triID ) = fixTri( M{m} , find( ismember( M{m}.triID , f ) ) , USE_VTK );
      end
      
      if any( isnan(w) ), error('there are triangles that were not fixed!'); end
      
      w = ~~w;
      
      M = M0;
      M.tri( w ,[2,3]) = M.tri( w ,[3,2]);
      
    case 10
      if nargin > 1, error('not implemented for fixed faces for this celltype'); end
      
      P1 = M.xyz( M.tri(:,1) ,:);
      P2 = M.xyz( M.tri(:,2) ,:);
      P3 = M.xyz( M.tri(:,3) ,:);
      P4 = M.xyz( M.tri(:,4) ,:);
      
      L1 = P2 - P1;
      L3 = P1 - P3;
      L4 = P4 - P1;      

      A1 = cross( L3 , L1 );
      vs = dot( A1 , L4 ,2);      
      
      w = vs < 0;
      
      if any(w)
        M.tri(w,[3,4]) = M.tri(w,[4,3]);
      end
      
  end
    
  %if nargout > 1, w = find(w); end

end


function W = fixTri( M , f , USE_VTK )
  
  if isempty( f ) && USE_VTK
    M = struct('xyz',double(M.xyz),'tri',double(M.tri));
    
    try,   N = cross2( M.xyz( M.tri(:,2) ,:) - M.xyz( M.tri(:,1) ,:) , M.xyz( M.tri(:,3) ,:) - M.xyz( M.tri(:,1) ,:)   );
    catch, N = cross(  M.xyz( M.tri(:,2) ,:) - M.xyz( M.tri(:,1) ,:) , M.xyz( M.tri(:,3) ,:) - M.xyz( M.tri(:,1) ,:) ,2);
    end

    Nvtk = vtkPolyDataNormals( M , 'SetFeatureAngle'          , 180     ,...
                                   'SetSplitting'             , false   ,...
                                   'SetConsistency'           , true    ,...
                                   'SetAutoOrientNormals'     , true    ,...
                                   'SetComputePointNormals'   , false   ,...
                                   'SetComputeCellNormals'    , true    ,...
                                   'SetFlipNormals'           , false   ,...
                                   'SetNonManifoldTraversal'  , false   );
    Nvtk = Nvtk.triNormals;
    W = dot( N , Nvtk , 2 ) < 0;
    
    
    M.tri( W ,[2,3]) = M.tri( W ,[3,2]);
    bb = meshBB( M ); d = bb(2,:)-bb(1,:);
    x = [ bb(1,:) - d ; bb(1,:) + d ; bb ; bb(2,:) - d ; bb(2,:) + d ];
    x = ndmat( x(:,1) , x(:,2) , x(:,3) );
    x = unique( x , 'rows','stable' );
    x( x(:,1) >= bb(1,1) & x(:,1) <= bb(2,1) & ...
       x(:,2) >= bb(1,2) & x(:,2) <= bb(2,2) & ...
       x(:,3) >= bb(1,3) & x(:,3) <= bb(2,3) ,:) = [];

    
    M.triNORMALS = meshNormals( M );
    M.xyzNORMALS = meshNormals( M , 'angle' );
    if sum( meshIsInterior_helper( M , x ) ) > size(x,1)/2
      W = ~W;
    end

    return;
  end
  if USE_VTK
    W = fixTri( M , [] , USE_VTK );
    if all( W(f) )
      W = ~W;
      return;
    elseif ~any( W(f) )
      return;
    end
  end

  if isempty( f )
    CH = convhulln( M.xyz );
    CH = CH(:,[1,3,2]);
    
    [~,a,b] = intersect( sort(CH,2) , sort(M.tri,2) ,'rows' );
    [~,pa] = sort( CH(a,:) , 2);
    [~,pb] = sort( M.tri(b,:) , 2);

    f = [ -b( parity(pb) ~= parity(pa) ) ;...
           b( parity(pb) == parity(pa) ) ];

  end
  if isempty( f )
    error('not implemented yet.');
  end

  nF  = size( M.tri ,1);
  W = NaN( nF ,1);
  

  fp =  f( f > 0 );
  W( fp ) = 0;

  
  fn = -f( f < 0 );
  W( fn ) = 1;
  M.tri( fn ,[2,3]) = M.tri( fn ,[3,2]);

  E = [ M.tri(:,[1 2]) ; M.tri(:,[2 3]) ; M.tri(:,[3 1]) ];
  E = E(:,1) + 1i * E(:,2);
  
  IDS = repmat( (1:nF).' ,3,1);

  f = ismember( IDS , [ fp ; fn ] );
  EF = E(f); E(f) = []; IDS(f) = [];
  while ~isempty( E ) && ~isempty( EF )
    EF0 = EF; EF = [];
    
    f = IDS( ismember( E , imag(EF0) + 1i*real(EF0) ) );
    if any(f)
      f = ismember( IDS , f ) & isnan( W( IDS ) );
      W( IDS(f) ) = 0;
      EF = [ EF ; E(f) ]; E(f) = []; IDS(f) = [];
    end
    
    f = IDS( ismember( E , EF0 ) );
    if any(f)
      f = ismember( IDS , f ) & isnan( W( IDS ) );
      W( IDS(f) ) = 1;
      EF = [ EF ; imag( E(f)) + 1i*real( E(f)) ]; E(f) = []; IDS(f) = [];
    end
  end
  
end
