#!/usr/bin/env python
# coding: utf-8

# In[1]:


from Supporting_functions import *
from aicsimageio.readers import CziReader
from aicsimageio.writers import OmeTiffWriter
import re
import scipy.ndimage as ndi
from WBNS import WBNS_image
import RedLionfishDeconv as rl


# # Predictions for a folder

# In[2]:


# Define paths

NucleiMembranesChannelId = 0
modelNameNuclei       = 'NucleiMembrane2Nuclei'
modelNameMembranes    = 'NucleiMembrane2Membrane'
modelNameIsoNuclei    = 'Self_Nuclei'
modelNameIsoMembranes = 'Self_Membranes'
modelNameIsoNucleiMem = 'Self_Nuclei_Membrane'


modelIdNuclei       = 'deblur_net_8_72000.pkl'
modelIdMembranes    = 'deblur_net_8_96000.pkl'
modelIdIsoNuclei    = 'deblur_net_4_8000.pkl'
modelIdIsoMembranes = 'deblur_net_2_8000.pkl'
modelIdIsoNucleiMem = 'deblur_net_12_64000.pkl'



angles = ['000', '060', '120', '180', '240', '300'] #['010', '145', '280', '325']


# Models
srcpath = r'/media/hmorales/Skynet/IsoNet/Models/'
model_path_Nuclei    = srcpath+modelNameNuclei+'/'+'checkpoint/saved_models/'+modelIdNuclei
model_path_Membranes = srcpath+modelNameMembranes+'/'+'checkpoint/saved_models/'+modelIdMembranes

model_path_IsoNuclei       = srcpath+modelNameIsoNuclei+'/'+'checkpoint/saved_models/'+modelIdIsoNuclei
model_path_IsoMembranes    = srcpath+modelNameIsoMembranes+'/'+'checkpoint/saved_models/'+modelIdIsoMembranes
model_path_IsoNucleiMem    = srcpath+modelNameIsoNucleiMem+'/'+'checkpoint/saved_models/'+modelIdIsoNucleiMem


# Image to test
img_src_path = '/media/hmorales/Skynet/IsoNet/test/'


#output dir
outdir = '/media/hmorales/MyBookDuo/Data/IsoNet/test/Isotropic/' #'/media/hmorales/Skynet/IsoNet/test/Isotropic/' #/run/user/1000/gvfs/smb-share:server=134.34.176.179,share=pmtest_fast/Cornelius/pErk/20230913/Isotropic/'

# CUDA device
device1 = torch.device('cuda:0')
device2 = torch.device('cuda:0')
batch_size = 6

skip_planes = 0   # for Nuclei Prediction
skip_planes2 = 0  # for Membranes Prediction
        
# Image Normalization
min_v = 0
max_v = 65535
norm_percentiles =  (20, 99.999)  #99.9995 For Nuclei, 99.999 For Membranes
norm_percentiles_out = (50.0, 99.999)  #99.9995 For Nuclei, 99.999 For Membranes
crop_for_calculations = True
thres_crop = 1.5
blur_mask = 2.0

# post processing

# BG subtraction
resolution_px = 0 # FWHM of the PSF
noise_lvl = 2
sigma = 0.0

# deconvolution
padding = 32
Niter = 5
psf_path = r'/home/hmorales/WorkSpace/DataIsoReconstructions/Averaged_transformed_PSF_561.tif'

# Create output folder
if not os.path.exists(outdir):
    os.mkdir(outdir)
      
    

# Open PSF and Prepare PSF
psf = tifffile.imread(psf_path)
psf_f = psf.astype(np.float32)
psf_norm = psf_f/psf_f.sum()


# In[3]:


def open_image_from_reader(reader, view, color, order="ZYX", out_type=np.uint16):
    
    lazy_t0 = reader.get_image_dask_data(order, V=view, C=color)  # returns 3D ZYX numpy array
    img = lazy_t0.compute()  # returns in-memory 4D numpy array
    img = img.astype(out_type)
    
    return img, reader.physical_pixel_sizes.X, reader.physical_pixel_sizes.Z


# In[4]:


# Prepare networks
net_Nuclei    = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device1,use_dropout=False,norm='instance')
net_Membranes = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device1,use_dropout=False,norm='instance')

net_IsoNuclei    = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device1,use_dropout=False,norm='instance')
net_IsoMembranes = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device1,use_dropout=False,norm='instance')

#net_IsoNucleiMem = Self_net_architecture.define_G(input_nc=1, output_nc=1, ngf=64, netG='deblur_net', device=device1,use_dropout=False,norm='instance')


# Load Model
net_Nuclei.load_state_dict(torch.load(model_path_Nuclei))
net_Membranes.load_state_dict(torch.load(model_path_Membranes))

