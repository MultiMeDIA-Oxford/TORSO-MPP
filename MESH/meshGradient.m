function G = meshGradient( M , V )
% 
% H.xyzV = randn( size(H.xyz,1) ,1); maxnorm( reshape( meshGradient( H ) * H.xyzV ,[],3) , meshGradient( H , H.xyzV ) )
% 

  if nargin > 1

    if ischar( V ) && strncmp( V , 'xyz' , 3 )
      V = M.(V);
    elseif ischar( V )
      V = M.([ 'xyz' , V ]);
    end

    if size( V , 1 ) ~= size( M.xyz , 1 )
      error('Number of nodes and number of scalar values must coincide.');
    end
    if size( V , 2 ) ~= 1
      error('Only scalar values are allowed.');
    end
    
  end

  M.celltype = meshCelltype( M );
  M.tri = double( M.tri );
  
  
  switch M.celltype
    case 3
      error('not implemented yet');
    
    case 5
      
      nV = size( M.xyz ,1);
      nT = size( M.tri ,1);
      
      N = meshNormals( M );
      A2 = meshQuality( M , 'area' ) * 2;

      G = sparse(0);
      
      G = G + sparse( 1:(3*nT) , M.tri(:,1)*[1 1 1] , bsxfun( @rdivide , cross( M.xyz( M.tri(:,3) ,:) - M.xyz( M.tri(:,2) ,:) , N ) , A2 ) , 3*nT , nV );
      G = G + sparse( 1:(3*nT) , M.tri(:,2)*[1 1 1] , bsxfun( @rdivide , cross( M.xyz( M.tri(:,1) ,:) - M.xyz( M.tri(:,3) ,:) , N ) , A2 ) , 3*nT , nV );
      G = G + sparse( 1:(3*nT) , M.tri(:,3)*[1 1 1] , bsxfun( @rdivide , cross( M.xyz( M.tri(:,2) ,:) - M.xyz( M.tri(:,1) ,:) , N ) , A2 ) , 3*nT , nV );
      
      if nargin > 1
        G = G * V;
        G = reshape( G , nT , 3 );
      end
      
    case 10

      X1 = M.xyz( M.tri(:,1) ,1); Y1 = M.xyz( M.tri(:,1) ,2); Z1 = M.xyz( M.tri(:,1) ,3);
      X2 = M.xyz( M.tri(:,2) ,1); Y2 = M.xyz( M.tri(:,2) ,2); Z2 = M.xyz( M.tri(:,2) ,3);
      X3 = M.xyz( M.tri(:,3) ,1); Y3 = M.xyz( M.tri(:,3) ,2); Z3 = M.xyz( M.tri(:,3) ,3);
      X4 = M.xyz( M.tri(:,4) ,1); Y4 = M.xyz( M.tri(:,4) ,2); Z4 = M.xyz( M.tri(:,4) ,3);
      
      MAT = permute( reshape( [ X2-X1 , X3-X1 , X4-X1 , Y2-Y1 , Y3-Y1 , Y4-Y1 , Z2-Z1 , Z3-Z1 , Z4-Z1 ] , [ numel(X1) , 3 , 3 ] ) , [ 2 3 1 ] );
      try
        iMAT = funsym3x3( MAT , [] , 'inv' );
      catch
        iMAT = NaN( size( MAT ) );
        %tic
        for k = 1:size( iMAT ,3)
          iMAT(:,:,k) = MAT(:,:,k) \ eye(3);
        end
        %toc
      end
      
      if nargin > 1

        V1 = V( M.tri(:,1) ,1);
        V2 = V( M.tri(:,2) ,1);
        V3 = V( M.tri(:,3) ,1);
        V4 = V( M.tri(:,4) ,1);

        V = permute( [V2-V1,V3-V1,V4-V1] , [2 3 1] );

        G = permute( sum( bsxfun( @times , iMAT , permute( V ,[2 1 3] ) ) , 2 ) , [3 1 2] );
        
      else
        
        nV = size( M.xyz , 1 );
        nT = size( M.tri , 1 );
        
        G1 = sparse( 1:nT , double(M.tri(:,1)) , 1 , nT , nV );
        G2 = sparse( 1:nT ,double( M.tri(:,2)) , 1 , nT , nV );
        G3 = sparse( 1:nT ,double( M.tri(:,3)) , 1 , nT , nV );
        G4 = sparse( 1:nT , double(M.tri(:,4)) , 1 , nT , nV );
        
        G = [ G2-G1 ; G3-G1 ; G4-G1 ];
        
        idx = reshape( 1:(3*nT) , [] ,3 );
        G = sparse( idx , idx.' , 1 , 3*nT , 3*nT ) * G;
        
        S = size(iMAT,3);
        R = 1:S;
        
        G = [ sparse( [1;1;1]*R , 1:3*S , vec(iMAT(1,:,:)) , S , 3*S ) ;...
              sparse( [1;1;1]*R , 1:3*S , vec(iMAT(2,:,:)) , S , 3*S ) ;...
              sparse( [1;1;1]*R , 1:3*S , vec(iMAT(3,:,:)) , S , 3*S ) ] * G;
      end

  end
  
end
