function Export_fig( hf , fn , varargin )



  fprintf('exporting picture (figure)...\n' );

  if mppBranch('ct')
%     wNaN = [];
%     for h = findall(hf)'
%       try
%         if any( isnan( get(h,'XData') ) ), wNaN(end+1) = h; continue; end
%         if any( isnan( get(h,'YData') ) ), wNaN(end+1) = h; continue; end
%         if any( isnan( get(h,'ZData') ) ), wNaN(end+1) = h; continue; end
%       end
%     end
    
    delete( findall( hf ,'Visible','off','-not','Type','axes') );
%     set( findall(hf,'Type','line'),'LineWidth',1)

    delete(findall(hf,'Marker','o'));
    delete(findall(hf,'Marker','x'));
%     delete(findall(hf,'LineStyle',':'));
%     delete(findall(hf,'LineStyle','--'));
    set(findall(hf,'Marker','o'),'Marker','x');
  end
  
  
  export_fig( hf , fn , varargin{:} );
  
  fprintf('Picture (figure) saved in "%s"\n', fn );
end

