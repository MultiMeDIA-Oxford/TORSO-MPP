function M = MeshBoolean( A , op , B , varargin )
% 
% A = struct('xyz',[0,0,1;0.8660254038,0,0.5;0.2676165673,0.8236391035,0.5;-0.7006292692,0.5090369605,0.5;-0.7006292692,-0.5090369605,0.5;0.2676165673,-0.8236391035,0.5;0,0,-1;0.75,0.4330127019,-0.5;-0.180056806,0.8471006709,-0.5;-0.861281226,0.0905243046,-0.5;-0.3522442656,-0.7911535738,-0.5;0.6435822976,-0.5794841036,-0.5],'tri',[1:3;1,3,4;1,4,5;1,5,6;1,6,2;8,7,9;9,7,10;10,7,11;11,7,12;12,7,8;2,8,3;3,8,9;9,4,3;4,9,10;5,10,11;5,11,6;6,11,12;6,12,2;2,12,8;5,4,10]);
% B = struct('xyz',[0.37,0,0.85;1.1061215932300001,0,0.425;0.597474082205,0.700093237975,0.425;-0.22553487882,0.432681416425,0.425;-0.22553487882,-0.432681416425,0.425;0.597474082205,-0.700093237975,0.425;1.0075,0.368060796615,-0.425;0.37,0,-0.85;0.2169517149,0.720035570265,-0.425;-0.3620890421,0.07694565890999999,-0.425;0.07059237424000003,-0.6724805377299999,-0.425;0.91704495296,-0.49256148806,-0.425],'tri',[1:3;1,3,4;1,4,5;1,5,6;1,6,2;7:9;9,8,10;10,8,11;11,8,12;12,8,7;2,7,3;3,7,9;9,4,3;4,9,10;5,10,11;5,11,6;6,11,12;6,12,2;2,12,7;5,4,10]);
% plotMESH( BooleanMeshes( A , '*' , B ),'EdgeColor','none' );hplotMESH(A,'FaceColor','none');hplotMESH(B,'FaceColor','none','EdgeColor','r')
% 
% A = normalize( randn(10000,3) , 2 ); A = struct('xyz',A,'tri',convhulln(A)); plotMESH(A)
% B = normalize( randn(10000,3) , 2 ); B = TransformMesh( struct('xyz',B,'tri',convhulln(B)),'s',.84,'tx',.4); hplotMESH(B,'facecolor','r')
% plotMESH( BooleanMeshes( A , '*' , B ) )
%

  if nargin == 1
    M = [];
    conn = ConnectivityMesh( A );
    for c = unique( conn ).'
      MM = A;
      MM.tri( conn ~= c , : ) = [];
      
      if isempty( M )
        M = Mesh( M ,0);
        M = MeshTidy( M ,0,true);
        M = checkFaces( M );
        
        bounds = vtkFeatureEdges( M , 'BoundaryEdgesOn',[],'FeatureEdgesOff',[],'NonManifoldEdgesOff',[],'ManifoldEdgesOff',[]);

        if isfield( bounds , 'xyz' )
          M = fillHoles( M );
        end
        
      else
        M = BooleanMeshes( M , 'union' , MM , 'clean','fill' );
      end
    end
    
    
    return;
  end



  [varargin,FAST] = parseargs(varargin,'fast','$FORCE$',{true,false});

  switch lower(  op )
    case {'u','union','+'}
      op = 'UNION';
    case {'i','int','intersect','intersection','*'}
      op = 'INTERSECTION';
    case {'sd','symdiff','symmetricdifference'}
      op = 'SYMMETRIC_DIFFERENCE';
    case {'minus','-','a_minus_b'}
      op = 'A_MINUS_B';
    case {'b_minus_a'}
      op = 'B_MINUS_A';
    otherwise
      error('incorrect operation');
  end

  if ~FAST
    A = MeshFixCellOrientation( MeshTidy( Mesh( A ,0) ,0,true) );
    bounds = MeshBoundary( A );
    if isfield( bounds , 'tri' ) && size( bounds.tri ,1) > 0, warning('MESH A look open. try with MeshFillHoles'); end


    B = MeshFixCellOrientation( MeshTidy( Mesh( B ,0) ,0,true) );
    bounds = MeshBoundary( B );
    if isfield( bounds , 'tri' ) && size( bounds.tri ,1) > 0, warning('MESH B look open. try with MeshFillHoles'); end
  end


  

  [dirname,CLEANUP] = tmpname('carve_***\','mkdir');

  A_fname = fullfile( dirname , 'A.vtk' );
  B_fname = fullfile( dirname , 'B.vtk' );
  M_fname = fullfile( dirname , 'M.ply' );
  
  write_VTP( A , A_fname ,'ascii');
  write_VTP( B , B_fname ,'ascii');
  
  
  [p,f,e] = fileparts( mfilename('fullpath') );
  command = fullfile( p , 'intersect' );
  command = [ '"' , command , '"' , ' --triangulate --edge --rescale ' , '"' , strrep( A_fname , '\','\\') , '"' , '  ' , op , ' ' , '"' , strrep( B_fname , '\','\\') , '"' , ' > ' , '"' , M_fname , '"' ];
  
%   command = [ command , ' --triangulate --edge ' , '"' , strrep( A_fname , '\','\\') , '"' , '  ' , op , ' ' , '"' , strrep( B_fname , '\','\\') , '"' , ' > ' , '"' , M_fname , '"' ];
  
  [status,result] = system( command );
  if status
    error('no pudo!!!');
  else
%     M = read_VTK( M_fname );
    M = read_PLY( M_fname ); M = struct( 'xyz', [ M.vertex.x(:) , M.vertex.y(:) , M.vertex.z(:) ] , 'tri' , cell2mat( M.face.vertex_indices )+1 );
  end

end
