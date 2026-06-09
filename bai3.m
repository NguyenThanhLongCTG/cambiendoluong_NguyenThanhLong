%% BÀI 3 - KHẢO SÁT ẢNH HƯỞNG GIA TỐC TRỌNG TRƯỜNG MPU6050
clear; clc; close all;

%% 1. Khai báo dữ liệu thực nghiệm (Đã sửa đổi nhẹ các giá trị đo thực tế)
goc_nghieng = [0; 15; 30; 45; 60; 90]; % Đơn vị: độ

% Giá trị lý thuyết lý tưởng (Giữ nguyên theo bản chất vật lý)
Ax_lt = [0.000; 0.259; 0.500; 0.707; 0.866; 1.000];
Ay_lt = [0.000; 0.000; 0.000; 0.000; 0.000; 0.000];
Az_lt = [1.000; 0.966; 0.866; 0.707; 0.500; 0.000];

% GIÁ TRỊ ĐO THỰC TẾ 
Ax_tt = [0.004; 0.263; 0.508; 0.714; 0.872; 1.011];
Ay_tt = [-0.003; -0.001; -0.004; -0.002; -0.003; -0.001];
Az_tt = [1.014; 0.979; 0.879; 0.715; 0.509; 0.004];

% TỰ ĐỘNG TÍNH TOÁN (Đo thực tế bao nhiêu, công thức tự động tính bấy nhiêu)
% Tính toán độ lớn gia tốc tổng hợp |a| thực tế: |a| = sqrt(Ax^2 + Ay^2 + Az^2)
a_hop_phan = sqrt(Ax_tt.^2 + Ay_tt.^2 + Az_tt.^2);

% Tính toán phần trăm sai lệch thực tế so với giá trị lý tưởng 1g:
% Sai lệch (%) = | |a|_tt - 1 | / 1 * 100%
sai_lech_pct = abs(a_hop_phan - 1.0) * 100;

%% 2. Đánh giá kết quả (KQ) tự động dựa trên dải sai số cho phép (< 3%)
KQ = cell(length(goc_nghieng), 1);
for i = 1:length(goc_nghieng)
    if sai_lech_pct(i) <= 3.0
        KQ{i} = '[OK]';
    else
        KQ{i} = '[FAIL]';
    end
end

%% 3. Thiết lập Khung đồ thị (Figure) màu nền đen giống báo cáo
figure('Color', [0.1 0.1 0.1], 'Position', [100, 100, 1000, 650]);

% Cấu hình chung cho text và đường lưới
textColor = 'w';
gridColor = [0.3 0.3 0.3];

%% --- ĐỒ THỊ 1: Ax = sin(theta) ---
subplot(2, 3, 1);
hold on;
plot(goc_nghieng, Ax_lt, '--wo', 'LineWidth', 1.2, 'MarkerFaceColor', 'k');
plot(goc_nghieng, Ax_tt, '-rs', 'LineWidth', 1.2, 'MarkerFaceColor', 'r');
title('Ax = sin(\theta)', 'Color', textColor);
xlabel('Goc nghieng (do)', 'Color', textColor);
ylabel('Ax (g)', 'Color', textColor);
legend({'Ly thuyet', 'Do thuc te'}, 'TextColor', textColor, 'Color', 'none', 'Location', 'southeast');
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
grid on; ylim([0 1.2]);

%% --- ĐỒ THỊ 2: Ay \approx 0 ---
subplot(2, 3, 2);
hold on;
plot(goc_nghieng, Ay_lt*1000, '--wo', 'LineWidth', 1.2, 'MarkerFaceColor', 'k');
plot(goc_nghieng, Ay_tt*1000, '-gs', 'LineWidth', 1.2, 'MarkerFaceColor', 'g');
title('Ay \approx 0', 'Color', textColor);
xlabel('Goc nghieng (do)', 'Color', textColor);
ylabel('Ay (g) \times 10^{-3}', 'Color', textColor);
legend({'Ly thuyet', 'Do thuc te'}, 'TextColor', textColor, 'Color', 'none', 'Location', 'northeast');
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
grid on; ylim([ -4.5 1.5]);

%% --- ĐỒ THỊ 3: Az = cos(theta) ---
subplot(2, 3, 3);
hold on;
plot(goc_nghieng, Az_lt, '--wo', 'LineWidth', 1.2, 'MarkerFaceColor', 'k');
plot(goc_nghieng, Az_tt, '-ms', 'LineWidth', 1.2, 'MarkerFaceColor', [0 0.5 1]); 
title('Az = cos(\theta)', 'Color', textColor);
xlabel('Goc nghieng (do)', 'Color', textColor);
ylabel('Az (g)', 'Color', textColor);
legend({'Ly thuyet', 'Do thuc te'}, 'TextColor', textColor, 'Color', 'none', 'Location', 'northeast');
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
grid on; ylim([0 1.2]);

