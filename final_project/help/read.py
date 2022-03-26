import cv2
L = cv2.imread('636_480_flower.jpg', cv2.IMREAD_GRAYSCALE)
fh = open('gray.txt', 'w')
for row in L:
    fh.write(f'{" ".join(list(map(str, row)))}\n')
fh.close()
print(L)