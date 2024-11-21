function CP = ArrangeContourPairs( C )

  nC = size( C , 2 );
  nR = size( C , 1 );
  CP = cell( nR , 0 );
  
  for s = 1:nC
    for i = 1:nR
      if isempty( C{i,s} ), continue; end
      XYZ = C{i,s};
%       XYZ( any(isnan(XYZ),2) , : ) = [];
%       m = mean( XYZ , 1 ); [~,~,v] = svd( bsxfun(@minus,XYZ,m) );
%       Z = [ v , m(:) ; 0 , 0 , 0 , 1 ]; iZ = Z \ eye(4);
      [Z,iZ] = getPlane( XYZ );
      for j = i+1:nR
        if isempty( C{j,s} ), continue; end
        xyz = transform( C{j,s} , iZ );
        xyz( any(isnan(xyz),2) , : ) = [];

        XYcuts = sum( ~~diff( sign(xyz(:,3)) ) );
        if     XYcuts == 0
        elseif XYcuts == 1
          c = size( CP , 2 ) + 1;
          CP{i,c} = C{i,s};
          CP{j,c} = C{j,s};

%            plot3d( transform( XYZ    ,iZ,Z) ,'r','eq' );
%           hplot3d( transform( C{j,s} ,iZ,Z) ,'o-m');
%           pause();
        elseif XYcuts >= 2
          if XYcuts > 2
            warning('too much intersections???');
          end
          z = [ xyz(:,3) , ( 1:size(xyz,1) ).' ];
          [~,m] = max( z(:,1) );
          z = circshift( z , [ -m+1 , 0 ] );
          [~,m] = min( z(:,1) );

          c = size( CP , 2 ) + 1;
          CP{i,c} = C{i,s};
          CP{j,c} = C{j,s}( z( 1:m-1 ,2) ,:);

          c = size( CP , 2 ) + 1;
          CP{i,c} = C{i,s};
          CP{j,c} = C{j,s}( z( m:end ,2) ,:);

%            plot3d( transform( XYZ ,iZ,Z) , 'r','eq' );
%           hplot3d( transform( xyz ,Z),'linewidth',2);
%           hplot3d( transform( C{j,s}( z( 1:m-1 ,2) ,:) ,iZ,Z),'o-m');
%           hplot3d( transform( C{j,s}( z( m:end ,2) ,:) ,iZ,Z),'o-g')
%           pause();
        else
          warning('too much intersections???');
        end
      end
    end
  end

end
