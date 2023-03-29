cd msd_scheduler/

echo "Starting scheduler..."
echo "----------------------"
echo "Device: xc7z020"
echo "Model: VGG-16"
echo "----------------------"

python run_simulator.py -a xc7z020 -m vgg16

echo "----------------------"
echo "Device: xc7z020"
echo "Model: ResNet-18"
echo "----------------------"

python run_simulator.py -a xc7z020 -m resnet18

echo "----------------------"
echo "Device: xc7z020"
echo "Model: MobileNet-V2"
echo "----------------------"

python run_simulator.py -a xc7z020 -m mobilenetv2

echo "----------------------"
echo "Device: Ultra96"
echo "Model: VGG-16"
echo "----------------------"

python run_simulator.py -a ultra96 -m vgg16

echo "----------------------"
echo "Device: Ultra96"
echo "Model: ResNet-18"
echo "----------------------"

python run_simulator.py -a ultra96 -m resnet18

echo "----------------------"
echo "Device: Ultra96"
echo "Model: ResNet-50"
echo "----------------------"

python run_simulator.py -a ultra96 -m resnet50

echo "----------------------"
echo "Device: Ultra96"
echo "Model: MobileNet-V2"
echo "----------------------"

python run_simulator.py -a ultra96 -m mobilenetv2


echo "----------------------"
echo "Device: ZCU102"
echo "Model: VGG-16"
echo "----------------------"

python run_simulator.py -a zcu102 -m vgg16

echo "----------------------"
echo "Device: ZCU102"
echo "Model: ResNet-18"
echo "----------------------"

python run_simulator.py -a zcu102 -m resnet18

echo "----------------------"
echo "Device: ZCU102"
echo "Model: ResNet-50"
echo "----------------------"

python run_simulator.py -a zcu102 -m resnet50

echo "----------------------"
echo "Device: ZCU102"
echo "Model: ViT-base"
echo "----------------------"

python run_simulator.py -a zcu102 -m vitbase

echo "----------------------"
echo "Scheduler finished."
echo "----------------------"