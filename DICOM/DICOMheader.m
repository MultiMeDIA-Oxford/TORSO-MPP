function [F,P] = DICOMheader( F , varargin )
  if nargin == 0
      disp 'Filename'
      disp 'rawPatientName'
      disp 'FileModDate'
      %patient
      disp 'PatientID'
      disp 'PatientName'
      disp 'PatientAge'
      disp 'PatientSize'
      disp 'PatientWeight'
      disp 'PatientBirthDate'
      disp 'PatientBirthTime'
      disp 'PatientSex'
      disp 'PatientPosition'
      %study
      disp 'StudyInstanceUID'
      disp 'StudyDescription'
      disp 'StudyID'
      disp 'StudyDate'
      disp 'StudyTime'
      %series
      disp 'SeriesInstanceUID'
      disp 'SeriesDescription'
      disp 'SeriesNumber'
      disp 'SeriesDate'
      disp 'SeriesTime'
      %image
      disp 'SOPInstanceUID'
      disp 'MediaStorageSOPInstanceUID'
      %geometry
      disp 'ImageOrientationPatient'
      disp 'ImagePositionPatient'
      disp 'SliceLocation'
      disp 'PixelSpacing'
      disp 'Rows'
      disp 'Columns'
      %order
      disp 'TriggerTime'
      disp 'InstanceNumber'
      disp 'AcquisitionNumber'
      disp 'AcquisitionTime'
      disp 'InstanceCreationDate'
      disp 'InstanceCreationTime'
      disp 'AcquisitionDate'
      disp 'ContentDate'
      disp 'ContentTime'
      disp 'AcquisitionDateTime'      %no
      disp 'DateTime'                 %no
      disp 'Date'                     %no
      disp 'Time'                     %no
      disp 'CreationDate'             %no
      disp 'CreationTime'             %no
      %sequence?
      disp 'ImageType'
      disp 'SequenceName'
      disp 'InversionTimes'
      disp 'RepetitionTime'
      disp 'EchoTime'
      disp 'InversionTime'
      disp 'TriggerDelayTime'         %no
      disp 'TriggerTimeOffset'        %no
      %misc
      disp 'NumberOfFrames'
      disp 'ImageComments'
      disp 'ImplementationClassUID'
      disp 'ImplementationVersionName'    
      disp 'Planes'                   %no
      %dti
      disp 'Private_0019_100c'
      disp 'Private_0019_100e'

  return;
  end


  bytes_to_read = [];
  w = cellfun(@isnumeric,varargin);
  if any(w)
    bytes_to_read = varargin{ find(w,1,'last') };
    varargin(w) = [];
  end
  
  
  useDICOMINFO = false;
  w = strcmpi( varargin , 'useDICOMINFO' ) | strcmpi( varargin , 'DICOMINFO' );
  if any(w)
    useDICOMINFO = true;
    varargin(w) = [];
  end

  if isempty(varargin)
    varargin = {
      'Filename'
      'PatientName'
      'StudyDescription'
      'SeriesNumber'
      'SeriesDescription'
      'MediaStorageSOPInstanceUID'
      'PatientID'
      'StudyID'
      'StudyInstanceUID'
      'SeriesInstanceUID'
      'Rows'
      'Columns'
      'Planes'
      'PixelSpacing'
      'ImageOrientationPatient'
      'ImagePositionPatient'
      'TriggerTime'
      'AcquisitionTime'
      'AcquisitionNumber'
      'InstanceNumber'
      }.';
  end

  
  
  if iscell( F )
    F = struct('name',F);
  end
  if ~isstruct( F )
    F = struct( 'name' , F );
  end
  if ~isfield( F , 'bytes' )
    F(1).bytes = [];
  end
  
  try, DICOMparse(); end
  
  if numel(F) > 100,  vprintf = @(varargin)fprintf(varargin{:});
  else,               vprintf = @(varargin)false;
  end

  if isempty( bytes_to_read )
    bytes_to_read = 0;
    for v = 1:numel(varargin)
      switch varargin{v}
        case {'MediaStorageSOPInstanceUID'}, bytes_to_read = max(bytes_to_read, 256  );
        case {'ImplementationClassUID'},     bytes_to_read = max(bytes_to_read, 322  );
        case {'ImplementationVersionName'},  bytes_to_read = max(bytes_to_read, 344  );
        case {'InstanceCreationDate'},       bytes_to_read = max(bytes_to_read, 446  );
        case {'ImageType'},                  bytes_to_read = max(bytes_to_read, 448  );
        case {'InstanceCreationTime'},       bytes_to_read = max(bytes_to_read, 468  );
        case {'SOPInstanceUID'},             bytes_to_read = max(bytes_to_read, 566  );
        case {'StudyDate'},                  bytes_to_read = max(bytes_to_read, 582  );
        case {'SeriesDate'},                 bytes_to_read = max(bytes_to_read, 598  );
        case {'AcquisitionDate'},            bytes_to_read = max(bytes_to_read, 614  );
        case {'ContentDate'},                bytes_to_read = max(bytes_to_read, 630  );
        case {'StudyTime'},                  bytes_to_read = max(bytes_to_read, 652  );
        case {'SeriesTime'},                 bytes_to_read = max(bytes_to_read, 674  );
        case {'AcquisitionTime'},            bytes_to_read = max(bytes_to_read, 696  );
        case {'ContentTime'},                bytes_to_read = max(bytes_to_read, 718  );
        case {'StudyDescription'},           bytes_to_read = max(bytes_to_read, 888  );
        case {'SeriesDescription'},          bytes_to_read = max(bytes_to_read, 978  );
        case {'PatientBirthTime'},           bytes_to_read = max(bytes_to_read, 1540 );
        case {'rawPatientName'},             bytes_to_read = max(bytes_to_read, 1668 );
        case {'PatientName'},                bytes_to_read = max(bytes_to_read, 1668 );
        case {'PatientID'},                  bytes_to_read = max(bytes_to_read, 1686 );
        case {'PatientAge'},                 bytes_to_read = max(bytes_to_read, 1690 );
        case {'PatientBirthDate'},           bytes_to_read = max(bytes_to_read, 1694 );
        case {'PatientSize'},                bytes_to_read = max(bytes_to_read, 1702 );
        case {'PatientSex'},                 bytes_to_read = max(bytes_to_read, 1704 );
        case {'PatientWeight'},              bytes_to_read = max(bytes_to_read, 1722 );
        case {'NumberOfFrames'},             bytes_to_read = max(bytes_to_read, 1742 );
        case {'SequenceName'},               bytes_to_read = max(bytes_to_read, 1794 );
        case {'RepetitionTime'},             bytes_to_read = max(bytes_to_read, 1828 );
        case {'InversionTime'},              bytes_to_read = max(bytes_to_read, 1840 );
        case {'EchoTime'},                   bytes_to_read = max(bytes_to_read, 1842 );
        case {'Private_0019_100c'},          bytes_to_read = max(bytes_to_read, 1980 );
        case {'TriggerTime'},                bytes_to_read = max(bytes_to_read, 2086 );
        case {'PatientPosition'},            bytes_to_read = max(bytes_to_read, 2284 );
        case {'InversionTimes'},             bytes_to_read = max(bytes_to_read, 2564 );
        case {'ImageComments'},              bytes_to_read = max(bytes_to_read, 2882 );
        case {'StudyInstanceUID'},           bytes_to_read = max(bytes_to_read, 3414 );
        case {'SeriesInstanceUID'},          bytes_to_read = max(bytes_to_read, 3466 );
        case {'StudyID'},                    bytes_to_read = max(bytes_to_read, 3476 );
        case {'SeriesNumber'},               bytes_to_read = max(bytes_to_read, 3486 );
        case {'AcquisitionNumber'},          bytes_to_read = max(bytes_to_read, 3496 );
        case {'InstanceNumber'},             bytes_to_read = max(bytes_to_read, 3506 );
        case {'ImagePositionPatient'},       bytes_to_read = max(bytes_to_read, 3538 );
        case {'ImageOrientationPatient'},    bytes_to_read = max(bytes_to_read, 3686 );
        case {'SliceLocation'},              bytes_to_read = max(bytes_to_read, 3784 );
        case {'Rows'},                       bytes_to_read = max(bytes_to_read, 5310 );
        case {'Columns'},                    bytes_to_read = max(bytes_to_read, 5320 );
        case {'PixelSpacing'},               bytes_to_read = max(bytes_to_read, 5422 );
        case {'TriggerDelayTime'},           bytes_to_read = max(bytes_to_read, Inf );
        case {'TriggerTimeOffset'},          bytes_to_read = max(bytes_to_read, Inf );
        case {'CreationDate'},               bytes_to_read = max(bytes_to_read, Inf );
        case {'AcquisitionDateTime'},        bytes_to_read = max(bytes_to_read, Inf );
        case {'Date'},                       bytes_to_read = max(bytes_to_read, Inf );
        case {'Private_0019_100e'},          bytes_to_read = max(bytes_to_read, Inf );
        case {'Planes'},                     bytes_to_read = max(bytes_to_read, Inf );
        case {'CreationTime'},               bytes_to_read = max(bytes_to_read, Inf );
        case {'DateTime'},                   bytes_to_read = max(bytes_to_read, Inf );
        case {'Time'},                       bytes_to_read = max(bytes_to_read, Inf );
        otherwise,                           bytes_to_read = max(bytes_to_read, Inf );
      end
    end
    if bytes_to_read <= 0, bytes_to_read = Inf; end
  end
  returnLength = false;
  if bytes_to_read < 0
    returnLength = true;
    bytes_to_read = Inf;
  end
  wentToInf = 0;
  
  vprintf('%7d of %7d',0,numel(F));
  for f = [ numel(F) , 1:numel(F)-1 ]
    if ~rem(f,100), vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%7d of %7d',f,numel(F)); end
    if ~DICOMisdicom( F(f).name ), F(f).bytes = -1; continue; end
    if isempty( F(f).bytes ), F(f).bytes = 0; end

    if useDICOMINFO
      F = usingDICOMINFO( F , f , varargin );
      continue;
    end
    
    try
      for Bsz = [ bytes_to_read , Inf ]
        goToInf = false;

        if any( ~strcmp( varargin , 'Filename' ) )
          DINFO = DICOMparse( F(f) , Bsz ); if nargout > 1, P{f} = DINFO; end
          GROUP = [ DINFO.Group   ];
          ELEME = [ DINFO.Element ];
        end

        for v = 1:numel(varargin)
          atr = varargin{v}; F(f).(atr) = [];
          i = []; type = '';

          switch atr
            case 'Filename',          F(f).(atr) = F(f).name; i = 0; continue;
            case 'FileModDate',       error('to be implemented');
            case 'rawPatientName',                                               i = find( GROUP ==    16 & ELEME ==    16 ,1); type = 'CS';

            case 'PatientName',                                                  i = find( GROUP ==    16 & ELEME ==    16 ,1); type = 'PN';
            case 'SeriesInstanceUID',                                            i = find( GROUP ==    32 & ELEME ==    14 ,1); type = 'UI';
            case 'SOPInstanceUID',                                               i = find( GROUP ==     8 & ELEME ==    24 ,1); type = 'UI';
            case 'MediaStorageSOPInstanceUID',                                   i = find( GROUP ==     2 & ELEME ==     3 ,1); type = 'UI';
            case 'StudyInstanceUID',                                             i = find( GROUP ==    32 & ELEME ==    13 ,1); type = 'UI';
            case 'ImageOrientationPatient',                                      i = find( GROUP ==    32 & ELEME ==    55 ,1); type = 'DS';
            case 'ImagePositionPatient',                                         i = find( GROUP ==    32 & ELEME ==    50 ,1); type = 'DS';
            case 'SliceLocation',                                                i = find( GROUP ==    32 & ELEME ==  4161 ,1); type = 'DS';
            case 'TriggerTime',                                                  i = find( GROUP ==    24 & ELEME ==  4192 ,1); type = 'DSnan';
            case 'InstanceNumber',                                               i = find( GROUP ==    32 & ELEME ==    19 ,1); type = 'IS';
            case 'SeriesNumber',                                                 i = find( GROUP ==    32 & ELEME ==    17 ,1); type = 'IS';
            case 'AcquisitionNumber',                                            i = find( GROUP ==    32 & ELEME ==    18 ,1); type = 'IS';
            case 'PatientID',                                                    i = find( GROUP ==    16 & ELEME ==    32 ,1); type = 'LO';
            case 'SeriesDescription',                                            i = find( GROUP ==     8 & ELEME ==  4158 ,1); type = 'LO';
            case 'StudyDescription',                                             i = find( GROUP ==     8 & ELEME ==  4144 ,1); type = 'LO';
            case 'StudyID',                                                      i = find( GROUP ==    32 & ELEME ==    16 ,1); type = 'SH';
            case 'AcquisitionTime',                                              i = find( GROUP ==     8 & ELEME ==    50 ,1); type = 'TM';
            case 'NumberOfFrames',                                               i = find( GROUP ==    40 & ELEME ==     8 ,1); type = 'IS';
            case 'Rows',                                                         i = find( GROUP ==    40 & ELEME ==    16 ,1); type = 'US';
            case 'Columns',                                                      i = find( GROUP ==    40 & ELEME ==    17 ,1); type = 'US';
            case 'PatientPosition',                                              i = find( GROUP ==    24 & ELEME == 20736 ,1); type = 'CS';
            case 'Planes',                                                       i = find( GROUP ==    40 & ELEME ==    18 ,1); type = 'US';
            case 'PatientAge',                                                   i = find( GROUP ==    16 & ELEME ==  4112 ,1); type = 'AS';
            case 'PatientSize',                                                  i = find( GROUP ==    16 & ELEME ==  4128 ,1); type = 'DS';
            case 'PatientWeight',                                                i = find( GROUP ==    16 & ELEME ==  4144 ,1); type = 'DS';
            case 'PixelSpacing',                                                 i = find( GROUP ==    40 & ELEME ==    48 ,1); type = 'DS';
            case 'ImageType',                                                    i = find( GROUP ==     8 & ELEME ==     8 ,1); type = 'CS';
            case 'SequenceName',                                                 i = find( GROUP ==    24 & ELEME ==    36 ,1); type = 'SH';
            case 'ImageComments',                                                i = find( GROUP ==    32 & ELEME == 16384 ,1); type = 'LT';
            case 'ImplementationClassUID',                                       i = find( GROUP ==     2 & ELEME ==    18 ,1); type = 'UI';
            case 'ImplementationVersionName',                                    i = find( GROUP ==     2 & ELEME ==    19 ,1); type = 'SH';
            case 'TriggerDelayTime',                                             i = find( GROUP ==    32 & ELEME == 37203 ,1); type = 'FD';
            case 'InversionTimes',                                               i = find( GROUP ==    24 & ELEME == 36985 ,1); type = 'FD';
            case 'TriggerTimeOffset',                                            i = find( GROUP ==    24 & ELEME ==  4201 ,1); type = 'DS';
            case 'InstanceCreationDate',                                         i = find( GROUP ==     8 & ELEME ==    18 ,1); type = 'DA';
            case 'InstanceCreationTime',                                         i = find( GROUP ==     8 & ELEME ==    19 ,1); type = 'TM';
            case 'StudyDate',                                                    i = find( GROUP ==     8 & ELEME ==    32 ,1); type = 'DA';
            case 'SeriesDate',                                                   i = find( GROUP ==     8 & ELEME ==    33 ,1); type = 'DA';
            case 'AcquisitionDate',                                              i = find( GROUP ==     8 & ELEME ==    34 ,1); type = 'DA';
            case 'ContentDate',                                                  i = find( GROUP ==     8 & ELEME ==    35 ,1); type = 'DA';
            case 'AcquisitionDateTime',                                          i = find( GROUP ==     8 & ELEME ==    42 ,1); type = 'DT';
            case 'StudyTime',                                                    i = find( GROUP ==     8 & ELEME ==    48 ,1); type = 'TM';
            case 'SeriesTime',                                                   i = find( GROUP ==     8 & ELEME ==    49 ,1); type = 'TM';
            case 'ContentTime',                                                  i = find( GROUP ==     8 & ELEME ==    51 ,1); type = 'TM';
            case 'PatientBirthDate',                                             i = find( GROUP ==    16 & ELEME ==    48 ,1); type = 'DA';
            case 'PatientBirthTime',                                             i = find( GROUP ==    16 & ELEME ==    50 ,1); type = 'TM';
            case 'PatientSex',                                                   i = find( GROUP ==    16 & ELEME ==    64 ,1); type = 'CS';
            case 'DateTime',                                                     i = find( GROUP ==    64 & ELEME == 41248 ,1); type = 'DT';
            case 'Date',                                                         i = find( GROUP ==    64 & ELEME == 41249 ,1); type = 'DA';
            case 'Time',                                                         i = find( GROUP ==    64 & ELEME == 41250 ,1); type = 'TM';
            case 'CreationDate',                                                 i = find( GROUP ==  8448 & ELEME ==    64 ,1); type = 'DA';
            case 'CreationTime',                                                 i = find( GROUP ==  8448 & ELEME ==    80 ,1); type = 'TM';
            case 'RepetitionTime',                                               i = find( GROUP ==    24 & ELEME ==   128 ,1); type = 'DS';
            case 'EchoTime',                                                     i = find( GROUP ==    24 & ELEME ==   129 ,1); type = 'DS';
            case 'InversionTime',                                                i = find( GROUP ==    24 & ELEME ==   130 ,1); type = 'DS';

            case 'Private_0019_100c',                                           %i = find( GROUP == hex2dec('0019') & ELEME == hex2dec('100c') ,1);
              i = find( GROUP ==              25 & ELEME ==            4108 ,1);
            case 'Private_0019_100e',                                           %i = find( GROUP == hex2dec('0019') & ELEME == hex2dec('100e') ,1);
              i = find( GROUP ==              58 & ELEME ==            4110 ,1);

            otherwise
              warning('Unknown attribute. Switching to useDICOMINFO option.\n');
              useDICOMINFO = true;
              F = usingDICOMINFO( F , f , varargin );
              continue;
          end

          if isempty(i) && ~isinf( Bsz )
%             vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
%             fprintf(2,'di=dicominfo(''%s'');di.%s\n',F(f).name,atr);
%             vprintf('%7d of %7d',f,numel(F));
            wentToInf = wentToInf + 1;
            goToInf = true; break; end
          
          if returnLength
            if isempty(i)
              F(f).(atr) = NaN;
              continue;
            end
            F(f).(atr) = DINFO(i).Location + DINFO(i).Length;
            continue
          end

          if isempty(type) && ~isempty(i),  type = DINFO(i).VR; end
          if isempty(type),                 type = 'UN';        end
          if isempty(i) && isempty( type ), continue;           end

          if isempty(i)
            switch type
              case {'FD'}
                F(f).(atr) = [];
              case {'AE','AS','CS','DA','DT','LO','LT','SH','ST','TM','UI','UT','PN'}
                F(f).(atr) = '';
              case {'DS','IS'}
                F(f).(atr) = [];
              case {'DSnan'}
                F(f).(atr) = NaN;
              case {'UN'}
                F(f).(atr) = [];
              case {'US'}
                F(f).(atr) = [];
              otherwise
                error('unknown type');
            end
            continue;
          end

          switch type
            case {'FD'}
              F(f).(atr) = typecast( DINFO(i).Data , 'double' );
            case {'AE','AS','CS','DA','DT','LO','LT','SH','ST','TM','UI','UT'}
              F(f).(atr) = deblank( char( DINFO(i).Data( ~~DINFO(i).Data ) ) );
            case {'DS','IS','DSnan'}
              F(f).(atr) = sscanf( char( DINFO(i).Data ) , '%f\\');
            case {'PN'}
              personName = parsePerson( deblank( char( DINFO(i).Data( ~~DINFO(i).Data ) ) ) );
              F(f).(atr) = personName.FamilyName;
            case {'US'}
              F(f).(atr) = typecast( DINFO(i).Data(:) , 'uint16' );
            case {'UN'}
              F(f).(atr) = DINFO(i).Data;
            otherwise
              error('unknown type');
          end
        end
        if goToInf, continue; end; break;
      end
    catch LE
      error('Some error reading attribute');
      warning('Some error reading attribute. Switching to useDICOMINFO option.\n');
      useDICOMINFO = true;
      F = usingDICOMINFO( F , f , varargin );
      continue;
    end
  end
  vprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
  
  %some fixings
  w = cellfun('isempty',{F.bytes}); [ F(w).bytes ] = deal(-1);
  isd = [F.bytes] >= 0;
  try, w = isd & cellfun('isempty',{F.StudyID                  }); [ F(w).StudyID                 ] = deal( 0 ); end
  try, w = isd & cellfun('isempty',{F.SeriesNumber             }); [ F(w).SeriesNumber            ] = deal( 0 ); end
  try, w = isd & cellfun('isempty',{F.InstanceNumber           }); [ F(w).InstanceNumber          ] = deal( 0 ); end
  try, w = isd & cellfun('isempty',{F.AcquisitionNumber        }); [ F(w).AcquisitionNumber       ] = deal( 0 ); end
  try, w = isd & cellfun('isempty',{F.Rows                     }); [ F(w).Rows                    ] = deal( 0 ); end
  try, w = isd & cellfun('isempty',{F.Columns                  }); [ F(w).Columns                 ] = deal( 0 ); end
  try, w = isd & cellfun('isempty',{F.PixelSpacing             }); [ F(w).PixelSpacing            ] = deal(NaN(2,1)); end
  try, w = isd & cellfun('isempty',{F.ImageOrientationPatient  }); [ F(w).ImageOrientationPatient ] = deal(NaN(6,1)); end
  try, w = isd & cellfun('isempty',{F.ImagePositionPatient     }); [ F(w).ImagePositionPatient    ] = deal(NaN(3,1)); end
  try, w = isd & cellfun('isempty',{F.SliceLocation            }); [ F(w).SliceLocation           ] = deal(NaN); end
  try, w = isd & cellfun('isempty',{F.TriggerTime              }); [ F(w).TriggerTime             ] = deal(NaN); end
  
  %wentToInf
end

function F = usingDICOMINFO( F , f , varargin )
  if any( ~strcmp( varargin , 'Filename' ) )
    DINFO = dicominfo( F(f).name );
  end
  for v = 1:numel(varargin)
    atr = varargin{v};
    F(f).(atr) = [];
    switch atr
      case 'Filename',    F(f).(atr) = F(f).name;
      case 'TriggerTime', F(f).(atr) = NaN; try, F(f).(atr) = DINFO.(atr); end
      case 'PatientName', F(f).(atr) = '';  try, F(f).(atr) = DINFO.PatientName.FamilyName; end
      otherwise, try, F(f).(atr) = DINFO.(atr); end
    end
  end
end

function personName = parsePerson(personString)
%PARSEPERSON  Get the various parts of a person name
% A description and examples of PN values is in PS 3.5-2000 Table 6.2-1.
  pnParts = {'FamilyName'
    'GivenName'
    'MiddleName'
    'NamePrefix'
    'NameSuffix'};
  if (isempty(personString))
    personName   = struct('FamilyName','','GivenName','','MiddleName','','NamePrefix','','NameSuffix','');
    return
  end
  people = tokenize(personString, '\\');  % Must quote '\' for calls to STRREAD.
  personName = struct([]);
  for p = 1:length(people)
    % ASCII, ideographic, and phonetic characters are separated by '='.
    components = tokenize(people{p}, '=');
    if (isempty(components))
      personName = makePerson(pnParts);
      return
    end
    % Only use ASCII parts.
    if (~isempty(components{1}))
      % Get the separate parts of the person's name from the component.
      componentParts = tokenize(components{1}, '^');
      % The DICOM standard requires that PN values have five or fewer
      % values separated by "^".  Some vendors produce files with more
      % than these person name parts.
      if (numel(componentParts) <= 5)
        % If there are the correct numbers, put them in separate fields.
        for q = 1:length(componentParts)
          personName(p).(pnParts{q}) = componentParts{q};
        end
      else
        % If there are more, just return the whole string.
        personName(p).FamilyName = people{p};
      end
    else
      % Use full string as value if no ASCII is present.
      if (~isempty(components))
        personName(p).FamilyName = people{p};
      end
    end
  end
end
function tokens = tokenize( input_string, delimiters )
  if (~isempty(input_string))
    tokens = strread(input_string,'%s',-1,'delimiter',delimiters);
  else
    tokens = {};
  end
end

