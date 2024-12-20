function SummarizeHeartSlices( HS , Iname )

  if ischar( HS )
    HS = loadv( HS , 'HS' );
  end

  if nargin < 2
    Iname = NaN;
  end
  try
    if isnumeric( Iname ) && numel( Iname )==1 && isnan( Iname )
      Iname = commonPath( arrayfun( @(h)HS{h}.INFO.Filename , 1:size(HS,1) ,'un',0)' );
    end
  end
  if isnumeric( Iname ) && numel( Iname )==1 && isnan( Iname )
    Iname = '';
  end


  if ischar( Iname )
    printf( '%s\n' , Iname );
  end
  printf('        SN.DICOM Serie Description                       (Zlevel  )[  ED    ]   LVepi LVendo RVendo LVex \n')
  
  for h = 1:3
    if isempty( HS{h,1} )
      switch h
        case 1, printf('(no HLA)\n');
        case 2, printf('(no VLA)\n');
        case 3, printf('(no LVOT)\n');
      end
    else
      printf( 'row%2Rd: %3Rd.%45Ls           [%2d of %2d]   | %3Cd | %3Cd | %3Cd | %3Cd |\n' , ...
        h ,...
        HS{h,1}.INFO.SeriesNumber     ,...
        HS{h,1}.INFO.SeriesDescription ,...
        DICOMxinfo( HS{h,1}.INFO , 'xPhase' ) , size( HS{h,1} ,4) ,...
        size( HS{h,2} ,1),...
        size( HS{h,3} ,1),...
        size( HS{h,4} ,1),...
        size( HS{h,5} ,1) ...
      );
    end
  end
  
  fprintf('------- SAs stack (more basal) ----------------------------------------------------------------------------\n');
  for h = size( HS ,1):-1:4
      printf( 'row%2Rd: %3Rd.%45Ls (Z:%6.1Ru)[%2d of %2d]   | %3Cd | %3Cd | %3Cd | %3Cd |\n' , ...
        h ,...
        HS{h,1}.INFO.SeriesNumber     ,...
        HS{h,1}.INFO.SeriesDescription ,...
        HS{h,1}.INFO.xZLevel ,...
        DICOMxinfo( HS{h,1}.INFO , 'xPhase' ) , size( HS{h,1} ,4) ,...
        size( HS{h,2} ,1),...
        size( HS{h,3} ,1),...
        size( HS{h,4} ,1),...
        size( HS{h,5} ,1) ...
     );
  end
  fprintf('------- SAs stack (more apical) ---------------------------------------------------------------------------\n');
  fprintf('\n\n');

end
