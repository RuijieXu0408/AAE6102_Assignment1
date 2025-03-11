%% ACF BY RayJ
% 多卫星ACF对比绘图
function plotMultipleSatelliteACF(trackResults, PRNs, epochs)
    numPRNs = length(PRNs);
    figure('Position', [100, 100, 1200, 800]);
    
    for i = 1:numPRNs
        subplot(2, 2, i);
        plotSingleSatelliteACF(trackResults, PRNs(i), epochs);
        title(['PRN ' num2str(PRNs(i))]);
    end
    
    sgtitle('Auto-correlation Functions at Different Epochs');
end

function plotSingleSatelliteACF(trackResults, PRN, epochs)
    % 获取特定PRN的跟踪结果
    channelIndex = find([trackResults.PRN] == PRN);
    
    if isempty(channelIndex)
        text(0.5, 0.5, ['PRN ' num2str(PRN) ' not found'], 'HorizontalAlignment', 'center');
        return;
    end
    
    % 选择要绘制的时间点
    if length(trackResults(channelIndex).I_multi) < epochs
        selectedEpochs = 1:length(trackResults(channelIndex).I_multi);
    else
        selectedEpochs = round(linspace(1, length(trackResults(channelIndex).I_multi), epochs));
    end
    
    % 定义相关器偏移量（以码片为单位）
    correlatorOffsets = [-0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5];
    
    hold on;
    
    % 为每个选定的时间点绘制ACF
    for i = 1:length(selectedEpochs)
        epoch = selectedEpochs(i);
        
        % 获取I和Q值
        I_values = trackResults(channelIndex).I_multi{epoch};
        Q_values = trackResults(channelIndex).Q_multi{epoch};
        
        % 计算相关峰值的幅度
        magnitudes = sqrt(I_values.^2 + Q_values.^2);
        
        % 归一化相对于提示相关器（通常是第6个值）
        normalizedMagnitudes = magnitudes / magnitudes(6);
        
        % 绘制
        plot(correlatorOffsets, normalizedMagnitudes, '--o', 'DisplayName', ['Epoch ' num2str(epoch)]);
    end
    
    xlabel('Code Offset (chips)');
    ylabel('Normalized Correlation');
    grid on;
    legend('Location', 'best');
    hold off;
end