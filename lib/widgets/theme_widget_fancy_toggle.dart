import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Widget de toggle de tema no canto superior esquerdo
/// Expande-se com hover no web e com toque no mobile
class ThemeCornerToggleOverlay extends ConsumerStatefulWidget {
  const ThemeCornerToggleOverlay({super.key});

  @override
  ConsumerState<ThemeCornerToggleOverlay> createState() => _ThemeCornerToggleOverlayState();
}

class _ThemeCornerToggleOverlayState extends ConsumerState<ThemeCornerToggleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _isHovered = false;
  bool _isMobileExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sizeAnimation = Tween<double>(
      begin: 32.0,
      end: 80.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handleMobileTap() {
    if (!_isMobileExpanded) {
      setState(() => _isMobileExpanded = true);
      _controller.forward();

      // Auto-collapse depois de 5 segundos se não for tocado novamente
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isMobileExpanded) {
          setState(() => _isMobileExpanded = false);
          _controller.reverse();
        }
      });
    } else {
      _toggleTheme();
      setState(() => _isMobileExpanded = false);
      _controller.reverse();
    }
  }

  void _toggleTheme() {
    ref.read(themeModeProvider.notifier).toggle();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    // final currentTheme = ref.watch(themeModeProvider);
    final brightness = Theme.of(context).brightness;
    final isMobile = _isMobile(context);
    
    // Determina as cores baseado no tema atual
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.black : Colors.white;
    final icon = isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round;

    return Positioned(
      top: 0,
      right: 0,
      child: MouseRegion(
        onEnter: isMobile ? null : (_) => _handleHover(true),
        onExit: isMobile ? null : (_) => _handleHover(false),
        child: GestureDetector(
          onTap: isMobile ? _handleMobileTap : _toggleTheme,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final size = _sizeAnimation.value;
              final opacity = _opacityAnimation.value;
              
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: backgroundColor.withAlpha((255.0 * opacity).round()),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(size / 1.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      spreadRadius : 1,
                      color: Colors.black.withAlpha((255.0 * 0.2).round()),
                      blurRadius: 98,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Ripple effect para web
                    if (!isMobile && (_isHovered || _controller.isAnimating))
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _toggleTheme,
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(size /  1.2),
                            ),
                            splashColor: iconColor.withAlpha((255.0 * 0.1).round()),
                            highlightColor: iconColor.withAlpha((255.0 * 0.05).round()),
                          ),
                        ),
                      ),
                    
                    // Ícone centralizado
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          icon,
                          key: ValueKey(icon),
                          color: iconColor,
                          size: size * 0.4,
                        ),
                      ),
                    ),
                    
                    // Indicador visual para mobile quando expandido
                    if (isMobile && _isMobileExpanded)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha((255.0 * 0.6).round()),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
