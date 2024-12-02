function D = getData( I , type )

  if nargin < 2
    type = '';
  end

  D = I.data;


  if ~isempty(type)
    D = cast( D , type );
  end
  
  
  if isempty(D)

    D = zeros([numel(I.X),numel(I.Y),numel(I.Z),numel(I.T)], class(D) );

  end

end
