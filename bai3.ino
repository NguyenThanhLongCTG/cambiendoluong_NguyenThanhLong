#include <Wire.h>

const int MPU_addr = 0x68; 
int16_t AcX, AcY, AcZ;

unsigned long lastTime = 0;
const unsigned long interval = 2000; // 2000 microseconds = 2ms (fs = 500Hz)

void setup() {
  Wire.begin();
  
  // Đánh thức MPU6050
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B); 
  Wire.write(0);    
  Wire.endTransmission(true);

  // Cấu hình dải đo gia tốc +/- 8g (Thanh ghi 0x1C)
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x1C);
  Wire.write(0x10); 
  Wire.endTransmission(true);

  // Mở cổng Serial tốc độ cao
  Serial.begin(115200);
}

void loop() {
  unsigned long currentTime = micros();
  
  // Đảm bảo lấy mẫu chuẩn xác mỗi 2ms (500Hz)
  if (currentTime - lastTime >= interval) {
    lastTime = currentTime;

    Wire.beginTransmission(MPU_addr);
    Wire.write(0x3B);
    Wire.endTransmission(false);
    Wire.requestFrom(MPU_addr, 6, true);
    
    AcX = Wire.read() << 8 | Wire.read();
    AcY = Wire.read() << 8 | Wire.read();
    AcZ = Wire.read() << 8 | Wire.read();

    // Chuyển đổi sang đơn vị g (dải +/- 8g chia cho 4096)
    float ax = (float)AcX / 4096.0;
    float ay = (float)AcY / 4096.0;
    float az = (float)AcZ / 4096.0;

    // Tính độ lớn gia tốc toàn phần |a|
    float a_total = sqrt(ax*ax + ay*ay + az*az);

    // Gửi dữ liệu dạng text cách nhau bằng dấu phẩy
    Serial.print(a_total, 4);
    Serial.print(",");
    Serial.println(az, 4);
  }
}