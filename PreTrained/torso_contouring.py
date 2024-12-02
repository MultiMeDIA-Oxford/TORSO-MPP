
"""
    Torso Contouring
    Written  for Colab by: Hannah Smith
    Modified for Python shell by: Abhirup Banerjee on 4th July, 2021

"""

import os
from os import listdir
from os.path import isfile, join
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import datasets, transforms
from torch.utils.data import Dataset, DataLoader
from torchvision.utils import make_grid
import torchvision.transforms.functional as TF
import PIL
from PIL import Image, ImageEnhance
import matplotlib.pyplot as plt
import argparse

"""
torch.set_default_tensor_type('torch.cuda.FloatTensor')
"""

class UNet(nn.Module):
    def __init__(self, n_channels, n_classes, bilinear=True):
        super(UNet, self).__init__()
        self.n_channels = n_channels
        self.n_classes = n_classes

        self.bilinear = bilinear #if unet uses bilinear upsampling

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
        # if you have padding issues, see
        # https://github.com/HaiyongJiang/U-Net-Pytorch-Unstructured-Buggy/commit/0e854509c2cea854e247a9c615f175f76fbb2e3a
        # https://github.com/xiaopeng-liao/Pytorch-UNet/commit/8ebac70e633bac59fc22bb5195e513d5832fb3bd
        x = torch.cat([x2, x1], dim=1)
        return self.conv(x)


class OutConv(nn.Module):
    def __init__(self, in_channels, out_channels):
        super(OutConv, self).__init__()
        self.conv = nn.Conv2d(int(in_channels), int(out_channels), kernel_size=1)

    def forward(self, x):
        return self.conv(x)


#Dataset class - c_full is full contours without anything removed
class UNet2Dataset(Dataset):

    def __init__(self, image_paths, c_full_paths):
        self.image_paths = image_paths
        self.c_full_paths = c_full_paths


    def transform(self, image, c_full):
        # Resize
        resize = transforms.Resize(size=(128, 128))
        image = resize(image)
        c_full = resize(c_full)
        c_full = c_full.convert('L')

        # binarise
        # image = TF.to_tensor(image).cuda()
        # c_full = TF.to_tensor(c_full).cuda()
        image = TF.to_tensor(image).cpu()
        c_full = TF.to_tensor(c_full).cpu()
        c_full[c_full < 0.1] = 0
        c_full[c_full > 0.1] = 1

        return torch.cat((image, c_full))

    def __getitem__(self, index):
        image = Image.open(self.image_paths[index])
        c_full = Image.open(self.c_full_paths[index])

        image = self.transform(image, c_full)
        img_name = self.image_paths[index].split('/')[-1]
        return img_name, image

    def __len__(self):
        return len(self.image_paths)

def run_model(model_path, data_dir):

  [model, valid_paths, train_losses, valid_losses] = torch.load(model_path, map_location=torch.device('cpu'))

  # images into data loader
  x_paths  = sorted([ f.path for f in os.scandir(data_dir) if f.is_file()])
  cf_paths = [sub.replace('torso-images', 'torso-contours-full') for sub in x_paths]

  test_dataset = UNet2Dataset(x_paths, cf_paths)
  test_loader = DataLoader(test_dataset, batch_size=1, shuffle=False)

  (path, file)  = os.path.split(data_dir)
  (path, file)  = os.path.split(path)
  segment_dir = '{0}/torso-contouring/'.format(path)
  del path, file

  if not os.path.isdir(segment_dir):
      os.mkdir(segment_dir)

  with torch.no_grad():
    for b, (img_names, x_test) in enumerate(test_loader):
      y_result = model(x_test)
      y_result[y_result < 0.5] = 0
      y_result[y_result > 0.5] = 1

      # converts segmentations into PIL images and saves them
      img = transforms.ToPILImage()(y_result[0].cpu())
      img.save(os.path.join(segment_dir, img_names[0]))

#performs the contouring
parser = argparse.ArgumentParser()
parser.add_argument('--dir_img', metavar='dir_img', required=True)
parser.add_argument('--model_path', metavar='model_path', default='d:/Oxford_research_projects/Student-supervision/Hannah-Smith/Torso-MPP/PreTrained/torso_cnt_N65_35_cycle_2.pt')
args = parser.parse_args()

data_dir = args.dir_img
model_path = args.model_path
if data_dir[-1] not in ["\\", "/"]:
    data_dir = '{0}/'.format(data_dir)

run_model(model_path, data_dir)
