function s_ = printf( varargin )

  persistent STDOUT_HISTORY

  persistent OPTS
  if isempty( OPTS )
    OPTS.LinePrefix = '';
    OPTS.IndentationLevel = -1;
  end
  if nargin == 1 && isstruct( varargin{1} )
    opts = varargin{1};
    if 0
    elseif isfield( opts , 'setIndentationLevel' )
      OPTS.IndentationLevel = opts.setIndentationLevel;
    elseif isfield( opts , 'increaseIndentationLevel' ) && OPTS.IndentationLevel >= 0
      OPTS.IndentationLevel = OPTS.IndentationLevel + 1;
      OPTS.LinePrefix = [ OPTS.LinePrefix , '    | '];
    elseif isfield( opts , 'decreaseIndentationLevel' )
      OPTS.IndentationLevel = max( OPTS.IndentationLevel - 1 , -1 );
      OPTS.LinePrefix = OPTS.LinePrefix(1:end-6);
    elseif isfield( opts , 'resetIndentationLevel' )
      OPTS.IndentationLevel = -1;
      OPTS.LinePrefix = '';
    end
    s_ = OPTS;
    
    return;
  end



  sID = find( cellfun( @ischar , varargin ) , 1 );
  if isempty(sID)
    error('no string to print');
  end
  
  FIDS   = varargin( 1:sID-1 );
  if isempty( FIDS ), FIDS = {1}; end
  if numel( FIDS ) == 1 && iscell( FIDS{1} )
    FIDS = FIDS{1};
  end
  FIDS( cellfun( 'isempty' , FIDS ) ) = [];
  if isempty( FIDS ) && nargout < 1
    return;
  end
  
  
  STRING = varargin{ sID };
  args   = varargin( sID+1:end );
  
  
  STRING = regexprep( STRING , '(\%\+?\-?[0-9]*\.?[0-9]*)R(.)' , '\x{A0}$1$2\x{A1}' );
  STRING = regexprep( STRING , '(\%\+?\-?[0-9]*\.?[0-9]*)L(.)' , '\x{A2}$1$2\x{A3}' );
  STRING = regexprep( STRING , '(\%\+?\-?[0-9]*\.?[0-9]*)C(.)' , '\x{A4}$1$2\x{A5}' );
  STRING = regexprep( STRING , '(\%)(\+?\-?[0-9]*\.?[0-9]*)(u)' , '\x{A6}\%30\.30e\($2\)\x{A7}' );
  
  STRING = regexprep( STRING , '(\%)(\+?\-?[0-9]*\.?[0-9]*)(W)' , '\x{A8}\%30\.30e\($2\)\x{A9}' );
  
  while 1
    % printf('%4{kk|, %}')   --> 'kk, kk, kk, kk'
    % printf('%5{%s |, %}')  --> '%s , %s , %s , %s '
    [bStart,bEnd] = regexp( STRING , '(\%[0-9]*{[^}]*\%})' , 'start' , 'end' , 'once' );
    if isempty(bStart), break; end
    
    B = STRING( bStart:bEnd );
    n = str2double( B( 2:find( B == '{' , 1 )-1 ) );
    B = regexp( B , '\%[0-9]*{([^}]*)\%}' , 'tokens' ,'once'); B = B{1};
    
    B = repmat( B , [1 n] );
    B = B( 1:find( B == '|' , 1 , 'last' ) );
    B = strrep( B , '|' , '' );
    
    STRING = [ STRING( 1:bStart-1 ) , B , STRING( bEnd+1:end ) ];
  end
  
  
  if ~isempty( OPTS.LinePrefix )
    STRING = regexprep( STRING , '^(\\\|)(.)(.*)' , '\x8$2$3' );
  else
    STRING = regexprep( STRING , '^(\\\|)(.)(.*)' , '$3' );
  end
  
  STRING = sprintf( STRING , args{:} );
  
  if any( STRING >= 160 & STRING < 180 )
    % %u rewriting
    while 1
      [uStart,uEnd] = regexp( STRING , '\x{A6}([ ]*)[^\x{A7} ]*\x{A7}' , 'start' , 'end' , 'once' );
      if isempty(uStart), break; end
      U = STRING( uStart:uEnd );
      openId  = find( U == '(' , 1 );
      closeId = find( U == ')' , 1 );
      gap_and_precision = U( openId+1:closeId-1 );
      if isempty( gap_and_precision )
        gap_and_precision = '0';
      end
      
      U = uneval( eval( U( 2:openId-1 ) ) );
      
      dotId = find( gap_and_precision == '.' );
      if ~isempty(dotId)
        gap       = str2double( gap_and_precision(1:dotId-1) );
        precision = str2double( gap_and_precision(dotId+1:end) );
      else
        gap       = str2double( gap_and_precision );
        precision = Inf;
      end
      
      if ~isinf( precision )
        dotId = find( U == '.' );
        if ~isempty( dotId )
          eId = find( U == 'e' );
          if isempty( eId ), eId = numel(U)+1; end
          U = U( unique( [ 1:min(end,dotId+precision) , eId:end ] ) );
        end
      end
      
      if gap
        gap = max( 0 , gap - numel(U) );
        U = [ blanks( gap ) , U ];
      end
      
      STRING = [ STRING(1:uStart-1) , U , STRING(uEnd+1:end) ];
    end
    
    

    
    % %W rewriting
    while 1
      [uStart,uEnd] = regexp( STRING , '\x{A8}([ ]*)[^\x{A9} ]*\x{A9}' , 'start' , 'end' , 'once' );
      if isempty(uStart), break; end
      W = STRING( uStart:uEnd );
      openId  = find( W == '(' , 1 );
      closeId = find( W == ')' , 1 );
      width = str2double( W( openId+1:closeId-1 ) );
      if isempty( width )
        width = '8';
      end
      
      W = eval( W( 2:openId-1 ) );
      W = Pftoa( sprintf('%%%dW' , width ) , W );
      
      if 1
        width = max( 0 , width - numel(W) );
        W = [ blanks( width ) , W ];
      end
      
      STRING = [ STRING(1:uStart-1) , W , STRING(uEnd+1:end) ];
    end
    
    
    % align to right
    STRING = regexprep( STRING , '(\x{A0})([^\x{A1}]*)([ ]*)(\x{A1})' , '$3$2' );

    % align to left
    STRING = regexprep( STRING , '(\x{A2})([ ]*)([^\x{A3}]*)(\x{A3})' , '$3$2' );
    
    
    % align to center
    toks = regexp( STRING , '\x{A4}([ ]*)[^\x{A5} ]*\x{A5}' , 'tokens' );
    for t = 1:numel(toks)
      T = toks{t}{1}; n = numel(T)/2;
      STRING = regexprep( STRING , [ '\x{A4}' , T , '([^\x{A5} ]*)' , '\x{A5}' ] , ...
                                   [ blanks(floor(n)) , '$1' , blanks(ceil(n)) ] );
    end
    
    toks = regexp( STRING , '\x{A4}[^\x{A5} ]*([ ]*)\x{A5}' , 'tokens' );
    for t = 1:numel(toks)
      T = toks{t}{1}; n = numel(T)/2;
      STRING = regexprep( STRING , [ '\x{A4}' , '([^\x{A5} ]*)' , T , '\x{A5}' ] , ...
                                   [ blanks(floor(n)) , '$1' , blanks(ceil(n)) ] );
    end
  end
  
  
  if ~isempty( OPTS.LinePrefix )
    if isequal( STRING(1:min(2,end)) , [' ' 8] )
      STRING(1:2) = [];
    else
      STRING = [ OPTS.LinePrefix , STRING ];
    end
    addLineBreakAtEnd = false;
    if STRING(end) == 10
      addLineBreakAtEnd = true;
      STRING(end) = [];
    end
    STRING = strrep( STRING , char(10) , [ char(10) , OPTS.LinePrefix ] );
    if addLineBreakAtEnd
      STRING = [ STRING , 10 ];
    end
  end
  
  while 1
    nSTRING = numel( STRING );
    STRING = regexprep( STRING , '([^^\x8]\x8)' , '' );
    if nSTRING == numel( STRING ), break; end
  end
  
  if nargout, s_ = STRING; end
  
  % check fids, if not --> error
  for f = 1:numel( FIDS )
    FID = FIDS{f};
    if ~isnumeric( FID ) || any( mod( FID , 1 ) )
      error('incorrect FID: %d-th  is %s', f , uneval( FID ) );
    end
  end

  % send to fids
  for f = 1:numel( FIDS )
    FID = FIDS{f};
    
    if numel(FID) == 1 && abs(FID) == 1
      STDOUT_HISTORY = [ STDOUT_HISTORY , STRING ];
      if numel( STDOUT_HISTORY ) > 1e4
        STDOUT_HISTORY = STDOUT_HISTORY( (numel(STDOUT_HISTORY)+1-1e4):end );
      end
    end
    
    if 0
    elseif isscalar( FID ) && isequal( FID , -1 )

      %print and flush the diary
      fprintf( 1 , '%s' , STRING );
      if strcmp( get(0,'Diary') , 'on' )
        diary('off');diary('on');
      end
      
    elseif isscalar( FID )

      try
        fprintf( FID , '%s' , STRING );
      catch
        warning('imposible to write in fid  %d' , FID );
      end
      
      
    elseif all( FID < 0 )

      FILE = fopen( char( -FID ) , 'w' );
      if FILE <= 0
        warning('imposible to open file "%s"',char(-FID));
        continue;
      end
      try
        fprintf( FILE , '%s' , STRING );
      catch
        warning('imposible to write in file "%s"',char(-FID));
      end
      fclose( FILE );

    elseif all( FID > 0 )

      FILE = fopen( char( FID ) , 'a' );
      if FILE <= 0
        warning('imposible to open file "%s"',char(FID));
        continue;
      end
      try
        fprintf( FILE , '%s' , STRING );
      catch
        warning('imposible to write in file "%s"',char(FID));
      end
      fclose( FILE );

    end
  end

  
  %if strcmp( get(0,'Diary') , 'on' ), diary('off');diary('on'); end

