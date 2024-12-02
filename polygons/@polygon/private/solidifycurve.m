function solidcurve=solidifycurve(curve,ep)
% solidcurve=solidifycurve(curve)
% curve:  coordenadas Nx2 de la curva original
% solidcurve: polygono solido


    v=diff(curve,1,1);
    % Normal en sentido levogiro de (x,y) es (y,-x)
    n=[-v(:,2),v(:,1)];
    n(end+1,:)=n(end,:);
    n(2:end-1,:)=(n(1:end-2,:)+n(2:end-1,:))/2;
    n=n./repmat(sqrt(sum(n.^2,2)),1,2);
    solidcurve={[curve-ep(1)*n; (curve(end:-1:1,:)+ep(2)*n(end:-1:1,:))] [1]};


end
