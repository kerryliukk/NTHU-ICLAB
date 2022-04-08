import numpy as np

if __name__ == '__main__':
    # load the feature maps
    unshuffle = np.load('feature_map/unshuffle.npy').astype(np.int32)
    conv1 = np.load('feature_map/conv1.npy')
    conv2 = np.load('feature_map/conv2.npy')
    conv3_pool = np.load('feature_map/conv3_pool.npy')

    # layer_sel = int(input('Enter the layer you want to show:\n0 for unshuffle,\n1 for conv1,\n2 for conv2,\n3 for conv3_pool:\n'))

    # if(layer_sel == 0):
    #     channel_sel = int(input('Enter the channel you want to show (0 ~ 3): \n'))
    #     if(channel_sel >=0 and channel_sel <=3):
    #         print(unshuffle[int(channel_sel)])
    #     else:
    #         raise ValueError('Invalid channel number!')
    # elif(layer_sel == 1):
    #     channel_sel = int(input('Enter the channel you want to show (0 ~ 3): \n'))
    #     if(channel_sel >=0 and channel_sel <=3):
    #         print(conv1[int(channel_sel)])
    #     else:
    #         raise ValueError('Invalid channel number!')
    # elif(layer_sel == 2):
    #     channel_sel = int(input('Enter the channel you want to show (0 ~ 11): \n'))
    #     if(channel_sel >=0 and channel_sel <=11):
    #         print(conv2[int(channel_sel)])
    #     else:
    #         raise ValueError('Invalid channel number!')
    # elif(layer_sel == 3):
    #     channel_sel = int(input('Enter the channel you want to show (0 ~ 47): \n'))
    #     if(channel_sel >=0 and channel_sel <=47):
    #         print(conv3_pool[int(channel_sel)])
    #     else:
    #         raise ValueError('Invalid channel number!')
    # else:
    #     raise ValueError('Invalid layer number!') 
    for i in range(48):
        print(f'{i}: \n{conv3_pool[i]}')