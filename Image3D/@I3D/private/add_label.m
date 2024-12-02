function I = add_label( I , l , description , alpha , rgb )
  if nargin < 2
    l= numel( I.LABELS_INFO )+1;
  end
  if numel( I.LABELS_INFO ) >= l
    error('The label already exists.');
  end
  if nargin < 5
    %rgb = rand(1,3);
    rgb = hsv2rgb( [ rand(1) , rand(1)*0.3 + 0.7 , rand(1)*0.1 + 0.9 ] );
    rgb = round( rgb*20 )/20;
  end
  if nargin < 4
    alpha = 0.5;
  end
  if nargin < 3
    description = sprintf( 'L_%04d',l );
  end

  I.LABELS_INFO(l).description = description;
  I.LABELS_INFO(l).alpha       = alpha;
  I.LABELS_INFO(l).color       = rgb;
  I.LABELS_INFO(l).state       = 1;

end
    
    
