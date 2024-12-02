function I = reduceimage( I , d , alias )

  if nargin < 3, alias = 1; end
  if nargin < 2, d=2; end

  if numel(d)==1,  d= [d d d];  end
  if numel(d)==3,  d= [d 1];    end
  
  I = subsref( I , substruct( '()' , {':',':',':','1:d(4):size(I.data,4)'} ) );

  [V,h(1),h(2),h(3)] = voxelvolume( I );
  
  if ischar( alias ) 
    I = spatialScale( I , [ h(1)*d(1)  h(2)*d(2)  h(3)*d(3) ] , alias );
  elseif alias
    I = spatialScale( I , [ h(1)*d(1)  h(2)*d(2)  h(3)*d(3) ] );
  end
  
  I = subsref( I , substruct( '()' , ...
                  { 1:d(1):size(I.data,1) , ...
                    1:d(2):size(I.data,2) , ...
                    1:d(3):size(I.data,3) , ...      
                    ':'} ) );
end
