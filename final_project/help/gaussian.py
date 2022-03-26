import numpy as np
import scipy.signal
f = open('noise_638_482.txt')
L = f.readlines()
f_o = open('new.txt', 'w')
cnt_large = 0
cnt_small = 0
final = np.zeros(shape=(482, 638), dtype=np.int64)
print(final.shape)
for line in L:
    tmp = line.split('_')
    ans = []
    for item in tmp:
        ans.append(int(item, 16))
    final[cnt_large] = np.array(ans, dtype=np.int64)
  
    cnt_large += 1
gauss = np.array([[1, 2, 1], [2, 4, 2], [1, 2, 1]])
print(gauss)
final_2 = scipy.signal.convolve2d(final, gauss, 'valid')
# print(final_2.shape)
for i in range(final_2.shape[0]):
    for j in range(final_2.shape[1]):
        final_2[i][j] = final_2[i][j] // 16
for i in range(final_2.shape[0]):
    a = list(map(hex, list(final_2[i])))
    b = []
    for item in a:
        b.append(item[2:].zfill(2))
    f_o.write('_'.join(b) + "\n")
    # print(final_2[i] // 16)
# print(final)
    # print(tmp_ans.shape)
# print(L)
f_o.close()