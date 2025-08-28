#include "mlp_model.h"        // Your TFLite flatbuffer model header
#include <tflm_esp32.h>
#include <eloquent_tinyml.h>
#include <esp_now.h>
#include <WiFi.h>
#include <ESP32Servo.h>

using namespace Eloquent::TF;

// ======================= TinyML Settings ========================
#define NUMBER_OF_INPUTS 8
#define NUMBER_OF_OUTPUTS 8
#define TENSOR_ARENA_SIZE (20 * 1024)


const float feature_mean[NUMBER_OF_INPUTS] = {
  19.30619797, 19.19131501, 19.34629111, 17.87492385,
  19.85021848, 22.18717688, 22.72578444, 22.29774153
};

const float feature_scale[NUMBER_OF_INPUTS] = {
  25.81835511, 17.51309927, 17.77630101, 14.56740024,
  17.56038264, 20.68601778, 23.31595183, 23.26393401
};

const float label_mapping[NUMBER_OF_OUTPUTS] = {0, 1, 2, 3, 6, 7, 8, 9};  // ignoring -1 (relax)

Sequential<10, TENSOR_ARENA_SIZE> ml;

// ======================= Servo Setup ============================
Servo finger[5];  // Thumb, Index, Middle, Ring, Little
Servo wrist;

const int fingerPins[5] = {17, 18, 19, 21, 22};  // Assign to actual pins
const int wristPin = 16;

// ======================= ESP-NOW Message ========================
typedef struct {
  float input_data[8];
} InputMessage;

InputMessage msg;

// ======================= Hand Control Logic ====================
void performGesture(int gesture) {
  Serial.print("Executing gesture: ");
  Serial.println(gesture);

  switch (gesture) {
    case 0:  // Idle
      for (int i = 0; i < 5; i++) finger[i].write(0);
      wrist.write(90);
      break;

    case 1:  // Fist
      for (int i = 0; i < 5; i++) finger[i].write(180);
      break;

    case 2:  // Flexion
      wrist.write(180);
      break;

    case 3:  // Extension
      wrist.write(0);
      break;

    case 6:  // Pinch index
      finger[0].write(180);  // Thumb
      finger[1].write(180);  // Index
      finger[2].write(0);
      finger[3].write(0);
      finger[4].write(0);
      break;

    case 7:  // Pinch middle
      finger[0].write(180);
      finger[1].write(0);
      finger[2].write(180);
      finger[3].write(0);
      finger[4].write(0);
      break;

    case 8:  // Pinch ring
      finger[0].write(180);
      finger[1].write(0);
      finger[2].write(0);
      finger[3].write(180);
      finger[4].write(0);
      break;

    case 9:  // Pinch small
      finger[0].write(180);
      finger[1].write(0);
      finger[2].write(0);
      finger[3].write(0);
      finger[4].write(180);
      break;

    default:
      Serial.println("Unknown gesture. No action taken.");
      break;
  }
}

// ======================= Inference Logic ========================
void runInference(float raw_input[8]) {
  float input[8];

  for (int i = 0; i < 8; i++)
    input[i] = (raw_input[i] - feature_mean[i]) / feature_scale[i];

  auto error = ml.predict(input);

  if (error) {
    Serial.print("Inference failed: ");
    Serial.println(error.toString());
    return;
  }

  Serial.print("Output: ");
  for (int i = 0; i < NUMBER_OF_OUTPUTS; i++) {
    Serial.print(ml.output(i), 4);
    Serial.print(" ");
  }
  Serial.println();

  int label_index = ml.classification;
  int predicted_label = (int)label_mapping[label_index];

  Serial.print("Predicted Label: ");
  Serial.println(predicted_label);

  performGesture(predicted_label);
}

// ======================= ESP-NOW Callback =======================
void OnDataRecv(const esp_now_recv_info_t *info, const uint8_t *data, int len) {
  if (len != sizeof(InputMessage)) {
    Serial.print("Invalid data size: ");
    Serial.println(len);
    return;
  }

  mmcpy(&msg, data, sizeof(msg));
  Serial.println("Data received. Running inference...");
  runInference(msg.input_data);
}

// ======================= Setup =======================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("ESP-NOW + TinyML Hand Receiver Starting...");

  // Servo setup
  for (int i = 0; i < 5; i++) {
    finger[i].setPeriodHertz(50);
    finger[i].attach(fingerPins[i], 500, 2500);
    finger[i].write(0);
  }
  wrist.setPeriodHertz(50);
  wrist.attach(wristPin, 500, 2500);
  wrist.write(90);

  // Wi-Fi & ESP-NOW init
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW init failed");
    return;
  }
  esp_now_register_recv_cb(OnDataRecv);

  // Model init
  ml.resolver.AddFullyConnected();
  ml.resolver.AddSoftmax();
  ml.setNumInputs(NUMBER_OF_INPUTS);
  ml.setNumOutputs(NUMBER_OF_OUTPUTS);

  if (!ml.begin(mlp_model_tflite).isOk()) {
    Serial.println("Model failed to load");
    Serial.println(ml.exception.toString());
    while (true);
  }

  Serial.println("Setup complete. Waiting for EMG input...");
}

void loop() {
  // Event-driven loop
}
