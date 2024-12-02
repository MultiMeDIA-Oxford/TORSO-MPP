# -*- coding: utf-8 -*-
"""
    torso_segmentor
    Written  for Colab by: Hannah Smith
    Modified for Python shell by: Abhirup Banerjee on 11th January, 2021

"""

import os
import torch
import torch.nn as nn
import torchvision.transforms.functional as TF
import torch.nn.functional as F
from torchvision import datasets, transforms
from torch.utils.data import Dataset, DataLoader
import PIL
from PIL import Image
import argparse

"""
from google.colab import drive
drive.mount('/content/gdrive')

torch.set_default_tensor_type('torch.cuda.FloatTensor')
"""

class ImageDataset(Dataset):
    '''
    Creates a dataset of images from filepaths
    No augmentation, just necessary resizing
    Returns the image name and the resized image as a tensor
    '''

    def __init__(self, image_paths):
        self.image_paths = image_paths

    def transform(self, image):
        # Resize
        resize = transforms.Resize(size=(128, 128))
        image = resize(image)

        # Transform to tensor
        # image = TF.to_tensor(image).cuda()
        image = TF.to_tensor(image).cpu()
        return image

    def __getitem__(self, index):
        image = Image.open(self.image_paths[index])
        image = self.transform(image)
        img_name = self.image_paths[index].split('/')[-1]
        return img_name, image

    def __len__(self):
        return len(self.image_paths)

class UNet(nn.Module):
    def __init__(self, n_channels, n_classes, bilinear=True):
        super(UNet, self).__init__()
        self.n_channels = n_channels
        self.n_classes = n_classes

        self.bilinear = bilinear #if UNet uses bilinear upsampling

        self.inc = DoubleConv(n_channels, 64)
        self.down1 = Down(64, 128)
        self.down2 = Down(128, 256)
        self.down3 = Down(256, 512)
        factor = 2 if bilinear else 1
        self.down4 = Down(512, 1024 // factor)
        self.up1 = Up(1024, 512 // factor, bilinear)
        self.up2 = Up(512, 256 // factor, bilinear)
        self.up3 = Up(256, 128 // factor, bilinear)
        self.up4 = Up(128, 64, bilinear)
        self.outc = OutConv(64, n_classes)

    def forward(self, x):
        x1 = self.inc(x)
        x2 = self.down1(x1)
        x3 = self.down2(x2)
        x4 = self.down3(x3)
        x5 = self.down4(x4)
        x = self.up1(x5, x4)
        x = self.up2(x, x3)
        x = self.up3(x, x2)
        x = self.up4(x, x1)
        # Added sigmoid activation layer to help binarise output
        logits = F.sigmoid(self.outc(x))
        return logits


class DoubleConv(nn.Module):
    """(Convolution -> Batch normalization -> ReLU activation) * 2"""

    def __init__(self, in_channels, out_channels, mid_channels=None):
        super().__init__()
        if not mid_channels:
            mid_channels = int(out_channels)
        self.double_conv = nn.Sequential(
            nn.Conv2d(int(in_channels), mid_channels, kernel_size=3, padding=1), #initial kernel 3
            nn.BatchNorm2d(mid_channels),
            nn.ReLU(inplace=True),
            nn.Conv2d(mid_channels, int(out_channels), kernel_size=3, padding=1), #initial kernel 3
            nn.BatchNorm2d(int(out_channels)),
            nn.ReLU(inplace=True)
        )

    def forward(self, x):
        return self.double_conv(x)


class Down(nn.Module):
    """Downscaling with maxpool then double conv"""

    def __init__(self, in_channels, out_channels):
        super().__init__()
        self.maxpool_conv = nn.Sequential(
            nn.MaxPool2d(2),
            DoubleConv(int(in_channels), int(out_channels))
        )

    def forward(self, x):
        return self.maxpool_conv(x)


class Up(nn.Module):
    """Upscaling then double conv"""

    def __init__(self, in_channels, out_channels, bilinear=True):
        super().__init__()

        # if bilinear, use the normal convolutions to reduce the number of channels
        if bilinear:
            self.up = nn.Upsample(scale_factor=2, mode='bilinear', align_corners=True)
            self.conv = DoubleConv(int(in_channels), int(out_channels), int(in_channels) // 2)
        else:
            self.up = nn.ConvTranspose2d(int(in_channels), int(in_channels) // 2, kernel_size=2, stride=2)
            self.conv = DoubleConv(int(in_channels), int(out_channels))


    def forward(self, x1, x2):
        x1 = self.up(x1)
        # input is CHW
        diffY = x2.size()[2] - x1.size()[2]
        diffX = x2.size()[3] - x1.size()[3]

        x1 = F.pad(x1, [diffX // 2, diffX - diffX // 2,
                        diffY // 2, diffY - diffY // 2])
        x = torch.cat([x2, x1], dim=1)
        return self.conv(x)


class OutConv(nn.Module):
    def __init__(self, in_channels, out_channels):
        super(OutConv, self).__init__()
        self.conv = nn.Conv2d(int(in_channels), int(out_channels), kernel_size=1)

    def forward(self, x):
        return self.conv(x)

#define directories input images are in and output segmented images are to be saved in
#****change here for input and output dirs****
"""
image_dir = '/content/gdrive/My Drive/1000037/torso-images'
segment_dir = '/content/gdrive/My Drive/1000037/1000037-seg-test'
"""
#define and load model
#****change here for model path****
"""
model_path = '/content/gdrive/My Drive/1000037/N15_cycle_4.pt'
"""
parser = argparse.ArgumentParser()
parser.add_argument('--dir_img', metavar='dir_img', required=True)
parser.add_argument('--dir_seg', metavar='dir_seg', default='')
parser.add_argument('--model_path', metavar='model_path', default='f:/Oxford_research_projects/Student-supervision/Hannah-Smith/Torso-MPP/PreTrained/N15_cycle_4.pt')
args = parser.parse_args()

image_dir = args.dir_img
if image_dir[-1] not in ["\\", "/"]:
    image_dir = '{0}/'.format(image_dir)

if args.dir_seg:
    segment_dir = args.dir_seg
else:
    (path, file)  = os.path.split(image_dir)
    (path, file)  = os.path.split(path)
    segment_dir = '{0}/torso-segment/'.format(path)
    del path, file

model_path  = args.model_path
if not os.path.isdir(segment_dir):
    os.mkdir(segment_dir)

[model, x_valid_paths, train_losses, valid_losses]  = torch.load(model_path, map_location=torch.device('cpu'))

#images into data loader
image_filepaths = sorted([f.path for f in os.scandir(image_dir) if f.is_file()])
test_dataset = ImageDataset(image_filepaths)
test_loader = DataLoader(test_dataset, batch_size=1000, shuffle=False)

#iterate over test loader making image segmentations and binarising them
with torch.no_grad():
    for b, (img_names, images) in enumerate(test_loader):
        y_results = model(images)
        y_results[y_results < 0.5] = 0
        y_results[y_results > 0.5] = 1

        #converts segmentations into PIL images and saves them
        for i, result in enumerate(y_results):
          name = img_names[i]
          save_path = os.path.join(segment_dir, name)
          img = transforms.ToPILImage()(result[0].cpu())
          img.save(save_path)
