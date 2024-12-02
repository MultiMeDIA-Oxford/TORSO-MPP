function filtered =  Moving_average(data, window)
  
  filtered = zeros(size(data));
  for ii = 1:size(data,1), filtered(ii,:) = mean(data(max(ii-floor(window/2.0),1):min(ii+floor(window/2.0),length(data)),:)); end
  
end