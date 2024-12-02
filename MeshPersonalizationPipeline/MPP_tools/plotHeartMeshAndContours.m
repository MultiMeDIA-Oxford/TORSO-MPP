function ds = plotHeartMeshAndContours( M , CS )

  plotMESH( M ,'ne','FaceAlpha',0.2,'dull','gouraud','patch');
  hplotMESH( MeshBoundary( M ) , 'EdgeColor','k','patch');
  %hplot3d(EPIc,'m','LineWidth',3)
  ds = {};
  for C = CS(:).'
    C = C{1};
    if isempty(C), continue; end
    [~,cp,d] = vtkClosestElement( M , C ); ds{end+1,1} = d;
    hold on
    cline( C , d ,'LineWidth',3);
    hold off;
    
    w = d > 1;
    if any(w)
      from = C(w,:);
      to   = cp(w,:);
      d    = d(w);

      patch( 'Vertices', [ from ; to ] , 'Faces' , [ 1:size(from,1) ; size(from,1)+1:size(from,1)*2 ].' ,'EdgeColor','flat','CData',[d;d]);
    end
    
%     plot3d( C(w,:) , cp(w,:) , '-','Color',[ );
  end
  cm = linspace(0,1,128).';
  cm = [ ones(size(cm)) , cm , zeros(size(cm)) ];
  
  colormap( [ 0.7,0.7,0.7 ; cm ; 1 0 1 ]);
  caxis([1 4]);
  headlight;
%   colorbar

end
