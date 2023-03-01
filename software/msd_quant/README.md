# MSD Quantization
We evaluate the results with models in image classification. 
## Paper's Hardware Configuration

+ AMD EPYC 7413 24-Core Processor @ 2.65GHz
+ 5 * NVIDIA 3090 GPUs (24GB)

## Environment
```

# PyTorch 1.12
conda create -n hamha_quant python=3.8 
conda activate hamha_quant
conda install  pytorch=1.12.0 torchvision torchaudio cudatoolkit=11.3 -c pytorch
# Quantization CUDA kernel
pip install ./quant

#ImageNet
pip install --extra-index-url https://developer.download.nvidia.com/compute/redist nvidia-dali-cuda110

```


## ImageNet
The image classification tasks include five models, i.e., VGG16, ResNet18, ResNet50, MobileNetV2 and ViT. 

For reproducing the results in Table III, please refer to `./ImageNet`.


## Structure

```
├── msd_quantization                        # The MSD framework with PyTorch.
│   ├── msdquant                            # Quantization framework of MSD.
│   ├── ImageNet
│   │   └── scripts                         # Download checkpoints and reproduce the experimental data in Table III.                          
│   └── quant                               # Quantization CUDA kernel.
├── msd_analysis                            # The performance evaluation of msd framework.
```

## License
Licensed under an Apache-2.0 license.
