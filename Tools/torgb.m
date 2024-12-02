function R = torgb( I , cm )

  sz = size( I );
  I  = I(:);
  nC = size( cm , 2 );
  
  R = zeros( numel(I) , nC );

  x = linspace( 0 , 1 , size(cm,1) ).';
  
  for c = 1:nC
    R(:,c) = Interp1D( cm(:,c) , x , I , 'closest' );
  end

  
  R = reshape( R , [ sz , nC ] );
  
end
