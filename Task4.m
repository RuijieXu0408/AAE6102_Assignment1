function Task4(trackResults, navSolutions)
%% for Weighted Least Square for positioning (elevation based)
% figure(401);
% open_gt=[22.328444770087565,114.1713630049711,3];
% geoscatter(open_gt(1),open_gt(2),"*");
% geobasemap satellite;
% 
% for i=1:size(navSolutions.latitude,2)
%     geoplot(navSolutions.latitude(i),navSolutions.longitude(i),'r*', 'MarkerSize', 10);hold on;
% end
%   geoplot(open_gt(1),open_gt(2),'o','MarkerFaceColor','y', 'MarkerSize', 10,'MarkerEdgeColor','y');hold on;

figure(402);
lla_gt = [22.328444770087565,114.1713630049711 0]; %% Opensky gt --RayJ
% lla_gt = [22.3198722,114.209101777778 0]; %% Urban gt --RayJ
lla = [navSolutions.latitude;navSolutions.longitude;zeros(1,length(navSolutions.longitude))]';
xyzENU = lla2enu(lla,lla_gt,'flat');
for i = 1:length(xyzENU(:,1))
    err(i) = sqrt(xyzENU(i,1)^2 + xyzENU(i,2)^2);
end

plot(1:39,err);
title('Positioning Result');
ylabel('Error (m)')


figure(403);
%% WLS for velocity

v=[];
for i=1:size(navSolutions.vX,2)
   v=[v;navSolutions.vX(i),navSolutions.vY(i),navSolutions.vZ(i)] ;
end
plot(1:39,v(:,1),1:39,v(:,2));
legend('x (ECEF)','y (ECEF)')