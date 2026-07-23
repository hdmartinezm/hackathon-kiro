import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/capture_repository.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/babyhealth_logo_widget.dart';
import '../widgets/phone_mockup_widget.dart';
import 'home_screen.dart';

/// Web landing screen with full informational sections and a phone mockup.
///
/// Only rendered when `kIsWeb == true`. Contains:
/// - Fixed navigation bar
/// - Hero section with phone mockup running [HomeScreen] in an isolated Navigator
/// - "El Desafío" section with 2-column layout
/// - "Cómo Funciona" 3-step flow
/// - "Características" 6-card grid
/// - "Arquitectura" service diagram
/// - "Seguridad y Disclaimer" card
/// - CTA subscription band
/// - Footer
class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  // GlobalKeys for scroll targets
  final _comoFuncionaKey = GlobalKey();
  final _caracteristicasKey = GlobalKey();
  final _arquitecturaKey = GlobalKey();
  final _seguridadKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToAuth({bool signup = false}) {
    Navigator.of(context).pushNamed(
      '/auth',
      arguments: signup ? 'signup' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _NavBar(
              onComoFunciona: () => _scrollToSection(_comoFuncionaKey),
              onCaracteristicas: () => _scrollToSection(_caracteristicasKey),
              onArquitectura: () => _scrollToSection(_arquitecturaKey),
              onSeguridad: () => _scrollToSection(_seguridadKey),
              onSolicitarAcceso: () => _navigateToAuth(),
            ),
            _HeroSection(
              onSolicitarAcceso: () => _navigateToAuth(),
              onVerComoFunciona: () => _scrollToSection(_comoFuncionaKey),
            ),
            _DesafioSection(),
            _ComoFuncionaSection(key: _comoFuncionaKey),
            _CaracteristicasSection(key: _caracteristicasKey),
            _ArquitecturaSection(key: _arquitecturaKey),
            _SeguridadSection(key: _seguridadKey),
            _CtaBandSection(onCrearCuenta: () => _navigateToAuth(signup: true)),
            _FooterSection(
              onComoFunciona: () => _scrollToSection(_comoFuncionaKey),
              onCaracteristicas: () => _scrollToSection(_caracteristicasKey),
              onArquitectura: () => _scrollToSection(_arquitecturaKey),
              onSeguridad: () => _scrollToSection(_seguridadKey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation Bar
// ---------------------------------------------------------------------------

class _NavBar extends StatelessWidget {
  final VoidCallback onComoFunciona;
  final VoidCallback onCaracteristicas;
  final VoidCallback onArquitectura;
  final VoidCallback onSeguridad;
  final VoidCallback onSolicitarAcceso;

  const _NavBar({
    required this.onComoFunciona,
    required this.onCaracteristicas,
    required this.onArquitectura,
    required this.onSeguridad,
    required this.onSolicitarAcceso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F4),
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE5E0DA), width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          if (isWide) {
            return _buildDesktopNav(context);
          }
          return _buildMobileNav(context);
        },
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopNav(BuildContext context) {
    return Row(
      children: [
        const BabyHealthLogoWidget(size: 40),
        const SizedBox(width: 12),
        Text(
          'BabyHealth',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B2826),
          ),
        ),
        const Spacer(),
        _navLink('Cómo funciona', onComoFunciona),
        const SizedBox(width: 24),
        _navLink('Características', onCaracteristicas),
        const SizedBox(width: 24),
        _navLink('Arquitectura', onArquitectura),
        const SizedBox(width: 24),
        _navLink('Seguridad', onSeguridad),
        const SizedBox(width: 32),
        _ctaButton(context),
      ],
    );
  }

  Widget _buildMobileNav(BuildContext context) {
    return Row(
      children: [
        const BabyHealthLogoWidget(size: 32),
        const SizedBox(width: 8),
        Text(
          'BabyHealth',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B2826),
          ),
        ),
        const Spacer(),
        _ctaButton(context),
      ],
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return _HoverableNavLink(label: label, onTap: onTap);
  }

  Widget _ctaButton(BuildContext context) {
    return _AnimatedCtaButton(
      label: 'Solicitar acceso',
      onPressed: onSolicitarAcceso,
    );
  }
}

