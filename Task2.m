function Task2(trackResults, navSolutions)
%% for multi-correaltor output

for i = 1:5
    data=trackResults(i).I_multi{200};
    if data(6)<0
        data=-data;
    end
    if i<=4
        subplot(3, 2, i);
        plot(-0.5:0.1:0.5,data,'b-');hold on;
        set(gca, 'FontSize', 12);
        scatter(-0.5:0.1:0.5,data,'r.');
        xlabel('code delay', 'FontSize',12);
        ylabel('ACF', 'FontSize',12);
        title(strcat('ACF of Multi-correlator PRN ', num2str(trackResults(i).PRN)), 'FontSize',12);
        grid on
    elseif i==5
        subplot(3, 2, i:i+1);
        plot(-0.5:0.1:0.5,data,'b-');hold on;
        set(gca, 'FontSize', 12);
        scatter(-0.5:0.1:0.5,data,'r.');
        xlabel('code delay', 'FontSize',12);
        ylabel('ACF', 'FontSize',12);
        title(strcat('ACF of Multi-correlator PRN ', num2str(trackResults(i).PRN)), 'FontSize',12);
        grid on
    end
end
