function set( eE , varargin )

  while numel(varargin)
    prop  = varargin{1}; varargin(1)=[];
    value = varargin{1}; varargin(1)=[];
    switch lower(prop)
      case 'visible'
        set( [eE.panel eE.edit eE.slider] , 'visible', value );
      case 'text'
        t = findall(eE.panel,'Style','text');
        if isempty(t)
          addtext( eE , value );
        else
          set( eE , 'String', value );
        end
      case 'enable'
        if strcmp(value,'on')
          set([eE.edit eE.slider],'Enable','on');
        elseif strcmp(value,'off')
          set( eE.edit   ,'Enable','inactive');
          set( eE.slider ,'Enable','off');
        end
        
    
    end
  end
  
end
