clear; clc; close all;

%% 1. Cấu hình kết nối Serial
comPort = 'COM3'; % Thay đổi cổng COM cho đúng với máy của bạn
baudRate = 115200;
numSamples = 500;
fs = 100; % Tần số 100 Hz
t = (0:numSamples-1) / fs; % Trục thời gian (5 giây)

% Khởi tạo mảng chứa dữ liệu
Ax = zeros(numSamples, 1); Ay = zeros(numSamples, 1); Az = zeros(numSamples, 1);
Gx = zeros(numSamples, 1); Gy = zeros(numSamples, 1); Gz = zeros(numSamples, 1);

% Mở cổng Serial (Dành cho phiên bản MATLAB mới R2020a trở về sau)
s = serialport(comPort, baudRate);
configureTerminator(s, "LF");

disp('Đang khởi động và xóa bộ đệm cảm biến... Giữ cảm biến cố định!');
pause(2);
flush(s);
disp('Bắt đầu thu thập 500 mẫu...');

%% 2. Thu thập dữ liệu
count = 1;
while count <= numSamples
    if s.NumBytesAvailable > 0
        dataStr = readline(s);
        try
            data = str2num(dataStr);
            if length(data) == 6
                Ax(count) = data(1);
                Ay(count) = data(2);
                Az(count) = data(3);
                Gx(count) = data(4);
                Gy(count) = data(5);
                Gz(count) = data(6);
                count = count + 1;
            end
        catch
            % Bỏ qua các dòng lỗi định dạng do truyền nhận ban đầu
        end
    end
end
clear s; % Đóng cổng kết nối sau khi nhận đủ mẫu
disp('Thu thập dữ liệu hoàn thành.');

%% 3. Tính toán thống kê
a_total = sqrt(Ax.^2 + Ay.^2 + Az.^2); % Gia tốc tổng hợp |a|

% Tính Mean
mean_Ax = mean(Ax); mean_Ay = mean(Ay); mean_Az = mean(Az);
mean_Gx = mean(Gx); mean_Gy = mean(Gy); mean_Gz = mean(Gz);
mean_a  = mean(a_total);

% Tính STD (Độ lệch chuẩn)
std_Ax = std(Ax); std_Ay = std(Ay); std_Az = std(Az);
std_Gx = std(Gx); std_Gy = std(Gy); std_Gz = std(Gz);
std_a  = std(a_total);

%% 4. Hiển thị Bảng kết quả ra Command Window
fprintf('\n================ BẢNG THỐNG KÊ ĐẶC TÍNH TĨNH MPU6050 ================\n');
fprintf('Kênh\tĐV\tLý tưởng\tMean đo\t\tSTD (Noise)\n');
fprintf('Ax\tg\t0.000\t\t% .5f\t\t%.6f\n', mean_Ax, std_Ax);
fprintf('Ay\tg\t0.000\t\t% .5f\t\t%.6f\n', mean_Ay, std_Ay);
fprintf('Az\tg\t1.000\t\t% .5f\t\t%.6f\n', mean_Az, std_Az);
fprintf('Gx\t°/s\t0.000\t\t% .5f\t\t%.6f\n', mean_Gx, std_Gx);
fprintf('Gy\t°/s\t0.000\t\t% .5f\t\t%.6f\n', mean_Gy, std_Gy);
fprintf('Gz\t°/s\t0.000\t\t% .5f\t\t%.6f\n', mean_Gz, std_Gz);
fprintf('|a|\tg\t1.000\t\t% .5f\t\t%.6f (Lệch %.2f%%)\n', mean_a, std_a, abs(mean_a-1)*100);

%% 5. Vẽ đồ thị (Layout 3x2 giống ảnh mẫu)
figure('Position', [100, 50, 1000, 750], 'Color', [0.15 0.15 0.15]); % Nền tối ntn trong hình vẽ mẫu

% --- Đồ thị 1: Gia tốc theo thời gian ---
subplot(3,2,1); hold on; grid on;
plot(t, Ax, 'r', 'LineWidth', 1); plot(t, Ay, 'g', 'LineWidth', 1); plot(t, Az, 'b', 'LineWidth', 1);
yline(mean_Ax, '--r'); yline(mean_Ay, '--g'); yline(mean_Az, '--b'); yline(1, ':w');
title('Gia tốc thô theo thời gian', 'Color', 'w');
xlabel('Thời gian (s)', 'Color', 'w'); ylabel('Gia tốc (g)', 'Color', 'w');
legend({'Ax', 'Ay', 'Az', 'Mean Ax', 'Mean Ay', 'Mean Az', 'Az=1g lý tưởng'}, 'TextColor', 'w', 'Color', 'none');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');