// Hoverable nav link with animation
class _HoverableNavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HoverableNavLink({required this.label, required this.onTap});

  @override
  State<_HoverableNavLink> createState() => _HoverableNavLinkState();
}

class _HoverableNavLinkState extends State<_HoverableNavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF389BB0).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isHovered ? const Color(0xFF389BB0) : const Color(0xFF2B2826).withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

// Animated CTA button with hover effect
class _AnimatedCtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _AnimatedCtaButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  State<_AnimatedCtaButton> createState() => _AnimatedCtaButtonState();
}

class _AnimatedCtaButtonState extends State<_AnimatedCtaButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [const Color(0xFF2D7E91), const Color(0xFF389BB0)]
                  : [const Color(0xFF389BB0), const Color(0xFF389BB0)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF389BB0).withValues(alpha: _isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
            ],
          ),
          transform: _isHovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Section
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  final VoidCallback onSolicitarAcceso;
  final VoidCallback onVerComoFunciona;

  const _HeroSection({
    required this.onSolicitarAcceso,
    required this.onVerComoFunciona,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAF7F4),
            Color(0xFFD6F2F7),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return _buildDesktopHero(context);
          }
          return _buildMobileHero(context);
        },
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHero(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: _buildHeroText(context),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 4,
            child: Center(child: _buildPhoneMockup(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHero(BuildContext context) {
    return Column(
      children: [
        _buildHeroText(context),
        const SizedBox(height: 40),
        _buildPhoneMockup(context),
      ],
    );
  }

  Widget _buildHeroText(BuildContext context) {
    final isLarge = MediaQuery.of(context).size.width >= 768;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD6F2F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'INNOVACIÓN EN SALUD NEONATAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF389BB0),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Title line 1
        Text(
          'Tu bebé te habla.',
          style: TextStyle(
            fontSize: isLarge ? 40 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B2826),
            height: 1.2,
          ),
        ),
        // Title line 2
        Text(
          'Nosotros te ayudamos a entenderlo.',
          style: TextStyle(
            fontSize: isLarge ? 40 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF389BB0),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        // Subtitle
        Text(
          'BabyHealth analiza imagen y audio de tu bebé con inteligencia '
          'artificial para darte orientación temprana sobre su salud. '
          'Un asistente informativo para padres primerizos, impulsado por AWS.',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF2B2826).withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        // Double buttons with better styling
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _HeroPrimaryButton(
              label: 'Comenzar ahora',
              icon: Icons.arrow_forward_rounded,
              onPressed: onSolicitarAcceso,
            ),
            _HeroSecondaryButton(
              label: 'Ver demostración',
              icon: Icons.play_circle_outline_rounded,
              onPressed: onVerComoFunciona,
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _badge('★ AWS Bedrock'),
            _badge('🕒 Análisis en segundos'),
            _badge('+ Multimodal'),
          ],
        ),
      ],
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF389BB0).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF389BB0).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF389BB0),
        ),
      ),
    );
  }

  Widget _buildPhoneMockup(BuildContext context) {
    return SizedBox(
      width: 280,
      child: PhoneMockupWidget(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<HomeViewModel>(
              create: (_) => HomeViewModel(
                captureRepository: context.read<CaptureRepository>(),
              ),
            ),
          ],
          child: const HomeScreen(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// El Desafío Section
// ---------------------------------------------------------------------------

class _DesafioSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: isWide
                ? _buildDesktopLayout(context)
                : _buildMobileLayout(context),
          );
        },
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildLeftColumn(context),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 4,
          child: _buildRightCard(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildLeftColumn(context),
        const SizedBox(height: 32),
        _buildRightCard(context),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD6F2F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'EL DESAFÍO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF389BB0),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'La incertidumbre de los primeros meses',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B2826),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cada llanto de un bebé tiene un significado. Los padres primerizos '
          'enfrentan noches de incertidumbre preguntándose si todo está bien. '
          'BabyHealth usa inteligencia artificial para ayudarte a interpretar '
          'las señales de tu bebé.',
          style: TextStyle(
            fontSize: 16,
            color: const Color(0xFF2B2826).withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        _checkItem('El 70% de las consultas nocturnas son por causas no urgentes'),
        const SizedBox(height: 12),
        _checkItem('La ictericia neonatal afecta al 60% de los recién nacidos'),
        const SizedBox(height: 12),
        _checkItem('La ansiedad parental es la principal causa de visitas a urgencias'),
      ],
    );
  }

  Widget _checkItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF389BB0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2B2826).withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round,
                  color: Colors.white.withValues(alpha: 0.6), size: 18),
              const SizedBox(width: 8),
              Text(
                'Son las 2:37 AM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '"¿Por qué llora así? ¿Es normal este color?"',
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '— Preguntas que todo padre se hace',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cómo Funciona Section
// ---------------------------------------------------------------------------

class _ComoFuncionaSection extends StatelessWidget {
  const _ComoFuncionaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAF7F4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                // Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6F2F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CÓMO FUNCIONA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF389BB0),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title with highlighted "tres pasos"
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2826),
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: 'De la duda a la orientación en '),
                      TextSpan(
                        text: 'tres pasos',
                        style: TextStyle(color: Color(0xFFE87055)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Wrap(
                  spacing: 32,
                  runSpacing: 32,
                  alignment: WrapAlignment.center,
                  children: [
                    _StepCard(
                      number: '01',
                      title: 'Captura',
                      description: 'Foto + 3 segundos de audio / video corto '
                          'de tu bebé.',
                      icon: Icons.videocam_rounded,
                    ),
                    _StepCard(
                      number: '02',
                      title: 'Analiza en AWS',
                      description: 'Claude 3.5 Sonnet Vision en Amazon Bedrock '
                          'procesa el contenido.',
                      icon: Icons.psychology_rounded,
                    ),
                    _StepCard(
                      number: '03',
                      title: 'Recibe orientación',
                      description: 'Resultados inmediatos con semáforo '
                          'y recomendaciones.',
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
          ),
        ),
      ),
    );
  }

}

