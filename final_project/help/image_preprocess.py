import numpy as np
from matplotlib import pyplot as plt

from math import sqrt
from copy import deepcopy
import cv2

from med import find_med, find_real_med, writefile, writefile_dec, writefile_long
import random as rd

#### Change your input image name here (include filename extension) ####
IMAGE_NAME = 'flower_638_482.jpg'
########################################################################

print('loading image...')
L = cv2.imread(f'{IMAGE_NAME}', cv2.IMREAD_GRAYSCALE)
L = L.tolist()


print('padding...')
padding = deepcopy(L)
for i in range(len(L)):
    for j in range(len(L[i])):
        if i == 0 or i == len(L) - 1 or j == 0 or j == len(L[i]) - 1:
            padding[i][j] = 0
cv2.imwrite(f'{IMAGE_NAME[:-4]}_padding.jpg', np.array(padding))


print('adding noise...')
noise = deepcopy(padding)
med_of_med = deepcopy(padding)
height, width = len(L), len(L[0])

pos = [(rd.randint(1, height - 2), rd.randint(1, width - 2)) for i in range(30000)]
for p in pos:
    noise[p[0]][p[1]] = 255
cv2.imwrite(f'{IMAGE_NAME[:-4]}_noise.jpg', np.array(noise))
plt.imshow(noise, cmap = 'gray')
plt.show()
writefile(noise, 'noise_638_482')
writefile_dec(noise, 'noise_638_482')

for i in range(len(noise)):
    for j in range(len(noise[i])):
        if i == 0 or i == height - 1 or j == 0 or j == width - 1:
            med_of_med[i][j] = noise[i][j]
        else:
            med_of_med[i][j] = find_med([noise[i-1][j-1], noise[i-1][j], noise[i-1][j+1], noise[i][j-1], noise[i][j], noise[i][j+1], noise[i+1][j-1], noise[i+1][j], noise[i+1][j+1]])

temp = []
for i in range(1, len(med_of_med) - 1):
    temp2 = []
    for j in range(1, len(med_of_med[i]) - 1):
        temp2.append(med_of_med[i][j])
    temp.append(temp2)
med_of_med = deepcopy(temp)

cv2.imwrite(f'{IMAGE_NAME[:-4]}_med_of_med.jpg', np.array(med_of_med))
plt.imshow(med_of_med, cmap = 'gray')
plt.show()
writefile(med_of_med, 'med_of_med_636_480')


# print('calculating hog without denoising...')
# noise_hog_tmp = deepcopy(med_of_med)
# noise_hog = deepcopy(med_of_med)
# for i in range(len(noise)):
#     for j in range(len(noise[i])):
#         if i == 0:
#             gy = int(noise[i + 1][j])
#         elif i == height - 1:
#             gy = int(noise[i - 1][j])
#         else:
#             gy = int(noise[i + 1][j]) - int(noise[i - 1][j])

#         if j == 0:
#             gx = int(noise[i][j + 1])
#         elif j == width - 1:
#             gx = int(noise[i][j - 1])
#         else:
#             gx = int(noise[i][j + 1]) - int(noise[i][j - 1])
#         noise_hog_tmp[i][j] = sqrt(gx ** 2 + gy ** 2)

# # cv2.imwrite(f'{IMAGE_NAME[:-4]}_output.jpg', ans)
# for i in range(len(noise_hog_tmp)):
#     for j in range(len(noise_hog_tmp[i])):
#         if noise_hog_tmp[i][j] > 20:
#             noise_hog[i][j] = 0
#         else:
#             noise_hog[i][j] = 255
# cv2.imwrite(f'{IMAGE_NAME[:-4]}_noise_edge.jpg', np.array(noise_hog))
# plt.imshow(noise_hog, cmap = 'gray')
# plt.show()



print('calculating hog with denoising...')
denoise_hog_tmp = deepcopy(med_of_med)
denoise_hog_tmp_no_sqrt = deepcopy(med_of_med)
denoise_hog = deepcopy(med_of_med)
for i in range(len(med_of_med)):
    for j in range(len(med_of_med[i])):
        if i == 0:
            gy = int(med_of_med[i + 1][j])
        elif i == len(med_of_med) - 1:
            gy = int(med_of_med[i - 1][j])
        else:
            gy = int(med_of_med[i + 1][j]) - int(med_of_med[i - 1][j])

        if j == 0:
            gx = int(med_of_med[i][j + 1])
        elif j == len(med_of_med[i]) - 1:
            gx = int(med_of_med[i][j - 1])
        else:
            gx = int(med_of_med[i][j + 1]) - int(med_of_med[i][j - 1])
        denoise_hog_tmp[i][j] = int(sqrt(gx ** 2 + gy ** 2))
        denoise_hog_tmp_no_sqrt[i][j] = (gx ** 2 + gy ** 2)
writefile_long(denoise_hog_tmp_no_sqrt, 'denoise_hog_no_sqrt_636_480')
writefile(denoise_hog_tmp, 'denoise_hog_with_sqrt_636_480')

# cv2.imwrite(f'{IMAGE_NAME[:-4]}_output.jpg', ans)
for i in range(len(denoise_hog_tmp)):
    for j in range(len(denoise_hog_tmp[i])):
        if denoise_hog_tmp[i][j] > 20:
            denoise_hog[i][j] = 0
        else:
            denoise_hog[i][j] = 255
cv2.imwrite(f'{IMAGE_NAME[:-4]}_denoise_edge.jpg', np.array(denoise_hog))
plt.imshow(denoise_hog, cmap = 'gray')
plt.show()

print('Finish')
