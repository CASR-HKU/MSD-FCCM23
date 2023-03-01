import numpy as np
import torch
import torchvision
import torch.nn as nn
from torchvision.models.quantization import resnet50, ResNet50_QuantizedWeights
from torchvision.models.quantization import resnet18, ResNet18_QuantizedWeights

from bit_sparsity import extract_bit_level, Quantize_bit_level
import matplotlib.pyplot as plt
from torchvision import datasets
import torchvision.transforms as transforms

import utils
import time
import sys
import os
import copy
"""
------------------------------
    Helper functions
------------------------------
"""


# def quantize_model(model):
#     """
#     Recursively quantize a pretrained single-precision model to int8 quantized model
#     model: pretrained single-precision model
#     """
#     # quantize layers
#     if type(model) == nn.QuantizedConvReLU2d:
#         wgt_arr = model.layer1[0].conv2.weight().int_repr().cpu().detach().numpy()
        
 
#     else:
#         # recursively use the quantized module to replace the single-precision module
#         q_model = copy.deepcopy(model)
#         for attr in dir(model):
#             mod = getattr(model, attr)
#             if isinstance(mod, nn.Module):
#                 setattr(q_model, attr, quantize_model(mod))
#         return q_model


class AverageMeter(object):
    """Computes and stores the average and current value"""
    def __init__(self, name, fmt=':f'):
        self.name = name
        self.fmt = fmt
        self.reset()

    def reset(self):
        self.val = 0
        self.avg = 0
        self.sum = 0
        self.count = 0

    def update(self, val, n=1):
        self.val = val
        self.sum += val * n
        self.count += n
        self.avg = self.sum / self.count

    def __str__(self):
        fmtstr = '{name} {val' + self.fmt + '} ({avg' + self.fmt + '})'
        return fmtstr.format(**self.__dict__)


# class AverageMeter(object):
#     """Computes and stores the average and current value"""

#     def __init__(self):
#         self.reset()

#     def reset(self):
#         self.val = 0
#         self.avg = 0
#         self.sum = 0
#         self.count = 0

#     def update(self, val, n=1):
#         self.val = val
#         self.sum += val * n
#         self.count += n
#         self.avg = self.sum / self.count



def accuracy(output, target, topk=(1,)):
    """Computes the accuracy over the k top predictions for the specified values of k"""
    with torch.no_grad():
        maxk = max(topk)
        batch_size = target.size(0)

        _, pred = output.topk(maxk, 1, True, True)
        pred = pred.t()
        correct = pred.eq(target.view(1, -1).expand_as(pred))

        res = []
        for k in topk:
            correct_k = correct[:k].reshape(-1).float().sum(0, keepdim=True)
            res.append(correct_k.mul_(100.0 / batch_size))
        return res


def evaluate(model, criterion, data_loader, neval_batches):
    model.eval()
    top1 = AverageMeter('Acc@1', ':6.2f')
    top5 = AverageMeter('Acc@5', ':6.2f')
    cnt = 0
    with torch.no_grad():
        for image, target in data_loader:
            output = model(image)
            loss = criterion(output, target)
            cnt += 1
            acc1, acc5 = accuracy(output, target, topk=(1, 5))
            print('.', end = '')
            top1.update(acc1[0], image.size(0))
            top5.update(acc5[0], image.size(0))
            if cnt >= neval_batches:
                 return top1, top5

    return top1, top5


def run_benchmark(model_file, img_loader):
    elapsed = 0
    model = torch.jit.load(model_file)
    model.eval()
    num_batches = 5
    # Run the scripted model on a few batches of images
    for i, (images, target) in enumerate(img_loader):
        if i < num_batches:
            start = time.time()
            output = model(images)
            end = time.time()
            elapsed = elapsed + (end-start)
        else:
            break
    num_images = images.size()[0] * num_batches

    print('Elapsed time: %3.0f ms' % (elapsed/num_images*1000))
    return elapsed


def get_imagenet_dataloader_official(batch_size=256, dataset_path=None):
    print('==> Using Pytorch Dataset')
    img_dir = dataset_path
    input_size = 224  # image resolution for resnets
    traindir = os.path.join(img_dir, 'train')
    valdir = os.path.join(img_dir, 'val')
    normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                     std=[0.229, 0.224, 0.225])

    torchvision.set_image_backend('accimage')
    train_dataset = datasets.ImageFolder(
        traindir,
        transforms.Compose([
            transforms.Resize(256),
            transforms.RandomCrop(input_size),
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor(),
            normalize,
        ]))

    train_loader = torch.utils.data.DataLoader(
        train_dataset, batch_size=batch_size, shuffle=True,
        num_workers=6, pin_memory=True)
    val_loader = torch.utils.data.DataLoader(
        datasets.ImageFolder(valdir, transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(input_size),
            transforms.ToTensor(),
            normalize,
        ])),
        batch_size=batch_size, shuffle=False,
        num_workers=6, pin_memory=True)
    return train_loader, val_loader

