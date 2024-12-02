function [V,S] = jigsaw_surface_2_volume( V , varargin )
%   ---> geom_seed - {default=8} number of "seed" vertices used to init-
%       ialise mesh generation.
%
%   ---> geom_feat - {default=false} attempt to auto-detect sharp "feat-
%       ures" in the input geometry. Features can be adjacent to 1-dim.
%       entities, (i.e. geometry "edges") and/or 2-dim. entities, (i.e.
%       geometry "faces") based on both geometrical and/or topological
%       constraints. Geometrically, features are located between any ne-
%       ighbouring entities that subtend angles less than GEOM_ETAX deg-
%       rees, where X is the (topological) dimension of the feature. To-
%       pologically, features are located at the apex of any non-manifo-
%       ld connections.
%
%   ---> geom_eta1 - {default=45deg} 1-dim. feature-angle, features are 
%       located between any neighbouring "edges" that subtend angles le-
%       ss than GEOM_ETA1 degrees.
%
%   ---> geom_eta2 - {default=45deg} 2-dim. feature angle, features are 
%       located between any neighbouring "faces" that subtend angles le-
%       ss than GEOM_ETA2 degrees.
%
%   ---> hfun_kern - {default='constant'} mesh-size kernal, choice betw-
%       een a constant size-function (KERN='constant') and a Delaunay-
%       based medial-axis method (KERN='delaunay') that attempts to aut-
%       omatically generate geometry-adaptive sizing data.
%
%   ---> hfun_scal - {default='relative'} scaling type for mesh-size fu-
%       ction. SCAL='relative' interprets mesh-size values as percentag-
%       es of the (mean) length of the axis-aligned bounding-box (AABB)
%       for the geometry. SCAL='absolute' interprets mesh-size values as
%       absolute measures.
%
%   ---> HFUN_HMAX - {default=0.02} max. mesh-size function value. Inte-
%       rpreted based on HFUN_SCAL setting.
%
%   ---> HFUN_HMIN - {default=0.00} min. mesh-size function value. Inte-
%       rpreted based on HFUN_SCAL setting.
%
%   ---> HFUN_GRAD - {default=0.25} max. allowable gradient in the mesh-
%       size function. 
%
%   ---> MESH_DIMS - {default=3} number of "topological" dimensions to 
%       mesh. DIMS=K meshes K-dimensional features, irrespective of the
%       number of spatial dimensions of the problem (i.e. if the geomet-
%       ry is 3-dimensional and DIMS=2 a surface mesh will be produced).
%
%   ---> MESH_KERN - {default='delfront'} meshing kernal, choice of the
%       standard Delaunay-refinement algorithm (KERN='delaunay') or the 
%       Frontal-Delaunay method (KERN='delfront').
%
%   ---> MESH_ITER - {default=+INF} max. number of mesh refinement iter-
%       ations. Set ITER=N to see progress after N iterations. 
%
%   ---> MESH_TOP1 - {default=false} enforce 1-dim. topological constra-
%       ints. 1-dim. edges are refined until all embedded nodes are "lo-
%       cally 1-manifold", i.e. nodes are either centred at topological
%       "features", or lie on 1-manifold complexes.
%
%   ---> MESH_TOP2 - {default=false} enforce 2-dim. topological constra-
%       ints. 2-dim. trias are refined until all embedded nodes are "lo-
%       cally 2-manifold", i.e. nodes are either centred at topological
%       "features", or lie on 2-manifold complexes.
%
%   ---> MESH_RAD2 - {default=1.05} max. radius-edge ratio for 2-tria 
%       elements. 2-trias are refined until the ratio of the element ci-
%       rcumradius to min. edge length is less-than MESH_RAD2.
%
%   ---> MESH_RAD3 - {default=2.05} max. radius-edge ratio for 3-tria 
%       elements. 3-trias are refined until the ratio of the element ci-
%       rcumradius to min. edge length is less-than MESH_RAD3.
%
%   ---> MESH_EPS1 - {default=0.33} max. surface-discretisation error
%       multiplier for 1-edge elements. 1-edge elements are refined unt-
%       il the surface-disc. error is less-than MESH_EPS1 * HFUN(X).
%
%   ---> MESH_EPS2 - {default=0.33} max. surface-discretisation error 
%       multiplier for 2-tria elements. 2-tria elements are refined unt-
%       il the surface-disc. error is less-than MESH_EPS2 * HFUN(X).
%
%   ---> MESH_VOL3 - {default=0.00} min. volume-length ratio for 3-tria
%       elements. 3-tria elements are refined until the volume-length 
%       ratio exceeds MESH_VOL3. Can be used to supress "sliver" elemen-
%       ts
%

  if isnumeric( varargin{1} ) && isscalar( varargin{1} )
    el = varargin{1}; varargin(1) = [];
    [V,S] = jigsaw_surface_2_volume( V , 'delfront' , 'absolute','geom_feat',true,'hfun_hmax',el,'hfun_hmin',el*0.9,varargin{:});
    return;
  end

  
  [ DIR , CLEANER ] = tmpname( 'jigsaw_****/' , 'mkdir' );
  
  fid = fopen( fullfile( DIR , 'opts.jig' ) , 'w' );
  
  fprintf( fid ,'geom_file = %s\\IN.msh\n'  , DIR );
  fprintf( fid ,'mesh_file = %s\\OUT.msh\n' , DIR );
  fprintf( fid , 'mesh_dims = 3\n' );  

  [varargin,VERBOSE] = parseargs( varargin , 'verbose' , '$FORCE$' , {true,false} );
  
  while ~isempty( varargin )
    key = varargin{1}; varargin(1) = [];
    switch lower( key )
      case 'relative', fprintf( fid , 'hfun_scal = relative\n' );
      case 'absolute', fprintf( fid , 'hfun_scal = absolute\n' );
      case 'delfront', fprintf( fid , 'mesh_kern = delfront\n' );
      case 'delaunay', fprintf( fid , 'mesh_kern = delaunay\n' );
      otherwise
        val = varargin{1}; varargin(1) = [];
        switch class(val)
          case 'logical', if val, val = 'true'; else, val = 'false'; end
          case 'char',
          otherwise, val = number2str( val );
        end
        fprintf( fid , '%s = %s\n' , lower( key ) , val );
    end
  end
  
  fprintf( fid , 'verbosity = %d\n' , double(VERBOSE) );
  fclose( fid );

  
  fid = fopen( fullfile( DIR , 'IN.msh' ) , 'w' );
  fprintf( fid , 'mshid=1\n' );
  fprintf( fid , 'ndims=3\n' );
  fprintf( fid , 'point=%d\n' , size( V.xyz , 1 ) );
  fprintf( fid , '%.16e;%.16e;%.16e;0\n' , V.xyz.' );
  fprintf( fid , 'tria3=%d\n' , size( V.tri , 1 ) );
  fprintf( fid,'%d;%d;%d;0\n', V.tri.' - 1 );
  fclose( fid );

  
  command = sprintf('"%s\\jigsaw64r.exe"  "%s\\opts.jig"' , fileparts( mfilename('fullpath') ) , DIR );
  if VERBOSE
    VERBOSE = {'-echo'};
  else
    VERBOSE = {};
  end
  [ status , cmdout ] = system( command , VERBOSE{:} );
  if status
    disp( cmdout );
    error('an error occurred.');
  end
  
  try
    V = readmsh( fullfile( DIR , 'OUT.msh' ) );
    V = struct( 'xyz' , V.point.coord(:,1:3) , 'tri' , V.tria4.index(:,1:4) );
    V.celltype = 10;

    %%there can be duplicated faces... remove them!!!
    try
      [~,F] = unique( sort( V.tri , 2 ) , 'rows','first' );
      F = sort( F );
      V.tri = V.tri( F , : );
    end
    
    
    try
      P1 = V.xyz( V.tri(:,1) , : );
      P2 = V.xyz( V.tri(:,2) , : );
      P3 = V.xyz( V.tri(:,3) , : );
      P4 = V.xyz( V.tri(:,4) , : );
      v = dot( cross( P2-P1 , P3-P1 , 2 ) , P4-P1 , 2 );
      V.tri( abs(v) < 1e-20 , : ) = [];
    end
    
    
    try
      V = MeshTidy( V );
    end
    
  catch
    disp( 'there was an error... check the tempDir!');
    movefile( fullfile( DIR , 'OUT.msh' ) , tmpname( 'F:\LastCallingToJIGSAW_????.msh' ) );
  end

  if nargout > 1
    clearvars('F','P1','P2','P3','P4','v','cmdout','command','VERBOSE','val','status','key','DIR');
    try,          S = MeshBoundary( V );
    catch
      try
        S = ExtractSurface( V );
      catch
        S = ExtractSurfaceFromTetras( V );
      end
    end
  end
  
end

