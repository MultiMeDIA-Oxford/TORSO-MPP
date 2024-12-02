function D = findDuplicates( A , B )
% find the files in A that are equal to some one of B

%   %first remove the files in B that are also in A
%   B( ismember( { B.name } , { A.name } ) ) = [];

  same_files = false;
  if nargin < 2
    A = A(end:-1:1);
    B = A;
    same_files = true;
  end


  D = A(1); D(1) = []; D = reshape( D , [0 0] );
  Bbytes   = [B.bytes];
  Bdatenum = [B.datenum];
  for a = 1:numel(A), try
    if ~rem(a,200), disp( a/numel(A) * 100 ); pause(1); end
    bb = true;
    bb = bb    &   Bbytes   == A(a).bytes;
%     bb = bb    &   Bdatenum == A(a).datenum;
    if same_files, bb( 1:a ) = false; end
    
    BB = find( bb );
    for b = BB(:).'
      if areDuplicates( A(a).name , B(b).name )
        disp( A(a).name );
%         try, delete( A(a).name ); end
        D(end+1,1) = A(a);
        D(end).isdir = B(b).name;
        break;
      end
    end
  end; end

  if same_files
    D = D(end:-1:1);
  end
  
end
