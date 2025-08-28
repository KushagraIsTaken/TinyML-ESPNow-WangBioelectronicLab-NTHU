#include <esp_now.h>
#include <WiFi.h>

typedef struct struct_message {
  float input_data[8];
} struct_message;

struct_message dataToSend;
uint8_t receiverMac[] = {0x80, 0x7d, 0x3a, 0xbd, 0x7f, 0x7c};  // Replace with Receiver MAC

void readSerialInput() {
  Serial.println("Enter 8 float values separated by space or newline:");

  int count = 0;
  while (count < 8) {
    if (Serial.available()) {
      String input = Serial.readStringUntil('\n');
      input.trim();

      if (input.length() == 0) continue;

      // Split input line into tokens
      char *token = strtok((char *)input.c_str(), " ");
      while (token != nullptr && count < 8) {
        dataToSend.input_data[count] = atof(token);
        count++;
        token = strtok(nullptr, " ");
      }
    }
  }

  Serial.println("Received input:");
  for (int i = 0; i < 8; i++) {
    Serial.print(dataToSend.input_data[i], 4);
    Serial.print(" ");
  }
  Serial.println();
}

void sendData() {
  esp_err_t result = esp_now_send(receiverMac, (uint8_t *) &dataToSend, sizeof(dataToSend));
  if (result == ESP_OK) {
    Serial.println("Data sent successfully");
  } else {
    Serial.print("Error sending data: ");
    Serial.println(result);
  }
}

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);

  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW init failed");
    while (true);
  }

  esp_now_peer_info_t peerInfo;
  memcpy(peerInfo.peer_addr, receiverMac, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;

  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("Failed to add peer");
    while (true);
  }

  Serial.println("ESP-NOW Sender Ready");
}

void loop() {
  readSerialInput();
  sendData();
}