class _StepCard extends StatefulWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 260,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? const Color(0xFF389BB0).withValues(alpha: 0.3) : const Color(0xFFE5E0DA),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0xFF389BB0).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 20 : 8,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        transform: _isHovered
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        child: Column(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isHovered
                      ? [const Color(0xFF389BB0), const Color(0xFF4BA8BC)]
                      : [const Color(0xFFD6F2F7), const Color(0xFFD6F2F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.icon,
                color: _isHovered ? Colors.white : const Color(0xFF389BB0),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            // Number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF389BB0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Paso ${widget.number}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF389BB0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2826),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF2B2826).withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Características Section
// ---------------------------------------------------------------------------

class _CaracteristicasSection extends StatelessWidget {
  const _CaracteristicasSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768;
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6F2F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CARACTERÍSTICAS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF389BB0),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tecnología al servicio de la tranquilidad',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2826),
                  ),
                ),
                const SizedBox(height: 40),
                GridView.count(
                  crossAxisCount: isWide ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isWide ? 1.1 : 3.5,
                  children: [
                    _featureCard(
                      label: 'VISIÓN POR IA',
                      title: 'Análisis visual',
                      description:
                          'Detección de ictericia y evaluación del estado general del bebé.',
                    ),
                    _featureCard(
                      label: 'AUDIO IA',
                      title: 'Análisis de llanto',
                      description:
                          'Clasificación de patrones de llanto con inteligencia artificial.',
                      badge: 'PRÓXIMAMENTE',
                    ),
                    _featureCard(
                      label: 'AWS NATIVE',
                      title: 'Infraestructura cloud',
                      description:
                          'Serverless con S3 Pre-signed URLs y Lambda.',
                    ),
                    _featureCard(
                      label: 'PRIVACIDAD',
                      title: 'Tus datos seguros',
                      description:
                          'Sin almacenamiento permanente de imágenes ni videos.',
                    ),
                    _featureCard(
                      label: 'EDGE ML',
                      title: 'Procesamiento local',
                      description: 'Detección on-device para respuestas rápidas.',
                    ),
                    _featureCard(
                      label: 'UX CUIDADO',
                      title: 'Diseño para padres',
                      description:
                          'Interfaz optimizada para padres exhaustos.',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required String label,
    required String title,
    required String description,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E0DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Uppercase label
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF389BB0),
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE87055),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2826),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF2B2826).withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arquitectura Section
// ---------------------------------------------------------------------------

