import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:video_player/video_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player App',
      home: VideoScreen(),
    );
  }
}

class VideoScreen extends StatefulWidget {
  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late IO.Socket socket;
  late VideoPlayerController _controller;
  String? videoUrl;

  @override
  void initState() {
    super.initState();

    // Conectar ao servidor Flask via Socket.IO
    socket = IO.io('http://127.0.0.1:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    // Ouvir pela conexão estabelecida
    socket.on('connect', (_) {
      print('Conectado ao servidor');
      // Enviar comando 'play_video' ao servidor
      socket.emit('play_video', {});
    });

    // Ouvir pela URL do vídeo
    socket.on('start_video', (data) {
      setState(() {
        videoUrl = 'http://127.0.0.1:5000' + data['url'];
      });

      // Iniciar o vídeo player
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl!),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      )
      )
        ..initialize().then((_) {
          setState(() {});
          _controller.initialize();
          
        });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player App'),
      ),
      body: videoUrl == null
          ? Center(child: Text('Aguardando URL do vídeo...'))
          : _controller.value.isInitialized
              ? Center(
                child: Column(
                  children: [
                    AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                    ),
                    VideoProgressIndicator(_controller, allowScrubbing: true, colors: VideoProgressColors(backgroundColor: Colors.blue),),
                    VideoControls(controller: _controller),
                    
                  ],
                ),
              )
              : Center(child: CircularProgressIndicator()),
    );
  }
}


class VideoControls extends StatefulWidget {
final VideoPlayerController controller;

 VideoControls({required this.controller});

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
 @override
 Widget build(BuildContext context) {

  return Container(
    color: Colors.black38,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () {
            widget.controller.seekTo(widget.controller.value.position - Duration(seconds:10));
          }, 
          icon: Icon(
            Icons.replay_10, color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: (){
            setState(() {
              widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
            });
          }, 
          icon: Icon(
            widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          )
          
        ),
        IconButton(
          onPressed: () {
            widget.controller.seekTo(widget.controller.value.position + Duration(seconds: 10));
          }, 
          icon: Icon(
            Icons.forward_10, color: Colors.white,
          )
        ),
      ],
    ),
  );
 }
}