net_IsoNuclei.load_state_dict(torch.load(model_path_IsoNuclei))
net_IsoMembranes.load_state_dict(torch.load(model_path_IsoMembranes))
#net_IsoNucleiMem.load_state_dict(torch.load(model_path_IsoNucleiMem))


# In[ ]:


# Get all tif images in the folder
image_names = sorted([f for f in os.listdir(img_src_path) if f.endswith('.czi')])

for i, image_name in enumerate(image_names):
       
    # get image path 
    czi_file_path = os.path.join(img_src_path, image_name)   
    reader = CziReader(czi_file_path)
    
    # Get time Id 
    match = re.search(r'\((\d+)\)', image_name)
    timeId = match.group(1)
    timeId= timeId.zfill(3)
    
    print(f"Processing image : {image_name}")

    for view in range(0,reader.dims.V ):      
        print(f"** Processing view : {view}")
        
        # Get general mask form NucleiMembranesChannel
        print(f"Getting tissue mask ...")
        start_time = time.time()
        # Open image
        img, pixel_size_X, pixel_size_Z = open_image_from_reader(reader, view, NucleiMembranesChannelId, "ZYX", np.uint16)
        pixel_size_X = 2.0* pixel_size_X #!!!!!!!!!!!!!!!!!!!!! delete Error in objective
        scale = pixel_size_X / pixel_size_Z
        
        # Get mask
        if crop_for_calculations == True:
            bounds_min, bounds_max, mask = get_image_cropping_box(img, blur_mask, scale, thres_crop)                     
        else:
            mask = get_image_simple_mask(img, blur_mask, scale, thres_crop)
            
        # create empty output image as template
        z,y,x = img.shape
        new_z = round(z / scale) 
        base_img  = np.zeros((new_z,y,x))
        Elapsed_time = time.time() - start_time
        print(f"Elapsed Time masking: {Elapsed_time:.4f} seconds")      
    
        # Process color by color
        
        for color in range(reader.dims.C): 
            print("Processing color : ", str(color))
            
            start_time = time.time()  # Record the start time 
            # Open image
            raw_img, pixel_size_X, pixel_size_Z = open_image_from_reader(reader, view, color, "ZYX", np.uint16)
            pixel_size_X = 2.0* pixel_size_X #!!!!!!!!!!!!!!!!!!!!! delete Error in objective
            scale = pixel_size_X / pixel_size_Z

            #  Predict nuclei, membranes and make isotropic image
            if color == NucleiMembranesChannelId:
                
                # prepare image for calculations
                if crop_for_calculations == True:
                    img = raw_img[bounds_min[0]:bounds_max[0], bounds_min[1]:bounds_max[1], bounds_min[2]:bounds_max[2]]
                    # get mask for beads           
                    imgBeads =  img * (~mask)
                else:
                    img = raw_img
                    imgBeads =  raw_img * (~mask)

                # Normalize 
                low_thres, high_thres = getNormalizationThresholds(img, norm_percentiles)
                img = remove_outliers_image(img, low_thres, high_thres)
                img, scaleI = image_get_scaling(img, min_v, max_v)
                print("scaleI : ", scaleI)
        
                # Predict image
                imgNuclei = predict_stack(img,net_Nuclei,    min_v, max_v, device1, batch_size)
                imgCells  = predict_stack(img,net_Membranes, min_v, max_v, device1, batch_size)
                
                imgNuclei = imgNuclei * mask
                imgCells  = imgCells  * mask
                
                # Isotropic prediction 

                imgNuclei = upsample_block(imgNuclei,pixel_size_X,pixel_size_Z,net_IsoNuclei,   net_IsoNuclei,   min_v,max_v, device1, device2, batch_size, skip_planes)              
                imgCells  = upsample_block(imgCells, pixel_size_X,pixel_size_Z,net_IsoMembranes,net_IsoMembranes,min_v,max_v, device1, device2, batch_size, skip_planes2)              
            
                # Re-scale intensities
                imgNuclei  = imgNuclei.astype(np.float32).astype(np.float32) / scaleI
                imgCells   = imgCells.astype(np.float32) / scaleI
                imgNuclei  = imgNuclei.astype(np.uint16)
                imgCells   = imgCells.astype(np.uint16)

               
                # put image back 
                if crop_for_calculations == True:   
                    ''' 
                    # if not isotropic prediction is done
                    base_img = np.zeros_like(raw_img)
                    imgNuclei = insert_predicted_image(base_img,imgNuclei,bounds_min,bounds_max,1.0)
                    imgCells = insert_predicted_image(base_img,imgCells, bounds_min,bounds_max,1.0)
                    imgBeads = insert_predicted_image(raw_img,imgBeads,bounds_min,bounds_max,1.0)
                    '''
                    imgNuclei = insert_predicted_image(base_img,imgNuclei,bounds_min,bounds_max,scale)
                    imgCells  = insert_predicted_image(base_img,imgCells, bounds_min,bounds_max,scale)
                    imgBeads  = insert_predicted_image(raw_img,imgBeads,bounds_min,bounds_max,1.0)              

                    
                # Make images isotropic 
                '''
                # if not isotropic prediction is done
                imgNuclei = reslice(imgNuclei,'xy',pixel_size_X,pixel_size_Z)
                imgCells  = reslice(imgCells,'xy',pixel_size_X,pixel_size_Z)
                '''
                imgBeads  = reslice_bysize(imgBeads,'xy',new_z)    
                    

                if Niter > 10: 
                    # Padding image
                    imgBeads = np.pad(imgBeads, padding, mode='reflect')
                    imgSizeGB = imgBeads.nbytes / (1024 ** 3)
                    print('     -size(GB) : ', imgSizeGB)
                    # GPU deconvolution
                    res_gpu = rl.doRLDeconvolutionFromNpArrays(imgBeads, psf, niter=Niter,resAsUint8=False)
                    # Removing padding
                    imgBeads = res_gpu[padding:-padding, padding:-padding, padding:-padding]
            
                # Normalize output
                #imgNuclei     = image_normalizing(imgNuclei,norm_percentiles_out, min_v, max_v)
                #imgCells      = image_normalizing(imgCells,norm_percentiles_out, min_v, max_v)
                #imgNucleiTemp = image_normalizing(imgNucleiTemp,norm_percentiles_out, min_v, max_v)

                # Remove noise and BG
                if resolution_px > 0:
                    imgNuclei = WBNS_image(imgNuclei, resolution_px, noise_lvl)
                    imgCells = WBNS_image(imgCells, resolution_px, noise_lvl)

                # Smooth
                if sigma > 0:
                    imgNuclei = ndi.gaussian_filter(imgNuclei, sigma)
                    imgCells = ndi.gaussian_filter(imgCells, sigma)
                
                # Save image
                outName = 'spim_TL'+str(timeId)+'_Channel'+str(color+2)+'_Angle'+angles[view]+'.tif'        
                custom_save_img(imgNuclei, outdir, outName, pixel_size_X,pixel_size_X, pixel_size_X)
                outName = 'spim_TL'+str(timeId)+'_Channel'+str(color+3)+'_Angle'+angles[view]+'.tif'        
                custom_save_img(imgCells, outdir, outName, pixel_size_X,pixel_size_X, pixel_size_X)
                outName = 'spim_TL'+str(timeId)+'_Channel'+str(color+4)+'_Angle'+angles[view]+'.tif'        
                custom_save_img(imgBeads, outdir, outName, pixel_size_X,pixel_size_X, pixel_size_X)
                 

            else:
                
                if crop_for_calculations == True:
                    img = raw_img[bounds_min[0]:bounds_max[0], bounds_min[1]:bounds_max[1], bounds_min[2]:bounds_max[2]]
                else:
                    img = raw_img
                
                fusion_stack=reslice(img,'xy',pixel_size_X,pixel_size_Z)
               # fusion_stack=ndi.zoom(img, ( 1/scale,1,1))

                if Niter > 0:       
                    # Padding image
                    fusion_stack = np.pad(fusion_stack, padding, mode='reflect')
                    imgSizeGB = fusion_stack.nbytes / (1024 ** 3)
                    print('     -size(GB) : ', imgSizeGB)
                    # GPU deconvolution
                    res_gpu = rl.doRLDeconvolutionFromNpArrays(fusion_stack, psf, niter=Niter,resAsUint8=False)
                    # Removing padding
                    fusion_stack = res_gpu[padding:-padding, padding:-padding, padding:-padding]
                                 
                if crop_for_calculations == True:
                    fusion_stack = insert_predicted_image(base_img,fusion_stack,bounds_min,bounds_max,scale)
                    
                outName = 'spim_TL'+str(timeId)+'_Channel'+str(color)+'_Angle'+angles[view]+'.tif'        
                custom_save_img(fusion_stack, outdir, outName, pixel_size_X,pixel_size_X, pixel_size_X)
  
  
            Elapsed_time = time.time() - start_time
            print(f"Elapsed Time: {Elapsed_time:.4f} seconds, image {outName}")                  
 


# In[ ]:





# In[ ]:


imgNuclei.shape


# In[ ]:


'''
scale_img = reslice(raw_img,'xy',reader.physical_pixel_sizes.X,reader.physical_pixel_sizes.Z)            
beads_image =  img * (~mask)
beads_image = insert_predicted_image(scale_img,beads_image,bounds_min,bounds_max,1.0)


outName = 'spim_TL'+str(timeId)+'_Channel'+str(color+2)+'_Angle'+angles[view]+'.tif'        
custom_save_img(beads_image, outdir, outName, reader.physical_pixel_sizes.X, reader.physical_pixel_sizes.Y, reader.physical_pixel_sizes.Z)
'''


# In[ ]:




