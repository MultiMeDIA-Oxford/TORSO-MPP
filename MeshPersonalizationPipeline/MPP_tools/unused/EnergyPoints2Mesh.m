function E = EnergyPoints2Mesh( M , P )
  [~,~,d] = vtkClosestElement( M , P );
  E = sum( d.^2 );
end
