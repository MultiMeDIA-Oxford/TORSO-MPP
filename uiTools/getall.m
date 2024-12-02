function props= getall( obj )

%   oldundoc= get(0,'HideUndocumented');
%   set( 0 , 'HideUndocumented','off' );
% 
%   props= get( obj );
%   
%   set( 0 , 'HideUndocumented','on' );
%   set( 0 , 'HideUndocumented',oldundoc );

  props = mergestruct( get( obj ) , getundoc( obj ) , '<' );

end