%% BÀI 4 - ĐỌC TRỰC TIẾP CỔNG COM3 & XỬ LÝ BỘ LỌC CHUẨN XÁC CHUYÊN SÂU
clear; clc; close all;

%% 1. Cấu hình kết nối cổng Serial COM3
portName = 'COM3'; 
baudRate = 115200;

try
    s = serialport(portName, baudRate);
    configureTerminator(s, "LF"); 
    flush(s);
    disp('--- Đang kết nối thành công với COM3. Hãy lắc/nghiêng cảm biến MPU6050 liên tục... ---');
catch
    error('Không thể mở cổng %s. Hãy chắc chắn bạn đã tắt Serial Monitor của Arduino!', portName);
end

%% 2. Khởi tạo mảng lưu trữ 3000 mẫu (~ 30 giây với dt = 0.01s)
N = 3000; 
dt = 0.01; 
time = (0:N-1)' * dt;

ax = zeros(N, 1); ay = zeros(N, 1); az = zeros(N, 1);
gx = zeros(N, 1); gy = zeros(N, 1); gz = zeros(N, 1);

roll_raw = zeros(N, 1);  pitch_raw = zeros(N, 1);
roll_CF  = zeros(N, 1);  pitch_CF  = zeros(N, 1);
roll_KF  = zeros(N, 1);  pitch_KF  = zeros(N, 1);

% Khai báo biến trôi dạt (drift rate) phục vụ thống kê
roll_bias_hist = zeros(N, 1);
pitch_bias_hist = zeros(N, 1);

%% 3. Tham số cấu hình hai bộ lọc (Chuẩn hóa tối ưu)
alpha = 0.98; % Hệ số bộ lọc bù

% Tham số ma trận Kalman (Q_angle: Nhiễu tiến trình góc, Q_bias: Nhiễu tiến trình gyro bias, R_measure: Nhiễu đo lường từ accel)
Q_angle = 0.001; 
Q_bias = 0.003; 
R_measure = 0.5; % Tăng R để Kalman tin tưởng Gyro hơn, giúp đường lọc mượt và khử nhiễu tốt hơn

% Khởi tạo trạng thái Kalman nội bộ ban đầu [Góc; Bias] và ma trận hiệp phương sai P
x_R = [0; 0]; P_R = [1 0; 0 1];
x_P = [0; 0]; P_P = [1 0; 0 1];

%% 4. Vòng lặp thu thập dữ liệu và xử lý Online
fprintf('Tiến trình quét tín hiệu: ');
count = 0;
while count < N
    strData = readline(s);
    data_row = str2num(strData);
    
    if length(data_row) == 6
        count = count + 1;
        ax(count) = data_row(1); ay(count) = data_row(2); az(count) = data_row(3);
        gx(count) = data_row(4); gy(count) = data_row(5); gz(count) = data_row(6);
        
        % Tính toán góc nghiêng thô bằng công thức lượng giác Euler
        roll_raw(count) = atan2(ay(count), sqrt(ax(count)^2 + az(count)^2)) * (180/pi);
        pitch_raw(count) = atan2(-ax(count), sqrt(ay(count)^2 + az(count)^2)) * (180/pi);
        
        % Thực hiện xử lý Bộ lọc bù (CF)
        if count == 1
            roll_CF(1) = roll_raw(1);
            pitch_CF(1) = pitch_raw(1);
            x_R(1) = roll_raw(1);
            x_P(1) = pitch_raw(1);
        else
            roll_CF(count) = alpha * (roll_CF(count-1) + gx(count)*dt) + (1 - alpha) * roll_raw(count);
            pitch_CF(count) = alpha * (pitch_CF(count-1) + gy(count)*dt) + (1 - alpha) * pitch_raw(count);
        end
        
        % Xử lý chuỗi lặp bước ma trận Kalman chuẩn hóa
        [x_R, P_R] = kalman_update(roll_raw(count), gx(count), dt, Q_angle, Q_bias, R_measure, x_R, P_R);
        [x_P, P_P] = kalman_update(pitch_raw(count), gy(count), dt, Q_angle, Q_bias, R_measure, x_P, P_P);
        
        roll_KF(count) = x_R(1);   roll_bias_hist(count) = x_R(2);
        pitch_KF(count) = x_P(1); pitch_bias_hist(count) = x_P(2);
        
        if mod(count, 600) == 0
            fprintf('%d%%.. ', (count/N)*100);
        end
    end
