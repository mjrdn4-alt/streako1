import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const StreakoApp());

const wk = [Color(0xFFB4CFFA), Color(0xFFF9B4D4), Color(0xFFA8E0E0), Color(0xFFFDD68C), Color(0xFFB4CFFA)];
const pinkBg = Color(0xFFFAE8F1);
const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

class StreakoApp extends StatelessWidget {
  const StreakoApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'Streako',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.pink, scaffoldBackgroundColor: const Color(0xFFFFFCF7)),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic> db = {};
  SharedPreferences? sp;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      sp = p;
      final s = p.getString('db');
      if (s != null) setState(() => db = jsonDecode(s));
    });
  }

  void save() {
    setState(() {});
    sp?.setString('db', jsonEncode(db));
  }

  Map m(String k) => (db[k] ??= <String, dynamic>{}) as Map;
  List get habits => (db['habits'] ??= <dynamic>[]) as List;
  String get ym => '${month.year}-${month.month}';
  int get nDays => DateTime(month.year, month.month + 1, 0).day;
  int get first => DateTime(month.year, month.month, 1).weekday; // Mon=1
  int weekOf(int d) => ((d - 1 + first - 1) ~/ 7).clamp(0, 4);
  List<int> done(int h) => List<int>.from(m('d')['$ym:$h'] ?? []);

  void toggle(int h, int d) {
    final l = done(h);
    l.contains(d) ? l.remove(d) : l.add(d);
    m('d')['$ym:$h'] = l;
    save();
  }

  int streak(int h) {
    final l = done(h)..sort();
    int best = 0, cur = 0, prev = -9;
    for (final d in l) {
      cur = d == prev + 1 ? cur + 1 : 1;
      if (cur > best) best = cur;
      prev = d;
    }
    return best;
  }

  List todo(String key) => (m('t')[key] ??= <dynamic>[]) as List;

  Future<String?> ask(String title) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Add'))],
      ),
    );
  }

  Widget card(String title, Color c, Widget child) => Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: c, width: 2), borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.vertical(top: Radius.circular(7))),
            child: Text(title.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(letterSpacing: 3, fontSize: 12)),
          ),
          Padding(padding: const EdgeInsets.all(8), child: child),
        ]),
      );

  Widget todoList(String key, Color c) {
    final items = todo(key);
    return Column(children: [
      for (int i = 0; i < items.length; i++)
        InkWell(
          onLongPress: () { items.removeAt(i); save(); },
          child: Row(children: [
            Checkbox(
              value: items[i]['x'], activeColor: c, visualDensity: VisualDensity.compact,
              onChanged: (v) { items[i]['x'] = v; save(); },
            ),
            Expanded(child: Text(items[i]['t'], style: TextStyle(decoration: items[i]['x'] ? TextDecoration.lineThrough : null))),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.add, size: 16), label: const Text('Add'),
          onPressed: () async {
            final t = await ask('New item');
            if (t != null && t.isNotEmpty) { items.add({'t': t, 'x': false}); save(); }
          },
        ),
      ),
    ]);
  }

  double pct(Iterable<String> keys) {
    int d = 0, t = 0;
    for (final k in keys) { for (final e in todo(k)) { t++; if (e['x'] == true) d++; } }
    return t == 0 ? 0 : d / t;
  }

  @override
  Widget build(BuildContext context) {
    final n = nDays, hs = habits;
    int total = hs.length * n, doneAll = 0;
    for (int h = 0; h < hs.length; h++) doneAll += done(h).length;
    final overall = total == 0 ? 0.0 : doneAll / total;
    final order = List<int>.generate(hs.length, (i) => i)..sort((a, b) => done(b).length.compareTo(done(a).length));
    final weekKeys = [for (int i = 0; i < 5; i++) 'w$ym:$i'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Column(children: [
          Text(months[month.month - 1], style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 24)),
          Text('HABIT TRACKER  ${month.year}', style: const TextStyle(fontSize: 10, letterSpacing: 3)),
        ]),
        leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => month = DateTime(month.year, month.month - 1))),
        actions: [IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add), label: const Text('Habit'),
        onPressed: () async {
          final t = await ask('New daily habit');
          if (t != null && t.isNotEmpty) { habits.add(t); save(); }
        },
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
        card('Daily progress', pinkBg, Column(children: [
          Text('${(overall * 100).toStringAsFixed(2)}%', style: const TextStyle(fontSize: 30, fontStyle: FontStyle.italic)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: overall, minHeight: 10, borderRadius: BorderRadius.circular(5), color: Colors.pink.shade200),
          const SizedBox(height: 4),
          Text('$doneAll / $total habits'),
        ])),
        card('Daily habits', wk[0], hs.isEmpty
            ? const Padding(padding: EdgeInsets.all(12), child: Text('Tap "+ Habit" to add your first habit.'))
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  const SizedBox(height: 40),
                  for (int h = 0; h < hs.length; h++)
                    GestureDetector(
                      onLongPress: () { hs.removeAt(h); save(); },
                      child: Container(
                        width: 110, height: 32, alignment: Alignment.centerLeft,
                        child: Text(hs[h], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                ]),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(children: [
                      Row(children: [
                        for (int d = 1; d <= n; d++)
                          Container(
                            width: 30, height: 40, alignment: Alignment.center,
                            color: wk[weekOf(d)],
                            child: Text('${'MTWTFSS'[(first - 1 + d - 1) % 7]}\n$d', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                          ),
                      ]),
                      for (int h = 0; h < hs.length; h++)
                        Row(children: [
                          for (int d = 1; d <= n; d++)
                            SizedBox(
                              width: 30, height: 32,
                              child: Checkbox(
                                value: done(h).contains(d), activeColor: wk[weekOf(d)], checkColor: Colors.black,
                                visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (_) => toggle(h, d),
                              ),
                            ),
                        ]),
                    ]),
                  ),
                ),
              ])),
        card('Top habits', wk[0], Column(children: [
          for (final h in order.take(10))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(flex: 3, child: Text(hs[h], style: const TextStyle(fontSize: 12))),
                Expanded(flex: 3, child: LinearProgressIndicator(value: done(h).length / n, color: wk[0], backgroundColor: Colors.blue.shade50)),
                SizedBox(width: 92, child: Text('  ${done(h).length}/$n · 🔥${streak(h)}', style: const TextStyle(fontSize: 11))),
              ]),
            ),
        ])),
        card('Weekly habits  ${(pct(weekKeys) * 100).toStringAsFixed(1)}%', wk[0], Column(children: [
          for (int i = 0; i < 5; i++)
            ExpansionTile(
              initiallyExpanded: i == 0,
              title: Text('Week ${i + 1}', style: const TextStyle(fontStyle: FontStyle.italic)),
              backgroundColor: wk[i].withOpacity(.15),
              children: [todoList(weekKeys[i], wk[i])],
            ),
        ])),
        card('Monthly habits  ${(pct(['m$ym']) * 100).round()}%', pinkBg, todoList('m$ym', Colors.pink)),
        card('Monthly reflection', wk[3], TextFormField(
          key: ValueKey(ym),
          initialValue: m('r')[ym] ?? '',
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'How did this month go?', border: InputBorder.none),
          onChanged: (v) { m('r')[ym] = v; sp?.setString('db', jsonEncode(db)); },
        )),
      ]),
    );
  }
}
