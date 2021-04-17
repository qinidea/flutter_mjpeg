// @dart=2.9
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:udp/udp.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends HookWidget {
  WebSocket _webSocket;

  Mjpeg mjpeg;

  MyHomePage() {
    print('=============MyHomePage');

    scheduleMicrotask(() async {
      print('============= ws://100.100.0.1:8888/websocket');
      _webSocket = await WebSocket.connect("ws://100.100.0.1:8888/websocket");
      _webSocket.listen(_onReceive, onDone: () {
        print('连接关闭时响应');
      }, onError: (error) {
        print('发生错误');
      }, cancelOnError: true);

      WriteBuffer buffer = WriteBuffer()
            ..putUint16(0x8888)
            // ..putUint8(0x40);
            ..putUint8(0x0A)
          // ..putUint8List(Uint8List.fromList(utf8.encode('192.168.5.161 8888')))
          // ..putUint8List(Uint8List.fromList(utf8.encode('100.100.0.179 7777')))
          // ..putUint8(0x0B)
          // ..putUint8List(Uint8List.fromList(utf8.encode('192.168.5.161 18888')))
          // ..putUint8(0)
          //
          ;
      List<int> bytes = buffer.done().buffer.asUint8List();
      _webSocket?.add(bytes);

      var receiver = await UDP.bind(Endpoint.unicast(InternetAddress.tryParse("172.27.35.14"), port: Port(7777)));
      receiver.send(bytes, Endpoint.unicast(InternetAddress.tryParse("100.100.0.1"), port: Port(36081)));
      receiver.listen((datagram) {
        mjpeg?.feedData(datagram.data);
      });
    });
  }

  void _onReceive(data) {
    print("收到服务器数据:" + data.toString());
    // mjpeg?.feedData(data);
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = useState(true);
    mjpeg = Mjpeg(
      isLive: isRunning.value,
      stream: '',
      // stream: 'http://192.168.0.86:8080/?action=stream',
      // stream: 'http://91.133.85.170:8090/cgi-bin/faststream.jpg?stream=half&fps=15&rand=COUNTER', //'http://192.168.1.37:8081',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Demo Home Page'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: mjpeg,
            ),
          ),
          Row(
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  isRunning.value = !isRunning.value;
                },
                child: Text('Toggle'),
              ),
              RaisedButton(
                onPressed: () {
                  test();
                },
                child: Text('Push new route'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> test() async {
    print('test1');

    // for (int i = 0; i < 10; i++) {
    //   await mouse(1, 10, 10);
    //   await mouse(0, 10, 10);
    // }

    await keyboard(34);
  }

  Future<void> keyboard(int k1, [int k2 = 0, int k3 = 0, int k4 = 0, int k5 = 0, int k6 = 0]) async {
    // aaaa 0800 0000 0009 0000 0000
    await Future.delayed(
        Duration(milliseconds: 10),
        () => send(WriteBuffer()
          ..putUint16(0xaaaa)
          ..putUint8(0x08)
          ..putUint8(0x0)
          ..putUint8(k1)
          ..putUint8(k2)
          ..putUint8(k3)
          ..putUint8(k4)
          ..putUint8(k5)
          ..putUint8(k6)));
  }

  Future<void> posMouse(int x, int y) async {
    // 精准鼠标 aaaa 0551 00ec 56eb 00
    await Future.delayed(
        Duration(milliseconds: 10),
        () => send(WriteBuffer()
          ..putUint16(0xaaaa)
          ..putUint8(0x05)
          ..putUint8(0x51)
          ..putUint16(0)
          ..putUint8(x)
          ..putUint8(y)));
  }

  Future<void> mouse(int key, int x, int y) async {
    await Future.delayed(
        Duration(milliseconds: 10),
        () => send(WriteBuffer()
          ..putUint16(0xaaaa)
          ..putUint8(0x04)
          ..putUint8(0x20)
          ..putUint8(key)
          ..putUint8(x)
          ..putUint8(y)
          ..putUint8(0x0)));
  }

  void send(WriteBuffer buffer) {
    ByteData data = buffer.done();
    ByteBuffer dataBuffer = data.buffer;
    List<int> bytes = dataBuffer.asUint8List().sublist(0, data.lengthInBytes);
    print('sending $bytes');
    _webSocket?.add(bytes);
  }
}
