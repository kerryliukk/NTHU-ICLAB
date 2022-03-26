# EE4292 IC Design Laboratory Final Project
## Implement Edge Detection and Object Detection on Image using HOG (Histogram of Oriented Gradient) Algorithm With Some Famous Filters
## 利用方向梯度直方圖演算法實現圖像邊緣檢測及物件識別
#### Instructor: Prof. Chao Tsung Huang</br>Team Members: 林暄傑、劉亦傑、謝霖泳

## Contributors
This project exists thanks to all the people who contribute.
![](https://github.com/LeoTheBestCoder/ICLAB_final/graphs/contributors)

## Motivation and Objective
&emsp;After the department store closes, some thieves will sneak into the store. So, we develop a system that can detect the edges in an image. When a thief sneaks into a store, the edges in the monitor screen will change drastically, indicating that something unusual has happened in the store.

## Functionality
The function we want to implement in our hardware is below:
* Normal mode
    1. Calculating gradient
* Advanced mode (Detection with noise figures)
    1. median filter 
    2. Gaussian denoiser

## Specification
* image: 640*480 pixels
* input: 70 pixels per cycle (each pixel is 8-bit)
* output: 36 pixels pixel per cycle
* cycle count : 8487


## Synthesis Performance
* timing : 3 ns
* area : 504,438 um^2
* power: 31.8 mW

## Chip Performance
* timing : 5 ns
* area : 562,169 um^2
* power: 28.3 mW (ICC)
* core utilization: 0.7

## Implementation:
1. Survey the algorithms on Internet, and decide to implement classical HOG (Histogram of Oriented Gradient) algorithm
2. image preprocessing (denoise)
3. Compute gradients (cell / block)
4. Use weighted vote to build orientation cells, so that it could construct the histogram.
5. Collect HOG’s over detection window
6. The combined vectors are fed to a linear SVM for object/non-object classification (Python based)

## Verification
1. Verify the calculated value with the golden file.
2. `$fwrite` the value into a log file (processed output result).
3. Visualize the result after whole processed data is written. We expect to see the edges being highlighted.


## Reference
[1] Histograms of Oriented Gradients for Human Detection, by Navneet Dalal and Bill Triggs, CVPR 2005</br>
[2] Image super-resolution as sparse representation of raw image patches, by J. Yang et al, CVPR 2008.</br>
[3] A non-local algorithm for image denoising, CVPR 2005</br>
[4] https://en.wikipedia.org/wiki/Median_filter</br>
[5] https://en.wikipedia.org/wiki/Gaussian_filter</br>