def prepare_data_loaders(data_path):
    traindir = os.path.join(data_path, 'train')
    valdir = os.path.join(data_path, 'val')
    normalize = transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                     std=[0.229, 0.224, 0.225])

    dataset = torchvision.datasets.ImageFolder(
        traindir,
        transforms.Compose([
            transforms.RandomResizedCrop(224),
            transforms.RandomHorizontalFlip(),
            transforms.ToTensor(),
            normalize,
        ]))
    print("dataset_train : %d" % (len(dataset)))

    dataset_test = torchvision.datasets.ImageFolder(
        valdir,
        transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            normalize,
        ]))
    print("dataset_test : %d" % (len(dataset_test)))

    train_sampler = torch.utils.data.RandomSampler(dataset)
    test_sampler = torch.utils.data.SequentialSampler(dataset_test)

    data_loader = torch.utils.data.DataLoader(
        dataset, batch_size=train_batch_size,
        sampler=train_sampler)

    data_loader_test = torch.utils.data.DataLoader(
        dataset_test, batch_size=eval_batch_size,
        sampler=test_sampler)

    return data_loader, data_loader_test

def evaluate(model, criterion, data_loader, neval_batches):
    model.eval()
    top1 = AverageMeter('Acc@1', ':6.2f')
    top5 = AverageMeter('Acc@5', ':6.2f')
    cnt = 0
    with torch.no_grad():
        for image, target in data_loader:
            output = model(image)
            loss = criterion(output, target)
            cnt += 1
            acc1, acc5 = accuracy(output, target, topk=(1, 5))
            print('.', end = '')
            top1.update(acc1[0], image.size(0))
            top5.update(acc5[0], image.size(0))
            if cnt >= neval_batches:
                 return top1, top5

    return top1, top5


def validate(val_loader, model, criterion):
    with torch.no_grad():
        batch_time = AverageMeter()
        losses = AverageMeter()
        top1 = AverageMeter()
        top5 = AverageMeter()

        # switch to evaluate mode
        model.eval()

        end = time.time()
        for i, (input, target) in enumerate(val_loader):
            target = target.cuda()
            input = input.cuda()

            # compute output
            output = model(input)
            loss = criterion(output, target)

            # measure accuracy and record loss
            prec1, prec5 = accuracy(output.data, target.data, topk=(1, 5))
            losses.update(loss.data.item(), input.size(0))
            top1.update(prec1.item(), input.size(0))
            top5.update(prec5.item(), input.size(0))

            # measure elapsed time
            batch_time.update(time.time() - end)
            end = time.time()

        #     print('Test: [{0}/{1}]\t'
        #               'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
        #               'Loss {loss.val:.4f} ({loss.avg:.4f})\t'
        #               'Acc@1 {top1.val:.3f} ({top1.avg:.3f})\t'
        #               'Acc@5 {top5.val:.3f} ({top5.avg:.3f})'.format(
        #                i, len(val_loader), batch_time=batch_time, loss=losses,
        #                top1=top1, top5=top5))

        # print(' * Acc@1 {top1.avg:.3f} Acc@5 {top5.avg:.3f}'
        #       .format(top1=top1, top5=top5))

        return top1.avg, top5.avg



# weights = ResNet50_QuantizedWeights.DEFAULT
# model = resnet50(weights=weights, quantize=True)

weights = ResNet18_QuantizedWeights.DEFAULT

model = resnet18(weights=weights, quantize=True)

device = torch.device("cuda")
model.to(device)
model.eval()
print(model)

# Select different layers here
# Names can be get in wgt_test_quant.ipynb
wgt_arr = model.layer1[0].conv2.weight().int_repr().cpu().detach().numpy()
print(wgt_arr)





conv1_essbit_mean, conv1_essbit_std = extract_bit_level(wgt_arr)
layer1_quant_v = Quantize_bit_level(wgt_arr)
print(wgt_arr.shape)
print(layer1_quant_v.shape)
layer1_quant_v = torch.from_numpy(layer1_quant_v).to(device)


model.layer1[0].conv2.weight = layer1_quant_v
quant_wgt_arr = model.layer1[0].conv2.weight.cpu().detach().numpy()


# conv1_essbit_mean, conv1_essbit_std = extract_bit_level(wgt_arr)
# fig, ax1 = plt.subplots(figsize=[4.0, 4.0])

# ax1.set_xlabel('Average Essential Bit', weight='bold', fontsize=8)
# ax1.set_ylabel('SD Essential Bit', weight='bold', fontsize=8)

# handle1, = ax1.plot(
#     conv1_essbit_mean,
#     conv1_essbit_std,
#     'o',
#     markersize=2.5,
#     color='mediumblue')

# ax1.set_ylim(bottom=0.00, top=3.00)
# ax1.set_xlim(left=0, right=5)
# ax1.grid(linestyle='--', linewidth=0.5)

# # handles = [handle1, handle2, handle3]
# # labels = [handle.get_label() for handle in handles]
# # ax1.legend(handles, labels, loc='upper center',
# #            fontsize='small', ncol=3, framealpha=0.5)

# fig.tight_layout()

# plt.savefig('essential_bits.pdf', bbox_inches='tight', transparent=True)
# plt.savefig('essential_bits.png')



"""
------------------------------
    Validation functions
------------------------------
"""

train_batch_size = 256
num_eval_batches = 250
eval_batch_size = 200

data_path = '/home/mnt/datasets/ImageNet2012'
data_loader, data_loader_test = get_imagenet_dataloader_official(batch_size=eval_batch_size,dataset_path=data_path)
criterion = nn.CrossEntropyLoss()

top1, top5 = evaluate(model, criterion, data_loader_test, neval_batches=num_eval_batches)
print('Final Evaluation accuracy on %d images, %2.2f'%(num_eval_batches * eval_batch_size, top1.avg))
