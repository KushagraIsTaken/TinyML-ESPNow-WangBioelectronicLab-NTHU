# ESP-NOW EMG Hand Control System

This project implements a wireless EMG (Electromyography) signal processing system for controlling a robotic hand prosthetic using ESP32 microcontrollers. The system consists of two components: a **Sender** that captures EMG data and a **Receiver** that processes the data through a machine learning model to control servo motors for hand gestures.

## System Architecture

```
[EMG Sensors] → [ESP32 Sender] --ESP-NOW--> [ESP32 Receiver] → [Servo Motors] → [Robotic Hand]
                                 (Wireless)                    (ML Inference)
```

## Components Overview

### 1. **Sender ESP32**
- Captures 8-channel EMG input data via Serial interface
- Transmits data wirelessly using ESP-NOW protocol
- Provides real-time data streaming to the receiver

### 2. **Receiver ESP32** 
- Receives EMG data wirelessly
- Processes data through trained MLP neural network
- Controls 6 servo motors (5 fingers + 1 wrist)
- Executes corresponding hand gestures based on predictions

## Hardware Requirements

### Receiver Side
- **ESP32 Development Board**
- **6 Servo Motors** (SG90 or similar):
  - 5x Finger servos (Thumb, Index, Middle, Ring, Little)
  - 1x Wrist servo
- **External Power Supply** (5V, sufficient current for servos)
- **Connecting Wires**

### Sender Side
- **ESP32 Development Board**
- **EMG Signal Acquisition System** (or Serial input for testing)

## Pin Configuration

### Receiver ESP32 Pins
```cpp
Finger Servos:
- Thumb:  Pin 17
- Index:  Pin 18  
- Middle: Pin 19
- Ring:   Pin 21
- Little: Pin 22
Wrist Servo: Pin 16
```

## Machine Learning Model

### Model Specifications
- **Type**: Multi-Layer Perceptron (MLP)
- **Input Features**: 8 EMG channels
- **Output Classes**: 8 hand gestures
- **Framework**: TensorFlow Lite for Microcontrollers
- **Memory Usage**: 20KB tensor arena

### Gesture Classes
| Class | Gesture | Description |
|-------|---------|-------------|
| 0 | Idle | All fingers extended, wrist neutral |
| 1 | Fist | All fingers closed |
| 2 | Flexion | Wrist flexed downward |
| 3 | Extension | Wrist extended upward |
| 6 | Pinch Index | Thumb + index finger pinch |
| 7 | Pinch Middle | Thumb + middle finger pinch |
| 8 | Pinch Ring | Thumb + ring finger pinch |
| 9 | Pinch Small | Thumb + little finger pinch |

*Note: Classes 4 and 5 are not used in the current model (likely filtered out during training)*

### Data Preprocessing
The system applies z-score normalization to incoming EMG data:
```cpp
normalized_value = (raw_value - mean) / standard_deviation
```

**Feature Statistics** (from training dataset):
- **Means**: [19.31, 19.19, 19.35, 17.87, 19.85, 22.19, 22.73, 22.30]
- **Std Devs**: [25.82, 17.51, 17.78, 14.57, 17.56, 20.69, 23.32, 23.26]

## ESP-NOW Communication

### Protocol Details
- **Communication**: Unidirectional (Sender → Receiver)
- **Data Structure**: 8 float values (32 bytes total)
- **Range**: Up to 200m in open space
- **Latency**: ~1-5ms typical

### Message Structure
```cpp
typedef struct {
  float input_data[8];  // 8-channel EMG data
} InputMessage;
```

## Software Flow

### Sender Operation
1. **Setup**: Initialize ESP-NOW and configure peer
2. **Input**: Read 8 EMG values via Serial Monitor
3. **Transmit**: Send data packet to receiver
4. **Loop**: Repeat for continuous operation

### Receiver Operation
1. **Setup**: Initialize servos, ESP-NOW, and ML model
2. **Receive**: Wait for incoming EMG data
3. **Preprocess**: Normalize received data
4. **Inference**: Run ML model prediction
5. **Action**: Execute corresponding hand gesture
6. **Event-driven**: No continuous loop, responds to data reception

