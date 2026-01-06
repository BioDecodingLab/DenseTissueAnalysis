#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#%%
######PACKAGES

from Supporting_functions import *
from WBNS import *
import time
from aicsimageio.readers import CziReader
from aicsimageio.writers import OmeTiffWriter
from aicsimageio import AICSImage
import re
import scipy.ndimage as ndi


### Predictions for a czi file

if __name__=='__main__':

    # Input parameters

    parser = argparse.ArgumentParser(description='Self_Net')
    parser.add_argument('--ChannelIds',  nargs='+', type=int, default=[0, 0])
    parser.add_argument('--model_path', default=r'/home/hmorales/WorkSpace/DataIsoReconstructions/')
    parser.add_argument('--modelNames',  nargs='*', default=['nuclei2nuclei', 'nuclei2nuclei_leftdistorted'])
    parser.add_argument('--modelIds',    nargs='*', default=['deblur_net_22_7200.pkl', 'deblur_net_4_21600.pkl'])
    parser.add_argument('--img_src_path', default=r'/Cornelius/pErk/20230913/sample1/sample_13__11_25_02_047(62).czi')
    parser.add_argument('--outdir', default=r'/media/hmorales/Skynet/Isotropic/')  
    parser.add_argument('--batch_size',type=int,default=4)
    parser.add_argument('--min_v', type=int, default=0)
    parser.add_argument('--max_v', type=int, default=65535)
    parser.add_argument('--angles',  nargs='*', default=['023', '068', '203', '338'])
    parser.add_argument('--norm_percentiles', nargs='+', type=float, default=[50.0, 99.9995])
    parser.add_argument('--norm_percentiles_out', nargs='+', type=float, default=[50.0, 99.999])
    
    # Define variables and paths
    args=parser.parse_args()

    ChannelIds = args.ChannelIds    
    modelNames = args.modelNames
    modelIds = args.modelIds
    angles = args.angles
    path = args.model_path

    # image path 
    czi_file_path = args.img_src_path 

    # Model paths
    model_paths = []
    for modelName, modelId in zip(modelNames,modelIds):
        model_paths.append(path+modelName+'/checkpoint/saved_models/deblur/'+modelId)
       
    #output dir
    outdir = args.outdir

    # CUDA device
    batch_size = args.batch_size

    # Image Normalization
    min_v = args.min_v
    max_v = args.max_v
    norm_percentiles = (50.0, 99.9995)  #99.9995 For Nuclei, 99.999 For Membranes
    norm_percentiles_out = (50.0, 99.999)  #99.9995 For Nuclei, 99.999 For Membranes

    # Pre-processing
    crop_for_calculations = True
    thres_crop = 1.2
    blurWnd = 2.0
    #overlap = 32
    removeBG = True
    resolution_px = 10
    noise_lvl = 2



    # Create output folder
    if not os.path.exists(outdir):
        os.mkdir(outdir)


    ## Start calculations

    start_time = time.time()  # Record the start time 

    # get image path 
    print("image:", czi_file_path)
    reader = CziReader(czi_file_path)


    match = re.search(r'\((\d+)\)', czi_file_path)
    timeId = match.group(1)
    timeId= timeId.zfill(3)
    print('spim_TL'+str(timeId))


    

    for color in range(reader.dims.C): 
    
    
    
    

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
            if color == NucleiChannelId:

		# Prepare GPU 
                torch.cuda.empty_cache()
                device1 = torch.device('cuda:0')
                device2 = torch.device('cuda:0')
                device3 = torch.device('cuda:0')
                device4 = torch.device('cuda:0')                
                torch.cuda.empty_cache()

                # Prepare networks
                deblur_net_A = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device1,use_dropout=False,norm='instance')
                deblur_net_B = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device2,use_dropout=False,norm='instance')
                deblur_net_C = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device3,use_dropout=False,norm='instance')
                deblur_net_D = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device4,use_dropout=False,norm='instance')

                 # Load Model
                deblur_net_A.load_state_dict(torch.load(model_path))
                deblur_net_B.load_state_dict(torch.load(model_path))
                deblur_net_C.load_state_dict(torch.load(model_path2))
                deblur_net_D.load_state_dict(torch.load(model_path2))
                
                # WBNS_image(image, resolution_px, noise_lvl=1):
                
                if removeBG == True:
               	    img_noBG = WBNS_image(img, resolution_px, noise_lvl)
		else:
		    img_noBG = img	
		
                # crop for calculations
                z,y,x=img.shape
                if crop_for_calculations == True:
                    bounds_min, bounds_max = get_image_cropping_box(img, blurWnd, scale, thres_crop)          
                    img = img_noBG[bounds_min[0]:bounds_max[0], bounds_min[1]:bounds_max[1], bounds_min[2]:bounds_max[2]]
                    

                # Normalize 
                img = image_preprocessing(img, norm_percentiles, min_v, max_v)

                # Predict image 
                
                img_dim = img.shape
                x2 = int(0.5 * img_dim[1])
                #subimg1 = img[:,:,:x2+overlap]
                #subimg2 = img[:,:,x2-overlap:]
                subimg1 = img[:,:,:x2]
                subimg2 = img[:,:,x2:]                
                
                fusion_stack_left  = upsample_block(subimg1,scale,1,deblur_net_C,deblur_net_D,min_v,max_v, device3, device4,batch_size)
                fusion_stack_rigth = upsample_block(subimg2,scale,1,deblur_net_A,deblur_net_B,min_v,max_v, device1, device2,batch_size)
                fusion_stack_left  = image_preprocessing(fusion_stack_left,norm_percentiles_out, min_v, max_v)
                fusion_stack_rigth = image_preprocessing(fusion_stack_rigth,norm_percentiles_out, min_v, max_v)

                #fusion_stack = np.concatenate((fusion_stack_left[:,:,:x2], fusion_stack_rigth[:,:,overlap:]), axis=2)
                fusion_stack = np.concatenate((fusion_stack_left, fusion_stack_rigth), axis=2)

                # put image back 
                if crop_for_calculations == True:
                    scale_img = reslice(img_noBG,'xy',reader.physical_pixel_sizes.X,reader.physical_pixel_sizes.Z)
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
 

