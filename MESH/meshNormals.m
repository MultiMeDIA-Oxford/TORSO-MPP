function N = meshNormals( M , mode )

  if nargin < 2 || isempty( mode )
    mode = false;
  end
  if ~ischar(mode) && isscalar( mode ), mode = ~~mode; end
  if islogical( mode ) && mode
    mode = 'uniform';
  end

  if ischar( mode )
    if isfield( M , 'triNORMALS' )
      N = M.triNORMALS;
    else
      N = meshNormals( M ,false);
    end
    
    switch lower(mode)
      case {'u','uniform'},   N = meshF2V( M , N ,'sum'    );
      case {'g','angle'  },   N = meshF2V( M , N ,'angles' );
      case {'a','area'   },   N = meshF2V( M , N ,'area'   );
      case {'best'}
        X = meshF2V( M , N , 'angles' );
%         X = normalizeRows( X );
        
        L = meshEsuP( M , 0 );
        for x = 1:size(X,1)
          if any( ( N( L(:,x) ,:) * X(x,:).' ) < 0 )
            NS = N( L(:,x) ,:);
            MM = NS * NS.';
            
            ww = ones(1,size(MM,1));
            for it = 1:5
              ww = Optimize( @(w)-min( w/sum(w) * MM ) , ww,'methods',{'conjugate','coordinate',1},'ls',{'quadratic','golden','quadratic'},'noplot',...
                'verbose',0,struct('MIN_ENERGY',-1e-1,'MAX_ITERATIONS',50));
              X(x,:) = ww * NS;
              if all( ( N( L(:,x) ,:) * X(x,:).' ) > 0 )
                break;
              end
            end
          end
        end
        N = X;
        
      otherwise,              error('Invalid weighting');
    end
    
    N = normalizeRows( N );
    return;
  end


  M.celltype = meshCelltype( M );

  switch M.celltype
    case 3
    
      M.xyz(:,end+1:3) = 0;
      
      XYZ = M.xyz( unique( M.tri ) ,:);
      [P,iP] = getPlane( XYZ ,'+z');
      if all( distance2Plane( XYZ , P ) < 1e-6 )
        
        N = transform( M.xyz , iP );
        N = N( M.tri(:,2) ,:) - N( M.tri(:,1) ,:);
        N = N * [0 -1 0;1 0 0;0 0 0];
        N = N * P(1:3,1:3).';
        
      else
        
        S = meshEsuE( M , true );
        N = zeros( size( M.tri ,1) , 3 );
        for c = 1:size( N ,1)
          XYZ = M.xyz( unique( M.tri( [ S{c} ; c ] ,:) ) ,:);
          [P,iP] = getPlane( XYZ ,'z');
          
          XY = transform( M.xyz( M.tri(c,:) ,:) ,iP );
          XY = diff( XY , 1 , 1 ) * [0 -1 0;1 0 0;0 0 0];
          N(c,:) = XY * P(1:3,1:3).';
        end
        
      end

    case 5
      M.xyz(:,end+1:3) = 0;
      N = cross( M.xyz( M.tri(:,2) ,:) - M.xyz( M.tri(:,1) ,:) , M.xyz( M.tri(:,3) ,:) - M.xyz( M.tri(:,1) ,:) , 2 );
      
    otherwise
      error('not implemented yet');
  end

  N = normalizeRows( N );
  
end
function N = normalizeRows( N )
  for it = 1:5
    nn = sqrt( sum( N.^2 ,2) );
    if all( nn == 1 ), break; end
    N = bsxfun( @rdivide , N , nn );
  end
end
