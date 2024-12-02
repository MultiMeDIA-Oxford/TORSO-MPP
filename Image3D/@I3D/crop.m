function I = crop( I , b_size , varargin )

  if nargin < 2  ||  isempty( b_size )
    b_size = 1;
  end
  
  [varargin,onLABELS] = parseargs( varargin ,'Labels' ,'$FORCE$',{true,false} );
  [varargin,~,BB    ] = parseargs( varargin ,'BoundingBox' ,'$DEFS$', [] );
  [varargin,i,mask  ] = parseargs( varargin ,'Mask'   ,'$DEFS$' , []          );
  
  
  if onLABELS
    if isempty( I.LABELS ), error('no LABELS in image'); end
    
    mask = ~~I.LABELS;
  end
  
  if ~isempty( BB )
    
    XYZ = transform( ndmat( I.X , I.Y , I.Z ) , I.SpatialTransform );
    
    mask = true;
    mask = mask & all( bsxfun( @ge , XYZ , BB(1,:) ) ,2);
    mask = mask & all( bsxfun( @le , XYZ , BB(2,:) ) ,2);
    
    mask = reshape( mask , size( I ,1:3) );
    
  end
  
  
  if isempty( mask )
    mask = ~~nonans( I.data , 0 );
  end

  if isa( mask , 'I3D' )
    mask = ~~( mask.data );
  end
  
  if ~islogical( mask )
    mask = ~~mask;
  end
  
  if ~any( mask(:) ), return; end
  
  idx = any( any( any( mask(:,:,:,:) , 4 ), 3 ) , 2 ); if ~any( idx ), idx( ceil( size( I , 1 )/2 ) ) = 1; end
  idy = any( any( any( mask(:,:,:,:) , 4 ), 3 ) , 1 ); if ~any( idy ), idy( ceil( size( I , 2 )/2 ) ) = 1; end
  idz = any( any( any( mask(:,:,:,:) , 4 ), 2 ) , 1 ); if ~any( idz ), idz( ceil( size( I , 3 )/2 ) ) = 1; end


  if size(b_size,1) == 1,  b_size = repmat(b_size,[2 1 ]); end
  if size(b_size,2) == 1,  b_size = repmat(b_size,[1 3 ]); end
  if size(b_size,1) ~= 2 || size(b_size,2) < 3
    error('incorrect border specification');
  end
  

  idx = [ max( 1 , find(idx,1,'first') - b_size(1,1) ) ,  min( size(I.data,1) , find(idx,1,'last') + b_size(2,1) ) ];
  idy = [ max( 1 , find(idy,1,'first') - b_size(1,2) ) ,  min( size(I.data,2) , find(idy,1,'last') + b_size(2,2) ) ];
  idz = [ max( 1 , find(idz,1,'first') - b_size(1,3) ) ,  min( size(I.data,3) , find(idz,1,'last') + b_size(2,3) ) ];

  I = I3D_subsref( I , substruct( '()' , { idx(1):idx(2) , idy(1):idy(2) , idz(1):idz(2) } ));

end
