function ret_pos = fixposition( h , pos , varargin)
% 
% pcenter = uipanel('position',[.3 .3 .3 .3]);
% pwest   = uipanel('position',[0 0 .1 1] );
% 
% fixposition( pcenter ,'.5-40p,.5-40p,80p,80p');
% fixposition( pwest   ,'20p,20p,100p,1-40p' );
% 
% set(pcenter,'ResizeFcn',@(h,e) fixposition(h,'container') )
% set(pcenter,'ResizeFcn',@(h,e) fixposition(h,'container') )
% 
% b = uicontrol('parent',pcenter);
% fixposition(b,'1-20p,1-20p,20p,20p','FIX');
% 
% % bj= findjobj(b);
% % set(bj,'ComponentResizedCallback',@(h,e) setposition(b) );
% 

  if nargin > 1
    if any( strcmp(pos,{'children','c'}) )
      children = findall( h , 'Parent' , h )';
      for c= children
        fixposition(c);   
      end
      return;
    end
    if any( strcmp(pos,{'allchildren','ac'}) )
      children = findall( h )';
      for c= children
        fixposition(c);   
      end
      return;
    end
    if any( strcmp(pos,{'container'}) )
      fixposition(h);
      fixposition(h,'children');
      return;
    end
    
    pos_n = [ 0   0   0   0 ];
    pos_p = [NaN NaN NaN NaN];

    if ischar(pos)
      pos = textscan(pos,'%s','delimiter',',');
      pos = pos{1};
    end

    if iscell(pos)
      for i= 1:numel(pos)
        p = pos{i};

        p = lower(p);
        p = strrep(p,' ','');
        p = strrep(p,'-','+-');
        p = strrep(p,'pixels','p');
        p = strrep(p,'pixel','p');
        p = strrep(p,'pix','p');
        p = strrep(p,'normalized','n');
        p = strrep(p,'norm','n');
        p = strrep(p,'nor','n');

        while ~isempty(p)
          if p(1)=='+', p(1)=[]; end
          [tok,p] = strtok(p,'+');
          if isstrprop(tok(end),'digit'), tok=[tok 'n']; end
          if tok(end)=='.'              , tok=[tok 'n']; end
          switch tok(end)
            case 'n'
              value = sscanf(tok,'%fn');
              if isnan(pos_n(i))
                pos_n(i)= value;
              else
                pos_n(i)= pos_n(i)+value;
              end
            case 'p'
              value = sscanf(tok,'%fp');
              if isnan(pos_p(i))
                pos_p(i)= value;
              else
                pos_p(i)= pos_p(i)+value;
              end
          end
        end
      end
    else
      pos_n = pos(1,:);
      try
        pos_p = pos(2,:);
      end
    end
    ret_pos = [pos_n ; pos_p];
    setappdata(h,'FIXEDPOSITION',ret_pos);
  else
    ret_pos = getappdata(h,'FIXEDPOSITION');
    if isempty(ret_pos), return; end
    pos_n   = ret_pos(1,:);
    pos_p   = ret_pos(2,:);
  end
  
  try
    container = get(h,'Parent');
%     set(container,'units','pixels');
%     WH= get(container,'position'); WH= WH(3:4);
    WH = getposition(container,'pixels','local',3:4);

    pos_n = pos_n.*[WH WH];
    pos = pos_n + pos_p;
    
%     hj= findjobj(h);
%     oldResizedCallback = get(hj,'ComponentResizedCallback');
%     set(hj,'ComponentResizedCallback', '' );

    oldUnits = get(h,'Units');
    set(h,'Units','pixels');
    if any(isnan(pos))
      pos_actual= get(h,'Position');
      pos( isnan(pos) )= pos_actual(isnan(pos));
    end
    set(h,'Position',pos);
    set(h,'units',oldUnits);

%     drawnow expose;
%     set(hj,'ComponentResizedCallback', oldResizedCallback );
%     drawnow expose;
  end

  [varargin,FIX]= parseargs(varargin,'fix','$FORCE$',1 );
  if FIX
    drawnow
    js = handle2javaobject(h);
    for i=1:numel(js)
      try
        jsi = handle( js{i} , 'callbackproperties');
        set( jsi ,'ComponentMovedCallback',@(hj,e) fixposition(h) );
        continue;
      end
    end
  end
  
end
