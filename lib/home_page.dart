import 'package:flutter/material.dart';
import 'book_pages/book_burn_page.dart';
import 'book_pages/book_rocksolid_page.dart';
import 'book_pages/book_trustme_page.dart';
import 'book_pages/book_draculi_page.dart';
import 'book_pages/book_loser_page.dart';
import 'book_pages/book_bones_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ListView(
          children: [
            // Orange Banner
            Container(
              color: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Column(
                children: [
                  Text(
                    'NovelReader',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The Home of Great Books',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stars + review
            const Column(
              children: [
                Text('★★★★★', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                SizedBox(height: 8),
                Text('Brilliantly Twisted',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '“Absolutely insane in the best possible way. Like a Carl Hiaasen novel filtered through a Guy Ritchie film.”',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Book Grid
            Wrap(
              spacing: 16,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                bookTile(
                  context,
                  'assets/images/burn-cover.webp',
                  'In tranquil Vancouver a charred corpse and a paralyzed woman drag a washed-up PI into a darkly funny world of arson...',
                  const BookBurnPage(),
                ),
                bookTile(
                  context,
                  'assets/images/rock-solid-vancouver-kenya-thailand-thriller.webp',
                  'Blackmail spreads from Bangkok brothels to million dollar yachts as greed and madness pull a PI deeper into a surreal spiral...',
                  const BookRocksolidPage(), // note: lowercase ‘s’ class name
                ),
                bookTile(
                  context,
                  'assets/images/trust-me-front-cover-paul-slatter.webp',
                  'A woman’s life is turned upside down when a dangerous man from her past resurfaces, forcing her to confront the lies...',
                  const BookTrustmePage(),
                ),
                bookTile(
                  context,
                  'assets/images/disciples-of-coont-draculi-cover.webp',
                  'A vampire’s quest for redemption leads him into a world of betrayal, blood, and ancient secrets...',
                  const BookDraculiPage(),
                ),
                bookTile(
                  context,
                  'assets/images/loser-cover.webp',
                  'Take a dangerously seductive detour into Thailand’s sun-soaked chaos—through tropical beaches, Muay Thai boxing, beautiful women…',
                  const BookLoserPage(),
                ),
                bookTile(
                  context,
                  'assets/images/bones-in-the-water-cover.webp',
                  'While tracking a missing woman in sordid Pattaya, a Thai detective uncovers a chilling world...',
                  const BookBonesPage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget bookTile(BuildContext context, String imagePath, String description, Widget targetPage) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage)),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: 220, fit: BoxFit.cover),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'read more',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
