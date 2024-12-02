function S = getRandState()

  while 1
    try
    state   = rand( 'state'   );
    seed    = rand( 'seed'    );
    twister = rand( 'twister' );
    break;
    end
  end

  sr = rand(1);

  rand('state',state); 
  srn = rand(1);
  if sr == srn
    S = { 'state' , state };
    rand( S{:} );
    return;
  end


  rand('seed',seed); 
  srn = rand(1);
  if sr == srn
    S = { 'seed' , seed };
    rand( S{:} );
    return;
  end
  
  
  rand('twister',twister); 
  srn = rand(1);
  if sr == srn
    S = { 'twister' , twister };
    rand( S{:} );
    return;
  end
  
  
end

