#!/bin/bash

# Set model size (tiny, base, small, medium, large)
MODEL="small"

# Capture microphone input and process it with Whisper
ffmpeg -f pulse -i default -t 5 -y temp.wav && whisper temp.wav --model $MODEL

