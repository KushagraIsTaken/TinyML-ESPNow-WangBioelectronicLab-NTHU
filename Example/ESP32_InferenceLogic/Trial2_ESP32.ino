#include "mlp_model.h"        // Your TFLite flatbuffer model header
#include <tflm_esp32.h>
#include <eloquent_tinyml.h>  // or the actual header where Sequential is defined

using namespace Eloquent::TF;

#define NUMBER_OF_INPUTS 8
#define NUMBER_OF_OUTPUTS 8
#define TENSOR_ARENA_SIZE (20 * 1024)

// Scaler parameters from training
const float feature_mean[NUMBER_OF_INPUTS] = {
    19.30619797, 19.19131501, 19.34629111, 17.87492385,
    19.85021848, 22.18717688, 22.72578444, 22.29774153
};

const float feature_scale[NUMBER_OF_INPUTS] = {
    25.81835511, 17.51309927, 17.77630101, 14.56740024,
    17.56038264, 20.68601778, 23.31595183, 23.26393401
};

// Label mapping exactly matching training remapping
const float label_mapping[NUMBER_OF_OUTPUTS] = {0, 1, 2, 3, 6, 7, 8, 9};

// Create the model wrapper
Sequential<10 /* numOps - adjust if needed */, TENSOR_ARENA_SIZE> ml;

void setup() {
  Serial.begin(115200);
  delay(2000);
  Serial.println("Starting...");

  // === Register required operators manually ===
  ml.resolver.AddFullyConnected();
  ml.resolver.AddSoftmax();         // Add more ops if your model uses them (e.g., Relu, Reshape, etc.)

  // === Set input/output counts (REQUIRED) ===
  ml.setNumInputs(NUMBER_OF_INPUTS);
  ml.setNumOutputs(NUMBER_OF_OUTPUTS);

  // === Initialize model ===
  if (!ml.begin(mlp_model_tflite).isOk()) {
    Serial.println("Model initialization failed!");
    Serial.println(ml.exception.toString());
    while (true); // Halt
  }


  Serial.println("Model loaded and ready.");
}

void loop() {
  float raw_input[NUMBER_OF_INPUTS] = {
    0.0, 1.0, 0.0, 5.0, 1.0, 3.0, 3.0, 3.0
  };

  // Normalize input
  float input[NUMBER_OF_INPUTS];
  for (int i = 0; i < NUMBER_OF_INPUTS; i++) {
    input[i] = (raw_input[i] - feature_mean[i]) / feature_scale[i];
  }

  // Predict (returns Exception, not prediction directly)
  Eloquent::Error::Exception error = ml.predict(input);
  if (error) {
    Serial.print("Inference failed: ");
    Serial.println(error.toString());
    delay(2000);
    return;
  }

  // ml.output(i) holds the probabilities
  Serial.print("Output probabilities: ");
  for (int i = 0; i < NUMBER_OF_OUTPUTS; i++) {
    Serial.print(ml.output(i), 4);
    Serial.print(" ");
  }
  Serial.println();

  // ml.classification holds predicted class index
  Serial.print("Predicted label: ");
  Serial.println(label_mapping[ml.classification]);

  delay(3000);
}
