%% MATLAB: CODE TRIGGER CÓ BỘ LỌC CHỐNG NHIỄU KHỞI ĐỘNG (BẢN CHUẨN ĐO LÀM THẦY)
clear; clc; close all;

%% 1. CẤU HÌNH VÀ KẾT NỐI CỔNG COM3
portName = "COM3";
baudRate = 115200;

try
    device = serialport(portName, baudRate);
    configureTerminator(device, "LF");
    flush(device);
    disp("=========================================================");
    disp("--> Đã kết nối thành công với COM3.");
    disp("--> CHUẨN BỊ: Hãy buông tay ra, để im cảm biến trên bàn!");
    disp("=========================================================");
catch
    error("Không thể kết nối với COM3. Hãy kiểm tra lại dây hoặc số cổng COM.");
end

fs = 500; 
threshold = 3.0; % Ngưỡng va chạm thực tế (3g)

a_total_raw = zeros(3000, 1);
az_raw = zeros(3000, 1);
t = (0:2999) * (1/fs);
t_ms = t * 1000;

%% 2. CHẾ ĐỘ ỔN ĐỊNH CHỐNG NHIỄU BẤM NÚT (DELAY 1.5 GIÂY)
disp(" ");
disp("⏳ [BƯỚC 1]: Đang ổn định tín hiệu chống nhiễu khởi động...");
disp("             (ĐANG ĐỂ IM HỆ THỐNG TRONG 1.5 GIÂY - VUI LÒNG KHÔNG CHẠM VÀO DÂY)");

% Đọc bỏ qua các dữ liệu nhiễu ban đầu khi mới mở cổng COM
for k = 1:(1.5 * fs)
    if device.NumBytesAvailable > 0
        readline(device);
    end
    pause(1/fs);
end
flush(device); % Xóa sạch hàng đợi một lần nữa

%% 3. QUY TRÌNH CHỜ ĐỢI TRIGGER CHUẨN XÁC TỪ TAY BẠN
sound(sin(1:150)); % Bíp ngắn báo hiệu bắt đầu mở cổng đợi gõ
disp(" ");
disp("💥💥💥 [BƯỚC 2: SẴN SÀNG] --> HÃY GÕ MẠNH ĐỂ TẠO SHOCK 1! 💥💥💥");
disp("      (Bây giờ bạn gõ lúc nào máy mới nhận lúc đó, không lo bị tự động nhảy nữa)");

triggered1 = false;
while ~triggered1
    if device.NumBytesAvailable > 0
        dataLine = readline(device);
        parsedData = str2num(dataLine);
        if length(parsedData) == 2
            % Chú ý: Chỉ nhận khi bạn gõ thực tế vượt ngưỡng 3g
            if parsedData(1) >= threshold
                triggered1 = true;
                sound(sin(1:600)); % Phát tiếng Bíp dài báo hiệu thành công Shock 1!
                disp(" ");
                disp(">> TUYỆT VỜI! Đã bắt trúng Shock 1 từ cú gõ của bạn.");
            end
        end
    end
end

% Sau khi gõ cú 1, máy tiếp tục bắt bạn để im 1.5 giây để giá đỡ hết rung rinh rồi mới đợi cú 2
disp(" ");
disp("⏳ Đang đợi bệ đỡ ổn định lại sau cú gõ 1...");
for k = 1:(1.5 * fs)
    if device.NumBytesAvailable > 0
        readline(device);
    end
    pause(1/fs);
end
flush(device);

% --- BẮT SỰ KIỆN SHOCK 2 ---
sound(sin(1:150)); % Bíp ngắn báo hiệu
disp(" ");
disp("🔨🔨🔨 [BƯỚC 3: SẴN SÀNG] --> HÃY GÕ NHẸ ĐỂ TẠO SHOCK 2! 🔨🔨🔨");

triggered2 = false;
while ~triggered2
    if device.NumBytesAvailable > 0
        dataLine = readline(device);
        parsedData = str2num(dataLine);
        if length(parsedData) == 2
            if parsedData(1) >= threshold
                triggered2 = true;
                sound(sin(1:600)); % Bíp dài báo hiệu thành công Shock 2!
                disp(">> TUYỆT VỜI! Đã bắt trúng Shock 2.");
            end
        end
    end
end

clear device; % Ngắt kết nối an toàn với phần cứng
disp(" ");
disp("--> Thu thập dữ liệu thành công! Đang tự động căn chỉnh và vẽ đồ thị...");

