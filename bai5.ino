#include <Wire.h>
#include <MPU6050_tockn.h>

MPU6050 mpu6050(Wire);

unsigned long lastTime = 0;
const unsigned long sampleInterval = 2000; // 2000 ms = 2ms (Tương đương fs = 500Hz)

void setup() {
  Serial.begin(115200); // Sử dụng baudrate cao để truyền dữ liệu nhanh, không bị nghẽn
  Wire.begin();
  mpu6050.begin();
  
  // Bạn có thể chạy mpu6050.calcGyroOffsets(true); nếu cần thiết
  // Tuy nhiên ở bài này chúng ta chỉ cần tập trung vào Gia tốc (Acc)
}

void loop() {
  unsigned long currentTime = micros();
  
  // Đảm bảo lấy mẫu chuẩn xác mỗi 2000 microseconds (2 ms)
  if (currentTime - lastTime >= sampleInterval) {
    lastTime = currentTime;
    
    mpu6050.update();
    
    // Đọc gia tốc trục Z (hoặc tổng hợp độ lớn gia tốc |a|)
    float az = mpu6050.getAccZ(); 
    float ax = mpu6050.getAccX();
    float ay = mpu6050.getAccY();
    
    // Tính độ lớn gia tốc toàn phần |a|
    float a_total = sqrt(ax*ax + ay*ay + az*az);
    
    // Gửi lên MATLAB qua Serial: Thời gian(ms), a_total, az
    Serial.print(millis());
    Serial.print(",");
    Serial.print(a_total, 3);
    Serial.print(",");
    Serial.println(az, 3);
  }
}