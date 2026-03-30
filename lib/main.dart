import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Tam ekran deneyimi (UIMode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FrcStrategyTabletProApp());
}

class FrcStrategyTabletProApp extends StatelessWidget {
  const FrcStrategyTabletProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Koyu tema temelini koruyoruz
      home: const FrcBoardTabletPro(),
    );
  }
}

class FrcBoardTabletPro extends StatefulWidget {
  const FrcBoardTabletPro({super.key});

  @override
  State<FrcBoardTabletPro> createState() => _FrcBoardTabletProState();
}

class _FrcBoardTabletProState extends State<FrcBoardTabletPro> {
  // --- PERİYOT SİSTEMİ ---
  int currentPeriodIndex = 0;
  final List<String> periodNames = ["Otonom", "Teleop", "Endgame"];
  List<List<Stroke>> periodStrokes = [[], [], []];

  Color selectedColor = Colors.yellowAccent; // Kalem rengi

  // --- ROBOT VERİLERİ (Tablette tutması kolay olsun diye yerleri açıldı) ---
  Map<String, Offset> robotPositions = {
    'R1': const Offset(80, 80), 'R2': const Offset(80, 160), 'R3': const Offset(80, 240),
    'B1': const Offset(800, 80), 'B2': const Offset(800, 160), 'B3': const Offset(800, 240),
  };

  final Map<String, Color> robotColors = {
    'R1': Colors.redAccent, 'R2': Colors.red, 'R3': Colors.red[900]!,
    'B1': Colors.blueAccent, 'B2': Colors.blue, 'B3': Colors.blue[900]!,
  };

  final String fieldAsset = 'assets/images/2026field.jpg';
  final String logoAsset = 'assets/images/team_logo.png';

  // --- KONTROL PANELİ VE GÖRÜNÜRLÜK ---
  bool isToolbarVisible = true; // Sağdaki araç çubuğu görünür mü?

  void undoLastStroke() {
    setState(() {
      if (periodStrokes[currentPeriodIndex].isNotEmpty) {
        periodStrokes[currentPeriodIndex].removeLast();
      }
    });
  }

  void clearCurrentPeriod() {
    setState(() {
      periodStrokes[currentPeriodIndex].clear();
    });
  }

  // Refresh (Yenile) fonksiyonu
  void resetRobots() {
    setState(() {
      robotPositions = {
        'R1': const Offset(80, 80), 'R2': const Offset(80, 160), 'R3': const Offset(80, 240),
        'B1': const Offset(800, 80), 'B2': const Offset(800, 160), 'B3': const Offset(800, 240),
      };
    });
  }

  void toggleToolbar() {
    setState(() {
      isToolbarVisible = !isToolbarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Temel arka plan siyah (saha görselinin kenarlarında boşluk kalırsa)
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KATMAN: Saha Görseli (RENK KALDIRILDI VE HAFİFLETİLDİ)
          Positioned.fill(
            child: Image.asset(
              fieldAsset,
              fit: BoxFit.contain,
              // YENİ: Mavi renk filtresi kaldırıldı, sadece karartma bırakıldı.
              // Karartmayı da çok hafif tutuyoruz ki taktikler ve logo net görünsün.
              color: Colors.black.withOpacity(0.1), // %10 saydamlıkta siyah filtre
              colorBlendMode: BlendMode.darken, // Karartma modu
              errorBuilder: (context, error, stackTrace) => const Center(child: Text("Saha Görseli Bulunamadı!")),
            ),
          ),

          // 2. KATMAN: Saydam ve Gradyanlı Takım Logosu
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.15, // Çok hafif görünmesi için (%15)
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.transparent],
                      stops: [0.4, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
            ),
          ),

          // 3. KATMAN: ÇİZİM ALANI
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() => periodStrokes[currentPeriodIndex].add(Stroke(points: [details.localPosition], color: selectedColor)));
              },
              onPanUpdate: (details) {
                setState(() => periodStrokes[currentPeriodIndex].last.points.add(details.localPosition));
              },
              onTapDown: (details) {
                setState(() => periodStrokes[currentPeriodIndex].add(Stroke(points: [details.localPosition, details.localPosition + const Offset(0.1, 0.1)], color: selectedColor)));
              },
              child: CustomPaint(
                painter: FreehandPainter(periodStrokes[currentPeriodIndex]),
                size: Size.infinite,
              ),
            ),
          ),

          // 4. KATMAN: ROBOTLAR
          ...robotPositions.keys.map((robotId) {
            return Positioned(
              left: robotPositions[robotId]!.dx,
              top: robotPositions[robotId]!.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() => robotPositions[robotId] = robotPositions[robotId]! + details.delta);
                },
                child: _buildRobotIcon(robotId, robotColors[robotId]!),
              ),
            );
          }),

          // --- UI KONTROLLERİ (Refresh ve Undo buraya geri döndü!) ---

          // ÜST ORTA: Periyot Seçici
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      bool isSelected = currentPeriodIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => currentPeriodIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            periodNames[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          // SAĞ ÜST KÖŞE: Refresh, Sil ve Geri Al Butonları (Her Zaman Görünür)
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.undo, color: Colors.white), tooltip: "Geri Al", onPressed: undoLastStroke),
                    IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.orange), tooltip: "Çizimi Sil", onPressed: clearCurrentPeriod),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.cyanAccent), tooltip: "Robotları Yenile", onPressed: resetRobots),
                  ],
                ),
              ),
            ),
          ),

          // SAĞ KENAR: Yüzen Renk Çubuğu (Sadece Renkler Kaldı)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            right: isToolbarVisible ? 20 : -100,
            top: 100,
            bottom: 100,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildColorButton(Colors.yellowAccent),
                      const SizedBox(height: 12),
                      _buildColorButton(Colors.redAccent),
                      const SizedBox(height: 12),
                      _buildColorButton(Colors.blueAccent),
                      const SizedBox(height: 12),
                      _buildColorButton(Colors.greenAccent),
                      const SizedBox(height: 12),
                      _buildColorButton(Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sol Alta Menü Göster/Gizle Butonu
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: isToolbarVisible ? Colors.black45 : Colors.orange,
              onPressed: toggleToolbar,
              child: Icon(isToolbarVisible ? Icons.menu_open : Icons.menu, color: Colors.white,),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    bool isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 4),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.white54, blurRadius: 8)] : [],
        ),
      ),
    );
  }

  // Tablet Pro için dairesel robot göstergesi
  Widget _buildRobotIcon(String label, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(2, 4))],
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}

class Stroke {
  final List<Offset> points;
  final Color color;
  Stroke({required this.points, required this.color});
}

class FreehandPainter extends CustomPainter {
  final List<Stroke> strokes;
  FreehandPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 6.0 // Tablet ekranında daha belirgin olsun diye çizgi kalınlaştırıldı
        ..style = PaintingStyle.stroke;

      Path path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}