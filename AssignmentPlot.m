function AssignmentPlot(trackResults, navSolutions)
%% for multi-correaltor output

% for i = 1:5
%     data=trackResults(i).I_multi{200};
%     if data(6)<0
%         data=-data;
%     end
%     if i<=4
%         subplot(3, 2, i);
%         plot(-0.5:0.1:0.5,data,'b-');hold on;
%         set(gca, 'FontSize', 12);
%         scatter(-0.5:0.1:0.5,data,'r.');
%         xlabel('code delay', 'FontSize',12);
%         ylabel('ACF', 'FontSize',12);
%         title(strcat('ACF of Multi-correlator PRN ', num2str(trackResults(i).PRN)), 'FontSize',12);
%         grid on
%     elseif i==5
%         subplot(3, 2, i:i+1);
%         plot(-0.5:0.1:0.5,data,'b-');hold on;
%         set(gca, 'FontSize', 12);
%         scatter(-0.5:0.1:0.5,data,'r.');
%         xlabel('code delay', 'FontSize',12);
%         ylabel('ACF', 'FontSize',12);
%         title(strcat('ACF of Multi-correlator PRN ', num2str(trackResults(i).PRN)), 'FontSize',12);
%         grid on
%     end
% end

    


%% for Weighted Least Square for positioning (elevation based)
open_gt=[22.328444770087565,114.1713630049711,3];
geoscatter(open_gt(1),open_gt(2),"*");
geobasemap satellite;
error=[];
for i=1:size(navSolutions.latitude,2)
    geoplot(navSolutions.latitude(i),navSolutions.longitude(i),'r*', 'MarkerSize', 10);hold on;
end
  geoplot(open_gt(1),open_gt(2),'o','MarkerFaceColor','y', 'MarkerSize', 10,'MarkerEdgeColor','y');hold on;

figure;

%% WLS for velocity

v=[];
for i=1:size(navSolutions.vX,2)
   v=[v;navSolutions.vX(i),navSolutions.vY(i),navSolutions.vZ(i)] ;
end
plot(1:39,v(:,1),1:39,v(:,2));
legend('x (ECEF)','y (ECEF)')


%% for Kalman Filter
city_gt=[22.3198722, 114.209101777778,3];
geobasemap satellite;
error=[];
for i=1:size(navSolutions.latitude,2)
    geoplot(navSolutions.latitude_kf(i),navSolutions.longitude_kf(i),'r*', 'MarkerSize', 10);hold on;
end
  geoplot(city_gt(1),city_gt(2),'o','MarkerFaceColor','y', 'MarkerSize', 10,'MarkerEdgeColor','y');hold on;


v=[];
for i=1:size(navSolutions.vX,2)
   v=[v;navSolutions.VX_kf(i),navSolutions.VY_kf(i),navSolutions.VZ_kf(i)] ;
end
plot(1:39,v(:,1),1:39,v(:,2));
legend('x (ECEF)','y (ECEF)')