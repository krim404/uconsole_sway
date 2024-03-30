#!/bin/bash
brightness=$(brightnessctl g)

if [ "$brightness" != "0" ]; then
	brightnessctl set 0;
else
	brightnessctl set 5;
fi