%{

if 0
  clc
  DDICT = load('dicom-dict.mat');
  for t = 1:numel( DDICT.values )
%     if ~isequal( DDICT.values(t).VM , [1 1] ), continue; end
    [id(1),id(2)] = find( DDICT.tags == t ); id = id-1;
    try,fprintf( '            case ''%s'', %si = find( GROUP == %5d & ELEME == %5d ,1); type = ''%s'';\n' , DDICT.values(t).Name , blanks( 60 - numel(DDICT.values(t).Name) ) , id , DDICT.values(t).VR );end
  end
end


            case 'GroupLength',                                                  i = find( GROUP ==     0 & ELEME ==     0 ,1); type = 'UL';
            case 'CommandGroupLengthToEnd',                                      i = find( GROUP ==     0 & ELEME ==     1 ,1); type = 'UL';
            case 'AffectedSOPClassUID',                                          i = find( GROUP ==     0 & ELEME ==     2 ,1); type = 'UI';
            case 'RequestedSOPClassUID',                                         i = find( GROUP ==     0 & ELEME ==     3 ,1); type = 'UI';
            case 'CommandRecognitionCode',                                       i = find( GROUP ==     0 & ELEME ==    16 ,1); type = 'CS';
            case 'CommandField',                                                 i = find( GROUP ==     0 & ELEME ==   256 ,1); type = 'US';
            case 'MessageID',                                                    i = find( GROUP ==     0 & ELEME ==   272 ,1); type = 'US';
            case 'MessageIDBeingRespondedTo',                                    i = find( GROUP ==     0 & ELEME ==   288 ,1); type = 'US';
            case 'Initiator',                                                    i = find( GROUP ==     0 & ELEME ==   512 ,1); type = 'AE';
            case 'Receiver',                                                     i = find( GROUP ==     0 & ELEME ==   768 ,1); type = 'AE';
            case 'FindLocation',                                                 i = find( GROUP ==     0 & ELEME ==  1024 ,1); type = 'AE';
            case 'MoveDestination',                                              i = find( GROUP ==     0 & ELEME ==  1536 ,1); type = 'AE';
            case 'Priority',                                                     i = find( GROUP ==     0 & ELEME ==  1792 ,1); type = 'US';
            case 'DataSetType',                                                  i = find( GROUP ==     0 & ELEME ==  2048 ,1); type = 'US';
            case 'NumberOfMatches',                                              i = find( GROUP ==     0 & ELEME ==  2128 ,1); type = 'US';
            case 'ResponseSequenceNumber',                                       i = find( GROUP ==     0 & ELEME ==  2144 ,1); type = 'US';
            case 'Status',                                                       i = find( GROUP ==     0 & ELEME ==  2304 ,1); type = 'US';
            case 'OffendingElement',                                             i = find( GROUP ==     0 & ELEME ==  2305 ,1); type = 'AT';
            case 'ErrorComment',                                                 i = find( GROUP ==     0 & ELEME ==  2306 ,1); type = 'LO';
            case 'ErrorID',                                                      i = find( GROUP ==     0 & ELEME ==  2307 ,1); type = 'US';
            case 'AffectedSOPInstanceUID',                                       i = find( GROUP ==     0 & ELEME ==  4096 ,1); type = 'UI';
            case 'RequestedSOPInstanceUID',                                      i = find( GROUP ==     0 & ELEME ==  4097 ,1); type = 'UI';
            case 'EventTypeID',                                                  i = find( GROUP ==     0 & ELEME ==  4098 ,1); type = 'US';
            case 'AttributeIdentifierList',                                      i = find( GROUP ==     0 & ELEME ==  4101 ,1); type = 'AT';
            case 'ActionTypeID',                                                 i = find( GROUP ==     0 & ELEME ==  4104 ,1); type = 'US';
            case 'NumberOfRemainingSuboperations',                               i = find( GROUP ==     0 & ELEME ==  4128 ,1); type = 'US';
            case 'NumberOfCompletedSuboperations',                               i = find( GROUP ==     0 & ELEME ==  4129 ,1); type = 'US';
            case 'NumberOfFailedSuboperations',                                  i = find( GROUP ==     0 & ELEME ==  4130 ,1); type = 'US';
            case 'NumberOfWarningSuboperations',                                 i = find( GROUP ==     0 & ELEME ==  4131 ,1); type = 'US';
            case 'MoveOriginatorApplicationEntityTitle',                         i = find( GROUP ==     0 & ELEME ==  4144 ,1); type = 'AE';
            case 'MoveOriginatorMessageID',                                      i = find( GROUP ==     0 & ELEME ==  4145 ,1); type = 'US';
            case 'DialogReceiver',                                               i = find( GROUP ==     0 & ELEME == 16384 ,1); type = 'AT';
            case 'TerminalType',                                                 i = find( GROUP ==     0 & ELEME == 16400 ,1); type = 'AT';
            case 'MessageSetID',                                                 i = find( GROUP ==     0 & ELEME == 20496 ,1); type = 'SH';
            case 'EndMessageSet',                                                i = find( GROUP ==     0 & ELEME == 20512 ,1); type = 'SH';
            case 'DisplayFormat',                                                i = find( GROUP ==     0 & ELEME == 20752 ,1); type = 'AT';
            case 'PagePositionID',                                               i = find( GROUP ==     0 & ELEME == 20768 ,1); type = 'AT';
            case 'TextFormatID',                                                 i = find( GROUP ==     0 & ELEME == 20784 ,1); type = 'CS';
            case 'NormalReverse',                                                i = find( GROUP ==     0 & ELEME == 20800 ,1); type = 'CS';
            case 'AddGrayScale',                                                 i = find( GROUP ==     0 & ELEME == 20816 ,1); type = 'CS';
            case 'Borders',                                                      i = find( GROUP ==     0 & ELEME == 20832 ,1); type = 'CS';
            case 'Copies',                                                       i = find( GROUP ==     0 & ELEME == 20848 ,1); type = 'IS';
            case 'OldMagnificationType',                                         i = find( GROUP ==     0 & ELEME == 20864 ,1); type = 'CS';
            case 'Erase',                                                        i = find( GROUP ==     0 & ELEME == 20880 ,1); type = 'CS';
            case 'Print',                                                        i = find( GROUP ==     0 & ELEME == 20896 ,1); type = 'CS';
            case 'Overlays',                                                     i = find( GROUP ==     0 & ELEME == 20912 ,1); type = 'US';
            case 'FileMetaInformationGroupLength',                               i = find( GROUP ==     2 & ELEME ==     0 ,1); type = 'UL';
            case 'FileMetaInformationVersion',                                   i = find( GROUP ==     2 & ELEME ==     1 ,1); type = 'OB';
            case 'MediaStorageSOPClassUID',                                      i = find( GROUP ==     2 & ELEME ==     2 ,1); type = 'UI';
            case 'MediaStorageSOPInstanceUID',                                   i = find( GROUP ==     2 & ELEME ==     3 ,1); type = 'UI';
            case 'TransferSyntaxUID',                                            i = find( GROUP ==     2 & ELEME ==    16 ,1); type = 'UI';
            case 'ImplementationClassUID',                                       i = find( GROUP ==     2 & ELEME ==    18 ,1); type = 'UI';
            case 'ImplementationVersionName',                                    i = find( GROUP ==     2 & ELEME ==    19 ,1); type = 'SH';
            case 'SourceApplicationEntityTitle',                                 i = find( GROUP ==     2 & ELEME ==    22 ,1); type = 'AE';
            case 'PrivateInformationCreatorUID',                                 i = find( GROUP ==     2 & ELEME ==   256 ,1); type = 'UI';
            case 'PrivateInformation',                                           i = find( GROUP ==     2 & ELEME ==   258 ,1); type = 'OB';
            case 'FileSetGroupLength',                                           i = find( GROUP ==     4 & ELEME ==     0 ,1); type = 'UL';
            case 'FileSetID',                                                    i = find( GROUP ==     4 & ELEME ==  4400 ,1); type = 'CS';
            case 'FileSetDescriptorFileID',                                      i = find( GROUP ==     4 & ELEME ==  4417 ,1); type = 'CS';
            case 'FileSetCharacterSet',                                          i = find( GROUP ==     4 & ELEME ==  4418 ,1); type = 'CS';
            case 'RootDirectoryFirstRecord',                                     i = find( GROUP ==     4 & ELEME ==  4608 ,1); type = 'UL';
            case 'RootDirectoryLastRecord',                                      i = find( GROUP ==     4 & ELEME ==  4610 ,1); type = 'UL';
            case 'FileSetConsistencyFlag',                                       i = find( GROUP ==     4 & ELEME ==  4626 ,1); type = 'US';
            case 'DirectoryRecordSequence',                                      i = find( GROUP ==     4 & ELEME ==  4640 ,1); type = 'SQ';
            case 'NextDirectoryRecordOffset',                                    i = find( GROUP ==     4 & ELEME ==  5120 ,1); type = 'UL';
            case 'RecordInUseFlag',                                              i = find( GROUP ==     4 & ELEME ==  5136 ,1); type = 'US';
            case 'LowerLevelDirectoryOffset',                                    i = find( GROUP ==     4 & ELEME ==  5152 ,1); type = 'UL';
            case 'DirectoryRecordType',                                          i = find( GROUP ==     4 & ELEME ==  5168 ,1); type = 'CS';
            case 'PrivateRecordUID',                                             i = find( GROUP ==     4 & ELEME ==  5170 ,1); type = 'UI';
            case 'ReferencedFileID',                                             i = find( GROUP ==     4 & ELEME ==  5376 ,1); type = 'CS';
            case 'MRDRDirectoryRecordOffset',                                    i = find( GROUP ==     4 & ELEME ==  5380 ,1); type = 'UL';
            case 'ReferencedSOPClassUIDInFile',                                  i = find( GROUP ==     4 & ELEME ==  5392 ,1); type = 'UI';
            case 'ReferencedSOPInstanceUIDInFile',                               i = find( GROUP ==     4 & ELEME ==  5393 ,1); type = 'UI';
            case 'ReferencedTransferSyntaxUIDInFile',                            i = find( GROUP ==     4 & ELEME ==  5394 ,1); type = 'UI';
            case 'NumberOfReferences',                                           i = find( GROUP ==     4 & ELEME ==  5632 ,1); type = 'UL';
            case 'IdentifyingGroupLength',                                       i = find( GROUP ==     8 & ELEME ==     0 ,1); type = 'UL';
            case 'IdentifyingGroupLengthToEnd',                                  i = find( GROUP ==     8 & ELEME ==     1 ,1); type = 'UL';
            case 'SpecificCharacterSet',                                         i = find( GROUP ==     8 & ELEME ==     5 ,1); type = 'CS';
            case 'ImageType',                                                    i = find( GROUP ==     8 & ELEME ==     8 ,1); type = 'CS';
            case 'RecognitionCode',                                              i = find( GROUP ==     8 & ELEME ==    16 ,1); type = 'CS';
            case 'InstanceCreationDate',                                         i = find( GROUP ==     8 & ELEME ==    18 ,1); type = 'DA';
            case 'InstanceCreationTime',                                         i = find( GROUP ==     8 & ELEME ==    19 ,1); type = 'TM';
            case 'InstanceCreatorUID',                                           i = find( GROUP ==     8 & ELEME ==    20 ,1); type = 'UI';
            case 'SOPClassUID',                                                  i = find( GROUP ==     8 & ELEME ==    22 ,1); type = 'UI';
            case 'StudyDate',                                                    i = find( GROUP ==     8 & ELEME ==    32 ,1); type = 'DA';
            case 'SeriesDate',                                                   i = find( GROUP ==     8 & ELEME ==    33 ,1); type = 'DA';
            case 'AcquisitionDate',                                              i = find( GROUP ==     8 & ELEME ==    34 ,1); type = 'DA';
            case 'ContentDate',                                                  i = find( GROUP ==     8 & ELEME ==    35 ,1); type = 'DA';
            case 'OverlayDate',                                                  i = find( GROUP ==     8 & ELEME ==    36 ,1); type = 'DA';
            case 'CurveDate',                                                    i = find( GROUP ==     8 & ELEME ==    37 ,1); type = 'DA';
            case 'AcquisitionDateTime',                                          i = find( GROUP ==     8 & ELEME ==    42 ,1); type = 'DT';
            case 'StudyTime',                                                    i = find( GROUP ==     8 & ELEME ==    48 ,1); type = 'TM';
            case 'SeriesTime',                                                   i = find( GROUP ==     8 & ELEME ==    49 ,1); type = 'TM';
            case 'AcquisitionTime',                                              i = find( GROUP ==     8 & ELEME ==    50 ,1); type = 'TM';
            case 'ContentTime',                                                  i = find( GROUP ==     8 & ELEME ==    51 ,1); type = 'TM';
            case 'OverlayTime',                                                  i = find( GROUP ==     8 & ELEME ==    52 ,1); type = 'TM';
            case 'CurveTime',                                                    i = find( GROUP ==     8 & ELEME ==    53 ,1); type = 'TM';
            case 'OldDataSetType',                                               i = find( GROUP ==     8 & ELEME ==    64 ,1); type = 'US';
            case 'DataSetSubtype',                                               i = find( GROUP ==     8 & ELEME ==    65 ,1); type = 'LT';
            case 'NuclearMedicineSeriesType',                                    i = find( GROUP ==     8 & ELEME ==    66 ,1); type = 'CS';
            case 'AccessionNumber',                                              i = find( GROUP ==     8 & ELEME ==    80 ,1); type = 'SH';
            case 'QueryRetrieveLevel',                                           i = find( GROUP ==     8 & ELEME ==    82 ,1); type = 'CS';
            case 'RetrieveAETitle',                                              i = find( GROUP ==     8 & ELEME ==    84 ,1); type = 'AE';
            case 'InstanceAvailability',                                         i = find( GROUP ==     8 & ELEME ==    86 ,1); type = 'CS';
            case 'FailedSOPInstanceUIDList',                                     i = find( GROUP ==     8 & ELEME ==    88 ,1); type = 'UI';
            case 'Modality',                                                     i = find( GROUP ==     8 & ELEME ==    96 ,1); type = 'CS';
            case 'ModalitiesInStudy',                                            i = find( GROUP ==     8 & ELEME ==    97 ,1); type = 'CS';
            case 'SOPClassesInStudy',                                            i = find( GROUP ==     8 & ELEME ==    98 ,1); type = 'UI';
            case 'ConversionType',                                               i = find( GROUP ==     8 & ELEME ==   100 ,1); type = 'CS';
            case 'PresentationIntentType',                                       i = find( GROUP ==     8 & ELEME ==   104 ,1); type = 'CS';
            case 'Manufacturer',                                                 i = find( GROUP ==     8 & ELEME ==   112 ,1); type = 'LO';
            case 'InstitutionName',                                              i = find( GROUP ==     8 & ELEME ==   128 ,1); type = 'LO';
            case 'InstitutionAddress',                                           i = find( GROUP ==     8 & ELEME ==   129 ,1); type = 'ST';
            case 'InstitutionCodeSequence',                                      i = find( GROUP ==     8 & ELEME ==   130 ,1); type = 'SQ';
            case 'ReferringPhysicianName',                                       i = find( GROUP ==     8 & ELEME ==   144 ,1); type = 'PN';
            case 'ReferringPhysicianAddress',                                    i = find( GROUP ==     8 & ELEME ==   146 ,1); type = 'ST';
            case 'ReferringPhysicianTelephoneNumber',                            i = find( GROUP ==     8 & ELEME ==   148 ,1); type = 'SH';
            case 'ReferringPhysicianIdentificationSequence',                     i = find( GROUP ==     8 & ELEME ==   150 ,1); type = 'SQ';
            case 'CodeValue',                                                    i = find( GROUP ==     8 & ELEME ==   256 ,1); type = 'SH';
            case 'CodingSchemeDesignator',                                       i = find( GROUP ==     8 & ELEME ==   258 ,1); type = 'SH';
            case 'CodingSchemeVersion',                                          i = find( GROUP ==     8 & ELEME ==   259 ,1); type = 'SH';
            case 'CodeMeaning',                                                  i = find( GROUP ==     8 & ELEME ==   260 ,1); type = 'LO';
            case 'MappingResource',                                              i = find( GROUP ==     8 & ELEME ==   261 ,1); type = 'CS';
            case 'ContextGroupVersion',                                          i = find( GROUP ==     8 & ELEME ==   262 ,1); type = 'DT';
            case 'ContextGroupLocalVersion',                                     i = find( GROUP ==     8 & ELEME ==   263 ,1); type = 'DT';
            case 'ContextGroupExtensionFlag',                                    i = find( GROUP ==     8 & ELEME ==   267 ,1); type = 'CS';
            case 'CodingSchemeUID',                                              i = find( GROUP ==     8 & ELEME ==   268 ,1); type = 'UI';
            case 'ContextGroupExtensionCreatorUID',                              i = find( GROUP ==     8 & ELEME ==   269 ,1); type = 'UI';
            case 'ContextIdentifier',                                            i = find( GROUP ==     8 & ELEME ==   271 ,1); type = 'CS';
            case 'CodingSchemeIdentificationSequence',                           i = find( GROUP ==     8 & ELEME ==   272 ,1); type = 'SQ';
            case 'CodingSchemeRegistry',                                         i = find( GROUP ==     8 & ELEME ==   274 ,1); type = 'LO';
            case 'CodingSchemeExternalID',                                       i = find( GROUP ==     8 & ELEME ==   276 ,1); type = 'ST';
            case 'CodingSchemeName',                                             i = find( GROUP ==     8 & ELEME ==   277 ,1); type = 'ST';
            case 'ResponsibleOrganization',                                      i = find( GROUP ==     8 & ELEME ==   278 ,1); type = 'ST';
            case 'TimezoneOffsetFromUTC',                                        i = find( GROUP ==     8 & ELEME ==   513 ,1); type = 'SH';
            case 'NetworkID',                                                    i = find( GROUP ==     8 & ELEME ==  4096 ,1); type = 'AE';
            case 'StationName',                                                  i = find( GROUP ==     8 & ELEME ==  4112 ,1); type = 'SH';
            case 'StudyDescription',                                             i = find( GROUP ==     8 & ELEME ==  4144 ,1); type = 'LO';
            case 'ProcedureCodeSequence',                                        i = find( GROUP ==     8 & ELEME ==  4146 ,1); type = 'SQ';
            case 'SeriesDescription',                                            i = find( GROUP ==     8 & ELEME ==  4158 ,1); type = 'LO';
            case 'InstitutionalDepartmentName',                                  i = find( GROUP ==     8 & ELEME ==  4160 ,1); type = 'LO';
            case 'PhysicianOfRecord',                                            i = find( GROUP ==     8 & ELEME ==  4168 ,1); type = 'PN';
            case 'PhysicianOfRecordIdentificationSequence',                      i = find( GROUP ==     8 & ELEME ==  4169 ,1); type = 'SQ';
            case 'PerformingPhysicianName',                                      i = find( GROUP ==     8 & ELEME ==  4176 ,1); type = 'PN';
            case 'PerformingPhysicianIdentificationSequence',                    i = find( GROUP ==     8 & ELEME ==  4178 ,1); type = 'SQ';
            case 'PhysicianReadingStudy',                                        i = find( GROUP ==     8 & ELEME ==  4192 ,1); type = 'PN';
            case 'PhysicianReadingStudyIdentificationSequence',                  i = find( GROUP ==     8 & ELEME ==  4194 ,1); type = 'SQ';
            case 'OperatorName',                                                 i = find( GROUP ==     8 & ELEME ==  4208 ,1); type = 'PN';
            case 'OperatorIdentificationSequence',                               i = find( GROUP ==     8 & ELEME ==  4210 ,1); type = 'SQ';
            case 'AdmittingDiagnosesDescription',                                i = find( GROUP ==     8 & ELEME ==  4224 ,1); type = 'LO';
            case 'AdmittingDiagnosesCodeSequence',                               i = find( GROUP ==     8 & ELEME ==  4228 ,1); type = 'SQ';
            case 'ManufacturerModelName',                                        i = find( GROUP ==     8 & ELEME ==  4240 ,1); type = 'LO';
            case 'ReferencedResultsSequence',                                    i = find( GROUP ==     8 & ELEME ==  4352 ,1); type = 'SQ';
            case 'ReferencedStudySequence',                                      i = find( GROUP ==     8 & ELEME ==  4368 ,1); type = 'SQ';
            case 'ReferencedPerformedProcedureStepSequence',                     i = find( GROUP ==     8 & ELEME ==  4369 ,1); type = 'SQ';
            case 'ReferencedSeriesSequence',                                     i = find( GROUP ==     8 & ELEME ==  4373 ,1); type = 'SQ';
            case 'ReferencedPatientSequence',                                    i = find( GROUP ==     8 & ELEME ==  4384 ,1); type = 'SQ';
            case 'ReferencedVisitSequence',                                      i = find( GROUP ==     8 & ELEME ==  4389 ,1); type = 'SQ';
            case 'ReferencedOverlaySequence',                                    i = find( GROUP ==     8 & ELEME ==  4400 ,1); type = 'SQ';
            case 'ReferencedWaveformSequence',                                   i = find( GROUP ==     8 & ELEME ==  4410 ,1); type = 'SQ';
            case 'ReferencedImageSequence',                                      i = find( GROUP ==     8 & ELEME ==  4416 ,1); type = 'SQ';
            case 'ReferencedCurveSequence',                                      i = find( GROUP ==     8 & ELEME ==  4421 ,1); type = 'SQ';
            case 'ReferencedInstanceSequence',                                   i = find( GROUP ==     8 & ELEME ==  4426 ,1); type = 'SQ';
            case 'ReferencedSOPClassUID',                                        i = find( GROUP ==     8 & ELEME ==  4432 ,1); type = 'UI';
            case 'ReferencedSOPInstanceUID',                                     i = find( GROUP ==     8 & ELEME ==  4437 ,1); type = 'UI';
            case 'SOPClassesSupported',                                          i = find( GROUP ==     8 & ELEME ==  4442 ,1); type = 'UI';
            case 'ReferencedFrameNumber',                                        i = find( GROUP ==     8 & ELEME ==  4448 ,1); type = 'IS';
            case 'TransactionUID',                                               i = find( GROUP ==     8 & ELEME ==  4501 ,1); type = 'UI';
            case 'FailureReason',                                                i = find( GROUP ==     8 & ELEME ==  4503 ,1); type = 'US';
            case 'FailedSOPSequence',                                            i = find( GROUP ==     8 & ELEME ==  4504 ,1); type = 'SQ';
            case 'ReferencedSOPSequence',                                        i = find( GROUP ==     8 & ELEME ==  4505 ,1); type = 'SQ';
            case 'StudiesContainingOtherReferencedInstancesSequence',            i = find( GROUP ==     8 & ELEME ==  4608 ,1); type = 'SQ';
            case 'LossyImageCompression',                                        i = find( GROUP ==     8 & ELEME ==  8464 ,1); type = 'CS';
            case 'DerivationDescription',                                        i = find( GROUP ==     8 & ELEME ==  8465 ,1); type = 'ST';
            case 'SourceImageSequence',                                          i = find( GROUP ==     8 & ELEME ==  8466 ,1); type = 'SQ';
            case 'StageName',                                                    i = find( GROUP ==     8 & ELEME ==  8480 ,1); type = 'SH';
            case 'StageNumber',                                                  i = find( GROUP ==     8 & ELEME ==  8482 ,1); type = 'IS';
            case 'NumberOfStages',                                               i = find( GROUP ==     8 & ELEME ==  8484 ,1); type = 'IS';
            case 'ViewName',                                                     i = find( GROUP ==     8 & ELEME ==  8487 ,1); type = 'SH';
            case 'ViewNumber',                                                   i = find( GROUP ==     8 & ELEME ==  8488 ,1); type = 'IS';
            case 'NumberOfEventTimers',                                          i = find( GROUP ==     8 & ELEME ==  8489 ,1); type = 'IS';
            case 'NumberOfViewsInStage',                                         i = find( GROUP ==     8 & ELEME ==  8490 ,1); type = 'IS';
            case 'EventElapsedTime',                                             i = find( GROUP ==     8 & ELEME ==  8496 ,1); type = 'DS';
            case 'EventTimerName',                                               i = find( GROUP ==     8 & ELEME ==  8498 ,1); type = 'LO';
            case 'StartTrim',                                                    i = find( GROUP ==     8 & ELEME ==  8514 ,1); type = 'IS';
            case 'StopTrim',                                                     i = find( GROUP ==     8 & ELEME ==  8515 ,1); type = 'IS';
            case 'RecommendedDisplayFrameRate',                                  i = find( GROUP ==     8 & ELEME ==  8516 ,1); type = 'IS';
            case 'TransducerPosition',                                           i = find( GROUP ==     8 & ELEME ==  8704 ,1); type = 'CS';
            case 'TransducerOrientation',                                        i = find( GROUP ==     8 & ELEME ==  8708 ,1); type = 'CS';
            case 'AnatomicStructure',                                            i = find( GROUP ==     8 & ELEME ==  8712 ,1); type = 'CS';
            case 'AnatomicRegionSequence',                                       i = find( GROUP ==     8 & ELEME ==  8728 ,1); type = 'SQ';
            case 'AnatomicRegionModifierSequence',                               i = find( GROUP ==     8 & ELEME ==  8736 ,1); type = 'SQ';
            case 'PrimaryAnatomicStructureSequence',                             i = find( GROUP ==     8 & ELEME ==  8744 ,1); type = 'SQ';
            case 'AnatomicStructureSpaceOrRegionSequence',                       i = find( GROUP ==     8 & ELEME ==  8745 ,1); type = 'SQ';
            case 'PrimaryAnatomicStructureModifierSequence',                     i = find( GROUP ==     8 & ELEME ==  8752 ,1); type = 'SQ';
            case 'TransducerPositionSequence',                                   i = find( GROUP ==     8 & ELEME ==  8768 ,1); type = 'SQ';
            case 'TransducerPositionModifierSequence',                           i = find( GROUP ==     8 & ELEME ==  8770 ,1); type = 'SQ';
            case 'TransducerOrientationSequence',                                i = find( GROUP ==     8 & ELEME ==  8772 ,1); type = 'SQ';
            case 'TransducerOrientationModifierSequence',                        i = find( GROUP ==     8 & ELEME ==  8774 ,1); type = 'SQ';
            case 'AnatomicStructureSpaceOrRegionCodeSequenceTrial',              i = find( GROUP ==     8 & ELEME ==  8785 ,1); type = 'SQ';
            case 'AnatomicPortalOfEntranceCodeSequenceTrial',                    i = find( GROUP ==     8 & ELEME ==  8787 ,1); type = 'SQ';
            case 'AnatomicApproachDirectionCodeSequenceTrial',                   i = find( GROUP ==     8 & ELEME ==  8789 ,1); type = 'SQ';
            case 'AnatomicPerspectiveDescriptionTrial',                          i = find( GROUP ==     8 & ELEME ==  8790 ,1); type = 'ST';
            case 'AnatomicPerspectiveCodeSequenceTrial',                         i = find( GROUP ==     8 & ELEME ==  8791 ,1); type = 'SQ';
            case 'AnatomicLocationOfExaminingInstrumentDescriptionTrial',        i = find( GROUP ==     8 & ELEME ==  8792 ,1); type = 'ST';
            case 'AnatomicLocationOfExaminingInstrumentCodeSequenceTrial',       i = find( GROUP ==     8 & ELEME ==  8793 ,1); type = 'SQ';
            case 'AnatomicStructureSpaceOrRegionModifierCodeSequenceTrial',      i = find( GROUP ==     8 & ELEME ==  8794 ,1); type = 'SQ';
            case 'OnAxisBackgroundAnatomicStructureCodeSequenceTrial',           i = find( GROUP ==     8 & ELEME ==  8796 ,1); type = 'SQ';
            case 'IdentifyingComments',                                          i = find( GROUP ==     8 & ELEME == 16384 ,1); type = 'LT';
            case 'FrameType',                                                    i = find( GROUP ==     8 & ELEME == 36871 ,1); type = 'CS';
            case 'ReferencedImageEvidenceSequence',                              i = find( GROUP ==     8 & ELEME == 37010 ,1); type = 'SQ';
            case 'ReferencedRawDataSequence',                                    i = find( GROUP ==     8 & ELEME == 37153 ,1); type = 'SQ';
            case 'CreatorVersionUID',                                            i = find( GROUP ==     8 & ELEME == 37155 ,1); type = 'UI';
            case 'DerivationImageSequence',                                      i = find( GROUP ==     8 & ELEME == 37156 ,1); type = 'SQ';
            case 'SourceImageEvidenceSequence',                                  i = find( GROUP ==     8 & ELEME == 37204 ,1); type = 'SQ';
            case 'PixelPresentation',                                            i = find( GROUP ==     8 & ELEME == 37381 ,1); type = 'CS';
            case 'VolumetricProperties',                                         i = find( GROUP ==     8 & ELEME == 37382 ,1); type = 'CS';
            case 'VolumeBasedCalculationTechnique',                              i = find( GROUP ==     8 & ELEME == 37383 ,1); type = 'CS';
            case 'ComplexImageComponent',                                        i = find( GROUP ==     8 & ELEME == 37384 ,1); type = 'CS';
            case 'AcquisitionContrast',                                          i = find( GROUP ==     8 & ELEME == 37385 ,1); type = 'CS';
            case 'DerivationCodeSequence',                                       i = find( GROUP ==     8 & ELEME == 37397 ,1); type = 'SQ';
            case 'ReferencedGrayscalePresentationStateSequence',                 i = find( GROUP ==     8 & ELEME == 37431 ,1); type = 'SQ';
            case 'PatientGroupLength',                                           i = find( GROUP ==    16 & ELEME ==     0 ,1); type = 'UL';
            case 'PatientID',                                                    i = find( GROUP ==    16 & ELEME ==    32 ,1); type = 'LO';
            case 'IssuerOfPatientID',                                            i = find( GROUP ==    16 & ELEME ==    33 ,1); type = 'LO';
            case 'PatientBirthDate',                                             i = find( GROUP ==    16 & ELEME ==    48 ,1); type = 'DA';
            case 'PatientBirthTime',                                             i = find( GROUP ==    16 & ELEME ==    50 ,1); type = 'TM';
            case 'PatientSex',                                                   i = find( GROUP ==    16 & ELEME ==    64 ,1); type = 'CS';
            case 'PatientInsurancePlanCodeSequence',                             i = find( GROUP ==    16 & ELEME ==    80 ,1); type = 'SQ';
            case 'PatientPrimaryLanguageCodeSequence',                           i = find( GROUP ==    16 & ELEME ==   257 ,1); type = 'SQ';
            case 'PatientPrimaryLanguageModifierCodeSequence',                   i = find( GROUP ==    16 & ELEME ==   258 ,1); type = 'SQ';
            case 'OtherPatientID',                                               i = find( GROUP ==    16 & ELEME ==  4096 ,1); type = 'LO';
            case 'OtherPatientName',                                             i = find( GROUP ==    16 & ELEME ==  4097 ,1); type = 'PN';
            case 'PatientBirthName',                                             i = find( GROUP ==    16 & ELEME ==  4101 ,1); type = 'PN';
            case 'PatientAge',                                                   i = find( GROUP ==    16 & ELEME ==  4112 ,1); type = 'AS';
            case 'PatientSize',                                                  i = find( GROUP ==    16 & ELEME ==  4128 ,1); type = 'DS';
            case 'PatientWeight',                                                i = find( GROUP ==    16 & ELEME ==  4144 ,1); type = 'DS';
            case 'PatientAddress',                                               i = find( GROUP ==    16 & ELEME ==  4160 ,1); type = 'LO';
            case 'InsurancePlanIdentification',                                  i = find( GROUP ==    16 & ELEME ==  4176 ,1); type = 'LT';
            case 'PatientMotherBirthName',                                       i = find( GROUP ==    16 & ELEME ==  4192 ,1); type = 'PN';
            case 'MilitaryRank',                                                 i = find( GROUP ==    16 & ELEME ==  4224 ,1); type = 'LO';
            case 'BranchOfService',                                              i = find( GROUP ==    16 & ELEME ==  4225 ,1); type = 'LO';
            case 'MedicalRecordLocator',                                         i = find( GROUP ==    16 & ELEME ==  4240 ,1); type = 'LO';
            case 'MedicalAlerts',                                                i = find( GROUP ==    16 & ELEME ==  8192 ,1); type = 'LO';
            case 'ContrastAllergies',                                            i = find( GROUP ==    16 & ELEME ==  8464 ,1); type = 'LO';
            case 'CountryOfResidence',                                           i = find( GROUP ==    16 & ELEME ==  8528 ,1); type = 'LO';
            case 'RegionOfResidence',                                            i = find( GROUP ==    16 & ELEME ==  8530 ,1); type = 'LO';
            case 'PatientTelephoneNumber',                                       i = find( GROUP ==    16 & ELEME ==  8532 ,1); type = 'SH';
            case 'EthnicGroup',                                                  i = find( GROUP ==    16 & ELEME ==  8544 ,1); type = 'SH';
            case 'Occupation',                                                   i = find( GROUP ==    16 & ELEME ==  8576 ,1); type = 'SH';
            case 'SmokingStatus',                                                i = find( GROUP ==    16 & ELEME ==  8608 ,1); type = 'CS';
            case 'AdditionalPatientHistory',                                     i = find( GROUP ==    16 & ELEME ==  8624 ,1); type = 'LT';
            case 'PregnancyStatus',                                              i = find( GROUP ==    16 & ELEME ==  8640 ,1); type = 'US';
            case 'LastMenstrualDate',                                            i = find( GROUP ==    16 & ELEME ==  8656 ,1); type = 'DA';
            case 'PatientReligiousPreference',                                   i = find( GROUP ==    16 & ELEME ==  8688 ,1); type = 'LO';
            case 'PatientComments',                                              i = find( GROUP ==    16 & ELEME == 16384 ,1); type = 'LT';
            case 'ClinicalTrialGroupLength',                                     i = find( GROUP ==    18 & ELEME ==     0 ,1); type = 'UL';
            case 'ClinicalTrialSponsorName',                                     i = find( GROUP ==    18 & ELEME ==    16 ,1); type = 'LO';
            case 'ClinicalTrialProtocolID',                                      i = find( GROUP ==    18 & ELEME ==    32 ,1); type = 'LO';
            case 'ClinicalTrialProtocolName',                                    i = find( GROUP ==    18 & ELEME ==    33 ,1); type = 'LO';
            case 'ClinicalTrialSiteID',                                          i = find( GROUP ==    18 & ELEME ==    48 ,1); type = 'LO';
            case 'ClinicalTrialSiteName',                                        i = find( GROUP ==    18 & ELEME ==    49 ,1); type = 'LO';
            case 'ClinicalTrialSubjectID',                                       i = find( GROUP ==    18 & ELEME ==    64 ,1); type = 'LO';
            case 'ClinicalTrialSubjectReadingID',                                i = find( GROUP ==    18 & ELEME ==    66 ,1); type = 'LO';
            case 'ClinicalTrialTimePointID',                                     i = find( GROUP ==    18 & ELEME ==    80 ,1); type = 'LO';
            case 'ClinicalTrialTimePointDescription',                            i = find( GROUP ==    18 & ELEME ==    81 ,1); type = 'ST';
            case 'ClinicalTrialCoordinatingCenterName',                          i = find( GROUP ==    18 & ELEME ==    96 ,1); type = 'LO';
            case 'AcquisitionGroupLength',                                       i = find( GROUP ==    24 & ELEME ==     0 ,1); type = 'UL';
            case 'ContrastBolusAgent',                                           i = find( GROUP ==    24 & ELEME ==    16 ,1); type = 'LO';
            case 'ContrastBolusAgentSequence',                                   i = find( GROUP ==    24 & ELEME ==    18 ,1); type = 'SQ';
            case 'ContrastBolusAdministrationRouteSequence',                     i = find( GROUP ==    24 & ELEME ==    20 ,1); type = 'SQ';
            case 'BodyPartExamined',                                             i = find( GROUP ==    24 & ELEME ==    21 ,1); type = 'CS';
            case 'ScanningSequence',                                             i = find( GROUP ==    24 & ELEME ==    32 ,1); type = 'CS';
            case 'SequenceVariant',                                              i = find( GROUP ==    24 & ELEME ==    33 ,1); type = 'CS';
            case 'ScanOptions',                                                  i = find( GROUP ==    24 & ELEME ==    34 ,1); type = 'CS';
            case 'MRAcquisitionType',                                            i = find( GROUP ==    24 & ELEME ==    35 ,1); type = 'CS';
            case 'SequenceName',                                                 i = find( GROUP ==    24 & ELEME ==    36 ,1); type = 'SH';
            case 'AngioFlag',                                                    i = find( GROUP ==    24 & ELEME ==    37 ,1); type = 'CS';
            case 'InterventionDrugInformationSequence',                          i = find( GROUP ==    24 & ELEME ==    38 ,1); type = 'SQ';
            case 'InterventionDrugStopTime',                                     i = find( GROUP ==    24 & ELEME ==    39 ,1); type = 'TM';
            case 'InterventionDrugDose',                                         i = find( GROUP ==    24 & ELEME ==    40 ,1); type = 'DS';
            case 'InterventionDrugCodeSequence',                                 i = find( GROUP ==    24 & ELEME ==    41 ,1); type = 'SQ';
            case 'AdditionalDrugSequence',                                       i = find( GROUP ==    24 & ELEME ==    42 ,1); type = 'SQ';
            case 'Radionuclide',                                                 i = find( GROUP ==    24 & ELEME ==    48 ,1); type = 'LO';
            case 'Radiopharmaceutical',                                          i = find( GROUP ==    24 & ELEME ==    49 ,1); type = 'LO';
            case 'EnergyWindowCenterline',                                       i = find( GROUP ==    24 & ELEME ==    50 ,1); type = 'DS';
            case 'EnergyWindowTotalWidth',                                       i = find( GROUP ==    24 & ELEME ==    51 ,1); type = 'DS';
            case 'InterventionDrugName',                                         i = find( GROUP ==    24 & ELEME ==    52 ,1); type = 'LO';
            case 'InterventionDrugStartTime',                                    i = find( GROUP ==    24 & ELEME ==    53 ,1); type = 'TM';
            case 'InterventionTherapySequence',                                  i = find( GROUP ==    24 & ELEME ==    54 ,1); type = 'SQ';
            case 'TherapyType',                                                  i = find( GROUP ==    24 & ELEME ==    55 ,1); type = 'CS';
            case 'InterventionStatus',                                           i = find( GROUP ==    24 & ELEME ==    56 ,1); type = 'CS';
            case 'TherapyDescription',                                           i = find( GROUP ==    24 & ELEME ==    57 ,1); type = 'CS';
            case 'CineRate',                                                     i = find( GROUP ==    24 & ELEME ==    64 ,1); type = 'IS';
            case 'SliceThickness',                                               i = find( GROUP ==    24 & ELEME ==    80 ,1); type = 'DS';
            case 'KVP',                                                          i = find( GROUP ==    24 & ELEME ==    96 ,1); type = 'DS';
            case 'CountsAccumulated',                                            i = find( GROUP ==    24 & ELEME ==   112 ,1); type = 'IS';
            case 'AcquisitionTerminationCondition',                              i = find( GROUP ==    24 & ELEME ==   113 ,1); type = 'CS';
            case 'EffectiveDuration',                                            i = find( GROUP ==    24 & ELEME ==   114 ,1); type = 'DS';
            case 'AcquisitionStartCondition',                                    i = find( GROUP ==    24 & ELEME ==   115 ,1); type = 'CS';
            case 'AcquisitionStartConditionData',                                i = find( GROUP ==    24 & ELEME ==   116 ,1); type = 'IS';
            case 'AcquisitionTerminationConditionData',                          i = find( GROUP ==    24 & ELEME ==   117 ,1); type = 'IS';
            case 'RepetitionTime',                                               i = find( GROUP ==    24 & ELEME ==   128 ,1); type = 'DS';
            case 'EchoTime',                                                     i = find( GROUP ==    24 & ELEME ==   129 ,1); type = 'DS';
            case 'InversionTime',                                                i = find( GROUP ==    24 & ELEME ==   130 ,1); type = 'DS';
            case 'NumberOfAverages',                                             i = find( GROUP ==    24 & ELEME ==   131 ,1); type = 'DS';
            case 'ImagingFrequency',                                             i = find( GROUP ==    24 & ELEME ==   132 ,1); type = 'DS';
            case 'ImagedNucleus',                                                i = find( GROUP ==    24 & ELEME ==   133 ,1); type = 'SH';
            case 'EchoNumber',                                                   i = find( GROUP ==    24 & ELEME ==   134 ,1); type = 'IS';
            case 'MagneticFieldStrength',                                        i = find( GROUP ==    24 & ELEME ==   135 ,1); type = 'DS';
            case 'SpacingBetweenSlices',                                         i = find( GROUP ==    24 & ELEME ==   136 ,1); type = 'DS';
            case 'NumberOfPhaseEncodingSteps',                                   i = find( GROUP ==    24 & ELEME ==   137 ,1); type = 'IS';
            case 'DataCollectionDiameter',                                       i = find( GROUP ==    24 & ELEME ==   144 ,1); type = 'DS';
            case 'EchoTrainLength',                                              i = find( GROUP ==    24 & ELEME ==   145 ,1); type = 'IS';
            case 'PercentSampling',                                              i = find( GROUP ==    24 & ELEME ==   147 ,1); type = 'DS';
            case 'PercentPhaseFieldOfView',                                      i = find( GROUP ==    24 & ELEME ==   148 ,1); type = 'DS';
            case 'PixelBandwidth',                                               i = find( GROUP ==    24 & ELEME ==   149 ,1); type = 'DS';
            case 'DeviceSerialNumber',                                           i = find( GROUP ==    24 & ELEME ==  4096 ,1); type = 'LO';
            case 'PlateID',                                                      i = find( GROUP ==    24 & ELEME ==  4100 ,1); type = 'LO';
            case 'SecondaryCaptureDeviceID',                                     i = find( GROUP ==    24 & ELEME ==  4112 ,1); type = 'LO';
            case 'HardcopyCreationDeviceID',                                     i = find( GROUP ==    24 & ELEME ==  4113 ,1); type = 'LO';
            case 'DateOfSecondaryCapture',                                       i = find( GROUP ==    24 & ELEME ==  4114 ,1); type = 'DA';
            case 'TimeOfSecondaryCapture',                                       i = find( GROUP ==    24 & ELEME ==  4116 ,1); type = 'TM';
            case 'SecondaryCaptureDeviceManufacturer',                           i = find( GROUP ==    24 & ELEME ==  4118 ,1); type = 'LO';
            case 'HardcopyDeviceManufacturer',                                   i = find( GROUP ==    24 & ELEME ==  4119 ,1); type = 'LO';
            case 'SecondaryCaptureDeviceManufacturerModelName',                  i = find( GROUP ==    24 & ELEME ==  4120 ,1); type = 'LO';
            case 'SecondaryCaptureDeviceSoftwareVersion',                        i = find( GROUP ==    24 & ELEME ==  4121 ,1); type = 'LO';
            case 'HardcopyDeviceSoftwareVersion',                                i = find( GROUP ==    24 & ELEME ==  4122 ,1); type = 'LO';
            case 'HardcopyDeviceManufacturerModelName',                          i = find( GROUP ==    24 & ELEME ==  4123 ,1); type = 'LO';
            case 'SoftwareVersion',                                              i = find( GROUP ==    24 & ELEME ==  4128 ,1); type = 'LO';
            case 'VideoImageFormatAcquired',                                     i = find( GROUP ==    24 & ELEME ==  4130 ,1); type = 'SH';
            case 'DigitalImageFormatAcquired',                                   i = find( GROUP ==    24 & ELEME ==  4131 ,1); type = 'LO';
            case 'ProtocolName',                                                 i = find( GROUP ==    24 & ELEME ==  4144 ,1); type = 'LO';
            case 'ContrastBolusRoute',                                           i = find( GROUP ==    24 & ELEME ==  4160 ,1); type = 'LO';
            case 'ContrastBolusVolume',                                          i = find( GROUP ==    24 & ELEME ==  4161 ,1); type = 'DS';
            case 'ContrastBolusStartTime',                                       i = find( GROUP ==    24 & ELEME ==  4162 ,1); type = 'TM';
            case 'ContrastBolusStopTime',                                        i = find( GROUP ==    24 & ELEME ==  4163 ,1); type = 'TM';
            case 'ContrastBolusTotalDose',                                       i = find( GROUP ==    24 & ELEME ==  4164 ,1); type = 'DS';
            case 'SyringeCounts',                                                i = find( GROUP ==    24 & ELEME ==  4165 ,1); type = 'IS';
            case 'ContrastFlowRate',                                             i = find( GROUP ==    24 & ELEME ==  4166 ,1); type = 'DS';
            case 'ContrastFlowDuration',                                         i = find( GROUP ==    24 & ELEME ==  4167 ,1); type = 'DS';
            case 'ContrastBolusIngredient',                                      i = find( GROUP ==    24 & ELEME ==  4168 ,1); type = 'CS';
            case 'ContrastBolusIngredientConcentration',                         i = find( GROUP ==    24 & ELEME ==  4169 ,1); type = 'DS';
            case 'SpatialResolution',                                            i = find( GROUP ==    24 & ELEME ==  4176 ,1); type = 'DS';
            case 'TriggerTime',                                                  i = find( GROUP ==    24 & ELEME ==  4192 ,1); type = 'DS';
            case 'TriggerSourceOrType',                                          i = find( GROUP ==    24 & ELEME ==  4193 ,1); type = 'LO';
            case 'NominalInterval',                                              i = find( GROUP ==    24 & ELEME ==  4194 ,1); type = 'IS';
            case 'FrameTime',                                                    i = find( GROUP ==    24 & ELEME ==  4195 ,1); type = 'DS';
            case 'FramingType',                                                  i = find( GROUP ==    24 & ELEME ==  4196 ,1); type = 'LO';
            case 'FrameTimeVector',                                              i = find( GROUP ==    24 & ELEME ==  4197 ,1); type = 'DS';
            case 'FrameDelay',                                                   i = find( GROUP ==    24 & ELEME ==  4198 ,1); type = 'DS';
            case 'ImageTriggerDelay',                                            i = find( GROUP ==    24 & ELEME ==  4199 ,1); type = 'DS';
            case 'MultiplexGroupTimeOffset',                                     i = find( GROUP ==    24 & ELEME ==  4200 ,1); type = 'DS';
            case 'TriggerTimeOffset',                                            i = find( GROUP ==    24 & ELEME ==  4201 ,1); type = 'DS';
            case 'SynchronizationTrigger',                                       i = find( GROUP ==    24 & ELEME ==  4202 ,1); type = 'CS';
            case 'SynchronizationChannel',                                       i = find( GROUP ==    24 & ELEME ==  4204 ,1); type = 'US';
            case 'TriggerSamplePosition',                                        i = find( GROUP ==    24 & ELEME ==  4206 ,1); type = 'UL';
            case 'RadiopharmaceuticalRoute',                                     i = find( GROUP ==    24 & ELEME ==  4208 ,1); type = 'LO';
            case 'RadiopharmaceuticalVolume',                                    i = find( GROUP ==    24 & ELEME ==  4209 ,1); type = 'DS';
            case 'RadiopharmaceuticalStartTime',                                 i = find( GROUP ==    24 & ELEME ==  4210 ,1); type = 'TM';
            case 'RadiopharmaceuticalStopTime',                                  i = find( GROUP ==    24 & ELEME ==  4211 ,1); type = 'TM';
            case 'RadionuclideTotalDose',                                        i = find( GROUP ==    24 & ELEME ==  4212 ,1); type = 'DS';
            case 'RadionuclideHalfLife',                                         i = find( GROUP ==    24 & ELEME ==  4213 ,1); type = 'DS';
            case 'RadionuclidePositronFraction',                                 i = find( GROUP ==    24 & ELEME ==  4214 ,1); type = 'DS';
            case 'RadiopharmaceuticalSpecificActivity',                          i = find( GROUP ==    24 & ELEME ==  4215 ,1); type = 'DS';
            case 'BeatRejectionFlag',                                            i = find( GROUP ==    24 & ELEME ==  4224 ,1); type = 'CS';
            case 'LowRRValue',                                                   i = find( GROUP ==    24 & ELEME ==  4225 ,1); type = 'IS';
            case 'HighRRValue',                                                  i = find( GROUP ==    24 & ELEME ==  4226 ,1); type = 'IS';
            case 'IntervalsAcquired',                                            i = find( GROUP ==    24 & ELEME ==  4227 ,1); type = 'IS';
            case 'IntervalsRejected',                                            i = find( GROUP ==    24 & ELEME ==  4228 ,1); type = 'IS';
            case 'PVCRejection',                                                 i = find( GROUP ==    24 & ELEME ==  4229 ,1); type = 'LO';
            case 'SkipBeats',                                                    i = find( GROUP ==    24 & ELEME ==  4230 ,1); type = 'IS';
            case 'HeartRate',                                                    i = find( GROUP ==    24 & ELEME ==  4232 ,1); type = 'IS';
            case 'CardiacNumberOfImages',                                        i = find( GROUP ==    24 & ELEME ==  4240 ,1); type = 'IS';
            case 'TriggerWindow',                                                i = find( GROUP ==    24 & ELEME ==  4244 ,1); type = 'IS';
            case 'ReconstructionDiameter',                                       i = find( GROUP ==    24 & ELEME ==  4352 ,1); type = 'DS';
            case 'DistanceSourceToDetector',                                     i = find( GROUP ==    24 & ELEME ==  4368 ,1); type = 'DS';
            case 'DistanceSourceToPatient',                                      i = find( GROUP ==    24 & ELEME ==  4369 ,1); type = 'DS';
            case 'EstimatedRadiographicMagnificationFactor',                     i = find( GROUP ==    24 & ELEME ==  4372 ,1); type = 'DS';
            case 'GantryDetectorTilt',                                           i = find( GROUP ==    24 & ELEME ==  4384 ,1); type = 'DS';
            case 'GantryDetectorSlew',                                           i = find( GROUP ==    24 & ELEME ==  4385 ,1); type = 'DS';
            case 'TableHeight',                                                  i = find( GROUP ==    24 & ELEME ==  4400 ,1); type = 'DS';
            case 'TableTraverse',                                                i = find( GROUP ==    24 & ELEME ==  4401 ,1); type = 'DS';
            case 'TableMotion',                                                  i = find( GROUP ==    24 & ELEME ==  4404 ,1); type = 'CS';
            case 'TableVerticalIncrement',                                       i = find( GROUP ==    24 & ELEME ==  4405 ,1); type = 'DS';
            case 'TableLateralIncrement',                                        i = find( GROUP ==    24 & ELEME ==  4406 ,1); type = 'DS';
            case 'TableLongitudinalIncrement',                                   i = find( GROUP ==    24 & ELEME ==  4407 ,1); type = 'DS';
            case 'TableAngle',                                                   i = find( GROUP ==    24 & ELEME ==  4408 ,1); type = 'DS';
            case 'TableType',                                                    i = find( GROUP ==    24 & ELEME ==  4410 ,1); type = 'CS';
            case 'RotationDirection',                                            i = find( GROUP ==    24 & ELEME ==  4416 ,1); type = 'CS';
            case 'AngularPosition',                                              i = find( GROUP ==    24 & ELEME ==  4417 ,1); type = 'DS';
            case 'RadialPosition',                                               i = find( GROUP ==    24 & ELEME ==  4418 ,1); type = 'DS';
            case 'ScanArc',                                                      i = find( GROUP ==    24 & ELEME ==  4419 ,1); type = 'DS';
            case 'AngularStep',                                                  i = find( GROUP ==    24 & ELEME ==  4420 ,1); type = 'DS';
            case 'CenterOfRotationOffset',                                       i = find( GROUP ==    24 & ELEME ==  4421 ,1); type = 'DS';
            case 'RotationOffset',                                               i = find( GROUP ==    24 & ELEME ==  4422 ,1); type = 'DS';
            case 'FieldOfViewShape',                                             i = find( GROUP ==    24 & ELEME ==  4423 ,1); type = 'CS';
            case 'FieldOfViewDimensions',                                        i = find( GROUP ==    24 & ELEME ==  4425 ,1); type = 'IS';
            case 'ExposureTime',                                                 i = find( GROUP ==    24 & ELEME ==  4432 ,1); type = 'IS';
            case 'XrayTubeCurrent',                                              i = find( GROUP ==    24 & ELEME ==  4433 ,1); type = 'IS';
            case 'Exposure',                                                     i = find( GROUP ==    24 & ELEME ==  4434 ,1); type = 'IS';
            case 'ExposureInuAs',                                                i = find( GROUP ==    24 & ELEME ==  4435 ,1); type = 'IS';
            case 'AveragePulseWidth',                                            i = find( GROUP ==    24 & ELEME ==  4436 ,1); type = 'DS';
            case 'RadiationSetting',                                             i = find( GROUP ==    24 & ELEME ==  4437 ,1); type = 'CS';
            case 'RectificationType',                                            i = find( GROUP ==    24 & ELEME ==  4438 ,1); type = 'CS';
            case 'RadiationMode',                                                i = find( GROUP ==    24 & ELEME ==  4442 ,1); type = 'CS';
            case 'ImageAreaDoseProduct',                                         i = find( GROUP ==    24 & ELEME ==  4446 ,1); type = 'DS';
            case 'FilterType',                                                   i = find( GROUP ==    24 & ELEME ==  4448 ,1); type = 'SH';
            case 'TypeOfFilters',                                                i = find( GROUP ==    24 & ELEME ==  4449 ,1); type = 'LO';
            case 'IntensifierSize',                                              i = find( GROUP ==    24 & ELEME ==  4450 ,1); type = 'DS';
            case 'ImagerPixelSpacing',                                           i = find( GROUP ==    24 & ELEME ==  4452 ,1); type = 'DS';
            case 'Grid',                                                         i = find( GROUP ==    24 & ELEME ==  4454 ,1); type = 'CS';
            case 'GeneratorPower',                                               i = find( GROUP ==    24 & ELEME ==  4464 ,1); type = 'IS';
            case 'CollimatorGridName',                                           i = find( GROUP ==    24 & ELEME ==  4480 ,1); type = 'SH';
            case 'CollimatorType',                                               i = find( GROUP ==    24 & ELEME ==  4481 ,1); type = 'CS';
            case 'FocalDistance',                                                i = find( GROUP ==    24 & ELEME ==  4482 ,1); type = 'IS';
            case 'XFocusCenter',                                                 i = find( GROUP ==    24 & ELEME ==  4483 ,1); type = 'DS';
            case 'YFocusCenter',                                                 i = find( GROUP ==    24 & ELEME ==  4484 ,1); type = 'DS';
            case 'FocalSpot',                                                    i = find( GROUP ==    24 & ELEME ==  4496 ,1); type = 'DS';
            case 'AnodeTargetMaterial',                                          i = find( GROUP ==    24 & ELEME ==  4497 ,1); type = 'CS';
            case 'BodyPartThickness',                                            i = find( GROUP ==    24 & ELEME ==  4512 ,1); type = 'DS';
            case 'CompressionForce',                                             i = find( GROUP ==    24 & ELEME ==  4514 ,1); type = 'DS';
            case 'DateOfLastCalibration',                                        i = find( GROUP ==    24 & ELEME ==  4608 ,1); type = 'DA';
            case 'TimeOfLastCalibration',                                        i = find( GROUP ==    24 & ELEME ==  4609 ,1); type = 'TM';
            case 'ConvolutionKernel',                                            i = find( GROUP ==    24 & ELEME ==  4624 ,1); type = 'SH';
            case 'UpperLowerPixelValues',                                        i = find( GROUP ==    24 & ELEME ==  4672 ,1); type = 'IS';
            case 'ActualFrameDuration',                                          i = find( GROUP ==    24 & ELEME ==  4674 ,1); type = 'IS';
            case 'CountRate',                                                    i = find( GROUP ==    24 & ELEME ==  4675 ,1); type = 'IS';
            case 'PreferredPlaybackSequencing',                                  i = find( GROUP ==    24 & ELEME ==  4676 ,1); type = 'US';
            case 'ReceiveCoilName',                                              i = find( GROUP ==    24 & ELEME ==  4688 ,1); type = 'SH';
            case 'TransmitCoilName',                                             i = find( GROUP ==    24 & ELEME ==  4689 ,1); type = 'SH';
            case 'PlateType',                                                    i = find( GROUP ==    24 & ELEME ==  4704 ,1); type = 'SH';
            case 'PhosphorType',                                                 i = find( GROUP ==    24 & ELEME ==  4705 ,1); type = 'LO';
            case 'ScanVelocity',                                                 i = find( GROUP ==    24 & ELEME ==  4864 ,1); type = 'DS';
            case 'WholeBodyTechnique',                                           i = find( GROUP ==    24 & ELEME ==  4865 ,1); type = 'CS';
            case 'ScanLength',                                                   i = find( GROUP ==    24 & ELEME ==  4866 ,1); type = 'IS';
            case 'AcquisitionMatrix',                                            i = find( GROUP ==    24 & ELEME ==  4880 ,1); type = 'US';
            case 'InPlanePhaseEncodingDirection',                                i = find( GROUP ==    24 & ELEME ==  4882 ,1); type = 'CS';
            case 'FlipAngle',                                                    i = find( GROUP ==    24 & ELEME ==  4884 ,1); type = 'DS';
            case 'VariableFlipAngleFlag',                                        i = find( GROUP ==    24 & ELEME ==  4885 ,1); type = 'CS';
            case 'SAR',                                                          i = find( GROUP ==    24 & ELEME ==  4886 ,1); type = 'DS';
            case 'dBdt',                                                         i = find( GROUP ==    24 & ELEME ==  4888 ,1); type = 'DS';
            case 'AcquisitionDeviceProcessingDescription',                       i = find( GROUP ==    24 & ELEME ==  5120 ,1); type = 'LO';
            case 'AcquisitionDeviceProcessingCode',                              i = find( GROUP ==    24 & ELEME ==  5121 ,1); type = 'LO';
            case 'CassetteOrientation',                                          i = find( GROUP ==    24 & ELEME ==  5122 ,1); type = 'CS';
            case 'CassetteSize',                                                 i = find( GROUP ==    24 & ELEME ==  5123 ,1); type = 'CS';
            case 'ExposuresOnPlate',                                             i = find( GROUP ==    24 & ELEME ==  5124 ,1); type = 'US';
            case 'RelativeXrayExposure',                                         i = find( GROUP ==    24 & ELEME ==  5125 ,1); type = 'IS';
            case 'ColumnAngulation',                                             i = find( GROUP ==    24 & ELEME ==  5200 ,1); type = 'DS';
            case 'TomoLayerHeight',                                              i = find( GROUP ==    24 & ELEME ==  5216 ,1); type = 'DS';
            case 'TomoAngle',                                                    i = find( GROUP ==    24 & ELEME ==  5232 ,1); type = 'DS';
            case 'TomoTime',                                                     i = find( GROUP ==    24 & ELEME ==  5248 ,1); type = 'DS';
            case 'TomoType',                                                     i = find( GROUP ==    24 & ELEME ==  5264 ,1); type = 'CS';
            case 'TomoClass',                                                    i = find( GROUP ==    24 & ELEME ==  5265 ,1); type = 'CS';
            case 'NumberOfTomosynthesisSourceImages',                            i = find( GROUP ==    24 & ELEME ==  5269 ,1); type = 'IS';
            case 'PositionerMotion',                                             i = find( GROUP ==    24 & ELEME ==  5376 ,1); type = 'CS';
            case 'PositionerType',                                               i = find( GROUP ==    24 & ELEME ==  5384 ,1); type = 'CS';
            case 'PositionerPrimaryAngle',                                       i = find( GROUP ==    24 & ELEME ==  5392 ,1); type = 'DS';
            case 'PositionerSecondaryAngle',                                     i = find( GROUP ==    24 & ELEME ==  5393 ,1); type = 'DS';
            case 'PositionerPrimaryAngleIncrement',                              i = find( GROUP ==    24 & ELEME ==  5408 ,1); type = 'DS';
            case 'PositionerSecondaryAngleIncrement',                            i = find( GROUP ==    24 & ELEME ==  5409 ,1); type = 'DS';
            case 'DetectorPrimaryAngle',                                         i = find( GROUP ==    24 & ELEME ==  5424 ,1); type = 'DS';
            case 'DetectorSecondaryAngle',                                       i = find( GROUP ==    24 & ELEME ==  5425 ,1); type = 'DS';
            case 'ShutterShape',                                                 i = find( GROUP ==    24 & ELEME ==  5632 ,1); type = 'CS';
            case 'ShutterLeftVerticalEdge',                                      i = find( GROUP ==    24 & ELEME ==  5634 ,1); type = 'IS';
            case 'ShutterRightVerticalEdge',                                     i = find( GROUP ==    24 & ELEME ==  5636 ,1); type = 'IS';
            case 'ShutterUpperHorizontalEdge',                                   i = find( GROUP ==    24 & ELEME ==  5638 ,1); type = 'IS';
            case 'ShutterLowerHorizontalEdge',                                   i = find( GROUP ==    24 & ELEME ==  5640 ,1); type = 'IS';
            case 'CenterOfCircularShutter',                                      i = find( GROUP ==    24 & ELEME ==  5648 ,1); type = 'IS';
            case 'RadiusOfCircularShutter',                                      i = find( GROUP ==    24 & ELEME ==  5650 ,1); type = 'IS';
            case 'VerticesOfPolygonalShutter',                                   i = find( GROUP ==    24 & ELEME ==  5664 ,1); type = 'IS';
            case 'ShutterPresentationValue',                                     i = find( GROUP ==    24 & ELEME ==  5666 ,1); type = 'US';
            case 'ShutterOverlayGroup',                                          i = find( GROUP ==    24 & ELEME ==  5667 ,1); type = 'US';
            case 'CollimatorShape',                                              i = find( GROUP ==    24 & ELEME ==  5888 ,1); type = 'CS';
            case 'CollimatorLeftVerticalEdge',                                   i = find( GROUP ==    24 & ELEME ==  5890 ,1); type = 'IS';
            case 'CollimatorRightVerticalEdge',                                  i = find( GROUP ==    24 & ELEME ==  5892 ,1); type = 'IS';
            case 'CollimatorUpperHorizontalEdge',                                i = find( GROUP ==    24 & ELEME ==  5894 ,1); type = 'IS';
            case 'CollimatorLowerHorizontalEdge',                                i = find( GROUP ==    24 & ELEME ==  5896 ,1); type = 'IS';
            case 'CenterOfCircularCollimator',                                   i = find( GROUP ==    24 & ELEME ==  5904 ,1); type = 'IS';
            case 'RadiusOfCircularCollimator',                                   i = find( GROUP ==    24 & ELEME ==  5906 ,1); type = 'IS';
            case 'VerticesOfPolygonalCollimator',                                i = find( GROUP ==    24 & ELEME ==  5920 ,1); type = 'IS';
            case 'AcquisitionTimeSynchronized',                                  i = find( GROUP ==    24 & ELEME ==  6144 ,1); type = 'CS';
            case 'TimeSource',                                                   i = find( GROUP ==    24 & ELEME ==  6145 ,1); type = 'SH';
            case 'TimeDistributionProtocol',                                     i = find( GROUP ==    24 & ELEME ==  6146 ,1); type = 'CS';
            case 'NTPSourceAddress',                                             i = find( GROUP ==    24 & ELEME ==  6147 ,1); type = 'LO';
            case 'PageNumberVector',                                             i = find( GROUP ==    24 & ELEME ==  8193 ,1); type = 'IS';
            case 'FrameLabelVector',                                             i = find( GROUP ==    24 & ELEME ==  8194 ,1); type = 'SH';
            case 'FramePrimaryAngleVector',                                      i = find( GROUP ==    24 & ELEME ==  8195 ,1); type = 'DS';
            case 'FrameSecondaryAngleVector',                                    i = find( GROUP ==    24 & ELEME ==  8196 ,1); type = 'DS';
            case 'SliceLocationVector',                                          i = find( GROUP ==    24 & ELEME ==  8197 ,1); type = 'DS';
            case 'DisplayWindowLabelVector',                                     i = find( GROUP ==    24 & ELEME ==  8198 ,1); type = 'SH';
            case 'NominalScannedPixelSpacing',                                   i = find( GROUP ==    24 & ELEME ==  8208 ,1); type = 'DS';
            case 'DigitizingDeviceTransportDirection',                           i = find( GROUP ==    24 & ELEME ==  8224 ,1); type = 'CS';
            case 'RotationOfScannedFilm',                                        i = find( GROUP ==    24 & ELEME ==  8240 ,1); type = 'DS';
            case 'IVUSAcquisition',                                              i = find( GROUP ==    24 & ELEME == 12544 ,1); type = 'CS';
            case 'IVUSPullbackRate',                                             i = find( GROUP ==    24 & ELEME == 12545 ,1); type = 'DS';
            case 'IVUSGatedRate',                                                i = find( GROUP ==    24 & ELEME == 12546 ,1); type = 'DS';
            case 'IVUSPullbackStartFrameNumber',                                 i = find( GROUP ==    24 & ELEME == 12547 ,1); type = 'IS';
            case 'IVUSPullbackStopFrameNumber',                                  i = find( GROUP ==    24 & ELEME == 12548 ,1); type = 'IS';
            case 'LesionNumber',                                                 i = find( GROUP ==    24 & ELEME == 12549 ,1); type = 'IS';
            case 'AcquisitionComments',                                          i = find( GROUP ==    24 & ELEME == 16384 ,1); type = 'LT';
            case 'OutputPower',                                                  i = find( GROUP ==    24 & ELEME == 20480 ,1); type = 'SH';
            case 'TransducerData',                                               i = find( GROUP ==    24 & ELEME == 20496 ,1); type = 'LO';
            case 'FocusDepth',                                                   i = find( GROUP ==    24 & ELEME == 20498 ,1); type = 'DS';
            case 'ProcessingFunction',                                           i = find( GROUP ==    24 & ELEME == 20512 ,1); type = 'LO';
            case 'PostprocessingFunction',                                       i = find( GROUP ==    24 & ELEME == 20513 ,1); type = 'LO';
            case 'MechanicalIndex',                                              i = find( GROUP ==    24 & ELEME == 20514 ,1); type = 'DS';
            case 'BoneThermalIndex',                                             i = find( GROUP ==    24 & ELEME == 20516 ,1); type = 'DS';
            case 'CranialThermalIndex',                                          i = find( GROUP ==    24 & ELEME == 20518 ,1); type = 'DS';
            case 'SoftTissueThermalIndex',                                       i = find( GROUP ==    24 & ELEME == 20519 ,1); type = 'DS';
            case 'SoftTissueFocusThermalIndex',                                  i = find( GROUP ==    24 & ELEME == 20520 ,1); type = 'DS';
            case 'SoftTissueSurfaceThermalIndex',                                i = find( GROUP ==    24 & ELEME == 20521 ,1); type = 'DS';
            case 'DynamicRange',                                                 i = find( GROUP ==    24 & ELEME == 20528 ,1); type = 'DS';
            case 'TotalGain',                                                    i = find( GROUP ==    24 & ELEME == 20544 ,1); type = 'DS';
            case 'DepthOfScanField',                                             i = find( GROUP ==    24 & ELEME == 20560 ,1); type = 'IS';
            case 'PatientPosition',                                              i = find( GROUP ==    24 & ELEME == 20736 ,1); type = 'CS';
            case 'ViewPosition',                                                 i = find( GROUP ==    24 & ELEME == 20737 ,1); type = 'CS';
            case 'ProjectionEponymousNameCodeSequence',                          i = find( GROUP ==    24 & ELEME == 20740 ,1); type = 'SQ';
            case 'ImageTransformationMatrix',                                    i = find( GROUP ==    24 & ELEME == 21008 ,1); type = 'DS';
            case 'ImageTranslationVector',                                       i = find( GROUP ==    24 & ELEME == 21010 ,1); type = 'DS';
            case 'Sensitivity',                                                  i = find( GROUP ==    24 & ELEME == 24576 ,1); type = 'DS';
            case 'SequenceOfUltrasoundRegions',                                  i = find( GROUP ==    24 & ELEME == 24593 ,1); type = 'SQ';
            case 'RegionSpatialFormat',                                          i = find( GROUP ==    24 & ELEME == 24594 ,1); type = 'US';
            case 'RegionDataType',                                               i = find( GROUP ==    24 & ELEME == 24596 ,1); type = 'US';
            case 'RegionFlags',                                                  i = find( GROUP ==    24 & ELEME == 24598 ,1); type = 'UL';
            case 'RegionLocationMinX0',                                          i = find( GROUP ==    24 & ELEME == 24600 ,1); type = 'UL';
            case 'RegionLocationMinY0',                                          i = find( GROUP ==    24 & ELEME == 24602 ,1); type = 'UL';
            case 'RegionLocationMaxX1',                                          i = find( GROUP ==    24 & ELEME == 24604 ,1); type = 'UL';
            case 'RegionLocationMaxY1',                                          i = find( GROUP ==    24 & ELEME == 24606 ,1); type = 'UL';
            case 'ReferencePixelX0',                                             i = find( GROUP ==    24 & ELEME == 24608 ,1); type = 'SL';
            case 'ReferencePixelY0',                                             i = find( GROUP ==    24 & ELEME == 24610 ,1); type = 'SL';
            case 'PhysicalUnitsXDirection',                                      i = find( GROUP ==    24 & ELEME == 24612 ,1); type = 'US';
            case 'PhysicalUnitsYDirection',                                      i = find( GROUP ==    24 & ELEME == 24614 ,1); type = 'US';
            case 'ReferencePixelPhysicalValueX',                                 i = find( GROUP ==    24 & ELEME == 24616 ,1); type = 'FD';
            case 'ReferencePixelPhysicalValueY',                                 i = find( GROUP ==    24 & ELEME == 24618 ,1); type = 'FD';
            case 'PhysicalDeltaX',                                               i = find( GROUP ==    24 & ELEME == 24620 ,1); type = 'FD';
            case 'PhysicalDeltaY',                                               i = find( GROUP ==    24 & ELEME == 24622 ,1); type = 'FD';
            case 'TransducerFrequency',                                          i = find( GROUP ==    24 & ELEME == 24624 ,1); type = 'UL';
            case 'TransducerType',                                               i = find( GROUP ==    24 & ELEME == 24625 ,1); type = 'CS';
            case 'PulseRepetitionFrequency',                                     i = find( GROUP ==    24 & ELEME == 24626 ,1); type = 'UL';
            case 'DopplerCorrectionAngle',                                       i = find( GROUP ==    24 & ELEME == 24628 ,1); type = 'FD';
            case 'SteeringAngle',                                                i = find( GROUP ==    24 & ELEME == 24630 ,1); type = 'FD';
            case 'DopplerSampleVolumeXPositionRetired',                          i = find( GROUP ==    24 & ELEME == 24632 ,1); type = 'UL';
            case 'DopplerSampleVolumeXPosition',                                 i = find( GROUP ==    24 & ELEME == 24633 ,1); type = 'SL';
            case 'DopplerSampleVolumeYPositionRetired',                          i = find( GROUP ==    24 & ELEME == 24634 ,1); type = 'UL';
            case 'DopplerSampleVolumeYPosition',                                 i = find( GROUP ==    24 & ELEME == 24635 ,1); type = 'SL';
            case 'TMLinePositionX0Retired',                                      i = find( GROUP ==    24 & ELEME == 24636 ,1); type = 'UL';
            case 'TMLinePositionX0',                                             i = find( GROUP ==    24 & ELEME == 24637 ,1); type = 'SL';
            case 'TMLinePositionY0Retired',                                      i = find( GROUP ==    24 & ELEME == 24638 ,1); type = 'UL';
            case 'TMLinePositionY0',                                             i = find( GROUP ==    24 & ELEME == 24639 ,1); type = 'SL';
            case 'TMLinePositionX1Retired',                                      i = find( GROUP ==    24 & ELEME == 24640 ,1); type = 'UL';
            case 'TMLinePositionX1',                                             i = find( GROUP ==    24 & ELEME == 24641 ,1); type = 'SL';
            case 'TMLinePositionY1Retired',                                      i = find( GROUP ==    24 & ELEME == 24642 ,1); type = 'UL';
            case 'TMLinePositionY1',                                             i = find( GROUP ==    24 & ELEME == 24643 ,1); type = 'SL';
            case 'PixelComponentOrganization',                                   i = find( GROUP ==    24 & ELEME == 24644 ,1); type = 'US';
            case 'PixelComponentMask',                                           i = find( GROUP ==    24 & ELEME == 24646 ,1); type = 'UL';
            case 'PixelComponentRangeStart',                                     i = find( GROUP ==    24 & ELEME == 24648 ,1); type = 'UL';
            case 'PixelComponentRangeStop',                                      i = find( GROUP ==    24 & ELEME == 24650 ,1); type = 'UL';
            case 'PixelComponentPhysicalUnits',                                  i = find( GROUP ==    24 & ELEME == 24652 ,1); type = 'US';
            case 'PixelComponentDataType',                                       i = find( GROUP ==    24 & ELEME == 24654 ,1); type = 'US';
            case 'NumberOfTableBreakPoints',                                     i = find( GROUP ==    24 & ELEME == 24656 ,1); type = 'UL';
            case 'TableOfXBreakPoints',                                          i = find( GROUP ==    24 & ELEME == 24658 ,1); type = 'UL';
            case 'TableOfYBreakPoints',                                          i = find( GROUP ==    24 & ELEME == 24660 ,1); type = 'FD';
            case 'NumberOfTableEntries',                                         i = find( GROUP ==    24 & ELEME == 24662 ,1); type = 'UL';
            case 'TableOfPixelValues',                                           i = find( GROUP ==    24 & ELEME == 24664 ,1); type = 'UL';
            case 'TableOfParameterValues',                                       i = find( GROUP ==    24 & ELEME == 24666 ,1); type = 'FL';
            case 'DetectorConditionsNominalFlag',                                i = find( GROUP ==    24 & ELEME == 28672 ,1); type = 'CS';
            case 'DetectorTemperature',                                          i = find( GROUP ==    24 & ELEME == 28673 ,1); type = 'DS';
            case 'DetectorType',                                                 i = find( GROUP ==    24 & ELEME == 28676 ,1); type = 'CS';
            case 'DetectorConfiguration',                                        i = find( GROUP ==    24 & ELEME == 28677 ,1); type = 'CS';
            case 'DetectorDescription',                                          i = find( GROUP ==    24 & ELEME == 28678 ,1); type = 'LT';
            case 'DetectorMode',                                                 i = find( GROUP ==    24 & ELEME == 28680 ,1); type = 'LT';
            case 'DetectorID',                                                   i = find( GROUP ==    24 & ELEME == 28682 ,1); type = 'SH';
            case 'DateOfLastDetectorCalibration',                                i = find( GROUP ==    24 & ELEME == 28684 ,1); type = 'DA';
            case 'TimeOfLastDetectorCalibration',                                i = find( GROUP ==    24 & ELEME == 28686 ,1); type = 'TM';
            case 'ExposuresOnDetectorSinceLastCalibration',                      i = find( GROUP ==    24 & ELEME == 28688 ,1); type = 'IS';
            case 'ExposuresOnDetectorSinceManufactured',                         i = find( GROUP ==    24 & ELEME == 28689 ,1); type = 'IS';
            case 'DetectorTimeSinceLastExposure',                                i = find( GROUP ==    24 & ELEME == 28690 ,1); type = 'DS';
            case 'DetectorActiveTime',                                           i = find( GROUP ==    24 & ELEME == 28692 ,1); type = 'DS';
            case 'DetectorActivationOffsetFromExposure',                         i = find( GROUP ==    24 & ELEME == 28694 ,1); type = 'DS';
            case 'DetectorBinning',                                              i = find( GROUP ==    24 & ELEME == 28698 ,1); type = 'DS';
            case 'DetectorElementPhysicalSize',                                  i = find( GROUP ==    24 & ELEME == 28704 ,1); type = 'DS';
            case 'DetectorElementSpacing',                                       i = find( GROUP ==    24 & ELEME == 28706 ,1); type = 'DS';
            case 'DetectorActiveShape',                                          i = find( GROUP ==    24 & ELEME == 28708 ,1); type = 'CS';
            case 'DetectorActiveDimensions',                                     i = find( GROUP ==    24 & ELEME == 28710 ,1); type = 'DS';
            case 'DetectorActiveOrigin',                                         i = find( GROUP ==    24 & ELEME == 28712 ,1); type = 'DS';
            case 'DetectorManufacturerName',                                     i = find( GROUP ==    24 & ELEME == 28714 ,1); type = 'LO';
            case 'DetectorManufacturerModelName',                                i = find( GROUP ==    24 & ELEME == 28715 ,1); type = 'LO';
            case 'FieldOfViewOrigin',                                            i = find( GROUP ==    24 & ELEME == 28720 ,1); type = 'DS';
            case 'FieldOfViewRotation',                                          i = find( GROUP ==    24 & ELEME == 28722 ,1); type = 'DS';
            case 'FieldOfViewHorizontalFlip',                                    i = find( GROUP ==    24 & ELEME == 28724 ,1); type = 'CS';
            case 'GridAbsorbingMaterial',                                        i = find( GROUP ==    24 & ELEME == 28736 ,1); type = 'LT';
            case 'GridSpacingMaterial',                                          i = find( GROUP ==    24 & ELEME == 28737 ,1); type = 'LT';
            case 'GridThickness',                                                i = find( GROUP ==    24 & ELEME == 28738 ,1); type = 'DS';
            case 'GridPitch',                                                    i = find( GROUP ==    24 & ELEME == 28740 ,1); type = 'DS';
            case 'GridAspectRatio',                                              i = find( GROUP ==    24 & ELEME == 28742 ,1); type = 'IS';
            case 'GridPeriod',                                                   i = find( GROUP ==    24 & ELEME == 28744 ,1); type = 'DS';
            case 'GridFocalDistance',                                            i = find( GROUP ==    24 & ELEME == 28748 ,1); type = 'DS';
            case 'FilterMaterial',                                               i = find( GROUP ==    24 & ELEME == 28752 ,1); type = 'CS';
            case 'FilterThicknessMinimum',                                       i = find( GROUP ==    24 & ELEME == 28754 ,1); type = 'DS';
            case 'FilterThicknessMaximum',                                       i = find( GROUP ==    24 & ELEME == 28756 ,1); type = 'DS';
            case 'ExposureControlMode',                                          i = find( GROUP ==    24 & ELEME == 28768 ,1); type = 'CS';
            case 'ExposureControlModeDescription',                               i = find( GROUP ==    24 & ELEME == 28770 ,1); type = 'LT';
            case 'ExposureStatus',                                               i = find( GROUP ==    24 & ELEME == 28772 ,1); type = 'CS';
            case 'PhototimerSetting',                                            i = find( GROUP ==    24 & ELEME == 28773 ,1); type = 'DS';
            case 'ExposureTimeInuS',                                             i = find( GROUP ==    24 & ELEME == 33104 ,1); type = 'DS';
            case 'XrayTubeCurrentInuA',                                          i = find( GROUP ==    24 & ELEME == 33105 ,1); type = 'DS';
            case 'ContentQualification',                                         i = find( GROUP ==    24 & ELEME == 36868 ,1); type = 'CS';
            case 'PulseSequenceName',                                            i = find( GROUP ==    24 & ELEME == 36869 ,1); type = 'SH';
            case 'MRImagingModifierSequence',                                    i = find( GROUP ==    24 & ELEME == 36870 ,1); type = 'SQ';
            case 'EchoPulseSequence',                                            i = find( GROUP ==    24 & ELEME == 36872 ,1); type = 'CS';
            case 'InversionRecovery',                                            i = find( GROUP ==    24 & ELEME == 36873 ,1); type = 'CS';
            case 'FlowCompensation',                                             i = find( GROUP ==    24 & ELEME == 36880 ,1); type = 'CS';
            case 'MultipleSpinEcho',                                             i = find( GROUP ==    24 & ELEME == 36881 ,1); type = 'CS';
            case 'MultiplanarExcitation',                                        i = find( GROUP ==    24 & ELEME == 36882 ,1); type = 'CS';
            case 'PhaseContrast',                                                i = find( GROUP ==    24 & ELEME == 36884 ,1); type = 'CS';
            case 'TimeOfFlightContrast',                                         i = find( GROUP ==    24 & ELEME == 36885 ,1); type = 'CS';
            case 'Spoiling',                                                     i = find( GROUP ==    24 & ELEME == 36886 ,1); type = 'CS';
            case 'SteadyStatePulseSequence',                                     i = find( GROUP ==    24 & ELEME == 36887 ,1); type = 'CS';
            case 'EchoPlanarPulseSequence',                                      i = find( GROUP ==    24 & ELEME == 36888 ,1); type = 'CS';
            case 'TagAngleFirstAxis',                                            i = find( GROUP ==    24 & ELEME == 36889 ,1); type = 'FD';
            case 'MagnetizationTransfer',                                        i = find( GROUP ==    24 & ELEME == 36896 ,1); type = 'CS';
            case 'T2Preparation',                                                i = find( GROUP ==    24 & ELEME == 36897 ,1); type = 'CS';
            case 'BloodSignalNulling',                                           i = find( GROUP ==    24 & ELEME == 36898 ,1); type = 'CS';
            case 'SaturationRecovery',                                           i = find( GROUP ==    24 & ELEME == 36900 ,1); type = 'CS';
            case 'SpectrallySelectedSuppression',                                i = find( GROUP ==    24 & ELEME == 36901 ,1); type = 'CS';
            case 'SpectrallySelectedExcitation',                                 i = find( GROUP ==    24 & ELEME == 36902 ,1); type = 'CS';
            case 'SpatialPresaturation',                                         i = find( GROUP ==    24 & ELEME == 36903 ,1); type = 'CS';
            case 'Tagging',                                                      i = find( GROUP ==    24 & ELEME == 36904 ,1); type = 'CS';
            case 'OversamplingPhase',                                            i = find( GROUP ==    24 & ELEME == 36905 ,1); type = 'CS';
            case 'TagSpacingFirstDimension',                                     i = find( GROUP ==    24 & ELEME == 36912 ,1); type = 'FD';
            case 'GeometryOfKSpaceTraversal',                                    i = find( GROUP ==    24 & ELEME == 36914 ,1); type = 'CS';
            case 'SegmentedKSpaceTraversal',                                     i = find( GROUP ==    24 & ELEME == 36915 ,1); type = 'CS';
            case 'RectilinearPhaseEncodeReordering',                             i = find( GROUP ==    24 & ELEME == 36916 ,1); type = 'CS';
            case 'TagThickness',                                                 i = find( GROUP ==    24 & ELEME == 36917 ,1); type = 'FD';
            case 'PartialFourierDirection',                                      i = find( GROUP ==    24 & ELEME == 36918 ,1); type = 'CS';
            case 'CardiacSynchronizationTechnique',                              i = find( GROUP ==    24 & ELEME == 36919 ,1); type = 'CS';
            case 'ReceiveCoilManufacturerName',                                  i = find( GROUP ==    24 & ELEME == 36929 ,1); type = 'LO';
            case 'MRReceiveCoilSequence',                                        i = find( GROUP ==    24 & ELEME == 36930 ,1); type = 'SQ';
            case 'ReceiveCoilType',                                              i = find( GROUP ==    24 & ELEME == 36931 ,1); type = 'CS';
            case 'QuadratureReceiveCoil',                                        i = find( GROUP ==    24 & ELEME == 36932 ,1); type = 'CS';
            case 'MultiCoilDefinitionSequence',                                  i = find( GROUP ==    24 & ELEME == 36933 ,1); type = 'SQ';
            case 'MultiCoilConfiguration',                                       i = find( GROUP ==    24 & ELEME == 36934 ,1); type = 'LO';
            case 'MultiCoilElementName',                                         i = find( GROUP ==    24 & ELEME == 36935 ,1); type = 'SH';
            case 'MultiCoilElementUsed',                                         i = find( GROUP ==    24 & ELEME == 36936 ,1); type = 'CS';
            case 'MRTransmitCoilSequence',                                       i = find( GROUP ==    24 & ELEME == 36937 ,1); type = 'SQ';
            case 'TransmitCoilManufacturerName',                                 i = find( GROUP ==    24 & ELEME == 36944 ,1); type = 'LO';
            case 'TransmitCoilType',                                             i = find( GROUP ==    24 & ELEME == 36945 ,1); type = 'CS';
            case 'SpectralWidth',                                                i = find( GROUP ==    24 & ELEME == 36946 ,1); type = 'FD';
            case 'ChemicalShiftReference',                                       i = find( GROUP ==    24 & ELEME == 36947 ,1); type = 'FD';
            case 'VolumeLocalizationTechnique',                                  i = find( GROUP ==    24 & ELEME == 36948 ,1); type = 'CS';
            case 'MRAcquisitionFrequencyEncodingSteps',                          i = find( GROUP ==    24 & ELEME == 36952 ,1); type = 'US';
            case 'Decoupling',                                                   i = find( GROUP ==    24 & ELEME == 36953 ,1); type = 'CS';
            case 'DecoupledNucleus',                                             i = find( GROUP ==    24 & ELEME == 36960 ,1); type = 'CS';
            case 'DecouplingFrequency',                                          i = find( GROUP ==    24 & ELEME == 36961 ,1); type = 'FD';
            case 'DecouplingMethod',                                             i = find( GROUP ==    24 & ELEME == 36962 ,1); type = 'CS';
            case 'DecouplingChemicalShiftReference',                             i = find( GROUP ==    24 & ELEME == 36963 ,1); type = 'FD';
            case 'KSpaceFiltering',                                              i = find( GROUP ==    24 & ELEME == 36964 ,1); type = 'CS';
            case 'TimeDomainFiltering',                                          i = find( GROUP ==    24 & ELEME == 36965 ,1); type = 'CS';
            case 'NumberOfZeroFills',                                            i = find( GROUP ==    24 & ELEME == 36966 ,1); type = 'US';
            case 'BaselineCorrection',                                           i = find( GROUP ==    24 & ELEME == 36967 ,1); type = 'CS';
            case 'ParallelReductionFactorInPlane',                               i = find( GROUP ==    24 & ELEME == 36969 ,1); type = 'FD';
            case 'CardiacRRIntervalSpecified',                                   i = find( GROUP ==    24 & ELEME == 36976 ,1); type = 'FD';
            case 'AcquisitionDuration',                                          i = find( GROUP ==    24 & ELEME == 36979 ,1); type = 'FD';
            case 'FrameAcquisitionDatetime',                                     i = find( GROUP ==    24 & ELEME == 36980 ,1); type = 'DT';
            case 'DiffusionDirectionality',                                      i = find( GROUP ==    24 & ELEME == 36981 ,1); type = 'CS';
            case 'DiffusionGradientDirectionSequence',                           i = find( GROUP ==    24 & ELEME == 36982 ,1); type = 'SQ';
            case 'ParallelAcquisition',                                          i = find( GROUP ==    24 & ELEME == 36983 ,1); type = 'CS';
            case 'ParallelAcquisitionTechnique',                                 i = find( GROUP ==    24 & ELEME == 36984 ,1); type = 'CS';
            case 'InversionTimes',                                               i = find( GROUP ==    24 & ELEME == 36985 ,1); type = 'FD';
            case 'MetaboliteMapDescription',                                     i = find( GROUP ==    24 & ELEME == 36992 ,1); type = 'ST';
            case 'PartialFourier',                                               i = find( GROUP ==    24 & ELEME == 36993 ,1); type = 'CS';
            case 'EffectiveEchoTime',                                            i = find( GROUP ==    24 & ELEME == 36994 ,1); type = 'FD';
            case 'MetaboliteCodeSequence',                                       i = find( GROUP ==    24 & ELEME == 36995 ,1); type = 'SQ';
            case 'ChemicalShiftSequence',                                        i = find( GROUP ==    24 & ELEME == 36996 ,1); type = 'SQ';
            case 'CardiacSignalSource',                                          i = find( GROUP ==    24 & ELEME == 36997 ,1); type = 'CS';
            case 'DiffusionBValue',                                              i = find( GROUP ==    24 & ELEME == 36999 ,1); type = 'FD';
            case 'DiffusionGradientOrientation',                                 i = find( GROUP ==    24 & ELEME == 37001 ,1); type = 'FD';
            case 'VelocityEncodingDirection',                                    i = find( GROUP ==    24 & ELEME == 37008 ,1); type = 'FD';
            case 'VelocityEncodingMinimumValue',                                 i = find( GROUP ==    24 & ELEME == 37009 ,1); type = 'FD';
            case 'NumberOfKSpaceTrajectories',                                   i = find( GROUP ==    24 & ELEME == 37011 ,1); type = 'US';
            case 'CoverageOfKSpace',                                             i = find( GROUP ==    24 & ELEME == 37012 ,1); type = 'CS';
            case 'SpectroscopyAcquisitionPhaseRows',                             i = find( GROUP ==    24 & ELEME == 37013 ,1); type = 'UL';
            case 'TransmitterFrequency',                                         i = find( GROUP ==    24 & ELEME == 37016 ,1); type = 'FD';
            case 'ResonantNucleus',                                              i = find( GROUP ==    24 & ELEME == 37120 ,1); type = 'CS';
            case 'FrequencyCorrection',                                          i = find( GROUP ==    24 & ELEME == 37121 ,1); type = 'CS';
            case 'MRSpectroscopyFOVGeometrySequence',                            i = find( GROUP ==    24 & ELEME == 37123 ,1); type = 'SQ';
            case 'SlabThickness',                                                i = find( GROUP ==    24 & ELEME == 37124 ,1); type = 'FD';
            case 'SlabOrientation',                                              i = find( GROUP ==    24 & ELEME == 37125 ,1); type = 'FD';
            case 'MidSlabPosition',                                              i = find( GROUP ==    24 & ELEME == 37126 ,1); type = 'FD';
            case 'MRSpatialSaturationSequence',                                  i = find( GROUP ==    24 & ELEME == 37127 ,1); type = 'SQ';
            case 'MRTimingAndRelatedParametersSequence',                         i = find( GROUP ==    24 & ELEME == 37138 ,1); type = 'SQ';
            case 'MREchoSequence',                                               i = find( GROUP ==    24 & ELEME == 37140 ,1); type = 'SQ';
            case 'MRModifierSequence',                                           i = find( GROUP ==    24 & ELEME == 37141 ,1); type = 'SQ';
            case 'MRDiffusionSequence',                                          i = find( GROUP ==    24 & ELEME == 37143 ,1); type = 'SQ';
            case 'CardiacTriggerSequence',                                       i = find( GROUP ==    24 & ELEME == 37144 ,1); type = 'SQ';
            case 'MRAveragesSequence',                                           i = find( GROUP ==    24 & ELEME == 37145 ,1); type = 'SQ';
            case 'MRFOVGeometrySequence',                                        i = find( GROUP ==    24 & ELEME == 37157 ,1); type = 'SQ';
            case 'VolumeLocalizationSequence',                                   i = find( GROUP ==    24 & ELEME == 37158 ,1); type = 'SQ';
            case 'SpectroscopyAcquisitionDataColumns',                           i = find( GROUP ==    24 & ELEME == 37159 ,1); type = 'UL';
            case 'DiffusionAnisotropyType',                                      i = find( GROUP ==    24 & ELEME == 37191 ,1); type = 'CS';
            case 'FrameReferenceDatetime',                                       i = find( GROUP ==    24 & ELEME == 37201 ,1); type = 'DT';
            case 'MRMetaboliteMapSequence',                                      i = find( GROUP ==    24 & ELEME == 37202 ,1); type = 'SQ';
            case 'ParallelReductionFactorOutOfPlane',                            i = find( GROUP ==    24 & ELEME == 37205 ,1); type = 'FD';
            case 'SpectroscopyAcquisitionOutOfPlanePhaseSteps',                  i = find( GROUP ==    24 & ELEME == 37209 ,1); type = 'UL';
            case 'BulkMotionStatus',                                             i = find( GROUP ==    24 & ELEME == 37222 ,1); type = 'CS';
            case 'ParallelReductionFactorSecondInPlane',                         i = find( GROUP ==    24 & ELEME == 37224 ,1); type = 'FD';
            case 'CardiacBeatRejectionTechnique',                                i = find( GROUP ==    24 & ELEME == 37225 ,1); type = 'CS';
            case 'RespiratoryMotionCompensationTechnique',                       i = find( GROUP ==    24 & ELEME == 37232 ,1); type = 'CS';
            case 'RespiratorySignalSource',                                      i = find( GROUP ==    24 & ELEME == 37233 ,1); type = 'CS';
            case 'BulkMotionCompensationTechnique',                              i = find( GROUP ==    24 & ELEME == 37234 ,1); type = 'CS';
            case 'BulkMotionSignalSource',                                       i = find( GROUP ==    24 & ELEME == 37235 ,1); type = 'CS';
            case 'ApplicableSafetyStandardAgency',                               i = find( GROUP ==    24 & ELEME == 37236 ,1); type = 'CS';
            case 'ApplicableSafetyStandardDescription',                          i = find( GROUP ==    24 & ELEME == 37237 ,1); type = 'LO';
            case 'OperatingModeSequence',                                        i = find( GROUP ==    24 & ELEME == 37238 ,1); type = 'SQ';
            case 'OperatingModeType',                                            i = find( GROUP ==    24 & ELEME == 37239 ,1); type = 'CS';
            case 'OperatingMode',                                                i = find( GROUP ==    24 & ELEME == 37240 ,1); type = 'CS';
            case 'SpecificAbsorptionRateDefinition',                             i = find( GROUP ==    24 & ELEME == 37241 ,1); type = 'CS';
            case 'GradientOutputType',                                           i = find( GROUP ==    24 & ELEME == 37248 ,1); type = 'CS';
            case 'SpecificAbsorptionRateValue',                                  i = find( GROUP ==    24 & ELEME == 37249 ,1); type = 'FD';
            case 'GradientOutput',                                               i = find( GROUP ==    24 & ELEME == 37250 ,1); type = 'FD';
            case 'FlowCompensationDirection',                                    i = find( GROUP ==    24 & ELEME == 37251 ,1); type = 'CS';
            case 'TaggingDelay',                                                 i = find( GROUP ==    24 & ELEME == 37252 ,1); type = 'FD';
            case 'ChemicalShiftMinimumIntegrationLimitInHz',                     i = find( GROUP ==    24 & ELEME == 37269 ,1); type = 'FD';
            case 'ChemicalShiftMaximumIntegrationLimitInHz',                     i = find( GROUP ==    24 & ELEME == 37270 ,1); type = 'FD';
            case 'MRVelocityEncodingSequence',                                   i = find( GROUP ==    24 & ELEME == 37271 ,1); type = 'SQ';
            case 'FirstOrderPhaseCorrection',                                    i = find( GROUP ==    24 & ELEME == 37272 ,1); type = 'CS';
            case 'WaterReferencedPhaseCorrection',                               i = find( GROUP ==    24 & ELEME == 37273 ,1); type = 'CS';
            case 'MRSpectroscopyAcquisitionType',                                i = find( GROUP ==    24 & ELEME == 37376 ,1); type = 'CS';
            case 'RespiratoryCyclePosition',                                     i = find( GROUP ==    24 & ELEME == 37396 ,1); type = 'CS';
            case 'VelocityEncodingMaximumValue',                                 i = find( GROUP ==    24 & ELEME == 37399 ,1); type = 'FD';
            case 'TagSpacingSecondDimension',                                    i = find( GROUP ==    24 & ELEME == 37400 ,1); type = 'FD';
            case 'TagAngleSecondAxis',                                           i = find( GROUP ==    24 & ELEME == 37401 ,1); type = 'SS';
            case 'FrameAcquisitionDuration',                                     i = find( GROUP ==    24 & ELEME == 37408 ,1); type = 'FD';
            case 'MRImageFrameTypeSequence',                                     i = find( GROUP ==    24 & ELEME == 37414 ,1); type = 'SQ';
            case 'MRSpectroscopyFrameTypeSequence',                              i = find( GROUP ==    24 & ELEME == 37415 ,1); type = 'SQ';
            case 'MRAcquisitionPhaseEncodingStepsInPlane',                       i = find( GROUP ==    24 & ELEME == 37425 ,1); type = 'US';
            case 'MRAcquisitionPhaseEncodingStepsOutOfPlane',                    i = find( GROUP ==    24 & ELEME == 37426 ,1); type = 'US';
            case 'SpectroscopyAcquisitionPhaseColumns',                          i = find( GROUP ==    24 & ELEME == 37428 ,1); type = 'UL';
            case 'CardiacCyclePosition',                                         i = find( GROUP ==    24 & ELEME == 37430 ,1); type = 'CS';
            case 'SpecificAbsorptionRateSequence',                               i = find( GROUP ==    24 & ELEME == 37433 ,1); type = 'SQ';
            case 'RFEchoTrainLength',                                            i = find( GROUP ==    24 & ELEME == 37440 ,1); type = 'US';
            case 'GradientEchoTrainLength',                                      i = find( GROUP ==    24 & ELEME == 37441 ,1); type = 'US';
            case 'ChemicalShiftMinimumIntegrationLimitInPPM',                    i = find( GROUP ==    24 & ELEME == 37525 ,1); type = 'FD';
            case 'ChemicalShiftMaximumIntegrationLimitInPPM',                    i = find( GROUP ==    24 & ELEME == 37526 ,1); type = 'FD';
            case 'CTAcquisitionTypeSequence',                                    i = find( GROUP ==    24 & ELEME == 37633 ,1); type = 'SQ';
            case 'AcquisitionType',                                              i = find( GROUP ==    24 & ELEME == 37634 ,1); type = 'CS';
            case 'TubeAngle',                                                    i = find( GROUP ==    24 & ELEME == 37635 ,1); type = 'FD';
            case 'CTAcquisitionDetailsSequence',                                 i = find( GROUP ==    24 & ELEME == 37636 ,1); type = 'SQ';
            case 'RevolutionTime',                                               i = find( GROUP ==    24 & ELEME == 37637 ,1); type = 'FD';
            case 'SingleCollimationWidth',                                       i = find( GROUP ==    24 & ELEME == 37638 ,1); type = 'FD';
            case 'TotalCollimationWidth',                                        i = find( GROUP ==    24 & ELEME == 37639 ,1); type = 'FD';
            case 'CTTableDynamicsSequence',                                      i = find( GROUP ==    24 & ELEME == 37640 ,1); type = 'SQ';
            case 'TableSpeed',                                                   i = find( GROUP ==    24 & ELEME == 37641 ,1); type = 'FD';
            case 'TableFeedPerRotation',                                         i = find( GROUP ==    24 & ELEME == 37648 ,1); type = 'FD';
            case 'SpiralPitchFactor',                                            i = find( GROUP ==    24 & ELEME == 37649 ,1); type = 'FD';
            case 'CTGeometrySequence',                                           i = find( GROUP ==    24 & ELEME == 37650 ,1); type = 'SQ';
            case 'DataCollectionCenterPatient',                                  i = find( GROUP ==    24 & ELEME == 37651 ,1); type = 'FD';
            case 'CTReconstructionSequence',                                     i = find( GROUP ==    24 & ELEME == 37652 ,1); type = 'SQ';
            case 'ReconstructionAlgorithm',                                      i = find( GROUP ==    24 & ELEME == 37653 ,1); type = 'CS';
            case 'ConvolutionKernelGroup',                                       i = find( GROUP ==    24 & ELEME == 37654 ,1); type = 'CS';
            case 'ReconstructionFieldOfView',                                    i = find( GROUP ==    24 & ELEME == 37655 ,1); type = 'FD';
            case 'ReconstructionTargetCenterPatient',                            i = find( GROUP ==    24 & ELEME == 37656 ,1); type = 'FD';
            case 'ReconstructionAngle',                                          i = find( GROUP ==    24 & ELEME == 37657 ,1); type = 'FD';
            case 'ImageFilter',                                                  i = find( GROUP ==    24 & ELEME == 37664 ,1); type = 'SH';
            case 'CTExposureSequence',                                           i = find( GROUP ==    24 & ELEME == 37665 ,1); type = 'SQ';
            case 'ReconstructionPixelSpacing',                                   i = find( GROUP ==    24 & ELEME == 37666 ,1); type = 'FD';
            case 'ExposureModulationType',                                       i = find( GROUP ==    24 & ELEME == 37667 ,1); type = 'CS';
            case 'EstimatedDoseSaving',                                          i = find( GROUP ==    24 & ELEME == 37668 ,1); type = 'FD';
            case 'CTXrayDetailsSequence',                                        i = find( GROUP ==    24 & ELEME == 37669 ,1); type = 'SQ';
            case 'CTPositionSequence',                                           i = find( GROUP ==    24 & ELEME == 37670 ,1); type = 'SQ';
            case 'TablePosition',                                                i = find( GROUP ==    24 & ELEME == 37671 ,1); type = 'FD';
            case 'ExposureTimeInms',                                             i = find( GROUP ==    24 & ELEME == 37672 ,1); type = 'FD';
            case 'CTImageFrameTypeSequence',                                     i = find( GROUP ==    24 & ELEME == 37673 ,1); type = 'SQ';
            case 'XrayTubeCurrentInmA',                                          i = find( GROUP ==    24 & ELEME == 37680 ,1); type = 'FD';
            case 'ExposureInmAs',                                                i = find( GROUP ==    24 & ELEME == 37682 ,1); type = 'FD';
            case 'ConstantVolumeFlag',                                           i = find( GROUP ==    24 & ELEME == 37683 ,1); type = 'CS';
            case 'FluoroscopyFlag',                                              i = find( GROUP ==    24 & ELEME == 37684 ,1); type = 'CS';
            case 'DistanceSourceToDataCollectionCenter',                         i = find( GROUP ==    24 & ELEME == 37685 ,1); type = 'FD';
            case 'ContrastBolusAgentNumber',                                     i = find( GROUP ==    24 & ELEME == 37687 ,1); type = 'US';
            case 'ContrastBolusIngredientCodeSequence',                          i = find( GROUP ==    24 & ELEME == 37688 ,1); type = 'SQ';
            case 'ContrastAdministrationProfileSequence',                        i = find( GROUP ==    24 & ELEME == 37696 ,1); type = 'SQ';
            case 'ContrastBolusUsageSequence',                                   i = find( GROUP ==    24 & ELEME == 37697 ,1); type = 'SQ';
            case 'ContrastBolusAgentAdministered',                               i = find( GROUP ==    24 & ELEME == 37698 ,1); type = 'CS';
            case 'ContrastBolusAgentDetected',                                   i = find( GROUP ==    24 & ELEME == 37699 ,1); type = 'CS';
            case 'ContrastBolusAgentPhase',                                      i = find( GROUP ==    24 & ELEME == 37700 ,1); type = 'CS';
            case 'CTDIVol',                                                      i = find( GROUP ==    24 & ELEME == 37701 ,1); type = 'FD';
            case 'ContributingEquipmentSequence',                                i = find( GROUP ==    24 & ELEME == 40961 ,1); type = 'SQ';
            case 'ContributionDateTime',                                         i = find( GROUP ==    24 & ELEME == 40962 ,1); type = 'DT';
            case 'ContributionDescription',                                      i = find( GROUP ==    24 & ELEME == 40963 ,1); type = 'ST';
            case 'RelationshipGroupLength',                                      i = find( GROUP ==    32 & ELEME ==     0 ,1); type = 'UL';
            case 'StudyInstanceUID',                                             i = find( GROUP ==    32 & ELEME ==    13 ,1); type = 'UI';
            case 'SeriesInstanceUID',                                            i = find( GROUP ==    32 & ELEME ==    14 ,1); type = 'UI';
            case 'StudyID',                                                      i = find( GROUP ==    32 & ELEME ==    16 ,1); type = 'SH';
            case 'SeriesNumber',                                                 i = find( GROUP ==    32 & ELEME ==    17 ,1); type = 'IS';
            case 'AcquisitionNumber',                                            i = find( GROUP ==    32 & ELEME ==    18 ,1); type = 'IS';
            case 'InstanceNumber',                                               i = find( GROUP ==    32 & ELEME ==    19 ,1); type = 'IS';
            case 'IsotopeNumber',                                                i = find( GROUP ==    32 & ELEME ==    20 ,1); type = 'IS';
            case 'PhaseNumber',                                                  i = find( GROUP ==    32 & ELEME ==    21 ,1); type = 'IS';
            case 'IntervalNumber',                                               i = find( GROUP ==    32 & ELEME ==    22 ,1); type = 'IS';
            case 'TimeSlotNumber',                                               i = find( GROUP ==    32 & ELEME ==    23 ,1); type = 'IS';
            case 'AngleNumber',                                                  i = find( GROUP ==    32 & ELEME ==    24 ,1); type = 'IS';
            case 'ItemNumber',                                                   i = find( GROUP ==    32 & ELEME ==    25 ,1); type = 'IS';
            case 'PatientOrientation',                                           i = find( GROUP ==    32 & ELEME ==    32 ,1); type = 'CS';
            case 'OverlayNumber',                                                i = find( GROUP ==    32 & ELEME ==    34 ,1); type = 'IS';
            case 'CurveNumber',                                                  i = find( GROUP ==    32 & ELEME ==    36 ,1); type = 'IS';
            case 'LUTNumber',                                                    i = find( GROUP ==    32 & ELEME ==    38 ,1); type = 'IS';
            case 'ImagePosition',                                                i = find( GROUP ==    32 & ELEME ==    48 ,1); type = 'DS';
            case 'ImagePositionPatient',                                         i = find( GROUP ==    32 & ELEME ==    50 ,1); type = 'DS';
            case 'ImageOrientation',                                             i = find( GROUP ==    32 & ELEME ==    53 ,1); type = 'DS';
            case 'ImageOrientationPatient',                                      i = find( GROUP ==    32 & ELEME ==    55 ,1); type = 'DS';
            case 'Location',                                                     i = find( GROUP ==    32 & ELEME ==    80 ,1); type = 'DS';
            case 'FrameOfReferenceUID',                                          i = find( GROUP ==    32 & ELEME ==    82 ,1); type = 'UI';
            case 'Laterality',                                                   i = find( GROUP ==    32 & ELEME ==    96 ,1); type = 'CS';
            case 'ImageLaterality',                                              i = find( GROUP ==    32 & ELEME ==    98 ,1); type = 'CS';
            case 'ImageGeometryType',                                            i = find( GROUP ==    32 & ELEME ==   112 ,1); type = 'LT';
            case 'MaskingImage',                                                 i = find( GROUP ==    32 & ELEME ==   128 ,1); type = 'CS';
            case 'TemporalPositionIdentifier',                                   i = find( GROUP ==    32 & ELEME ==   256 ,1); type = 'IS';
            case 'NumberOfTemporalPositions',                                    i = find( GROUP ==    32 & ELEME ==   261 ,1); type = 'IS';
            case 'TemporalResolution',                                           i = find( GROUP ==    32 & ELEME ==   272 ,1); type = 'DS';
            case 'SynchronizationFrameOfReferenceUID',                           i = find( GROUP ==    32 & ELEME ==   512 ,1); type = 'UI';
            case 'SeriesInStudy',                                                i = find( GROUP ==    32 & ELEME ==  4096 ,1); type = 'IS';
            case 'AcquisitionsInSeries',                                         i = find( GROUP ==    32 & ELEME ==  4097 ,1); type = 'IS';
            case 'ImagesInAcquisition',                                          i = find( GROUP ==    32 & ELEME ==  4098 ,1); type = 'IS';
            case 'ImagesInSeries',                                               i = find( GROUP ==    32 & ELEME ==  4099 ,1); type = 'IS';
            case 'AcquisitionsInStudy',                                          i = find( GROUP ==    32 & ELEME ==  4100 ,1); type = 'IS';
            case 'ImagesInStudy',                                                i = find( GROUP ==    32 & ELEME ==  4101 ,1); type = 'IS';
            case 'Reference',                                                    i = find( GROUP ==    32 & ELEME ==  4128 ,1); type = 'CS';
            case 'PositionReferenceIndicator',                                   i = find( GROUP ==    32 & ELEME ==  4160 ,1); type = 'LO';
            case 'SliceLocation',                                                i = find( GROUP ==    32 & ELEME ==  4161 ,1); type = 'DS';
            case 'OtherStudyNumbers',                                            i = find( GROUP ==    32 & ELEME ==  4208 ,1); type = 'IS';
            case 'NumberOfPatientRelatedStudies',                                i = find( GROUP ==    32 & ELEME ==  4608 ,1); type = 'IS';
            case 'NumberOfPatientRelatedSeries',                                 i = find( GROUP ==    32 & ELEME ==  4610 ,1); type = 'IS';
            case 'NumberOfPatientRelatedInstances',                              i = find( GROUP ==    32 & ELEME ==  4612 ,1); type = 'IS';
            case 'NumberOfStudyRelatedSeries',                                   i = find( GROUP ==    32 & ELEME ==  4614 ,1); type = 'IS';
            case 'NumberOfStudyRelatedInstances',                                i = find( GROUP ==    32 & ELEME ==  4616 ,1); type = 'IS';
            case 'NumberOfSeriesRelatedInstances',                               i = find( GROUP ==    32 & ELEME ==  4617 ,1); type = 'IS';
            case 'ModifyingDeviceID',                                            i = find( GROUP ==    32 & ELEME == 13313 ,1); type = 'CS';
            case 'ModifiedImageID',                                              i = find( GROUP ==    32 & ELEME == 13314 ,1); type = 'CS';
            case 'ModifiedImageDate',                                            i = find( GROUP ==    32 & ELEME == 13315 ,1); type = 'DA';
            case 'ModifyingDeviceManufacturer',                                  i = find( GROUP ==    32 & ELEME == 13316 ,1); type = 'LO';
            case 'ModifiedImageTime',                                            i = find( GROUP ==    32 & ELEME == 13317 ,1); type = 'TM';
            case 'ModifiedImageDescription',                                     i = find( GROUP ==    32 & ELEME == 13318 ,1); type = 'LT';
            case 'ImageComments',                                                i = find( GROUP ==    32 & ELEME == 16384 ,1); type = 'LT';
            case 'OriginalImageIdentification',                                  i = find( GROUP ==    32 & ELEME == 20480 ,1); type = 'AT';
            case 'OriginalImageIdentificationNomenclature',                      i = find( GROUP ==    32 & ELEME == 20482 ,1); type = 'CS';
            case 'StackID',                                                      i = find( GROUP ==    32 & ELEME == 36950 ,1); type = 'SH';
            case 'InStackPositionNumber',                                        i = find( GROUP ==    32 & ELEME == 36951 ,1); type = 'UL';
            case 'FrameAnatomySequence',                                         i = find( GROUP ==    32 & ELEME == 36977 ,1); type = 'SQ';
            case 'FrameLaterality',                                              i = find( GROUP ==    32 & ELEME == 36978 ,1); type = 'CS';
            case 'FrameContentSequence',                                         i = find( GROUP ==    32 & ELEME == 37137 ,1); type = 'SQ';
            case 'PlanePositionSequence',                                        i = find( GROUP ==    32 & ELEME == 37139 ,1); type = 'SQ';
            case 'PlaneOrientationSequence',                                     i = find( GROUP ==    32 & ELEME == 37142 ,1); type = 'SQ';
            case 'TemporalPositionIndex',                                        i = find( GROUP ==    32 & ELEME == 37160 ,1); type = 'UL';
            case 'TriggerDelayTime',                                             i = find( GROUP ==    32 & ELEME == 37203 ,1); type = 'FD';
            case 'FrameAcquisitionNumber',                                       i = find( GROUP ==    32 & ELEME == 37206 ,1); type = 'US';
            case 'DimensionIndexValues',                                         i = find( GROUP ==    32 & ELEME == 37207 ,1); type = 'UL';
            case 'FrameComments',                                                i = find( GROUP ==    32 & ELEME == 37208 ,1); type = 'LT';
            case 'ConcatenationUID',                                             i = find( GROUP ==    32 & ELEME == 37217 ,1); type = 'UI';
            case 'InConcatenationNumber',                                        i = find( GROUP ==    32 & ELEME == 37218 ,1); type = 'US';
            case 'InConcatenationTotalNumber',                                   i = find( GROUP ==    32 & ELEME == 37219 ,1); type = 'US';
            case 'DimensionOrganizationUID',                                     i = find( GROUP ==    32 & ELEME == 37220 ,1); type = 'UI';
            case 'DimensionIndexPointer',                                        i = find( GROUP ==    32 & ELEME == 37221 ,1); type = 'AT';
            case 'FunctionalGroupPointer',                                       i = find( GROUP ==    32 & ELEME == 37223 ,1); type = 'AT';
            case 'DimensionIndexPrivateCreator',                                 i = find( GROUP ==    32 & ELEME == 37395 ,1); type = 'LO';
            case 'DimensionOrganizationSequence',                                i = find( GROUP ==    32 & ELEME == 37409 ,1); type = 'SQ';
            case 'DimensionIndexSequence',                                       i = find( GROUP ==    32 & ELEME == 37410 ,1); type = 'SQ';
            case 'ConcatenationFrameOffsetNumber',                               i = find( GROUP ==    32 & ELEME == 37416 ,1); type = 'UL';
            case 'FunctionalGroupPrivateCreator',                                i = find( GROUP ==    32 & ELEME == 37432 ,1); type = 'LO';
            case 'ImagePresentationGroupLength',                                 i = find( GROUP ==    40 & ELEME ==     0 ,1); type = 'UL';
            case 'SamplesPerPixel',                                              i = find( GROUP ==    40 & ELEME ==     2 ,1); type = 'US';
            case 'PhotometricInterpretation',                                    i = find( GROUP ==    40 & ELEME ==     4 ,1); type = 'CS';
            case 'ImageDimensions',                                              i = find( GROUP ==    40 & ELEME ==     5 ,1); type = 'US';
            case 'PlanarConfiguration',                                          i = find( GROUP ==    40 & ELEME ==     6 ,1); type = 'US';
            case 'NumberOfFrames',                                               i = find( GROUP ==    40 & ELEME ==     8 ,1); type = 'IS';
            case 'FrameIncrementPointer',                                        i = find( GROUP ==    40 & ELEME ==     9 ,1); type = 'AT';
            case 'Rows',                                                         i = find( GROUP ==    40 & ELEME ==    16 ,1); type = 'US';
            case 'Columns',                                                      i = find( GROUP ==    40 & ELEME ==    17 ,1); type = 'US';
            case 'Planes',                                                       i = find( GROUP ==    40 & ELEME ==    18 ,1); type = 'US';
            case 'UltrasoundColorDataPresent',                                   i = find( GROUP ==    40 & ELEME ==    20 ,1); type = 'US';
            case 'PixelSpacing',                                                 i = find( GROUP ==    40 & ELEME ==    48 ,1); type = 'DS';
            case 'ZoomFactor',                                                   i = find( GROUP ==    40 & ELEME ==    49 ,1); type = 'DS';
            case 'ZoomCenter',                                                   i = find( GROUP ==    40 & ELEME ==    50 ,1); type = 'DS';
            case 'PixelAspectRatio',                                             i = find( GROUP ==    40 & ELEME ==    52 ,1); type = 'IS';
            case 'ImageFormat',                                                  i = find( GROUP ==    40 & ELEME ==    64 ,1); type = 'CS';
            case 'ManipulatedImage',                                             i = find( GROUP ==    40 & ELEME ==    80 ,1); type = 'LT';
            case 'CorrectedImage',                                               i = find( GROUP ==    40 & ELEME ==    81 ,1); type = 'CS';
            case 'CompressionRecognitionCode',                                   i = find( GROUP ==    40 & ELEME ==    95 ,1); type = 'CS';
            case 'CompressionCode',                                              i = find( GROUP ==    40 & ELEME ==    96 ,1); type = 'CS';
            case 'CompressionOriginator',                                        i = find( GROUP ==    40 & ELEME ==    97 ,1); type = 'SH';
            case 'CompressionLabel',                                             i = find( GROUP ==    40 & ELEME ==    98 ,1); type = 'SH';
            case 'CompressionDescription',                                       i = find( GROUP ==    40 & ELEME ==    99 ,1); type = 'SH';
            case 'CompressionSequence',                                          i = find( GROUP ==    40 & ELEME ==   101 ,1); type = 'CS';
            case 'CompressionStepPointers',                                      i = find( GROUP ==    40 & ELEME ==   102 ,1); type = 'AT';
            case 'RepeatInterval',                                               i = find( GROUP ==    40 & ELEME ==   104 ,1); type = 'US';
            case 'BitsGrouped',                                                  i = find( GROUP ==    40 & ELEME ==   105 ,1); type = 'US';
            case 'PerimeterTable',                                               i = find( GROUP ==    40 & ELEME ==   112 ,1); type = 'US';
            case 'PredictorRows',                                                i = find( GROUP ==    40 & ELEME ==   128 ,1); type = 'US';
            case 'PredictorColumns',                                             i = find( GROUP ==    40 & ELEME ==   129 ,1); type = 'US';
            case 'PredictorConstants',                                           i = find( GROUP ==    40 & ELEME ==   130 ,1); type = 'US';
            case 'BlockedPixels',                                                i = find( GROUP ==    40 & ELEME ==   144 ,1); type = 'CS';
            case 'BlockRows',                                                    i = find( GROUP ==    40 & ELEME ==   145 ,1); type = 'US';
            case 'BlockColumns',                                                 i = find( GROUP ==    40 & ELEME ==   146 ,1); type = 'US';
            case 'RowOverlap',                                                   i = find( GROUP ==    40 & ELEME ==   147 ,1); type = 'US';
            case 'ColumnOverlap',                                                i = find( GROUP ==    40 & ELEME ==   148 ,1); type = 'US';
            case 'BitsAllocated',                                                i = find( GROUP ==    40 & ELEME ==   256 ,1); type = 'US';
            case 'BitsStored',                                                   i = find( GROUP ==    40 & ELEME ==   257 ,1); type = 'US';
            case 'HighBit',                                                      i = find( GROUP ==    40 & ELEME ==   258 ,1); type = 'US';
            case 'PixelRepresentation',                                          i = find( GROUP ==    40 & ELEME ==   259 ,1); type = 'US';
            case 'ImageLocation',                                                i = find( GROUP ==    40 & ELEME ==   512 ,1); type = 'US';
            case 'QualityControlImage',                                          i = find( GROUP ==    40 & ELEME ==   768 ,1); type = 'CS';
            case 'BurnedInAnnotation',                                           i = find( GROUP ==    40 & ELEME ==   769 ,1); type = 'CS';
            case 'TransformLabel',                                               i = find( GROUP ==    40 & ELEME ==  1024 ,1); type = 'CS';
            case 'TransformVersionNumber',                                       i = find( GROUP ==    40 & ELEME ==  1025 ,1); type = 'CS';
            case 'NumberOfTransformSteps',                                       i = find( GROUP ==    40 & ELEME ==  1026 ,1); type = 'US';
            case 'SequenceOfCompressedData',                                     i = find( GROUP ==    40 & ELEME ==  1027 ,1); type = 'CS';
            case 'DetailsOfCoefficients',                                        i = find( GROUP ==    40 & ELEME ==  1028 ,1); type = 'AT';
            case 'RowsForNthOrderCoefficients',                                  i = find( GROUP ==    40 & ELEME ==  1040 ,1); type = 'US';
            case 'ColumnsForNthOrderCoefficients',                               i = find( GROUP ==    40 & ELEME ==  1041 ,1); type = 'US';
            case 'CoefficientCoding',                                            i = find( GROUP ==    40 & ELEME ==  1042 ,1); type = 'CS';
            case 'CoefficientCodingPointers',                                    i = find( GROUP ==    40 & ELEME ==  1043 ,1); type = 'AT';
            case 'DCTLabel',                                                     i = find( GROUP ==    40 & ELEME ==  1792 ,1); type = 'CS';
            case 'DataBlockDescription',                                         i = find( GROUP ==    40 & ELEME ==  1793 ,1); type = 'CS';
            case 'DataBlock',                                                    i = find( GROUP ==    40 & ELEME ==  1794 ,1); type = 'AT';
            case 'NormalizationFactorFormat',                                    i = find( GROUP ==    40 & ELEME ==  1808 ,1); type = 'US';
            case 'ZonalMapNumberFormat',                                         i = find( GROUP ==    40 & ELEME ==  1824 ,1); type = 'US';
            case 'ZonalMapLocation',                                             i = find( GROUP ==    40 & ELEME ==  1825 ,1); type = 'AT';
            case 'ZonalMapFormat',                                               i = find( GROUP ==    40 & ELEME ==  1826 ,1); type = 'US';
            case 'AdaptiveMapFormat',                                            i = find( GROUP ==    40 & ELEME ==  1840 ,1); type = 'US';
            case 'CodeNumberFormat',                                             i = find( GROUP ==    40 & ELEME ==  1856 ,1); type = 'US';
            case 'CodeLabel',                                                    i = find( GROUP ==    40 & ELEME ==  2048 ,1); type = 'CS';
            case 'NumberOfTables',                                               i = find( GROUP ==    40 & ELEME ==  2050 ,1); type = 'US';
            case 'CodeTableLocation',                                            i = find( GROUP ==    40 & ELEME ==  2051 ,1); type = 'AT';
            case 'BitsForCodeWord',                                              i = find( GROUP ==    40 & ELEME ==  2052 ,1); type = 'US';
            case 'ImageDataLocation',                                            i = find( GROUP ==    40 & ELEME ==  2056 ,1); type = 'AT';
            case 'PixelIntensityRelationship',                                   i = find( GROUP ==    40 & ELEME ==  4160 ,1); type = 'CS';
            case 'PixelIntensityRelationshipSign',                               i = find( GROUP ==    40 & ELEME ==  4161 ,1); type = 'SS';
            case 'WindowCenter',                                                 i = find( GROUP ==    40 & ELEME ==  4176 ,1); type = 'DS';
            case 'WindowWidth',                                                  i = find( GROUP ==    40 & ELEME ==  4177 ,1); type = 'DS';
            case 'RescaleIntercept',                                             i = find( GROUP ==    40 & ELEME ==  4178 ,1); type = 'DS';
            case 'RescaleSlope',                                                 i = find( GROUP ==    40 & ELEME ==  4179 ,1); type = 'DS';
            case 'RescaleType',                                                  i = find( GROUP ==    40 & ELEME ==  4180 ,1); type = 'LO';
            case 'WindowCenterWidthExplanation',                                 i = find( GROUP ==    40 & ELEME ==  4181 ,1); type = 'LO';
            case 'VOILUTFunction',                                               i = find( GROUP ==    40 & ELEME ==  4182 ,1); type = 'CS';
            case 'GrayScale',                                                    i = find( GROUP ==    40 & ELEME ==  4224 ,1); type = 'CS';
            case 'RecommendedViewingMode',                                       i = find( GROUP ==    40 & ELEME ==  4240 ,1); type = 'CS';
            case 'PaletteColorLookupTableUID',                                   i = find( GROUP ==    40 & ELEME ==  4505 ,1); type = 'UI';
            case 'RedPaletteColorLookupTableData',                               i = find( GROUP ==    40 & ELEME ==  4609 ,1); type = 'OW';
            case 'GreenPaletteColorLookupTableData',                             i = find( GROUP ==    40 & ELEME ==  4610 ,1); type = 'OW';
            case 'BluePaletteColorLookupTableData',                              i = find( GROUP ==    40 & ELEME ==  4611 ,1); type = 'OW';
            case 'LargeRedPaletteColorLookupTableData',                          i = find( GROUP ==    40 & ELEME ==  4625 ,1); type = 'OW';
            case 'LargeGreenPaletteColorLookupTableData',                        i = find( GROUP ==    40 & ELEME ==  4626 ,1); type = 'OW';
            case 'LargeBluePaletteColorLookupTableData',                         i = find( GROUP ==    40 & ELEME ==  4627 ,1); type = 'OW';
            case 'LargePaletteColorLookupTableUID',                              i = find( GROUP ==    40 & ELEME ==  4628 ,1); type = 'UI';
            case 'SegmentedRedPaletteColorLookupTableData',                      i = find( GROUP ==    40 & ELEME ==  4641 ,1); type = 'OW';
            case 'SegmentedGreenPaletteColorLookupTableData',                    i = find( GROUP ==    40 & ELEME ==  4642 ,1); type = 'OW';
            case 'SegmentedBluePaletteColorLookupTableData',                     i = find( GROUP ==    40 & ELEME ==  4643 ,1); type = 'OW';
            case 'ImplantPresent',                                               i = find( GROUP ==    40 & ELEME ==  4864 ,1); type = 'CS';
            case 'PartialView',                                                  i = find( GROUP ==    40 & ELEME ==  4944 ,1); type = 'CS';
            case 'PartialViewDescription',                                       i = find( GROUP ==    40 & ELEME ==  4945 ,1); type = 'ST';
            case 'PartialViewCodeSequence',                                      i = find( GROUP ==    40 & ELEME ==  4946 ,1); type = 'SQ';
            case 'LossyImageCompression',                                        i = find( GROUP ==    40 & ELEME ==  8464 ,1); type = 'CS';
            case 'LossyImageCompressionRatio',                                   i = find( GROUP ==    40 & ELEME ==  8466 ,1); type = 'DS';
            case 'LossyImageCompressionMethod',                                  i = find( GROUP ==    40 & ELEME ==  8468 ,1); type = 'CS';
            case 'ModalityLUTSequence',                                          i = find( GROUP ==    40 & ELEME == 12288 ,1); type = 'SQ';
            case 'LUTDescriptor',                                                i = find( GROUP ==    40 & ELEME == 12290 ,1); type = 'US';
            case 'LUTExplanation',                                               i = find( GROUP ==    40 & ELEME == 12291 ,1); type = 'LO';
            case 'ModalityLUTType',                                              i = find( GROUP ==    40 & ELEME == 12292 ,1); type = 'LO';
            case 'VOILUTSequence',                                               i = find( GROUP ==    40 & ELEME == 12304 ,1); type = 'SQ';
            case 'SoftcopyVOILUTSequence',                                       i = find( GROUP ==    40 & ELEME == 12560 ,1); type = 'SQ';
            case 'ImagePresentationComments',                                    i = find( GROUP ==    40 & ELEME == 16384 ,1); type = 'LT';
            case 'BiplaneAcquisitionSequence',                                   i = find( GROUP ==    40 & ELEME == 20480 ,1); type = 'SQ';
            case 'RepresentativeFrameNumber',                                    i = find( GROUP ==    40 & ELEME == 24592 ,1); type = 'US';
            case 'FrameNumbersOfInterest',                                       i = find( GROUP ==    40 & ELEME == 24608 ,1); type = 'US';
            case 'FrameOfInterestDescription',                                   i = find( GROUP ==    40 & ELEME == 24610 ,1); type = 'LO';
            case 'FrameOfInterestType',                                          i = find( GROUP ==    40 & ELEME == 24611 ,1); type = 'CS';
            case 'MaskPointer',                                                  i = find( GROUP ==    40 & ELEME == 24624 ,1); type = 'US';
            case 'RWavePointer',                                                 i = find( GROUP ==    40 & ELEME == 24640 ,1); type = 'US';
            case 'MaskSubtractionSequence',                                      i = find( GROUP ==    40 & ELEME == 24832 ,1); type = 'SQ';
            case 'MaskOperation',                                                i = find( GROUP ==    40 & ELEME == 24833 ,1); type = 'CS';
            case 'ApplicableFrameRange',                                         i = find( GROUP ==    40 & ELEME == 24834 ,1); type = 'US';
            case 'MaskFrameNumbers',                                             i = find( GROUP ==    40 & ELEME == 24848 ,1); type = 'US';
            case 'ContrastFrameAveraging',                                       i = find( GROUP ==    40 & ELEME == 24850 ,1); type = 'US';
            case 'MaskSubPixelShift',                                            i = find( GROUP ==    40 & ELEME == 24852 ,1); type = 'FL';
            case 'TIDOffset',                                                    i = find( GROUP ==    40 & ELEME == 24864 ,1); type = 'SS';
            case 'MaskOperationExplanation',                                     i = find( GROUP ==    40 & ELEME == 24976 ,1); type = 'ST';
            case 'DataPointRows',                                                i = find( GROUP ==    40 & ELEME == 36865 ,1); type = 'UL';
            case 'DataPointColumns',                                             i = find( GROUP ==    40 & ELEME == 36866 ,1); type = 'UL';
            case 'SignalDomainColumns',                                          i = find( GROUP ==    40 & ELEME == 36867 ,1); type = 'CS';
            case 'LargestMonochromePixelValue',                                  i = find( GROUP ==    40 & ELEME == 37017 ,1); type = 'US';
            case 'DataRepresentation',                                           i = find( GROUP ==    40 & ELEME == 37128 ,1); type = 'CS';
            case 'PixelMeasuresSequence',                                        i = find( GROUP ==    40 & ELEME == 37136 ,1); type = 'SQ';
            case 'FrameVOILUTSequence',                                          i = find( GROUP ==    40 & ELEME == 37170 ,1); type = 'SQ';
            case 'PixelValueTransformationSequence',                             i = find( GROUP ==    40 & ELEME == 37189 ,1); type = 'SQ';
            case 'SignalDomainRows',                                             i = find( GROUP ==    40 & ELEME == 37429 ,1); type = 'CS';
            case 'StudyGroupLength',                                             i = find( GROUP ==    50 & ELEME ==     0 ,1); type = 'UL';
            case 'StudyStatusID',                                                i = find( GROUP ==    50 & ELEME ==    10 ,1); type = 'CS';
            case 'StudyPriorityID',                                              i = find( GROUP ==    50 & ELEME ==    12 ,1); type = 'CS';
            case 'StudyIDIssuer',                                                i = find( GROUP ==    50 & ELEME ==    18 ,1); type = 'LO';
            case 'StudyVerifiedDate',                                            i = find( GROUP ==    50 & ELEME ==    50 ,1); type = 'DA';
            case 'StudyVerifiedTime',                                            i = find( GROUP ==    50 & ELEME ==    51 ,1); type = 'TM';
            case 'StudyReadDate',                                                i = find( GROUP ==    50 & ELEME ==    52 ,1); type = 'DA';
            case 'StudyReadTime',                                                i = find( GROUP ==    50 & ELEME ==    53 ,1); type = 'TM';
            case 'ScheduledStudyStartDate',                                      i = find( GROUP ==    50 & ELEME ==  4096 ,1); type = 'DA';
            case 'ScheduledStudyStartTime',                                      i = find( GROUP ==    50 & ELEME ==  4097 ,1); type = 'TM';
            case 'ScheduledStudyStopDate',                                       i = find( GROUP ==    50 & ELEME ==  4112 ,1); type = 'DA';
            case 'ScheduledStudyStopTime',                                       i = find( GROUP ==    50 & ELEME ==  4113 ,1); type = 'TM';
            case 'ScheduledStudyLocation',                                       i = find( GROUP ==    50 & ELEME ==  4128 ,1); type = 'LO';
            case 'ScheduledStudyLocationAETitle',                                i = find( GROUP ==    50 & ELEME ==  4129 ,1); type = 'AE';
            case 'ReasonForStudy',                                               i = find( GROUP ==    50 & ELEME ==  4144 ,1); type = 'LO';
            case 'RequestingPhysicianIdentificationSequence',                    i = find( GROUP ==    50 & ELEME ==  4145 ,1); type = 'SQ';
            case 'RequestingPhysician',                                          i = find( GROUP ==    50 & ELEME ==  4146 ,1); type = 'PN';
            case 'RequestingService',                                            i = find( GROUP ==    50 & ELEME ==  4147 ,1); type = 'LO';
            case 'StudyArrivalDate',                                             i = find( GROUP ==    50 & ELEME ==  4160 ,1); type = 'DA';
            case 'StudyArrivalTime',                                             i = find( GROUP ==    50 & ELEME ==  4161 ,1); type = 'TM';
            case 'StudyCompletionDate',                                          i = find( GROUP ==    50 & ELEME ==  4176 ,1); type = 'DA';
            case 'StudyCompletionTime',                                          i = find( GROUP ==    50 & ELEME ==  4177 ,1); type = 'TM';
            case 'StudyComponentStatusID',                                       i = find( GROUP ==    50 & ELEME ==  4181 ,1); type = 'CS';
            case 'RequestedProcedureDescription',                                i = find( GROUP ==    50 & ELEME ==  4192 ,1); type = 'LO';
            case 'RequestedProcedureCodeSequence',                               i = find( GROUP ==    50 & ELEME ==  4196 ,1); type = 'SQ';
            case 'RequestedContrastAgent',                                       i = find( GROUP ==    50 & ELEME ==  4208 ,1); type = 'LO';
            case 'StudyComments',                                                i = find( GROUP ==    50 & ELEME == 16384 ,1); type = 'LT';
            case 'VisitGroupLength',                                             i = find( GROUP ==    56 & ELEME ==     0 ,1); type = 'UL';
            case 'ReferencedPatientAliasSequence',                               i = find( GROUP ==    56 & ELEME ==     4 ,1); type = 'SQ';
            case 'VisitStatusID',                                                i = find( GROUP ==    56 & ELEME ==     8 ,1); type = 'CS';
            case 'AdmissionID',                                                  i = find( GROUP ==    56 & ELEME ==    16 ,1); type = 'LO';
            case 'IssuerOfAdmissionID',                                          i = find( GROUP ==    56 & ELEME ==    17 ,1); type = 'LO';
            case 'RouteOfAdmissions',                                            i = find( GROUP ==    56 & ELEME ==    22 ,1); type = 'LO';
            case 'ScheduledAdmissionDate',                                       i = find( GROUP ==    56 & ELEME ==    26 ,1); type = 'DA';
            case 'ScheduledAdmissionTime',                                       i = find( GROUP ==    56 & ELEME ==    27 ,1); type = 'TM';
            case 'ScheduledDischargeDate',                                       i = find( GROUP ==    56 & ELEME ==    28 ,1); type = 'DA';
            case 'ScheduledDischargeTime',                                       i = find( GROUP ==    56 & ELEME ==    29 ,1); type = 'TM';
            case 'ScheduledPatientInstitutionResidence',                         i = find( GROUP ==    56 & ELEME ==    30 ,1); type = 'LO';
            case 'AdmittingDate',                                                i = find( GROUP ==    56 & ELEME ==    32 ,1); type = 'DA';
            case 'AdmittingTime',                                                i = find( GROUP ==    56 & ELEME ==    33 ,1); type = 'TM';
            case 'DischargeDate',                                                i = find( GROUP ==    56 & ELEME ==    48 ,1); type = 'DA';
            case 'DischargeTime',                                                i = find( GROUP ==    56 & ELEME ==    50 ,1); type = 'TM';
            case 'DischargeDiagnosisDescription',                                i = find( GROUP ==    56 & ELEME ==    64 ,1); type = 'LO';
            case 'DischargeDiagnosisCodeSequence',                               i = find( GROUP ==    56 & ELEME ==    68 ,1); type = 'SQ';
            case 'SpecialNeeds',                                                 i = find( GROUP ==    56 & ELEME ==    80 ,1); type = 'LO';
            case 'CurrentPatientLocation',                                       i = find( GROUP ==    56 & ELEME ==   768 ,1); type = 'LO';
            case 'PatientInstitutionResidence',                                  i = find( GROUP ==    56 & ELEME ==  1024 ,1); type = 'LO';
            case 'PatientState',                                                 i = find( GROUP ==    56 & ELEME ==  1280 ,1); type = 'LO';
            case 'PatientClinicalTrialParticipationSequence',                    i = find( GROUP ==    56 & ELEME ==  1282 ,1); type = 'SQ';
            case 'VisitComments',                                                i = find( GROUP ==    56 & ELEME == 16384 ,1); type = 'LT';
            case 'WaveformOriginality',                                          i = find( GROUP ==    58 & ELEME ==     4 ,1); type = 'CS';
            case 'NumberOfWaveformChannels',                                     i = find( GROUP ==    58 & ELEME ==     5 ,1); type = 'US';
            case 'NumberOfWaveformSamples',                                      i = find( GROUP ==    58 & ELEME ==    16 ,1); type = 'UL';
            case 'SamplingFrequency',                                            i = find( GROUP ==    58 & ELEME ==    26 ,1); type = 'DS';
            case 'MultiplexGroupLabel',                                          i = find( GROUP ==    58 & ELEME ==    32 ,1); type = 'SH';
            case 'ChannelDefinitionSequence',                                    i = find( GROUP ==    58 & ELEME ==   512 ,1); type = 'SQ';
            case 'WaveformChannelNumber',                                        i = find( GROUP ==    58 & ELEME ==   514 ,1); type = 'IS';
            case 'ChannelLabel',                                                 i = find( GROUP ==    58 & ELEME ==   515 ,1); type = 'SH';
            case 'ChannelStatus',                                                i = find( GROUP ==    58 & ELEME ==   517 ,1); type = 'CS';
            case 'ChannelSourceSequence',                                        i = find( GROUP ==    58 & ELEME ==   520 ,1); type = 'SQ';
            case 'ChannelSourceModifiersSequence',                               i = find( GROUP ==    58 & ELEME ==   521 ,1); type = 'SQ';
            case 'SourceWaveformSequence',                                       i = find( GROUP ==    58 & ELEME ==   522 ,1); type = 'SQ';
            case 'ChannelDerivationDescription',                                 i = find( GROUP ==    58 & ELEME ==   524 ,1); type = 'LO';
            case 'ChannelSensitivity',                                           i = find( GROUP ==    58 & ELEME ==   528 ,1); type = 'DS';
            case 'ChannelSensitivityUnitsSequence',                              i = find( GROUP ==    58 & ELEME ==   529 ,1); type = 'SQ';
            case 'ChannelSensitivityCorrectionFactor',                           i = find( GROUP ==    58 & ELEME ==   530 ,1); type = 'DS';
            case 'ChannelBaseline',                                              i = find( GROUP ==    58 & ELEME ==   531 ,1); type = 'DS';
            case 'ChannelTimeSkew',                                              i = find( GROUP ==    58 & ELEME ==   532 ,1); type = 'DS';
            case 'ChannelSampleSkew',                                            i = find( GROUP ==    58 & ELEME ==   533 ,1); type = 'DS';
            case 'ChannelOffset',                                                i = find( GROUP ==    58 & ELEME ==   536 ,1); type = 'DS';
            case 'WaveformBitsStored',                                           i = find( GROUP ==    58 & ELEME ==   538 ,1); type = 'US';
            case 'FilterLowFrequency',                                           i = find( GROUP ==    58 & ELEME ==   544 ,1); type = 'DS';
            case 'FilterHighFrequency',                                          i = find( GROUP ==    58 & ELEME ==   545 ,1); type = 'DS';
            case 'NotchFilterFrequency',                                         i = find( GROUP ==    58 & ELEME ==   546 ,1); type = 'DS';
            case 'NotchFilterBandwidth',                                         i = find( GROUP ==    58 & ELEME ==   547 ,1); type = 'DS';
            case 'MultiplexedAudioChannelsDescriptionCodeSequence',              i = find( GROUP ==    58 & ELEME ==   768 ,1); type = 'SQ';
            case 'ChannelIdentificationCode',                                    i = find( GROUP ==    58 & ELEME ==   769 ,1); type = 'IS';
            case 'ChannelMode',                                                  i = find( GROUP ==    58 & ELEME ==   770 ,1); type = 'CS';
            case 'ScheduledProcedureGroupLength',                                i = find( GROUP ==    64 & ELEME ==     0 ,1); type = 'UL';
            case 'ScheduledStationAETitle',                                      i = find( GROUP ==    64 & ELEME ==     1 ,1); type = 'AE';
            case 'ScheduledProcedureStepStartDate',                              i = find( GROUP ==    64 & ELEME ==     2 ,1); type = 'DA';
            case 'ScheduledProcedureStepStartTime',                              i = find( GROUP ==    64 & ELEME ==     3 ,1); type = 'TM';
            case 'ScheduledProcedureStepEndDate',                                i = find( GROUP ==    64 & ELEME ==     4 ,1); type = 'DA';
            case 'ScheduledProcedureStepEndTime',                                i = find( GROUP ==    64 & ELEME ==     5 ,1); type = 'TM';
            case 'ScheduledPerformingPhysicianName',                             i = find( GROUP ==    64 & ELEME ==     6 ,1); type = 'PN';
            case 'ScheduledProcedureStepDescription',                            i = find( GROUP ==    64 & ELEME ==     7 ,1); type = 'LO';
            case 'ScheduledProtocolCodeSequence',                                i = find( GROUP ==    64 & ELEME ==     8 ,1); type = 'SQ';
            case 'ScheduledProcedureStepID',                                     i = find( GROUP ==    64 & ELEME ==     9 ,1); type = 'SH';
            case 'StageCodeSequence',                                            i = find( GROUP ==    64 & ELEME ==    10 ,1); type = 'SQ';
            case 'ScheduledPerformingPhysicianIdentificationSequence',           i = find( GROUP ==    64 & ELEME ==    11 ,1); type = 'SQ';
            case 'ScheduledStationName',                                         i = find( GROUP ==    64 & ELEME ==    16 ,1); type = 'SH';
            case 'ScheduledProcedureStepLocation',                               i = find( GROUP ==    64 & ELEME ==    17 ,1); type = 'SH';
            case 'PreMedication',                                                i = find( GROUP ==    64 & ELEME ==    18 ,1); type = 'LO';
            case 'ScheduledProcedureStepStatus',                                 i = find( GROUP ==    64 & ELEME ==    32 ,1); type = 'CS';
            case 'ScheduledProcedureStepSequence',                               i = find( GROUP ==    64 & ELEME ==   256 ,1); type = 'SQ';
            case 'ReferencedNonImageCompositeSOPInstanceSequence',               i = find( GROUP ==    64 & ELEME ==   544 ,1); type = 'SQ';
            case 'PerformedStationAETitle',                                      i = find( GROUP ==    64 & ELEME ==   577 ,1); type = 'AE';
            case 'PerformedStationName',                                         i = find( GROUP ==    64 & ELEME ==   578 ,1); type = 'SH';
            case 'PerformedLocation',                                            i = find( GROUP ==    64 & ELEME ==   579 ,1); type = 'SH';
            case 'PerformedProcedureStepStartDate',                              i = find( GROUP ==    64 & ELEME ==   580 ,1); type = 'DA';
            case 'PerformedProcedureStepStartTime',                              i = find( GROUP ==    64 & ELEME ==   581 ,1); type = 'TM';
            case 'PerformedProcedureStepEndDate',                                i = find( GROUP ==    64 & ELEME ==   592 ,1); type = 'DA';
            case 'PerformedProcedureStepEndTime',                                i = find( GROUP ==    64 & ELEME ==   593 ,1); type = 'TM';
            case 'PerformedProcedureStepStatus',                                 i = find( GROUP ==    64 & ELEME ==   594 ,1); type = 'CS';
            case 'PerformedProcedureStepID',                                     i = find( GROUP ==    64 & ELEME ==   595 ,1); type = 'SH';
            case 'PerformedProcedureStepDescription',                            i = find( GROUP ==    64 & ELEME ==   596 ,1); type = 'LO';
            case 'PerformedProcedureTypeDescription',                            i = find( GROUP ==    64 & ELEME ==   597 ,1); type = 'LO';
            case 'PerformedProtocolCodeSequence',                                i = find( GROUP ==    64 & ELEME ==   608 ,1); type = 'SQ';
            case 'ScheduledStepAttributesSequence',                              i = find( GROUP ==    64 & ELEME ==   624 ,1); type = 'SQ';
            case 'RequestAttributesSequence',                                    i = find( GROUP ==    64 & ELEME ==   629 ,1); type = 'SQ';
            case 'CommentsOnPerformedProcedureStep',                             i = find( GROUP ==    64 & ELEME ==   640 ,1); type = 'ST';
            case 'PerformedProcedureStepDiscontinuationReasonCodeSequence',      i = find( GROUP ==    64 & ELEME ==   641 ,1); type = 'SQ';
            case 'QuantitySequence',                                             i = find( GROUP ==    64 & ELEME ==   659 ,1); type = 'SQ';
            case 'Quantity',                                                     i = find( GROUP ==    64 & ELEME ==   660 ,1); type = 'DS';
            case 'MeasuringUnitsSequence',                                       i = find( GROUP ==    64 & ELEME ==   661 ,1); type = 'SQ';
            case 'BillingItemSequence',                                          i = find( GROUP ==    64 & ELEME ==   662 ,1); type = 'SQ';
            case 'TotalTimeOfFlouroscopy',                                       i = find( GROUP ==    64 & ELEME ==   768 ,1); type = 'US';
            case 'TotalNumberOfExposures',                                       i = find( GROUP ==    64 & ELEME ==   769 ,1); type = 'US';
            case 'EntranceDose',                                                 i = find( GROUP ==    64 & ELEME ==   770 ,1); type = 'US';
            case 'ExposedArea',                                                  i = find( GROUP ==    64 & ELEME ==   771 ,1); type = 'US';
            case 'DistanceSourceToEntrance',                                     i = find( GROUP ==    64 & ELEME ==   774 ,1); type = 'DS';
            case 'DistanceSourceToSupport',                                      i = find( GROUP ==    64 & ELEME ==   775 ,1); type = 'DS';
            case 'ExposureDoseSequence',                                         i = find( GROUP ==    64 & ELEME ==   782 ,1); type = 'SQ';
            case 'CommentsOnRadiationDose',                                      i = find( GROUP ==    64 & ELEME ==   784 ,1); type = 'ST';
            case 'XRayOutput',                                                   i = find( GROUP ==    64 & ELEME ==   786 ,1); type = 'DS';
            case 'HalfValueLayer',                                               i = find( GROUP ==    64 & ELEME ==   788 ,1); type = 'DS';
            case 'OrganDose',                                                    i = find( GROUP ==    64 & ELEME ==   790 ,1); type = 'DS';
            case 'OrganExposed',                                                 i = find( GROUP ==    64 & ELEME ==   792 ,1); type = 'CS';
            case 'BillingProcedureStepSequence',                                 i = find( GROUP ==    64 & ELEME ==   800 ,1); type = 'SQ';
            case 'FilmConsumptionSequence',                                      i = find( GROUP ==    64 & ELEME ==   801 ,1); type = 'SQ';
            case 'BillingSuppliesAndDevicesSequence',                            i = find( GROUP ==    64 & ELEME ==   804 ,1); type = 'SQ';
            case 'ReferencedProcedureStepSequence',                              i = find( GROUP ==    64 & ELEME ==   816 ,1); type = 'SQ';
            case 'PerformedSeriesSequence',                                      i = find( GROUP ==    64 & ELEME ==   832 ,1); type = 'SQ';
            case 'CommentsOnScheduledProcedureStep',                             i = find( GROUP ==    64 & ELEME ==  1024 ,1); type = 'LT';
            case 'SpecimenAccessionNumber',                                      i = find( GROUP ==    64 & ELEME ==  1290 ,1); type = 'LO';
            case 'SpecimenSequence',                                             i = find( GROUP ==    64 & ELEME ==  1360 ,1); type = 'SQ';
            case 'SpecimenIdentifier',                                           i = find( GROUP ==    64 & ELEME ==  1361 ,1); type = 'LO';
            case 'SpecimenDescriptionSequenceTrial',                             i = find( GROUP ==    64 & ELEME ==  1362 ,1); type = 'SQ';
            case 'SpecimenDescriptionTrial',                                     i = find( GROUP ==    64 & ELEME ==  1363 ,1); type = 'ST';
            case 'AcquisitionContextSequence',                                   i = find( GROUP ==    64 & ELEME ==  1365 ,1); type = 'SQ';
            case 'AcquisitionContextDescription',                                i = find( GROUP ==    64 & ELEME ==  1366 ,1); type = 'ST';
            case 'SpecimenTypeCodeSequence',                                     i = find( GROUP ==    64 & ELEME ==  1434 ,1); type = 'SQ';
            case 'SlideIdentifier',                                              i = find( GROUP ==    64 & ELEME ==  1786 ,1); type = 'LO';
            case 'ImageCenterPointCoordinatesSequence',                          i = find( GROUP ==    64 & ELEME ==  1818 ,1); type = 'SQ';
            case 'XOffsetInSlideCoordinateSystem',                               i = find( GROUP ==    64 & ELEME ==  1834 ,1); type = 'DS';
            case 'YOffsetInSlideCoordinateSystem',                               i = find( GROUP ==    64 & ELEME ==  1850 ,1); type = 'DS';
            case 'ZOffsetInSlideCoordinateSystem',                               i = find( GROUP ==    64 & ELEME ==  1866 ,1); type = 'DS';
            case 'PixelSpacingSequence',                                         i = find( GROUP ==    64 & ELEME ==  2264 ,1); type = 'SQ';
            case 'CoordinateSystemAxisCodeSequence',                             i = find( GROUP ==    64 & ELEME ==  2266 ,1); type = 'SQ';
            case 'MeasurementUnitsCodeSequence',                                 i = find( GROUP ==    64 & ELEME ==  2282 ,1); type = 'SQ';
            case 'VitalStainCodeSequenceTrial',                                  i = find( GROUP ==    64 & ELEME ==  2552 ,1); type = 'SQ';
            case 'RequestedProcedureID',                                         i = find( GROUP ==    64 & ELEME ==  4097 ,1); type = 'SH';
            case 'ReasonForRequestedProcedure',                                  i = find( GROUP ==    64 & ELEME ==  4098 ,1); type = 'LO';
            case 'RequestedProcedurePriority',                                   i = find( GROUP ==    64 & ELEME ==  4099 ,1); type = 'SH';
            case 'PatientTransportArrangements',                                 i = find( GROUP ==    64 & ELEME ==  4100 ,1); type = 'LO';
            case 'RequestedProcedureLocation',                                   i = find( GROUP ==    64 & ELEME ==  4101 ,1); type = 'LO';
            case 'PlacerOrderNumberOfProcedure',                                 i = find( GROUP ==    64 & ELEME ==  4102 ,1); type = 'SH';
            case 'FillerOrderNumberOfProcedure',                                 i = find( GROUP ==    64 & ELEME ==  4103 ,1); type = 'SH';
            case 'ConfidentialityCode',                                          i = find( GROUP ==    64 & ELEME ==  4104 ,1); type = 'LO';
            case 'ReportingPriority',                                            i = find( GROUP ==    64 & ELEME ==  4105 ,1); type = 'SH';
            case 'ReasonForRequestedProcedureCodeSequence',                      i = find( GROUP ==    64 & ELEME ==  4106 ,1); type = 'SQ';
            case 'NamesOfIntendedRecipientsOfResults',                           i = find( GROUP ==    64 & ELEME ==  4112 ,1); type = 'PN';
            case 'IntendedRecipientsOfResultsIdentificationSequence',            i = find( GROUP ==    64 & ELEME ==  4113 ,1); type = 'SQ';
            case 'PersonIdentificationCodeSequence',                             i = find( GROUP ==    64 & ELEME ==  4353 ,1); type = 'SQ';
            case 'PersonAddress',                                                i = find( GROUP ==    64 & ELEME ==  4354 ,1); type = 'ST';
            case 'PersonTelephoneNumbers',                                       i = find( GROUP ==    64 & ELEME ==  4355 ,1); type = 'LO';
            case 'RequestedProcedureComments',                                   i = find( GROUP ==    64 & ELEME ==  5120 ,1); type = 'LT';
            case 'ReasonForImagingServiceRequest',                               i = find( GROUP ==    64 & ELEME ==  8193 ,1); type = 'LO';
            case 'IssueDateOfImagingServiceRequest',                             i = find( GROUP ==    64 & ELEME ==  8196 ,1); type = 'DA';
            case 'IssueTimeOfImagingServiceRequest',                             i = find( GROUP ==    64 & ELEME ==  8197 ,1); type = 'TM';
            case 'PlacerOrderNumberOfImagingServiceRequestRetired',              i = find( GROUP ==    64 & ELEME ==  8198 ,1); type = 'SH';
            case 'FillerOrderNumberOfImagingServiceRequestRetired',              i = find( GROUP ==    64 & ELEME ==  8199 ,1); type = 'SH';
            case 'OrderEnteredBy',                                               i = find( GROUP ==    64 & ELEME ==  8200 ,1); type = 'PN';
            case 'OrderEntererLocation',                                         i = find( GROUP ==    64 & ELEME ==  8201 ,1); type = 'SH';
            case 'OrderCallbackPhoneNumber',                                     i = find( GROUP ==    64 & ELEME ==  8208 ,1); type = 'SH';
            case 'PlacerOrderNumberOfImagingServiceRequest',                     i = find( GROUP ==    64 & ELEME ==  8214 ,1); type = 'LO';
            case 'FillerOrderNumberOfImagingServiceRequest',                     i = find( GROUP ==    64 & ELEME ==  8215 ,1); type = 'LO';
            case 'ImagingServiceRequestComments',                                i = find( GROUP ==    64 & ELEME ==  9216 ,1); type = 'LT';
            case 'ConfidentialityConstraintOnPatientDataDescription',            i = find( GROUP ==    64 & ELEME == 12289 ,1); type = 'LO';
            case 'GeneralPurposeScheduledProcedureStepStatus',                   i = find( GROUP ==    64 & ELEME == 16385 ,1); type = 'CS';
            case 'GeneralPurposePerformedProcedureStepStatus',                   i = find( GROUP ==    64 & ELEME == 16386 ,1); type = 'CS';
            case 'GeneralPurposeScheduledProcedureStepPriority',                 i = find( GROUP ==    64 & ELEME == 16387 ,1); type = 'CS';
            case 'ScheduledProcessingApplicationsCodeSequence',                  i = find( GROUP ==    64 & ELEME == 16388 ,1); type = 'SQ';
            case 'ScheduledProcedureStepStartDateAndTime',                       i = find( GROUP ==    64 & ELEME == 16389 ,1); type = 'DT';
            case 'MultipleCopiesFlag',                                           i = find( GROUP ==    64 & ELEME == 16390 ,1); type = 'CS';
            case 'PerformedProcessingApplicationsCodeSequence',                  i = find( GROUP ==    64 & ELEME == 16391 ,1); type = 'SQ';
            case 'HumanPerformerCodeSequence',                                   i = find( GROUP ==    64 & ELEME == 16393 ,1); type = 'SQ';
            case 'ScheduledProcedureStepModificationDateAndTime',                i = find( GROUP ==    64 & ELEME == 16400 ,1); type = 'DT';
            case 'ExpectedCompletionDateAndTime',                                i = find( GROUP ==    64 & ELEME == 16401 ,1); type = 'DT';
            case 'ResultingGeneralPurposePerformedProcedureStepsSequence',       i = find( GROUP ==    64 & ELEME == 16405 ,1); type = 'SQ';
            case 'ReferencedGeneralPurposeScheduledProcedureStepSequence',       i = find( GROUP ==    64 & ELEME == 16406 ,1); type = 'SQ';
            case 'ScheduledWorkitemCodeSequence',                                i = find( GROUP ==    64 & ELEME == 16408 ,1); type = 'SQ';
            case 'PerformedWorkitemCodeSequence',                                i = find( GROUP ==    64 & ELEME == 16409 ,1); type = 'SQ';
            case 'InputAvailabilityFlag',                                        i = find( GROUP ==    64 & ELEME == 16416 ,1); type = 'CS';
            case 'InputInformationSequence',                                     i = find( GROUP ==    64 & ELEME == 16417 ,1); type = 'SQ';
            case 'RelevantInformationSequence',                                  i = find( GROUP ==    64 & ELEME == 16418 ,1); type = 'SQ';
            case 'ReferencedGeneralPurposeScheduledProcedureStepTransactionUID', i = find( GROUP ==    64 & ELEME == 16419 ,1); type = 'UI';
            case 'ScheduledStationNameCodeSequence',                             i = find( GROUP ==    64 & ELEME == 16421 ,1); type = 'SQ';
            case 'ScheduledStationClassCodeSequence',                            i = find( GROUP ==    64 & ELEME == 16422 ,1); type = 'SQ';
            case 'ScheduledStationGeographicLocationCodeSequence',               i = find( GROUP ==    64 & ELEME == 16423 ,1); type = 'SQ';
            case 'PerformedStationNameCodeSequence',                             i = find( GROUP ==    64 & ELEME == 16424 ,1); type = 'SQ';
            case 'PerformedStationClassCodeSequence',                            i = find( GROUP ==    64 & ELEME == 16425 ,1); type = 'SQ';
            case 'PerformedStationGeographicLocationCodeSequence',               i = find( GROUP ==    64 & ELEME == 16432 ,1); type = 'SQ';
            case 'RequestedSubsequentWorkitemCodeSequence',                      i = find( GROUP ==    64 & ELEME == 16433 ,1); type = 'SQ';
            case 'NonDICOMOutputCodeSequence',                                   i = find( GROUP ==    64 & ELEME == 16434 ,1); type = 'SQ';
            case 'OutputInformationSequence',                                    i = find( GROUP ==    64 & ELEME == 16435 ,1); type = 'SQ';
            case 'ScheduledHumanPerformersSequence',                             i = find( GROUP ==    64 & ELEME == 16436 ,1); type = 'SQ';
            case 'ActualHumanPerformersSequence',                                i = find( GROUP ==    64 & ELEME == 16437 ,1); type = 'SQ';
            case 'HumanPerformersOrganization',                                  i = find( GROUP ==    64 & ELEME == 16438 ,1); type = 'LO';
            case 'HumanPerformersName',                                          i = find( GROUP ==    64 & ELEME == 16439 ,1); type = 'PN';
            case 'EntranceDoseInmGy',                                            i = find( GROUP ==    64 & ELEME == 33538 ,1); type = 'DS';
            case 'RealWorldValueMappingSequence',                                i = find( GROUP ==    64 & ELEME == 37014 ,1); type = 'SQ';
            case 'LUTLabel',                                                     i = find( GROUP ==    64 & ELEME == 37392 ,1); type = 'SH';
            case 'RealWorldValueLUTData',                                        i = find( GROUP ==    64 & ELEME == 37394 ,1); type = 'FD';
            case 'RealWorldValueIntercept',                                      i = find( GROUP ==    64 & ELEME == 37412 ,1); type = 'FD';
            case 'RealWorldValueSlope',                                          i = find( GROUP ==    64 & ELEME == 37413 ,1); type = 'FD';
            case 'RelationshipType',                                             i = find( GROUP ==    64 & ELEME == 40976 ,1); type = 'CS';
            case 'VerifyingOrganization',                                        i = find( GROUP ==    64 & ELEME == 40999 ,1); type = 'LO';
            case 'VerificationDateTime',                                         i = find( GROUP ==    64 & ELEME == 41008 ,1); type = 'DT';
            case 'ObservationDateTime',                                          i = find( GROUP ==    64 & ELEME == 41010 ,1); type = 'DT';
            case 'ValueType',                                                    i = find( GROUP ==    64 & ELEME == 41024 ,1); type = 'CS';
            case 'ConceptNameCodeSequence',                                      i = find( GROUP ==    64 & ELEME == 41027 ,1); type = 'SQ';
            case 'ContinuityOfContent',                                          i = find( GROUP ==    64 & ELEME == 41040 ,1); type = 'CS';
            case 'VerifyingObserverSequence',                                    i = find( GROUP ==    64 & ELEME == 41075 ,1); type = 'SQ';
            case 'VerifyingObserverName',                                        i = find( GROUP ==    64 & ELEME == 41077 ,1); type = 'PN';
            case 'VerifyingObserverIdentificationCodeSequence',                  i = find( GROUP ==    64 & ELEME == 41096 ,1); type = 'SQ';
            case 'ReferencedWaveformChannels',                                   i = find( GROUP ==    64 & ELEME == 41136 ,1); type = 'US';
            case 'DateTime',                                                     i = find( GROUP ==    64 & ELEME == 41248 ,1); type = 'DT';
            case 'Date',                                                         i = find( GROUP ==    64 & ELEME == 41249 ,1); type = 'DA';
            case 'Time',                                                         i = find( GROUP ==    64 & ELEME == 41250 ,1); type = 'TM';
            case 'PersonName',                                                   i = find( GROUP ==    64 & ELEME == 41251 ,1); type = 'PN';
            case 'UID',                                                          i = find( GROUP ==    64 & ELEME == 41252 ,1); type = 'UI';
            case 'TemporalRangeType',                                            i = find( GROUP ==    64 & ELEME == 41264 ,1); type = 'CS';
            case 'ReferencedSamplePositions',                                    i = find( GROUP ==    64 & ELEME == 41266 ,1); type = 'UL';
            case 'ReferencedFrameNumbers',                                       i = find( GROUP ==    64 & ELEME == 41270 ,1); type = 'US';
            case 'ReferencedTimeOffsets',                                        i = find( GROUP ==    64 & ELEME == 41272 ,1); type = 'DS';
            case 'ReferencedDateTime',                                           i = find( GROUP ==    64 & ELEME == 41274 ,1); type = 'DT';
            case 'TextValue',                                                    i = find( GROUP ==    64 & ELEME == 41312 ,1); type = 'UT';
            case 'ConceptCodeSequence',                                          i = find( GROUP ==    64 & ELEME == 41320 ,1); type = 'SQ';
            case 'PurposeOfReferenceCodeSequence',                               i = find( GROUP ==    64 & ELEME == 41328 ,1); type = 'SQ';
            case 'AnnotationGroupNumber',                                        i = find( GROUP ==    64 & ELEME == 41344 ,1); type = 'US';
            case 'ModifierCodeSequence',                                         i = find( GROUP ==    64 & ELEME == 41365 ,1); type = 'SQ';
            case 'MeasuredValueSequence',                                        i = find( GROUP ==    64 & ELEME == 41728 ,1); type = 'SQ';
            case 'NumericValueQualifierCodeSequence',                            i = find( GROUP ==    64 & ELEME == 41729 ,1); type = 'SQ';
            case 'NumericValue',                                                 i = find( GROUP ==    64 & ELEME == 41738 ,1); type = 'DS';
            case 'AddressTrial',                                                 i = find( GROUP ==    64 & ELEME == 41811 ,1); type = 'ST';
            case 'TelephoneNumberTrial',                                         i = find( GROUP ==    64 & ELEME == 41812 ,1); type = 'LO';
            case 'PredecessorDocumentsSequence',                                 i = find( GROUP ==    64 & ELEME == 41824 ,1); type = 'SQ';
            case 'ReferencedRequestSequence',                                    i = find( GROUP ==    64 & ELEME == 41840 ,1); type = 'SQ';
            case 'PerformedProcedureCodeSequence',                               i = find( GROUP ==    64 & ELEME == 41842 ,1); type = 'SQ';
            case 'CurrentRequestedProcedureEvidenceSequence',                    i = find( GROUP ==    64 & ELEME == 41845 ,1); type = 'SQ';
            case 'PertinentOtherEvidenceSequence',                               i = find( GROUP ==    64 & ELEME == 41861 ,1); type = 'SQ';
            case 'CompletionFlag',                                               i = find( GROUP ==    64 & ELEME == 42129 ,1); type = 'CS';
            case 'CompletionFlagDescription',                                    i = find( GROUP ==    64 & ELEME == 42130 ,1); type = 'LO';
            case 'VerificationFlag',                                             i = find( GROUP ==    64 & ELEME == 42131 ,1); type = 'CS';
            case 'ContentTemplateSequence',                                      i = find( GROUP ==    64 & ELEME == 42244 ,1); type = 'SQ';
            case 'IdenticalDocumentsSequence',                                   i = find( GROUP ==    64 & ELEME == 42277 ,1); type = 'SQ';
            case 'ContentSequence',                                              i = find( GROUP ==    64 & ELEME == 42800 ,1); type = 'SQ';
            case 'AnnotationSequence',                                           i = find( GROUP ==    64 & ELEME == 45088 ,1); type = 'SQ';
            case 'TemplateIdentifier',                                           i = find( GROUP ==    64 & ELEME == 56064 ,1); type = 'CS';
            case 'TemplateVersion',                                              i = find( GROUP ==    64 & ELEME == 56070 ,1); type = 'DT';
            case 'TemplateLocalVersion',                                         i = find( GROUP ==    64 & ELEME == 56071 ,1); type = 'DT';
            case 'TemplateExtensionFlag',                                        i = find( GROUP ==    64 & ELEME == 56075 ,1); type = 'CS';
            case 'TemplateExtensionOrganizationUID',                             i = find( GROUP ==    64 & ELEME == 56076 ,1); type = 'UI';
            case 'TemplateExtensionCreatorUID',                                  i = find( GROUP ==    64 & ELEME == 56077 ,1); type = 'UI';
            case 'ReferencedContentItemIdentifier',                              i = find( GROUP ==    64 & ELEME == 56179 ,1); type = 'UL';
            case 'DocumentTitle',                                                i = find( GROUP ==    66 & ELEME ==    16 ,1); type = 'ST';
            case 'EncapsulatedDocument',                                         i = find( GROUP ==    66 & ELEME ==    17 ,1); type = 'OB';
            case 'MIMETypeOfEncapsulatedDocument',                               i = find( GROUP ==    66 & ELEME ==    18 ,1); type = 'LO';
            case 'SourceInstanceSequence',                                       i = find( GROUP ==    66 & ELEME ==    19 ,1); type = 'SQ';
            case 'CalibrationGroupLength',                                       i = find( GROUP ==    80 & ELEME ==     0 ,1); type = 'UL';
            case 'CalibrationImage',                                             i = find( GROUP ==    80 & ELEME ==     4 ,1); type = 'CS';
            case 'DeviceSequence',                                               i = find( GROUP ==    80 & ELEME ==    16 ,1); type = 'SQ';
            case 'DeviceLength',                                                 i = find( GROUP ==    80 & ELEME ==    20 ,1); type = 'DS';
            case 'DeviceDiameter',                                               i = find( GROUP ==    80 & ELEME ==    22 ,1); type = 'DS';
            case 'DeviceDiameterUnits',                                          i = find( GROUP ==    80 & ELEME ==    23 ,1); type = 'CS';
            case 'DeviceVolume',                                                 i = find( GROUP ==    80 & ELEME ==    24 ,1); type = 'DS';
            case 'InterMarkerDistance',                                          i = find( GROUP ==    80 & ELEME ==    25 ,1); type = 'DS';
            case 'DeviceDescription',                                            i = find( GROUP ==    80 & ELEME ==    32 ,1); type = 'LO';
            case 'NuclearAcquisitionGroupLength',                                i = find( GROUP ==    84 & ELEME ==     0 ,1); type = 'UL';
            case 'EnergyWindowVector',                                           i = find( GROUP ==    84 & ELEME ==    16 ,1); type = 'US';
            case 'NumberOfEnergyWindows',                                        i = find( GROUP ==    84 & ELEME ==    17 ,1); type = 'US';
            case 'EnergyWindowInformationSequence',                              i = find( GROUP ==    84 & ELEME ==    18 ,1); type = 'SQ';
            case 'EnergyWindowRangeSequence',                                    i = find( GROUP ==    84 & ELEME ==    19 ,1); type = 'SQ';
            case 'EnergyWindowLowerLimit',                                       i = find( GROUP ==    84 & ELEME ==    20 ,1); type = 'DS';
            case 'EnergyWindowUpperLimit',                                       i = find( GROUP ==    84 & ELEME ==    21 ,1); type = 'DS';
            case 'RadiopharmaceuticalInformationSequence',                       i = find( GROUP ==    84 & ELEME ==    22 ,1); type = 'SQ';
            case 'ResidualSyringeCounts',                                        i = find( GROUP ==    84 & ELEME ==    23 ,1); type = 'IS';
            case 'EnergyWindowName',                                             i = find( GROUP ==    84 & ELEME ==    24 ,1); type = 'SH';
            case 'DetectorVector',                                               i = find( GROUP ==    84 & ELEME ==    32 ,1); type = 'US';
            case 'NumberOfDetectors',                                            i = find( GROUP ==    84 & ELEME ==    33 ,1); type = 'US';
            case 'DetectorInformationSequence',                                  i = find( GROUP ==    84 & ELEME ==    34 ,1); type = 'SQ';
            case 'PhaseVector',                                                  i = find( GROUP ==    84 & ELEME ==    48 ,1); type = 'US';
            case 'NumberOfPhases',                                               i = find( GROUP ==    84 & ELEME ==    49 ,1); type = 'US';
            case 'PhaseInformationSequence',                                     i = find( GROUP ==    84 & ELEME ==    50 ,1); type = 'SQ';
            case 'NumberOfFramesInPhase',                                        i = find( GROUP ==    84 & ELEME ==    51 ,1); type = 'US';
            case 'PhaseDelay',                                                   i = find( GROUP ==    84 & ELEME ==    54 ,1); type = 'IS';
            case 'PauseBetweenFrames',                                           i = find( GROUP ==    84 & ELEME ==    56 ,1); type = 'IS';
            case 'RotationVector',                                               i = find( GROUP ==    84 & ELEME ==    80 ,1); type = 'US';
            case 'NumberOfRotations',                                            i = find( GROUP ==    84 & ELEME ==    81 ,1); type = 'US';
            case 'RotationInformationSequence',                                  i = find( GROUP ==    84 & ELEME ==    82 ,1); type = 'SQ';
            case 'NumberOfFramesInRotation',                                     i = find( GROUP ==    84 & ELEME ==    83 ,1); type = 'US';
            case 'RRIntervalVector',                                             i = find( GROUP ==    84 & ELEME ==    96 ,1); type = 'US';
            case 'NumberOfRRIntervals',                                          i = find( GROUP ==    84 & ELEME ==    97 ,1); type = 'US';
            case 'GatedInformationSequence',                                     i = find( GROUP ==    84 & ELEME ==    98 ,1); type = 'SQ';
            case 'DataInformationSequence',                                      i = find( GROUP ==    84 & ELEME ==    99 ,1); type = 'SQ';
            case 'TimeSlotVector',                                               i = find( GROUP ==    84 & ELEME ==   112 ,1); type = 'US';
            case 'NumberOfTimeSlots',                                            i = find( GROUP ==    84 & ELEME ==   113 ,1); type = 'US';
            case 'TimeSlotInformationSequence',                                  i = find( GROUP ==    84 & ELEME ==   114 ,1); type = 'SQ';
            case 'TimeSlotTime',                                                 i = find( GROUP ==    84 & ELEME ==   115 ,1); type = 'DS';
            case 'SliceVector',                                                  i = find( GROUP ==    84 & ELEME ==   128 ,1); type = 'US';
            case 'NumberOfSlices',                                               i = find( GROUP ==    84 & ELEME ==   129 ,1); type = 'US';
            case 'AngularViewVector',                                            i = find( GROUP ==    84 & ELEME ==   144 ,1); type = 'US';
            case 'TimeSliceVector',                                              i = find( GROUP ==    84 & ELEME ==   256 ,1); type = 'US';
            case 'NumberOfTimeSlices',                                           i = find( GROUP ==    84 & ELEME ==   257 ,1); type = 'US';
            case 'StartAngle',                                                   i = find( GROUP ==    84 & ELEME ==   512 ,1); type = 'DS';
            case 'TypeOfDetectorMotion',                                         i = find( GROUP ==    84 & ELEME ==   514 ,1); type = 'CS';
            case 'TriggerVector',                                                i = find( GROUP ==    84 & ELEME ==   528 ,1); type = 'IS';
            case 'NumberOfTriggersInPhase',                                      i = find( GROUP ==    84 & ELEME ==   529 ,1); type = 'US';
            case 'ViewCodeSequence',                                             i = find( GROUP ==    84 & ELEME ==   544 ,1); type = 'SQ';
            case 'ViewModifierCodeSequence',                                     i = find( GROUP ==    84 & ELEME ==   546 ,1); type = 'SQ';
            case 'RadionuclideCodeSequence',                                     i = find( GROUP ==    84 & ELEME ==   768 ,1); type = 'SQ';
            case 'AdministrationRouteCodeSequence',                              i = find( GROUP ==    84 & ELEME ==   770 ,1); type = 'SQ';
            case 'RadiopharmaceuticalCodeSequence',                              i = find( GROUP ==    84 & ELEME ==   772 ,1); type = 'SQ';
            case 'CalibrationDataSequence',                                      i = find( GROUP ==    84 & ELEME ==   774 ,1); type = 'SQ';
            case 'EnergyWindowNumber',                                           i = find( GROUP ==    84 & ELEME ==   776 ,1); type = 'US';
            case 'ImageID',                                                      i = find( GROUP ==    84 & ELEME ==  1024 ,1); type = 'SH';
            case 'PatientOrientationCodeSequence',                               i = find( GROUP ==    84 & ELEME ==  1040 ,1); type = 'SQ';
            case 'PatientOrientationModifierCodeSequence',                       i = find( GROUP ==    84 & ELEME ==  1042 ,1); type = 'SQ';
            case 'PatientGantryRelationshipCodeSequence',                        i = find( GROUP ==    84 & ELEME ==  1044 ,1); type = 'SQ';
            case 'SliceProgressionDirection',                                    i = find( GROUP ==    84 & ELEME ==  1280 ,1); type = 'CS';
            case 'SeriesType',                                                   i = find( GROUP ==    84 & ELEME ==  4096 ,1); type = 'CS';
            case 'Units',                                                        i = find( GROUP ==    84 & ELEME ==  4097 ,1); type = 'CS';
            case 'CountsSource',                                                 i = find( GROUP ==    84 & ELEME ==  4098 ,1); type = 'CS';
            case 'ReprojectionMethod',                                           i = find( GROUP ==    84 & ELEME ==  4100 ,1); type = 'CS';
            case 'RandomsCorrectionMethod',                                      i = find( GROUP ==    84 & ELEME ==  4352 ,1); type = 'CS';
            case 'AttenuationCorrectionMethod',                                  i = find( GROUP ==    84 & ELEME ==  4353 ,1); type = 'LO';
            case 'DecayCorrection',                                              i = find( GROUP ==    84 & ELEME ==  4354 ,1); type = 'CS';
            case 'ReconstructionMethod',                                         i = find( GROUP ==    84 & ELEME ==  4355 ,1); type = 'LO';
            case 'DetectorLinesOfResponseUsed',                                  i = find( GROUP ==    84 & ELEME ==  4356 ,1); type = 'LO';
            case 'ScatterCorrectionMethod',                                      i = find( GROUP ==    84 & ELEME ==  4357 ,1); type = 'LO';
            case 'AxialAcceptance',                                              i = find( GROUP ==    84 & ELEME ==  4608 ,1); type = 'DS';
            case 'AxialMash',                                                    i = find( GROUP ==    84 & ELEME ==  4609 ,1); type = 'IS';
            case 'TransverseMash',                                               i = find( GROUP ==    84 & ELEME ==  4610 ,1); type = 'IS';
            case 'DetectorElementSize',                                          i = find( GROUP ==    84 & ELEME ==  4611 ,1); type = 'DS';
            case 'CoincidenceWindowWidth',                                       i = find( GROUP ==    84 & ELEME ==  4624 ,1); type = 'DS';
            case 'SecondaryCountsType',                                          i = find( GROUP ==    84 & ELEME ==  4640 ,1); type = 'CS';
            case 'FrameReferenceTime',                                           i = find( GROUP ==    84 & ELEME ==  4864 ,1); type = 'DS';
            case 'PrimaryPromptsCountsAccumulated',                              i = find( GROUP ==    84 & ELEME ==  4880 ,1); type = 'IS';
            case 'SecondaryCountsAccumulated',                                   i = find( GROUP ==    84 & ELEME ==  4881 ,1); type = 'IS';
            case 'SliceSensitivityFactor',                                       i = find( GROUP ==    84 & ELEME ==  4896 ,1); type = 'DS';
            case 'DecayFactor',                                                  i = find( GROUP ==    84 & ELEME ==  4897 ,1); type = 'DS';
            case 'DoseCalibrationFactor',                                        i = find( GROUP ==    84 & ELEME ==  4898 ,1); type = 'DS';
            case 'ScatterFractionFactor',                                        i = find( GROUP ==    84 & ELEME ==  4899 ,1); type = 'DS';
            case 'DeadTimeFactor',                                               i = find( GROUP ==    84 & ELEME ==  4900 ,1); type = 'DS';
            case 'ImageIndex',                                                   i = find( GROUP ==    84 & ELEME ==  4912 ,1); type = 'US';
            case 'CountsIncluded',                                               i = find( GROUP ==    84 & ELEME ==  5120 ,1); type = 'CS';
            case 'DeadTimeCorrectionFlag',                                       i = find( GROUP ==    84 & ELEME ==  5121 ,1); type = 'CS';
            case 'HistogramGroupLength',                                         i = find( GROUP ==    96 & ELEME ==     0 ,1); type = 'UL';
            case 'HistogramSequence',                                            i = find( GROUP ==    96 & ELEME == 12288 ,1); type = 'SQ';
            case 'HistogramNumberOfBins',                                        i = find( GROUP ==    96 & ELEME == 12290 ,1); type = 'US';
            case 'HistogramBinWidth',                                            i = find( GROUP ==    96 & ELEME == 12296 ,1); type = 'US';
            case 'HistogramExplanation',                                         i = find( GROUP ==    96 & ELEME == 12304 ,1); type = 'LO';
            case 'HistogramData',                                                i = find( GROUP ==    96 & ELEME == 12320 ,1); type = 'UL';
            case 'GraphicAnnotationSequence',                                    i = find( GROUP ==   112 & ELEME ==     1 ,1); type = 'SQ';
            case 'GraphicLayer',                                                 i = find( GROUP ==   112 & ELEME ==     2 ,1); type = 'CS';
            case 'BoundingBoxAnnotationUnits',                                   i = find( GROUP ==   112 & ELEME ==     3 ,1); type = 'CS';
            case 'AnchorPointAnnotationUnits',                                   i = find( GROUP ==   112 & ELEME ==     4 ,1); type = 'CS';
            case 'GraphicAnnotationUnits',                                       i = find( GROUP ==   112 & ELEME ==     5 ,1); type = 'CS';
            case 'UnformattedTextValue',                                         i = find( GROUP ==   112 & ELEME ==     6 ,1); type = 'ST';
            case 'TextObjectSequence',                                           i = find( GROUP ==   112 & ELEME ==     8 ,1); type = 'SQ';
            case 'GraphicObjectSequence',                                        i = find( GROUP ==   112 & ELEME ==     9 ,1); type = 'SQ';
            case 'BoundingBoxTLHC',                                              i = find( GROUP ==   112 & ELEME ==    16 ,1); type = 'FL';
            case 'BoundingBoxBRHC',                                              i = find( GROUP ==   112 & ELEME ==    17 ,1); type = 'FL';
            case 'BoundingBoxTextHorizontalJustification',                       i = find( GROUP ==   112 & ELEME ==    18 ,1); type = 'CS';
            case 'AnchorPoint',                                                  i = find( GROUP ==   112 & ELEME ==    20 ,1); type = 'FL';
            case 'AnchorPointVisibility',                                        i = find( GROUP ==   112 & ELEME ==    21 ,1); type = 'CS';
            case 'GraphicDimensions',                                            i = find( GROUP ==   112 & ELEME ==    32 ,1); type = 'US';
            case 'NumberOfGraphicPoints',                                        i = find( GROUP ==   112 & ELEME ==    33 ,1); type = 'US';
            case 'GraphicData',                                                  i = find( GROUP ==   112 & ELEME ==    34 ,1); type = 'FL';
            case 'GraphicType',                                                  i = find( GROUP ==   112 & ELEME ==    35 ,1); type = 'CS';
            case 'GraphicFilled',                                                i = find( GROUP ==   112 & ELEME ==    36 ,1); type = 'CS';
            case 'ImageRotationFrozenDraftRetired',                              i = find( GROUP ==   112 & ELEME ==    64 ,1); type = 'IS';
            case 'ImageHorizontalFlip',                                          i = find( GROUP ==   112 & ELEME ==    65 ,1); type = 'CS';
            case 'ImageRotation',                                                i = find( GROUP ==   112 & ELEME ==    66 ,1); type = 'US';
            case 'DisplayedAreaTLHCFrozenDraftRetired',                          i = find( GROUP ==   112 & ELEME ==    80 ,1); type = 'US';
            case 'DisplayedAreaBRHCFrozenDraftRetired',                          i = find( GROUP ==   112 & ELEME ==    81 ,1); type = 'US';
            case 'DisplayedAreaTLHC',                                            i = find( GROUP ==   112 & ELEME ==    82 ,1); type = 'SL';
            case 'DisplayedAreaBRHC',                                            i = find( GROUP ==   112 & ELEME ==    83 ,1); type = 'SL';
            case 'DisplayedAreaSelectionSequence',                               i = find( GROUP ==   112 & ELEME ==    90 ,1); type = 'SQ';
            case 'GraphicLayerSequence',                                         i = find( GROUP ==   112 & ELEME ==    96 ,1); type = 'SQ';
            case 'GraphicLayerOrder',                                            i = find( GROUP ==   112 & ELEME ==    98 ,1); type = 'IS';
            case 'GraphicLayerRecommendedDisplayGrayscaleValue',                 i = find( GROUP ==   112 & ELEME ==   102 ,1); type = 'US';
            case 'GraphicLayerRecommendedDisplayRGBValue',                       i = find( GROUP ==   112 & ELEME ==   103 ,1); type = 'US';
            case 'GraphicLayerDescription',                                      i = find( GROUP ==   112 & ELEME ==   104 ,1); type = 'LO';
            case 'ContentLabel',                                                 i = find( GROUP ==   112 & ELEME ==   128 ,1); type = 'CS';
            case 'ContentDescription',                                           i = find( GROUP ==   112 & ELEME ==   129 ,1); type = 'LO';
            case 'PresentationCreationDate',                                     i = find( GROUP ==   112 & ELEME ==   130 ,1); type = 'DA';
            case 'PresentationCreationTime',                                     i = find( GROUP ==   112 & ELEME ==   131 ,1); type = 'TM';
            case 'ContentCreatorsName',                                          i = find( GROUP ==   112 & ELEME ==   132 ,1); type = 'PN';
            case 'PresentationSizeMode',                                         i = find( GROUP ==   112 & ELEME ==   256 ,1); type = 'CS';
            case 'PresentationPixelSpacing',                                     i = find( GROUP ==   112 & ELEME ==   257 ,1); type = 'DS';
            case 'PresentationPixelAspectRatio',                                 i = find( GROUP ==   112 & ELEME ==   258 ,1); type = 'IS';
            case 'PresentationPixelMagnificationRatio',                          i = find( GROUP ==   112 & ELEME ==   259 ,1); type = 'FL';
            case 'ShapeType',                                                    i = find( GROUP ==   112 & ELEME ==   774 ,1); type = 'CS';
            case 'RegistrationSequence',                                         i = find( GROUP ==   112 & ELEME ==   776 ,1); type = 'SQ';
            case 'MatrixRegistrationSequence',                                   i = find( GROUP ==   112 & ELEME ==   777 ,1); type = 'SQ';
            case 'MatrixSequence',                                               i = find( GROUP ==   112 & ELEME ==   778 ,1); type = 'SQ';
            case 'FrameOfReferenceTransformationMatrixType',                     i = find( GROUP ==   112 & ELEME ==   780 ,1); type = 'CS';
            case 'RegistrationTypeCodeSequence',                                 i = find( GROUP ==   112 & ELEME ==   781 ,1); type = 'SQ';
            case 'FiducialDescription',                                          i = find( GROUP ==   112 & ELEME ==   783 ,1); type = 'ST';
            case 'FiducialIdentifier',                                           i = find( GROUP ==   112 & ELEME ==   784 ,1); type = 'SH';
            case 'FiducialIdentifierCodeSequence',                               i = find( GROUP ==   112 & ELEME ==   785 ,1); type = 'SQ';
            case 'ContourUncertaintyRadius',                                     i = find( GROUP ==   112 & ELEME ==   786 ,1); type = 'FD';
            case 'UsedFiducialsSequence',                                        i = find( GROUP ==   112 & ELEME ==   788 ,1); type = 'SQ';
            case 'GraphicCoordinatesDataSequence',                               i = find( GROUP ==   112 & ELEME ==   792 ,1); type = 'SQ';
            case 'FiducialUID',                                                  i = find( GROUP ==   112 & ELEME ==   794 ,1); type = 'UI';
            case 'FiducialSetSequence',                                          i = find( GROUP ==   112 & ELEME ==   796 ,1); type = 'SQ';
            case 'FiducialSequence',                                             i = find( GROUP ==   112 & ELEME ==   798 ,1); type = 'SQ';
            case 'HangingProtocolName',                                          i = find( GROUP ==   114 & ELEME ==     2 ,1); type = 'SH';
            case 'HangingProtocolDescription',                                   i = find( GROUP ==   114 & ELEME ==     4 ,1); type = 'LO';
            case 'HangingProtocolLevel',                                         i = find( GROUP ==   114 & ELEME ==     6 ,1); type = 'CS';
            case 'HangingProtocolCreator',                                       i = find( GROUP ==   114 & ELEME ==     8 ,1); type = 'LO';
            case 'HangingProtocolCreationDatetime',                              i = find( GROUP ==   114 & ELEME ==    10 ,1); type = 'DT';
            case 'HangingProtocolDefinitionSequence',                            i = find( GROUP ==   114 & ELEME ==    12 ,1); type = 'SQ';
            case 'HangingProtocolUserIdentificationCodeSequence',                i = find( GROUP ==   114 & ELEME ==    14 ,1); type = 'SQ';
            case 'HangingProtocolUserGroupName',                                 i = find( GROUP ==   114 & ELEME ==    16 ,1); type = 'LO';
            case 'SourceHangingProtocolSequence',                                i = find( GROUP ==   114 & ELEME ==    18 ,1); type = 'SQ';
            case 'NumberOfPriorsReferenced',                                     i = find( GROUP ==   114 & ELEME ==    20 ,1); type = 'US';
            case 'ImageSetsSequence',                                            i = find( GROUP ==   114 & ELEME ==    32 ,1); type = 'SQ';
            case 'ImageSetSelectorSequence',                                     i = find( GROUP ==   114 & ELEME ==    34 ,1); type = 'SQ';
            case 'ImageSetSelectorUsageFlag',                                    i = find( GROUP ==   114 & ELEME ==    36 ,1); type = 'CS';
            case 'SelectorAttribute',                                            i = find( GROUP ==   114 & ELEME ==    38 ,1); type = 'AT';
            case 'SelectorValueNumber',                                          i = find( GROUP ==   114 & ELEME ==    40 ,1); type = 'US';
            case 'TimeBasedImageSetsSequence',                                   i = find( GROUP ==   114 & ELEME ==    48 ,1); type = 'SQ';
            case 'ImageSetNumber',                                               i = find( GROUP ==   114 & ELEME ==    50 ,1); type = 'US';
            case 'ImageSetSelectorCategory',                                     i = find( GROUP ==   114 & ELEME ==    52 ,1); type = 'CS';
            case 'RelativeTime',                                                 i = find( GROUP ==   114 & ELEME ==    56 ,1); type = 'US';
            case 'RelativeTimeUnits',                                            i = find( GROUP ==   114 & ELEME ==    58 ,1); type = 'CS';
            case 'AbstractPriorValue',                                           i = find( GROUP ==   114 & ELEME ==    60 ,1); type = 'SS';
            case 'AbstractPriorCodeSequence',                                    i = find( GROUP ==   114 & ELEME ==    62 ,1); type = 'SQ';
            case 'ImageSetLabel',                                                i = find( GROUP ==   114 & ELEME ==    64 ,1); type = 'LO';
            case 'SelectorAttributeVR',                                          i = find( GROUP ==   114 & ELEME ==    80 ,1); type = 'CS';
            case 'SelectorSequencePointer',                                      i = find( GROUP ==   114 & ELEME ==    82 ,1); type = 'AT';
            case 'SelectorSequencePointerPrivateCreator',                        i = find( GROUP ==   114 & ELEME ==    84 ,1); type = 'LO';
            case 'SelectorAttributePrivateCreator',                              i = find( GROUP ==   114 & ELEME ==    86 ,1); type = 'LO';
            case 'SelectorATValue',                                              i = find( GROUP ==   114 & ELEME ==    96 ,1); type = 'AT';
            case 'SelectorCSValue',                                              i = find( GROUP ==   114 & ELEME ==    98 ,1); type = 'CS';
            case 'SelectorISValue',                                              i = find( GROUP ==   114 & ELEME ==   100 ,1); type = 'IS';
            case 'SelectorLOValue',                                              i = find( GROUP ==   114 & ELEME ==   102 ,1); type = 'LO';
            case 'SelectorLTValue',                                              i = find( GROUP ==   114 & ELEME ==   104 ,1); type = 'LT';
            case 'SelectorPNValue',                                              i = find( GROUP ==   114 & ELEME ==   106 ,1); type = 'PN';
            case 'SelectorSHValue',                                              i = find( GROUP ==   114 & ELEME ==   108 ,1); type = 'SH';
            case 'SelectorSTValue',                                              i = find( GROUP ==   114 & ELEME ==   110 ,1); type = 'ST';
            case 'SelectorUTValue',                                              i = find( GROUP ==   114 & ELEME ==   112 ,1); type = 'UT';
            case 'SelectorDSValue',                                              i = find( GROUP ==   114 & ELEME ==   114 ,1); type = 'DS';
            case 'SelectorFDValue',                                              i = find( GROUP ==   114 & ELEME ==   116 ,1); type = 'FD';
            case 'SelectorFLValue',                                              i = find( GROUP ==   114 & ELEME ==   118 ,1); type = 'FL';
            case 'SelectorULValue',                                              i = find( GROUP ==   114 & ELEME ==   120 ,1); type = 'UL';
            case 'SelectorUSValue',                                              i = find( GROUP ==   114 & ELEME ==   122 ,1); type = 'US';
            case 'SelectorSLValue',                                              i = find( GROUP ==   114 & ELEME ==   124 ,1); type = 'SL';
            case 'SelectorSSValue',                                              i = find( GROUP ==   114 & ELEME ==   126 ,1); type = 'SS';
            case 'SelectorCodeSequenceValue',                                    i = find( GROUP ==   114 & ELEME ==   128 ,1); type = 'SQ';
            case 'NumberOfScreens',                                              i = find( GROUP ==   114 & ELEME ==   256 ,1); type = 'US';
            case 'NominalScreenDefinitionSequence',                              i = find( GROUP ==   114 & ELEME ==   258 ,1); type = 'SQ';
            case 'NumberOfVerticalPixels',                                       i = find( GROUP ==   114 & ELEME ==   260 ,1); type = 'US';
            case 'NumberOfHorizontalPixels',                                     i = find( GROUP ==   114 & ELEME ==   262 ,1); type = 'US';
            case 'DisplayEnvironmentSpatialPosition',                            i = find( GROUP ==   114 & ELEME ==   264 ,1); type = 'FD';
            case 'ScreenMinimumGrayscaleBitDepth',                               i = find( GROUP ==   114 & ELEME ==   266 ,1); type = 'US';
            case 'ScreenMinimumColorBitDepth',                                   i = find( GROUP ==   114 & ELEME ==   268 ,1); type = 'US';
            case 'ApplicationMaximumRepaintTime',                                i = find( GROUP ==   114 & ELEME ==   270 ,1); type = 'US';
            case 'DisplaySetsSequence',                                          i = find( GROUP ==   114 & ELEME ==   512 ,1); type = 'SQ';
            case 'DisplaySetNumber',                                             i = find( GROUP ==   114 & ELEME ==   514 ,1); type = 'US';
            case 'DisplaySetPresentationGroup',                                  i = find( GROUP ==   114 & ELEME ==   516 ,1); type = 'US';
            case 'DisplaySetPresentationGroupDescription',                       i = find( GROUP ==   114 & ELEME ==   518 ,1); type = 'LO';
            case 'PartialDataDisplayHandling',                                   i = find( GROUP ==   114 & ELEME ==   520 ,1); type = 'CS';
            case 'SynchronizedScrollingSequence',                                i = find( GROUP ==   114 & ELEME ==   528 ,1); type = 'SQ';
            case 'DisplaySetScrollingGroup',                                     i = find( GROUP ==   114 & ELEME ==   530 ,1); type = 'US';
            case 'NavigationIndicatorSequence',                                  i = find( GROUP ==   114 & ELEME ==   532 ,1); type = 'SQ';
            case 'NavigationDisplaySet',                                         i = find( GROUP ==   114 & ELEME ==   534 ,1); type = 'US';
            case 'ReferenceDisplaySets',                                         i = find( GROUP ==   114 & ELEME ==   536 ,1); type = 'US';
            case 'ImageBoxesSequence',                                           i = find( GROUP ==   114 & ELEME ==   768 ,1); type = 'SQ';
            case 'ImageBoxNumber',                                               i = find( GROUP ==   114 & ELEME ==   770 ,1); type = 'US';
            case 'ImageBoxLayoutType',                                           i = find( GROUP ==   114 & ELEME ==   772 ,1); type = 'CS';
            case 'ImageBoxTileHorizontalDimension',                              i = find( GROUP ==   114 & ELEME ==   774 ,1); type = 'US';
            case 'ImageBoxTileVerticalDimension',                                i = find( GROUP ==   114 & ELEME ==   776 ,1); type = 'US';
            case 'ImageBoxScrollDirection',                                      i = find( GROUP ==   114 & ELEME ==   784 ,1); type = 'CS';
            case 'ImageBoxSmallScrollType',                                      i = find( GROUP ==   114 & ELEME ==   786 ,1); type = 'CS';
            case 'ImageBoxSmallScrollAmount',                                    i = find( GROUP ==   114 & ELEME ==   788 ,1); type = 'US';
            case 'ImageBoxLargeScrollType',                                      i = find( GROUP ==   114 & ELEME ==   790 ,1); type = 'CS';
            case 'ImageBoxLargeScrollAmount',                                    i = find( GROUP ==   114 & ELEME ==   792 ,1); type = 'US';
            case 'ImageBoxOverlapPriority',                                      i = find( GROUP ==   114 & ELEME ==   800 ,1); type = 'US';
            case 'CineRelativeToRealTime',                                       i = find( GROUP ==   114 & ELEME ==   816 ,1); type = 'FD';
            case 'FilterOperationsSequence',                                     i = find( GROUP ==   114 & ELEME ==  1024 ,1); type = 'SQ';
            case 'FilterByCategory',                                             i = find( GROUP ==   114 & ELEME ==  1026 ,1); type = 'CS';
            case 'FilterByAttributePresence',                                    i = find( GROUP ==   114 & ELEME ==  1028 ,1); type = 'CS';
            case 'FilterByOperator',                                             i = find( GROUP ==   114 & ELEME ==  1030 ,1); type = 'CS';
            case 'BlendingOperationType',                                        i = find( GROUP ==   114 & ELEME ==  1280 ,1); type = 'CS';
            case 'ReformattingOperationType',                                    i = find( GROUP ==   114 & ELEME ==  1296 ,1); type = 'CS';
            case 'ReformattingThickness',                                        i = find( GROUP ==   114 & ELEME ==  1298 ,1); type = 'FD';
            case 'ReformattingInterval',                                         i = find( GROUP ==   114 & ELEME ==  1300 ,1); type = 'FD';
            case 'ReformattingOperationInitialViewDirection',                    i = find( GROUP ==   114 & ELEME ==  1302 ,1); type = 'CS';
            case 'ThreeDRenderingType',                                          i = find( GROUP ==   114 & ELEME ==  1312 ,1); type = 'CS';
            case 'SortingOperationsSequence',                                    i = find( GROUP ==   114 & ELEME ==  1536 ,1); type = 'SQ';
            case 'SortByCategory',                                               i = find( GROUP ==   114 & ELEME ==  1538 ,1); type = 'CS';
            case 'SortingDirection',                                             i = find( GROUP ==   114 & ELEME ==  1540 ,1); type = 'CS';
            case 'DisplaySetPatientOrientation',                                 i = find( GROUP ==   114 & ELEME ==  1792 ,1); type = 'CS';
            case 'VOIType',                                                      i = find( GROUP ==   114 & ELEME ==  1794 ,1); type = 'CS';
            case 'PseudocolorType',                                              i = find( GROUP ==   114 & ELEME ==  1796 ,1); type = 'CS';
            case 'ShowGrayscaleInverted',                                        i = find( GROUP ==   114 & ELEME ==  1798 ,1); type = 'CS';
            case 'ShowImageTrueSizeFlag',                                        i = find( GROUP ==   114 & ELEME ==  1808 ,1); type = 'CS';
            case 'ShowGraphicAnnotationFlag',                                    i = find( GROUP ==   114 & ELEME ==  1810 ,1); type = 'CS';
            case 'ShowPatientDemographicsFlag',                                  i = find( GROUP ==   114 & ELEME ==  1812 ,1); type = 'CS';
            case 'ShowAcquisitionTechniquesFlag',                                i = find( GROUP ==   114 & ELEME ==  1814 ,1); type = 'CS';
            case 'StorageGroupLength',                                           i = find( GROUP ==   136 & ELEME ==     0 ,1); type = 'UL';
            case 'StorageMediaFileSetID',                                        i = find( GROUP ==   136 & ELEME ==   304 ,1); type = 'SH';
            case 'StorageMediaFileSetUID',                                       i = find( GROUP ==   136 & ELEME ==   320 ,1); type = 'UI';
            case 'IconImageSequence',                                            i = find( GROUP ==   136 & ELEME ==   512 ,1); type = 'SQ';
            case 'TopicTitle',                                                   i = find( GROUP ==   136 & ELEME ==  2308 ,1); type = 'LO';
            case 'TopicSubject',                                                 i = find( GROUP ==   136 & ELEME ==  2310 ,1); type = 'ST';
            case 'TopicAuthor',                                                  i = find( GROUP ==   136 & ELEME ==  2320 ,1); type = 'LO';
            case 'TopicKeyWords',                                                i = find( GROUP ==   136 & ELEME ==  2322 ,1); type = 'LO';
            case 'SOPInstanceStatus',                                            i = find( GROUP ==   256 & ELEME ==  1040 ,1); type = 'CS';
            case 'SOPAuthorizationDateAndTime',                                  i = find( GROUP ==   256 & ELEME ==  1056 ,1); type = 'DT';
            case 'SOPAuthorizationComment',                                      i = find( GROUP ==   256 & ELEME ==  1060 ,1); type = 'LT';
            case 'AuthorizationEquipmentCertificationNumber',                    i = find( GROUP ==   256 & ELEME ==  1062 ,1); type = 'LO';
            case 'MACIDNumber',                                                  i = find( GROUP ==  1024 & ELEME ==     5 ,1); type = 'US';
            case 'MACCalculationTransferSyntaxUID',                              i = find( GROUP ==  1024 & ELEME ==    16 ,1); type = 'UI';
            case 'MACAlgorithm',                                                 i = find( GROUP ==  1024 & ELEME ==    21 ,1); type = 'CS';
            case 'DataElementsSigned',                                           i = find( GROUP ==  1024 & ELEME ==    32 ,1); type = 'AT';
            case 'DigitalSignatureUID',                                          i = find( GROUP ==  1024 & ELEME ==   256 ,1); type = 'UI';
            case 'DigitalSignatureDateTime',                                     i = find( GROUP ==  1024 & ELEME ==   261 ,1); type = 'DT';
            case 'CertificateType',                                              i = find( GROUP ==  1024 & ELEME ==   272 ,1); type = 'CS';
            case 'CertificateOfSigner',                                          i = find( GROUP ==  1024 & ELEME ==   277 ,1); type = 'OB';
            case 'Signature',                                                    i = find( GROUP ==  1024 & ELEME ==   288 ,1); type = 'OB';
            case 'CertifiedTimestampType',                                       i = find( GROUP ==  1024 & ELEME ==   773 ,1); type = 'CS';
            case 'CertifiedTimestamp',                                           i = find( GROUP ==  1024 & ELEME ==   784 ,1); type = 'OB';
            case 'EncryptedAttributesSequence',                                  i = find( GROUP ==  1024 & ELEME ==  1280 ,1); type = 'SQ';
            case 'EncryptedContentTransferSyntaxUID',                            i = find( GROUP ==  1024 & ELEME ==  1296 ,1); type = 'UI';
            case 'EncryptedContent',                                             i = find( GROUP ==  1024 & ELEME ==  1312 ,1); type = 'OB';
            case 'ModifiedAttributesSequence',                                   i = find( GROUP ==  1024 & ELEME ==  1360 ,1); type = 'SQ';
            case 'CodeTableGroupLength',                                         i = find( GROUP ==  4096 & ELEME ==     0 ,1); type = 'UL';
            case 'EscapeTriplet',                                                i = find( GROUP ==  4096 & ELEME ==    16 ,1); type = 'US';
            case 'RunLengthTriplet',                                             i = find( GROUP ==  4096 & ELEME ==    17 ,1); type = 'US';
            case 'HuffmanTableSize',                                             i = find( GROUP ==  4096 & ELEME ==    18 ,1); type = 'US';
            case 'HuffmanTableTriplet',                                          i = find( GROUP ==  4096 & ELEME ==    19 ,1); type = 'US';
            case 'ShiftTableSize',                                               i = find( GROUP ==  4096 & ELEME ==    20 ,1); type = 'US';
            case 'ShiftTableTriplet',                                            i = find( GROUP ==  4096 & ELEME ==    21 ,1); type = 'US';
            case 'ZonalMapGroupLength',                                          i = find( GROUP ==  4112 & ELEME ==     0 ,1); type = 'UL';
            case 'ZonalMap',                                                     i = find( GROUP ==  4112 & ELEME ==     4 ,1); type = 'US';
            case 'FilmSessionGroupLength',                                       i = find( GROUP ==  8192 & ELEME ==     0 ,1); type = 'UL';
            case 'NumberOfCopies',                                               i = find( GROUP ==  8192 & ELEME ==    16 ,1); type = 'IS';
            case 'PrinterConfigurationSequence',                                 i = find( GROUP ==  8192 & ELEME ==    30 ,1); type = 'SQ';
            case 'PrintPriority',                                                i = find( GROUP ==  8192 & ELEME ==    32 ,1); type = 'CS';
            case 'MediumType',                                                   i = find( GROUP ==  8192 & ELEME ==    48 ,1); type = 'CS';
            case 'FilmDestination',                                              i = find( GROUP ==  8192 & ELEME ==    64 ,1); type = 'CS';
            case 'FilmSessionLabel',                                             i = find( GROUP ==  8192 & ELEME ==    80 ,1); type = 'LO';
            case 'MemoryAllocation',                                             i = find( GROUP ==  8192 & ELEME ==    96 ,1); type = 'IS';
            case 'MaximumMemoryAllocation',                                      i = find( GROUP ==  8192 & ELEME ==    97 ,1); type = 'IS';
            case 'ColorImagePrintingFlag',                                       i = find( GROUP ==  8192 & ELEME ==    98 ,1); type = 'CS';
            case 'CollationFlag',                                                i = find( GROUP ==  8192 & ELEME ==    99 ,1); type = 'CS';
            case 'AnnotationFlag',                                               i = find( GROUP ==  8192 & ELEME ==   101 ,1); type = 'CS';
            case 'ImageOverlayFlag',                                             i = find( GROUP ==  8192 & ELEME ==   103 ,1); type = 'CS';
            case 'PresentationLUTFlag',                                          i = find( GROUP ==  8192 & ELEME ==   105 ,1); type = 'CS';
            case 'ImageBoxPresentationLUTFlag',                                  i = find( GROUP ==  8192 & ELEME ==   106 ,1); type = 'CS';
            case 'MemoryBitDepth',                                               i = find( GROUP ==  8192 & ELEME ==   160 ,1); type = 'US';
            case 'PrintingBitDepth',                                             i = find( GROUP ==  8192 & ELEME ==   161 ,1); type = 'US';
            case 'MediaInstalledSequence',                                       i = find( GROUP ==  8192 & ELEME ==   162 ,1); type = 'SQ';
            case 'OtherMediaAvailableSequence',                                  i = find( GROUP ==  8192 & ELEME ==   164 ,1); type = 'SQ';
            case 'SupportedImageDisplayFormatsSequence',                         i = find( GROUP ==  8192 & ELEME ==   168 ,1); type = 'SQ';
            case 'ReferencedFilmBoxSequence',                                    i = find( GROUP ==  8192 & ELEME ==  1280 ,1); type = 'SQ';
            case 'ReferencedStoredPrintSequence',                                i = find( GROUP ==  8192 & ELEME ==  1296 ,1); type = 'SQ';
            case 'FilmBoxGroupLength',                                           i = find( GROUP ==  8208 & ELEME ==     0 ,1); type = 'UL';
            case 'ImageDisplayFormat',                                           i = find( GROUP ==  8208 & ELEME ==    16 ,1); type = 'ST';
            case 'AnnotationDisplayFormatID',                                    i = find( GROUP ==  8208 & ELEME ==    48 ,1); type = 'CS';
            case 'FilmOrientation',                                              i = find( GROUP ==  8208 & ELEME ==    64 ,1); type = 'CS';
            case 'FilmSizeID',                                                   i = find( GROUP ==  8208 & ELEME ==    80 ,1); type = 'CS';
            case 'PrinterResolutionID',                                          i = find( GROUP ==  8208 & ELEME ==    82 ,1); type = 'CS';
            case 'DefaultPrinterResolutionID',                                   i = find( GROUP ==  8208 & ELEME ==    84 ,1); type = 'CS';
            case 'MagnificationType',                                            i = find( GROUP ==  8208 & ELEME ==    96 ,1); type = 'CS';
            case 'SmoothingType',                                                i = find( GROUP ==  8208 & ELEME ==   128 ,1); type = 'CS';
            case 'DefaultMagnificationType',                                     i = find( GROUP ==  8208 & ELEME ==   166 ,1); type = 'CS';
            case 'OtherMagnificationTypesAvailable',                             i = find( GROUP ==  8208 & ELEME ==   167 ,1); type = 'CS';
            case 'DefaultSmoothingType',                                         i = find( GROUP ==  8208 & ELEME ==   168 ,1); type = 'CS';
            case 'OtherSmoothingTypesAvailable',                                 i = find( GROUP ==  8208 & ELEME ==   169 ,1); type = 'CS';
            case 'BorderDensity',                                                i = find( GROUP ==  8208 & ELEME ==   256 ,1); type = 'CS';
            case 'EmptyImageDensity',                                            i = find( GROUP ==  8208 & ELEME ==   272 ,1); type = 'CS';
            case 'MinDensity',                                                   i = find( GROUP ==  8208 & ELEME ==   288 ,1); type = 'US';
            case 'MaxDensity',                                                   i = find( GROUP ==  8208 & ELEME ==   304 ,1); type = 'US';
            case 'Trim',                                                         i = find( GROUP ==  8208 & ELEME ==   320 ,1); type = 'CS';
            case 'ConfigurationInformation',                                     i = find( GROUP ==  8208 & ELEME ==   336 ,1); type = 'ST';
            case 'ConfigurationInformationDescription',                          i = find( GROUP ==  8208 & ELEME ==   338 ,1); type = 'LT';
            case 'MaximumCollatedFilms',                                         i = find( GROUP ==  8208 & ELEME ==   340 ,1); type = 'IS';
            case 'Illumination',                                                 i = find( GROUP ==  8208 & ELEME ==   350 ,1); type = 'US';
            case 'ReflectedAmbientLight',                                        i = find( GROUP ==  8208 & ELEME ==   352 ,1); type = 'US';
            case 'PrinterPixelSpacing',                                          i = find( GROUP ==  8208 & ELEME ==   886 ,1); type = 'DS';
            case 'ReferencedFilmSessionSequence',                                i = find( GROUP ==  8208 & ELEME ==  1280 ,1); type = 'SQ';
            case 'ReferencedImageBoxSequence',                                   i = find( GROUP ==  8208 & ELEME ==  1296 ,1); type = 'SQ';
            case 'ReferencedBasicAnnotationBoxSequence',                         i = find( GROUP ==  8208 & ELEME ==  1312 ,1); type = 'SQ';
            case 'ImageBoxGroupLength',                                          i = find( GROUP ==  8224 & ELEME ==     0 ,1); type = 'UL';
            case 'ImageBoxPosition',                                             i = find( GROUP ==  8224 & ELEME ==    16 ,1); type = 'US';
            case 'Polarity',                                                     i = find( GROUP ==  8224 & ELEME ==    32 ,1); type = 'CS';
            case 'RequestedImageSize',                                           i = find( GROUP ==  8224 & ELEME ==    48 ,1); type = 'DS';
            case 'RequestedDecimateCropBehavior',                                i = find( GROUP ==  8224 & ELEME ==    64 ,1); type = 'CS';
            case 'RequestedResolutionID',                                        i = find( GROUP ==  8224 & ELEME ==    80 ,1); type = 'CS';
            case 'RequestedImageSizeFlag',                                       i = find( GROUP ==  8224 & ELEME ==   160 ,1); type = 'CS';
            case 'DecimateCropResult',                                           i = find( GROUP ==  8224 & ELEME ==   162 ,1); type = 'CS';
            case 'BasicGrayscaleImageSequence',                                  i = find( GROUP ==  8224 & ELEME ==   272 ,1); type = 'SQ';
            case 'BasicColorImageSequence',                                      i = find( GROUP ==  8224 & ELEME ==   273 ,1); type = 'SQ';
            case 'ReferencedImageOverlayBoxSequence',                            i = find( GROUP ==  8224 & ELEME ==   304 ,1); type = 'SQ';
            case 'ReferencedVOILUTBoxSequence',                                  i = find( GROUP ==  8224 & ELEME ==   320 ,1); type = 'SQ';
            case 'AnnotationGroupLength',                                        i = find( GROUP ==  8240 & ELEME ==     0 ,1); type = 'UL';
            case 'AnnotationPosition',                                           i = find( GROUP ==  8240 & ELEME ==    16 ,1); type = 'US';
            case 'TextString',                                                   i = find( GROUP ==  8240 & ELEME ==    32 ,1); type = 'LO';
            case 'OverlayBoxGroupLength',                                        i = find( GROUP ==  8256 & ELEME ==     0 ,1); type = 'UL';
            case 'ReferencedOverlayPlaneSequence',                               i = find( GROUP ==  8256 & ELEME ==    16 ,1); type = 'SQ';
            case 'ReferencedOverlayPlaneGroups',                                 i = find( GROUP ==  8256 & ELEME ==    17 ,1); type = 'US';
            case 'OverlayPixelDataSequence',                                     i = find( GROUP ==  8256 & ELEME ==    32 ,1); type = 'SQ';
            case 'OverlayMagnificationType',                                     i = find( GROUP ==  8256 & ELEME ==    96 ,1); type = 'CS';
            case 'OverlaySmoothingType',                                         i = find( GROUP ==  8256 & ELEME ==   112 ,1); type = 'CS';
            case 'OverlayOrImageMagnification',                                  i = find( GROUP ==  8256 & ELEME ==   114 ,1); type = 'CS';
            case 'MagnifyToNumberOfColumns',                                     i = find( GROUP ==  8256 & ELEME ==   116 ,1); type = 'US';
            case 'OverlayForegroundDensity',                                     i = find( GROUP ==  8256 & ELEME ==   128 ,1); type = 'CS';
            case 'OverlayBackgroundDensity',                                     i = find( GROUP ==  8256 & ELEME ==   130 ,1); type = 'CS';
            case 'OverlayMode',                                                  i = find( GROUP ==  8256 & ELEME ==   144 ,1); type = 'CS';
            case 'ThresholdDensity',                                             i = find( GROUP ==  8256 & ELEME ==   256 ,1); type = 'CS';
            case 'ReferencedImageBoxSequence',                                   i = find( GROUP ==  8256 & ELEME ==  1280 ,1); type = 'SQ';
            case 'PresentationLUTGroupLength',                                   i = find( GROUP ==  8272 & ELEME ==     0 ,1); type = 'UL';
            case 'PresentationLUTSequence',                                      i = find( GROUP ==  8272 & ELEME ==    16 ,1); type = 'SQ';
            case 'PresentationLUTShape',                                         i = find( GROUP ==  8272 & ELEME ==    32 ,1); type = 'CS';
            case 'ReferencedPresentationLUTSequence',                            i = find( GROUP ==  8272 & ELEME ==  1280 ,1); type = 'SQ';
            case 'PrintJobGroupLength',                                          i = find( GROUP ==  8448 & ELEME ==     0 ,1); type = 'UL';
            case 'PrintJobID',                                                   i = find( GROUP ==  8448 & ELEME ==    16 ,1); type = 'SH';
            case 'ExecutionStatus',                                              i = find( GROUP ==  8448 & ELEME ==    32 ,1); type = 'CS';
            case 'ExecutionStatusInfo',                                          i = find( GROUP ==  8448 & ELEME ==    48 ,1); type = 'CS';
            case 'CreationDate',                                                 i = find( GROUP ==  8448 & ELEME ==    64 ,1); type = 'DA';
            case 'CreationTime',                                                 i = find( GROUP ==  8448 & ELEME ==    80 ,1); type = 'TM';
            case 'Originator',                                                   i = find( GROUP ==  8448 & ELEME ==   112 ,1); type = 'AE';
            case 'DestinationAE',                                                i = find( GROUP ==  8448 & ELEME ==   320 ,1); type = 'AE';
            case 'OwnerID',                                                      i = find( GROUP ==  8448 & ELEME ==   352 ,1); type = 'SH';
            case 'NumberOfFilms',                                                i = find( GROUP ==  8448 & ELEME ==   368 ,1); type = 'IS';
            case 'ReferencedPrintJobSequencePull',                               i = find( GROUP ==  8448 & ELEME ==  1280 ,1); type = 'SQ';
            case 'PrinterGroupLength',                                           i = find( GROUP ==  8464 & ELEME ==     0 ,1); type = 'UL';
            case 'PrinterStatus',                                                i = find( GROUP ==  8464 & ELEME ==    16 ,1); type = 'CS';
            case 'PrinterStatusInfo',                                            i = find( GROUP ==  8464 & ELEME ==    32 ,1); type = 'CS';
            case 'PrinterName',                                                  i = find( GROUP ==  8464 & ELEME ==    48 ,1); type = 'LO';
            case 'PrintQueueID',                                                 i = find( GROUP ==  8464 & ELEME ==   153 ,1); type = 'SH';
            case 'PrintJobGroupLength',                                          i = find( GROUP ==  8480 & ELEME ==     0 ,1); type = 'UL';
            case 'QueueStatus',                                                  i = find( GROUP ==  8480 & ELEME ==    16 ,1); type = 'CS';
            case 'PrintJobDescriptionSequence',                                  i = find( GROUP ==  8480 & ELEME ==    80 ,1); type = 'SQ';
            case 'ReferencedPrintJobSequenceQueue',                              i = find( GROUP ==  8480 & ELEME ==   112 ,1); type = 'SQ';
            case 'PrintSequenceGroupLength',                                     i = find( GROUP ==  8496 & ELEME ==     0 ,1); type = 'UL';
            case 'PrintManagementCapabilitiesSequence',                          i = find( GROUP ==  8496 & ELEME ==    16 ,1); type = 'SQ';
            case 'PrinterCharacteristicsSequence',                               i = find( GROUP ==  8496 & ELEME ==    21 ,1); type = 'SQ';
            case 'FilmBoxContentSequence',                                       i = find( GROUP ==  8496 & ELEME ==    48 ,1); type = 'SQ';
            case 'ImageBoxContentSequence',                                      i = find( GROUP ==  8496 & ELEME ==    64 ,1); type = 'SQ';
            case 'AnnotationContentSequence',                                    i = find( GROUP ==  8496 & ELEME ==    80 ,1); type = 'SQ';
            case 'ImageOverlayBoxContentSequence',                               i = find( GROUP ==  8496 & ELEME ==    96 ,1); type = 'SQ';
            case 'PresentationLUTContentSequence',                               i = find( GROUP ==  8496 & ELEME ==   128 ,1); type = 'SQ';
            case 'ProposedStudySequence',                                        i = find( GROUP ==  8496 & ELEME ==   160 ,1); type = 'SQ';
            case 'OriginalImageSequence',                                        i = find( GROUP ==  8496 & ELEME ==   192 ,1); type = 'SQ';
            case 'RTGroupLength',                                                i = find( GROUP == 12290 & ELEME ==     0 ,1); type = 'UL';
            case 'RTImageLabel',                                                 i = find( GROUP == 12290 & ELEME ==     2 ,1); type = 'SH';
            case 'RTImageName',                                                  i = find( GROUP == 12290 & ELEME ==     3 ,1); type = 'LO';
            case 'RTImageDescription',                                           i = find( GROUP == 12290 & ELEME ==     4 ,1); type = 'ST';
            case 'ReportedValuesOrigin',                                         i = find( GROUP == 12290 & ELEME ==    10 ,1); type = 'CS';
            case 'RTImagePlane',                                                 i = find( GROUP == 12290 & ELEME ==    12 ,1); type = 'CS';
            case 'XRayImageReceptorAngle',                                       i = find( GROUP == 12290 & ELEME ==    14 ,1); type = 'DS';
            case 'RTImageOrientation',                                           i = find( GROUP == 12290 & ELEME ==    16 ,1); type = 'DS';
            case 'ImagePlanePixelSpacing',                                       i = find( GROUP == 12290 & ELEME ==    17 ,1); type = 'DS';
            case 'RTImagePosition',                                              i = find( GROUP == 12290 & ELEME ==    18 ,1); type = 'DS';
            case 'RadiationMachineName',                                         i = find( GROUP == 12290 & ELEME ==    32 ,1); type = 'SH';
            case 'RadiationMachineSAD',                                          i = find( GROUP == 12290 & ELEME ==    34 ,1); type = 'DS';
            case 'RadiationMachineSSD',                                          i = find( GROUP == 12290 & ELEME ==    36 ,1); type = 'DS';
            case 'RTImageSID',                                                   i = find( GROUP == 12290 & ELEME ==    38 ,1); type = 'DS';
            case 'SourceToReferenceObjectDistance',                              i = find( GROUP == 12290 & ELEME ==    40 ,1); type = 'DS';
            case 'FractionNumber',                                               i = find( GROUP == 12290 & ELEME ==    41 ,1); type = 'IS';
            case 'ExposureSequence',                                             i = find( GROUP == 12290 & ELEME ==    48 ,1); type = 'SQ';
            case 'MetersetExposure',                                             i = find( GROUP == 12290 & ELEME ==    50 ,1); type = 'DS';
            case 'DiaphragmPosition',                                            i = find( GROUP == 12290 & ELEME ==    52 ,1); type = 'DS';
            case 'DoseGroupLength',                                              i = find( GROUP == 12292 & ELEME ==     0 ,1); type = 'UL';
            case 'DVHType',                                                      i = find( GROUP == 12292 & ELEME ==     1 ,1); type = 'CS';
            case 'DoseUnits',                                                    i = find( GROUP == 12292 & ELEME ==     2 ,1); type = 'CS';
            case 'DoseType',                                                     i = find( GROUP == 12292 & ELEME ==     4 ,1); type = 'CS';
            case 'DoseComment',                                                  i = find( GROUP == 12292 & ELEME ==     6 ,1); type = 'LO';
            case 'NormalizationPoint',                                           i = find( GROUP == 12292 & ELEME ==     8 ,1); type = 'DS';
            case 'DoseSummationType',                                            i = find( GROUP == 12292 & ELEME ==    10 ,1); type = 'CS';
            case 'GridFrameOffsetVector',                                        i = find( GROUP == 12292 & ELEME ==    12 ,1); type = 'DS';
            case 'DoseGridScaling',                                              i = find( GROUP == 12292 & ELEME ==    14 ,1); type = 'DS';
            case 'RTDoseROISequence',                                            i = find( GROUP == 12292 & ELEME ==    16 ,1); type = 'SQ';
            case 'DoseValue',                                                    i = find( GROUP == 12292 & ELEME ==    18 ,1); type = 'DS';
            case 'TissueHeterogeneityCorrection',                                i = find( GROUP == 12292 & ELEME ==    20 ,1); type = 'CS';
            case 'DVHNormalizationPoint',                                        i = find( GROUP == 12292 & ELEME ==    64 ,1); type = 'DS';
            case 'DVHNormalizationDoseValue',                                    i = find( GROUP == 12292 & ELEME ==    66 ,1); type = 'DS';
            case 'DVHSequence',                                                  i = find( GROUP == 12292 & ELEME ==    80 ,1); type = 'SQ';
            case 'DVHDoseScaling',                                               i = find( GROUP == 12292 & ELEME ==    82 ,1); type = 'DS';
            case 'DVHVolumeUnits',                                               i = find( GROUP == 12292 & ELEME ==    84 ,1); type = 'CS';
            case 'DVHNumberOfBins',                                              i = find( GROUP == 12292 & ELEME ==    86 ,1); type = 'IS';
            case 'DVHData',                                                      i = find( GROUP == 12292 & ELEME ==    88 ,1); type = 'DS';
            case 'DVHReferencedROISequence',                                     i = find( GROUP == 12292 & ELEME ==    96 ,1); type = 'SQ';
            case 'DVHROIContributionType',                                       i = find( GROUP == 12292 & ELEME ==    98 ,1); type = 'CS';
            case 'DVHMinimumDose',                                               i = find( GROUP == 12292 & ELEME ==   112 ,1); type = 'DS';
            case 'DVHMaximumDose',                                               i = find( GROUP == 12292 & ELEME ==   114 ,1); type = 'DS';
            case 'DVHMeanDose',                                                  i = find( GROUP == 12292 & ELEME ==   116 ,1); type = 'DS';
            case 'ROIGroupLength',                                               i = find( GROUP == 12294 & ELEME ==     0 ,1); type = 'UL';
            case 'StructureSetLabel',                                            i = find( GROUP == 12294 & ELEME ==     2 ,1); type = 'SH';
            case 'StructureSetName',                                             i = find( GROUP == 12294 & ELEME ==     4 ,1); type = 'LO';
            case 'StructureSetDescription',                                      i = find( GROUP == 12294 & ELEME ==     6 ,1); type = 'ST';
            case 'StructureSetDate',                                             i = find( GROUP == 12294 & ELEME ==     8 ,1); type = 'DA';
            case 'StructureSetTime',                                             i = find( GROUP == 12294 & ELEME ==     9 ,1); type = 'TM';
            case 'ReferencedFrameOfReferenceSequence',                           i = find( GROUP == 12294 & ELEME ==    16 ,1); type = 'SQ';
            case 'RTReferencedStudySequence',                                    i = find( GROUP == 12294 & ELEME ==    18 ,1); type = 'SQ';
            case 'RTReferencedSeriesSequence',                                   i = find( GROUP == 12294 & ELEME ==    20 ,1); type = 'SQ';
            case 'ContourImageSequence',                                         i = find( GROUP == 12294 & ELEME ==    22 ,1); type = 'SQ';
            case 'StructureSetROISequence',                                      i = find( GROUP == 12294 & ELEME ==    32 ,1); type = 'SQ';
            case 'ROINumber',                                                    i = find( GROUP == 12294 & ELEME ==    34 ,1); type = 'IS';
            case 'ReferencedFrameOfReferenceUID',                                i = find( GROUP == 12294 & ELEME ==    36 ,1); type = 'UI';
            case 'ROIName',                                                      i = find( GROUP == 12294 & ELEME ==    38 ,1); type = 'LO';
            case 'ROIDescription',                                               i = find( GROUP == 12294 & ELEME ==    40 ,1); type = 'ST';
            case 'ROIDisplayColor',                                              i = find( GROUP == 12294 & ELEME ==    42 ,1); type = 'IS';
            case 'ROIVolume',                                                    i = find( GROUP == 12294 & ELEME ==    44 ,1); type = 'DS';
            case 'RTRelatedROISequence',                                         i = find( GROUP == 12294 & ELEME ==    48 ,1); type = 'SQ';
            case 'RTROIRelationship',                                            i = find( GROUP == 12294 & ELEME ==    51 ,1); type = 'CS';
            case 'ROIGenerationAlgorithm',                                       i = find( GROUP == 12294 & ELEME ==    54 ,1); type = 'CS';
            case 'ROIGenerationDescription',                                     i = find( GROUP == 12294 & ELEME ==    56 ,1); type = 'LO';
            case 'ROIContourSequence',                                           i = find( GROUP == 12294 & ELEME ==    57 ,1); type = 'SQ';
            case 'ContourSequence',                                              i = find( GROUP == 12294 & ELEME ==    64 ,1); type = 'SQ';
            case 'ContourGeometricType',                                         i = find( GROUP == 12294 & ELEME ==    66 ,1); type = 'CS';
            case 'ContourSlabThickness',                                         i = find( GROUP == 12294 & ELEME ==    68 ,1); type = 'DS';
            case 'ContourOffsetVector',                                          i = find( GROUP == 12294 & ELEME ==    69 ,1); type = 'DS';
            case 'NumberOfContourPoints',                                        i = find( GROUP == 12294 & ELEME ==    70 ,1); type = 'IS';
            case 'ContourNumber',                                                i = find( GROUP == 12294 & ELEME ==    72 ,1); type = 'IS';
            case 'AttachedContours',                                             i = find( GROUP == 12294 & ELEME ==    73 ,1); type = 'IS';
            case 'ContourData',                                                  i = find( GROUP == 12294 & ELEME ==    80 ,1); type = 'DS';
            case 'RTROIObservationsSequence',                                    i = find( GROUP == 12294 & ELEME ==   128 ,1); type = 'SQ';
            case 'ObservationNumber',                                            i = find( GROUP == 12294 & ELEME ==   130 ,1); type = 'IS';
            case 'ReferencedROINumber',                                          i = find( GROUP == 12294 & ELEME ==   132 ,1); type = 'IS';
            case 'ROIObservationLabel',                                          i = find( GROUP == 12294 & ELEME ==   133 ,1); type = 'SH';
            case 'RTROIIdentificationCodeSequence',                              i = find( GROUP == 12294 & ELEME ==   134 ,1); type = 'SQ';
            case 'ROIObservationDescription',                                    i = find( GROUP == 12294 & ELEME ==   136 ,1); type = 'ST';
            case 'RelatedRTROIObservationsSequence',                             i = find( GROUP == 12294 & ELEME ==   160 ,1); type = 'SQ';
            case 'RTROIInterpretedType',                                         i = find( GROUP == 12294 & ELEME ==   164 ,1); type = 'CS';
            case 'ROIInterpreter',                                               i = find( GROUP == 12294 & ELEME ==   166 ,1); type = 'PN';
            case 'ROIPhysicalPropertiesSequence',                                i = find( GROUP == 12294 & ELEME ==   176 ,1); type = 'SQ';
            case 'ROIPhysicalProperty',                                          i = find( GROUP == 12294 & ELEME ==   178 ,1); type = 'CS';
            case 'ROIPhysicalPropertyValue',                                     i = find( GROUP == 12294 & ELEME ==   180 ,1); type = 'DS';
            case 'FrameOfReferenceRelationshipSequence',                         i = find( GROUP == 12294 & ELEME ==   192 ,1); type = 'SQ';
            case 'RelatedFrameOfReferenceUID',                                   i = find( GROUP == 12294 & ELEME ==   194 ,1); type = 'UI';
            case 'FrameOfReferenceTransformationType',                           i = find( GROUP == 12294 & ELEME ==   196 ,1); type = 'CS';
            case 'FrameOfReferenceTransformationMatrix',                         i = find( GROUP == 12294 & ELEME ==   198 ,1); type = 'DS';
            case 'FrameOfReferenceTransformationComment',                        i = find( GROUP == 12294 & ELEME ==   200 ,1); type = 'LO';
            case 'TreatmentGroupLength',                                         i = find( GROUP == 12296 & ELEME ==     0 ,1); type = 'UL';
            case 'MeasuredDoseReferenceSequence',                                i = find( GROUP == 12296 & ELEME ==    16 ,1); type = 'SQ';
            case 'MeasuredDoseDescription',                                      i = find( GROUP == 12296 & ELEME ==    18 ,1); type = 'ST';
            case 'MeasuredDoseType',                                             i = find( GROUP == 12296 & ELEME ==    20 ,1); type = 'CS';
            case 'MeasuredDoseValue',                                            i = find( GROUP == 12296 & ELEME ==    22 ,1); type = 'DS';
            case 'TreatmentSessionBeamSequence',                                 i = find( GROUP == 12296 & ELEME ==    32 ,1); type = 'SQ';
            case 'CurrentFractionNumber',                                        i = find( GROUP == 12296 & ELEME ==    34 ,1); type = 'IS';
            case 'TreatmentControlPointDate',                                    i = find( GROUP == 12296 & ELEME ==    36 ,1); type = 'DA';
            case 'TreatmentControlPointTime',                                    i = find( GROUP == 12296 & ELEME ==    37 ,1); type = 'TM';
            case 'TreatmentTerminationStatus',                                   i = find( GROUP == 12296 & ELEME ==    42 ,1); type = 'CS';
            case 'TreatmentTerminationCode',                                     i = find( GROUP == 12296 & ELEME ==    43 ,1); type = 'SH';
            case 'TreatmentVerificationStatus',                                  i = find( GROUP == 12296 & ELEME ==    44 ,1); type = 'CS';
            case 'ReferencedTreatmentRecordSequence',                            i = find( GROUP == 12296 & ELEME ==    48 ,1); type = 'SQ';
            case 'SpecifiedPrimaryMeterset',                                     i = find( GROUP == 12296 & ELEME ==    50 ,1); type = 'DS';
            case 'SpecifiedSecondaryMeterset',                                   i = find( GROUP == 12296 & ELEME ==    51 ,1); type = 'DS';
            case 'DeliveredPrimaryMeterset',                                     i = find( GROUP == 12296 & ELEME ==    54 ,1); type = 'DS';
            case 'DeliveredSecondaryMeterset',                                   i = find( GROUP == 12296 & ELEME ==    55 ,1); type = 'DS';
            case 'SpecifiedTreatmentTime',                                       i = find( GROUP == 12296 & ELEME ==    58 ,1); type = 'DS';
            case 'DeliveredTreatmentTime',                                       i = find( GROUP == 12296 & ELEME ==    59 ,1); type = 'DS';
            case 'ControlPointDeliverySequence',                                 i = find( GROUP == 12296 & ELEME ==    64 ,1); type = 'SQ';
            case 'SpecifiedMeterset',                                            i = find( GROUP == 12296 & ELEME ==    66 ,1); type = 'DS';
            case 'DeliveredMeterset',                                            i = find( GROUP == 12296 & ELEME ==    68 ,1); type = 'DS';
            case 'DoseRateDelivered',                                            i = find( GROUP == 12296 & ELEME ==    72 ,1); type = 'DS';
            case 'TreatmentSummaryCalculatedDoseReferenceSequence',              i = find( GROUP == 12296 & ELEME ==    80 ,1); type = 'SQ';
            case 'CumulativeDoseToDoseReference',                                i = find( GROUP == 12296 & ELEME ==    82 ,1); type = 'DS';
            case 'FirstTreatmentDate',                                           i = find( GROUP == 12296 & ELEME ==    84 ,1); type = 'DA';
            case 'MostRecentTreatmentDate',                                      i = find( GROUP == 12296 & ELEME ==    86 ,1); type = 'DA';
            case 'NumberOfFractionsDelivered',                                   i = find( GROUP == 12296 & ELEME ==    90 ,1); type = 'IS';
            case 'OverrideSequence',                                             i = find( GROUP == 12296 & ELEME ==    96 ,1); type = 'SQ';
            case 'OverrideParameterPointer',                                     i = find( GROUP == 12296 & ELEME ==    98 ,1); type = 'AT';
            case 'MeasuredDoseReferenceNumber',                                  i = find( GROUP == 12296 & ELEME ==   100 ,1); type = 'IS';
            case 'OverrideReason',                                               i = find( GROUP == 12296 & ELEME ==   102 ,1); type = 'ST';
            case 'CalculatedDoseReferenceSequence',                              i = find( GROUP == 12296 & ELEME ==   112 ,1); type = 'SQ';
            case 'CalculatedDoseReferenceNumber',                                i = find( GROUP == 12296 & ELEME ==   114 ,1); type = 'IS';
            case 'CalculatedDoseReferenceDescription',                           i = find( GROUP == 12296 & ELEME ==   116 ,1); type = 'ST';
            case 'CalculatedDoseReferenceDoseValue',                             i = find( GROUP == 12296 & ELEME ==   118 ,1); type = 'DS';
            case 'StartMeterset',                                                i = find( GROUP == 12296 & ELEME ==   120 ,1); type = 'DS';
            case 'EndMeterset',                                                  i = find( GROUP == 12296 & ELEME ==   122 ,1); type = 'DS';
            case 'ReferencedMeasuredDoseReferenceSequence',                      i = find( GROUP == 12296 & ELEME ==   128 ,1); type = 'SQ';
            case 'ReferencedMeasuredDoseReferenceNumber',                        i = find( GROUP == 12296 & ELEME ==   130 ,1); type = 'IS';
            case 'ReferencedCalculatedDoseReferenceSequence',                    i = find( GROUP == 12296 & ELEME ==   144 ,1); type = 'SQ';
            case 'ReferencedCalculatedDoseReferenceNumber',                      i = find( GROUP == 12296 & ELEME ==   146 ,1); type = 'IS';
            case 'BeamLimitingDeviceLeafPairsSequence',                          i = find( GROUP == 12296 & ELEME ==   160 ,1); type = 'SQ';
            case 'RecordedWedgeSequence',                                        i = find( GROUP == 12296 & ELEME ==   176 ,1); type = 'SQ';
            case 'RecordedCompensatorSequence',                                  i = find( GROUP == 12296 & ELEME ==   192 ,1); type = 'SQ';
            case 'RecordedBlockSequence',                                        i = find( GROUP == 12296 & ELEME ==   208 ,1); type = 'SQ';
            case 'TreatmentSummaryMeasuredDoseReferenceSequence',                i = find( GROUP == 12296 & ELEME ==   224 ,1); type = 'SQ';
            case 'RecordedSourceSequence',                                       i = find( GROUP == 12296 & ELEME ==   256 ,1); type = 'SQ';
            case 'SourceSerialNumber',                                           i = find( GROUP == 12296 & ELEME ==   261 ,1); type = 'LO';
            case 'TreatmentSessionApplicationSetupSequence',                     i = find( GROUP == 12296 & ELEME ==   272 ,1); type = 'SQ';
            case 'ApplicationSetupCheck',                                        i = find( GROUP == 12296 & ELEME ==   278 ,1); type = 'CS';
            case 'RecordedBrachyAccessoryDeviceSequence',                        i = find( GROUP == 12296 & ELEME ==   288 ,1); type = 'SQ';
            case 'ReferencedBrachyAccessoryDeviceNumber',                        i = find( GROUP == 12296 & ELEME ==   290 ,1); type = 'IS';
            case 'RecordedChannelSequence',                                      i = find( GROUP == 12296 & ELEME ==   304 ,1); type = 'SQ';
            case 'SpecifiedChannelTotalTime',                                    i = find( GROUP == 12296 & ELEME ==   306 ,1); type = 'DS';
            case 'DeliveredChannelTotalTime',                                    i = find( GROUP == 12296 & ELEME ==   308 ,1); type = 'DS';
            case 'SpecifiedNumberOfPulses',                                      i = find( GROUP == 12296 & ELEME ==   310 ,1); type = 'IS';
            case 'DeliveredNumberOfPulses',                                      i = find( GROUP == 12296 & ELEME ==   312 ,1); type = 'IS';
            case 'SpecifiedPulseRepetitionInterval',                             i = find( GROUP == 12296 & ELEME ==   314 ,1); type = 'DS';
            case 'DeliveredPulseRepetitionInterval',                             i = find( GROUP == 12296 & ELEME ==   316 ,1); type = 'DS';
            case 'RecordedSourceApplicatorSequence',                             i = find( GROUP == 12296 & ELEME ==   320 ,1); type = 'SQ';
            case 'ReferencedSourceApplicatorNumber',                             i = find( GROUP == 12296 & ELEME ==   322 ,1); type = 'IS';
            case 'RecordedChannelShieldSequence',                                i = find( GROUP == 12296 & ELEME ==   336 ,1); type = 'SQ';
            case 'ReferencedChannelShieldNumber',                                i = find( GROUP == 12296 & ELEME ==   338 ,1); type = 'IS';
            case 'BrachyControlPointDeliveredSequence',                          i = find( GROUP == 12296 & ELEME ==   352 ,1); type = 'SQ';
            case 'SafePositionExitDate',                                         i = find( GROUP == 12296 & ELEME ==   354 ,1); type = 'DA';
            case 'SafePositionExitTime',                                         i = find( GROUP == 12296 & ELEME ==   356 ,1); type = 'TM';
            case 'SafePositionReturnDate',                                       i = find( GROUP == 12296 & ELEME ==   358 ,1); type = 'DA';
            case 'SafePositionReturnTime',                                       i = find( GROUP == 12296 & ELEME ==   360 ,1); type = 'TM';
            case 'CurrentTreatmentStatus',                                       i = find( GROUP == 12296 & ELEME ==   512 ,1); type = 'CS';
            case 'TreatmentStatusComment',                                       i = find( GROUP == 12296 & ELEME ==   514 ,1); type = 'ST';
            case 'FractionGroupSummarySequence',                                 i = find( GROUP == 12296 & ELEME ==   544 ,1); type = 'SQ';
            case 'ReferencedFractionNumber',                                     i = find( GROUP == 12296 & ELEME ==   547 ,1); type = 'IS';
            case 'FractionGroupType',                                            i = find( GROUP == 12296 & ELEME ==   548 ,1); type = 'CS';
            case 'BeamStopperPosition',                                          i = find( GROUP == 12296 & ELEME ==   560 ,1); type = 'CS';
            case 'FractionStatusSummarySequence',                                i = find( GROUP == 12296 & ELEME ==   576 ,1); type = 'SQ';
            case 'TreatmentDate',                                                i = find( GROUP == 12296 & ELEME ==   592 ,1); type = 'DA';
            case 'TreatmentTime',                                                i = find( GROUP == 12296 & ELEME ==   593 ,1); type = 'TM';
            case 'PlanGroupLength',                                              i = find( GROUP == 12298 & ELEME ==     0 ,1); type = 'UL';
            case 'RTPlanLabel',                                                  i = find( GROUP == 12298 & ELEME ==     2 ,1); type = 'SH';
            case 'RTPlanName',                                                   i = find( GROUP == 12298 & ELEME ==     3 ,1); type = 'LO';
            case 'RTPlanDescription',                                            i = find( GROUP == 12298 & ELEME ==     4 ,1); type = 'ST';
            case 'RTPlanDate',                                                   i = find( GROUP == 12298 & ELEME ==     6 ,1); type = 'DA';
            case 'RTPlanTime',                                                   i = find( GROUP == 12298 & ELEME ==     7 ,1); type = 'TM';
            case 'TreatmentProtocols',                                           i = find( GROUP == 12298 & ELEME ==     9 ,1); type = 'LO';
            case 'TreatmentIntent',                                              i = find( GROUP == 12298 & ELEME ==    10 ,1); type = 'CS';
            case 'TreatmentSites',                                               i = find( GROUP == 12298 & ELEME ==    11 ,1); type = 'LO';
            case 'RTPlanGeometry',                                               i = find( GROUP == 12298 & ELEME ==    12 ,1); type = 'CS';
            case 'PrescriptionDescription',                                      i = find( GROUP == 12298 & ELEME ==    14 ,1); type = 'ST';
            case 'DoseReferenceSequence',                                        i = find( GROUP == 12298 & ELEME ==    16 ,1); type = 'SQ';
            case 'DoseReferenceNumber',                                          i = find( GROUP == 12298 & ELEME ==    18 ,1); type = 'IS';
            case 'DoseReferenceUID',                                             i = find( GROUP == 12298 & ELEME ==    19 ,1); type = 'UI';
            case 'DoseReferenceStructureType',                                   i = find( GROUP == 12298 & ELEME ==    20 ,1); type = 'CS';
            case 'NominalBeamEnergyUnit',                                        i = find( GROUP == 12298 & ELEME ==    21 ,1); type = 'CS';
            case 'DoseReferenceDescription',                                     i = find( GROUP == 12298 & ELEME ==    22 ,1); type = 'LO';
            case 'DoseReferencePointCoordinates',                                i = find( GROUP == 12298 & ELEME ==    24 ,1); type = 'DS';
            case 'NominalPriorDose',                                             i = find( GROUP == 12298 & ELEME ==    26 ,1); type = 'DS';
            case 'DoseReferenceType',                                            i = find( GROUP == 12298 & ELEME ==    32 ,1); type = 'CS';
            case 'ConstraintWeight',                                             i = find( GROUP == 12298 & ELEME ==    33 ,1); type = 'DS';
            case 'DeliveryWarningDose',                                          i = find( GROUP == 12298 & ELEME ==    34 ,1); type = 'DS';
            case 'DeliveryMaximumDose',                                          i = find( GROUP == 12298 & ELEME ==    35 ,1); type = 'DS';
            case 'TargetMinimumDose',                                            i = find( GROUP == 12298 & ELEME ==    37 ,1); type = 'DS';
            case 'TargetPrescriptionDose',                                       i = find( GROUP == 12298 & ELEME ==    38 ,1); type = 'DS';
            case 'TargetMaximumDose',                                            i = find( GROUP == 12298 & ELEME ==    39 ,1); type = 'DS';
            case 'TargetUnderdoseVolumeFraction',                                i = find( GROUP == 12298 & ELEME ==    40 ,1); type = 'DS';
            case 'OrganAtRiskFullVolumeDose',                                    i = find( GROUP == 12298 & ELEME ==    42 ,1); type = 'DS';
            case 'OrganAtRiskLimitDose',                                         i = find( GROUP == 12298 & ELEME ==    43 ,1); type = 'DS';
            case 'OrganAtRiskMaximumDose',                                       i = find( GROUP == 12298 & ELEME ==    44 ,1); type = 'DS';
            case 'OrganAtRiskOverdoseVolumeFraction',                            i = find( GROUP == 12298 & ELEME ==    45 ,1); type = 'DS';
            case 'ToleranceTableSequence',                                       i = find( GROUP == 12298 & ELEME ==    64 ,1); type = 'SQ';
            case 'ToleranceTableNumber',                                         i = find( GROUP == 12298 & ELEME ==    66 ,1); type = 'IS';
            case 'ToleranceTableLabel',                                          i = find( GROUP == 12298 & ELEME ==    67 ,1); type = 'SH';
            case 'GantryAngleTolerance',                                         i = find( GROUP == 12298 & ELEME ==    68 ,1); type = 'DS';
            case 'BeamLimitingDeviceAngleTolerance',                             i = find( GROUP == 12298 & ELEME ==    70 ,1); type = 'DS';
            case 'BeamLimitingDeviceToleranceSequence',                          i = find( GROUP == 12298 & ELEME ==    72 ,1); type = 'SQ';
            case 'BeamLimitingDevicePositionTolerance',                          i = find( GROUP == 12298 & ELEME ==    74 ,1); type = 'DS';
            case 'PatientSupportAngleTolerance',                                 i = find( GROUP == 12298 & ELEME ==    76 ,1); type = 'DS';
            case 'TableTopEccentricAngleTolerance',                              i = find( GROUP == 12298 & ELEME ==    78 ,1); type = 'DS';
            case 'TableTopVerticalPositionTolerance',                            i = find( GROUP == 12298 & ELEME ==    81 ,1); type = 'DS';
            case 'TableTopLongitudinalPositionTolerance',                        i = find( GROUP == 12298 & ELEME ==    82 ,1); type = 'DS';
            case 'TableTopLateralPositionTolerance',                             i = find( GROUP == 12298 & ELEME ==    83 ,1); type = 'DS';
            case 'RTPlanRelationship',                                           i = find( GROUP == 12298 & ELEME ==    85 ,1); type = 'CS';
            case 'FractionGroupSequence',                                        i = find( GROUP == 12298 & ELEME ==   112 ,1); type = 'SQ';
            case 'FractionGroupNumber',                                          i = find( GROUP == 12298 & ELEME ==   113 ,1); type = 'IS';
            case 'FractionGroupDescription',                                     i = find( GROUP == 12298 & ELEME ==   114 ,1); type = 'LO';
            case 'NumberOfFractionsPlanned',                                     i = find( GROUP == 12298 & ELEME ==   120 ,1); type = 'IS';
            case 'NumberOfFractionPatternDigitsPerDay',                          i = find( GROUP == 12298 & ELEME ==   121 ,1); type = 'IS';
            case 'RepeatFractionCycleLength',                                    i = find( GROUP == 12298 & ELEME ==   122 ,1); type = 'IS';
            case 'FractionPattern',                                              i = find( GROUP == 12298 & ELEME ==   123 ,1); type = 'LT';
            case 'NumberOfBeams',                                                i = find( GROUP == 12298 & ELEME ==   128 ,1); type = 'IS';
            case 'BeamDoseSpecificationPoint',                                   i = find( GROUP == 12298 & ELEME ==   130 ,1); type = 'DS';
            case 'BeamDose',                                                     i = find( GROUP == 12298 & ELEME ==   132 ,1); type = 'DS';
            case 'BeamMeterset',                                                 i = find( GROUP == 12298 & ELEME ==   134 ,1); type = 'DS';
            case 'NumberOfBrachyApplicationSetups',                              i = find( GROUP == 12298 & ELEME ==   160 ,1); type = 'IS';
            case 'BrachyApplicationSetupDoseSpecificationPoint',                 i = find( GROUP == 12298 & ELEME ==   162 ,1); type = 'DS';
            case 'BrachyApplicationSetupDose',                                   i = find( GROUP == 12298 & ELEME ==   164 ,1); type = 'DS';
            case 'BeamSequence',                                                 i = find( GROUP == 12298 & ELEME ==   176 ,1); type = 'SQ';
            case 'TreatmentMachineName',                                         i = find( GROUP == 12298 & ELEME ==   178 ,1); type = 'SH';
            case 'PrimaryDosimeterUnit',                                         i = find( GROUP == 12298 & ELEME ==   179 ,1); type = 'CS';
            case 'SourceAxisDistance',                                           i = find( GROUP == 12298 & ELEME ==   180 ,1); type = 'DS';
            case 'BeamLimitingDeviceSequence',                                   i = find( GROUP == 12298 & ELEME ==   182 ,1); type = 'SQ';
            case 'RTBeamLimitingDeviceType',                                     i = find( GROUP == 12298 & ELEME ==   184 ,1); type = 'CS';
            case 'SourceToBeamLimitingDeviceDistance',                           i = find( GROUP == 12298 & ELEME ==   186 ,1); type = 'DS';
            case 'NumberOfLeafJawPairs',                                         i = find( GROUP == 12298 & ELEME ==   188 ,1); type = 'IS';
            case 'LeafPositionBoundaries',                                       i = find( GROUP == 12298 & ELEME ==   190 ,1); type = 'DS';
            case 'BeamNumber',                                                   i = find( GROUP == 12298 & ELEME ==   192 ,1); type = 'IS';
            case 'BeamName',                                                     i = find( GROUP == 12298 & ELEME ==   194 ,1); type = 'LO';
            case 'BeamDescription',                                              i = find( GROUP == 12298 & ELEME ==   195 ,1); type = 'ST';
            case 'BeamType',                                                     i = find( GROUP == 12298 & ELEME ==   196 ,1); type = 'CS';
            case 'RadiationType',                                                i = find( GROUP == 12298 & ELEME ==   198 ,1); type = 'CS';
            case 'HighDoseTechniqueType',                                        i = find( GROUP == 12298 & ELEME ==   199 ,1); type = 'CS';
            case 'ReferenceImageNumber',                                         i = find( GROUP == 12298 & ELEME ==   200 ,1); type = 'IS';
            case 'PlannedVerificationImageSequence',                             i = find( GROUP == 12298 & ELEME ==   202 ,1); type = 'SQ';
            case 'ImagingDeviceSpecificAcquisitionParameters',                   i = find( GROUP == 12298 & ELEME ==   204 ,1); type = 'LO';
            case 'TreatmentDeliveryType',                                        i = find( GROUP == 12298 & ELEME ==   206 ,1); type = 'CS';
            case 'NumberOfWedges',                                               i = find( GROUP == 12298 & ELEME ==   208 ,1); type = 'IS';
            case 'WedgeSequence',                                                i = find( GROUP == 12298 & ELEME ==   209 ,1); type = 'SQ';
            case 'WedgeNumber',                                                  i = find( GROUP == 12298 & ELEME ==   210 ,1); type = 'IS';
            case 'WedgeType',                                                    i = find( GROUP == 12298 & ELEME ==   211 ,1); type = 'CS';
            case 'WedgeID',                                                      i = find( GROUP == 12298 & ELEME ==   212 ,1); type = 'SH';
            case 'WedgeAngle',                                                   i = find( GROUP == 12298 & ELEME ==   213 ,1); type = 'IS';
            case 'WedgeFactor',                                                  i = find( GROUP == 12298 & ELEME ==   214 ,1); type = 'DS';
            case 'WedgeOrientation',                                             i = find( GROUP == 12298 & ELEME ==   216 ,1); type = 'DS';
            case 'SourceToWedgeTrayDistance',                                    i = find( GROUP == 12298 & ELEME ==   218 ,1); type = 'DS';
            case 'NumberOfCompensators',                                         i = find( GROUP == 12298 & ELEME ==   224 ,1); type = 'IS';
            case 'MaterialID',                                                   i = find( GROUP == 12298 & ELEME ==   225 ,1); type = 'SH';
            case 'TotalCompensatorTrayFactor',                                   i = find( GROUP == 12298 & ELEME ==   226 ,1); type = 'DS';
            case 'CompensatorSequence',                                          i = find( GROUP == 12298 & ELEME ==   227 ,1); type = 'SQ';
            case 'CompensatorNumber',                                            i = find( GROUP == 12298 & ELEME ==   228 ,1); type = 'IS';
            case 'CompensatorID',                                                i = find( GROUP == 12298 & ELEME ==   229 ,1); type = 'SH';
            case 'SourceToCompensatorTrayDistance',                              i = find( GROUP == 12298 & ELEME ==   230 ,1); type = 'DS';
            case 'CompensatorRows',                                              i = find( GROUP == 12298 & ELEME ==   231 ,1); type = 'IS';
            case 'CompensatorColumns',                                           i = find( GROUP == 12298 & ELEME ==   232 ,1); type = 'IS';
            case 'CompensatorPixelSpacing',                                      i = find( GROUP == 12298 & ELEME ==   233 ,1); type = 'DS';
            case 'CompensatorPosition',                                          i = find( GROUP == 12298 & ELEME ==   234 ,1); type = 'DS';
            case 'CompensatorTransmissionData',                                  i = find( GROUP == 12298 & ELEME ==   235 ,1); type = 'DS';
            case 'CompensatorThicknessData',                                     i = find( GROUP == 12298 & ELEME ==   236 ,1); type = 'DS';
            case 'NumberOfBoli',                                                 i = find( GROUP == 12298 & ELEME ==   237 ,1); type = 'IS';
            case 'CompensatorType',                                              i = find( GROUP == 12298 & ELEME ==   238 ,1); type = 'CS';
            case 'NumberOfBlocks',                                               i = find( GROUP == 12298 & ELEME ==   240 ,1); type = 'IS';
            case 'TotalBlockTrayFactor',                                         i = find( GROUP == 12298 & ELEME ==   242 ,1); type = 'DS';
            case 'BlockSequence',                                                i = find( GROUP == 12298 & ELEME ==   244 ,1); type = 'SQ';
            case 'BlockTrayID',                                                  i = find( GROUP == 12298 & ELEME ==   245 ,1); type = 'SH';
            case 'SourceToBlockTrayDistance',                                    i = find( GROUP == 12298 & ELEME ==   246 ,1); type = 'DS';
            case 'BlockType',                                                    i = find( GROUP == 12298 & ELEME ==   248 ,1); type = 'CS';
            case 'AccessoryCode',                                                i = find( GROUP == 12298 & ELEME ==   249 ,1); type = 'LO';
            case 'BlockDivergence',                                              i = find( GROUP == 12298 & ELEME ==   250 ,1); type = 'CS';
            case 'BlockMountingPosition',                                        i = find( GROUP == 12298 & ELEME ==   251 ,1); type = 'CS';
            case 'BlockNumber',                                                  i = find( GROUP == 12298 & ELEME ==   252 ,1); type = 'IS';
            case 'BlockName',                                                    i = find( GROUP == 12298 & ELEME ==   254 ,1); type = 'LO';
            case 'BlockThickness',                                               i = find( GROUP == 12298 & ELEME ==   256 ,1); type = 'DS';
            case 'BlockTransmission',                                            i = find( GROUP == 12298 & ELEME ==   258 ,1); type = 'DS';
            case 'BlockNumberOfPoints',                                          i = find( GROUP == 12298 & ELEME ==   260 ,1); type = 'IS';
            case 'BlockData',                                                    i = find( GROUP == 12298 & ELEME ==   262 ,1); type = 'DS';
            case 'ApplicatorSequence',                                           i = find( GROUP == 12298 & ELEME ==   263 ,1); type = 'SQ';
            case 'ApplicatorID',                                                 i = find( GROUP == 12298 & ELEME ==   264 ,1); type = 'SH';
            case 'ApplicatorType',                                               i = find( GROUP == 12298 & ELEME ==   265 ,1); type = 'CS';
            case 'ApplicatorDescription',                                        i = find( GROUP == 12298 & ELEME ==   266 ,1); type = 'LO';
            case 'CumulativeDoseReferenceCoefficient',                           i = find( GROUP == 12298 & ELEME ==   268 ,1); type = 'DS';
            case 'FinalCumulativeMetersetWeight',                                i = find( GROUP == 12298 & ELEME ==   270 ,1); type = 'DS';
            case 'NumberOfControlPoints',                                        i = find( GROUP == 12298 & ELEME ==   272 ,1); type = 'IS';
            case 'ControlPointSequence',                                         i = find( GROUP == 12298 & ELEME ==   273 ,1); type = 'SQ';
            case 'ControlPointIndex',                                            i = find( GROUP == 12298 & ELEME ==   274 ,1); type = 'IS';
            case 'NominalBeamEnergy',                                            i = find( GROUP == 12298 & ELEME ==   276 ,1); type = 'DS';
            case 'DoseRateSet',                                                  i = find( GROUP == 12298 & ELEME ==   277 ,1); type = 'DS';
            case 'WedgePositionSequence',                                        i = find( GROUP == 12298 & ELEME ==   278 ,1); type = 'SQ';
            case 'WedgePosition',                                                i = find( GROUP == 12298 & ELEME ==   280 ,1); type = 'CS';
            case 'BeamLimitingDevicePositionSequence',                           i = find( GROUP == 12298 & ELEME ==   282 ,1); type = 'SQ';
            case 'LeafJawPositions',                                             i = find( GROUP == 12298 & ELEME ==   284 ,1); type = 'DS';
            case 'GantryAngle',                                                  i = find( GROUP == 12298 & ELEME ==   286 ,1); type = 'DS';
            case 'GantryRotationDirection',                                      i = find( GROUP == 12298 & ELEME ==   287 ,1); type = 'CS';
            case 'BeamLimitingDeviceAngle',                                      i = find( GROUP == 12298 & ELEME ==   288 ,1); type = 'DS';
            case 'BeamLimitingDeviceRotationDirection',                          i = find( GROUP == 12298 & ELEME ==   289 ,1); type = 'CS';
            case 'PatientSupportAngle',                                          i = find( GROUP == 12298 & ELEME ==   290 ,1); type = 'DS';
            case 'PatientSupportRotationDirection',                              i = find( GROUP == 12298 & ELEME ==   291 ,1); type = 'CS';
            case 'TableTopEccentricAxisDistance',                                i = find( GROUP == 12298 & ELEME ==   292 ,1); type = 'DS';
            case 'TableTopEccentricAngle',                                       i = find( GROUP == 12298 & ELEME ==   293 ,1); type = 'DS';
            case 'TableTopEccentricRotationDirection',                           i = find( GROUP == 12298 & ELEME ==   294 ,1); type = 'CS';
            case 'TableTopVerticalPosition',                                     i = find( GROUP == 12298 & ELEME ==   296 ,1); type = 'DS';
            case 'TableTopLongitudinalPosition',                                 i = find( GROUP == 12298 & ELEME ==   297 ,1); type = 'DS';
            case 'TableTopLateralPosition',                                      i = find( GROUP == 12298 & ELEME ==   298 ,1); type = 'DS';
            case 'IsocenterPosition',                                            i = find( GROUP == 12298 & ELEME ==   300 ,1); type = 'DS';
            case 'SurfaceEntryPoint',                                            i = find( GROUP == 12298 & ELEME ==   302 ,1); type = 'DS';
            case 'SourceToSurfaceDistance',                                      i = find( GROUP == 12298 & ELEME ==   304 ,1); type = 'DS';
            case 'CumulativeMetersetWeight',                                     i = find( GROUP == 12298 & ELEME ==   308 ,1); type = 'DS';
            case 'PatientSetupSequence',                                         i = find( GROUP == 12298 & ELEME ==   384 ,1); type = 'SQ';
            case 'PatientSetupNumber',                                           i = find( GROUP == 12298 & ELEME ==   386 ,1); type = 'IS';
            case 'PatientAdditionalPosition',                                    i = find( GROUP == 12298 & ELEME ==   388 ,1); type = 'LO';
            case 'FixationDeviceSequence',                                       i = find( GROUP == 12298 & ELEME ==   400 ,1); type = 'SQ';
            case 'FixationDeviceType',                                           i = find( GROUP == 12298 & ELEME ==   402 ,1); type = 'CS';
            case 'FixationDeviceLabel',                                          i = find( GROUP == 12298 & ELEME ==   404 ,1); type = 'SH';
            case 'FixationDeviceDescription',                                    i = find( GROUP == 12298 & ELEME ==   406 ,1); type = 'ST';
            case 'FixationDevicePosition',                                       i = find( GROUP == 12298 & ELEME ==   408 ,1); type = 'SH';
            case 'ShieldingDeviceSequence',                                      i = find( GROUP == 12298 & ELEME ==   416 ,1); type = 'SQ';
            case 'ShieldingDeviceType',                                          i = find( GROUP == 12298 & ELEME ==   418 ,1); type = 'CS';
            case 'ShieldingDeviceLabel',                                         i = find( GROUP == 12298 & ELEME ==   420 ,1); type = 'SH';
            case 'ShieldingDeviceDescription',                                   i = find( GROUP == 12298 & ELEME ==   422 ,1); type = 'ST';
            case 'ShieldingDevicePosition',                                      i = find( GROUP == 12298 & ELEME ==   424 ,1); type = 'SH';
            case 'SetupTechnique',                                               i = find( GROUP == 12298 & ELEME ==   432 ,1); type = 'CS';
            case 'SetupTechniqueDescription',                                    i = find( GROUP == 12298 & ELEME ==   434 ,1); type = 'ST';
            case 'SetupDeviceSequence',                                          i = find( GROUP == 12298 & ELEME ==   436 ,1); type = 'SQ';
            case 'SetupDeviceType',                                              i = find( GROUP == 12298 & ELEME ==   438 ,1); type = 'CS';
            case 'SetupDeviceLabel',                                             i = find( GROUP == 12298 & ELEME ==   440 ,1); type = 'SH';
            case 'SetupDeviceDescription',                                       i = find( GROUP == 12298 & ELEME ==   442 ,1); type = 'ST';
            case 'SetupDeviceParameter',                                         i = find( GROUP == 12298 & ELEME ==   444 ,1); type = 'DS';
            case 'SetupReferenceDescription',                                    i = find( GROUP == 12298 & ELEME ==   464 ,1); type = 'ST';
            case 'TableTopVerticalSetupDisplacement',                            i = find( GROUP == 12298 & ELEME ==   466 ,1); type = 'DS';
            case 'TableTopLongitudinalSetupDisplacement',                        i = find( GROUP == 12298 & ELEME ==   468 ,1); type = 'DS';
            case 'TableTopLateralSetupDisplacement',                             i = find( GROUP == 12298 & ELEME ==   470 ,1); type = 'DS';
            case 'BrachyTreatmentTechnique',                                     i = find( GROUP == 12298 & ELEME ==   512 ,1); type = 'CS';
            case 'BrachyTreatmentType',                                          i = find( GROUP == 12298 & ELEME ==   514 ,1); type = 'CS';
            case 'TreatmentMachineSequence',                                     i = find( GROUP == 12298 & ELEME ==   518 ,1); type = 'SQ';
            case 'SourceSequence',                                               i = find( GROUP == 12298 & ELEME ==   528 ,1); type = 'SQ';
            case 'SourceNumber',                                                 i = find( GROUP == 12298 & ELEME ==   530 ,1); type = 'IS';
            case 'SourceType',                                                   i = find( GROUP == 12298 & ELEME ==   532 ,1); type = 'CS';
            case 'SourceManufacturer',                                           i = find( GROUP == 12298 & ELEME ==   534 ,1); type = 'LO';
            case 'ActiveSourceDiameter',                                         i = find( GROUP == 12298 & ELEME ==   536 ,1); type = 'DS';
            case 'ActiveSourceLength',                                           i = find( GROUP == 12298 & ELEME ==   538 ,1); type = 'DS';
            case 'SourceEncapsulationNominalThickness',                          i = find( GROUP == 12298 & ELEME ==   546 ,1); type = 'DS';
            case 'SourceEncapsulationNominalTransmission',                       i = find( GROUP == 12298 & ELEME ==   548 ,1); type = 'DS';
            case 'SourceIsotopeName',                                            i = find( GROUP == 12298 & ELEME ==   550 ,1); type = 'LO';
            case 'SourceIsotopeHalfLife',                                        i = find( GROUP == 12298 & ELEME ==   552 ,1); type = 'DS';
            case 'ReferenceAirKermaRate',                                        i = find( GROUP == 12298 & ELEME ==   554 ,1); type = 'DS';
            case 'AirKermaRateReferenceDate',                                    i = find( GROUP == 12298 & ELEME ==   556 ,1); type = 'DA';
            case 'AirKermaRateReferenceTime',                                    i = find( GROUP == 12298 & ELEME ==   558 ,1); type = 'TM';
            case 'ApplicationSetupSequence',                                     i = find( GROUP == 12298 & ELEME ==   560 ,1); type = 'SQ';
            case 'ApplicationSetupType',                                         i = find( GROUP == 12298 & ELEME ==   562 ,1); type = 'CS';
            case 'ApplicationSetupNumber',                                       i = find( GROUP == 12298 & ELEME ==   564 ,1); type = 'IS';
            case 'ApplicationSetupName',                                         i = find( GROUP == 12298 & ELEME ==   566 ,1); type = 'LO';
            case 'ApplicationSetupManufacturer',                                 i = find( GROUP == 12298 & ELEME ==   568 ,1); type = 'LO';
            case 'TemplateNumber',                                               i = find( GROUP == 12298 & ELEME ==   576 ,1); type = 'IS';
            case 'TemplateType',                                                 i = find( GROUP == 12298 & ELEME ==   578 ,1); type = 'SH';
            case 'TemplateName',                                                 i = find( GROUP == 12298 & ELEME ==   580 ,1); type = 'LO';
            case 'TotalReferenceAirKerma',                                       i = find( GROUP == 12298 & ELEME ==   592 ,1); type = 'DS';
            case 'BrachyAccessoryDeviceSequence',                                i = find( GROUP == 12298 & ELEME ==   608 ,1); type = 'SQ';
            case 'BrachyAccessoryDeviceNumber',                                  i = find( GROUP == 12298 & ELEME ==   610 ,1); type = 'IS';
            case 'BrachyAccessoryDeviceID',                                      i = find( GROUP == 12298 & ELEME ==   611 ,1); type = 'SH';
            case 'BrachyAccessoryDeviceType',                                    i = find( GROUP == 12298 & ELEME ==   612 ,1); type = 'CS';
            case 'BrachyAccessoryDeviceName',                                    i = find( GROUP == 12298 & ELEME ==   614 ,1); type = 'LO';
            case 'BrachyAccessoryDeviceNominalThickness',                        i = find( GROUP == 12298 & ELEME ==   618 ,1); type = 'DS';
            case 'BrachyAccessoryDeviceNominalTransmission',                     i = find( GROUP == 12298 & ELEME ==   620 ,1); type = 'DS';
            case 'ChannelSequence',                                              i = find( GROUP == 12298 & ELEME ==   640 ,1); type = 'SQ';
            case 'ChannelNumber',                                                i = find( GROUP == 12298 & ELEME ==   642 ,1); type = 'IS';
            case 'ChannelLength',                                                i = find( GROUP == 12298 & ELEME ==   644 ,1); type = 'DS';
            case 'ChannelTotalTime',                                             i = find( GROUP == 12298 & ELEME ==   646 ,1); type = 'DS';
            case 'SourceMovementType',                                           i = find( GROUP == 12298 & ELEME ==   648 ,1); type = 'CS';
            case 'NumberOfPulses',                                               i = find( GROUP == 12298 & ELEME ==   650 ,1); type = 'IS';
            case 'PulseRepetitionInterval',                                      i = find( GROUP == 12298 & ELEME ==   652 ,1); type = 'DS';
            case 'SourceApplicatorNumber',                                       i = find( GROUP == 12298 & ELEME ==   656 ,1); type = 'IS';
            case 'SourceApplicatorID',                                           i = find( GROUP == 12298 & ELEME ==   657 ,1); type = 'SH';
            case 'SourceApplicatorType',                                         i = find( GROUP == 12298 & ELEME ==   658 ,1); type = 'CS';
            case 'SourceApplicatorName',                                         i = find( GROUP == 12298 & ELEME ==   660 ,1); type = 'LO';
            case 'SourceApplicatorLength',                                       i = find( GROUP == 12298 & ELEME ==   662 ,1); type = 'DS';
            case 'SourceApplicatorManufacturer',                                 i = find( GROUP == 12298 & ELEME ==   664 ,1); type = 'LO';
            case 'SourceApplicatorWallNominalThickness',                         i = find( GROUP == 12298 & ELEME ==   668 ,1); type = 'DS';
            case 'SourceApplicatorWallNominalTransmission',                      i = find( GROUP == 12298 & ELEME ==   670 ,1); type = 'DS';
            case 'SourceApplicatorStepSize',                                     i = find( GROUP == 12298 & ELEME ==   672 ,1); type = 'DS';
            case 'TransferTubeNumber',                                           i = find( GROUP == 12298 & ELEME ==   674 ,1); type = 'IS';
            case 'TransferTubeLength',                                           i = find( GROUP == 12298 & ELEME ==   676 ,1); type = 'DS';
            case 'ChannelShieldSequence',                                        i = find( GROUP == 12298 & ELEME ==   688 ,1); type = 'SQ';
            case 'ChannelShieldNumber',                                          i = find( GROUP == 12298 & ELEME ==   690 ,1); type = 'IS';
            case 'ChannelShieldID',                                              i = find( GROUP == 12298 & ELEME ==   691 ,1); type = 'SH';
            case 'ChannelShieldName',                                            i = find( GROUP == 12298 & ELEME ==   692 ,1); type = 'LO';
            case 'ChannelShieldNominalThickness',                                i = find( GROUP == 12298 & ELEME ==   696 ,1); type = 'DS';
            case 'ChannelShieldNominalTransmission',                             i = find( GROUP == 12298 & ELEME ==   698 ,1); type = 'DS';
            case 'FinalCumulativeTimeWeight',                                    i = find( GROUP == 12298 & ELEME ==   712 ,1); type = 'DS';
            case 'BrachyControlPointSequence',                                   i = find( GROUP == 12298 & ELEME ==   720 ,1); type = 'SQ';
            case 'ControlPointRelativePosition',                                 i = find( GROUP == 12298 & ELEME ==   722 ,1); type = 'DS';
            case 'ControlPoint3DPosition',                                       i = find( GROUP == 12298 & ELEME ==   724 ,1); type = 'DS';
            case 'CumulativeTimeWeight',                                         i = find( GROUP == 12298 & ELEME ==   726 ,1); type = 'DS';
            case 'CompensatorDivergence',                                        i = find( GROUP == 12298 & ELEME ==   736 ,1); type = 'CS';
            case 'CompensatorMountingPosition',                                  i = find( GROUP == 12298 & ELEME ==   737 ,1); type = 'CS';
            case 'SourceToCompensatorDistance',                                  i = find( GROUP == 12298 & ELEME ==   738 ,1); type = 'DS';
            case 'ReferencedRTGroupLength',                                      i = find( GROUP == 12300 & ELEME ==     0 ,1); type = 'UL';
            case 'ReferencedRTPlanSequence',                                     i = find( GROUP == 12300 & ELEME ==     2 ,1); type = 'SQ';
            case 'ReferencedBeamSequence',                                       i = find( GROUP == 12300 & ELEME ==     4 ,1); type = 'SQ';
            case 'ReferencedBeamNumber',                                         i = find( GROUP == 12300 & ELEME ==     6 ,1); type = 'IS';
            case 'ReferencedReferenceImageNumber',                               i = find( GROUP == 12300 & ELEME ==     7 ,1); type = 'IS';
            case 'StartCumulativeMetersetWeight',                                i = find( GROUP == 12300 & ELEME ==     8 ,1); type = 'DS';
            case 'EndCumulativeMetersetWeight',                                  i = find( GROUP == 12300 & ELEME ==     9 ,1); type = 'DS';
            case 'ReferencedBrachyApplicationSetupSequence',                     i = find( GROUP == 12300 & ELEME ==    10 ,1); type = 'SQ';
            case 'ReferencedBrachyApplicationSetupNumber',                       i = find( GROUP == 12300 & ELEME ==    12 ,1); type = 'IS';
            case 'ReferencedSourceNumber',                                       i = find( GROUP == 12300 & ELEME ==    14 ,1); type = 'IS';
            case 'ReferencedFractionGroupSequence',                              i = find( GROUP == 12300 & ELEME ==    32 ,1); type = 'SQ';
            case 'ReferencedFractionGroupNumber',                                i = find( GROUP == 12300 & ELEME ==    34 ,1); type = 'IS';
            case 'ReferencedVerificationImageSequence',                          i = find( GROUP == 12300 & ELEME ==    64 ,1); type = 'SQ';
            case 'ReferencedReferenceImageSequence',                             i = find( GROUP == 12300 & ELEME ==    66 ,1); type = 'SQ';
            case 'ReferencedDoseReferenceSequence',                              i = find( GROUP == 12300 & ELEME ==    80 ,1); type = 'SQ';
            case 'ReferencedDoseReferenceNumber',                                i = find( GROUP == 12300 & ELEME ==    81 ,1); type = 'IS';
            case 'BrachyReferencedDoseReferenceSequence',                        i = find( GROUP == 12300 & ELEME ==    85 ,1); type = 'SQ';
            case 'ReferencedStructureSetSequence',                               i = find( GROUP == 12300 & ELEME ==    96 ,1); type = 'SQ';
            case 'ReferencedPatientSetupNumber',                                 i = find( GROUP == 12300 & ELEME ==   106 ,1); type = 'IS';
            case 'ReferencedDoseSequence',                                       i = find( GROUP == 12300 & ELEME ==   128 ,1); type = 'SQ';
            case 'ReferencedToleranceTableNumber',                               i = find( GROUP == 12300 & ELEME ==   160 ,1); type = 'IS';
            case 'ReferencedBolusSequence',                                      i = find( GROUP == 12300 & ELEME ==   176 ,1); type = 'SQ';
            case 'ReferencedWedgeNumber',                                        i = find( GROUP == 12300 & ELEME ==   192 ,1); type = 'IS';
            case 'ReferencedCompensatorNumber',                                  i = find( GROUP == 12300 & ELEME ==   208 ,1); type = 'IS';
            case 'ReferencedBlockNumber',                                        i = find( GROUP == 12300 & ELEME ==   224 ,1); type = 'IS';
            case 'ReferencedControlPointIndex',                                  i = find( GROUP == 12300 & ELEME ==   240 ,1); type = 'IS';
            case 'ReviewGroupLength',                                            i = find( GROUP == 12302 & ELEME ==     0 ,1); type = 'UL';
            case 'ApprovalStatus',                                               i = find( GROUP == 12302 & ELEME ==     2 ,1); type = 'CS';
            case 'ReviewDate',                                                   i = find( GROUP == 12302 & ELEME ==     4 ,1); type = 'DA';
            case 'ReviewTime',                                                   i = find( GROUP == 12302 & ELEME ==     5 ,1); type = 'TM';
            case 'ReviewerName',                                                 i = find( GROUP == 12302 & ELEME ==     8 ,1); type = 'PN';
            case 'TextGroupLength',                                              i = find( GROUP == 16384 & ELEME ==     0 ,1); type = 'UL';
            case 'TextArbitrary',                                                i = find( GROUP == 16384 & ELEME ==    16 ,1); type = 'LT';
            case 'TextComments',                                                 i = find( GROUP == 16384 & ELEME == 16384 ,1); type = 'LT';
            case 'ResultsGroupLength',                                           i = find( GROUP == 16392 & ELEME ==     0 ,1); type = 'UL';
            case 'ResultsID',                                                    i = find( GROUP == 16392 & ELEME ==    64 ,1); type = 'SH';
            case 'ResultsIDIssuer',                                              i = find( GROUP == 16392 & ELEME ==    66 ,1); type = 'LO';
            case 'ReferencedInterpretationSequence',                             i = find( GROUP == 16392 & ELEME ==    80 ,1); type = 'SQ';
            case 'InterpretationRecordedDate',                                   i = find( GROUP == 16392 & ELEME ==   256 ,1); type = 'DA';
            case 'InterpretationRecordedTime',                                   i = find( GROUP == 16392 & ELEME ==   257 ,1); type = 'TM';
            case 'InterpretationRecorder',                                       i = find( GROUP == 16392 & ELEME ==   258 ,1); type = 'PN';
            case 'ReferenceToRecordedSound',                                     i = find( GROUP == 16392 & ELEME ==   259 ,1); type = 'LO';
            case 'InterpretationTranscriptionDate',                              i = find( GROUP == 16392 & ELEME ==   264 ,1); type = 'DA';
            case 'InterpretationTranscriptionTime',                              i = find( GROUP == 16392 & ELEME ==   265 ,1); type = 'TM';
            case 'InterpretationTranscriber',                                    i = find( GROUP == 16392 & ELEME ==   266 ,1); type = 'PN';
            case 'InterpretationText',                                           i = find( GROUP == 16392 & ELEME ==   267 ,1); type = 'ST';
            case 'InterpretationAuthor',                                         i = find( GROUP == 16392 & ELEME ==   268 ,1); type = 'PN';
            case 'InterpretationApproverSequence',                               i = find( GROUP == 16392 & ELEME ==   273 ,1); type = 'SQ';
            case 'InterpretationApprovalDate',                                   i = find( GROUP == 16392 & ELEME ==   274 ,1); type = 'DA';
            case 'InterpretationApprovalTime',                                   i = find( GROUP == 16392 & ELEME ==   275 ,1); type = 'TM';
            case 'PhysicianApprovingInterpretation',                             i = find( GROUP == 16392 & ELEME ==   276 ,1); type = 'PN';
            case 'InterpretationDiagnosisDescription',                           i = find( GROUP == 16392 & ELEME ==   277 ,1); type = 'LT';
            case 'InterpretationDiagnosisCodeSequence',                          i = find( GROUP == 16392 & ELEME ==   279 ,1); type = 'SQ';
            case 'ResultsDistributionListSequence',                              i = find( GROUP == 16392 & ELEME ==   280 ,1); type = 'SQ';
            case 'DistributionName',                                             i = find( GROUP == 16392 & ELEME ==   281 ,1); type = 'PN';
            case 'DistributionAddress',                                          i = find( GROUP == 16392 & ELEME ==   282 ,1); type = 'LO';
            case 'InterpretationID',                                             i = find( GROUP == 16392 & ELEME ==   512 ,1); type = 'SH';
            case 'InterpretationIDIssuer',                                       i = find( GROUP == 16392 & ELEME ==   514 ,1); type = 'LO';
            case 'InterpretationTypeID',                                         i = find( GROUP == 16392 & ELEME ==   528 ,1); type = 'CS';
            case 'InterpretationStatusID',                                       i = find( GROUP == 16392 & ELEME ==   530 ,1); type = 'CS';
            case 'Impressions',                                                  i = find( GROUP == 16392 & ELEME ==   768 ,1); type = 'ST';
            case 'ResultsComments',                                              i = find( GROUP == 16392 & ELEME == 16384 ,1); type = 'ST';
            case 'MACParametersSequence',                                        i = find( GROUP == 20478 & ELEME ==     1 ,1); type = 'SQ';
            case 'SharedFunctionalGroupsSequence',                               i = find( GROUP == 20992 & ELEME == 37417 ,1); type = 'SQ';
            case 'PerFrameFunctionalGroupsSequence',                             i = find( GROUP == 20992 & ELEME == 37424 ,1); type = 'SQ';
            case 'WaveformSequence',                                             i = find( GROUP == 21504 & ELEME ==   256 ,1); type = 'SQ';
            case 'WaveformBitsAllocated',                                        i = find( GROUP == 21504 & ELEME ==  4100 ,1); type = 'US';
            case 'WaveformSampleInterpretation',                                 i = find( GROUP == 21504 & ELEME ==  4102 ,1); type = 'CS';
            case 'FirstOrderPhaseCorrectionAngle',                               i = find( GROUP == 22016 & ELEME ==    16 ,1); type = 'OF';
            case 'SpectroscopyData',                                             i = find( GROUP == 22016 & ELEME ==    32 ,1); type = 'OF';
            case 'PixelDataGroupLength',                                         i = find( GROUP == 32736 & ELEME ==     0 ,1); type = 'UL';
            case 'CoefficientsSDVN',                                             i = find( GROUP == 32736 & ELEME ==    32 ,1); type = 'OW';
            case 'CoefficientsSDHN',                                             i = find( GROUP == 32736 & ELEME ==    48 ,1); type = 'OW';
            case 'CoefficientsSDDN',                                             i = find( GROUP == 32736 & ELEME ==    64 ,1); type = 'OW';
            case 'DigitalSignaturesSequence',                                    i = find( GROUP == 65530 & ELEME == 65530 ,1); type = 'SQ';
            case 'DataSetTrailingPadding',                                       i = find( GROUP == 65532 & ELEME == 65532 ,1); type = 'OB';
            case 'Item',                                                         i = find( GROUP == 65534 & ELEME == 57344 ,1); type = 'UN';
            case 'ItemDelimitationItem',                                         i = find( GROUP == 65534 & ELEME == 57357 ,1); type = 'UN';
            case 'SequenceDelimitationItem',                                     i = find( GROUP == 65534 & ELEME == 57565 ,1); type = 'UN';

%}
