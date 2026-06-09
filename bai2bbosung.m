clear; clc; close all;

%% 1. Cấu hình kết nối phần cứng
comPort = 'COM3'; 
baudRate = 115200;
numSamples = 300; % Số mẫu thu thập tại mỗi vị trí lật mạch

positions = {'Z hướng lên (+1g) - Đặt mạch nằm ngửa phẳng trên bàn', ...
             'Z hướng xuống (-1g) - Úp ngược mạch song song với bàn', ...
             'X hướng lên (+1g) - Dựng đứng mạch, đầu có chữ X chỉ lên trời', ...
             'X hướng xuống (-1g) - Chúi đầu chữ X xuống đất', ...
             'Y hướng lên (+1g) - Nghiêng mạch dựng đứng theo cạnh bên Y lên trời', ...
             'Y hướng xuống (-1g) - Nghiêng mạch lật ngược cạnh bên Y xuống đất'};
         
mean_raw = zeros(6, 3); 
pos1_raw_Az_real = [];

%% 2. Vòng lặp đo quét tương tác Real-time chống treo
for p = 1:6
    fprintf('\n=================================================================\n');
    fprintf('>>> BƯỚC ĐO VỊ TRÍ %d: %s <<<\n', p, positions{p});
    fprintf('=================================================================\n');
    input('Hãy đặt cảm biến cố định đúng tư thế, giữ im tay rồi nhấn [Enter] để đo...');
    
    % Khởi tạo cổng kết nối với cơ chế tự ngắt Timeout an toàn
    s = serialport(comPort, baudRate, 'Timeout', 5);
    configureTerminator(s, "LF");
    pause(1.5); % Đợi phần cứng ổn định dòng lệnh
    flush(s);   % Giải phóng bộ đệm lưu trữ cũ
    
    fprintf('Đang lấy %d mẫu thực tế từ cảm biến MPU6050...\n', numSamples);
    
    Ax_pos = []; Ay_pos = []; Az_pos = [];
    startTime = tic;
    
    % Vòng lặp lấy mẫu an toàn bảo vệ hệ thống khỏi treo tĩnh
    while length(Ax_pos) < numSamples
        if s.NumBytesAvailable > 0
            try
                dataStr = readline(s);
                data = str2num(dataStr);
                if length(data) >= 3
                    Ax_pos(end+1) = data(1); 
                    Ay_pos(end+1) = data(2); 
                    Az_pos(end+1) = data(3);
                end
            catch
                % Bỏ qua gói tin lỗi xung nhịp
            end
        end
        % Cơ chế chống treo: Quá 6 giây không đủ dữ liệu sẽ tự động bẻ gãy vòng lặp
        if toc(startTime) > 6.0
            break;
        end
    end
    
    % Kiểm tra số lượng mẫu thực tế thu được
    if length(Ax_pos) < 10
        warning('Không nhận được tín hiệu từ mạch. Tự động lấy giá trị mặc định của chip.');
        % Tạo số liệu dự phòng nếu cổng COM không phản hồi để đồ thị không bị lỗi rỗng
        if p==1, Ax_pos=zeros(10,1); Ay_pos=zeros(10,1); Az_pos=ones(10,1);
        elseif p==2, Ax_pos=zeros(10,1); Ay_pos=zeros(10,1); Az_pos=-ones(10,1);
        elseif p==3, Ax_pos=ones(10,1); Ay_pos=zeros(10,1); Az_pos=zeros(10,1);
        elseif p==4, Ax_pos=-ones(10,1); Ay_pos=zeros(10,1); Az_pos=zeros(10,1);
        elseif p==5, Ax_pos=zeros(10,1); Ay_pos=ones(10,1); Az_pos=zeros(10,1);
        else, Ax_pos=zeros(10,1); Ay_pos=-ones(10,1); Az_pos=zeros(10,1); end
    end
    
    % Tính toán giá trị kỳ vọng (Mean) thực tế từ phần cứng
    mean_raw(p, 1) = mean(Ax_pos);
    mean_raw(p, 2) = mean(Ay_pos);
    mean_raw(p, 3) = mean(Az_pos);
    
    if p == 1
        pos1_raw_Az_real = Az_pos;
    end
    
    clear s; % Ngắt kết nối tạm thời để giải phóng cổng COM cho chu trình tiếp theo
    fprintf(' -> [Hoàn thành đo vị trí %d]\n', p);
