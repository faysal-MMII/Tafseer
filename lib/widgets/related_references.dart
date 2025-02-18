import 'package:flutter/material.dart';

class RelatedReferences extends StatefulWidget {
  final List<String>? verses; // Nullable list for verses
  final List<String>? hadiths; // Nullable list for hadiths

  const RelatedReferences({
    Key? key,
    this.verses,
    this.hadiths,
  }) : super(key: key);

  @override
  State<RelatedReferences> createState() => _RelatedReferencesState();
}

class _RelatedReferencesState extends State<RelatedReferences> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Dynamically create TabController based on the number of tabs
    _tabController = TabController(
      length: _getTabCount(), 
      vsync: this
    );
  }

  // Helper method to determine the number of tabs
  int _getTabCount() {
    int count = 0;
    if (widget.verses != null && widget.verses!.isNotEmpty) count++;
    if (widget.hadiths != null && widget.hadiths!.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    // Check if both lists are null or empty
    if ((widget.verses == null || widget.verses!.isEmpty) && 
        (widget.hadiths == null || widget.hadiths!.isEmpty)) {
      return const SizedBox.shrink(); // Return an empty widget if no data
    }

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
          // Dynamically create TabBar based on available data
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF333333),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF333333),
            tabs: [
              if (widget.verses != null && widget.verses!.isNotEmpty)
                const Tab(text: 'Related Verses'),
              if (widget.hadiths != null && widget.hadiths!.isNotEmpty)
                const Tab(text: 'Related Hadiths'),
            ],
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 250, // More flexible height
              minHeight: 50,
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                // Verses Tab
                if (widget.verses != null && widget.verses!.isNotEmpty)
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.verses!.map((verse) => Padding(
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
                if (widget.hadiths != null && widget.hadiths!.isNotEmpty)
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.hadiths!.map((hadith) => Padding(
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