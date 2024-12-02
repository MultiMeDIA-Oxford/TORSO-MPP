function I = permute( I , order )
  %% falta implementar DefomationField y invDeformationField

  for d = 1:max(ndims(I.data),4)
    if numel(order) < d,  order(d) = d; end
  end

  switch order(1)
    case 1, newX= I.X;
    case 2, newX= I.Y;
    case 3, newX= I.Z;
    case 4, newX= I.T;
    otherwise, error('X can not be a coordinates dimension.');
  end
  switch order(2)
    case 1, newY= I.X;
    case 2, newY= I.Y;
    case 3, newY= I.Z;
    case 4, newY= I.T;
    otherwise, error('T can not be a coordinates dimension.');
  end
  switch order(3)
    case 1, newZ= I.X;
    case 2, newZ= I.Y;
    case 3, newZ= I.Z;
    case 4, newZ= I.T;
    otherwise, error('Z can not be a coordinates dimension.');
  end
  switch order(4)
    case 1, newT= I.X;
    case 2, newT= I.Y;
    case 3, newT= I.Z;
    case 4, newT= I.T;
%     otherwise, error('T can not be a coordinates dimension.');
    otherwise
      newT = 1:size(I,order(4));
  end

  if ~isempty( I.data   )
    I = DATA_action( I , [ '@(X) permute(X,' uneval(order) ')' ] );
  end
  if ~isempty( I.LABELS ),  I.LABELS = permute( I.LABELS , order ); end
  
  if ~isempty( I.FIELDS )
    for fn = fieldnames(I.FIELDS)'
      if isnumeric( I.FIELDS.(fn{1}) )  ||  islogical( I.FIELDS.(fn{1}) )
        I.FIELDS.(fn{1}) = permute( I.FIELDS.(fn{1}) , order );
        if any( [size(I.data,1) size(I.data,2) size(I.data,3)] ~= [size(I.FIELDS.(fn{1}),1) size(I.FIELDS.(fn{1}),2) size(I.FIELDS.(fn{1}),3)])
          warning('I3D:permuteInvalidFieldSize','After permute, check the field sizes.');
        end
      end
    end
  end


  I.X      = newX;
  I.Y      = newY;
  I.Z      = newZ;
  I.T      = newT;

end
