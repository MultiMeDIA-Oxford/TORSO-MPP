function [HC,CS,warns] = CVI42Contours2HeartSlices( C , DICOMs , varargin )

  if ischar( DICOMs )
    fprintf('Reading DICOMs from "%s" ... ', DICOMs );
    DICOMs = DICOMheader( rdir( DICOMs ) ,...
            'MediaStorageSOPInstanceUID' ,...
            'PatientID' ,...
            'SeriesInstanceUID' ,...
            'StudyInstanceUID' ,...
            'ImageOrientationPatient' ,...
            'ImagePositionPatient' ,...
            'TriggerTime' ,...
            'AcquisitionTime' ,...
            'Filename' ,...
            'SeriesNumber' ,...
            'StudyInstanceUID' ,...
            'SeriesDescription' ,...
            'SliceLocation' );
    DICOMs( cellfun('isempty', { DICOMs.Filename } ) ) = [];
    fprintf('done\n');
  end
  if ischar( C )
    fprintf('Reading CVI42 file "%s" ... ', C );
    C = read_CVI42WSX( C , DICOMs );
    fprintf('done\n');
  end
    

  for c = 1:numel(C), C(c).id = c; end
  C = pruneCVI42Contours( C , 'unique' , varargin{:} , '>2' , 'sort' );
  %figure; for v=1:numel(V), plot3d( { V.Points3D } , 'color',[1 1 1]*0.4 ,'eq');hplot3d( V(v).Points3D ,'r','linewidth',3);pause(0.3); end; close
  %clc; arrayfun( @(v)fprintf('(%2d) %25s - %10g - %03d.%s\n', v.TimeInstant , v.Description , v.ImageHeader.origin*v.ImageHeader.TransformMatrix(:,3) , DICOMs( strcmp({DICOMs.MediaStorageSOPInstanceUID},v.parentUID ) ).SeriesNumber , v.parentSeriesDescription ) ,  V );

  if numel( unique( { C.parentPatientID } ) ) ~= 1
    error('a single PatientID was expected');
  end
  if numel( unique( { C.parentStudyInstanceUID } ) ) ~= 1
    error('a single StudyInstanceUID was expected');
  end
  

  [varargin,asI3D] = parseargs(varargin,'asi3d','$FORCE$',{true,false});
  [varargin,addLVOT] = parseargs(varargin,'addlvot','$FORCE$',{true,false});
  [varargin,addSAs] = parseargs(varargin,'addsas','$FORCE$',{true,false});
  [varargin,removeZeroSlices] = parseargs(varargin,'removezeroslices','$FORCE$',{true,false});
  
  
  if isempty( DICOMs )
    DS = unique( { C.parentFilename } );
    for d = 1:numel(DS)
      DICOMs = catstruct( 1 , DICOMs , dicominfo( DS{d} ) );
    end
  end

  if ~isfield( DICOMs , 'name' ) && isfield( DICOMs , 'Filename' )
    [ DICOMs.name ] = deal( DICOMs.Filename );
  end
  [ DICOMs.Filename ] = deal( DICOMs.name );

  try, DICOMs( cellfun(@isnumeric,{DICOMs.StudyInstanceUID}) ) = []; end
  try, DICOMs( ~strcmp( { DICOMs.StudyInstanceUID } , C(1).parentStudyInstanceUID ) ) = []; end
  if ~addLVOT && ~addSAs
    DICOMs( ~ismember( { DICOMs.SeriesInstanceUID } , { C.parentSeriesInstanceUID } ) ) = [];
  end
  
  
  toADD = { 'SeriesNumber' , 'StudyInstanceUID' , 'MediaStorageSOPInstanceUID' , 'SeriesInstanceUID' , 'SeriesDescription' , 'SliceLocation' , 'StudyInstanceUID' };
  toADD = setdiff( toADD , fieldnames( DICOMs ) );
  if ~isempty( toADD )
    DICOMs = DICOMheader( DICOMs , toADD{:} );
  end
  
  
  w = find( cellfun('isempty', { DICOMs.SeriesNumber } ) );
  for ww = w(:).'
    DICOMs(ww).SeriesNumber = NaN;
  end
  
  warns = {};
  [varargin,WARMinsteadOfERRORS] = parseargs(varargin,'warning','$FORCE$',{true,false});
  function werror( id , varargin )
    if WARMinsteadOfERRORS
      warning( id , varargin{:} );
      warns{1,end+1} = id;
    else
      error( id , varargin{:} );
    end
  end



  HLAx = C( ~cellfun('isempty',regexpi( { C.parentSeriesDescription } , '^hla' ) ) );
  if numel( unique( { HLAx.parentUID }.' ) ) > 1, werror('HSlices:HLAs','several HLA'); end
  if isempty( HLAx ), werror('HSlices:noHLA','error in picking out HLA contours!. particular case?');  end
  if isempty( HLAx ), HLAx(1).parentUID = 'hla____'; end
  [ HLAx.PlaneName ] = deal('HLAx');

  VLAx = C( ~cellfun('isempty',regexpi( { C.parentSeriesDescription } , '^vla' ) ) );
  if numel( unique( { VLAx.parentUID }.' ) ) > 1, werror('HSlices:VLAs','several VLA'); end
  if isempty( VLAx ), werror('HSlices:noVLA','error in picking out VLA contours!. particular case?'); end
  if isempty( VLAx ), VLAx(1).parentUID = 'vla____'; end
  [ VLAx.PlaneName ] = deal('VLAx');

  LVOT = C( ~cellfun('isempty',regexpi( { C.parentSeriesDescription } , '^lvot' ) ) );
  if numel( unique( { LVOT.parentUID }.' ) ) > 1, werror('HSlices:LVOTs','several LOT'); end
  if isempty( LVOT ), LVOT(1).parentUID = 'lvot____'; end
  [ LVOT.PlaneName ] = deal('LVOT');

  SAxs  = C( ~cellfun('isempty',regexpi( { C.parentSeriesDescription } , '^s' ) ) );
  if isempty( SAxs ), werror('HSlices:noSA','error in picking out SAs contours!. particular case?'); end
  Zs = arrayfun( @(v)v.ImageHeader.origin*v.ImageHeader.TransformMatrix(:,3) , SAxs );
  if any( arrayfun( @(z)numel( unique( { SAxs( Zs == z ).parentUID } ) ) , unique( Zs ) ) ~= 1 )
    werror('HSlices:SAgap0','several SA at the same height');
  end
  Zs = cellfun( @(u)mean( Zs( strcmp( { SAxs.parentUID } , u ) ) ) , unique( { SAxs.parentUID } , 'stable' ) );
  if var( diff( Zs ) ) > 1e-7
    werror('HSlices:SAgapDifferent','not equal spaced SA stack.');
  end
  try,
  sns = sort( [ DICOMs( ismember( { DICOMs.MediaStorageSOPInstanceUID } , unique( { SAxs.parentUID } ) ) ).SeriesNumber ] );
  if any( diff( sns ) ~= 1 )
    werror('HSlices:noConsecutiveSN','no consecutive SeriesNumber stack.');
  end
  end
  [ SAxs.PlaneName ] = deal('SAx');
  
  
  CC = C;
  CC( ismember( [ CC.id ] , [ HLAx.id ] ) ) = [];
  CC( ismember( [ CC.id ] , [ VLAx.id ] ) ) = [];
  CC( ismember( [ CC.id ] , [ LVOT.id ] ) ) = [];
  CC( ismember( [ CC.id ] , [ SAxs.id ] ) ) = [];


  C = catstruct(1 , HLAx , VLAx , LVOT , SAxs );
  %figure; for v=1:numel(V), plot3d( { V.Points3D } , 'color',[1 1 1]*0.4 ,'eq');hplot3d( V(v).Points3D ,'r','linewidth',3);pause(0.3); end; close
  %clc; arrayfun( @(v)fprintf('(%2d) %25s - %10g - %03d.%s\n', v.TimeInstant , v.Description , v.ImageHeader.origin*v.ImageHeader.TransformMatrix(:,3) , DICOMs( strcmp({DICOMs.MediaStorageSOPInstanceUID},v.parentUID ) ).SeriesNumber , v.parentSeriesDescription ) ,  V );

  allDESCRIPTIONS = unique( [ 'saepicardialContour' ,...           %1
                              'laepicardialContour' ,...           %2
                              'saepicardialOpenContour' ,...       %3
                              'saendocardialContour' ,...          %4
                              'saendocardialOpenContour' ,...      %5
                              'laendocardialContour' ,...          %6
                              'sarvendocardialContour' ,...        %7
                              'freeDrawRoiContour' ,...            %8
                              'laxLvExtentPoints' ,...             %9
                              {C(~cellfun('isempty',{C.Description})).Description} ] , 'stable' ).';

  UIDs = unique( { C.parentUID } , 'stable' );
  HC = cell( numel( UIDs ) , 5 );
  CS = cell( numel( UIDs ) , 0 );
  for h = 1:numel( UIDs ), if isempty( UIDs{h} ), continue; end
    w = strcmp( { DICOMs.MediaStorageSOPInstanceUID } , UIDs{h} );
    if ~any( w ), continue; end
    
    dinfo = [];
    if isempty(dinfo), try,    dinfo = DICOMs( w ).info; end; end
    if isempty(dinfo), try,    dinfo = dicominfo( DICOMs( w ).Filename ); end; end
    if isempty(dinfo), try,    dinfo = DICOMs( w ); end; end
    try
      dinfo.PlaneName = unique( { C( strcmp( { C.parentUID } , UIDs{h} ) ).PlaneName } );
      dinfo.PlaneName = dinfo.PlaneName{1};
    end
    PHASES = DICOMs( strcmp( { DICOMs.SeriesInstanceUID } , dinfo.SeriesInstanceUID ) );
    PHASES = PHASES( [ PHASES.SliceLocation ] == dinfo.SliceLocation );

    if isfield( PHASES , 'AcquisitionNumber' )
      [~,ord] = sort( [ PHASES.AcquisitionNumber ] );               PHASES = PHASES(ord);
    end
    if isfield( PHASES , 'AcquisitionTime' )
      [~,ord] = sort( str2double( { PHASES.AcquisitionTime } ) );   PHASES = PHASES(ord);
    end
    if isfield( PHASES , 'InstanceNumber' )
      [~,ord] = sort( [ PHASES.InstanceNumber ] );                  PHASES = PHASES(ord);
    end
    if isfield( PHASES , 'TriggerTime' )
      [~,ord] = sort( [ PHASES.TriggerTime ] );                     PHASES = PHASES(ord);
    end
    
    
    if isfield( PHASES , 'AcquisitionNumber' ) && ~issorted( [ PHASES.AcquisitionNumber ] )
      werror('HSlices:unsortedAcquisitionNumber','PHASES cannot be sorted');
    end
    if isfield( PHASES , 'AcquisitionTime' ) && ~issorted( str2double( { PHASES.AcquisitionTime } ) )
      werror('HSlices:unsortedAcquisitionTime','PHASES cannot be sorted');
    end
    if isfield( PHASES , 'InstanceNumber' ) && ~issorted( [ PHASES.InstanceNumber ] )
      werror('HSlices:unsortedInstanceNumber','PHASES cannot be sorted');
    end
    if isfield( PHASES , 'TriggerTime' ) && ~issorted( [ PHASES.TriggerTime ] )
      werror('HSlices:unsortedTriggerTime','PHASES cannot be sorted');
    end
    
    thisPHASE = find( strcmp( { PHASES.MediaStorageSOPInstanceUID } , dinfo.MediaStorageSOPInstanceUID ) );
    PHASES = PHASES( [ thisPHASE:end , 1:thisPHASE-1 ] );
    dinfo.xPhase = [ thisPHASE , numel(PHASES) ];
      
    I = [];
    for p = 1:numel( PHASES )
      try,   im = PHASES(p).DATA;
      catch, im = dicomread( PHASES(p).Filename );
      end
      I = cat( 4 , I , im );
    end
    
    HC{h,1} = I;
    HC{h,2} = dinfo;

    tV = C( strcmp( { C.parentUID } , UIDs{h} ) );
    for v = 1:numel(tV)
      j = find( strcmp( allDESCRIPTIONS , tV(v).Description ) );
      switch j
        
        case {1,2,3}, j = 3;
        case {4,5,6}, j = 4;
        case {7,8},   j = 5;
        case {9},     j = 6;
        otherwise,    j = j-3;
      end
      try,   HC{h,j} = [ HC{h,j} ; NaN(1,size(tV.Points3D,2)) ; tV(v).Points3D ];
      catch, HC{h,j} = tV(v).Points3D;
      end
      if nargout > 1
      try,   CS{h,j} = [ CS{h,j} , tV(v).id ];
      catch, CS{h,j} = tV(v).id;
      end
      end
    end
  end
  %clf;arrayfun(@(h)set(findall(himage3(HC(h,1:2),'nolines','showcontrols','KC',{cell2mat(HC(h,3:end).')}),'Type','surface','LineWidth',2),'LineWidth',1,'EdgeColor','c') ,size(HC,1):-1:1 );axis(objbounds);set(findall(gca,'Type','line'),'Marker','.','LineStyle','none');
  %clf;arrayfun(@(h)himage3(HC(h,1:2),'nolines','showcontrols') ,size(HC,1):-1:1 );axis(objbounds)
  %hplot3d(HC(:,3),'b');hplot3d(HC(:,4),'r');hplot3d(HC(:,5),'g');axis equal

  
  

  if addLVOT
    if isempty( HC{3,1} ), try
      w = true;
      w = w & strcmp( { DICOMs.StudyInstanceUID } , HC{1,2}.StudyInstanceUID );
      w = w & strncmpi( { DICOMs.SeriesDescription } , 'lvot' , 4 );
      w = w & [ DICOMs.SeriesNumber ] == min( [ DICOMs(w).SeriesNumber ] );
      LVOT = DICOMs(w);
      [~,ord] = sort( [ LVOT.TriggerTime ] ); LVOT = LVOT(ord);
      p = DICOMxinfo( HC{1,2} , 'xPhase' ); p = p(1);
      LVOT = LVOT( [ p:end , 1:p-1 ] );
      if ~isfield( LVOT , 'info' )
        LVOT(1).info = dicominfo( LVOT(1).Filename );
      end
      LVOT(1).info.xPhase = [ p , numel(LVOT) ];
      
      I = [];
      for p = 1:numel( LVOT )
        try,   im = LVOT(p).DATA;
        catch, im = dicomread( LVOT(p).Filename );
        end
        I = cat( 4 , I , im );
      end

      HC{3,1} = I;

      try,    HC{3,2} = LVOT(1).info;
      catch,  HC{3,2} = dicominfo( LVOT(1).Filename );
      end
      
    end; end
  end
  
  
  if addSAs
    sns = cellfun( @(s)s.SeriesNumber , HC(4:end,2) );
    
    D = DICOMs;
    
    D( ~strcmp( { D.PatientID }  , HC{end,2}.PatientID  ) ) = [];
    D( ~strcmp( { D.StudyInstanceUID }  , HC{end,2}.StudyInstanceUID  ) ) = [];
    D( ~cellfun( @(o)isequal(o,HC{end,2}.ImageOrientationPatient) , { D.ImageOrientationPatient } ) ) = [];
%     D( ~strcmp( { D.SeriesDescription } , HC{end,2}.SeriesDescription ) ) = [];
    D( ismember( [ D.SeriesNumber ] , sns ) ) = [];
    
    SAphase = DICOMxinfo( HC{4,2} , 'xPhase' );
    newSNs = unique( [ D.SeriesNumber ] );
    if numel( newSNs )
      [~,ord] = sort( min( abs( bsxfun( @minus , sns , newSNs )) , [] , 1 ) );
      newSNs = newSNs(ord);
    end
    for nsn = newSNs(:).'
      if min( abs( sns - nsn ) ) > 1
        continue;
      end
      nSA = D( [ D.SeriesNumber ] == nsn );
      try
        dinfo = nSA(1).info;
      catch
        dinfo = dicominfo( nSA(1).Filename );  
      end
      if ~isequal( dinfo.Columns , HC{4,2}.Columns  ), continue; end
      if ~isequal( dinfo.Rows    , HC{4,2}.Rows     ), continue; end
      
      [~,ord] = sort( [ nSA.TriggerTime ] ); nSA = nSA(ord);
      nSA = nSA( [ SAphase(1):end , 1:SAphase(1)-1 ] );
      if ~isfield( nSA , 'info' )
        nSA(1).info = dicominfo( nSA(1).Filename );
      end
      nSA(1).info.xPhase = [ SAphase(1) , numel(nSA) ];
      
      I = [];
      for p = 1:numel( nSA )
        try,   im = nSA(p).DATA;
        catch, im = dicomread( nSA(p).Filename );
        end
        I = cat( 4 , I , im );
      end

      HC{end+1,1} = I;
      
      
      try,    HC{end  ,2} = nSA(1).info;
      catch,  HC{end  ,2} = dicominfo( nSA(1).Filename );
      end
      
      CS{end+1,1} = [];
      sns = [ sns ; nsn  ];
    end
    
  end  

  if removeZeroSlices
    ZLevel = NaN( 1 , size(HC,1) );
    for h = 4:size(HC,1)
      try, ZLevel(h) = DICOMxinfo( HC{h,2} ,'xZLevel' ); end
    end
    
    Z = Inf( 1 , numel(ZLevel) );
    for h = 4:numel(Z)
      Z(h) = min( abs( ZLevel([4:h-1,h+1:end]) - ZLevel(h) ) );
    end
    
    HC( Z(:) < 1e-3 & all( cellfun('isempty',HC(:,3:end)) , 2 ) ,:) = [];
  end
  
  
  
  
  
  ZLevel = cellfun( @(s)DICOMxinfo(s,'xZLevel') , HC(4:end,2) );
  if min( diff( sort( ZLevel ) ) ) < 1
    werror('HSlices:SAsmallGap','stack with a very small gap.');
  end
  sns = cellfun( @(s)DICOMxinfo(s,'SeriesNumber') , HC(4:end,2) );
  [~,ord] = sortrows( [ZLevel -sns] );
  HC = HC( [ 1 , 2 , 3 , ord(:).'+3 ] , :);
  CS = CS( [ 1 , 2 , 3 , ord(:).'+3 ] , :);

  
  sns = cellfun( @(s)s.SeriesNumber , HC(4:end,2) );
  if ~issorted( sns ) && ~issorted( sns(end:-1:1) )
    werror('HSlices:unsortedSN','no sorted SeriesNumber after ZLevel sorting.');
  end
  if any( diff( sort(sns)  )-1 )
    werror('HSlices:unconsecutive','no consecutive SeriesNumber after ZLevel sorting.');
  end


    if ~isempty( HC{1,2} ) && ~isfield( HC{1,2} , 'PlaneName' ), HC{1,2}.PlaneName = 'HLAx'; end
    if ~isempty( HC{2,2} ) && ~isfield( HC{2,2} , 'PlaneName' ), HC{2,2}.PlaneName = 'VLAx'; end
    if ~isempty( HC{3,2} ) && ~isfield( HC{3,2} , 'PlaneName' ), HC{3,2}.PlaneName = 'LVOT'; end
  for h = 4:size(HC,1)
    if ~isempty( HC{h,2} ) && ~isfield( HC{h,2} , 'PlaneName' ), HC{h,2}.PlaneName = 'SAx'; end
  end
  
  
  if 1
    for h = 1:size(HC,1)    
      try
        HC{h,2} = DICOMxinfo( HC{h,2} );
      end
      if ~isfield( HC{h,2} , 'xPhase' );
        try, HC{h,2}.xPhase = DICOMxinfo( HC{h,2} , 'xPhase' ); end
      end
    end
  end
  
  if asI3D
    for h = 1:size(HC,1)
      try
        HC{h,1} = I3D( HC(h,1:2) );
      end
    end
    HC(:,2) = [];
    CS(:,2) = [];
  end
  
%   for h = 1:numel(HC)
%     if isnumeric( HC{h} ) && ~isempty( HC{h} )
%       HC{h} = Segments2Contour( Contour2Segments( HC{h} ) );
%     end
%   end

  
  
%   if nargout > 1
%     C0 = C([]);
% %     C0 = C(1);
% %     for f = fieldnames(C0).', f = f{1};
% %       switch class(C0.(f))
% %         case {'uint8','int8','uint16','int16','uint32','int32','uint64','int64'}, C0.(f) = [];
% %         case {'single','double'}, C0.(f) = NaN( size(C0.(f)) );
% %         case {'char'}, C0.(f) = '';
% %         otherwise, C0.(f) = ndv;
% %       end
% %     end
%     
%     for i = 1:numel(CS)
%       if isempty( CS{i} )
%         CS{i} = C0;
%       end
%     end
%   end
  
  
end

