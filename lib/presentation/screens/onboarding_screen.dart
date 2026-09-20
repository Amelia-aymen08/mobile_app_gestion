import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // Built on demand: the titles depend on the selected language.
  List<_Slide> get _slides => [
    _Slide(image: 'assets/onboarding-who-we-are.png', title: 'WHO WE ARE'.tr, description: 'Crafting exceptional residences where luxury, comfort, and modern living come together to create a lifestyle beyond expectations.'.tr),
    _Slide(image: 'assets/screen02.png', title: 'WHAT WE OFFER'.tr, description: 'From residence updates to payments, bookings, and maintenance requests — everything you need, brought together in one seamless experience.'.tr),
    _Slide(image: 'assets/screen03.png', title: 'LIVE WITH PEACE OF MIND'.tr, description: 'Stay connected, informed, and fully in control of your daily life with premium services designed for modern living.'.tr),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? darkSurface : brandCream,
      body: PageView.builder(
        controller: _controller,
        itemCount: _slides.length,
        onPageChanged: (value) => setState(() => _page = value),
        itemBuilder: (_, index) => _buildSlide(_slides[index], dark),
      ),
    );
  }

  Widget _buildSlide(_Slide slide, bool dark) {
    final isLast = _page == _slides.length - 1;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(slide.image, fit: BoxFit.cover, alignment: Alignment.center, errorBuilder: (_, __, ___) => const ColoredBox(color: brandNavy)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.14, 0.61, 1],
              colors: dark
                  ? const [Colors.transparent, Color(0x99202A33), darkSurface]
                  : const [Colors.transparent, Color(0x77F6F3EC), brandCream],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(_slides.length, (index) {
                    final active = index == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 2),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(color: active ? brandAmber : const Color(0xFF999999), borderRadius: BorderRadius.circular(2)),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(slide.title, style: TextStyle(color: dark ? Colors.white : brandNavy, fontSize: 24, height: 1.2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(slide.description, style: TextStyle(color: dark ? Colors.white70 : const Color(0xFF333333), fontSize: 16, height: 1.36, fontWeight: FontWeight.w400)),
                const SizedBox(height: 38),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isLast)
                      TextButton(
                        onPressed: widget.onComplete,
                        style: TextButton.styleFrom(foregroundColor: dark ? Colors.white : Colors.black, padding: EdgeInsets.zero),
                        child: Text('Skip'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      )
                    else
                      const SizedBox(width: 48),
                    FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(backgroundColor: brandAmber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: const StadiumBorder()),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text((isLast ? 'Get started' : 'Next').tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 16),
                          SvgPicture.asset('assets/figma-arrow-right.svg', width: 24, height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Slide {
  final String image;
  final String title;
  final String description;
  const _Slide({required this.image, required this.title, required this.description});
}