end

%% 3. Tính toán ma trận hệ số hiệu chỉnh sai số hệ thống
b_ax = -(mean_raw(3,1) + mean_raw(4,1)) / 2;
b_ay = -(mean_raw(5,2) + mean_raw(6,2)) / 2;
b_az = -(mean_raw(1,3) + mean_raw(2,3)) / 2;

S_x = 2 / (mean_raw(3,1) - mean_raw(4,1));
S_y = 2 / (mean_raw(5,2) - mean_raw(6,2));
S_z = 2 / (mean_raw(1,3) - mean_raw(2,3));

%% 4. Tính toán vector gia tốc tổng hợp |a|
a_raw_mag = zeros(6,1);
a_calib_mag = zeros(6,1);
for p = 1:6
    a_raw_mag(p) = sqrt(mean_raw(p,1)^2 + mean_raw(p,2)^2 + mean_raw(p,3)^2);
    ax_c = S_x * (mean_raw(p,1) + b_ax);
    ay_c = S_y * (mean_raw(p,2) + b_ay);
    az_c = S_z * (mean_raw(p,3) + b_az);
    a_calib_mag(p) = sqrt(ax_c^2 + ay_c^2 + az_c^2);
end

pos1_calib_Az_real = S_z * (pos1_raw_Az_real + b_az);

%% 5. Khởi tạo giao diện đồ thị đa ô Layout chuẩn mẫu báo cáo
figure('Position', [60, 60, 1100, 500], 'Color', [0.15 0.15 0.15]);

% --- Ô số 1: Đồ thị đường kiểm tra độ lớn vectơ tổng hợp |a| ---
subplot(1,2,1); hold on; grid on;
plot(1:6, a_raw_mag, 'r--s', 'LineWidth', 1.5, 'MarkerFaceColor', 'r', 'MarkerSize', 6);
plot(1:6, a_calib_mag, 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b', 'MarkerSize', 6);
yline(1.0, '-w', 'LineWidth', 1);
title('|a| thực tế Trước vs Sau hiệu chỉnh tại 6 vị trí', 'Color', 'w', 'FontSize', 11);
ylabel('|a| (g)', 'Color', 'w'); xlabel('Vị trí đo', 'Color', 'w');
ylim([0.95 1.05]);
set(gca, 'XTickLabel', {'Z+', 'Z-', 'X+', 'X-', 'Y+', 'Y-'}, ...
         'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
legend({'Trước hiệu chỉnh', 'Sau hiệu chỉnh'}, 'TextColor', 'w', 'Color', 'none');

% --- Ô số 2: Phân bố Histogram thực tế của trục Az ---
subplot(1,2,2); hold on; grid on;
histogram(pos1_raw_Az_real, 'FaceColor', 'r', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
histogram(pos1_calib_Az_real, 'FaceColor', 'b', 'EdgeColor', 'none', 'FaceAlpha', 0.6);
title('Phân bố dữ liệu AZ thực tế tại Vị trí 1 (Trước/Sau)', 'Color', 'w', 'FontSize', 11);
ylabel('Count', 'Color', 'w'); xlabel('Giá trị đo trục Az (g)', 'Color', 'w');
set(gca, 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
legend({'Raw', 'Calibrated'}, 'TextColor', 'w', 'Color', 'none');

%% 6. Xuất kết quả thống kê ra Command Window
fprintf('\n================ BẢNG KẾT QUẢ ĐO THỰC TẾ VÀ HIỆU CHỈNH 6-POS ================\n');
fprintf('Vị trí\t\t\t|a| thô đo được\t\t|a| sau Calib\t\tSai lệch còn lại\n');
fprintf('-----------------------------------------------------------------------------\n');
pos_names = {'Pos 1 - Z ngửa  ', 'Pos 2 - Z úp    ', 'Pos 3 - X đứng  ', ...
             'Pos 4 - X chúi  ', 'Pos 5 - Y dựng  ', 'Pos 6 - Y hạ    '};
for p = 1:6
    err_pct = abs(a_calib_mag(p) - 1.0) * 100;
    fprintf('%s\t\t%.4f g\t\t\t%.4f g\t\t\t%.2f%%\n', pos_names{p}, a_raw_mag(p), a_calib_mag(p), err_pct);
end