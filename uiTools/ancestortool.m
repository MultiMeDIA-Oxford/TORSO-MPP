function h= ancestortool(h,type)

  if nargin<2, type= 'figure';  end
  if nargin<1, h= hittest;      end
  
%   if ishandle(h) 
%     if strcmp(get(h,'Type'),'uicontrol') || strcmp(get(h,'Type'),'uipanel')
%       h= 0
%       return
%     end
%   end

  if ishandle( h )
    while ~strcmpi( get(h,'Type') , type )
      h= get( h, 'Parent');
      if strcmpi( get(h,'Type') , 'root' ),  return;  end
    end
  else
    h = 0;
  end
end
