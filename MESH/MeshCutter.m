function M = MeshCutter( M , C , insideOut , method )
if 0
  
M = MeshTidy( MeshCrinkle( Mesh(normalize(randn(10000,3),2),'convhull') , eye(4) ,1) );
M = MeshTidy( MeshCrinkle( sphereMesh , eye(4) ,1) );
M = MeshRemoveFaces( sphereMesh(3) , 1 );
paintOnMesh( plotMESH(M) )
C = findall(gcf,'Type','line'); C = [ get(C(1),'XData')' , get(C(1),'YData')' ,  get(C(1),'ZData')' ];

plotMESH( M ,'r','FaceAlpha',0.1)
plotMESH( MeshCutter( M , C ,1) ,'gouraud' ); hplot3d( C , '.-r' )

end

  persistent lastINPUTS

  if nargin < 4, method = 'delaunayTriangulation'; end
  if nargin < 3, insideOut = false; end
  
  if ~isempty( lastINPUTS ) &&...
      isidentical( lastINPUTS.M , M )  &&...
      isidentical( lastINPUTS.C , C )  &&...
      isidentical( lastINPUTS.insideOut , insideOut )
    try
      M = lastINPUTS.result;
      return;
    end
  end
  lastINPUTS = struct( 'M' , M , 'C' , C , 'insideOut' , insideOut );

  BOTH = false;
  if isequal( insideOut , 2), insideOut = 'both'; end
  if ~ischar( insideOut ), insideOut = ~~insideOut; end
  if ischar( insideOut ) && ( strcmp( insideOut , 'both' ) || strcmp( insideOut , 'b' ) )
    BOTH = true;
  end

  C = double( resample( polyline( C ) , '+normalized', linspace(0,1,1e4+1) ) );

  [~,C] = vtkClosestElement( Mesh(M) , C );

  F = MeshFlatten( M );
  D = meshMapPoints( C , M , F );
  D(:,3:end) = [];
  D = double( decimate( polyline(D) ) );
  
  switch lower( method )
    case 'clip'
  
      [ ~ , ~ , d ] = closestElement( polyline(D) , F.xyz );
      s = ~~inpoly( F.xyz.' , D.' );
      d(s) = -d(s);

      
      F = MeshClip( F , d ,'KeepParentEdge');
      F.xyzParentEdge( ~F.xyzParentEdge(:,2) ,2) = 1;

      M.xyz = bsxfun( @times , ( 1 - F.xyzParentEdge(:,3) ) , M.xyz( F.xyzParentEdge(:,1) , : ) )  +...
              bsxfun( @times ,       F.xyzParentEdge(:,3)   , M.xyz( F.xyzParentEdge(:,2) , : ) );
      M.tri = F.tri;

      
    case {'delaunaytriangulation','dt'}
      
      T = MeshTidy( F );
      
      %T.triM = meshV2F( T , d ,@max );
      %T = MeshTidy( MeshRemoveFaces( T , T.triM > 0 ) );

      T = MeshAppend( MeshWireframe(T) , Mesh( D , 'contour' ) );
      
      onCLEAN = {};
      state = warning( 'off' , 'MATLAB:delaunayTriangulation:ConsConsSplitWarnId' );
      onCLEAN{end+1} = onCleanup( @()warning(state) );
      state = warning( 'off' , 'MATLAB:delaunayTriangulation:DupPtsConsUpdatedWarnId' );
      onCLEAN{end+1} = onCleanup( @()warning(state) );
      
      T = Mesh( delaunayTriangulation( T.xyz(:,1) , T.xyz(:,2) , double( T.tri ) ) );
      
      
      
      
      if BOTH && ~isequal( D(end,:) , D(1,:) )
        
        a = atan2( D([1 end],2) , D([1 end],1) );
        if a(2) < a(1)
          D = flip( D , 1 );
          a = flip( a , 1 );
        end

        R = sqrt( max( fro2( F.xyz ,2) ) )*1.1;
        t = linspace( a(2) , a(1) , 100 );
        D = [ D ; cos(t(:))*R  , sin(t(:))*R ];
        
      end

      if BOTH
        
        w = inpoly( meshFacesCenter( T ).' , D.' );
        
        T = MeshAppend( ...
                MeshTidy( Mesh( T , T.tri( w,:) ) ) ,...
                MeshTidy( Mesh( T , T.tri(~w,:) ) ) );
        
      else
        isExterior = ~inpoly( meshFacesCenter( T ).' , D.' );
        
        if ~insideOut, isExterior = ~isExterior; end
        T = MeshRemoveFaces( T , ~isExterior );
      end
      
      M = Mesh( meshMapPoints( T.xyz , F , M ) , T.tri );
      
  end

  lastINPUTS.result = M;
end
