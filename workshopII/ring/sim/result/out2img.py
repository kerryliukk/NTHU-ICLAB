from PIL import Image
import numpy as np
import matplotlib.pyplot as plt

def txt2png():
    with open('out.dat','r') as f_txt:
        h=sum(1 for line in f_txt)//3
        f_txt.seek(0)
        w=len(f_txt.readline().split('_'))
        print('image size: {0}x{1}'.format(w,h))
        idx = 0
        img_array = np.empty([h,w,3], dtype=np.uint8)
        f_txt.seek(0)
        for line in f_txt:
            row = line.split('_')
            for i in range(len(row)):
                img_array[idx%h,i,idx//h] = int(row[i],base=16)
            idx+=1
    img = Image.fromarray(img_array,'RGB')
    img.save('out.png')

    return img_array, img

def cal_psnr(img, bicubic):
    imgTar = np.asarray(Image.open('../../../../golden/HR_zebra_groundtruth.png'))
    prediction = np.asarray(img)
    bicubic_ary = np.asarray(bicubic)
    if imgTar.shape == prediction.shape:
        diff_model = prediction/255.0 - imgTar/255.0
        diff_bicubic = bicubic_ary/255.0 - imgTar/255.0
        mse_model = np.power(diff_model,2).mean()
        mse_bicubic = np.power(diff_bicubic,2).mean()
        psnr_model = -10 * np.log10(mse_model)
        psnr_bicubic = -10 * np.log10(mse_bicubic)
        print('===> PSNR model output: {0:.4f} dB'.format(psnr_model))
        print('===> PSNR bicubic output: {0:.4f} dB'.format(psnr_bicubic))
    else:
        print('No target image.')

def show(img):
    w,h = img.size
    if w == 960 and h == 640:
        bicubic=Image.open('../../../../golden/bicubic_zebra.png')
    elif w == 480 and h == 320:
        bicubic=Image.open('../../../../golden/bicubic_crossing.png')
    elif w == 300 and h == 240:
        bicubic=Image.open('../../../../golden/bicubic_horse.png')
    elif w == 424 and h == 240:
        bicubic=Image.open('../../../../golden/bicubic_panda.png')
    elif w == 340 and h == 240:
        bicubic=Image.open('../../../../golden/bicubic_pups.png')
    cal_psnr(img, bicubic)
    dpi = plt.rcParams['figure.dpi']
    width, height = img.size
    figsize = width / float(dpi), 1+height / float(dpi)
    fig0 = plt.figure(figsize=figsize)
    ax0 = fig0.add_axes([0, 0, 1, 1])
    ax0.set_axis_off()
    ax0.set_title('model output')
    ax0.imshow(img)
    fig1 = plt.figure(figsize=figsize)
    ax1 = fig1.add_axes([0, 0, 1, 1])
    ax1.set_axis_off()
    ax1.set_title('bicubic output')
    ax1.imshow(bicubic)
    plt.show()

if __name__ == '__main__':
    prediction, img = txt2png()
    show(img)