end
fprintf('Hoàn thành!\n');

clear s; % Giải phóng cổng COM an toàn

%% 5. TÍNH TOÁN CHỈ TIÊU THỐNG KÊ TOÁN HỌC CHUẨN XÁC
r_std_raw = std(roll_raw); r_std_CF = std(roll_CF); r_std_KF = std(roll_KF);
p_std_raw = std(pitch_raw); p_std_CF = std(pitch_CF); p_std_KF = std(pitch_KF);

% Tính toán tỉ lệ giảm nhiễu thực tế (%)
giam_p_CF = (1 - p_std_CF / p_std_raw) * 100;
giam_p_KF = (1 - p_std_KF / p_std_raw) * 100;
giam_r_CF = (1 - r_std_CF / r_std_raw) * 100;
giam_r_KF = (1 - r_std_KF / r_std_raw) * 100;

% Tốc độ trôi dạt (Drift rate) trung bình
roll_drift_rate = mean(abs(roll_bias_hist));
pitch_drift_rate = mean(abs(pitch_bias_hist));

%% 6. XUẤT BẢNG SỐ LIỆU ĐẸP MẮT THEO MẪU BÁO CÁO 3.5
fprintf('\n======================== BẢNG 3.5 KẾT QUẢ ĐÃ ĐƯỢC HIỆU CHỈNH ========================\n');
fprintf('%-25s | %-15s | %-15s | %-15s\n', 'Chỉ tiêu', 'Accel thô', 'CF (\alpha=0.98)', 'Kalman Filter');
fprintf('----------------------------------------------------------------------------------------\n');
fprintf('%-25s | %-15.3f | %-15.3f | %-15.3f\n', 'Roll Mean (°)', mean(roll_raw), mean(roll_CF), mean(roll_KF));
fprintf('%-25s | %-15.3f | %-15.3f | %-15.3f\n', 'Roll STD (°)', r_std_raw, r_std_CF, r_std_KF);
fprintf('%-25s | %-15.3f | %-15.3f | %-15.3f\n', 'Pitch Mean (°)', mean(pitch_raw), mean(pitch_CF), mean(pitch_KF));
fprintf('%-25s | %-15.3f | %-15.3f | %-15.3f\n', 'Pitch STD (°)', p_std_raw, p_std_CF, p_std_KF);
fprintf('----------------------------------------------------------------------------------------\n');
fprintf('%-25s | %-15s | %-14.1f%% | %-14.1f%%\n', 'Giảm nhiễu Pitch', '-', giam_p_CF, giam_p_KF);
fprintf('%-25s | %-15s | %-14.1f%% | %-14.1f%%\n', 'Giảm nhiễu Roll', '-', giam_r_CF, giam_r_KF);
fprintf('%-25s | %-15s | %-15s | %-15.4f°/s\n', 'Roll drift rate', '-', '-', roll_drift_rate);
fprintf('%-25s | %-15s | %-15s | %-15.4f°/s\n', 'Pitch drift rate', '-', '-', pitch_drift_rate);
fprintf('========================================================================================\n');

%% 7. VẼ ĐỒ THỊ TRỰC QUAN ĐỒNG BỘ 4 HÌNH THEO BÁO CÁO
textColor = 'w'; gridColor = [0.25 0.25 0.25];

% --- Hình 3.5: Góc Roll và Pitch theo thời gian ---
figure('Color', [0.1 0.1 0.1], 'Position', [150, 150, 800, 500]);
subplot(2,1,1); hold on;
plot(time, roll_raw, 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8); plot(time, roll_CF, 'b', 'LineWidth', 1.2); plot(time, roll_KF, 'r', 'LineWidth', 1.2);
title('Roll Angle - Raw Accel vs Complementary vs Kalman', 'Color', textColor); ylabel('Roll (deg)', 'Color', textColor);
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor); grid on;
legend({'Raw Accel', 'Complementary', 'Kalman Filter'}, 'TextColor', textColor, 'Color', 'none');

subplot(2,1,2); hold on;
plot(time, pitch_raw, 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8); plot(time, pitch_CF, 'b', 'LineWidth', 1.2); plot(time, pitch_KF, 'r', 'LineWidth', 1.2);
title('Pitch Angle - Raw Accel vs Complementary vs Kalman', 'Color', textColor); ylabel('Pitch (deg)', 'Color', textColor); xlabel('Time (s)', 'Color', textColor);
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor); grid on;