class _ArquitecturaSection extends StatelessWidget {
  const _ArquitecturaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAF7F4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6F2F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ARQUITECTURA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF389BB0),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Infraestructura serverless en AWS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B2826),
                  ),
                ),
                const SizedBox(height: 40),
                _architectureFlow(),
                const SizedBox(height: 32),
                _infrastructurePills(),
              ],
            ),
          );
        },
      ),
          ),
        ),
      ),
    );
  }

  Widget _architectureFlow() {
    final nodes = [
      _ArchNode(
        label: 'Flutter App',
        sublabel: 'App nativa',
        icon: Icons.phone_android_rounded,
      ),
      _ArchNode(
        label: 'API Gateway',
        sublabel: 'Endpoint HTTPS',
        icon: Icons.api_rounded,
      ),
      _ArchNode(
        label: 'AWS Lambda',
        sublabel: 'FastAPI + mangum',
        icon: Icons.code_rounded,
      ),
      _ArchNode(
        label: 'Amazon S3',
        sublabel: 'Media storage',
        icon: Icons.storage_rounded,
      ),
      _ArchNode(
        label: 'Bedrock',
        sublabel: 'Claude 3.5 Vision',
        icon: Icons.psychology_rounded,
      ),
      _ArchNode(
        label: 'DynamoDB',
        sublabel: 'Resultados',
        icon: Icons.table_chart_rounded,
      ),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 12,
      children: nodes.expand((node) {
        final isLast = nodes.indexOf(node) == nodes.length - 1;
        return [
          node,
          if (!isLast) const _ArchArrow(),
        ];
      }).toList(),
    );
  }

  Widget _infrastructurePills() {
    final pills = [
      '☁️ Full serverless',
      '⚡ Lambda + API Gateway',
      '🧠 Bedrock Vision',
      '📦 CDK mínimo',
      '🔒 API Key + rate limiting',
      '📊 CloudWatch logs',
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: pills.map((pill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: const Color(0xFF389BB0).withValues(alpha: 0.2)),
          ),
          child: Text(
            pill,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF389BB0),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ArchNode extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;

  const _ArchNode({
    required this.label,
    required this.sublabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E0DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF389BB0), size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2826),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFF2B2826).withValues(alpha: 0.5),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchArrow extends StatelessWidget {
  const _ArchArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: Color(0xFF389BB0),
        size: 20,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seguridad y Disclaimer Section
// ---------------------------------------------------------------------------

class _SeguridadSection extends StatelessWidget {
  const _SeguridadSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: const Color(0xFFE5E0DA)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Shield icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F2F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 32,
                      color: Color(0xFF389BB0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Seguridad y Privacidad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2826),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _securityPoint(
                    Icons.lock_outline,
                    'Privacidad total: No almacenamos permanentemente '
                        'imágenes ni videos de tu bebé.',
                  ),
                  const SizedBox(height: 12),
                  _securityPoint(
                    Icons.lock_rounded,
                    'Transmisión cifrada: Todos los datos se transmiten '
                        'de forma segura mediante HTTPS y pre-signed URLs.',
                  ),
                  const SizedBox(height: 12),
                  _securityPoint(
                    Icons.info_outline,
                    'Descargo médico: Esta aplicación no reemplaza la '
                        'evaluación de un profesional de la salud. '
                        'Consulte a su pediatra ante cualquier preocupación.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
          ),
        ),
      ),
    );
  }

  Widget _securityPoint(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF389BB0)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2B2826).withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CTA Subscription Band
// ---------------------------------------------------------------------------

class _CtaBandSection extends StatelessWidget {
  final VoidCallback onCrearCuenta;

