function HS = HSwC( HS )
% keep only the slices with at least 1 contour

  HS = HS( ~all(cellfun('isempty',HS(:,2:end)),2) ,:);

end