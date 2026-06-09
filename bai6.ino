#include <Wire.h>

const int MPU_addr = 0x68; // Địa chỉ I2C của MPU6050
int16_t AcX, AcY, AcZ, Tmp, GyX, GyY, GyZ;

void setup() {
  Wire.begin();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B); // Thanh ghi quản lý nguồn điện
  Wire.write(0);    // Đánh thức MPU6050
  Wire.endTransmission(true);
  
  Serial.begin(115200); // Tốc độ Baud cao để truyền dữ liệu nhanh, mượt
}

void loop() {
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B); // Bắt đầu từ thanh ghi ACCEL_XOUT_H
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr, 14, true); // Đọc 14 thanh ghi dữ liệu
  
  AcX = Wire.read() << 8 | Wire.read();  
  AcY = Wire.read() << 8 | Wire.read();  
  AcZ = Wire.read() << 8 | Wire.read();  
  Tmp = Wire.read() << 8 | Wire.read();  
  GyX = Wire.read() << 8 | Wire.read();  
  GyY = Wire.read() << 8 | Wire.read();  
  GyZ = Wire.read() << 8 | Wire.read();  
  
  // Gửi dữ liệu thô qua Serial cách nhau bằng dấu phẩy
  Serial.print(AcX); Serial.print(",");
  Serial.print(AcY); Serial.print(",");
  Serial.print(AcZ); Serial.print(",");
  Serial.print(GyX); Serial.print(",");
  Serial.print(GyY); Serial.print(",");
  Serial.println(GyZ);
  
  delay(10); // Đảm bảo chu kỳ lấy mẫu ~10ms (100Hz)
}