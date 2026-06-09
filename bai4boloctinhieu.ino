#include <Wire.h>

const int MPU_addr = 0x68;
int16_t AcX, AcY, AcZ, GyX, GyY, GyZ;

// Biến kiểm soát thời gian lấy mẫu chính xác (10ms = 100Hz)
unsigned long previousTime = 0;
const unsigned long samplePeriod = 10000; // micro-seconds

void setup() {
  Wire.begin();
  Wire.setClock(400000); // Tăng tốc độ giao tiếp I2C lên 400kHz
  
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B); // Thanh ghi Power Management 1
  Wire.write(0);    // Kích hoạt MPU6050
  Wire.endTransmission(true);

  Serial.begin(115200);
  previousTime = micros();
}

void loop() {
  // Đảm bảo chu kỳ lấy mẫu chuẩn xác
  while (micros() - previousTime < samplePeriod);
  previousTime = micros();

  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B); // Bắt đầu đọc từ thanh ghi dữ liệu gia tốc X
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr, 14, true); // Đọc liền 14 thanh ghi (Accel, Temp, Gyro)

  AcX = Wire.read() << 8 | Wire.read();
  AcY = Wire.read() << 8 | Wire.read();
  AcZ = Wire.read() << 8 | Wire.read();
  Wire.read(); Wire.read(); // Bỏ qua 2 thanh ghi nhiệt độ
  GyX = Wire.read() << 8 | Wire.read();
  GyY = Wire.read() << 8 | Wire.read();
  GyZ = Wire.read() << 8 | Wire.read();

  // Quy đổi dữ liệu thô sang đơn vị vật lý chuẩn (g và deg/s)
  // Dải đo mặc định: Accel là +/- 2g (16384 LSB/g), Gyro là +/- 250 deg/s (131 LSB/deg/s)
  float ax = (float)AcX / 16384.0;
  float ay = (float)AcY / 16384.0;
  float az = (float)AcZ / 16384.0;
  float gx = (float)GyX / 131.0;
  float gy = (float)GyY / 131.0;
  float gz = (float)GyZ / 131.0;

  // Gửi gói dữ liệu lên MATLAB định dạng phân tách bằng dấu phẩy
  Serial.print(ax, 4); Serial.print(",");
  Serial.print(ay, 4); Serial.print(",");
  Serial.print(az, 4); Serial.print(",");
  Serial.print(gx, 4); Serial.print(",");
  Serial.print(gy, 4); Serial.print(",");
  Serial.println(gz, 4);
}