## Installation & Setup

### 1. Library Dependencies
Install the following libraries in Arduino IDE:
```
- ESP32Servo
- TensorFlowLite_ESP32 (or tflm_esp32)
- Eloquent TinyML
```

### 2. Hardware Connections
Connect servos to designated pins with proper power supply (servos typically require 5V, not 3.3V).

### 3. MAC Address Configuration
Find receiver ESP32 MAC address and update in sender code:
```cpp
uint8_t receiverMac[] = {0x80, 0x7d, 0x3a, 0xbd, 0x7f, 0x7c};  // Update this
```

### 4. Model Integration
Ensure `mlp_model.h` contains your trained TensorFlow Lite model as a byte array.

## Usage Instructions

### Testing with Manual Input
1. **Flash sender code** to one ESP32
2. **Flash receiver code** to another ESP32
3. **Open Serial Monitor** on sender (115200 baud)
4. **Enter 8 float values** separated by spaces
5. **Observe gesture execution** on receiver

### Example Input
```
Serial Input: 0.5 1.2 -0.3 2.1 0.8 -1.5 1.0 0.2
Expected Output: Hand performs predicted gesture
```

### Integration with EMG Sensors
Replace the serial input mechanism in sender code with actual EMG sensor readings:
```cpp
// Replace readSerialInput() with:
void readEMGSensors() {
  for(int i = 0; i < 8; i++) {
    dataToSend.input_data[i] = analogRead(emgPins[i]);
    // Apply any necessary scaling/filtering
  }
}
```

## Performance Characteristics

- **Inference Time**: ~5-10ms on ESP32
- **Gesture Response**: ~20-50ms total latency
- **Servo Movement**: Configurable speed (currently immediate positioning)
- **Communication Range**: 10-200m depending on environment
- **Power Consumption**: ~200-500mA with servos active

## Troubleshooting

### Common Issues

**1. Model Loading Failure**
- Check tensor arena size (increase if needed)
- Verify model file is properly included
- Ensure sufficient flash memory

**2. ESP-NOW Communication Issues**
- Verify MAC addresses are correct
- Check both devices are on same WiFi channel
- Ensure proper ESP-NOW initialization

**3. Servo Control Problems**
- Check power supply (servos need adequate current)
- Verify pin connections
- Test servos individually

**4. Inference Errors**
- Validate input data range and format
- Check feature normalization parameters
- Monitor for NaN or infinite values

### Debug Commands
```cpp
Serial.println(WiFi.macAddress());  // Get MAC address
ml.debug();  // Model debugging info
```

## Customization Options

### Gesture Modification
Add new gestures by modifying the `performGesture()` function:
```cpp
case 10:  // New gesture
  finger[0].write(90);  // Custom positions
  finger[1].write(45);
  // ... additional servo commands
  break;
```

### Servo Speed Control
Implement gradual movement instead of immediate positioning:
```cpp
void smoothMove(Servo &servo, int targetPos, int speed) {
  int currentPos = servo.read();
  // Implement gradual movement logic
}
```

### Multiple Receiver Support
Modify sender to broadcast to multiple receivers for synchronized control.

### Advanced Filtering
Add signal processing for EMG data:
```cpp
float applyFilter(float rawValue) {
  // Implement bandpass filter, envelope detection, etc.
  return filteredValue;
}
```

## Safety Considerations

- **Power Supply**: Use adequate current rating for multiple servos
- **Mechanical Limits**: Implement position limits to prevent servo damage
- **Emergency Stop**: Consider adding manual override capability
- **Signal Validation**: Implement bounds checking on input data
- **Timeout Handling**: Add communication timeout detection

## Future Enhancements

- Real-time EMG signal acquisition and processing
- Adaptive learning for user-specific calibration
- Force feedback integration
- Multiple user profiles
- Mobile app control interface
- Data logging and analysis capabilities