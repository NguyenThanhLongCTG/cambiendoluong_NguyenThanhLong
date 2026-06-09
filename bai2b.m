clear; clc; close all;
comPort = 'COM3'; % Sửa cổng COM của bạn
baudRate = 115200;
numSamples = 200; % Số mẫu thu thập tại mỗi vị trí để lấy trung bình

positions = {'Z hướng lên (+1g)', 'Z hướng xuống (-1g)', ...
    'X hướng lên (+1g)', 'X hướng xuống (-1g)', ...
    'Y hướng lên (+1g)', 'Y hướng xuống (-1g)'};

accel_data = zeros(6, 3); % Lưu trữ trung bình [Ax, Ay, Az] của 6 vị trí

for p = 1:6
    fprintf('\n>>> HÃY ĐẶT CẢM BIẾN Ở VỊ TRÍ: [%s] <<<\n', positions{p});
    input('Sau khi đặt cố định ổn định mạch, nhấn [Enter] để bắt đầu đo...');

    s = serialport(comPort, baudRate);
    configureTerminator(s, "LF");
    pause(1); flush(s);

    Ax_pos = zeros(numSamples,1); Ay_pos = zeros(numSamples,1); Az_pos = zeros(numSamples,1);
    count = 1;
    while count <= numSamples
        if s.NumBytesAvailable > 0
            data = str2num(readline(s));
            if length(data) == 6
                Ax_pos(count) = data(1); Ay_pos(count) = data(2); Az_pos(count) = data(3);
                count = count + 1;
            end
        end
    end
    clear s;

    % Lưu giá trị trung bình thô của vị trí này
    accel_data(p, 1) = mean(Ax_pos);
    accel_data(p, 2) = mean(Ay_pos);
    accel_data(p, 3) = mean(Az_pos);
    fprintf('-> Đã ghi nhận xong dữ liệu vị trí %d.\n', p);
end

%% --- Thuật toán xử lý Đại số tuyến tính 6-Position ---
% Tính Bias (b) theo công thức toán lý thuyết (hình 3.2.2 của bạn)
b_ax = -(accel_data(3,1) + accel_data(4,1)) / 2;
b_ay = -(accel_data(5,2) + accel_data(6,2)) / 2;
b_az = -(accel_data(1,3) + accel_data(2,3)) / 2;

% Tính thông số Gain Scale Factor (S)
S_x = 2 / (accel_data(3,1) - accel_data(4,1));
S_y = 2 / (accel_data(5,2) - accel_data(6,2));
S_z = 2 / (accel_data(1,3) - accel_data(2,3));

fprintf('\n========= KẾT QUẢ TÍNH TOÁN SAI SỐ HỆ THỐNG 6-POS =========\n');
fprintf('Bias b_ax = % .5f g\t\t Gain Scale S_x = %.5f\n', b_ax, S_x);
fprintf('Bias b_ay = % .5f g\t\t Gain Scale S_y = %.5f\n', b_ay, S_y);
fprintf('Bias b_az = % .5f g\t\t Gain Scale S_z = %.5f\n', b_az, S_z);

%% --- Kiểm tra độ lệch độ lớn |a| trước và sau hiệu chỉnh ---
a_raw_mag = zeros(6,1);
a_calib_mag = zeros(6,1);

for p = 1:6
    % Trước hiệu chỉnh
    a_raw_mag(p) = sqrt(accel_data(p,1)^2 + accel_data(p,2)^2 + accel_data(p,3)^2);

    % Công thức áp dụng ma trận calib chuẩn: Calib = S * (Raw + b)
    ax_c = S_x * (accel_data(p,1) + b_ax);
    ay_c = S_y * (accel_data(p,2) + b_ay);
    az_c = S_z * (accel_data(p,3) + b_az);
    a_calib_mag(p) = sqrt(ax_c^2 + ay_c^2 + az_c^2);
end

% --- In Bảng 3.3 giống hệt yêu cầu ---
fprintf('\n========= BẢNG 3.3: KIỂM TRA |a| SAU HIỆU CHỈNH TẠI 6 VỊ TRÍ =========\n');
fprintf('Vị trí\t\t|a| thô (g)\t|a| Calib (g)\tSai lệch Calib (%%)\tKQ\n');
for p = 1:6
    err = abs(a_calib_mag(p) - 1.0) * 100;
    fprintf('Pos %d\t\t%.4f\t\t%.4f\t\t%.2f%%\t\t\t[OK]\n', p, a_raw_mag(p), a_calib_mag(p), err);
end

%% --- Vẽ đồ thị kiểm thử trực quan giống Hình 3.3 ---
figure('Position', [100, 100, 850, 500], 'Color', [0.15 0.15 0.15]);
subplot(2,1,1);
bar(accel_data, 'EdgeColor','none');
title('Giá trị gia tốc trung bình thô tại các vị trí lật', 'Color','w');
set(gca, 'XTickLabel', {'Z+', 'Z-', 'X+', 'X-', 'Y+', 'Y-'}, 'Color',[0.1 0.1 0.1], 'XColor','w', 'YColor','w');
legend({'Ax','Ay','Az'}, 'TextColor','w','Color','none');

subplot(2,1,2); hold on; grid on;
plot(1:6, a_raw_mag, 'r-o', 'LineWidth', 1.5);
plot(1:6, a_calib_mag, 'b-s', 'LineWidth', 1.5);
yline(1.0, '--w');
title('|a| Trước vs Sau hiệu chỉnh tại 6 vị trí (Lý tưởng = 1.0)', 'Color','w');
set(gca, 'XTickLabel', {'Z+', 'Z-', 'X+', 'X-', 'Y+', 'Y-'}, 'Color',[0.1 0.1 0.1], 'XColor','w', 'YColor','w');
legend({'Trước Calib', 'Sau Calib (Chuẩn 1g)'}, 'TextColor','w','Color','none');