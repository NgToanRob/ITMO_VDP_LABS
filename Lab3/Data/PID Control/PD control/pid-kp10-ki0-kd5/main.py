#!/usr/bin/env python3
from ev3dev.ev3 import *
import time

mA = LargeMotor('outA')
timeStart = time.time() # chỗ này không cần đâu nha
mA.position = current_time = start_time = 0

fh = open('data.txt', 'w')
fh.write('0' + '0' + '\n')

start_time = time.time()
previous_time = start_time
integral = 0
previous_error = 0




target_theta = 580

kp = 10
ki = 0
kd = 5

while True:
	current_time = time.time() - start_time
	dt = current_time - previous_time
	error = target_theta - mA.position
	proportional = error
	integral = integral + (error*dt)
	derivative = (error - previous_error)/dt
	
	U = kp*proportional + ki*integral + kd*derivative
	
	if (U > 100):
		U = 100
	if (U < -100):
		U = -100
	mA.run_direct(duty_cycle_sp=U)
	fh.write(str(current_time) + ' ' + str(mA.position) + '\n')
	previous_time = current_time
	previous_error = error
	if (current_time - start_time >= 10):
		mA.stop(stop_action = 'brake')
		fh.close

