function P=orientate_polygon(P)


for i=1:size(P.XY,1)
    if (P.XY{i,2}~=0)&&(~orientation(P.XY{i,1}))
        P.XY{i,1}=flipud(P.XY{i,1});
    end;
end;