#!/bin/bash
sudo apt update || die
sudo apt install -y cmake libusb-1.0-0-dev || die
