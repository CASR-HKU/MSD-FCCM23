# MSD quantization for image classification.
## ImageNet data

Please prepare your dataset with [this script](https://github.com/pytorch/examples/blob/main/imagenet/extract_ILSVRC.sh) and set your dataset path using "--dataset_path /your/imagenet_path".


## Evaluation 


### Results of 8-bit quantization with fine-tuning (Table IV).
---

```shell
./scripts/msd_quant_standard_eb.sh         # Different models with same EB configuration
```
The accuracy results under our configuration are listed in the following table. 

| Model | MSD  | Model | MSD | 
| :----:| :----: | :----: | :----: | 
| MobileNet V2 | **71.156%** | VGG16 | **73.43%** | 
| ResNet18 | **70.08%** | ResNet50 | **76.464%** |

Results of 8-bit quantization can be reproduced with slight random error. 

There are relatively large errors and unacceptable accuracy losses (10%-50%) in the results of 8-bit quantization with fine-tuning.

### Results of RSD quantization with fine-tuning (Table III).
---
We fine-tune the CV models with two types of server configuration.
- The server equipped with Three `NVIDIA 3090 (24GB)` GPUs is for the models:
    - ResNet-18;
    - ResNet-50;
    - ViT;
    - VGG16;
    - MobilneNet V2.

Note that you can reconfigure the batch size to reduce the memory requirement to run on a server with less memory, but this will impact the model accuracy results due to different batch sizes.
To conduct a fair comparison, we set Mode INT with the same settings under differnet effectual bits (EB) selection.
For MSD quantization, the log file will print the data type chosen result, and we can analyze it for the selected EB quantization.

You can exploit the following scripts to fine-tune all models. We provide the approximate execution time for each script.


You can find the log files in the directory `./log`. You can run the following scripts to reproduce the results with fine-tuning for CNNs (ResNet18, ResNet50, VGG16) and ViT. The result may have a little random error (< 0.1%) due to the CUDA rounding implementation. 

If it occurs the error "RuntimeError: CUDA out of memory.", you can reduce the batch size.

```shell
./scripts/msd_quant_xxx.sh         
```
Notice that the complete fine-tuning process will take dozens of hours for all above models. 




