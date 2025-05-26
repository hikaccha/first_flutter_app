import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'agenda_page.dart';
import 'diary_editor_page.dart';

class MainTabPage extends StatefulWidget {
  @override
  _MainTabPageState createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ProfilePage(),
    AgendaPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.person),
            label: 'プロフィール',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            activeIcon: Icon(Icons.calendar_today),
            label: 'アジェンダ',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DiaryEditorPage()),
          );

          // 新しい日記が作成された場合、両方のページを更新
          if (result == true) {
            // ProfilePageとAgendaPageの両方でデータを再読み込みするため
            // 各ページで適切に状態管理されている前提
            setState(() {
              // IndexedStackを使用しているため、ページの再構築が必要
              _pages[0] = ProfilePage();
              _pages[1] = AgendaPage();
            });
          }
        },
        child: Icon(Icons.add),
        tooltip: '新しい日記を作成',
      ),
    );
  }
}
