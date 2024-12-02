function [C_, h_] = contour(varargin)

  cax = [];
  if isscalar( varargin{1} ) && ishandle( varargin{1} ) && strcmp(get(varargin{1},'type'),'axes')
    cax = varargin{1};
    varargin(1) = [];
  end

  lineprops = {};
  firstCHAR = find( cellfun(@ischar,varargin) , 1 );
  if firstCHAR
    lineprops = getLinespec( varargin( firstCHAR:end ) );
    varargin( firstCHAR:end ) = [];
  end

  C = contourc( varargin{:} );

  if isempty(cax) || isa(handle(cax),'hg.axes')
    cax = newplot(cax);
    is_hold = ishold( cax );
  else
    is_hold = false
  end

  h = line( 'Parent', cax , 'XData', C(:,1) , 'YData', C(:,2) , 'ZData', C(:,3) , lineprops{:} );

  if ~ishold
    axis(cax,'equal');
    view(cax,3);
  end

  if nargout > 0, C_ = C; end
  if nargout > 0, h_ = h; end

end
