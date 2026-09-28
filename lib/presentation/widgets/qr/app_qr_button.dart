import 'dart:ui';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class AppQrButton extends StatelessWidget {
  const AppQrButton({super.key, this.title = 'Mã QR', required this.data});

  final String title;
  final String data;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => _AppQrDialog(title: title, data: data),
        );
      },
      icon: const Icon(Icons.qr_code),
    );
  }
}

class _AppQrDialog extends StatefulWidget {
  const _AppQrDialog({required this.title, required this.data});

  final String title;
  final String data;

  @override
  State<_AppQrDialog> createState() => _AppQrDialogState();
}

class _AppQrDialogState extends State<_AppQrDialog> {
  final qrDecoration = const PrettyQrDecoration(
    // image: PrettyQrDecorationImage(
    //   image: Assets.images.logoKaizenGo.provider(),
    //   clipper: const PrettyQrStarLogoClipper(),
    // ),
    quietZone: PrettyQrQuietZone.standard,
  );

  late final QrImage qrImage;

  @override
  void initState() {
    super.initState();
    final qrCode = QrCode.fromData(data: widget.data, errorCorrectLevel: QrErrorCorrectLevel.H);
    qrImage = QrImage(qrCode);
  }

  void _saveQrImage() async {
    final imgBytes = await qrImage.toImageAsBytes(
      size: 512,
      decoration: qrDecoration,
      format: ImageByteFormat.png,
    );
    if (imgBytes == null) return;
    await FileSaver.instance.saveFile(
      name: widget.title,
      bytes: imgBytes.buffer.asUint8List(),
      fileExtension: 'png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox.square(
        dimension: 240,
        child: PrettyQrView(qrImage: qrImage, decoration: qrDecoration),
      ),
      actions: [
        TextButton.icon(
          onPressed: _saveQrImage,
          icon: const Icon(Icons.download),
          label: const Text('Tải xuống'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: ColorName.red),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class PrettyQrStarLogoClipper implements PrettyQrClipper {
  const PrettyQrStarLogoClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0.5000, 0.0000)
      ..lineTo(0.6123, 0.3455)
      ..lineTo(0.9755, 0.3455)
      ..lineTo(0.6816, 0.5590)
      ..lineTo(0.7939, 0.9045)
      ..lineTo(0.5000, 0.6910)
      ..lineTo(0.2061, 0.9045)
      ..lineTo(0.3184, 0.5590)
      ..lineTo(0.0245, 0.3455)
      ..lineTo(0.3877, 0.3455)
      ..close();

    return path.transform(
      (Matrix4.identity()..scaleByDouble(size.width, size.height, 1, 1)).storage,
    );
  }
}
