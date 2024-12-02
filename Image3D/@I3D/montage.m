function montage( I , d , sz , varargin )

  [varargin,i,FCN] = parseargs(varargin,'FCN','$DEFS$',[]);

  if nargin < 3  || isempty( sz )
    sz = [NaN NaN];
  end
  if nargin < 2, d  = 'k';   end

  if numel(sz) == 1, sz = [sz,sz]; end
  
  nK = size( I , d-'i'+1 );
  if      isnan( sz(1) ) && ~isnan( sz(2) )
    sz(1) = ceil( nK/sz(2) );
  elseif ~isnan( sz(1) ) &&  isnan( sz(2) )
    sz(2) = ceil( nK/sz(1) );
  elseif  isnan( sz(1) ) &&  isnan( sz(2) )
    sz(2) = ceil( sqrt(nK) );
    sz(1) = ceil( nK / sz(2) );
  else
  end
  
  
  idxs = unique( round( linspace( 1 , size( I , lower(d)-'i'+1 ) , sz(1)*sz(2) ) ) );
  idxs(end+1:(sz(1)*sz(2))) = 0;

  
  hFig = figure(varargin{:}); clf(hFig,'reset');
  set( hFig ,'nextPlot','add');
  
  w = 1/sz(2);
  h = 1/sz(1);
  
  k = 0;
  for i = 1:sz(1)
    for j = 1:sz(2)
      k = k+1; if ~idxs(k), continue; end
      hAxe = axes( 'parent' , hFig , 'position' , [ w*(j-1) , h*( sz(1) - i )  , w , h ]  ,'box','on' );
      
      switch lower(d)
        case 'k', image( subsref( I , substruct('()',{':',':',idxs(k)}) ) );
        case 'j', image( subsref( I , substruct('()',{':',idxs(k),':'}) ) );
        case 'i', image( subsref( I , substruct('()',{idxs(k),':',':'}) ) );
      end
      
      if ~isempty( FCN ), try, feval( FCN , idxs(k) ); end; end
      
      set( hAxe , 'xtick',[],'ytick',[],'ztick',[] ,'visible','off' );
    end
  end

  set( hFig ,'nextPlot','new');
end
