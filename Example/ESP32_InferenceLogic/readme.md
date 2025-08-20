# ESP32 Multi-Layer Perceptron (MLP) Classification Model

This Arduino sketch implements a machine learning inference system for ESP32 microcontrollers using TensorFlow Lite for Microcontrollers (TFLite Micro) to run a trained Multi-Layer Perceptron model for classification tasks.

## Overview

The code loads a pre-trained neural network model that takes 8 input features and classifies them into one of 8 possible output classes. It includes proper data preprocessing (normalization) and post-processing (label mapping) to ensure compatibility with the original training pipeline.

## Key Components

### Dependencies
- **TensorFlow Lite Micro ESP32**: Core inference engine for running TensorFlow models on ESP32
- **Eloquent TinyML**: Higher-level C++ wrapper providing simplified model management
- **mlp_model.h**: Header file containing the compiled TensorFlow Lite model as a byte array

### Model Architecture
- **Input Layer**: 8 features
- **Output Layer**: 8 classes (probability distribution)
- **Model Type**: Multi-Layer Perceptron (fully connected neural network)
- **Tensor Arena Size**: 20KB (memory allocated for model inference)

## Data Processing Pipeline

### 1. Input Normalization
The model expects normalized input data using z-score standardization:
```
normalized_value = (raw_value - mean) / standard_deviation
```

**Feature Statistics** (derived from training data):
- **Means**: [19.31, 19.19, 19.35, 17.87, 19.85, 22.19, 22.73, 22.30]
- **Standard Deviations**: [25.82, 17.51, 17.78, 14.57, 17.56, 20.69, 23.32, 23.26]

### 2. Label Mapping
The model outputs probabilities for indices 0-7, but these map to actual class labels:
- **Index 0** → Class 0
- **Index 1** → Class 1
- **Index 2** → Class 2
- **Index 3** → Class 3
- **Index 4** → Class 6
- **Index 5** → Class 7
- **Index 6** → Class 8
- **Index 7** → Class 9

This mapping suggests the original dataset had 10 classes (0-9) but only 8 were present in the training data.

## Code Structure

### Setup Phase
1. **Serial Communication**: Initializes at 115200 baud for debugging
2. **Operator Registration**: Manually registers required TensorFlow operators:
   - `FullyConnected`: Dense layer operations
   - `Softmax`: Output probability normalization
3. **Model Initialization**: Loads the TFLite model and allocates memory
4. **Input/Output Configuration**: Sets expected tensor dimensions

### Main Loop
1. **Raw Input**: Defines test input vector (currently hardcoded example)
2. **Preprocessing**: Applies z-score normalization to all input features
3. **Inference**: Runs the neural network prediction
4. **Output Processing**: 
   - Displays probability distribution across all classes
   - Shows the predicted class label (highest probability)
5. **Delay**: Waits 3 seconds before next prediction

## Sample Input/Output

**Raw Input Example**: `[0.0, 1.0, 0.0, 5.0, 1.0, 3.0, 3.0, 3.0]`

**Expected Output Format**:
```
Output probabilities: 0.1234 0.0567 0.7891 0.0234 0.0012 0.0045 0.0015 0.0002
Predicted label: 2
```

## Configuration Parameters

- **NUMBER_OF_INPUTS**: 8 (input feature count)
- **NUMBER_OF_OUTPUTS**: 8 (output class count)
- **TENSOR_ARENA_SIZE**: 20KB (adjust based on model complexity)
- **Serial Baud Rate**: 115200

## Usage Instructions

1. **Hardware Setup**: Connect ESP32 to computer via USB
2. **Model Integration**: Ensure `mlp_model.h` contains your trained model
3. **Library Installation**: Install required TensorFlow Lite and Eloquent TinyML libraries
4. **Upload Code**: Compile and upload to ESP32
5. **Monitor Output**: Open Serial Monitor to view predictions
6. **Input Modification**: Replace hardcoded `raw_input` array with sensor data or other input sources

## Customization Points

- **Input Source**: Replace static array with sensor readings, network data, etc.
- **Model Parameters**: Update means, scales, and label mappings for different trained models
- **Output Actions**: Add logic to act on predictions (control actuators, send notifications, etc.)
- **Batch Processing**: Modify to handle multiple inputs simultaneously
- **Error Handling**: Enhance error reporting and recovery mechanisms

## Performance Considerations

- **Memory Usage**: Monitor tensor arena size - increase if model fails to load
- **Inference Speed**: Typically milliseconds on ESP32, suitable for real-time applications
- **Power Consumption**: Consider deep sleep modes between predictions for battery-powered projects

## Troubleshooting

- **Model Load Failure**: Check tensor arena size and model file inclusion
- **Inference Errors**: Verify input dimensions match model expectations
- **Incorrect Predictions**: Confirm normalization parameters match training pipeline
- **Memory Issues**: Increase `TENSOR_ARENA_SIZE` or optimize model architecture