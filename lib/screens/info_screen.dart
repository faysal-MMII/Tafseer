import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

class InfoScreen extends StatefulWidget {
  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);

  List<Map<String, dynamic>> faqs = [];
  bool isLoadingFAQ = true;
  String? faqError;
  bool isFAQExpanded = false;
  late AnimationController _faqAnimationController;
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _faqAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    loadFAQData();
    _getVersionNumber();
  }

  @override
  void dispose() {
    _faqAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getVersionNumber() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'Version ${packageInfo.version}+${packageInfo.buildNumber}';
      });
    } catch (e) {
      setState(() {
        _version = 'Version 1.0.0';
      });
    }
  }

  Future<void> loadFAQData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/faq_data.json');
      final data = await json.decode(response);

      setState(() {
        faqs = List<Map<String, dynamic>>.from(data['muslim_faq']) +
               List<Map<String, dynamic>>.from(data['revert_faq']);
        isLoadingFAQ = false;
      });
    } catch (e) {
      setState(() {
        faqError = e.toString();
        isLoadingFAQ = false;
      });
      print('Error loading FAQ data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'About Tafseer',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue.withOpacity(0.8), lightBlue.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tafseer',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Islamic Knowledge & Guidance',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            _buildSection(
              title: 'About This App',
              icon: Icons.info_outline,
              child: Text(
                'Tafseer is an Islamic Q&A app that delivers results using Qur\'anic and Ahadith contexts. More than that, though, it provides a plethora of functions and tools catered to your Islamic needs.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.justify,
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        isFAQExpanded = !isFAQExpanded;
                      });
                      if (isFAQExpanded) {
                        _faqAnimationController.forward();
                      } else {
                        _faqAnimationController.reverse();
                      }
                    },
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: isFAQExpanded ? Radius.zero : Radius.circular(16),
                      bottomRight: isFAQExpanded ? Radius.zero : Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.3),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: isFAQExpanded ? Radius.zero : Radius.circular(16),
                          bottomRight: isFAQExpanded ? Radius.zero : Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, color: primaryBlue, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Frequently Asked Questions',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          Spacer(),
                          AnimatedBuilder(
                            animation: _faqAnimationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _faqAnimationController.value * 3.14159,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: primaryBlue,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  AnimatedBuilder(
                    animation: _faqAnimationController,
                    builder: (context, child) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: Curves.elasticOut.transform(_faqAnimationController.value),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            child: isLoadingFAQ
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                                      ),
                                    ),
                                  )
                                : faqError != null
                                    ? Center(
                                        child: Text(
                                          'Error loading FAQs: $faqError',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.red,
                                          ),
                                        ),
                                      )
                                    : Column(
                                        children: faqs.map((faq) => _buildFAQItem(faq)).toList(),
                                      ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            _buildSection(
              title: 'Features',
              icon: Icons.star_outline,
              child: Column(
                children: [
                  _buildFeatureItem(
                    '1. Prayer time and notification for said prayer based on your location',
                    Icons.access_time,
                  ),
                  _buildFeatureItem(
                    '2. Qibla compass',
                    Icons.explore,
                  ),
                  _buildFeatureItem(
                    '3. Notifications of fun Islamic facts',
                    Icons.lightbulb_outline,
                  ),
                  _buildFeatureItem(
                    '4. The Complete Qur\'an - Arabic text with Pickthall\'s interpretation',
                    Icons.menu_book,
                  ),
                  _buildFeatureItem(
                    '5. The Forty Hadith of Imam Nawawi\'s collection (only English translation)',
                    Icons.library_books,
                  ),
                  _buildFeatureItem(
                    '6. History for past searches',
                    Icons.history,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            _buildSection(
              title: 'AI Ethics & Privacy',
              icon: Icons.security,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryBlue.withOpacity(0.2)),
                    ),
                    child: Text(
                      'This app uses AI responsibly. We follow ethical guidelines to protect your privacy, promote fairness, and ensure safe, respectful interactions.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryBlue.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Technical Details',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'We use AI technology via the OpenAI API to enhance user experience. No user data is stored or used to train the AI model. We comply with OpenAI\'s usage guidelines and ethical practices regarding data privacy, safety, and fairness.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://zingy-cat-952388.netlify.app/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: Icon(Icons.privacy_tip_outlined, size: 20),
                label: Text(
                  'View Privacy Policy',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),

            SizedBox(height: 24),

            Center(
              child: Text(
                _version,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          title: Text(
            faq['question'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add,
              size: 16,
              color: primaryBlue,
            ),
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
          children: [
            Divider(
              color: primaryBlue.withOpacity(0.2),
              height: 16,
            ),
            Text(
              faq['answer'],
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: primaryBlue, size: 20),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: primaryBlue,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}