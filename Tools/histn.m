function [M0,centerbars] = histn( varargin )

  [varargin,PLOT_G] = parseargs(varargin,'g','$FORCE$',1 );

  cax = [];
  if isscalar( varargin{1} ) && ishandle( varargin{1} ) && strcmp(get(varargin{1},'type'),'axes')
    cax = varargin{1};
    varargin = varargin(2:end);
  end
  
  if numel(varargin) == 0, error('a matrix data expected.'); end
  x = varargin{1};
  varargin = varargin(2:end);
  
  if ndims(x) ~= 2, error('a matrix data expected.'); end
  
  N = size(x,1);
  D = size(x,2);
  
  if N < 2, error('more than 1 element expected.'); end
  if D < 1, error('empty data!!!.'); end

  
  if numel(varargin)
    B = varargin{1};
    varargin = varargin(2:end);
  else
    B = 10;
  end
  if isscalar(B), B = zeros([1,D])+B; end
  if numel(B) ~= D, error('nbins has to have %d elements.',D); end
  
  range = [ min( x , [] , 1 ) ; max( x , [] , 1 ) ];
  range(1,:) = range(1,:) - 10*eps(range(1,:));
  range(2,:) = range(2,:) + 10*eps(range(2,:));
  center = mean(range,1);
  maxR = max( range(2,:) - center );

  
  edges = arrayfun( @(d) linspace(center(d)-maxR,center(d)+maxR,B(d)+1) , 1:D , 'UniformOutput', false );
  centerbars = cellfun( @(x) (x(1:end-1)+x(2:end))/2 , edges , 'UniformOutput', false );
  I = cell2mat( arrayfun( @(d) getInterval( x(:,d) , edges{d} ) , 1:D , 'UniformOutput',false ) );
  I( ~I ) = 1;
  
  
  M = accumarray( I , 1 );
  Bv = prod( cellfun( @(e) mean(diff(e)) , edges ) );

  M = M/N/Bv;

  o(1:D) = {1};
  for d = 1:D
    if size(M,d) < B(d)
      M( o{1:d-1} , B(d) , o{d+1:end} ) = 0;
    end
  end

  
  if nargout == 0
    switch D
      case 1
        if isempty(cax), cax = gca; end
        if isempty( varargin )
          bar(cax , centerbars{1} , M , edges{1}([1 end]) , 'hist' );
        else
          varargin = getLinespec( varargin );
          
          newplot
          
          line('xdata', centerbars{1} , 'ydata', M , 'Parent', cax , varargin{:} );
