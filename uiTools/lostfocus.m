function lostfocus( h )
% 
% Example:
% 
%   close all
%   figure
%   set( gcf , 'KeyPressFcn','disp(123)');
%   uicontrol( 'callback','disp(456)' );
%   uicontrol( 'Position',[20 60 50 20],'callback','disp(789), lostfocus' );
% 

  if nargin < 1, h = gcf; end
  h = ancestor( h , 'figure' );

  try %#ok<TRYNC>
    matlabV = sscanf(version,'%d.%d.%d.%d.%d',5); matlabV=[100,1,1e-2,1e-9,1e-13]*[ matlabV(1:min(5,end)) ; zeros(5-numel(matlabV),1) ];
    if matlabV > 804
      oldW = warning('query','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
      CLEANOUT = onCleanup( @()warning(oldW.state,oldW.identifier) );
      warning('off',oldW.identifier);
    end
    jf= get( handle(h) , 'JavaFrame' );
    jf.getFigurePanelContainer.getParent.getParent.requestFocusInWindow;
  end  
end
