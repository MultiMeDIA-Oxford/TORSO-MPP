function s_old_ = randnseed

  s_old = getRandnState;
  try
    randn( 'state' , sum( ( double(uuid) - double('00000000-0000-0000-0000-000000000000') ).* ( 10.^[1:8 0 1:4 0 1:4 0 1:4 0 1:12] ) )/6.00065e13*2^32 );
  catch
    
    if ispc
      s = [ feature('timing','cpucount')  feature('timing','wintimeofday')   feature('getpid') ];
    elseif isunix
      s = [ feature('timing','cpucount')  feature('timing','unixtimeofday')  feature('getpid') ];
    else
      %type feature('timing') to know options
      s = [ feature('timing','cpucount')  feature('getpid') ];
    end
    
    s = rem( sum(double(s)) , 2^30);
    try
      s = s + trand * 2^30;
      s = rem( s , 2^30 );
    end

    randn( 'state', s );
  end

  
  if nargout, s_old_ = s_old; end

if 0

for i=1:10
  for kk=1:10000
%     m(kk)= uint32( ( sum( double(uuid).*linspace(0.005,1,36) ) - 859 )*2^32/( 1744 - 859 ) );
    m(kk)= uint32( uint32( sum( ( double(uuid) - double('00000000-0000-0000-0000-000000000000') ).* ( 10.^[1:8 0 1:4 0 1:4 0 1:4 0 1:12] ) )/6.00065e13*2^32 ) );
  end
  disp([ numel( unique(m) )/numel(m) ,  numel(m)-numel( unique(m) ) ])
end

hist( log10(double(m)) , 100 )


intmax('uint32') - ...
uint32( sum( ( double('ffffffff-ffff-ffff-ffff-ffffffffffff') - double('00000000-0000-0000-0000-000000000000') ).* ( 10.^[1:8 0 1:4 0 1:4 0 1:4 0 1:12] ) )/6.00065e13*2^32 )


sum( double(uuid)-double('00000000-0000-0000-0000-000000000000').*linspace(1,10,36) )
sum( ( double('ffffffff-ffff-ffff-ffff-ffffffffffff') - double('00000000-0000-0000-0000-000000000000') ).* ( 10.^[1:8 0 1:4 0 1:4 0 1:4 0 1:12] ) )/6.001e13*2^32

end

end
