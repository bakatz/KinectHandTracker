KinectHandTracker
=================

Prerequisites:
-Xcode 4
-Mac OSX Lion (10.7)
-MacPorts (dmg available here: <https://distfiles.macports.org/MacPorts/MacPorts-2.0.3-10.7-Lion.dmg>)
-All the folders included on the kinect git repository


Part 1: Install libusb from MacPorts
In Terminal, run the following commands, in order, after installing MacPorts from the dmg file above:
1. `sudo port install libtool`
2. `sudo port install libusb-devel +universal`

The second command is important -- make sure you have the +universal flag on the end.

Part 2: Install PrimeSense OpenNI
Open the “OpenNI-Unstable” folder from the kinect repository, and run the following commands:
1. `chmod +x install.sh`
2. `sudo ./install.sh`
If successful, the install script copies key files to the following location:
  	       Libs into: `/usr/lib`
		       Bins into: `/usr/bin`
		       Includes into: `/usr/include/ni`
		       Config files into: `/var/lib/ni`

Part 3: Install SensorKinect
Open the “SensorServer” folder from the kinect repository, and run the following commands:
1. `chmod +x install.sh`
2. `sudo ./install.sh`

Part 4: Install PrimeSense NITE Middleware
Open the “nite” folder from the kinect repository.
1. Navigate to `nite/Hands_1_4_1/Data/` and open `Nite.ini`
2. Make sure the lines about detecting hands are uncommented, and save the file.
3. Go back to the nite root folder and:
4. `chmod +x install.sh`
5. `sudo ./install.sh`
This script will copy the libs to /usr/lib. The include files will be left in the nite directory.

Part 5: Test OpenNI/NITE/Kinect installation

Open the `nite\Samples\Bin\Debug` directory, and run the following command:
`./Sample-PointViewer`

You should see output from the kinect camera, and when you wave your hand, OpenNI/NITE should start tracking your hand. If this does not happen, you should go back and check your installation before continuing.

Part 6: Set up Xcode project
1. Open Xcode 4, and click open an existing project. Browse to the `webkit-plugin-mac` folder from the kinect repository, and select the directory ending in .xcodeproj to be the existing project to open.

2. Do not build the project yet! Click on the `webkit-plugin-mac` header and navigate to Build Settings. 

3. In the search box, search for `header` and you should come up with `header search paths.` You will notice the header path for NITE is set to some directory on my computer. You will need to change this to the location you downloaded nite from the repository, specifically <YOUR_NITE_PATH>/Include

4. Build the Xcode project. It should come up with a large number of warnings, but no errors, and you should receive a “BUILD SUCCESSFUL” message if everything went OK.

Part 7: Run the demo application
1. Navigate to `webkit-plugin-mac/build/Debug/webkit-plugin-mac.webplugin/Contents/MacOS` if your Xcode is set up to build to the working directory, or wherever you normally build your Xcode projects otherwise.

2. Run `./webkit-plugin-mac`, and step a little bit back from the Kinect camera -- the depth sensor is not good when you are too close to the camera.

3. You should see a 3D cube come up, and after a second or two, a message about “openni thread started” in the console. At this point, wave your hand until you see a “new session *” message in the console.

4. Move your hand around to move the cube around. If you put your other hand up and then move both hands left or right, a different cube will be selected. Put one hand down again, and you can move the selected cube. Don’t keep your hands too close together when you raise both of them.

5. Exit the application by pressing CTRL+C in the console or hitting the ESC key on your keyboard with the cube window visible.
