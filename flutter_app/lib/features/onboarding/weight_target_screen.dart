import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_base.dart';

class WeightTargetScreen extends StatefulWidget {
  const WeightTargetScreen({super.key});

  @override
  State<WeightTargetScreen> createState() => _WeightTargetScreenState();
}

class _WeightTargetScreenState extends State<WeightTargetScreen> {
  double weight = 50;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    
    return OnboardingBase(
      title: 'Your target\nWeight?',
      step: 9,
      content: Column(
        children: [
          Text('${weight.toInt()} kg', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 32),
          Slider(min: 30, max: 150, value: weight, onChanged: (v) => setState(() => weight = v), activeColor: Colors.pink),
        ],
      ),
      onContinue: () => controller.setTargetWeight(weight),
    );
  }
}
