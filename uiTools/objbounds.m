function lims = objbounds( HS , T , on_hidden )

  if nargin == 1 && isnumeric( HS ) && isscalar( HS ) && HS < 0
    lims = objbounds( gca , -HS );
    return;
  end


  if nargin < 1, HS = gca; end
  if nargin < 2 || isempty( T ), T = eye(4);  end
  if nargin < 3, on_hidden = false;  end
  SC = 1;
  if isscalar(T), SC = T; T = eye(4); end
  
  lims = nan(2,3);
  for i = 1:numel(HS)
    h = HS(i);
    try, if ~on_hidden && ~onoff( h , 'Visible' ), continue; end; end
    try,   type = get( h , 'type' );
    catch, type = class( h );
    end
    this_lims = nan(2,3);
    switch lower(type)
      case { 'axes' , 'hggroup' }
        this_lims = objbounds( get( h , 'Children' ) , T , on_hidden );
        if isempty( this_lims ), this_lims = nan(2,3); end
        this_lims = reshape( this_lims , [2 3] );
      case 'hgtransform'
        this_lims = objbounds( get( h , 'Children' ) , T * get( h , 'Matrix' ) , on_hidden );
        if isempty( this_lims ), this_lims = nan(2,3); end
        this_lims = reshape( this_lims , [2 3] );
      case {'line','surface','patch'}
        X = []; Y = []; Z = [];
        if onoff(h,'XLimInclude'), X = get( h , 'XData' ); end
        if onoff(h,'YLimInclude'), Y = get( h , 'YData' ); end
        if onoff(h,'ZLimInclude'), Z = get( h , 'ZData' ); end
        this_lims = computeLims( X , Y , Z , T );
      case 'image'
        [X,Y] = localGetImageBounds( h );
        if ~onoff(h,'XLimInclude'), X = []; end
        if ~onoff(h,'YLimInclude'), Y = []; end
        if ~isequal( T , eye(4) ) && ~isequal( T , 1 )
          warning('limits of transformed images can be wrong!');
        end
        this_lims = computeLims( X , Y , [] , T );
      case 'rectangle'
        R = get( h , 'position' );
        X = R(1) + [ 0 ; R(3) ];
        Y = R(2) + [ 0 ; R(4) ];
        if ~onoff(h,'XLimInclude'), X = []; end
        if ~onoff(h,'YLimInclude'), Y = []; end
        this_lims = computeLims( X , Y , [] , T );
        
    end
    if isempty( this_lims ), this_lims = nan(2,3); end
    lims = [ min( lims(1,:) , this_lims(1,:) ) ;...
             max( lims(2,:) , this_lims(2,:) ) ];
  end
  
  if numel(HS) == 1 && strcmp(get(HS,'type'),'axes')
    xl = get(HS,'XLim');
    if ~isfinite(lims(1,1)), lims(1,1) = xl(1); end
    if ~isfinite(lims(2,1)), lims(2,1) = xl(2); end
    
    yl = get(HS,'YLim');
    if ~isfinite(lims(1,2)), lims(1,2) = yl(1); end
    if ~isfinite(lims(2,2)), lims(2,2) = yl(2); end
    
    zl = get(HS,'ZLim');
    if ~isfinite(lims(1,3)), lims(1,3) = zl(1); end
    if ~isfinite(lims(2,3)), lims(2,3) = zl(2); end
  end
  if lims(1,1) == lims(2,1), lims(:,1) = double( eps(single(lims(1,1))) )*pow2(10)*[-1;1] + lims(1,1); end
  if lims(1,2) == lims(2,2), lims(:,2) = double( eps(single(lims(1,2))) )*pow2(10)*[-1;1] + lims(1,2); end
  if lims(1,3) == 0 && lims(2,3) == 0, lims(:,3) = [-1;1]; end
  if lims(1,3) == lims(2,3), lims(:,3) = double( eps(single(lims(1,3))) )*pow2(10)*[-1;1] + lims(1,3); end

 
  lims = lims(:).';
  if all( isnan(lims) )
    lims = [];
  elseif isnan( lims(5) ) && isnan( lims(6) )  ||...
         all( abs( lims([5 6])  ) < 1e-10 )
    lims([5 6]) = [-1 1];
  end

  function tlims = computeLims( X , Y , Z , T )
    sz = [ max( [numel(X),numel(Y),numel(Z)] ) , 1 ];
    if isempty( X ), X = nan(sz); end
    if isempty( Y ), Y = nan(sz); end
    if isempty( Z ), Z = nan(sz); end
    try, X = repmat( X(:) , sz(1)/numel(X) , 1 ); end
    try, Y = repmat( Y(:) , sz(1)/numel(Y) , 1 ); end
    try, Z = repmat( Z(:) , sz(1)/numel(Z) , 1 ); end
    XYZ = [ X(:) , Y(:) , Z(:) ];
    if ~isequal( T , eye(4) ) && ~isequal( T , 1 )
      XYZ = XYZ*T(1:3,1:3).';
      XYZ = bsxfun( @plus , XYZ , T(1:3,4).' );
    end
    tlims = [ min(XYZ,[],1) ; max(XYZ,[],1) ];
  end

  if SC ~= 1
    lims = reshape( lims ,2,[]);
    lims = bsxfun(@plus, SC* bsxfun(@minus, lims , mean(lims,1) )  , mean(lims,1) );
    lims = lims(:).';
  end
  

%----------------------------------
  function [xd,yd] = localGetImageBounds(h)
    % Determine the bounds of the image
    
    xdata = get(h,'XData');
    ydata = get(h,'YData');
    cdata = get(h,'CData');
    m = size(cdata,1);
    n = size(cdata,2);
    
    [xd(1), xd(2)] = localComputeImageEdges(xdata,n);
    [yd(1), yd(2)] = localComputeImageEdges(ydata,m);
    
    %----------------------------------
    function [min,max]= localComputeImageEdges(xdata,num)
      % Determine the bounds of an image edge
      
      % This algorithm is an exact duplication of the image HG c-code
      % Reference: src/hg/gs_obj/image.cpp, ComputeImageEdges(...)
      
      offset = .5;
      nreals = length(xdata);
      old_nreals = nreals;
      
      if (old_nreals>1 && isequal(xdata(1),xdata(end)))
        nreals = 1;
      end
      
      first_last(1) = 1;
      first_last(2) = num;
      
      if (num==0)
        min = nan;
        max = nan;
      else
        first_last(1) = xdata(1);
        if (nreals>1)
          first_last(2) = xdata(end);
        else
          first_last(2) = first_last(1) + num - 1;
        end
        
        % Data should be monotonically increasing
        if (first_last(2) < first_last(1))
          first_last = fliplr(first_last);
        end
        
        if (num > 1)
          offset = (first_last(2) - first_last(1)) / (2 * (num-1));
        elseif (nreals > 1)
          offset = xdata(end) - xdata(1);
        end
        min = first_last(1) - offset;
        max = first_last(2) + offset;
      end
      
    end
  end

end
