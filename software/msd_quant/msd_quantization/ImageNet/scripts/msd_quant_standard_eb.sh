mkdir -p log

# Run on the server with 4 NVIDIA A10 GPUs.
#PTQ
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46666 main.py --batch_size=128 --ptq --dataset=imagenet --model=resnet18 --mode=ant-int --wbit=8 --abit=8 -wl=100 -al=100 --eb=sel-1-2-3-4-5 > ./log/resnet18_Int_EB_kernelwise_inference_test1.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46668 main.py --batch_size=128 --ptq --dataset=imagenet --model=resnet18 --mode=ant-int --wbit=8 --abit=8 -wl=100 -al=100 --eb=sel-1-2-3-4-5 > ./log/resnet18_Int_EB_layerwise_inference_test2.log 2>&1

#ResNet18
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46671 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train > ./checkpoint_log/ResNet18_EB2_MSD.log 2>&1

#ResNet50
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46670 main.py --dataset=imagenet --model=resnet50 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train > ./checkpoint_log/ResNet50_EB2_MSD_layerwise.log 2>&1

#MobileNetV2
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46671 main.py --dataset=imagenet --model=mobilenet_v2 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train > ./checkpoint_log/mobilenet_v2_EB2_MSD.log 2>&1

#VGG-16
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46673 main.py --dataset=imagenet --model=vgg16_bn --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.001 --train > ./checkpoint_log/vgg16_EB2_MSD_layerwise.log 2>&1

#ViT
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46670 main.py --dataset=imagenet --model=vit_b_16 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train > ./checkpoint_log/Vit_B16_EB2_MSD.log 2>&1
