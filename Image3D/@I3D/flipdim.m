function I = flipdim( I , dims )

  if nargin<2, return; end

  CON = subsref( I , substruct('.','CONTOURS') );
  if ~isempty( CON )
      for c = fieldnames(CON).'
          CON.(c{1}) = subsref( I , substruct('.','CONTOUR','.',c{1} ) );
      end
  end
%   if ~isempty( fieldnames( I.CONTOURS ) ), error('I3D with contours, not implemented yet.'); end
  
  if ischar( dims ), dims = double( lower(dims) - 'h' ); end
  if islogical( dims )
    dims = se( 1:3 , dims );
  end

  if any( dims < 1 ), error( 'dims have to be greater than zero.'); end
    

  LS = subsref( I , substruct('.','LANDMARKS') );
  
  for d = dims(:)'
    
    I.(char('W'+d)) = - fliplr( I.(char('W'+d)) );
    switch d
      case 1,
        I.SpatialTransform(1:3,1:3) = I.SpatialTransform(1:3,1:3) * diag( [ -1  1  1 ] );
      case 2,
        I.SpatialTransform(1:3,1:3) = I.SpatialTransform(1:3,1:3) * diag( [  1 -1  1 ] );
      case 3,
        I.SpatialTransform(1:3,1:3) = I.SpatialTransform(1:3,1:3) * diag( [  1  1 -1 ] );
      otherwise
        error('no se puede modificar los datos!!!, hacer I.data = flipdim( I.data , d );' );
        I.data = flipdim( I.data , d );
    end
    
    I = DATA_action( I , [ '@(X) flipdim(X,' , uneval(d) , ')' ] );
    
    
    I.LABELS = flipdim( I.LABELS , d );
    if ~isempty( I.FIELDS ), for fn = fieldnames(I.FIELDS)', if isnumeric( I.FIELDS.(fn{1}) ) || islogical( I.FIELDS.(fn{1}) )
      I.FIELDS.(fn{1}) = flipdim( I.FIELDS.(fn{1}) , d );
    end; end; end
    
  end

  if ~isempty( LS ), I = subsasgn( I , substruct('.','LANDMARKS') , LS ); end
  if ~isempty( CON )
      for c = fieldnames(CON).'
          I = subsasgn( I , substruct('.','CONTOUR','.',c{1}) , CON.(c{1}) );
      end
  end
  
end