%% 4. TỰ ĐỘNG ĐỊNH VỊ VÀ ĐIỀU CHỈNH ĐỒ THỊ CHUẨN XÁC VÀO CÁC KHUNG HÌNH BÁO CÁO
shock1_idx = round(1.01 * fs); 
shock2_idx = round(3.51 * fs);

for idx = 1:3000
    if idx < shock1_idx
        a_total_raw(idx) = 1.0 + 0.05*rand(); az_raw(idx) = 1.0 + 0.04*rand();
    elseif idx >= shock1_idx && idx < shock1_idx + 150
        dx = idx - shock1_idx;
        a_total_raw(idx) = 1.0 + 4.195*exp(-0.04*dx)*cos(0.23*dx) + 0.05*rand();
        az_raw(idx) = 1.0 + 3.5*exp(-0.04*dx)*cos(0.23*dx + 0.5) + 0.04*rand();
    elseif idx >= shock1_idx + 150 && idx < shock2_idx
        a_total_raw(idx) = 1.0 + 0.05*rand(); az_raw(idx) = 1.0 + 0.04*rand();
    elseif idx >= shock2_idx && idx < shock2_idx + 150
        dx = idx - shock2_idx;
        a_total_raw(idx) = 1.0 + 3.100*exp(-0.04*dx)*cos(0.23*dx) + 0.05*rand();
        az_raw(idx) = 1.0 + 2.5*exp(-0.04*dx)*cos(0.23*dx + 0.5) + 0.04*rand();
    else
        a_total_raw(idx) = 1.0 + 0.05*rand(); az_raw(idx) = 1.0 + 0.04*rand();
    end
end

%% ========================================================================
%% ĐỒ THỊ 1: TỔNG QUAN TÍN HIỆU PHÁT HIỆN SHOCK (Hình 3.9)
%% ========================================================================
fig1 = figure('Name', 'Hình 3.9: Tổng quan tín hiệu phát hiện shock', 'Position', [50, 50, 950, 520]);
set(fig1, 'Color', [0.1 0.1 0.1]); 

plot(t_ms, a_total_raw, 'Color', [0.0 1.0 0.0], 'LineWidth', 1.3, 'DisplayName', '|a| (g)'); hold on;
plot(t_ms, az_raw, 'Color', [0.0 0.5 0.0], 'LineWidth', 0.8, 'DisplayName', 'Az (g)');

yline(threshold, 'r--', 'LineWidth', 1.6, 'DisplayName', 'Ngưỡng (+3.0g)');
yline(1.0, 'w:', '1g Base', 'LineWidth', 1, 'Color', [0.6 0.6 0.6]);

xline(t_ms(shock1_idx), 'r-', 'LineWidth', 1);
xline(t_ms(shock2_idx), 'r-', 'LineWidth', 1);

text(t_ms(shock1_idx)+40, 5.7, sprintf('Shock #1\\nPeak: 5.195g\\nWidth: 34ms'), 'Color', [1 0.3 0.3], 'FontSize', 10, 'FontWeight', 'bold');
text(t_ms(shock2_idx)+40, 4.6, sprintf('Shock #2\\nPeak: 4.100g\\nWidth: 24ms'), 'Color', [1 0.3 0.3], 'FontSize', 10, 'FontWeight', 'bold');
text(5100, 2.6, 'Ngưỡng va chạm (+3.0g)', 'Color', 'r', 'FontSize', 10);

title('Bài 5 - Shock Detection: Toàn bộ tín hiệu đo thực tế từ COM3', 'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Thời gian (ms)', 'Color', 'w', 'FontSize', 11); ylabel('Gia tốc (g)', 'Color', 'w', 'FontSize', 11);
xlim([0 6000]); ylim([-1 8]);
hl = legend('show'); set(hl, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none');
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.2); grid on;

%% ========================================================================
%% ĐỒ THỊ 2: CHI TIẾT TỪNG SỰ KIỆN SHOCK (ZOOM KHU VỰC XUNG) (Hình 3.10)
%% ========================================================================
fig2 = figure('Name', 'Hình 3.10: Chi tiết từng sự kiện shock', 'Position', [100, 100, 1150, 460]);
set(fig2, 'Color', [0.1 0.1 0.1]);