%           bbars = dualVector( centerbars{1} ); bbars = bbars(:);
%           xy = cat(3, [ bbars(1:end-1) , M ] , [ bbars(2:end) , M ] );
%           xy = reshape( permute( xy , [3 1 2] ) , [] , 2 );
%           xy = [ bbars(1) , 0 ; xy ; bbars(end) , 0 ];
%           line('xdata', xy(:,1) , 'ydata', xy(:,2) , 'Parent', cax , varargin{:} );
               
          
          
        end

        if PLOT_G
          m = mean(x);
          s = std(x);
          t = sort( [ -10:0.01:10 -2 -2 -1 -1 0 0 1 1 2 2 ] ) * s + m;
          g = 1/( sqrt(2*pi) * s )*exp( - (t-m).^2 / 2 / s^2 );
          idx = find( ~diff(t) );
          g( idx(2:2:end) ) = 0;
          
          line( 'parent',cax,'xdata', t , 'ydata', g ,'Color',[0 0.7 0] );
        end
        
      case 2
        if isempty(cax), cax = gca; end
        surf(cax, edges{1}(sort([1:end 2:end-1])) , edges{2}(sort([1:end 2:end-1])) , M(sort([1:end 1:end]),sort([1:end 1:end])).' , 'facecolor','interp' );

        if PLOT_G
          z = max( M(:) );
          m = mean(x,1);
          [v,d] = eig(cov(x));
          d= sqrt(diag(d));
          line( 'Parent' , cax ,'XData',m(1)+[0 v(1,1)]*d(1),'YData',m(2)+[0 v(1,2)]*d(1),'ZData',[z z],'Color',[0 0 1],'linewidth',2);
          line( 'Parent' , cax ,'XData',m(1)+[0 v(2,1)]*d(2),'YData',m(2)+[0 v(2,2)]*d(2),'ZData',[z z],'Color',[1 0 0],'linewidth',2 );
          
          t = linspace(0,2*pi,500); t=t(1:end-1).';

          xy = [ cos(t) sin(t) ]*v*diag(d)*v.';
          line( 'Parent' , cax ,'XData',m(1)+xy(:,1),'YData',m(2)+xy(:,2),'ZData',z+xy(:,1)*0,'Color',[0 1 0],'linewidth',1 );

          xy = 2*xy;
          line( 'Parent' , cax ,'XData',m(1)+xy(:,1),'YData',m(2)+xy(:,2),'ZData',z+xy(:,1)*0,'Color',[0 1 1],'linewidth',1 ,'linestyle',':');

%           m = mean(x,1).';
%           C = cov(x); iC = inv(C);
%           xy = ndmat( linspace(range(1,1),range(2,1),50) , linspace(range(1,2),range(2,2),50) ,'nocat' );
%           for i=1:size(xy,1)
%             for j=1:size(xy,2)
%               v = vec( xy(i,j,:) ) - m ;
%               g(i,j) = exp( - v.'*iC*v/2 );
%             end
%           end
%           g = g/2/pi/sqrt(det(C));
%           surface('Parent',cax ,'XData',xy(:,:,1),'YData',xy(:,:,2),'ZData',g,'cdata',g,'faceColor',[0 1 1],'edgecolor',[1 0 0],'facealpha',0.2 );
       
        end
        
      case 3
        if isempty(cax), cax = gca; end
        image3( M , 'x',centerbars{1} ,'y',centerbars{2},'z',centerbars{3},'facemode','flat');
        caxis( [ 0   max(M(:))/2 ] );

        if PLOT_G
          m = mean(x,1);
          [v,d] = eig(cov(x));
          d= sqrt( diag(d) );
          line( 'Parent' , cax ,'XData',m(1)+[0 v(1,1)]*d(1),'YData',m(2)+[0 v(2,1)]*d(1),'ZData',m(3)+[0 v(3,1)]*d(1),'Color',[0 0 1],'linewidth',2);
          line( 'Parent' , cax ,'XData',m(1)+[0 v(1,2)]*d(2),'YData',m(2)+[0 v(2,2)]*d(2),'ZData',m(3)+[0 v(3,2)]*d(2),'Color',[0 1 0],'linewidth',2 );
          line( 'Parent' , cax ,'XData',m(1)+[0 v(1,3)]*d(3),'YData',m(2)+[0 v(2,3)]*d(3),'ZData',m(3)+[0 v(3,3)]*d(3),'Color',[1 0 0],'linewidth',2 );
          
          [xx yy zz] = sphere(50);
          xyz = [xx(:) yy(:) zz(:)]*v*diag(d)*v.';
          xx(:) = xyz(:,1);
          yy(:) = xyz(:,2);
          zz(:) = xyz(:,3);
          
          surface('Parent',cax,'XData',m(1)+xx,'YData',m(2)+yy,'ZData',m(3)+zz,...
            'facecolor',[0 1 0],'facealpha',0.4 ,'edgecolor', 'none' );
          
          surface('Parent',cax,'XData',m(1)+2*xx,'YData',m(2)+2*yy,'ZData',m(3)+2*zz,...
            'facecolor',[0 1 1],'facealpha',0.1 ,'edgecolor','r' );
          
        end
        
    end

  else
    M0 = M;
  end
    