% --- Đồ thị 2: Phân bố gia tốc (Histogram) ---
subplot(3,2,2); hold on; grid on;
histogram(Ax, 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
histogram(Ay, 'FaceColor', 'g', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
histogram(Az, 'FaceColor', 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
title('Phân bố gia tốc (Histogram)', 'Color', 'w');
xlabel('Gia tốc (g)', 'Color', 'w'); ylabel('Số mẫu', 'Color', 'w');
legend({'Ax', 'Ay', 'Az'}, 'TextColor', 'w', 'Color', 'none');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');

% --- Đồ thị 3: Gyroscope theo thời gian ---
subplot(3,2,3); hold on; grid on;
plot(t, Gx, 'r', 'LineWidth', 1); plot(t, Gy, 'g', 'LineWidth', 1); plot(t, Gz, 'b', 'LineWidth', 1);
yline(mean_Gx, '--r'); yline(mean_Gy, '--g'); yline(mean_Gz, '--b'); yline(0, ':w');
title('Gyroscope thô theo thời gian', 'Color', 'w');
xlabel('Thời gian (s)', 'Color', 'w'); ylabel('Vận tốc góc (deg/s)', 'Color', 'w');
legend({'Gx', 'Gy', 'Gz', 'Mean Gx', 'Mean Gy', 'Mean Gz', '0 deg/s'}, 'TextColor', 'w', 'Color', 'none');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');

% --- Đồ thị 4: Phân bố Gyroscope (Histogram) ---
subplot(3,2,4); hold on; grid on;
histogram(Gx, 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
histogram(Gy, 'FaceColor', 'g', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
histogram(Gz, 'FaceColor', 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
title('Phân bố gyroscope (Histogram)', 'Color', 'w');
xlabel('Vận tốc góc (deg/s)', 'Color', 'w'); ylabel('Số mẫu', 'Color', 'w');
legend({'Gx', 'Gy', 'Gz'}, 'TextColor', 'w', 'Color', 'none');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');

% --- Đồ thị 5: Gia tốc tổng hợp |a| ---
subplot(3,2,5); hold on; grid on;
plot(t, a_total, 'w', 'LineWidth', 1);
yline(1, '-r', 'LineWidth', 1.5);
yline(1.03, ':y'); yline(0.97, ':y');
title(sprintf('Gia tốc tổng hợp |a| = %.4fg (lý tưởng: 1.000)', mean_a), 'Color', 'w');
xlabel('Thời gian (s)', 'Color', 'w'); ylabel('|a| (g)', 'Color', 'w');
legend({'|a|', '1g', '+3%', '-3%'}, 'TextColor', 'w', 'Color', 'none');
ylim([0.96 1.04]);
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');

% --- Ô số 6: Chèn bảng text tổng kết trực tiếp lên hình ---
subplot(3,2,6); axis off;
tblText = {
    'BẢNG TỔNG KẾT ĐẶC TÍNH TĨNH'
    ''
    sprintf('Thông số\t\t\tMean\t\t\tSTD (noise)')
    sprintf('Ax (g)\t\t\t\t% .5f\t\t%.6f', mean_Ax, std_Ax)
    sprintf('Ay (g)\t\t\t\t% .5f\t\t%.6f', mean_Ay, std_Ay)
    sprintf('Az (g)\t\t\t\t% .5f\t\t%.6f', mean_Az, std_Az)
    sprintf('Gx (d/s)\t\t\t% .5f\t\t%.6f', mean_Gx, std_Gx)
    sprintf('Gy (d/s)\t\t\t% .5f\t\t%.6f', mean_Gy, std_Gy)
    sprintf('Gz (d/s)\t\t\t% .5f\t\t%.6f', mean_Gz, std_Gz)
    sprintf('|a| (g)\t\t\t\t% .5f\t\t%.2f%%', mean_a, std_a*100)
};
text(0.1, 0.5, tblText, 'Color', 'w', 'FontName', 'Courier', 'FontSize', 11);
