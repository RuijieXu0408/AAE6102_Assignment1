%% ACF by RayJ
% 这是一个处理和绘制ACF的示例函数
function plotACF(trackResults, PRN, epochs)
    % 获取特定PRN的跟踪结果
    channelIndex = find([trackResults.PRN] == PRN);
    
    if isempty(channelIndex)
        error('PRN not found in tracking results');
    end
    
    % 选择要绘制的时间点
    selectedEpochs = round(linspace(1, length(trackResults(channelIndex).I_multi), epochs));
    
    % 定义相关器偏移量（以码片为单位）
    correlatorOffsets = [-0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5];
    
    figure;
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
    title(['ACF for PRN ' num2str(PRN)]);
    legend('Location', 'best');
    grid on;
    hold off;
end