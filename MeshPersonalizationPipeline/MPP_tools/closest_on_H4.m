function C = closest_on_H4( A , M , XS , PS )

  lastA = 0;
  for p = 1:numel( XS )
    n = size( XS{p} ,1);
    XS{p} = A( ( lastA + 1 ):( lastA + n ) ,:);
    lastA = lastA + n;

   %PS{p} = MeshRemoveFaces( M , { PS{p}.triID } );
    PS{p} = struct( 'xyz' , M.xyz , 'tri' , M.tri( PS{p}.triID ,:) );
    
    [~,XS{p}] = vtkClosestElement( PS{p} , XS{p} );
  end
  
  C = cell2mat( XS(:) );
  
end