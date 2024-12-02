function keepvars( V )

  if isstruct( V ), V = { V.name }; end
  if ~iscell(V), V = V{1}; end
  allV = evalin( 'caller' , 'who' );
  
  allV = setdiff( allV , V );

  for i = 1:numel(allV)
    evalin('caller' , sprintf('clearvars(''%s'');' , allV{i} ) );
  end

  if strcmp( get(0,'Diary') , 'on' );
    diary('off');
    diary('on');
  end
  
end
