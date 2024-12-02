function o = subsref( P , s )

  S= [];

  s_orig = s;
  optional_args = {};
  for ss = 1:numel(s)
%     if numel( s(ss).subs ) == 0, S= '0'; continue; end
    stype = s(ss).type;
    switch stype
      case '.'
        name = s(ss).subs;
        S = [S '.' name ];
      case {'()','{}'}
        first_opt_arg = find( cellfun( @(x) ischar(x) && ~strcmp(x,':') , s(ss).subs ) , 1 );
        if ~isempty( first_opt_arg )
          optional_args = s(ss).subs(first_opt_arg:end);
          s(ss).subs = s(ss).subs(1:first_opt_arg-1);
        end
        S = [ S stype ];
        switch numel( s(ss).subs )
          case 0,    S= [S(1:end-1) '0' S(end)];
          case 1,    S= [S(1:end-1) '1' S(end)];
          case 2,    S= [S(1:end-1) '2' S(end)];
          case 3,    S= [S(1:end-1) '3' S(end)];
          case 4,    S= [S(1:end-1) '4' S(end)];
          otherwise, S= [S(1:end-1) '_' S(end)];
        end
    end
  end

  
  switch S
    case '(0)'
      o = P;
      o.XY = polygon_mx( P.XY );
    case '(1)'
      idxs = s(1).subs{1};
      o = P;
      o.XY = P.XY(idxs,:);
   
    case '.XY'
%           if size(P.XY,1) ~= 1
%               error('solo a polygonos simples');
%           end
%           o = P.XY{1,1};
            o = cell2mat( P.XY(:,1) );
    case '.type'
            o = cell2mat( P.XY(:,2) );
      
      case '.XY(2)'
          idxs1 = s(2).subs{1};
          idxs2 = s(2).subs{2};
          xy = cell2mat( P.XY(:,1) );
          o=xy(idxs1,idxs2);
          
    case '(1).XY(2)'
          idxs = s(1).subs{1};
          idxs1 = s(3).subs{1};
          idxs2 = s(3).subs{2};
          o = P.XY{idxs,1}(idxs1,idxs2);
      case '(1).XY'
          idxs = s(1).subs{1};
          if numel(idxs) ~= 1
              error('solo de a una subpolygon');
          end
          o = P.XY{idxs,1};
          
      case '(1).type'
      idxs = s(1).subs{1};
      o = P.XY{idxs,2};
          
      case '.fill(1)'
          o = P;
          new_xy = s(2).subs{1};
          
          nop = ( cellfun( @(c)size(c,1) , P.XY(:,1) ) );
          if size( new_xy , 1 ) ~= sum(nop)
              error('incorrect number of points');
          end
          if size( new_xy , 2 ) ~= 2
              error('que????');
          end
          
          lastXY = 0;
          for c = 1:size( P.XY , 1 )
            o.XY{c,1} = new_xy( lastXY + (1:nop(c)) , : );
            lastXY = lastXY + nop(c);
          end
          
          
          
          
          
          
          
    
  end

end