end

























function s = Pftoa(fmtstr,val) % floating point to ascii convertion - called by prin.m
%
% Pftoa.m:  Alternative number conversion formatting - version 01Jan17
% Author:   Paul Mennen (paul@mennen.org)
%           Copyright (c) 2017, Paul Mennen
%
% function s = Pftoa(fmtstr,val)
% returns a string representing the number val using the format specified by fmtstr
%.
% fmtstr: format description string
% val:    the number to be converted to ascii
%
%
% fmtstr in the form '%nV' --------------------------------------------
% n: the field width
% s: the string representation of x with the maximum resolution possible
%    while using at exactly n characters.
%
% fmtstr in the form '%nv' ---------------------------------------------
% n: the field width, not counting decimal point (since it's so skinny)
% s: the string representation of x with the maximum resolution possible
%    while using at exactly n+1 characters. (If a decimal point is not
%    needed, then only n characters will be used).
%
% fmtstr in the form '%nW' ---------------------------------------------
% n: the field width
% s: the string representation of x with the maximum resolution possible
%    while using at most n characters.
%
% fmtstr in the form '%nw' ---------------------------------------------
% n: the field width, not counting decimal point (since it's so skinny)
% s: the string representation of x with the maximum resolution possible
%    while using at most n+1 characters.
%
% For any of the VWvw formats, if the field width is too small to allow
% even one significant digit, then '*' is returned.

% If the format code is not one of the four characters VWvw then use
% the sprintf c conventions: s=sprintf(fmtstr,number);
% e.g.  Pftoa('%7.2f',value) is identical to sprintf('%7.2f',value).

% Optional format modifiers are allowed between the % sign and the field width.
% An optional modifier is one of the characters "+-jJkL". The + and - modifiers
% control padding the output with blanks and the other four modifiers allow
% the conversion of complex numbers. These modifies are described fully in
% the prin.pdf help file.

% BACKGROUND: ---------------------------------------------------------------
% Pftoa() expands on the number conversion capabilities of sprintf's d,f,e,g
% conversion codes (which are identical to the c language conventions). These
% formats are ideal for many situations, however the fact that these formats
% will sometimes output more characters than the specified field width make
% them inappropriate when used to generate a number that is displayed in a
% fixed sized GUI element (such as an edit box) or in a table of numbers
% arranged in fixed width columns. This motivated the invention of Pftoa's new
% V and W formats. With the e & g formats one is often forced to specify a very
% small number of signifcant digits since otherwise on the possibly rare
% occations when the numbers are very big or very small an unintelligable
% display is produced in the GUI, or the generated table becomes hopelessly
% misallined. For example, suppose a column of numbers of width 8 characters
% normally contains numbers that look something like 1.234567 but could
% occationally contain a number such as 7.654321E-100. The best you could
      % do with a g format would be '%8.2g' which would produce the strings
% 1.2 and 7.6E-100 which means the numbers we see most often are truncated
% far more than necessary. Essentially with the e and g formats, you specify
% the precision you want and you accept whatever size string is produced.
% With the V and W formats, this is turned around. You specify the length
% of the string you want, and Pftoa supplies as much precision as possible
% with this constraint.
%
% For displaying columns of numbers (using a fixed spaced font) the V format
% is best since it always outputs a character string of the specified length.
% For example, the format string '%7V' will output seven characters. Never
% less and never more.
%
% For displaying a number in an edit box the W format is best. For example
% '%7W' will output at most seven characters, although it will output fewer
% than 7 characters if this does not reduce the precision of the output.
% For example, the integer "34" will be displayed with just two characters
% (instead of padding with blanks like the V format does). Since the text
% in an edit box is most often center aligned, this produces a more pleasing
% result. Using a lower case w (i.e. the '%7w' format) behaves similarly
% except that periods are not counted in the character count. This means
% that if a decimal point is needed to represent the number, 8 characters
% will be output and if a decimal point is not included in the representation
% then only 7 characters are output. This is most useful when using
% proportional width fonts. The period is not counted because the character
% width of the period is small compared with the '0-9' digits. Actually
% since most GUIs are rendered using proportially spaced fonts, the w format
% is used more often than the W format.
%
if nargin~=2 disp('Calling sequence: resultString = Pftoa(formatString,val)'); return; end;

fmtstr = deblank(fmtstr);                 % make sure format code is the last character
fcode = fmtstr(end);  fc = upper(fcode);  % extract format code. Convert to upper case
fw = fmtstr(2:end-1);                     % extract field width
pad = 0;                                  % no final padding (+1/-1 = pad on left/right)
if isempty(fw) fw = '7'; end;             % if field width is omited, use the default (7)
mf = fw(1);  sp = ' '; lmf = lower(mf);   % get possible modifier
if lmf=='k' mf=mf-1; lmf=lmf-1; sp=''; end; % k/K modifiers are more "Kompact" than j/J (no spaces)
if lmf=='j'                               % is there a complex modifier?
  fw(1) = '%';  fw = [fw fcode];          % yes, create the format string without the modifier
  ival = imag(val);  rval = real(val);
  if mf=='J' | (rval*ival)~=0
              if ival<0 pp = '-'; ival = -ival; else pp = '+'; end;
              if rval==0 rval=abs(rval); end;
              s = [Pftoa(fw,rval) sp pp sp Pftoa(fw,ival) 'i'];  % both real/imag parts
  elseif ival s = [Pftoa(fw,ival) 'i']; else s = Pftoa(fw,rval); % only need one part
  end;
  return;
end;
if fc~='W' & fc~='V'  s = sprintf(fmtstr,val); return; end; % use sprintf if format isn't v,V,w,W
uc = fc==fcode;                           % upper case code (i.e. V or W)
val = real(val);                          % ignore imaginary part
if mf=='+' pad=1; elseif mf=='-' pad=-1; end;
if pad fw = fw(2:end); if isempty(fw) fw = '7'; end; end;
w = sscanf(fw,'%d'); v = w;               % get field width
if ~w s = ''; return; end;                % zero field width returns an empty string
if fc=='V' s = [blanks(v-1) '*']; else s = '*'; end;  ss = s;  neg = [];
if     val==0     s = strrep(s,'*','0');

elseif isnan(val) s = [blanks(length(s)-3) 'NaN']; if v<3 s=s(1:v); end;
elseif isinf(val) if val>0 s = [blanks(length(s)-3) 'Inf'];  if v<3 s=s(1:v); end;
                  else     s = [blanks(length(s)-4) '-Inf']; if v<4 s=s(1:v); end;
                  end;
else neg = val<0;
end;
if isempty(neg)  % special cases (0,Inf,Nan) come here
  if pad
    if fc=='W'    p = v-length(s);  if p<1 return; end;
                  if pad>0 s = [blanks(p) s]; else s = [s blanks(p)]; end;
    elseif pad<0  while s(1)==' ' s = [s(2:end) ' ']; end;
    elseif val==0 s = ['0.' repmat('0',1,v-2)]; 
    end;
  end;
  return;
end;
q = [6 0 1 1; 5 1 1 2; 4 0 3 3; 0 0 0 0; 3 0 4 4; 4 1 2 3; 5 2 0 2;   % v,w formats
     7 1 0 0; 6 2 0 1; 5 1 2 2; 0 0 0 0; 4 1 3 3; 5 2 1 2; 6 3 -1 1]; % V,W formats
q = q(7*uc+min(find(abs(val) < [1e-99 1e-9 .01 10^(v-neg) 1e10 1e100 inf])),:);
fp = v - q(1) - neg;                         % compute fp, the format precision
if fp==-1 & uc fp=0; v=v+1; end;
if fp<0 return; end;                         % not enough digits available
if q(1) fmt = 'e'; else fmt = 'g'; end;      % select the e or g format
if ~fp  q = q + [0,1,-1,-1]; end;            % e format sometimes removes the "."
s = sprintf(sprintf('%%1.%d%c',fp,fmt),val); % convert to decimal string
n = length(s);                               % length of result
if n>3 & s(n-3)=='e'                         % is it a 2 digit exponent (for MAC)
  s = [s(1:n-2) '0' s(n-1:n)];               % change it to 3 digits
  n = n + 1;
end;
if q(1) q = [1:v-q(2) v+q(3):v+q(4)];        % here for e format
else                                         % here for g format
  fdot = findstr('.',s);
  if length(fdot)
    i = uc;  lz = 0;
    if fdot==2 & s(1)=='0' | length(findstr('-0.',s))
       i = i + 1;
       lz = length(findstr('0.0',s));
    end;
    if i s = sprintf(sprintf('%%1.%dg',fp-i),val); % use one or two fewer digits
         n = length(s);
    end;
    if lz s = strrep(s,'0.0','.0'); n=n-1; end;
  end;
  q = 1:min(~uc+v,n);
end; % end if q(1)
if max(q)>n s = ss; return; end;             % don't go over array bounds
s = s(q);  n = length(s);
if length([findstr(s,'0') findstr(s,'.') findstr(s,'-')]) == n % is there at least one nonzero digit?
  s = ss; return;                                              % return if not
end;
if fc=='V'
  p = w-length(s);                           % number of padding characters required
  isp = length(findstr('.',s));              % true if there is a period
  if ~uc p=p+isp; end;
  if p<=0 return; end;                       % no padding required
  if fmt=='e' s = [' ' s]; return; end;      % pad with blanks on left (p will be 1)
  if ~isp s=[s '.']; if uc p=p-1; end; end;  % if there is no period, add one before padding
  s = [s repmat('0',1,p)];                   % pad with zeros on the right
elseif pad & fc=='W'
  p = v-length(s);  if p<1 return; end;
  if pad>0 s = [blanks(p) s]; else s = [s blanks(p)]; end;
end;
end
% end function Pftoa