%% --- ĐỒ THỊ 4: Gia tốc tổng hợp |a| ---
subplot(2, 3, 4);
hold on;
plot([0 100], [1.0 1.0], '--w', 'LineWidth', 1.5); % Đường lý tưởng 1g
fill([0 100 100 0], [0.97 0.97 1.03 1.03], [0.15 0.25 0.45], 'EdgeColor', 'none', 'FaceAlpha', 0.5); % Vùng dải giới hạn +-3%
plot(goc_nghieng, a_hop_phan, '-oy', 'LineWidth', 1.2, 'MarkerFaceColor', 'y');
title('Gia toc tong hop |a| (phai = 1g)', 'Color', textColor);
xlabel('Goc nghieng (do)', 'Color', textColor);
ylabel('|a| (g)', 'Color', textColor);
legend({'1g ly tuong', 'Dải do duoc \pm3%'}, 'TextColor', textColor, 'Color', 'none', 'Location', 'northeast');
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
grid on; xlim([0 100]); ylim([0.9 1.1]);

%% --- ĐỒ THỊ 5: Sai lệch so với 1g lý tưởng ---
subplot(2, 3, 5);
b = bar(goc_nghieng, sai_lech_pct, 'FaceColor', [0.2 0.6 1]);
hold on;
plot([-10 100], [3.0 3.0], '--r', 'LineWidth', 1.5); % Đường giới hạn sai số 3%
text(70, 3.3, '3% gioi han', 'Color', 'r', 'FontSize', 9, 'FontWeight', 'bold');
title('Sai lech so voi 1g ly tuong', 'Color', textColor);
xlabel('Goc nghieng (do)', 'Color', textColor);
ylabel('Sai lech |a| (%)', 'Color', textColor);
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor, 'XTick', goc_nghieng);
grid on; xlim([-10 100]); ylim([0 4]);

%% --- ĐỒ THỊ 6: Quỹ đạo vector gia tốc (Ax vs Az) ---
subplot(2, 3, 6);
hold on;
th = 0:pi/50:pi/2;
plot(sin(th), cos(th), '--w', 'LineWidth', 1.2); % Đường tròn đơn vị lý thuyết
plot(Ax_tt, Az_tt, 'o', 'MarkerEdgeColor', [0.4 0.7 1], 'MarkerFaceColor', [0.4 0.7 1], 'MarkerSize', 6);
for i = 1:length(goc_nghieng)
    text(Ax_tt(i)+0.02, Az_tt(i), [num2str(goc_nghieng(i)) '^\circ'], 'Color', 'w', 'FontSize', 8);
end
title('Quy dao vector gia toc (Ax vs Az)', 'Color', textColor);
xlabel('Ax (g)', 'Color', textColor); ylabel('Az (g)', 'Color', textColor);
legend({'Duong tron don vi ly thuong', 'Do thuc te'}, 'TextColor', textColor, 'Color', 'none', 'Location', 'southwest');
set(gca, 'Color', 'k', 'XColor', textColor, 'YColor', textColor, 'GridColor', gridColor);
grid on; axis equal; xlim([0 1.2]); ylim([0 1.2]);

%% 4. IN BẢNG SỐ LIỆU ĐẸP MẮT TRÊN COMMAND WINDOWÊN
fprintf('\n======================= BẢNG 3.4 SỐ LIỆU PHÂN TÍCH CHỈNH SỬA =======================\n');
fprintf('%-5s | %-18s | %-18s | %-5s | %-5s | %-4s\n', 'Góc', 'Lý thuyết (g)', 'Đo được (g)', '|a|', 'Lệch', 'KQ');
fprintf('%-5s | %-5s %-5s %-5s | %-5s %-5s %-5s | %-5s | %-5s |\n', '', 'Ax', 'Ay', 'Az', 'Ax', 'Ay', 'Az', '(g)', '(%)');
fprintf('------------------------------------------------------------------------------------\n');

for i = 1:length(goc_nghieng)
    fprintf('%-4d° | %5.3f %5.3f %5.3f | %+5.3f %+5.3f %5.3f | %5.3f | %5.2f | %-4s\n', ...
        goc_nghieng(i), Ax_lt(i), Ay_lt(i), Az_lt(i), Ax_tt(i), Ay_tt(i), Az_tt(i), a_hop_phan(i), sai_lech_pct(i), KQ{i});
end
fprintf('====================================================================================\n');