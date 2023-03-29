cd msd_quant/msd_quantization/ImageNet
mkdir -p log

#ResNet18
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46666 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --lr=0.00005 --train > ./log/resnet18_Int.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46667 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=sel-2-3-4-5 --lr=0.0005 --train > ./log/resnet18_Int_EB3_layerwise.log 2>&1
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46666 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=sel-2-3-4-5 --lr=0.0005 --train > ./log/resnet18_Int_EB2_layerwise.log 2>&1
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46670 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=eb1 --lr=0.0005 --train > ./log/resnet18_Int_EB1_layerwise.log 2>&1

#Latency-search framework
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46670 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=eb3 --lr=0.0005 --train -l8=15,14,13> ./log/resnet18_Int_EB_layerwise_mix_1.5148784628086114.log 2>&1
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46671 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=eb3 --lr=0.0005 --train -l8=15,14,13,10,20,16,18,0,4,2,9> ./log/resnet18_Int_EB_layerwise_mix_1.594210420371631.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46672 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=eb3 --lr=0.0005 --train -l8=15,14,13,10,20,16,18,0,4,2,9,8,6,4> ./log/resnet18_Int_EB_layerwise_mix_1.6508462215919382.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46666 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=eb2 --lr=0.0005 --train -l4=17,7,8,9,15,14,11 > ./log/resnet18_Int_EB_layerwise_mix_1.7575486860057685.log 2>&1
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46667 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=eb2 --lr=0.0005 --train -l4=17,7,8,9,15,14,11,10,20,19 > ./log/resnet18_Int_EB_layerwise_mix_1.8403395669812619.log 2>&1
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46668 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=eb2 --lr=0.0005 --train -l4=17,7,8,9,15,14,11,10,20,19,16 > ./log/resnet18_Int_EB_layerwise_mix_1.903645191333169.log 2>&1

#VGG-16
#Latency-search framework
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46670 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb3 --lr=0.0005 --train > ./log/vgg16_Int_EB3_layerwise_mix_1.5012781223260003.log 2>&1
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46671 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train > ./log/vgg16_Int_EB2_layerwise_mix_1.737614389850166.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46672 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=64 --eb=csd_eb1 --lr=0.0005 --train > ./log/vgg16_Int_EB1_layerwise_mix_2.2849717717171862.log 2>&1
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46666 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb3 --lr=0.0005 --train -l8=2,4,7,15,11,0,3,6 > ./log/vgg16_Int_EB_layerwise_mix_1.6148889324891162.log 2>&1
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46667 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb3 --lr=0.0005 --train -l8=2,4,7,15,11,0 > ./log/vgg16_Int_EB_layerwise_mix_1.5418001972489717.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46668 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb3 --lr=0.0005 --train -l8=2,4,7,15,11,0,6,3,9,14,13,2,4,12 > ./log/vgg16_Int_EB_layerwise_mix_1.6814700797761533.log 2>&1
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46667 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train -l4=13 > ./log/vgg16_Int_EB_layerwise_mix_1.988074265643286.log 2>&1
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46668 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train -l4=13,4,15,11,0,15,1,3,6 > ./log/vgg16_Int_EB_layerwise_mix_2.0586388000108022.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46669 main.py --dataset=imagenet --model=vgg16_bn --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train -l4=13,4,15,11,0,15,1,3,6,5,9 > ./log/vgg16_Int_EB_layerwise_mix_2.1365108346304034.log 2>&1


#ResNet50
#Latency-search framework
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46670 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb3 --lr=0.0005 --train > ./log/resnet50_Int_EB3_layerwise_mix_2.226201031542863.log 2>&1
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46671 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train > ./log/resnet50_Int_EB2_layerwise_mix_2.7428610035032848.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46672 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=64 --eb=csd_eb1 --lr=0.0005 --train > ./log/resnet50_Int_EB1_layerwise_mix_3.2263346767314967.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46666 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb3 --lr=0.0005 --train -l8=25,47,46,35,29,38,46,5,8,15 > ./log/resnet50_Int_EB_layerwise_mix_2.326966341222434.log 2>&1
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46667 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb3 --lr=0.0005 --train -l8=25,47,46,35,29,38,46,5,8,15,29,1,10,31,37,40,8,10,1,17,14,27,42,33,0,14,40,31,15,37,13,42,27,33,43 > ./log/resnet50_Int_EB_layerwise_mix_2.433465312782313.log 2>&1
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46667 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb3 --lr=0.0005 --train -l8=25,47,46,35,29,38,46,5,8,15,38,29,1,10,31,37,40,8,10,1,17,14,27,42,33,0,14,40,31,15,37,13,42,27,33,43,24,13,43,45,45,48,48,12,9,6,3,16,19 > ./log/resnet50_Int_EB_layerwise_mix_2.5786077408601855.log 2>&1
CUDA_VISIBLE_DEVICES=2 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46668 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train -l4=28,40,18,0,39,27,33,40,27,33,39,13,43> ./log/resnet50_Int_EB_layerwise_mix_2.817414251480465.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46669 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train -l4=28,40,18,0,39,27,33,40,27,33,39,13,43,24,45,48,2,3,9,25,12 > ./log/resnet50_Int_EB_layerwise_mix_2.912476737327861.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46670 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train -l4=28,40,18,0,39,27,33,40,27,33,39,13,43,24,45,48,2,3,9,25,12,16,22,25,49,47,41,35,32,4,1,10,8,7,41,32,35,47,23,14,49,31 > ./log/resnet50_Int_EB_layerwise_mix_2.999844996839765.log 2>&1
CUDA_VISIBLE_DEVICES=1 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46671 main.py --dataset=imagenet --model=resnet50 --epoch=3 --mode=int --wbit=8 --abit=8 --batch_size=128 --eb=csd_eb2 --lr=0.0005 --train -l4=28,40,18,0,39,27,33,40,27,33,39,13,43,24,45,48,2,3,9,25,12,16,22,25,49,47,41,35,32,4,1,10,8,7,41,32,35,47,23,14,49,31,37,21 > ./log/resnet50_Int_EB_layerwise_mix_3.0088910337175596.log 2>&1
CUDA_VISIBLE_DEVICES=0 python -u -m torch.distributed.launch --nproc_per_node=1 --master_port 46666 main.py --dataset=imagenet --model=resnet18 --epoch=5 --mode=int --wbit=8 --abit=8 --batch_size=256 --eb=sel-2-3-4-5 --lr=0.00005 --train > ./log/resnet18_Int_EB_layerwise_largeeb.log 2>&1



