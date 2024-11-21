function [HS,centerH,R] = MaskHeart( HS , R )

  if nargin < 2, R = []; end

  IL = {};
  for r = 1:size(HS,1)
    for s = 1:r-1
      try, IL{end+1} = intersectionLine( HS{r,1} , HS{s,1} ); end
    end
  end
  IL( cellfun('isempty',IL) ) = [];

  centerH = CentralPoint( IL );

  %%

  if isempty( R ), R = -1.05; end
  if R < 0
    X = vertcat( HS{:,2:end} );
    if ~isempty( X )
      R = -R * max( sqrt( sum( bsxfun( @minus , X , centerH ).^2 ,2) ) );
    end
  end
  if R < 0, R = 100; end
  
  
  for h = 1:size(HS,1)
    if isempty( HS{h,1} ), continue; end
    HS{h,1}.FIELDS.Hmask = reshape( ipd( HS{h,1}.XYZ , centerH ) < R , size( HS{h,1} , 1:3) );
  end

end
