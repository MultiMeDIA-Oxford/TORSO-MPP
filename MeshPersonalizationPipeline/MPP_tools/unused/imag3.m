function varargout = imag3( D , varargin )

  name = get( gcf , 'Name' );


  MAT = eye(4);
  [varargin,~,MAT] = parseargs(varargin,'R','$DEFS$',MAT);
  
  CONTOURS = cell(1,3);
  if numel( varargin ) && iscell( varargin{1} )
    CONTOURS = varargin{1};
    varargin(1) = [];
  end
  
  I = D{1,1}(:,:,:,1);
  I = double( I );
  I = I - min(I(:));
  I = I/max(I(:));
  I = imadjust( I );
  
  D{1,2} = mergestruct( D{1,2} , struct( 'Format','DICOM' ) );
  [ varargout{1:nargout} ] = image3( { I , transform( D{1,2} , MAT ) } , 'NOBoundaries' , 'nolines' , varargin{:} );
  
  for c = 1:numel( CONTOURS )
    if isempty( CONTOURS{c} ), continue; end
    C = CONTOURS{c};
    C = transform( C , MAT );
    switch c
      case 1,     color = [0 , 0 , 1];
      case 2,     color = [1 , 0 , 0];
      case 3,     color = [0 , 1 , 0];
      otherwise,  color = rand(1,3);
    end
    line( C(:,1) , C(:,2) , C(:,3) , 'Color',color,'LineWidth',2 );
  end
  
  set( gcf , 'Name' , name );

end
