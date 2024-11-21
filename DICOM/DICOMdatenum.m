function dn = DICOMdatenum( item , FS )
  if ischar( item )
    item = dicominfo( item );
  end
  if nargin < 2
    FS = {'Acquisition','Content','InstanceCreation'};
  end
  if ~iscell( FS ), FS = { FS }; end
  
  dn = NaN;
  for f = FS(:).'
    try
           itime = item.( [ f{1} , 'Time' ] );
           idate = '19000101';
      try, idate = item.( [ f{1} , 'Date' ] ); end

      dn = zeros(1,6);
      dn(1) = str2double( idate(1:4) );
      dn(2) = str2double( idate(5:6) );
      dn(3) = str2double( idate(7:8) );

      dn(4) = str2double( itime(1:2)   );
      dn(5) = str2double( itime(3:4)   );
      dn(6) = str2double( itime(5:end) );
      dn    = datenum( dn );
      
      break;
    end
  end
  
end
