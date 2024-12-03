import 'package:flutter/material.dart';

class RelatedReferences extends StatefulWidget {
  final List<String> verses;
  final List<String> hadiths;

  const RelatedReferences({
    Key? key,
    required this.verses,
    required this.hadiths,
  }) : super(key: key);

  @override
  State<RelatedReferences> createState() => _RelatedReferencesState();
}

class _RelatedReferencesState extends State<RelatedReferences> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verses.isEmpty && widget.hadiths.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF333333),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF333333),
            tabs: const [
              Tab(text: 'Related Verses'),
              Tab(text: 'Related Hadiths'),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(15),
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Verses Tab
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.verses.map((verse) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Verse $verse',
                        style: const TextStyle(
                          fontFamily: 'Noto Serif',
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                // Hadiths Tab
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.hadiths.map((hadith) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Hadith $hadith',
                        style: const TextStyle(
                          fontFamily: 'Noto Serif',
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}