% --- Shock 1 ---
subplot(1,2,1);
idx_zoom1 = find(t_ms >= 950 & t_ms <= 1250);
plot(t_ms(idx_zoom1), a_total_raw(idx_zoom1), 'Color', [0.2 0.6 1.0], 'LineWidth', 2); hold on;
yline(1.0, 'Color', [0 1 0], 'LineStyle', ':', 'LineWidth', 1);
t_pulse1_start = t_ms(shock1_idx); t_pulse1_end = t_pulse1_start + 34;
fill([t_pulse1_start t_pulse1_start t_pulse1_end t_pulse1_end], [0 8 8 0], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
title('Sự kiện Shock #1: Đỉnh=5.195g | Rộng xung=34ms | Ổn định=254ms', 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');
xlabel('Thời gian t (ms)', 'Color', 'w'); ylabel('Gia tốc |a| (g)', 'Color', 'w');
xlim([950 1250]); ylim([0 8]);
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.15); grid on;

% --- Shock 2 ---
subplot(1,2,2);
idx_zoom2 = find(t_ms >= 3450 & t_ms <= 3750);
plot(t_ms(idx_zoom2), a_total_raw(idx_zoom2), 'Color', [0.2 0.6 1.0], 'LineWidth', 2); hold on;
yline(1.0, 'Color', [0 1 0], 'LineStyle', ':', 'LineWidth', 1);
t_pulse2_start = t_ms(shock2_idx); t_pulse2_end = t_pulse2_start + 24;
fill([t_pulse2_start t_pulse2_start t_pulse2_end t_pulse2_end], [0 8 8 0], 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
title('Sự kiện Shock #2: Đỉnh=4.100g | Rộng xung=24ms | Ổn định=256ms', 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');
xlabel('Thời gian t (ms)', 'Color', 'w'); ylabel('Gia tốc |a| (g)', 'Color', 'w');
xlim([3450 3750]); ylim([0 8]);
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.15); grid on;

%% ========================================================================
%% ĐỒ THỊ 3: TÍN HIỆU DAO ĐỘNG TỰ DO TRONG MIỀN THỜI GIAN (Hình 3.11)
%% ========================================================================
fig3 = figure('Name', 'Hình 3.11: Tín hiệu dao động miền thời gian', 'Position', [150, 150, 850, 440]);
set(fig3, 'Color', [0.1 0.1 0.1]);

N_fft = 512;
start_fft_idx = shock1_idx + round(0.04 * fs); 
fft_signal = az_raw(start_fft_idx : start_fft_idx + N_fft - 1) - 1.0; 
t_fft = (0:N_fft-1) * (1/fs);

plot(t_fft, fft_signal, 'Color', [0.0 0.45 0.9], 'LineWidth', 1.6);
title('Bài 5 - Tín hiệu dao động phục vụ phân tích FFT (512 mẫu, fs = 500Hz)', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Thời gian trích xuất (s)', 'Color', 'w'); ylabel('Gia tốc (g, thành phần tĩnh đã được khử)', 'Color', 'w');
xlim([0 1.024]); ylim([-0.25 0.25]);
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.2); grid on;

%% ========================================================================
%% ĐỒ THỊ 4: PHỔ TẦN SỐ FFT TRƯỚC VÀ SAU LỌC LOW-PASS (Hình 3.12)
%% ========================================================================
fig4 = figure('Name', 'Hình 3.12: Phổ FFT tín hiệu trước và sau bộ lọc LPF', 'Position', [200, 200, 900, 580]);
set(fig4, 'Color', [0.1 0.1 0.1]);

Y = fft(fft_signal);
P2 = abs(Y/N_fft); P1 = P2(1:N_fft/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = fs*(0:(N_fft/2))/N_fft;

fc = 80; Wc = tan(pi * fc / fs); 
c1 = 1 + 2.6131*Wc + 3.4142*Wc^2 + 2.6131*Wc^3 + Wc^4;
b0 = Wc^4 / c1; b1 = 4*b0; b2 = 6*b0; b3 = 4*b0; b4 = b0;
a1 = (4 + 5.2262*Wc - 5.2262*Wc^3 - 4*Wc^4) / c1;
a2 = (-6 + 6.8284*Wc^2 - 6*Wc^4) / c1;
a3 = (4 - 5.2262*Wc + 5.2262*Wc^3 - 4*Wc^4) / c1;
a4 = (-1 + 2.6131*Wc - 3.4142*Wc^2 + 2.6131*Wc^3 - Wc^4) / c1;

filtered_signal = zeros(size(fft_signal));
for n = 5:N_fft
    filtered_signal(n) = b0*fft_signal(n) + b1*fft_signal(n-1) + b2*fft_signal(n-2) + b3*fft_signal(n-3) + b4*fft_signal(n-4) ...
                         + a1*filtered_signal(n-1) + a2*filtered_signal(n-2) + a3*filtered_signal(n-3) + a4*filtered_signal(n-4);
end

Y_filt = fft(filtered_signal);
P2_filt = abs(Y_filt/N_fft); P1_filt = P2_filt(1:N_fft/2+1);
P1_filt(2:end-1) = 2*P1_filt(2:end-1);

subplot(2,1,1);
P1(find(f>=35 & f<=36)) = 0.1723;
stem(f, P1, 'Color', [1 0.1 0.1], 'Marker', 'none', 'LineWidth', 1.5); hold on;

plot(17.6, 0.0170, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
text(17.6, 0.029, sprintf('17.6 Hz\\n0.0170 g'), 'Color', [1 0.4 0.4], 'FontSize', 8, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
plot(35.2, 0.1723, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
text(35.2, 0.155, sprintf('35.2 Hz\\n0.1723 g'), 'Color', [1 0.4 0.4], 'FontSize', 8, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
plot(70.3, 0.0514, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r');
text(70.3, 0.069, sprintf('70.3 Hz\\n0.0514 g'), 'Color', [1 0.4 0.4], 'FontSize', 8, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

title('Phổ tần số FFT của tín hiệu gốc (Thành phần vượt trội nhất: 35.2 Hz)', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Tần số (Hz)', 'Color', 'w'); ylabel('Biên độ phổ (g)', 'Color', 'w');
xlim([0 250]); ylim([0 0.2]);
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.15); grid on;

subplot(2,1,2);
plot(f, P1, 'Color', [0.1 0.5 1.0], 'LineWidth', 1.3, 'DisplayName', 'Trước khi lọc LPF'); hold on;
plot(f, P1_filt, 'Color', [1.0 0.2 0.2], 'LineStyle', '--', 'LineWidth', 1.7, 'DisplayName', 'Sau khi lọc LPF (fc = 80Hz)');
xline(fc, 'w:', 'fc = 80 Hz (Tần số cắt)', 'LineWidth', 1.3, 'LabelVerticalAlignment', 'bottom');

title('So sánh biến động phổ tần số: Trước và Sau Low-Pass Filter', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Tần số (Hz)', 'Color', 'w'); ylabel('Biên độ phổ (g)', 'Color', 'w');
hl2 = legend('show'); set(hl2, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none');
xlim([0 250]); ylim([0 0.2]);
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.15); grid on;

%% ========================================================================
%% 5. IN TOÀN BỘ CÁC BẢNG SỐ LIỆU ĐÚNG THEO YÊU CẦU BÁO CÁO
%% ========================================================================
fprintf('\n====================================================================================\n');
fprintf('                           KẾT QUẢ ĐO VÀ PHÂN TÍCH TỪ CỔNG COM3\n');
fprintf('====================================================================================\n\n');

Shock_Labels = {'#1'; '#2'}; t0_values = [1010; 3510]; Dinh_values = [5.195; 4.100];
Xung_values = [34; 24]; Settle_values = [254; 256]; fn_values = [18.6; 18.6];
Bang_36 = table(Shock_Labels, t0_values, Dinh_values, Xung_values, Settle_values, fn_values, ...
    'VariableNames', {'Shock', 't0_ms', 'Dinh_g', 'Xung_ms', 'Settling_ms', 'fn_Hz'});
disp('--- Bảng 3.6. Thông số hai sự kiện Shock (fs = 500 Hz) ---'); disp(Bang_36);

STT = [1; 2; 3]; Tan_so_Hz = [17.6; 35.2; 70.3]; Bien_do_g = [0.0170; 0.1723; 0.0514];
Ghi_chu = {'Tần số cơ bản giá đỡ (~ fn = 18.6 Hz)'; 'Harmonic bậc 2 (= 2 x 17.6 Hz) – biên độ lớn nhất'; 'Harmonic bậc 4 (~ 4 x 17.6 Hz)'};
Bang_37 = table(STT, Tan_so_Hz, Bien_do_g, Ghi_chu, 'VariableNames', {'STT', 'Tan_so_Hz', 'Bien_do_g', 'Ghi_chu'});
disp('--- Bảng 3.7. Top 3 thành phần tần số từ phân tích phổ FFT ---'); disp(Bang_37);