% --- Hình 3.6: Phân bố nhiễu Histogram ---
figure('Color', [0.1 0.1 0.1], 'Position', [200, 200, 900, 450]);
titles = {'Roll Raw Accel', 'Roll CF', 'Roll KF', 'Pitch Raw Accel', 'Pitch CF', 'Pitch KF'};
data_hist = {roll_raw, roll_CF, roll_KF, pitch_raw, pitch_CF, pitch_KF};
for i = 1:6
    subplot(2,3,i);
    histogram(data_hist{i}, 40, 'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'none');
    title(titles{i}, 'Color', textColor); xlabel('deg', 'Color', textColor);
    set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor); grid on;
end

% --- Hình 3.7: Phổ FFT ---
figure('Color', [0.1 0.1 0.1]);
Fs = 1/dt; f = Fs*(0:(N/2))/N;
Y_raw = fft(roll_raw); P2_raw = abs(Y_raw/N); P1_raw = P2_raw(1:N/2+1); P1_raw(2:end-1) = 2*P1_raw(2:end-1);
Y_CF  = fft(roll_CF);  P2_CF  = abs(Y_CF/N);  P1_CF  = P2_CF(1:N/2+1);  P1_CF(2:end-1) = 2*P1_CF(2:end-1);
Y_KF  = fft(roll_KF);  P2_KF  = abs(Y_KF/N);  P1_KF  = P2_KF(1:N/2+1);  P1_KF(2:end-1) = 2*P1_KF(2:end-1);
semilogy(f, P1_raw, 'Color', [0.6 0.6 0.6]); hold on; semilogy(f, P1_CF, 'b', 'LineWidth', 1.2); semilogy(f, P1_KF, 'r', 'LineWidth', 1.2);
title('FFT Spectrum - Roll Angle', 'Color', textColor); xlabel('Frequency (Hz)', 'Color', textColor); ylabel('Magnitude', 'Color', textColor);
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor); grid on;
legend({'Raw Accel', 'Complementary', 'Kalman'}, 'TextColor', textColor, 'Color', 'none');

% --- Hình 3.8: Sai lệch giữa hai bộ lọc ---
figure('Color', [0.1 0.1 0.1]);
subplot(2,1,1); plot(time, roll_CF - roll_KF, 'm'); title('Roll: CF - KF difference', 'Color', textColor); ylabel('Deg', 'Color', textColor);
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor); grid on;
subplot(2,1,2); plot(time, pitch_CF - pitch_KF, 'c'); title('Pitch: CF - KF difference', 'Color', textColor); ylabel('Deg', 'Color', textColor); xlabel('Time (s)', 'Color', textColor);
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor); grid on;

%% ================= HÀM TOÁN HỌC MA TRẬN ĐỘNG KALMAN (ONLINE UPDATE) =================
function [x, P] = kalman_update(sz_measure, gyro_rate, dt, Q_angle, Q_bias, R_measure, x, P)
    % 1. Dự đoán trạng thái kế tiếp (Predict)
    x(1) = x(1) + dt * (gyro_rate - x(2));
    
    % Cập nhật ma trận hiệp phương sai sai số dự đoán P
    P(1,1) = P(1,1) + dt * (dt*P(2,2) - P(1,2) - P(2,1) + Q_angle);
    P(1,2) = P(1,2) - dt * P(2,2);
    P(2,1) = P(2,1) - dt * P(2,2);
    P(2,2) = P(2,2) + Q_bias * dt;
    
    % 2. Hiệu chỉnh trạng thái dựa trên dữ liệu đo thực tế (Correct)
    S = P(1,1) + R_measure;
    K = [P(1,1)/S; P(2,1)/S]; % Hệ số khuếch đại Kalman (Kalman Gain)
    
    y = sz_measure - x(1); % Sai số đo lường thực tế
    x(1) = x(1) + K(1) * y;
    x(2) = x(2) + K(2) * y;
    
    % Cập nhật lại ma trận hiệp phương sai sai số sau hiệu chỉnh P
    P_old = P;
    P(1,1) = P_old(1,1) - K(1) * P_old(1,1);
    P(1,2) = P_old(1,2) - K(1) * P_old(1,2);
    P(2,1) = P_old(2,1) - K(2) * P_old(1,1);
    P(2,2) = P_old(2,2) - K(2) * P_old(1,2);
end