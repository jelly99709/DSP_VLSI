# (d+2)-bit fix point twiddle factor generator
# 1 sign bit, 1 int bit, d decimal point bits

import numpy as np

file = open('twiddle.v','w')

#parameter declaration
d = 7
N = 32
pi = np.pi
j = 0 + 1j
real_name = 'twf_R'
imag_name = 'twf_I'

file.write('wire signed [' + str(d+1) + ':0] ' + real_name + ' [0:' + str(int(N/2-1)) + '];\n')
file.write('wire signed [' + str(d+1) + ':0] ' + imag_name + ' [0:' + str(int(N/2-1)) + '];\n')
for k in range(16):
	W_k = np.exp(-j*2*pi*k/N)
	R = np.real(W_k)
	I = np.imag(W_k)
	if(R < 0): R += 4 #2's complement shift
	if(I < 0): I += 4 #2's complement shift
	R = int(round(R * (2 ** d)))
	I = int(round(I * (2 ** d)))
	R_ = bin(R)[2:].zfill(d+2)
	I_ = bin(I)[2:].zfill(d+2)
	file.write('assign ' + real_name + '[' + str(k) + '] = ' + str(d+2) +'\'sb' + R_ + ';')
	file.write('   ')
	file.write('assign ' + imag_name + '[' + str(k) + '] = ' + str(d+2) +'\'sb' + I_ + ';')
	file.write('\n')

file.close()