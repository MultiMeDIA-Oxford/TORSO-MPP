function [I,H] = read_NII( fname , varargin )

  if ~isfile( fname )
    error('imposible to open file');
  end

  
  onlyHDR = false;
  [varargin,onlyHDR] = parseargs(varargin,'onlyHDR' ,'$FORCE$',{true,onlyHDR});


  for machineformat = { 'ieee-be' , 'ieee-le' , 'ieee-be.l64' , 'ieee-le.l64' , 'native' , 'vaxd' , 'vaxg' }
    try
      fid = fopen( fname , 'rb' , machineformat{1} );
    catch
      continue;
    end
    fseek(fid,0,'bof');
    H.sizeof_hdr    = fread(fid,1,'*int32')';
    
    if H.sizeof_hdr ~= 348
      H = [];
      fclose(fid);
      continue;
    end
    
    fseek( fid , 344 , 'bof' );
    H.magic         = fread(fid,4,'*char')';
    if      strcmp( H.magic(1:3) , 'n+1' )
      data_fname      = fname;
      data_min_offset = 352;
      hdr_format = 'nii';
    elseif  strcmp( H.magic(1:3) , 'ni1' )
      [p,f,e] = fileparts( fname );
      data_fname      = fullfile( p , [ f , '.img' ] );
      data_min_offset = 0;
      hdr_format = 'nii';
    elseif  isequal( H.magic , char([0 0 0 0]) )
      [p,f,e] = fileparts( fname );
      data_fname      = fullfile( p , [ f , '.img' ] );
      data_min_offset = 0;
      hdr_format = 'img';
    end

    H.hdr_format = hdr_format;

    fseek( fid , 4 , 'bof' );
    H.data_type     = trim( fread(fid,10,'*char')' );
    H.db_name       = trim( fread(fid,18,'*char')' );
    H.extents       = fread(fid,1,'*int32')';
    H.session_error = fread(fid,1,'*int16')';
    H.regular       = trim( fread(fid,1,'*char')' );
    H.dim_info      = trim( fread(fid,1,'*char')' );
    H.dim           = fread(fid,8,'*int16')';

    switch hdr_format
      case 'nii'
    H.intent_p1     = fread(fid,1,'float32')';
    H.intent_p2     = fread(fid,1,'float32')';
    H.intent_p3     = fread(fid,1,'float32')';
    H.intent_code   = fread(fid,1,'*int16')';
    H.datatype      = fread(fid,1,'*int16')';
    H.bitpix        = fread(fid,1,'int16')';
    H.slice_start   = fread(fid,1,'*int16')';
    H.pixdim        = fread(fid,8,'float32')';

    H.qfac          = double( H.pixdim(1) );
    if H.qfac == 0 , H.qfac = 1; end
    if abs(H.qfac) ~= 1
      warning('bad value in qfac, using qfac = 1');
      H.qfac = 1;
    end

    H.vox_offset    = fread(fid,1,'float32')';
    H.scl_slope     = fread(fid,1,'float32')';
    H.scl_inter     = fread(fid,1,'float32')';
    H.slice_end     = fread(fid,1,'*int16')';
    H.slice_code    = trim( fread(fid,1,'*char')' );
    H.xyzt_units    = fread(fid,1,'*int8')';
      case 'img'
    H.unused8       = fread(fid,1,'*int16')';
    H.unused9       = fread(fid,1,'*int16')';
    H.unused10      = fread(fid,1,'*int16')';
    H.unused11      = fread(fid,1,'*int16')';
    H.unused12      = fread(fid,1,'*int16')';
    H.unused13      = fread(fid,1,'*int16')';
    H.unused14      = fread(fid,1,'*int16')';
    H.datatype      = fread(fid,1,'*int16')';
    H.bitpix        = fread(fid,1,'*int16')';
    H.dim_un0       = fread(fid,1,'*int16')';
    H.pixdim        = fread(fid,8,'float32')';
    H.vox_offset    = fread(fid,1,'float32')';
    H.funused1      = fread(fid,1,'float32')';
    H.funused2      = fread(fid,1,'float32')';
    H.funused3      = fread(fid,1,'float32')';
    end

    H.cal_max       = fread(fid,1,'float32')';
    H.cal_min       = fread(fid,1,'float32')';

    switch hdr_format
      case 'nii'
    H.slice_duration= fread(fid,1,'float32')';
    H.toffset       = fread(fid,1,'float32')';
      case 'img'
    H.compressed    = fread(fid,1,'float32')';
    H.verified      = fread(fid,1,'float32')';
    end
    
    H.glmax         = fread(fid,1,'*int32')';
    H.glmin         = fread(fid,1,'*int32')';
    H.descrip       = trim( fread(fid,80,'*char')' );
    H.aux_file      = trim( fread(fid,24,'*char')' );

    switch hdr_format
      case 'nii'
    H.qform_code    = fread(fid,1 ,'*int16')';
    H.sform_code    = fread(fid,1 ,'*int16')';
    H.quatern_b     = fread(fid,1,'float32')';
    H.quatern_c     = fread(fid,1,'float32')';
    H.quatern_d     = fread(fid,1,'float32')';
    H.qoffset_x     = fread(fid,1,'float32')';
    H.qoffset_y     = fread(fid,1,'float32')';
    H.qoffset_z     = fread(fid,1,'float32')';
    H.srow_x        = fread(fid,4,'float32')';
    H.srow_y        = fread(fid,4,'float32')';
    H.srow_z        = fread(fid,4,'float32')';
    H.intent_name   = trim( fread(fid,16,'*char')' );
    H.magic         = trim( fread(fid,4,'*char')' );
    H.extensions    = trim( fread(fid,4,'*char')' );
      case 'img'
    H.orient        = fread(fid,1 ,'*int8')';
    H.originator    = trim( fread(fid,10,'*char')' );
    H.generated     = trim( fread(fid,10,'*char')' );
    H.scannum       = trim( fread(fid,10,'*char')' );
    H.patient_id    = trim( fread(fid,10,'*char')' );
    H.exp_date      = trim( fread(fid,10,'*char')' );
    H.exp_time      = trim( fread(fid,10,'*char')' );
    H.hist_un0      = trim( fread(fid,3 ,'*char')' );
    H.views         = fread(fid,1,'*int32')';
    H.vols_added    = fread(fid,1,'*int32')';
    H.start_field   = fread(fid,1,'*int32')';
    H.field_skip    = fread(fid,1,'*int32')';
    H.omax          = fread(fid,1,'*int32')';
    H.omin          = fread(fid,1,'*int32')';
    H.smax          = fread(fid,1,'*int32')';
    H.smin          = fread(fid,1,'*int32')';
    end

    fclose(fid);
    
    if onlyHDR
      I = [];
      return;
    end
    
    bits = -1;
    switch H.datatype
      case    0, error('datatype 0!!!  what it says, dude?? ');
      case    1, error('aun no esta implementado que lea logicals!!!' );
      case    2, DT = '*uint8';   bits = 8;
      case    4, DT = '*int16';   bits = 16;
      case    8, DT = '*int32';   bits = 32;
      case   16, DT = '*float32'; bits = 32;
      case   32, error('leyendo una imagen en complejos??? partes reales e imag en float32 (single)');
      case   64, DT = '*double';  bits = 64;
      case  128, error('leyendo una imagen en RGBTRIPLETS!!?? de 24 bits/voxel');
      case  255, error('datatype 255!!!  not very usefull (?) ');
      case  256, DT = '*int8';    bits = 8;
      case  512, DT = '*uint16';  bits = 16;
      case  768, DT = '*uint32';  bits = 32;
      case 1024, DT = '*int64';   bits = 64;
      case 1280, DT = '*uint64';  bits = 64;
      case 1536, error('no puedo leer long double (128 bits)');
      case 1792, error('leyendo una imagen en complejos??? partes reales e imag en float64 (double)');
      case 2048, error('leyendo una imagen en complejos??? partes reales e imag en float128 (long double)');
      case 2304, error('leyendo una imagen en RGBTRIPLETS!!?? de 32 bits/voxel');
    end
    if bits == -1
      switch lower( H.data_type )
        case 'ushort', DT = '*uint16';   bits = 16;
        case 'short',  DT = '*int16';    bits = 16;
        case 'char',   DT = '*int8';     bits = 8;
        otherwise
          warning('read_NII:unknownDataType','Unknown DATATYPE (%d) and DATA_TYPE (%s). Using bitpix (%d). if the image is incorrect try with typecast.',H.datatype,H.data_type,H.bitpix);
          switch H.bitpix
            case    8, DT = '*uint8';   bits = 8;
            case   16, DT = '*int16';   bits = 16;
            case   32, DT = '*float32'; bits = 32;
            case   64, DT = '*double';  bits = 64;
            otherwise
              error('incorrect bitpix');
          end
      end
    end
    if bits ~= H.bitpix
      error('inconsistency between datatype and bitpix');
    end
    
    dim = double( H.dim );
    if dim(1) > 0 && dim(1) < 8
      dim = dim( 2 : dim(1)+1 );
    else
      dim = dim(2:end); dim(~dim) = [];
    end
    nvoxels = prod( dim(~~dim) );

    if ~isfile( data_fname )
      error('no hay data_fname');
    end
    
    if ( filesize( data_fname ) - max( data_min_offset , H.vox_offset ) )*8/double(H.bitpix) < nvoxels
      %fclose(fid);
      error('file too small??!!?!?!!?!?');
    end

    fid = fopen( data_fname , 'rb' , machineformat{1} );
    fseek( fid , max( data_min_offset , H.vox_offset ) , 'bof' );
    I = fread( fid , nvoxels , DT );
    fclose(fid);

    I = reshape(I,dim(~~dim));

%     if strcmp( hdr_format , 'nii' )
%       I = I*H.scl_slope + H.scl_inter;
%     end
    
    break;

  end

  if isempty(H)
    error('incorrect filetype??');
  end

  
  function s = trim(s)
    if any(~s)
      s = s( 1:find(~s,1)-1 );
    end
  end

  %vfunction 's = trim(s), if any(~s), s = s( 1:find(~s,1)-1 ); end; end'


end

