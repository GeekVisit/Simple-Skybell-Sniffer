#!/bin/bash
###################################
#https://github.com/GeekVisit/Simple-Skybell-Sniffer/
#
# This is the script that runs once skybell-sniffer detects button push

#After editing this file you need to reload skybell sniffer: 
#sudo systemctl start skybell-sniff
#sudo systemctl daemon-reload
#sudo systemctl start skybell-sniff
#sudo systemctl enable skybell-sniff
##########################################

# This script publishes an mqtt topic so that Homeassistant can detect the doorbell has been run 

#Instructions: 

#Put this in your home assistant in configuration.yaml:

# Under Sensor:

#
#- platform: mqtt
#    name: "mqtt_skybell_doorbell"
#    state_topic: "skybell/doorbell/state"
#    qos: 1
#

# Under Automation:

# - alias: Doorbell
#    trigger:
#      platform: state
#      entity_id: sensor.mqtt_skybell_doorbell
#      from: 'OFF'
#      to: 'Ringing'       
#    action:
#      - service: media_player.play_media           
#        data:
#          entity_id: media_player.family_room_speaker
#          media_content_id: "https://[your server].duckdns.org:443/doorbell1.mp3" # change to your mp3 file, must use an external https address to undo 
#          media_content_type: 'audio/mp3'

VISIT_TIME=$(date '+%m-%d-%Y %l:%M:%S %p')
#Change 192.168.0.200 to your mqtt broker (e.g., mosquitto) and -p to mosquitto port)
#silent - comment out
/usr/bin/mosquitto_pub -h 192.168.0.200 -p 1883 -t skybell/doorbell/state -m "Ringing"
mosquitto_pub -h 192.168.0.200 -p 1883 -t skybell/motion/state -m "Detected"
sleep 2 
mosquitto_pub -h 192.168.0.200 -p 1883 -t skybell/doorbell/state -m "OFF"
mosquitto_pub -h 192.168.0.200 -p 1883 -t skybell/motion/state -m "OFF"



logger $VISIT_TIME": Script: Button Pressed - Skybell Doorbell Rung"
#to get log of rings do this: 
#sudo tail -f /var/log/syslog | grep -i skybell

