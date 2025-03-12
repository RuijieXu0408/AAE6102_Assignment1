function Task5(trackResults, navSolutions)
%% for Kalman Filter
figure(501);
% open_gt = [22.328444770087565,114.1713630049711 0]; %% Opensky gt --RayJ
open_gt = [22.3198722,114.209101777778 0]; %% Urban gt --RayJ

geoscatter(open_gt(1),open_gt(2),"*");
geobasemap satellite;
error=[];
for i=1:size(navSolutions.latitude,2)
    geoplot(navSolutions.latitude_kf(i),navSolutions.longitude_kf(i),'r*', 'MarkerSize', 10);hold on;
end
  geoplot(open_gt(1),open_gt(2),'o','MarkerFaceColor','y', 'MarkerSize', 10,'MarkerEdgeColor','y');hold on;

figure(502);
v=[];
for i=1:size(navSolutions.vX,2)
   v=[v;navSolutions.VX_kf(i),navSolutions.VY_kf(i),navSolutions.VZ_kf(i)] ;
end
v_Urban_kf = v;
save('v_Urban_kf.mat','v_Urban_kf');
plot(1:39,v(:,1),1:39,v(:,2));
title('Velocity Estimation Result (ECEF)');
legend('x (m/s)','y (m/s)')