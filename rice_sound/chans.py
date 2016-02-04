
import os
import math



def filter(arr):
	maxValue = 0;
	for a in arr:
		if (maxValue < a ):
			maxValue = a

	for i in range(len(arr)):
		if arr[i] < maxValue * 0.01:
			arr[i] = 0

	return maxValue

def normalize(arr):
	s = 0;
	for a in arr:
		s += a * a 
	s = math.sqrt(s)

	for i in range(len(arr)):
		arr[i] = arr[i] / s




files = os.listdir('.')


blankValue = []
blankfile = open('blank.txt','r')
for line in blankfile.readlines():
	blankValue.append(float(line.split(' ')[1]))

blankMax = filter(blankValue)

for fileName in files:
	if fileName.endswith('txt') and not(fileName.endswith('-c.txt')):
		infile = open(fileName,'r')
		outfile = open(fileName.split('.')[0]+'-c.txt','w')


		value = []
		for line in infile.readlines():
			if len(line.split(' '))>1:
				print line.split(' ')[1]
				value.append(float(line.split(' ')[1]))


		if not(fileName.startswith('blank')):
			value[65]=value[66]=value[67]=value[97]=value[98]=value[99]=0;
			vMax = filter(value)
			normalize(value)

		for i in range(len(value)):
			outfile.write(str(i)+","+str(value[i])+"\r\n");

		infile.close()
		outfile.close()



