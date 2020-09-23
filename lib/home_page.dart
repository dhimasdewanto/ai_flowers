import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

const tfLiteModelPath = "assets/model.tflite";
const tfLiteLabelPath = "assets/labels.txt";
const flowerImageAssetPath = "assets/flower.jpg";
/// 5 types of flowers.
const classCount = 5;

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = false;
  List _output;
  File _image;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  Future<void> _classifyImage(File image) async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
    });
    final output = await Tflite.runModelOnImage(
      path: image.path,
      // ignore: avoid_redundant_argument_values
      numResults: classCount,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _output = output;
      _loading = false;
    });
  }

  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: tfLiteModelPath,
      labels: tfLiteLabelPath,
    );
  }

  Future<void> _pickImage({
    ImageSource source,
  }) async {
    final image = await _picker.getImage(
      source: source ?? ImageSource.gallery,
    );
    if (image == null) {
      return;
    }
    setState(() {
      _image = File(image.path);
    });
    await _classifyImage(_image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detect Flowers"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image == null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    flowerImageAssetPath,
                    height: 250,
                    width: 250,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Column(
                  children: [
                    Container(
                      height: 250,
                      child: Image.file(_image),
                    ),
                    const SizedBox(height: 20),
                    if (_output != null)
                      Text(
                        "${_output[0]['label']}".toUpperCase(),
                        style: Theme.of(context).textTheme.headline3,
                      )
                  ],
                ),
              const SizedBox(height: 30),
              RaisedButton(
                onPressed: () {
                  _pickImage(
                    source: ImageSource.camera,
                  );
                },
                child: const Text("Take a Photo"),
              ),
              const SizedBox(height: 10),
              RaisedButton(
                onPressed: () {
                  _pickImage(
                    source: ImageSource.gallery,
                  );
                },
                child: const Text("Get from Galery"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
