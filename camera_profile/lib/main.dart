import 'dart:async';
import 'dart:io';
import 'package:sensors/sensors.dart';
import 'dart:convert';
import 'constants.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:camera_features/camera_features.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  //  spliting the camera configuration based on lens Direction
  Map<String, List<CameraDescription>> getCameraConfiguration(
      List<CameraDescription> cameras) {
    return {
      Constants.BACK_CAMERA: cameras
          .where((element) => element.lensDirection == CameraLensDirection.back)
          .toList(),
      Constants.FRONT_CAMERA: cameras
          .where(
              (element) => element.lensDirection == CameraLensDirection.front)
          .toList()
    };
  }

  final Map<String, List<CameraDescription>> configuredCameras =
      getCameraConfiguration(cameras);

  // Setting Back Camera first as first camera
  var selectedCameraDirection = Constants.BACK_CAMERA;
  var selectedCamera = 0;

  CameraDescription getSelectedCamera(String direction, int index) {
    return configuredCameras[direction][index];
  }

  // Setting Back Camera first as first camera
  final firstCamera =
      getSelectedCamera(selectedCameraDirection, selectedCamera);
  var a = firstCamera.lensDirection;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  Future<String> initPlatformState() async {
    var fields = new List<String>();

    fields.add("LENS_FACING");
    fields.add('LENS_DISTORTION');
    fields.add('LENS_INFO_AVAILABLE_APERTURES');
    fields.add('LENS_INFO_AVAILABLE_FILTER_DENSITIES');
    fields.add('LENS_INFO_AVAILABLE_FOCAL_LENGTHS');
    fields.add('LENS_INFO_AVAILABLE_OPTICAL_STABILIZATION');
    fields.add('LENS_INFO_FOCUS_DISTANCE_CALIBRATION');
    fields.add('LENS_INFO_HYPERFOCAL_DISTANCE');
    fields.add('LENS_INFO_MINIMUM_FOCUS_DISTANCE');
    fields.add('LENS_INTRINSIC_CALIBRATION');
    fields.add('LENS_POSE_REFERENCE');
    fields.add('LENS_POSE_ROTATION');
    fields.add('LENS_POSE_TRANSLATION');
    fields.add('LENS_RADIAL_DISTORTION');

    var res = await CameraFeatures.getCameraFeatures(fields);

    //resPrint(res);

    return res;
  }

  void resPrint(List<String> strs) {
    strs.map((e) => print(e));
  }

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.veryHigh,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera Profile')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Row(
        children: [
          FloatingActionButton(
            child: Icon(Icons.camera_alt),
            // Provide an onPressed callback.
            onPressed: () async {
              // Take the Picture in a try / catch block. If anything goes wrong,
              // catch the error.
              try {
                // Ensure that the camera is initialized.
                await _initializeControllerFuture;

                // Attempt to take a picture and get the file `image`
                // where it was saved.
                final image = await _controller.takePicture();

                // If the picture was taken, display it on a new screen.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisplayPictureScreen(
                      // Pass the automatically generated path to
                      // the DisplayPictureScreen widget.
                      imagePath: image?.path,
                    ),
                  ),
                );
              } catch (e) {
                // If an error occurs, log the error to the console.
                print(e);
              }
              ;
            },
          ),
          FloatingActionButton(
            child: Icon(Icons.flip_camera_android),
            // Provide an onPressed callback.
            onPressed: () async {
              print('roatate the camera');
            },
          ),
          FloatingActionButton(
            child: Icon(Icons.lens),
            // Provide an onPressed callback.
            onPressed: () async {
              initPlatformState().then((value) => print(value));
            },
          ),
          FloatingActionButton(
            child: Icon(Icons.gamepad),
            // Provide an onPressed callback.
            onPressed: () async {
              print('Acce. Matrix');
            },
          ),
        ],
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
