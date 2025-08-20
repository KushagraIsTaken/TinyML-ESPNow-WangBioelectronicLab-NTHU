  #include <ESP32Servo.h>
  #include <esp_now.h>
  #include <WiFi.h>

  Servo finger[5];
  Servo wrist;

  const int fingerPins[5] = {17, 18, 19, 21, 22};
  const int wristPin = 16;

  typedef struct {
    char cmd;
  } CommandMessage;

  CommandMessage msg;

  void processCommand(char cmd) {
    switch (cmd) {
      case 'A': wrist.write(0); break;
      case 'a': wrist.write(180); break;
      case 'B': finger[0].write(0); break;
      case 'b': finger[0].write(180); break;
      case 'C': finger[1].write(180); break;
      case 'c': finger[1].write(0); break;
      case 'D': finger[2].write(180); break;
      case 'd': finger[2].write(0); break;
      case 'E': finger[3].write(180); break;
      case 'e': finger[3].write(0); break;
      case 'F': finger[4].write(180); break;
      case 'f': finger[4].write(0); break;
      case 'G': for (int j = 0; j < 5; j++) finger[j].write(j == 0 ? 0 : 180); break;
      case 'g': for (int j = 0; j < 5; j++) finger[j].write(j == 0 ? 180 : 0); break;
      default:
        Serial.print("Invalid command: "); Serial.println(cmd);
        break;
    }
  }

  void OnDataRecv(const esp_now_recv_info_t *info, const uint8_t *data, int len) {
    memcpy(&msg, data, sizeof(msg));
    Serial.print("Received command: ");
    Serial.println(msg.cmd);
    processCommand(msg.cmd);
  }

  void setup() {
    Serial.begin(115200);

    for (int i = 0; i < 5; i++) {
      finger[i].setPeriodHertz(50);
      finger[i].attach(fingerPins[i], 500, 2500);
      finger[i].write(0);
    }

    wrist.setPeriodHertz(50);
    wrist.attach(wristPin, 500, 2500);
    wrist.write(90);

    WiFi.mode(WIFI_STA);

    if (esp_now_init() != ESP_OK) {
      Serial.println("ESP-NOW init failed");
      return;
    }

    esp_now_register_recv_cb(OnDataRecv);
    Serial.println("Robotic hand ESP-NOW receiver ready.");
  }

  void loop() {
    // Nothing here — purely event-driven
  }
