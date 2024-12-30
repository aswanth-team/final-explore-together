import 'package:flutter/material.dart';

class FloatingChatButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData? icon;
  final ImageProvider? imageIcon;
  final Color buttonColor;
  final Color iconColor;

  const FloatingChatButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.imageIcon,
    this.buttonColor = Colors.blue,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
            bottomLeft: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: imageIcon != null
              ? Image(
                  image: imageIcon!,
                  width: 90,
                  height: 90,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null)
                      Icon(
                        icon,
                        color: iconColor, // Customizable icon color
                        size: 24,
                      ),
                    if (icon != null) const SizedBox(width: 5),
                  ],
                ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Floating Chat Button"),
        ),
        body: const Center(
          child: Text("Press the floating button!"),
        ),
        floatingActionButton: FloatingChatButton(
          onPressed: () {
            debugPrint("Floating button pressed!");
          },
          imageIcon: const AssetImage("assets/system/iconImage/aiIcon.png"),
          buttonColor: Colors.blue,
          iconColor: Colors.white,
        ),
      ),
    );
  }
}
