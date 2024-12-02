function S = getRandnState

  try, state   = randn( 'state'   ); end
  try, seed    = randn( 'seed'    ); end
  try, twister = randn( 'twister' ); end

  sr = randn(1);

  randn('state',state); 
  srn = randn(1);
  if sr == srn
    S = { 'state' , state };
    randn( S{:} );
    return;
  end


  randn('seed',seed); 
  srn = randn(1);
  if sr == srn
    S = { 'seed' , seed };
    randn( S{:} );
    return;
  end
  
  try
    randn('twister',twister); 
    srn = randn(1);
    if sr == srn
      S = { 'twister' , twister };
      randn( S{:} );
      return;
    end
  end
  
end

