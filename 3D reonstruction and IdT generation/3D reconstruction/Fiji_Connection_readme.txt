Using MotionTracking version:
- 8.97.00

1) During installation, a window appears that says
- Database Logon:zerial-srv-1
- Remote Host Account: rink
- Password: rink-1

2) The Plide can be found at:
- C:\MotionTracking\bin64\plide
(right-click and create a shortcut on the desktop)

3) Start Plide with MT:
Open Plide. Run > connect > type motiontracking64 in "Application". 
Then open MT and immediately press OK in the Plide window where the information was entered.

4) Bioformat in MT.
- Install Fiji
- Install Java (jdk-8u261-windows-x64, see Bioimage Archive repository, Dataset/Mask_sets/Idealized_tissue_masks/MT_Script/jdk-8u261-windows-x64.exe)
- To connect MT with Fiji, search in the Windows search bar for "env" (Edit the system environment variables). 
  Advanced options > Environment Variables > Path

Double-click and add the paths where Java is located:
C:\Program Files\Java\jdk1.8.0_261\bin
and
C:\Program Files\Java\jdk1.8.0_261\jre\bin\server

- When opening MT and selecting the Bioformat import option, MT will ask for the Fiji path:
C:\Users\Gaming\Desktop\Fiji.app\
C:\Users\SuperServer\Desktop\fiji-win64\Fiji.app (This is another example. The important thing is to reach the part where several folders are shown, such as: Contents, downloads, etc.)



