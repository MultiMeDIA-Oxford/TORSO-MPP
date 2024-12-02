function xy= axesxyz2figurexy( ax , xyz , varargin )
%
%   xy= axesxyz2figurexy( ax , xyz , ...
%                                   'Units' , {'pixels'}
%
%
%  examples:
%
%     axesxyz2figurexy( gca , [0 0 0] );
%
%     xy= axesxyz2figurexy( gca , [0 0 0; 1 1 1] ,'u','normalized' );
%     annotation('line', [xy(1,1) xy(2,1)],[xy(1,2) xy(2,2)] )
%


if ~strcmpi( get(ax,'Type') , 'Axes' )
  error('ax has to be an axes handle');
end

fH= get( ax , 'Parent' );
while ~strcmpi( get(fH,'Type'),'Figure' )
  fH= get( fH, 'Parent' );
end
oldU = get( fH,'Units' );
oldCP= get( fH,'CurrentPoint');

[varargin,i,units]= parseargs(varargin,'Units' , '$DEFS$','pixels');

set( fH, 'Units', 'pixels' );
h= get(fH,'Position');
h= h(4);

oldWAR= warning('query','MATLAB:Axes:NegativeDataInLogAxis');
warning('off','MATLAB:Axes:NegativeDataInLogAxis');
        
xlim= get( ax , 'XLim' ); if strcmp( get(ax,'XDir'),'reverse'), xlim= xlim([2 1]); end
ylim= get( ax , 'YLim' ); if strcmp( get(ax,'YDir'),'reverse'), ylim= ylim([2 1]); end
zlim= get( ax , 'ZLim' ); if strcmp( get(ax,'ZDir'),'reverse'), zlim= zlim([2 1]); end

warning( oldWAR.state , oldWAR.identifier );
        
if strcmp( get(ax,'XScale'),'log' ), xyz(:,1)= log10( xyz(:,1) ); xlim(1)= log10( xlim(1) ); end
if strcmp( get(ax,'YScale'),'log' ), xyz(:,2)= log10( xyz(:,2) ); ylim(1)= log10( ylim(1) ); end
if strcmp( get(ax,'ZScale'),'log' ), xyz(:,3)= log10( xyz(:,3) ); zlim(1)= log10( zlim(1) ); end

xyz= ( xyz(:)' - [xlim(1) ylim(1) zlim(1)] );


% xyz= (xyz(:)'-[xlim(1) ylim(1) zlim(1)]);

% if strcmp( get(ax,'XScale'),'log' ), xyz(:,1)= log( xyz(:,1) ); end
% if strcmp( get(ax,'YScale'),'log' ), xyz(:,2)= log( xyz(:,2) ); end
% if strcmp( get(ax,'ZScale'),'log' ), xyz(:,3)= log( xyz(:,3) ); end

RM = get( ax, 'x_RenderTransform' );
for i= 1:size( xyz,1 )
  p= RM*[ xyz(i,:) 1]';
  p= [ p(1) p(2) ]/p(4);
  p= round( [p(1) h-p(2)] + 0.5 );
  if ~strcmp( units , 'pixels' )
    set( fH, 'CurrentPoint', p );
    set( fH, 'Units', units );
    p= get( fH, 'CurrentPoint' );
    set( fH, 'Units', 'pixels' );
  end
  xy(i,:)= p;
end

set( fH, 'Units', oldU );
set( fH, 'CurrentPoint', oldCP);














%
% function [p] = topixels(this)
% %    topixels - Obtain the pixel coordinates of the pin with respect to
% % the figure
%
% %   Copyright 1984-2005 The MathWorks, Inc.
%
% ax = get(double(this), 'parent');
% vert = [ get(double(this), 'xdata'), ...
%          get(double(this), 'ydata'), ...
%          get(double(this), 'zdata') ];
%
% if strcmp(get(ax,'XScale'),'log')
%     if all(get(ax,'XLim') > 0)
%         vert(:,1) = log10(vert(:,1));
%     else
%         vert(:,1) = -log10(-vert(:,1));
%     end
% end
% if strcmp(get(ax,'YScale'),'log')
%     if all(get(ax,'YLim') > 0)
%         vert(:,2) = log10(vert(:,2));
%     else
%         vert(:,2) = -log10(-vert(:,2));
%     end
% end
% if strcmp(get(ax,'ZScale'),'log')
%     if all(get(ax,'ZLim') > 0)
%         vert(:,3) = log10(vert(:,3));
%     else
%         vert(:,3) = -log10(-vert(:,3));
%     end
% end
%
%
% % Transform vertices from data space to pixel space. This code
% % is based on HG's gs_data3matrix_to_pixel internal c-function.
%
% % Get needed transforms
% xform = get(ax,'x_RenderTransform');
% offset = get(ax,'x_RenderOffset');
% scale = get(ax,'x_RenderScale');
%
% % Equivalent: nvert = vert/scale - offset;
% nvert(:,1) = vert(:,1)./scale(1) - offset(1);
% nvert(:,2) = vert(:,2)./scale(2) - offset(2);
% nvert(:,3) = vert(:,3)./scale(3) - offset(3);
%
% % Equivalent xvert = xform*xvert;
% w = xform(4,1) * nvert(:,1) + xform(4,2) * nvert(:,2) + xform(4,3) * nvert(:,3) + xform(4,4);
% xvert(:,1) = xform(1,1) * nvert(:,1) + xform(1,2) * nvert(:,2) + xform(1,3) * nvert(:,3) + xform(1,4);
% xvert(:,2) = xform(2,1) * nvert(:,1) + xform(2,2) * nvert(:,2) + xform(2,3) * nvert(:,3) + xform(2,4);
%
% % w may be 0 for perspective plots
% ind = find(w==0);
% w(ind) = 1; % avoid divide by zero warning
% xvert(ind,:) = 0; % set pixel to 0
%
% p(:,1) = xvert(:,1) ./ w;
% p(:,2) = xvert(:,2) ./ w;
