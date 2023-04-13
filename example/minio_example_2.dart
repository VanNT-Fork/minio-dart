import 'dart:io';
import 'dart:typed_data';

import 'package:minio/minio.dart';
import 'package:http/http.dart';

void main() async {
  // Create a minio client.
  final minio = Minio(
      enableTrace: true,
      endPoint: 'objectstorage.wp-vancen.vcoder.host',
      port: 443,
      accessKey: 'j3B9quiBPCruMQLa',
      secretKey: 'OIj3dji5FdgL5ErkOiPABSeX5VGH2T7B');

  // try connecting to the server and getting credentials object storage
  final stream = await minio.getObject('demo-e2ee-prepdoc', 'credentials.json');

  // Get object length
  print(stream.contentLength);

  // make server encryption headers (sse-c)
  final ssecHeaders = {
    'X-Amz-Server-Side-Encryption-Customer-Algorithm': 'AES256',
    'X-Amz-Server-Side-Encryption-Customer-Key':
        'MzJieXRlc2xvbmdzZWNyZXRrZXltdXN0cHJvdmlkZWQ=',
    'X-Amz-Server-Side-Encryption-Customer-Key-MD5': '7PpPLAK26ONlVUGOWlusfg=='
  };

  // Write object data stream to file
  var file = File('output.json');
  await stream.pipe(file.openWrite());
  print(await file.readAsString());

  // option1: using presigned url to upload file to server
  // step 1: make presigned url
  final preUrl = await minio.presignedUrl(
    'PUT',
    'demo-e2ee-prepdoc',
    'test-sse-c-1.txt',
    reqHeaders: ssecHeaders,
  );

  print(preUrl);

  // step 2: put file to server via presigned url
  final res = await put(
    Uri.parse(preUrl),
    body: file.readAsBytesSync(),
    headers: ssecHeaders,
  );
  print(res.body);


  // options 2: put file to minio server using sse-c
  await minio.putObject(
    'demo-e2ee-prepdoc',
    'test-sse-c-3.txt',
    Stream.value(file.readAsBytesSync()),
    headers: ssecHeaders,
  );

  // try to download file from the server using SSE-C
  final stream2 = await minio.getObject('demo-e2ee-prepdoc', 'test-sse-c-3.txt',
      headers: ssecHeaders);

  // Get object length
  print(stream2.contentLength);

  // Write object data stream to file
  var file2 = File('output2.txt');
  await stream2.pipe(file2.openWrite());
  print(await file2.readAsString());
}
