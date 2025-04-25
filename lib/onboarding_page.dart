
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engineering_theme.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // Controller for page view
  final PageController _pageController = PageController();
  
  // Current page index
  int _currentPage = 0;
  
  // Onboarding steps content
  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Добро пожаловать в справочник по допускам',
      description: 'Приложение поможет рассчитать размеры с учетом допусков. Пролистайте вправо, чтобы ознакомиться с основными функциями.',
      icon: Icons.precision_manufacturing,
      imageAsset: null,
    ),
    OnboardingStep(
      title: 'Поиск допусков',
      description: 'Нажмите на кнопку поиска, чтобы быстро найти необходимый допуск. Вы можете фильтровать по отверстиям и валам.',
      icon: Icons.search,
      imageAsset: null,
    ),
    OnboardingStep(
      title: 'Расчет размеров',
      description: 'Выберите ячейку с допуском и введите номинальный размер для получения минимальных и максимальных значений.',
      icon: Icons.straighten,
      imageAsset: null,
    ),
    OnboardingStep(
      title: 'Переключение единиц',
      description: 'Вы можете переключаться между миллиметрами, дюймами и микронами через меню настроек в правом верхнем углу.',
      icon: Icons.swap_horiz,
      imageAsset: null,
    ),
    OnboardingStep(
      title: 'Темная тема',
      description: 'Для комфортной работы в условиях плохого освещения включите темную тему через меню настроек.',
      icon: Icons.dark_mode,
      imageAsset: null,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // Handle page change
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Add haptic feedback on page change
    HapticFeedback.lightImpact();
  }
    @override
  void initState() {
    super.initState();
    // Установить правильный стиль для статус-бара
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Для светлой темы
        statusBarBrightness: Brightness.light, // Для iOS
      ),
    );
  }
  // Move to next page or complete onboarding
  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      widget.onComplete();
    }
  }
  
  // Skip onboarding
  void _skipOnboarding() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    // Get current brightness
    final brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    
    // Обновляем стиль статус-бара в зависимости от темы
    if (isDark) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // Для темной темы
          statusBarBrightness: Brightness.dark, // Для iOS
        ),
      );
    }
    
    return Scaffold(
      // Добавить AppBar для лучшего контроля над статус-баром
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Невидимый AppBar только для контроля статус-бара
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: const Text('ПРОПУСТИТЬ'),
                ),
              ),
            ),
            
            // Page view with onboarding steps
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon or image
                        if (step.imageAsset != null)
                          Image.asset(
                            step.imageAsset!,
                            height: 200,
                          )
                        else
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: EngineeringTheme.primaryBlue.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              step.icon,
                              size: 60,
                              color: EngineeringTheme.primaryBlue,
                            ),
                          ),
                        
                        const SizedBox(height: 40),
                        
                        // Title
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Description
                        Text(
                          step.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: EngineeringTheme.getTextColor(brightness, false),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Page indicator and next button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  // Page indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 16 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? EngineeringTheme.primaryBlue
                              : isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Next/Start button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == _steps.length - 1 ? 'НАЧАТЬ' : 'ДАЛЕЕ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model class for onboarding steps
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final String? imageAsset;
  
  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    this.imageAsset,
  });
}