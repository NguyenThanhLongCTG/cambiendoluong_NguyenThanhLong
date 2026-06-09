clear; clc; close all;
comPort = 'COM3'; % Sửa lại cổng COM thực tế
baudRate = 115200;
numSamples = 500;

s = serialport(comPort, baudRate);
configureTerminator(s, "LF");
disp('Bài 2A: Đang thu thập 500 mẫu Gyroscope tĩnh...');
pause(2); flush(s);

Gx_raw = zeros(numSamples,1); Gy_raw = zeros(numSamples,1); Gz_raw = zeros(numSamples,1);
count = 1;
while count <= numSamples
    if s.NumBytesAvailable > 0
        data = str2num(readline(s));
        if length(data) == 6
            Gx_raw(count) = data(4); Gy_raw(count) = data(5); Gz_raw(count) = data(6);
            count = count + 1;
        end
    end
end
clear s;

% --- Thuật toán tính toán Offset ---
bias_Gx = mean(Gx_raw);
bias_Gy = mean(Gy_raw);
bias_Gz = mean(Gz_raw);

% Áp dụng bù sai số
Gx_calib = Gx_raw - bias_Gx;
Gy_calib = Gy_raw - bias_Gy;
Gz_calib = Gz_raw - bias_Gz;

% --- Hiển thị bảng số liệu ---
fprintf('\n========= BẢNG 3.2: OFFSET GYROSCOPE ĐO ĐƯỢC =========\n');
fprintf('Trục\tOffset (°/s)\tSTD (°/s)\tĐánh giá\n');
fprintf('Gx\t\t% .5f\t\t%.6f\tÁp dụng bù\n', bias_Gx, std(Gx_raw));
fprintf('Gy\t\t% .5f\t\t%.6f\tÁp dụng bù\n', bias_Gy, std(Gy_raw));
fprintf('Gz\t\t% .5f\t\t%.6f\tÁp dụng bù\n', bias_Gz, std(Gz_raw));

% --- Vẽ hình 3.2 đối chiếu Trước/Sau ---
figure('Position', [150, 150, 900, 450], 'Color', [0.15 0.15 0.15]);
t = (0:numSamples-1)/100;

subplot(1,2,1); hold on; grid on;
plot(t, Gx_raw, 'r'); plot(t, Gy_raw, 'g'); plot(t, Gz_raw, 'b');
title('Gyro TRƯỚC hiệu chỉnh', 'Color', 'w');
xlabel('Thời gian (s)'); ylabel('Vận tốc góc (°/s)');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');

subplot(1,2,2); hold on; grid on;
plot(t, Gx_calib, 'r'); plot(t, Gy_calib, 'g'); plot(t, Gz_calib, 'b');
yline(0, '--w');
title('Gyro SAU hiệu chỉnh', 'Color', 'w');
xlabel('Thời gian (s)'); ylabel('Vận tốc góc (°/s)');
legend({'Gx','Gy','Gz'}, 'TextColor', 'w', 'Color', 'none');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');