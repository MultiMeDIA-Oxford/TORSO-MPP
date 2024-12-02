function M = remeshHEART( H , EDGE_LENGTH )
% 
% 
% EDGE_LENGTH in mm.
% 

  cm = false;
  if diff( range( H.xyz( H.tri ,3) ) ) < 50
    cm = true;
    H.xyz = H.xyz * 10;
  end

  celltype = meshCelltype( H );
  if celltype == 5
    S = H;
  elseif celltype == 10
    S = MeshTidy( MeshBoundary( H ) , -1 );
  else
    error('incorrect HEART mesh');
  end
  
  
  if EDGE_LENGTH > 0
    [EPI,LV,RV,LID,Z] = HEARTparts( S );
    M = HEARTremesh( S , Z , MakeMesh(EPI) , MakeMesh(LV) , MakeMesh(RV) , EDGE_LENGTH , 'SMOOTH' , 0 , 'PLANARIZE' , 'COLLAPSE' , 'fixANGLES' );
  end

  if celltype == 10
    
    Oopt = [ 4 7 ];
    
    HH = tetgen( M , 'q' , 1 , 'a', 0 , 'O' , Oopt );
    HH = rmfield( HH , 'tricell_scalars' );
    
    HH = ReorderNodes( HH , M );
    
    eval( M.TITLE );
    HH.face = M.tri;
    HH.epi  = ( 1:EPInodes );
    HH.lv   = ( 1:LVnodes ) + EPInodes;
    HH.rv   = ( 1:RVnodes ) + EPInodes + LVnodes;
    M = HH;
    
    
    M.xyzOLDIDS = vtkClosestPoint( struct('xyz',double(H.xyz)) , double(M.xyz) );
    M.triOLDIDS = vtkClosestPoint( struct('xyz',double(meshFacesCenter(H))) , double(meshFacesCenter(M)) );

    
    for f = fieldnames(H).', f = f{1};
      if    0
      elseif strcmp(  f , 'xyz' )
      elseif strcmp(  f , 'tri' )
      elseif strncmp( f , 'tri' , 3 )
        M.(f) = H.(f)( M.triOLDIDS ,:,:,:);
      elseif strncmp( f , 'xyz' , 3 )
        M.(f) = H.(f)( M.xyzOLDIDS ,:,:,:);
      end
    end
    
  end
  
  
  if cm
    M.xyz = M.xyz / 10;
  end
  
 
end

function HH = ReorderNodes( HH , M )

  if ~isequal( HH.xyz( 1:size( M.xyz ,1) ,:) , M.xyz )
    nnF = size( M.xyz , 1 );
    HH.xyz = [ M.xyz ; HH.xyz ];
    HH.tri = [ (1:nnF).'*[1 1 1 1] ; nnF + HH.tri ];
    HH = MeshTidy( HH , 0 , [] , [1 1 1 0] );
    HH.tri( 1:nnF , : ) = [];
  end

end
