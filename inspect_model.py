#!/usr/bin/env python3
"""
Inspect TensorFlow Lite model to understand input/output tensor specifications.
"""

import numpy as np

try:
    import tensorflow as tf
    print(f"TensorFlow version: {tf.__version__}")
except ImportError:
    print("TensorFlow not installed. Install with: pip install tensorflow")
    exit(1)

# Load the model
model_path = "assets/models/ssd_mobilenet.tflite"
try:
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
except Exception as e:
    print(f"Error loading model: {e}")
    exit(1)

print("\n" + "="*80)
print("MODEL INSPECTION REPORT")
print("="*80)

# Get input and output tensor details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("\nINPUT TENSORS:")
print("-" * 80)
for i, detail in enumerate(input_details):
    print(f"\nInput {i}:")
    print(f"  Name: {detail['name']}")
    print(f"  Shape: {detail['shape']}")
    print(f"  Type: {detail['dtype']}")
    if 'quantization' in detail:
        print(f"  Quantization: {detail['quantization']}")

print("\n\nOUTPUT TENSORS:")
print("-" * 80)
for i, detail in enumerate(output_details):
    print(f"\nOutput {i}:")
    print(f"  Name: {detail['name']}")
    print(f"  Shape: {detail['shape']}")
    print(f"  Type: {detail['dtype']}")
    if 'quantization' in detail:
        print(f"  Quantization: {detail['quantization']}")

# Try a dummy inference to check if model works
print("\n\nTESTING MODEL WITH RANDOM INPUT:")
print("-" * 80)

try:
    input_shape = input_details[0]['shape']
    input_dtype = input_details[0]['dtype']
    
    print(f"Input shape: {input_shape}, dtype: {input_dtype}")
    
    # Create random input
    test_input = np.random.randint(0, 255, size=input_shape, dtype=input_dtype)
    
    # Set the input tensor
    interpreter.set_tensor(input_details[0]['index'], test_input)
    
    # Run inference
    interpreter.invoke()
    
    # Get outputs
    print("\nModel inference successful! Output tensor values:")
    print("-" * 80)
    
    for i, detail in enumerate(output_details):
        output_data = interpreter.get_tensor(detail['index'])
        print(f"\nOutput {i}: {detail['name']}")
        print(f"  Shape: {output_data.shape}")
        print(f"  dtype: {output_data.dtype}")
        print(f"  Min value: {output_data.min()}")
        print(f"  Max value: {output_data.max()}")
        print(f"  First few values: {output_data.flatten()[:10]}")
        
except Exception as e:
    print(f"Error during inference: {e}")

print("\n" + "="*80)
