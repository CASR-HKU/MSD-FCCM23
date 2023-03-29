DEVICE_MODEL_LIST := xc7z020_vgg16 xc7z020_resnet18 xc7z020_mobilenetv2
DEVICE_MODEL_LIST += ultra96_vgg16 ultra96_resnet18 ultra96_mobilenetv2 ultra96_resnet50
DEVICE_MODEL_LIST += zcu102_vgg16 zcu102_resnet18 zcu102_resnet50 zcu102_vitbase

.PHONY: all DEVICE_MODEL_LIST

all: $(DEVICE_MODEL_LIST)

$(DEVICE_MODEL_LIST):
	@python run_simulator.py -a $(word 1,$(subst _, ,$@)) -m $(word 2,$(subst _, ,$@))