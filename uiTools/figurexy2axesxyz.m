function xyz= figurexy2axesxyz( xy , ax , varargin )
% 
% xyz= figurexy2axesxyz( xy , axes , varargin )
% 
% examples:
%   figurexy2axesxyz( [1 1], gca, 'units', 'pixels' )
%   
%   figurexy2axesxyz( [1 1], gca )
%   
%   figurexy2axesxyz( [.5 .5], gca, 'units', 'normalized')
%
%   figurexy2axesxyz( [.5 .5], gca, 'units', 'normalized')
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


[varargin,i,units]= parseargs( varargin , 'Units', '$DEFS$','pixels' );

set( fH, 'Units', units );

set( fH, 'CurrentPoint', xy )

xyz= get( ax , 'CurrentPoint' );

set( fH, 'Units', oldU );
set( fH, 'CurrentPoint', oldCP);
