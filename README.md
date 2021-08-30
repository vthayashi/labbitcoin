# labbitcoin
LabBitcoin for energy consumption FPGA experiment with IoT remote lab

## Getting Started
### Hardware Materials
- Current sensor 2000:1
- Resistor 1k
- Capacitor 10u
- ESP8266 NodeMCU
- Protoboard 400 Points
- Male Male Jumper Kit 50+ pcs
- Male Female Jumper Kit 40 pcs
- Micro USB Cable
- Bipolar Power Cable
- Power Cord
- Module 1 relay for Arduino
- DE0-CV Altera Cyclone V FPGA Board with USB Blaster cable

## Software Codes
- labdig.htm (available in this repo)
- Hashers22 adapted for DE0-CV Altera Cyclone V FPGA Board (available in this repo)
- ESP8266 script (use EOS library available in https://github.com/vthayashi/esp8266-esp32-eos)

## Steps
- Build the smart meter prototype considering the assembly of the hardware materials (there are multiple tutorials available, such as https://optimalprimate.github.io/projects/2020/11/06/smart-power-meter.html)
- Update the firmware made with EOS library using the Arduino IDE (more details on https://github.com/vthayashi/esp8266-esp32-eos/wiki/Getting-Started)
- Compile and load the VHDL project using Quartus and the USB Blaster cable (more details on https://www2.pcs.usp.br/~labdig/material/VHDL-Quartus-Prime-16.1-v1.pdf)
- Use a public MQTT broker (https://github.com/mqtt/mqtt.org/wiki/public_brokers) or your own (more details on https://github.com/vthayashi/esp8266-esp32-eos/wiki/Config-(MQTT))
- Configure labdig.htm with the MQTT broker information
- You may use remote lab LabEAD (https://github.com/vthayashi/labead-labdig) for remote access to your experiment using another ESP8266 device or Analog Discovery for live interactions. It is possible to use the python script to futher automatize the process, but it is optional.

## Thanks to
Victor Takashi Hayashi
Felipe Valencia de Almeida
Fabio Hirotsugu Hayashi
