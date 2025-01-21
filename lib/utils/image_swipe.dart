import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ImageCarousel extends StatefulWidget {
  final List<dynamic> locationImages;

  const ImageCarousel({super.key, required this.locationImages});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSwipe();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _startAutoSwipe() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isPaused) {
        if (_currentPage < widget.locationImages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pauseAutoSwipe() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeAutoSwipe() {
    setState(() {
      _isPaused = false;
    });
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.8,
            maxScale: 5.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Positioned(
      bottom: 10.0,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.locationImages.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            width: 10.0,
            height: 10.0,
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.white : Colors.grey,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 250.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: GestureDetector(
              onLongPress: _pauseAutoSwipe,
              onLongPressUp: _resumeAutoSwipe,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.locationImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showImageDialog(widget.locationImages[index]),
                    child: Image(
                      image: CachedNetworkImageProvider(
                          widget.locationImages[index]),
                      fit: BoxFit.cover,
                    ),
                  );
                },
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
              ),
            ),
          ),
        ),
        if (widget.locationImages.length > 1) _buildDots(),
      ],
    );
  }
}
