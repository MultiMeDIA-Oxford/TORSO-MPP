function [C,P] = pruneCVI42Contours( C , varargin )
  if nargout > 1
    P = C;
    for c = 1:numel(C)
      C(c).thisID = c;
    end
  end
    
  


  for v = 1:numel( varargin )
    
    switch lower( varargin{v} )
      case 'mostprobablepatient'
        Pid = { C( [ C.parentDICOMfound ] ).parentPatientID };
        [Pid,~,i] = unique( Pid );
        Pid = Pid{ argmax( accumarray(i,1) ) };
        
        C( ~strcmp( { C.parentPatientID } , Pid ) ) = [];
      
      
      case 'nopapilmusc'
        C( ~cellfun('isempty',strfind( cellfun(@lower,{C.Description},'un',0) ,'papilmusc' )) ) = [];
        
      case {'unique'}
        dups = [];
        for c = 1:numel(C)
          if any( c == dups ), continue; end
          for cc = c+1:numel(C)
            if  isequal( C(c).Points                      ,  C(cc).Points                     )  &&...
                isequal( C(c).parentUID                   ,  C(cc).parentUID                  )  &&...
                isequal( C(c).parentImageOrientation      ,  C(cc).parentImageOrientation     )  &&...
                isequal( C(c).ImageSize                   ,  C(cc).ImageSize                  )  &&...
                isequal( C(c).PixelSize                   ,  C(cc).PixelSize                  )  &&...
                isequal( C(c).SubpixelResolution          ,  C(cc).SubpixelResolution         )  &&...
                isequal( C(c).Label                       ,  C(cc).Label                      )  &&...
                isequal( C(c).Description                 ,  C(cc).Description                )  &&...
                isequal( C(c).parentDICOMfound            ,  C(cc).parentDICOMfound           )  &&...
                isequal( C(c).parentFilename              ,  C(cc).parentFilename             )  &&...
                isequal( C(c).parentPatientID             ,  C(cc).parentPatientID            )  &&...
                isequal( C(c).parentStudyInstanceUID      ,  C(cc).parentStudyInstanceUID     )  &&...
                isequal( C(c).parentStudyDescription      ,  C(cc).parentStudyDescription     )  &&...
                isequal( C(c).parentSeriesInstanceUID     ,  C(cc).parentSeriesInstanceUID    )  &&...
                isequal( C(c).parentSeriesDescription     ,  C(cc).parentSeriesDescription    )  &&...
                isequal( C(c).parentSeriesNumber          ,  C(cc).parentSeriesNumber         )  &&...
                isequal( C(c).NumberOfTimeInstant         ,  C(cc).NumberOfTimeInstant        )  &&...
                isequal( C(c).TimeInstant                 ,  C(cc).TimeInstant                )  &&...
                isequal( C(c).NumberOfSlices              ,  C(cc).NumberOfSlices             )  &&...
                isequal( C(c).Zid                         ,  C(cc).Zid                        )
              dups(end+1,1) = cc;
            end
          end
        end
        C( dups ) = [];
              
      
      case {'nf>1'}
        C( ~( [ C.NumberOfTimeInstant ] > 1 ) ) = [];
      case {'onlydicoms','dicoms','parent'}
        C( ~[ C.parentDICOMfound ] ) = [];
      case {'>2'}
        C( [ C.NPoints ] <= 2 ) = [];
      case {'>3'}
        C( [ C.NPoints ] <= 3 ) = [];
      case {'>4'}
        C( [ C.NPoints ] <= 4 ) = [];
      case {'>5'}
        C( [ C.NPoints ] <= 5 ) = [];
      case {'noatria'}
        %remove Atria
        C( strcmp( {C.Description} , 'lalaContour' ) ) = [];
      case {'noextent'}
        %remove ExtentPoints
        C( ~cellfun( 'isempty' , regexp( {C.Description} , 'ExtentPoints$' ) ) ) = [];
      case {'ed'}
        C( ~[ C.parentDICOMfound ] ) = [];

        %remove phases that are not in EndDiastole
        SUIDs = unique( { C.parentSeriesInstanceUID }.' );
        for s = SUIDs.', s = s{1};
          w = strcmp( { C.parentSeriesInstanceUID } , s );
          t = accumarray( [ C(w).TimeInstant ].' , 1 );
          try, t( (end+1):C( find(w,1) ).NumberOfTimeInstant ) = 0; end
          if numel(t) == 1, C(w) = []; continue; end
          t( 5:(end-5+1) ) = NaN;
          [~,t] = max( t );
          C( w & [ C.TimeInstant ] ~= t ) = [];
        end

      case {'es'}
        C( ~[ C.parentDICOMfound ] ) = [];

        %remove phases that are not in EndDiastole
        SUIDs = unique( { C.parentSeriesInstanceUID }.' );
        for s = SUIDs.', s = s{1};
          w = strcmp( { C.parentSeriesInstanceUID } , s );
          t = accumarray( [ C(w).TimeInstant ].' , 1 );
          try, t( (end+1):C( find(w,1) ).NumberOfTimeInstant ) = 0; end
          if numel(t) == 1, C(w) = []; continue; end
          t( [ 1:4 , (end-4+1):end ] ) = NaN;
          [~,t] = max( t );
          C( w & [ C.TimeInstant ] ~= t ) = [];
        end
        
      case {'sort'}
        nC = numel(C);

        try
          [~,~,val] = unique( { C.cvi42wsxFile } ,'stable' );
          [~,ord] = sort( val ); C = C(ord);
        end
        
        
        val = Inf( nC , 1 );
        for c = 1:nC, try, val(c) = C(c).NPoints; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = repmat( {char(65535)} , [ nC , 1 ] );
        for c = 1:nC, try, val{c} = C(c).Type; if all(isnan(double(val{c}))), val{c} = char(65535); end; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = Inf( nC , 1 );
        for c = 1:nC, try, val(c) = C(c).IsManuallyDrawn; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = repmat( {char(65535)} , [ nC , 1 ] );
        for c = 1:nC, try, val{c} = C(c).Label; if all(isnan(double(val{c}))), val{c} = char(65535); end; end; end
        [~,ord] = sort( val ); C = C(ord);

        val = Inf( nC , 1 );
        for c = 1:nC, try, val(c) = C(c).TimeInstant; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = Inf( nC , 1 );
        for c = 1:nC, try, val(c) = C(c).NumberOfSlices; end; end
        [~,ord] = sort( val ); C = C(ord);

        val = Inf( nC , 1 );
        for c = 1:nC, try, val(c) = C(c).parentSeriesNumber; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = Inf( nC , 1 );
        for c = 1:nC, try, val(c) = C(c).Zid; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = Inf( nC , 1 );
        for c = 1:nC, try
            switch lower( C(c).Description )
              case 'saepicardialcontour',          val(c) = 1;
              case 'laepicardialcontour',          val(c) = 2;
              case 'saendocardialcontour',         val(c) = 3;
              case 'laendocardialcontour',         val(c) = 4;
              case 'sarvendocardialcontour',       val(c) = 5;
              case 'bloodpoolcontour',             val(c) = 6;
              case 'lalacontour',                  val(c) = 7;
              case 'laxlvextentpoints',            val(c) = 8;
              case 'lineroicontour',               val(c) = 9;
              case 'sacardialinferiorrefpoint',    val(c) = 10;
              case 'sacardialrefpoint',            val(c) = 11;
              case 'freedrawroicontour',           val(c) = 12;
            end
        end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = repmat( {char(65535)} , [ nC , 1 ] );
        for c = 1:nC, try, val{c} = C(c).parentUID; end; end
        [~,ord] = sort( val ); C = C(ord);

        val = repmat( {char(65535)} , [ nC , 1 ] );
        for c = 1:nC, try, val{c} = C(c).parentSeriesInstanceUID; if all(isnan(double(val{c}))), val{c} = char(65535); end; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = repmat( {char(65535)} , [ nC , 1 ] );
        for c = 1:nC, try, val{c} = C(c).parentSeriesDescription; if all(isnan(double(val{c}))), val{c} = char(65535); end; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = Inf( nC , 1 );
        for c = 1:nC, try
            val(c) = C(c).ImageHeader.origin * C(c).ImageHeader.TransformMatrix(:,3);
        end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = Inf( nC , 1 );
        for c = 1:nC, try
            switch lower( C(c).parentSeriesDescription(1) )
              case 'h', val(c) = 1;
              case 'v', val(c) = 2;
              case 'l', val(c) = 3;
              case 's', val(c) = 4;
            end
        end; end
        [~,ord] = sort( val ); C = C(ord);

        val = repmat( {char(65535)} , [ nC , 1 ] );
        for c = 1:nC, try, val{c} = C(c).parentStudyInstanceUID; if all(isnan(double(val{c}))), val{c} = char(65535); end; end; end
        [~,ord] = sort( val ); C = C(ord);
        
        val = repmat( {char(65535)} , [ nC , 1 ] );
        for c = 1:nC, try, val{c} = C(c).parentPatientID; if all(isnan(double(val{c}))), val{c} = char(65535); end; end; end
        [~,ord] = sort( val ); C = C(ord);

        val = Inf( nC , 1 );
        for c = 1:nC, try, val(c) = ~C(c).parentDICOMfound; end; end
        [~,ord] = sort( val ); C = C(ord);
        
%         clc
%         for c = 1:nC
%           fprintf('- ');try, fprintf( '%15g ', C(c).ImageHeader.origin * C(c).ImageHeader.TransformMatrix(:,3) ); end
%           fprintf('- ');try, fprintf( '%30s ', C(c).parentSeriesDescription ); end
%           fprintf('- ');try, fprintf( '%30s ', C(c).Description ); end
%           fprintf('- ');try, fprintf( '%60s ', C(c).parentUID ); end
%           fprintf('- ');try, fprintf( '%60s ', C(c).parentSeriesInstanceUID ); end
%           fprintf('- ');try, fprintf( '%60s ', C(c).parentStudyInstanceUID ); end
%           fprintf('- ');try, fprintf( '%40s ', C(c).parentPatientID ); end
%           fprintf('- ');try, fprintf( '%d ', C(c).parentDICOMfound ); end
%           fprintf('\n');
%         end
% 
%         val = Inf( nC , 1 );
%         for c = 1:nC, try
%             val(c) = C(c).ImageHeader.origin * C(c).ImageHeader.TransformMatrix(:,3);
%         end; end
%         plot(val)
  %%      
        
    end    
  end

  if nargout > 1
    P( [ C.thisID ] ) = [];
    C = rmfield( C , 'thisID' );
  end

end