  const _CtaBandSection({required this.onCrearCuenta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFAF7F4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF389BB0), Color(0xFF2D7E91)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF389BB0).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '¿Listo para probar BabyHealth?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crea tu cuenta gratis y comienza a usar BabyHealth hoy mismo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _CtaWhiteButton(
                      label: 'Crear cuenta gratis',
                      onPressed: onCrearCuenta,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _FooterSection extends StatelessWidget {
  final VoidCallback onComoFunciona;
  final VoidCallback onCaracteristicas;
  final VoidCallback onArquitectura;
  final VoidCallback onSeguridad;

  const _FooterSection({
    required this.onComoFunciona,
    required this.onCaracteristicas,
    required this.onArquitectura,
    required this.onSeguridad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2B2826),
      child: Column(
        children: [
          // Main footer content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 768;
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: isWide
                          ? _buildDesktopFooter(context)
                          : _buildMobileFooter(context),
                    );
                  },
                ),
              ),
            ),
          ),
          // Bottom bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        'Esta aplicación no reemplaza la evaluación de un '
                        'profesional de la salud. Consulte a su pediatra ante '
                        'cualquier preocupación sobre la salud de su bebé.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '© 2026 BabyHealth. Todos los derechos reservados.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BabyHealthLogoWidget(size: 36),
                  const SizedBox(width: 10),
                  Text(
                    'BabyHealth',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Asistente de cuidado neonatal con IA multimodal.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        // Product column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Producto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              _footerLink('Cómo funciona', onComoFunciona),
              const SizedBox(height: 8),
              _footerLink('Características', onCaracteristicas),
              const SizedBox(height: 8),
              _footerLink('Arquitectura', onArquitectura),
              const SizedBox(height: 8),
              _footerLink('Seguridad', onSeguridad),
            ],
          ),
        ),
        // Hackathon column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hackathon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              _footerLink('AWS Bedrock', () {}),
              const SizedBox(height: 8),
              _footerLink('AWS Lambda', () {}),
              const SizedBox(height: 8),
              _footerLink('Flutter', () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter(BuildContext context) {
    return Column(
      children: [
        // Brand
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BabyHealthLogoWidget(size: 36),
            const SizedBox(width: 10),
            Text(
              'BabyHealth',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Asistente de cuidado neonatal con IA multimodal.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        // Links row
        Wrap(
          spacing: 24,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _footerLink('Cómo funciona', onComoFunciona),
            _footerLink('Características', onCaracteristicas),
            _footerLink('Arquitectura', onArquitectura),
            _footerLink('Seguridad', onSeguridad),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _footerLink('AWS Bedrock', () {}),
            _footerLink('AWS Lambda', () {}),
            _footerLink('Flutter', () {}),
          ],
        ),
      ],
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Section Buttons
// ---------------------------------------------------------------------------

class _HeroPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeroPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_HeroPrimaryButton> createState() => _HeroPrimaryButtonState();
}

class _HeroPrimaryButtonState extends State<_HeroPrimaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [const Color(0xFF2D7E91), const Color(0xFF389BB0)]
                  : [const Color(0xFF389BB0), const Color(0xFF4BA8BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF389BB0).withValues(alpha: _isHovered ? 0.5 : 0.3),
                blurRadius: _isHovered ? 24 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -3.0))
              : Matrix4.identity(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                transform: _isHovered
                    ? (Matrix4.identity()..translate(4.0, 0.0))
                    : Matrix4.identity(),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSecondaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeroSecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_HeroSecondaryButton> createState() => _HeroSecondaryButtonState();
}

class _HeroSecondaryButtonState extends State<_HeroSecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF2B2826).withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF2B2826).withValues(alpha: 0.5)
                  : const Color(0xFF2B2826).withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: const Color(0xFF2B2826).withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2B2826).withValues(alpha: 0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CTA White button for colored backgrounds
class _CtaWhiteButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _CtaWhiteButton({
    required this.label,
    required this.onPressed,
  });

  @override
  State<_CtaWhiteButton> createState() => _CtaWhiteButtonState();
}

class _CtaWhiteButtonState extends State<_CtaWhiteButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -3.0))
              : Matrix4.identity(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF389BB0),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                transform: _isHovered
                    ? (Matrix4.identity()..translate(4.0, 0.0))
                    : Matrix4.identity(),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF389BB0),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
