function item = DICOMxinfo( item , varargin )
% 
% DICOMxinfo( item , '^(?!Private_).*' )
% DICOMxinfo( item , '^x.*' )
% DICOMxinfo( item , 'xSpatialTransform' )
% DICOMxinfo( item , 'xSpatialTransform' , '' )
% DICOMxinfo( item , 'uid$' , '' )
% DICOMxinfo( item , 'Med' , '' )
% DICOMxinfo( item , '(?i)MEd' , '' )
% DICOMxinfo( item , 'CSA' ,'.*')
% DICOMxinfo( item , 'CSA_','.*')
% 

  if ischar( item )
    fn = item;
    item = NaN;
    if isnan( item )
      try, item = dicominfo( fn ); end
    end
    if isnumeric( item ) && isnan( item )
      IOpath = { fullfile( fileparts( mfilename('fullpath') ) , 'dicomIO' ) };
      swarn = warning('off','MATLAB:rmpath:DirNotFound');
      for io = 1:numel( IOpath )
        rmpath( IOpath{io} );
        try, item = dicominfo( fn ); break; end

        addpath( IOpath{io} );
        try, item = dicominfo( fn ); break; end
        rmpath( IOpath{io} );
      end
      warning( swarn );
    end
    if isnumeric( item ) && isnan( item ), return; end
  end
  
  %adding some extra useful information
  %%%%
  try,
  [p,f,e] = fileparts( item.Filename );
  item.xDirname = p;
  item.xFilename = [ f , e ];
  end
  
  %%%%
  if ~isfield( item , 'xPatientName' )
    try, item.xPatientName = item.PatientName.FamilyName;
    end
  end
  
  if ~isfield( item , 'xDatenum' )
    try,   item.xDatenum = DICOMdatenum( item );                  %#ok<TRYNC>
    end
  end
  
  %%%%
  if ~isfield( item , 'xSize' )
    try,   item.xSize = [ item.Rows ,  item.Columns ];
    catch, item.xSize = [ 0 , 0 ];
    end
    try,   item.xSize = [ item.xSize , item.SamplesPerPixel ];
    catch, item.xSize = [ item.xSize , 1 ];
    end
    try,   item.xSize = [ item.xSize , item.NumberOfFrames ];
    catch, item.xSize = [ item.xSize , 1 ];
    end
  end

  item.xNormal = [];
  try
    R = reshape( item.ImageOrientationPatient , 3 , 2 );
    N = cross( R(:,1), R(:,2) );
    for it = 1:5, N = N/sqrt( N(:).' *  N(:) ); end

    item.xNormal = N;
  end
  
  
  
  item.xRotationMatrix = [];
  try
    R = reshape( item.ImageOrientationPatient , 3 , 2 );
    R(:,3)= cross( R(:,1), R(:,2) );
    for cc = 1:3, for it = 1:5, R(:,cc) = R(:,cc)/sqrt( R(:,cc).' * R(:,cc) ); end; end

    item.xRotationMatrix = R;
  end
  
  
  if ~isfield( item , 'xSpatialTransform' )
    item.xSpatialTransform = [];
    try
      item.xSpatialTransform = [ item.xRotationMatrix , item.ImagePositionPatient(:) ; 0 0 0 1 ];
    end
  end  
  
  if ~isfield( item , 'xZLevel' )
    try
      Z = item.ImagePositionPatient;
      Z = R(1:3,1:3).'*Z(:);
      item.xZLevel = Z(3);
    end
  end 
  
  if ~isfield( item , 'xPhase' ) && any( ismember( varargin , 'xPhase' ) )
    item.xPhase = -1;
    try
      [d,fn,e] = fileparts( item.Filename ); fn = [fn,e];
      p = dir( d );
      p( [p.isdir] ) = [];
      p( strncmp( {p.name} , '.#.', 3 ) ) = [];
      for f=1:numel(p), p(f).name = fullfile( d , p(f).name ); end
      p = DICOMheader( p ,...
            'SliceLocation' ,...
            'SeriesNumber' ,...
            'ImageOrientationPatient' ,...
            'ImagePositionPatient' ,...
            'SeriesInstanceUID' ,...
            'StudyID' ,...
            'PatientID' ,...
            'SeriesDescription' ,...
            'StudyDescription' ,...
            'MediaStorageSOPInstanceUID' ,...
            'TriggerTime' );

      try, p( [ p.SliceLocation ] ~= item.SliceLocation ) = []; end
      try, p( [ p.SeriesNumber ] ~= item.SeriesNumber ) = []; end
      try, p( ~cellfun(@(x)isequal( x , item.ImagePositionPatient   ) , { p.ImagePositionPatient    } ) ) = []; end
      try, p( ~cellfun(@(x)isequal( x , item.ImageOrientationPatient) , { p.ImageOrientationPatient } ) ) = []; end
      try, p( ~strcmp( { p.SeriesInstanceUID } , item.SeriesInstanceUID ) ) = []; end
      try, p( ~strcmp( { p.StudyID } , item.StudyID ) ) = []; end
      try, p( ~strcmp( { p.PatientID } , item.PatientID ) ) = []; end
      try, p( ~strcmp( { p.SeriesDescription }  , item.SeriesDescription ) ) = []; end
      try, p( ~strcmp( { p.StudyDescription }  , item.StudyDescription ) ) = []; end

      [~,ord] = sort( [ p.TriggerTime ] );
      p = p(ord);
      item.xPhase = [ find( strcmp( { p.MediaStorageSOPInstanceUID } , item.MediaStorageSOPInstanceUID ) ) ,...
                      numel(p) ];
    end
  end 
  
  
  if ~isfield( item , 'CSA' ) && any( ismember( varargin , 'CSA' ) )
    try
      CSA = readCSAitems( item );
      item.CSA = CSA.csa;
    end
  end
  if any( ismember( varargin , 'CSA_' ) )
    if ~isfield( item , 'CSA' )
      CSA = readCSAitems( item );
      CSA = CSA.csa;
    else
      CSA = item.CSA; item = rmfield( item , 'CSA' );
    end
    for c = fieldnames( CSA ).', c = c{1};
      item.(['CSA',c]) = CSA.(c);
    end
  end
  
  %%%%

  try
    [d,fn,e] = fileparts( item.Filename ); fn = [fn,e];
    p = dir( d );
    p( [p.isdir] ) = [];
    p( ~strncmp( {p.name} , '.#.', 3 ) ) = [];
    p( strcmp( {p.name} , fn ) ) = [];
    for f=1:numel(p), p(f).name = fullfile( d , p(f).name ); end
    p = DICOMheader( p , 'MediaStorageSOPInstanceUID' );
    p( ~strcmp( {p.MediaStorageSOPInstanceUID} , item.MediaStorageSOPInstanceUID ) ) = [];
    for f = 1:numel(p)
      xitem = dicominfo( p(f).name );
      
      for a = fieldnames( xitem ).', a = a{1};
        if isfield( item , a ) 
          if ~isidentical( item.(a) , xitem.(a) )
            %"ird" means "in replicated dicom"
            item.(['ird_', a]) = xitem.(a);
          end
        else
          item.(a) = xitem.(a);
        end
      end
    end
  end
  
  
  
  if numel( varargin ) == 1
    try
      item = item.(varargin{1});
      varargin(1) = [];
    catch
      error('no field');
      item = []; return;
    end
  end  
    
  if ~isempty( varargin )
    fn = fieldnames( item );
    w = false;
    for v = 1:numel( varargin )
      if isempty( varargin{v} ), continue; end
      w = w | ~cellfun( 'isempty' , regexp( fn , varargin{v} , 'once' ) );
    end
    item = rmfield( item , fn(~w) );
  end
  
end





















function [ item ] = readCSAitems( item )
  %% Locate SIEMENS CSA HEADER
  tagId = getDicomPrivateTag(item,'0029','SIEMENS CSA HEADER');

  if isempty(tagId)
    return
  end

  %% Process the two parameter fields
  SiemensCsaParse_ReadDicomTag(['Private_0029_' tagId '10']);
  SiemensCsaParse_ReadDicomTag(['Private_0029_' tagId '20']);

  %% Main code
  function SiemensCsaParse_ReadDicomTag( strTag )
    currdx = 0;
    
    if ~strcmp(char(private_read(4)),'SV10') || ~all(private_read(4)==[4 3 2 1])
      error('Unsupported CSA block format');
    end
    
    % This parsing code is translated from gdcm (http://gdcm.sf.net/)
    numElements = double(private_readuint32(1));
    
    % Sanity check
    if private_readuint32(1)~=77
      error('Unsupported CSA block format');
    end
    
    for tagdx=1:numElements
      tagName = private_readstring(64);
      
      % Fix up tagName
      tagName(tagName == '-') = [];
      
      vm = private_readuint32(1);
      vr = private_readstring(4);
      syngodt = private_readuint32(1);
      nitems = double(private_readuint32(1));
      
      checkbit = private_readuint32(1);
      
      if checkbit ~= 77 && checkbit ~= 205
        error('Unsupported CSA block format');
      end
      
      data = {};
      for itemdx=1:nitems
        header = double(private_readuint32(4));
        
        if (header(3) ~= 77 && header(3) ~= 205) || ...
           (header(1) ~= header(2)) || ...
           (header(1) ~= header(4))
          error('Unsupported CSA block format');
        end
        
        data{itemdx} = private_readstring(header(1));
        
        % Dump junk up to DWORD boundary
        private_read(mod(mod(4-header(1),4),4));
      end
      
      % Store this in the csa structure
      switch vr
        case {'CS', 'LO', 'LT', 'SH', 'SS', 'UI', 'UT', 'UN'} % Strings and unknown byte string
          if numel(data) < vm
            % Pad if necessary. Siemens CSA format omits null strings.
            data{vm} = '';
          end
          
          if vm == 1
            item.csa.(tagName) = data{1};
          else
            item.csa.(tagName) = data(1:vm);
          end
        case {'DS', 'FD', 'FL', 'IS', 'SL', 'ST', 'UL', 'US'} % Numbers
          dataNumeric = arrayfun(@str2double,data);
          
          if numel(dataNumeric) < vm
            % Zero pad if necessary. Siemens CSA format omits zeros.
            dataNumeric(vm) = 0;
          end
          
          item.csa.(tagName) = dataNumeric(1:vm);
        otherwise
          warning('RodgersSpectroTools:UnknownVrType','Unknown VR type: "%s".',vr)
      end
    end
    
    
    %% Helper functions to simulate file I/O
    function [out] = private_read(numBytes)
      out = item.(strTag)(currdx+(1:numBytes)).';
      currdx=currdx+numBytes;
    end
    function [out] = private_readuint32(num)
      out=typecast(private_read(4*num),'uint32');
    end
    function [out] = private_readstring(maxchar)
      out = reshape(char(private_read(maxchar)),1,[]);
      terminator = find(out==0,1);
      if numel(terminator)>0
        out=out(1:(terminator-1));
      end
    end
  end
  function [id] = getDicomPrivateTag( item ,strGroupId,tagName )
    % Search for a private DICOM tag.
    %
    % Inputs:
    %
    % info - structure returned by dicominfo().
    % strGroupId - the DICOM group as a string of hexidecimal characters
    %            - e.g. '0029'
    %            - N.B. This value should be an ODD number according to the
    %              DICOM standard.
    % tagName - String containing the name of the private tag to be found.
    %
    % Returns a string with the leading digits of the key.
    
    % Copyright Chris Rodgers, University of Oxford, 2011.
    % $Id$
    
    myFn = fieldnames(item);
    
    myFnMatches = regexp(myFn,['^Private_' strGroupId '_([0-9]{2})xx_Creator$'],'tokens','once');
    
    for myDx = 1:numel(myFn)
      if isempty(myFnMatches{myDx})
        continue
      end
      
      %     fprintf('%s = ''%s''\n',myFn{myDx},info.(myFn{myDx}));
      if strcmp(tagName,item.(myFn{myDx}))
        id = myFnMatches{myDx}{1};
        return
      end
    end
    
    id = '';
    
  end

end





function sinfo=SiemensInfo(info)
% This function reads the information from the Siemens Private tag 0029 1020 
% from a struct with all dicom info.
%
%
% dcminfo=dicominfo('example.dcm');
% info = SiemensInfo(dcminfo)
%
%
%
str=char(info.Private_0029_1020(:))';
a1=strfind(str,'### ASCCONV BEGIN ###');
a2=strfind(str,'### ASCCONV END ###');
str=str((a1+22):a2-2);
request_lines = regexp(str, '\n+', 'split');
request_words = regexp(request_lines, '=', 'split');
sinfo=struct;
for i=1:length(request_lines)
    s=request_words{i};
    name=s{1};
    while(name(end)==' '); name=name(1:end-1); end
    while(name(1)==' '); name=name(2:end); end
    value=s{2}; value=value(2:end);
    if(any(value=='"'))
        value(value=='"')=[];
        valstr=true;
    else
        valstr=false;
    end
    names = regexp(name, '\.', 'split');
    ind=zeros(1,length(names));
    for j=1:length(names)
        name=names{j};
        ps=find(name=='[');
        if(~isempty(ps))
            pe=find(name==']');
            ind(j)=str2double(name(ps+1:pe-1))+1;
            names{j}=name(1:ps-1);
        end
    end
    try
    evalstr='sinfo';
    for j=1:length(names)
        if(ind(j)==0)
            evalstr=[evalstr '.(names{' num2str(j) '})'];
        else
            evalstr=[evalstr '.(names{' num2str(j) '})(' num2str(ind(j)) ')'];
        end
    end
    if(valstr)
        evalstr=[evalstr '=''' value ''';'];
    else
        if(strcmp(value(1:min(2:end)),'0x'))
            evalstr=[evalstr '='  num2str(hex2dec(value(3:end))) ';'];
        else
        evalstr=[evalstr '=' value ';'];
        end
    end
    eval(evalstr);
    catch ME
        warning(ME.message);
    end
end

end
