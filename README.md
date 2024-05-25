
# CR Fly

CR Fly is an iOS application developed as part of a bachelor's thesis. It is designed to work with DJI drones to capture photographs and create 3D models using RealityCapture. This guide provides detailed instructions for setting up and running the project in Xcode.

## Requirements

- Xcode 15.3 (functionality verified on this version)
- Cocoapods
- DJI Drone and Controller (must be supported by DJI (Mobile) SDK v4, supported drones are listed [here](https://developer.dji.com/document/2c6f3a26-412e-45d2-a312-eb82e72411e7))
- RealityCapture software (can be downloaded [here](https://www.capturingreality.com/DownloadNow))

## Installation

1. **Clone the repository:**

   ```sh
   git clone https://github.com/your-username/CR-Fly.git
   cd CR-Fly
   ```

2. **Install Cocoapods:**

   If you haven't installed Cocoapods yet, you can do so with the following command:

   ```sh
   sudo gem install cocoapods
   ```

3. **Install project dependencies:**

   ```sh
   pod install
   ```

4. **Open the project in Xcode:**

   Open the `CR-Fly.xcworkspace` file in Xcode:

   ```sh
   open CR-Fly.xcworkspace
   ```

5. **Configure Signing for Libraries:**

   Some libraries might require proper signing configuration, particularly `SSZipArchive`. To configure the signing:

   - Navigate to the `Pods` project within Xcode.
   - Select `Signing & Capabilities`.
   - Choose your development team in the `Team` dropdown.

6. **Generate and Set DJI SDK AppKey:**

   If the project's bundle identifier is changed, it is necessary to generate a new DJI SDK AppKey. Follow the instructions on the [DJI Developer Website](https://developer.dji.com/document/2e5ae092-b0fa-4cbd-abe2-956f44253c12) to generate your DJI SDK AppKey. Once generated, add the AppKey to your project:

   - Navigate to `Project CR Fly -> Info`.
   - Replace the value for the key `DJISDKAppKey` with your new DJI SDK AppKey.

## Usage

1. **Launch the application:**

   Build and run the application on your iOS device from Xcode.

2. **Connect DJI Drone Controller:**

   Connect your DJI drone controller to your device via USB.

3. **Capture Photographs:**

   - Navigate to the `Drone FPV View`, accessible via the 'Let's Fly' button, which replaces the 'Not Connected' button once the drone connection is successfully established.
   - Use the interface to control the drone and take photographs.

4. **Create a 3D Model:**

   - Switch to the `3D Scene View`, accessible from the home screen.
   - Connect to RealityCapture:
     - Enable Real-time Assistance in RealityCapture by navigating to `Workflow -> Wiz`.
     - Use the app's `3D Scene View` and press the connect button to scan the QR code provided by Real-time Assistance.
     - Alternatively, manually enter the IP address and authorization token of the computer running RealityCapture. These details can be obtained from the Windows taskbar, selecting hidden icons, and then choosing `RealityCaptureNode -> About`.

5. **Upload Photographs:**

   - Go to the `PhotoAlbum` view via the home screen or after creating/opening a project in `3D Scene` using the '+' button in the lower left corner.
   - Select and upload the photos you wish to use for reconstruction.

6. **Align Photos:**

   After the upload completes, the application will start the alignment process to create a point cloud mesh.

7. **Finalize 3D Model:**

   - You can choose to add more photos or proceed with the reconstruction.
   - Select the type of model you want to reconstruct from the bottom menu.
   - Press the refresh button on the bottom right corner to begin reconstruction.

8. **View the Model:**

   Once the reconstruction is complete, the model will be downloaded and displayed within the application.

## Features

- **FPV Drone Control**: Real-time First-Person View (FPV) from your DJI drone.
- **Photo Capture**: Easily capture high-resolution photographs from your drone.
- **3D Scene View**: Integrate with RealityCapture for advanced 3D model creation.
- **Photo Album Management**: Upload and manage photos within the app.
- **Model Reconstruction**: Automated alignment and reconstruction of 3D models.

## Contributing

Feel free to fork this project, make changes, and submit pull requests. Contributions are welcome!

## License

This project is licensed under the MIT License.

---

Thank you for using CR Fly! We hope this application helps you create amazing 3D models with ease. Happy flying!
