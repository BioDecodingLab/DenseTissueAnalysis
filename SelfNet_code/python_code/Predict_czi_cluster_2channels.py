#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#%%
######PACKAGES

from Supporting_functions import *
import time
from aicsimageio.readers import CziReader
from aicsimageio.writers import OmeTiffWriter
from aicsimageio import AICSImage
import re
import scipy.ndimage as ndi


### Predictions for a czi file

if __name__=='__main__':

    # Input parameters

    parser=argparse.ArgumentParser(description='Self_Net')

    parser.add_argument('--NucleiChannelId',type=int,default=0)
    parser.add_argument('--MembraneChannelId',type=int,default=1)
    parser.add_argument('--modelName',default=r'nuclei2nuclei')
    parser.add_argument('--modelId',default=r'deblur_net_22_7200.pkl')
    parser.add_argument('--modelName2',default=r'membranes2membranes')
    parser.add_argument('--modelId2',default=r'deblur_net_17_13200.pkl')   
    parser.add_argument('--path', default=r'/home/hmorales/WorkSpace/DataIsoReconstructions/')
    parser.add_argument('--img_src_path', default=r'/run/user/1000/gvfs/smb-share:server=134.34.176.179,share=pmtest_fast/Cornelius/pErk/20230913/sample1/pErk_913_2023_09_13__11_25_02_047(62).czi')
    parser.add_argument('--outdir', default=r'/media/hmorales/Skynet/Isotropic/')  
    parser.add_argument('--batch_size',type=int,default=4)
    parser.add_argument('--min_v', type=int, default=0)
    parser.add_argument('--max_v', type=int, default=65535)

    args=parser.parse_args()



    # Define variables and paths

    NucleiChannelId = args.NucleiChannelId
    MembraneChannelId = args.MembraneChannelId
    modelName = args.modelName
    modelId = args.modelId
    modelName2 = args.modelName2
    modelId2 = args.modelId2    
    angles = ['023', '068', '203', '338']
    path = args.path


    # image path 
    czi_file_path = args.img_src_path 

    # Models
    srcpath  = path+modelName+'/'
    srcpath2 = path+modelName2+'/'
    
    model_path  = srcpath+'checkpoint/saved_models/deblur/'+modelId
    model_path2 = srcpath2+'checkpoint/saved_models/deblur/'+modelId2


    #output dir
    outdir = args.outdir

    # CUDA device
    batch_size = args.batch_size

    # Image Normalization
    min_v = args.min_v
    max_v = args.max_v
    norm_percentiles = (50.0, 99.999)  #99.9995 For Nuclei, 99.999 For Membranes
    norm_percentiles_out = (50.0, 99.999)  #99.9995 For Nuclei, 99.999 For Membranes
    crop_for_calculations = True
    thres_crop = 1.2



    # Create output folder
    if not os.path.exists(outdir):
        os.mkdir(outdir)




    start_time = time.time()  # Record the start time 

    # get image path 
    print("image:", czi_file_path)
    reader = CziReader(czi_file_path)


    match = re.search(r'\((\d+)\)', czi_file_path)
    timeId = match.group(1)
    timeId= timeId.zfill(3)
    print('spim_TL'+str(timeId))

    for view in range(reader.dims.V): 
        print("Processing view : ", str(view), " : ", str(angles[view]))
        for color in range(reader.dims.C): 

            start_time = time.time()  # Record the start time 
            # Open image
            lazy_t0 = reader.get_image_dask_data("ZYX", V=view, C=color)  # returns 3D ZYX numpy array
            img = lazy_t0.compute()  # returns in-memory 4D numpy array
            img = img.astype(np.uint16)
            scale = reader.physical_pixel_sizes.X / reader.physical_pixel_sizes.Z
            print(img.shape)


            # Make isotropic image and predict nuclei
            if color == NucleiChannelId or color == MembraneChannelId:

		# Prepare GPU 
                torch.cuda.empty_cache()
                device1 = torch.device('cuda:0')
                device2 = torch.device('cuda:0')
                torch.cuda.empty_cache()

                # Prepare networks
                deblur_net_A = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device1,use_dropout=False,norm='instance')
                deblur_net_B = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device2,use_dropout=False,norm='instance')

                 # Load Model
                if color == NucleiChannelId :  
		        deblur_net_A.load_state_dict(torch.load(model_path))
		        deblur_net_B.load_state_dict(torch.load(model_path))

                if color == MembraneChannelId :  
		        deblur_net_A.load_state_dict(torch.load(model_path2))
		        deblur_net_B.load_state_dict(torch.load(model_path2))
		        

                # crop for calculations
                z,y,x=img.shape
                if crop_for_calculations == True:
                    raw_img = img
                    bounds_min, bounds_max = get_image_cropping_box(raw_img, 2.0, scale, thres_crop)          
                    img = raw_img[bounds_min[0]:bounds_max[0], bounds_min[1]:bounds_max[1], bounds_min[2]:bounds_max[2]]

                # Normalize 
                img = image_preprocessing(img, norm_percentiles, min_v, max_v)

                # Predict image
                fusion_stack = upsample_block(img,scale,1,deblur_net_A,deblur_net_B,min_v,max_v, device1, device2,batch_size)              

                # put image back 
                if crop_for_calculations == True:
                    scale_img=reslice(raw_img,'xy',reader.physical_pixel_sizes.X,reader.physical_pixel_sizes.Z)
                    scale_img[round(bounds_min[0]/scale):round(bounds_max[0]/scale), bounds_min[1]:bounds_max[1], bounds_min[2]:bounds_max[2]] = fusion_stack
                    fusion_stack = scale_img

                # Normalize output
                fusion_stack = image_preprocessing(fusion_stack,norm_percentiles_out, min_v, max_v)
                
            else:
                fusion_stack=reslice(img,'xy',reader.physical_pixel_sizes.X,reader.physical_pixel_sizes.Z)


            # Save image
            fusion_stack = fusion_stack.astype(np.uint16)
            print(fusion_stack.shape)
            outName = 'spim_TL'+str(timeId)+'_Channel'+str(color)+'_Angle'+angles[view]+'.tif'
            img_out = os.path.join(outdir, outName)            
            tifffile.imwrite(      
            img_out,
            fusion_stack,
            imagej=True, 
            bigtiff=True,
            resolution=(1.0/reader.physical_pixel_sizes.X, 1.0/reader.physical_pixel_sizes.Y), 
            metadata={'spacing': reader.physical_pixel_sizes.X, 'unit': 'um', 'axes': 'ZYX'})


            Elapsed_time = time.time() - start_time
            print(f"Elapsed Time: {Elapsed_time:.4f} seconds, image {outName}")                  
 

