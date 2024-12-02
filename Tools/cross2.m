function r = cross2(a,b)
  % Optimizes r = cross(a,b,2), that is it computes cross products per row
  % Faster than cross if I know that I'm calling it correctly
  r = [ a(:,2).*b(:,3) - a(:,3).*b(:,2) ,...
        a(:,3).*b(:,1) - a(:,1).*b(:,3) ,...
        a(:,1).*b(:,2) - a(:,2).*b(:,1) ];
end
