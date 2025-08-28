#include <esp_now.h>
#include <WiFi.h>

uint8_t receiverMAC[] = {0x80, 0x7d, 0x3a, 0xbd, 0x7f, 0x7c}; // Replace with your receiver ESP32's MAC

typedef struct {
  char cmd; // One character command: 'A', 'b', 'G', etc.
} CommandMessage;

CommandMessage msg;
esp_now_peer_info_t peerInfo;

void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.print("Send status: ");
  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "SUCCESS" : "FAIL");
}

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);

  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW init failed");
    return;
  }

  esp_now_register_send_cb(OnDataSent);

  memcpy(peerInfo.peer_addr, receiverMAC, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;

  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("Failed to add peer");
    return;
  }

  if (esp_now_add_peer(&peerInfo) == ESP_OK) {
    Serial.println("Peer Added Succesfully");
    return;
  }

  Serial.println("Sender ready. Type commands like A, b, G, etc.");
}

void loop() {
  if (Serial.available()) {
    char c = Serial.read();
    if (c >= 32 && c <= 126) { // ignore weird non-printable chars
      msg.cmd = c;
      esp_err_t result = esp_now_send(receiverMAC, (uint8_t *)&msg, sizeof(msg));

      Serial.print("Sent command: ");
      Serial.println(c);
    }
  }
}
