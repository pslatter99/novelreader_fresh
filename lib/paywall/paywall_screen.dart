import 'package:flutter/material.dart';
import 'access.dart';

class PaywallScreen extends StatelessWidget {
  final String bookKey;
  const PaywallScreen({super.key, required this.bookKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Continue reading')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Unlock the rest of this book',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Chapters 1–5 are free. Choose an option to keep going.'),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await AccessManager.instance.chooseSubscribe();
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Subscribe — all novels + early releases'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await AccessManager.instance.chooseAds(bookKey);
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Read for free with ads'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await AccessManager.instance.choosePurchase(bookKey);
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Purchase this eBook'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
