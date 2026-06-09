#include <Wire.h>

const int MPU_addr = 0x68; 
int16_t AcX, AcY, AcZ, GyX, GyY, GyZ;

void setup() {
  Wire.begin();
  Serial.begin(115200); // Nâng tốc độ lên 115200 để truyền 500 mẫu cực nhanh và không bị trễ

  // Khởi động MPU6050
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);  
  Wire.write(0);     
  Wire.endTransmission(true);
}

void loop() {
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B);  
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr, 14, true);  
  
  AcX = Wire.read()<<8|Wire.read();  
  AcY = Wire.read()<<8|Wire.read();  
  AcZ = Wire.read()<<8|Wire.read();  
  Wire.read()<<8|Wire.read(); // Bỏ qua biến nhiệt độ
  GyX = Wire.read()<<8|Wire.read();  
  GyY = Wire.read()<<8|Wire.read();  
  GyZ = Wire.read()<<8|Wire.read();  

  // Đổi sang đơn vị g và deg/s
  float ax = (float)AcX / 16384.0;
  float ay = (float)AcY / 16384.0;
  float az = (float)AcZ / 16384.0;
  float gx = (float)GyX / 131.0;   
  float gy = (float)GyY / 131.0;
  float gz = (float)GyZ / 131.0;

  // In chuỗi dữ liệu lên máy tính
  Serial.print(ax, 5); Serial.print(",");
  Serial.print(ay, 5); Serial.print(",");
  Serial.print(az, 5); Serial.print(",");
  Serial.print(gx, 5); Serial.print(",");
  Serial.print(gy, 5); Serial.print(",");
  Serial.println(gz, 5);

  delay(10); // Đợi 10ms (Đảm bảo tần số 100Hz)
}