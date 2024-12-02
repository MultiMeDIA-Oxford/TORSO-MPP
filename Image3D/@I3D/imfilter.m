function [I,K] = imfilter( I , K , varargin )
% 
% 
% I = imfilter( I(I3D) , K(float) , varargin )
%   
%

  if ~isfloat(K)
    error('I3D:Filtering','The Kernel have to be float.')
  end
  if ~isfloat( I.data )
    error('I3D:Filtering','The Image.data have to be float.')
  end

  if ndims(K) > 3
    warning('I3D:Filtering','The Kernel have more than 3 dims. Cropping.');
    K = K(:,:,:,1);
  end            
  
  I = remove_dereference( I );


  [varargin,KinFourierDomain ] = parseargs( varargin , 'kfd'                     , '$FORCE$', 1 );
  
  [varargin,UseFourierDomain ] = parseargs( varargin , 'fourier','FourierDomain' , '$FORCE$', 1 );
  [varargin,UseSpatialDomain ] = parseargs( varargin , 'spatial','SpatialDomain' , '$FORCE$', 1 );
  
  if UseFourierDomain == UseSpatialDomain
    if KinFourierDomain
      UseSpatialDomain = 0; UseFourierDomain = 1;
    else
      UseSpatialDomain = 1; UseFourierDomain = 0;
    end
  end

  
  method = [];
  [varargin,method] = parseargs(varargin, 'CIRCular','PERiodic' ,'$FORCE$',{'circular',method});
  [varargin,method] = parseargs(varargin, 'symm','SYMmetric'           ,'$FORCE$',{'symmetric',method});
  [varargin,i,method] = parseargs(varargin,'Value','$DEFS$',method);
  if isempty(method)
    switch I.BoundaryMode
      case 'circular' , method = 'circular';
      case 'symmetric', method = 'symmetric';
      case 'value'    , method = I.OutsideValue;
      case 'closest'  , method = 'replicate';
      case 'decay'    ,
        warning('I3D:Filtering','You are trying to Filter with DECAY conditions. Using VALUE');
        method = I.OutsideValue;
    end
  end


  if UseSpatialDomain

    if KinFourierDomain
      K = FK2Kernel( K );
    end

    I.data = imfilter( I.data , K , method , 'same' , 'conv' );

  elseif UseFourierDomain

    if strcmp( method , 'circular' )

      if KinFourierDomain
        szK = size(K); 
        szK( max( numel(szK) , ndims( I.data ) ) + 1 ) = 1;
        szK( ~szK ) = 1;
        if ~isequal( szK( szK ~= 1 ) , size( I , find( szK ~= 1 )  ) )
          K = Kernel2FK( FK2Kernel( K ) , size(I,1:3) );
        end
      else
        K = Kernel2FK( K , size(I,1:3) );
      end
      I.data = real(ifftn(  bsxfun( @times , fftn(I.data) , K ) ));

    else

      if KinFourierDomain
        K = FK2Kernel( K );
      end
      I.data = fconvn( I.data , K , method );

    end
    
  end

end
