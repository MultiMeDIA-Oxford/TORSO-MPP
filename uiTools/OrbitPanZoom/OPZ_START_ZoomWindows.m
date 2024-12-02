function OPZ_START_ZoomWindows( h )
  aa = ancestortool( hittest , 'axes' );
  if ~aa || is3daxes(aa), return; end

  STORED_STATE = setACTIONS( h , 'suspend' );

  
  P1 = mean( get(aa,'CurrentPoint') );

  Rectangle = line('Parent',aa,'Linestyle',':','Linewidth',2,'Color',[1 0 0],'XData',NaN,'YData',NaN,'ZData',NaN,'XlimInclude','off','YLimInclude','off','ZLimInclude','off','Clip','off');

  set(h,'WindowButtonUpFcn'     ,@(h,e) STOP_ZoomWindows );
  set(h,'WindowButtonMotionFcn' ,@(h,e) ZoomWindows      );

  [ZZ,HH,VV] = viewfrom( aa ); ZZ = ZZ(2);
  idHH = HH - 'X'+1;
  idVV = VV - 'X'+1;
  idZZ = ZZ - 'X'+1;

  fixedDAR = strcmp( get(aa,'DataAspectRatioMode'),'manual' );

  hl = get( aa , [HH 'lim']); DH = diff(hl);
  vl = get( aa , [VV 'lim']); DV = diff(vl);

  set( Rectangle , [HH 'Data'] , [NaN NaN NaN NaN NaN] , ...
                   [VV 'Data'] , [NaN NaN NaN NaN NaN] , ...
                   [ZZ 'Data'] , zeros(1,5)+P1(idZZ) );

  function ZoomWindows
    P2 = mean( get(aa,'CurrentPoint') );
    
    isCTRL = any( strcmp( pressedkeys , 'LCONTROL') );
    if ( fixedDAR && ~isCTRL ) || isCTRL
      dv = P2(idVV) - P1(idVV);
      dh = P2(idHH) - P1(idHH);
      
      P2( idHH ) = P1( idHH ) + sign(dh)*sign(dv) * dv * DH/DV;
      
%       t  = (P2([idHH idVV]) - P1([idHH idVV]))*[ DH ;  DV ]/DD;
%       C1 = [0 0 0];
%       C1([idHH idVV]) = t*[ DH , DV ];
%       C1 = C1 + P1;
%       
%       t  = (P2([idHH idVV]) - P1([idHH idVV]))*[ DH ; -DV ]/DD;
%       C2 = [0 0 0];
%       C2([idHH idVV]) = t*[ DH , -DV ];
%       C2 = C2 + P1;
% 
%       if fro2( C2 - P2 ) < fro2( C1 - P2 )
%         P2([idHH idVV]) = C2([idHH idVV]);
%       else
%         P2([idHH idVV]) = C1([idHH idVV]);
%       end
    end

    set( Rectangle , [HH 'Data'], [P1(idHH) P2(idHH) P2(idHH) P1(idHH) P1(idHH) ] , ...
                     [VV 'Data'], [P1(idVV) P1(idVV) P2(idVV) P2(idVV) P1(idVV) ] );
  end

  function STOP_ZoomWindows
    setACTIONS( h , 'restore' , STORED_STATE );

    try
    xn = get(Rectangle , [HH 'Data']); xn = sort( xn(1:2) );
    yn = get(Rectangle , [VV 'Data']); yn = sort( yn(2:3) );

    delete( Rectangle );

    for t= 0.1:0.1:1
      set( aa , [HH 'Lim'], hl+t*(xn-hl) , [VV 'Lim'], vl+t*(yn-vl) );
      pause(0.01);
    end
    end
  end

end
