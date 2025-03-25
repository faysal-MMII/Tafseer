import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import '../models/islamic_fact.dart';
import '../models/region_boundary.dart'; // Assuming RegionBoundary model is in this path

class IslamicFactsData {
  static const List<Map<String, String>> _interactionBasedFacts = [
    // Mosque-related facts
    {
      'category': 'Mosque',
      'title': 'First Mosque',
      'description': 'The Prophet\'s Mosque in Medina was one of the first mosques built in Islamic history, established by Prophet Muhammad in 622 CE.'
    },
    {
      'category': 'Mosque',
      'title': 'Architectural Evolution',
      'description': 'The minaret, a distinctive feature of mosques, was first introduced during the Umayyad period around 673 CE.'
    },
    {
      'category': 'Mosque',
      'title': 'Grand Mosque',
      'description': 'The Great Mosque of Mecca (Masjid al-Haram) can accommodate over 4 million worshippers during Hajj season.'
    },
    {
      'category': 'Mosque',
      'title': 'Blue Mosque',
      'description': 'The Sultan Ahmed Mosque in Istanbul features over 20,000 handmade ceramic tiles and 200 stained glass windows.'
    },
    {
      'category': 'Mosque',
      'title': 'Oldest Mosque',
      'description': 'The Quba Mosque in Medina is the oldest mosque in the world, with its first stones laid by Prophet Muhammad himself.'
    },
    {
      'category': 'Mosque',
      'title': 'Mosque Etiquette',
      'description': 'The tradition of removing shoes before entering a mosque stems from the concept of maintaining cleanliness in prayer spaces.'
    },
    {
      'category': 'Mosque',
      'title': 'Prayer Direction',
      'description': 'Every mosque in the world is built facing the Kaaba in Mecca, known as the Qibla direction.'
    },
    {
      'category': 'Mosque',
      'title': 'Mosque Functions',
      'description': 'Historically, mosques served not just as prayer spaces but also as schools, courts, and community centers.'
    },
    {
      'category': 'Mosque',
      'title': 'Dome Design',
      'description': 'The dome of a mosque is designed to create acoustic amplification for the imam\'s voice during prayers.'
    },
    {
      'category': 'Mosque',
      'title': 'Prayer Halls',
      'description': 'Most mosques have separate prayer halls for men and women to maintain modesty and focus during worship.'
    },

    // Food-related facts
    {
      'category': 'Food',
      'title': 'Origins of Halal',
      'description': 'The concept of halal food is mentioned in the Quran and includes both the type of food and method of preparation.'
    },
    {
      'category': 'Food',
      'title': 'Dates Tradition',
      'description': 'Breaking the fast during Ramadan traditionally begins with eating dates, following the Prophet\'s example.'
    },
    {
      'category': 'Food',
      'title': 'Blessing Food',
      'description': 'Muslims say "Bismillah" (In the name of Allah) before eating as a way of blessing their food.'
    },
    {
      'category': 'Food',
      'title': 'Communal Dining',
      'description': 'Islamic tradition encourages eating together, as it\'s believed to bring more blessings to the meal.'
    },
    {
      'category': 'Food',
      'title': 'Food Ethics',
      'description': 'Islamic dietary laws promote ethical treatment of animals and sustainable farming practices.'
    },
    {
      'category': 'Food',
      'title': 'Fasting Benefits',
      'description': 'The practice of fasting in Ramadan has been scientifically proven to have numerous health benefits.'
    },
    {
      'category': 'Food',
      'title': 'Prohibited Foods',
      'description': 'The prohibition of pork and alcohol in Islam extends to their derivatives and ingredients in processed foods.'
    },
    {
      'category': 'Food',
      'title': 'Hospitality',
      'description': 'Offering food to guests is considered a fundamental aspect of Islamic hospitality.'
    },
    {
      'category': 'Food',
      'title': 'Eating Manners',
      'description': 'Islamic tradition recommends eating with the right hand and sitting while eating.'
    },
    {
      'category': 'Food',
      'title': 'Food Waste',
      'description': 'Islam strongly discourages food waste, considering it a form of extravagance.'
    },

    // Commerce-related facts
    {
      'category': 'Commerce',
      'title': 'Islamic Trade',
      'description': 'Early Muslim traders established vast networks spanning from China to Spain during the Golden Age.'
    },
    {
      'category': 'Commerce',
      'title': 'Interest Ban',
      'description': 'Islamic finance prohibits charging interest (riba) and has developed alternative financial instruments.'
    },
    {
      'category': 'Commerce',
      'title': 'Market Ethics',
      'description': 'Islamic commerce emphasizes honest pricing, quality disclosure, and fair dealing.'
    },
    {
      'category': 'Commerce',
      'title': 'Trade Routes',
      'description': 'The Silk Road was significantly influenced by Muslim traders who introduced new goods and technologies.'
    },
    {
      'category': 'Commerce',
      'title': 'Banking History',
      'description': 'The first checks were developed by Muslim merchants in the 9th century.'
    },
    {
      'category': 'Commerce',
      'title': 'Market Rules',
      'description': 'The concept of market supervision (hisbah) was developed in early Islamic societies.'
    },
    {
      'category': 'Commerce',
      'title': 'Partnership System',
      'description': 'The Islamic mudarabah system influenced the development of modern business partnerships.'
    },
    {
      'category': 'Commerce',
      'title': 'Fair Trade',
      'description': 'Islamic principles of trade include prohibitions against monopolies and price manipulation.'
    },
    {
      'category': 'Commerce',
      'title': 'Business Ethics',
      'description': 'Transparency and mutual consent are fundamental principles in Islamic business transactions.'
    },
    {
      'category': 'Commerce',
      'title': 'Zakat System',
      'description': 'The Islamic tax system (Zakat) helped establish a systematic approach to wealth distribution.'
    },

    // Community-related facts
    {
      'category': 'Community',
      'title': 'Community Spirit',
      'description': 'The concept of Ummah emphasizes the unity and brotherhood of all Muslims globally.'
    },
    {
      'category': 'Community',
      'title': 'Neighborly Rights',
      'description': 'Islamic teachings place great emphasis on maintaining good relations with neighbors.'
    },
    {
      'category': 'Community',
      'title': 'Social Welfare',
      'description': 'The Islamic community system includes built-in mechanisms for supporting the poor and needy.'
    },
    {
      'category': 'Community',
      'title': 'Education Value',
      'description': 'Seeking knowledge is considered a religious duty for every Muslim, male and female.'
    },
    {
      'category': 'Community',
      'title': 'Family Structure',
      'description': 'Extended family networks play a crucial role in Islamic community organization.'
    },
    {
      'category': 'Community',
      'title': 'Conflict Resolution',
      'description': 'Islamic communities traditionally use mediation and arbitration to resolve disputes.'
    },
    {
      'category': 'Community',
      'title': 'Youth Development',
      'description': 'Islamic communities emphasize mentorship and guidance for young people.'
    },
    {
      'category': 'Community',
      'title': 'Elderly Care',
      'description': 'Caring for elderly parents and community members is considered a religious obligation.'
    },
    {
      'category': 'Community',
      'title': 'Cultural Diversity',
      'description': 'Islamic communities worldwide maintain unique cultural traditions while sharing core values.'
    },
    {
      'category': 'Community',
      'title': 'Social Events',
      'description': 'Regular community gatherings and celebrations strengthen social bonds in Muslim communities.'
    },
  ];

  static List<IslamicFact> getMonthlyFacts(int month) {
    final monthData = _monthlyFacts[month] ?? [];
    return monthData.map((map) => IslamicFact.fromMap(map)).toList();
  }

  static List<IslamicFact> get generalFacts {
    return _generalFacts.map((map) => IslamicFact.fromMap(map)).toList();
  }

  static List<IslamicFact> getFactsByInteraction(String category) {
    return _interactionBasedFacts
        .where((map) => map['category']?.toLowerCase() == category.toLowerCase())
        .map((map) => IslamicFact.fromMap(map))
        .toList();
  }

  static const Map<int, List<Map<String, String>>> _monthlyFacts = {
    1: const [
      {
        'category': 'Religious Observance',
        'title': 'Sacred Month',
        'description': 'Muharram is one of the four sacred months in Islam where fighting is prohibited.'
      },
      {
        'category': 'Historical/Religious Events',
        'title': 'Day of Ashura Significance',
        'description': 'The Day of Ashura (10th Muharram) is significant for multiple historical events.'
      },
      {
        'category': 'Religious History',
        'title': 'Prophet Musa Saved',
        'description': 'Prophet Musa (AS) and Bani Israel were saved from Pharaoh on Ashura.'
      },
      {
        'category': 'Religious History',
        'title': 'Pharaoh Drowned',
        'description': 'Pharaoh and his army drowned in the Red Sea on this day.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Fasting on Ashura (Original)',
        'description': 'Fasting on Ashura was originally obligatory before Ramadan became compulsory.'
      },
      {
        'category': 'Historical Event',
        'title': 'Martyrdom of Imam Hussain',
        'description': 'The grandson of the Prophet (SAW), Imam Hussain (RA), was martyred in Karbala on Ashura (680 CE).'
      },
      {
        'category': 'Historical Aftermath',
        'title': 'Desecration after Karbala',
        'description': 'Yazid\'s forces desecrated the bodies of the martyrs in Karbala.'
      },
      {
        'category': 'Religious Tradition',
        'title': 'Ark of Prophet Nuh Landing',
        'description': 'The Ark of Prophet Nuh (AS) is said to have landed on Mount Judi on Ashura.'
      },
      {
        'category': 'Historical Event',
        'title': 'Survival of Imam Zain-ul-Abideen',
        'description': 'Imam Zain-ul-Abideen (RA), son of Imam Hussain (RA), survived Karbala due to illness.'
      },
      {
        'category': 'Historical Event',
        'title': 'Battle of Harra',
        'description': 'The battle of Harra (683 CE) occurred in Muharram, Yazid\'s forces attacked Medina.'
      },
      {
        'category': 'Historical Event',
        'title': 'Kaaba Fire in Siege of Mecca',
        'description': 'The Kaaba was set on fire during the siege of Mecca in Muharram 683 CE.'
      },
      {
        'category': 'Historical Aftermath',
        'title': 'Imprisonment after Karbala',
        'description': 'Imam Hussain’s family was imprisoned and taken to Damascus after Karbala.'
      },
      {
        'category': 'Prophetic Saying',
        'title': 'Leaders of Youth of Jannah',
        'description': 'Prophet (SAW) called Imam Hussain & Hassan "leaders of the youth of Jannah".'},
      {
        'category': 'Historical Event',
        'title': 'Abbasid Coup',
        'description': 'Abbasids overthrew Umayyads in a bloody coup during Muharram 750 CE.'
      },
      {
        'category': 'Cultural Practice',
        'title': 'Avoidance of War',
        'description': 'Many Muslim rulers avoided waging wars during Muharram out of respect.'
      },
      {
        'category': 'Cultural Tradition',
        'title': 'Majlis Tradition',
        'description': 'Tradition of Majlis (gatherings) to remember Karbala began centuries ago.'
      },
      {
        'category': 'Historical Event',
        'title': 'Formal Ashura Commemoration',
        'description': 'Fatimids, a Shia dynasty, formalized Ashura commemoration as a state event.'
      },
      {
        'category': 'Historical Event',
        'title': 'Death of Umar ibn Abdul Aziz',
        'description': 'Umayyad Caliph Umar ibn Abdul Aziz died in Muharram.'
      },
      {
        'category': 'Cultural Practice',
        'title': 'Time of Mourning (Shia)',
        'description': 'Muharram is a time of mourning for many Shia Muslims.'
      },
      {
        'category': 'Religious Belief',
        'title': 'Rise of the Mahdi (Speculation)',
        'description': 'Some scholars believe the Mahdi (AS) will rise in Muharram.'
      },
    ],
    2: const [
      {
        'category': 'Pre-Islamic Belief',
        'title': 'Unlucky Month (Pre-Islam)',
        'description': 'Safar was considered an unlucky month in pre-Islamic Arabia.'
      },
      {
        'category': 'Prophetic Tradition',
        'title': 'Rejection of Safar Superstition',
        'description': 'The Prophet (SAW) rejected superstitions about Safar.'
      },
      {
        'category': 'Historical Event (Speculated)',
        'title': 'Amwas Plague Start (Speculated)',
        'description': 'Many believe the first plague of Islam (Amwas plague) began in Safar.'
      },
      {
        'category': 'Prophetic History',
        'title': 'Prophet’s Illness in Safar',
        'description': 'The Prophet (SAW) fell seriously ill in Safar, leading to his passing in Rabi\' al-Awwal.'
      },
      {
        'category': 'Military History',
        'title': 'Khalid ibn Walid’s Battles',
        'description': 'Khalid ibn Walid (RA) led key battles during Safar.'
      },
      {
        'category': 'Military History',
        'title': 'Battle of Khyber',
        'description': 'The battle of Khyber (7 AH) took place in Safar, Muslims defeated Jewish tribes.'
      },
      {
        'category': 'Historical Claim',
        'title': 'Migration to Abyssinia (Claimed)',
        'description': 'Some Islamic historians claim the migration to Abyssinia happened in Safar.'
      },
      {
        'category': 'Historical Event',
        'title': 'Usama ibn Zayd’s Command',
        'description': 'Safar 11 AH: Prophet (SAW) appointed Usama ibn Zayd as army commander.'
      },
      {
        'category': 'Biographical',
        'title': 'Birth of Imam Malik',
        'description': 'Many great scholars such as Imam Malik were born in Safar.'
      },
      {
        'category': 'Prophetic Event',
        'title': 'Prophet’s Last Sermon (Pre-Illness)',
        'description': 'Prophet’s (SAW) last sermon before final illness was given in Safar.'
      },
      {
        'category': 'Prophetic Hint (Speculated)',
        'title': 'Hint at Death (Speculated)',
        'description': 'Some believe the Prophet (SAW) hinted at his death during Safar.'
      },
      {
        'category': 'Historical Aftermath',
        'title': 'Karbala Aftermath Unfolded',
        'description': 'Battle of Karbala aftermath unfolded in Safar as prisoners were taken to Yazid.'
      },
      {
        'category': 'Historical Event',
        'title': 'Martyrdom of Umar ibn Khattab',
        'description': 'Martyrdom of the second caliph, Umar ibn Khattab (RA), took place in Safar.'
      },
      {
        'category': 'Historical Persecution',
        'title': 'Umayyad Persecution of Ahlul Bayt',
        'description': 'Umayyads intensified persecution of Ahlul Bayt during Safar.'
      },
      {
        'category': 'Cultural Superstition',
        'title': 'Avoidance of Marriages',
        'description': 'Many kings and rulers avoided marriages in Safar due to superstition.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Prophet’s Final Umrah',
        'description': 'The Prophet (SAW) performed his final Umrah in Safar.'
      },
      {
        'category': 'Cultural Tradition',
        'title': 'Sufi Mawlids & Gatherings',
        'description': 'Tradition of Sufi Mawlids & gatherings gained prominence in Safar.'
      },
      {
        'category': 'Biographical',
        'title': 'Death of Ibn Sina (Avicenna)',
        'description': 'Famous Muslim philosopher Ibn Sina (Avicenna) passed away in Safar.'
      },
      {
        'category': 'Historical Expansion',
        'title': 'Umayyad Empire Expansions',
        'description': 'Safar saw major expansions of the Umayyad empire.'
      },
      {
        'category': 'Historical Event',
        'title': 'Abbasid Victories',
        'description': 'Abbasids marked victories against the Umayyads in Safar.'
      },
    ],
    3: const [
      {
        'category': 'Prophetic Birth',
        'title': 'Birth of Prophet Muhammad (ﷺ)',
        'description': 'Prophet Muhammad (SAW) was born on a Monday in Rabi\' al-Awwal (most say 12th, opinions vary).'
      },
      {
        'category': 'Prophetic Death',
        'title': 'Death of Prophet Muhammad (ﷺ)',
        'description': 'The Prophet (SAW) passed away on 12th Rabi\' al-Awwal, same day many believe he was born.'
      },
      {
        'category': 'Historical Event',
        'title': 'Hijrah to Medina',
        'description': 'Hijrah (migration) to Medina began in Rabi\' al-Awwal, a turning point in Islamic history.'
      },
      {
        'category': 'Architectural History',
        'title': 'Construction of Masjid Quba',
        'description': 'Masjid Quba, Islam’s first mosque, was built by Prophet (SAW) during his migration.'
      },
      {
        'category': 'Architectural History',
        'title': 'Establishment of Masjid al-Nabawi',
        'description': 'Masjid al-Nabawi (Prophet’s Mosque) was established in Rabi\' al-Awwal after Medina arrival.'
      },
      {
        'category': 'Historical Leadership',
        'title': 'Abu Bakr Becomes First Caliph',
        'description': 'Abu Bakr (RA) officially became the first caliph in Rabi\' al-Awwal after Prophet\'s passing.'
      },
      {
        'category': 'Military History',
        'title': 'Battle of Buwayb',
        'description': 'Battle of Buwayb (637 CE), decisive Muslim victory against Persians, occurred in Rabi\' al-Awwal.'
      },
      {
        'category': 'Religious Observance (Debated)',
        'title': 'Origin of Mawlid (Debated)',
        'description': 'Mawlid (celebration of Prophet\'s birth) originated centuries later, remains debated.'
      },
      {
        'category': 'Prophetic Residence',
        'title': 'Prophet Lived at Abu Ayyub’s House',
        'description': 'Prophet (SAW) lived in Abu Ayyub al-Ansari’s house for months before his home was built.'
      },
      {
        'category': 'Biographical',
        'title': 'Birth of Imam Bukhari',
        'description': 'Famous scholar Imam Bukhari was born in Rabi\' al-Awwal (810 CE).'
      },
      {
        'category': 'Architectural Innovation',
        'title': 'First Minbar Construction',
        'description': 'Construction of first minbar (pulpit) in a mosque was initiated by Prophet (SAW) in Rabi\' al-Awwal.'
      },
      {
        'category': 'Religious Practice',
        'title': 'First Jumu’ah Prayer',
        'description': 'Prophet (SAW) performed his first Jumu\'ah (Friday prayer) in Rabi\' al-Awwal.'
      },
      {
        'category': 'Natural Disaster',
        'title': 'Mecca Earthquake',
        'description': 'Major earthquake hit Mecca in Rabi\' al-Awwal (1033 CE), damaging the Kaaba.'
      },
      {
        'category': 'Cultural Tradition',
        'title': 'Ottoman Mawlid Processions',
        'description': 'Many Ottoman Sultans organized Mawlid processions in Rabi\' al-Awwal.'
      },
      {
        'category': 'Prophetic Event',
        'title': 'Last Sermon in Medina',
        'description': 'Last sermon of Prophet (SAW) to followers in Medina was in Rabi\' al-Awwal.'
      },
    ],
    4: const [
      {
        'category': 'Historical Governance',
        'title': 'Medina Constitution Completion (Speculated)',
        'description': 'Many historians believe Prophet (SAW) completed initial Medina Constitution in Rabi\' al-Thani.'
      },
      {
        'category': 'Biographical',
        'title': 'Birth of Abd al-Malik ibn Marwan',
        'description': 'Abd al-Malik ibn Marwan, influential Umayyad caliph, was born in Rabi\' al-Thani.'
      },
      {
        'category': 'Biographical',
        'title': 'Birth of Imam Ahmad ibn Hanbal',
        'description': 'Imam Ahmad ibn Hanbal, founder of Hanbali school, was born in Rabi\' al-Thani (780 CE).'
      },
      {
        'category': 'Military History',
        'title': 'Conquest of Jerusalem by Salahuddin',
        'description': 'Conquest of Jerusalem by Salahuddin Al-Ayyubi (1187 CE) finalized in Rabi\' al-Thani.'
      },
      {
        'category': 'Biographical',
        'title': 'Death of Abdul Qadir al-Jilani',
        'description': 'Famous Sufi saint Abdul Qadir al-Jilani passed away in Rabi\' al-Thani (1166 CE).'
      },
      {
        'category': 'Medical History',
        'title': 'First Muslim Hospital with Wards',
        'description': 'First Muslim hospital with medical wards built in Rabi\' al-Thani during Abbasid era.'
      },
      {
        'category': 'Social History',
        'title': 'Prophet Settled Medina Disputes',
        'description': 'Prophet (SAW) settled disputes among Medina’s tribes in Rabi\' al-Thani.'
      },
      {
        'category': 'Historical Reforms',
        'title': 'Ottoman Reforms by Suleiman',
        'description': 'Ottoman Sultan Suleiman the Magnificent’s reforms were initiated in Rabi\' al-Thani.'
      },
      {
        'category': 'Architectural History',
        'title': 'Completion of Great Mosque of Kairouan',
        'description': 'Great Mosque of Kairouan, one of Islam’s oldest mosques, completed in Rabi\' al-Thani.'
      },
      {
        'category': 'Natural Disaster',
        'title': 'Fire in Masjid al-Haram',
        'description': 'Huge fire destroyed parts of Masjid al-Haram in Rabi\' al-Thani (1629 CE).'
      },
      {
        'category': 'Prophetic Diplomacy',
        'title': 'Discussions with Jewish Tribes',
        'description': 'Prophet (SAW) held important discussions with Jewish tribes in Rabi\' al-Thani.'
      },
      {
        'category': 'Scholarly Achievement (Speculated)',
        'title': 'Completion of Major Scholarly Works (Speculated)',
        'description': 'Some historical records suggest early Islamic scholars completed major works in Rabi\' al-Thani.'
      },
      {
        'category': 'Historical Policy Change',
        'title': 'Akbar Lifts Jizya Tax',
        'description': 'Mughal emperor Akbar lifted jizya tax on non-Muslims during Rabi\' al-Thani.'
      },
      {
        'category': 'Military History',
        'title': 'Battles Against Mongols',
        'description': 'Many significant battles against the Mongols occurred in Rabi\' al-Thani.'
      },
      {
        'category': 'Scientific Achievement',
        'title': 'Advancements by Al-Khwarizmi',
        'description': 'Great Islamic mathematician Al-Khwarizmi made major advancements in Rabi\' al-Thani.'
      },
    ],
    5: const [
      {
        'category': 'Military History',
        'title': 'Battle of Yamama',
        'description': 'First major battle after Prophet’s passing, Battle of Yamama (632 CE), took place.'
      },
      {
        'category': 'Financial History',
        'title': 'Establishment of Bayt al-Mal',
        'description': 'Umar ibn Khattab (RA) established Bayt al-Mal (first Islamic treasury) in Jumada al-Awwal.'
      },
      {
        'category': 'Military History',
        'title': 'Battle of Mu\'tah',
        'description': 'Battle of Mu\'tah (629 CE), where 3 Muslim commanders were martyred, happened in Jumada al-Awwal.'
      },
      {
        'category': 'Historical Title',
        'title': 'Khalid Earns Sword of Allah Title',
        'description': 'Khalid ibn Walid earned title ‘Sword of Allah’ in Jumada al-Awwal during Mu’tah.'
      },
      {
        'category': 'Historical Expansion',
        'title': 'First Expansion into Persia',
        'description': 'First Muslim expansion into Persia began in Jumada al-Awwal.'
      },
      {
        'category': 'Biographical',
        'title': 'Birth of Al-Farabi',
        'description': 'Famous Islamic philosopher Al-Farabi was born in Jumada al-Awwal (872 CE).'
      },
      {
        'category': 'Military History',
        'title': 'Al-Mansur’s Campaigns in Andalusia',
        'description': 'Andalusian Muslim ruler, Al-Mansur, launched campaign against Christian kingdoms.'
      },
      {
        'category': 'Linguistic History',
        'title': 'First Quranic Manuscripts with Diacritics',
        'description': 'First Quranic manuscripts with diacritics (dots for pronunciation) appeared in Jumada al-Awwal.'
      },
      {
        'category': 'Religious Text History',
        'title': 'Standardized Quran Copies Commissioned',
        'description': 'Uthman ibn Affan (RA) commissioned first standardized copies of Quran in Jumada al-Awwal.'
      },
      {
        'category': 'Historical Event',
        'title': 'Fall of Abbasid Caliphate in Baghdad',
        'description': 'Mongols executed last Abbasid caliph in Baghdad in Jumada al-Awwal (1258 CE).'
      },
      {
        'category': 'Historical Leadership Claim',
        'title': 'Selim I Declares Caliphate',
        'description': 'Ottoman Sultan Selim I declared himself ‘Caliph of Islam’ in Jumada al-Awwal.'
      },
      {
        'category': 'Military History',
        'title': 'Mamluks Defend Egypt',
        'description': 'Mamluks successfully defended Egypt against Mongols in Jumada al-Awwal.'
      },
      {
        'category': 'Prophetic History',
        'title': 'Ali Takes Prophet’s Place in Mecca',
        'description': 'Prophet (SAW) appointed Ali ibn Abi Talib (RA) to take his place in Mecca during Hijrah.'
      },
      {
        'category': 'Prophetic Family Event',
        'title': 'Fatimah’s Wedding',
        'description': 'Prophet’s daughter, Fatimah (RA), had her wedding in Jumada al-Awwal.'
      },
      {
        'category': 'Social History',
        'title': 'First Islamic Public Baths',
        'description': 'First Islamic public baths (hammams) were built in Jumada al-Awwal.'
      },
    ],
    6: const [
      {
        'category': 'Prophetic Family Event',
        'title': 'Death of Fatimah (RA)',
        'description': 'Prophet’s (SAW) daughter Fatimah (RA) passed away in Jumada al-Thani (some say Rabi\' al-Awwal).'
      },
      {
        'category': 'Military History',
        'title': 'Battle of Ain Jalut',
        'description': 'Battle of Ain Jalut (1260 CE) against Mongols was fought in Jumada al-Thani.'
      },
      {
        'category': 'Historical Event',
        'title': 'Illness of Caliph Abu Bakr',
        'description': 'Caliph Abu Bakr (RA) fell seriously ill in Jumada al-Thani before passing away.'
      },
      {
        'category': 'Historical Diplomacy',
        'title': 'Treaty of Hudaibiyah Discussions Start',
        'description': 'Treaty of Hudaibiyah discussions started in Jumada al-Thani.'
      },
      {
        'category': 'Scientific Achievement',
        'title': 'Discoveries of Al-Tusi',
        'description': 'Great Islamic astronomer Al-Tusi made significant discoveries in Jumada al-Thani.'
      },
      {
        'category': 'Military History',
        'title': 'Khalid’s Campaigns Against Byzantines',
        'description': 'Khalid ibn Walid led decisive campaigns against Byzantines in Jumada al-Thani.'
      },
      {
        'category': 'Architectural History',
        'title': 'Completion of Al-Azhar Mosque',
        'description': 'Construction of Al-Azhar Mosque, leading Islamic university, was completed.'
      },
      {
        'category': 'Historical Planning',
        'title': 'Mehmed II Plans Constantinople Conquest',
        'description': 'Ottoman Sultan Mehmed II began plans to conquer Constantinople in Jumada al-Thani.'
      },
      {
        'category': 'Exploration History',
        'title': 'Ibn Battuta’s Journeys Begin',
        'description': 'Famous Muslim explorer Ibn Battuta started one of his major journeys.'
      },
      {
        'category': 'Prophetic Diplomacy',
        'title': 'Treaties with Bedouin Tribes',
        'description': 'Prophet (SAW) signed key treaties with Bedouin tribes in Jumada al-Thani.'
      },
      {
        'category': 'Historical Pandemic',
        'title': 'Black Death Plague Hits',
        'description': 'Black Death plague hit the Islamic world during Jumada al-Thani.'
      },
      {
        'category': 'Military History',
        'title': 'Ottoman Naval Dominance',
        'description': 'Ottomans established their naval dominance in Jumada al-Thani.'
      },
      {
        'category': 'Linguistic Achievement',
        'title': 'First Organized Arabic Lexicon',
        'description': 'First organized Arabic lexicon was completed by Al-Khalil ibn Ahmad.'
      },
      {
        'category': 'Historical Golden Age',
        'title': 'Harun al-Rashid’s Scientific Advancements',
        'description': 'Caliph Harun al-Rashid’s rule saw peak science advancements in Jumada al-Thani.'
      },
      {
        'category': 'Prophetic Diplomacy',
        'title': 'Meetings with Christian & Jewish Leaders',
        'description': 'Prophet (SAW) met delegations from Christian and Jewish leaders in Jumada al-Thani.'
      },
    ],
    7: const [
      {
        'category': 'Miraculous Event',
        'title': 'Isra and Mi\'raj',
        'description': 'Miraculous journey of Isra and Mi\'raj took place, Prophet (SAW) ascended to heavens.'
      },
      {
        'category': 'Religious Observance',
        'title': 'Sacred Month (Rajab)',
        'description': 'Rajab is one of four sacred months, fighting prohibited in pre-Islamic Arabia and Islam.'
      },
      {
        'category': 'Religious Practice',
        'title': 'First Public Adhan',
        'description': 'First-ever call to prayer (Adhan) was publicly given by Bilal (RA) in Rajab.'
      },
      {
        'category': 'Military Planning',
        'title': 'Preparation for Battle of Tabuk',
        'description': 'Battle of Tabuk, one of Prophet’s last military expeditions, was prepared during Rajab.'
      },
      {
        'category': 'Biographical',
        'title': 'Birth of Umar ibn Abdul Aziz',
        'description': 'Umar ibn Abdul Aziz, often called \'Fifth Rightly Guided Caliph\', was born in Rajab.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Voluntary Fasting in Rajab',
        'description': 'Many Islamic scholars consider Rajab a month for voluntary fasting and increased worship.'
      },
      {
        'category': 'Architectural History',
        'title': 'Baghdad Construction Begins',
        'description': 'Al-Mansur, Abbasid Caliph, began constructing Baghdad, later world\'s greatest Islamic center.'
      },
      {
        'category': 'Military History',
        'title': 'Mongol Invasion of Aleppo',
        'description': 'Mongols invaded and sacked Aleppo in Rajab 658 AH (1260 CE).'
      },
      {
        'category': 'Biographical',
        'title': 'Death of Imam Shafi’i',
        'description': 'Imam Shafi’i, founder of Shafi’i school of thought, passed away in Rajab.'
      },
      {
        'category': 'Prophetic Mission',
        'title': 'Letters to Rulers',
        'description': 'Prophet (SAW) used Rajab to send letters to various rulers inviting them to Islam.'
      },
      {
        'category': 'Historical Conquest',
        'title': 'Selim I Controls Mecca and Medina',
        'description': 'Ottoman Sultan Selim I defeated Mamluks and took control of Mecca and Medina.'
      },
      {
        'category': 'Military History',
        'title': 'Andalusian Naval Raids',
        'description': 'Muslims in Andalusia launched naval raids against Christian forces in Rajab.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Emphasis on Tahajjud Prayers',
        'description': 'Practice of night prayers (Tahajjud) strongly emphasized by early scholars in Rajab.'
      },
      {
        'category': 'Military History',
        'title': 'Salahuddin Captures Crusader Fortresses',
        'description': 'Salahuddin Ayyubi captured key fortresses from Crusaders during Rajab.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Istighfar in Rajab',
        'description': 'Prophet (SAW) encouraged making Istighfar (seeking forgiveness) abundantly in Rajab.'
      },
    ],
    8: const [
      {
        'category': 'Religious Practice',
        'title': 'Qibla Change',
        'description': 'Qibla changed from Jerusalem to Kaaba in Sha’ban, marking a major shift in Islamic practice.'
      },
      {
        'category': 'Religious Observance',
        'title': 'Laylat al-Bara’ah',
        'description': 'Virtuous night, Laylat al-Bara’ah (Night of Forgiveness), occurs on 15th of Sha\'ban.'
      },
      {
        'category': 'Prophetic Practice',
        'title': 'Prophet’s Fasting in Sha’ban',
        'description': 'Aisha (RA) reported Prophet (SAW) fasted more in Sha\'ban than any month except Ramadan.'
      },
      {
        'category': 'Financial History (Speculated)',
        'title': 'Zakat Collection Organized (Speculated)',
        'description': 'Many historians believe Islamic taxation (Zakat collection) was first organized in Sha\'ban.'
      },
      {
        'category': 'Military Planning',
        'title': 'Badr Preparations Intensify',
        'description': 'Battle preparations for Badr intensified in Sha\'ban.'
      },
      {
        'category': 'Historical Imprisonment',
        'title': 'Imprisonment of Ibn Taymiyyah',
        'description': 'Famous scholar Ibn Taymiyyah was imprisoned during Sha\'ban due to controversial views.'
      },
      {
        'category': 'Prophetic Family Event',
        'title': 'Fatimah’s Engagement to Ali',
        'description': 'Fatimah (RA), Prophet’s daughter, was engaged to Ali (RA) during Sha\'ban.'
      },
      {
        'category': 'Religious Advice',
        'title': 'Prepare Wills Before Ramadan',
        'description': 'Prophet (SAW) encouraged writing wills and settling debts before Ramadan.'
      },
      {
        'category': 'Military History',
        'title': 'Mongol Defeat Against Muslims',
        'description': 'Mongols suffered one of their first major defeats against Muslims in Sha\'ban.'
      },
      {
        'category': 'Historical Reforms',
        'title': 'Umar ibn Abdul Aziz’s Reforms',
        'description': 'Umayyad Caliph Umar ibn Abdul Aziz implemented key social reforms in Sha\'ban.'
      },
      {
        'category': 'Scholarly Practice',
        'title': 'Hadith Review by Scholars',
        'description': 'Many scholars of Hadith preferred reviewing collections during Sha\'ban.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Charity in Sha’ban',
        'description': 'Prophet (SAW) urged Muslims to increase charity in Sha\'ban.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Emphasis on Qiyam Prayers',
        'description': 'Night prayer (Qiyam) was given extra emphasis in second half of Sha\'ban.'
      },
      {
        'category': 'Cultural Practice',
        'title': 'Food Preparation for Ramadan',
        'description': 'Muslims in early history used Sha\'ban to prepare food reserves for Ramadan.'
      },
      {
        'category': 'Social Practice',
        'title': 'Mend Relationships Before Ramadan',
        'description': 'Prophet (SAW) encouraged mending broken relationships before entering Ramadan.'
      },
    ],
    9: const [
      {
        'category': 'Religious Revelation',
        'title': 'Quran Revelation Begins',
        'description': 'Quran was first revealed to Prophet (SAW) on Laylat al-Qadr, Night of Decree.'
      },
      {
        'category': 'Military History',
        'title': 'Battle of Badr',
        'description': 'Battle of Badr, first major victory of Islam, took place on 17th of Ramadan.'
      },
      {
        'category': 'Religious Obligation',
        'title': 'Fasting Becomes Obligatory',
        'description': 'Fasting during Ramadan became obligatory in second year after Hijrah.'
      },
      {
        'category': 'Religious Significance',
        'title': 'Doors of Jannah Opened',
        'description': 'Doors of Jannah are opened, doors of Jahannam closed throughout Ramadan.'
      },
      {
        'category': 'Religious Significance',
        'title': 'Satan Chained',
        'description': 'Satan is chained, making it easier for believers to resist temptation in Ramadan.'
      },
      {
        'category': 'Religious Practice',
        'title': 'I’tikaf in Last Ten Nights',
        'description': 'Prophet (SAW) would spend last ten nights in deep seclusion (I’tikaf) in Ramadan.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Taraweeh PrayersWidely Practiced',
        'description': 'Taraweeh prayers, special night worship, became widely practiced during Umar’s Caliphate.'
      },
      {
        'category': 'Historical Conquest',
        'title': 'Conquest of Mecca',
        'description': 'Muslims conquered Mecca in Ramadan, marking a historic turning point.'
      },
      {
        'category': 'Historical Diplomacy',
        'title': 'Treaty of Hudaybiyyah Signed',
        'description': 'Treaty of Hudaybiyyah, pivotal event in Islamic history, was signed in Ramadan.'
      },
      {
        'category': 'Biographical',
        'title': 'Deaths of Key Islamic Figures',
        'description': 'Many key Islamic figures, including Fatimah (RA), passed away in Ramadan.'
      },
      {
        'category': 'Religious Belief',
        'title': 'Revelation of Previous Scriptures',
        'description': 'Believed all previous scriptures (Torah, Psalms, Gospel) were revealed in Ramadan.'
      },
      {
        'category': 'Military History',
        'title': 'Victories in Ramadan Battles',
        'description': 'Muslim soldiers fought and won several battles in Ramadan, including conquest of Spain.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Feeding Others Rewarded',
        'description': 'Prophet (SAW) encouraged feeding others as means of gaining immense reward in Ramadan.'
      },
      {
        'category': 'Religious Reward',
        'title': 'Sins Forgiven for Sincere Fasting',
        'description': 'Said sins are forgiven for those who fast with sincerity in Ramadan.'
      },
      {
        'category': 'Prophetic Revelation',
        'title': 'First Words of Quran Revealed',
        'description': 'Prophet (SAW) received first words of Quran meditating in Cave Hira in Ramadan.'
      },
    ],
    10: const [
      {
        'category': 'Religious Observance',
        'title': 'Eid al-Fitr',
        'description': 'Eid al-Fitr, celebration marking end of Ramadan, takes place on 1st of Shawwal.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Six Days of Shawwal Fasting',
        'description': 'Prophet (SAW) encouraged fasting six days of Shawwal for immense reward.'
      },
      {
        'category': 'Military History',
        'title': 'Battle of Uhud',
        'description': 'Battle of Uhud, challenging test for Muslims, occurred in Shawwal.'
      },
      {
        'category': 'Prophetic Family Event',
        'title': 'Prophet’s Marriage to Aisha Consummated',
        'description': 'Marriage of Prophet (SAW) to Aisha (RA) was consummated in Shawwal.'
      },
      {
        'category': 'Historical Reconstruction',
        'title': 'Kaaba Rebuilt by Quraysh',
        'description': 'Kaaba was rebuilt by Quraysh before Prophet’s prophethood.'
      },
      {
        'category': 'Religious Practice',
        'title': 'First Hajj Under Islam',
        'description': 'First Hajj performed under Islam’s new guidance happened in Shawwal.'
      },
      {
        'category': 'Historical Expansion',
        'title': 'Continued Expansion into Persia & Byzantium',
        'description': 'Muslims continued expanding into Persia and Byzantium after Ramadan.'
      },
      {
        'category': 'Religious Leadership',
        'title': 'Farewell Hajj Preparations',
        'description': 'Prophet (SAW) led farewell Hajj preparations in Shawwal.'
      },
      {
        'category': 'Biographical',
        'title': 'Birth of Imam Muslim',
        'description': 'Imam Muslim, famous Hadith compiler, was born in Shawwal.'
      },
      {
        'category': 'Military History',
        'title': 'Battle of Hunayn Secured',
        'description': 'Battle of Hunayn, where Muslims secured major victory, took place in Shawwal.'
      },
      {
        'category': 'Scholarly Practice',
        'title': 'Hadith Studies Review',
        'description': 'Many Islamic scholars dedicated Shawwal to reviewing Hadith studies.'
      },
      {
        'category': 'Historical Reforms',
        'title': 'Legal Reforms Under Umar',
        'description': 'Caliphate of Umar (RA) saw key legal reforms during Shawwal.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Voluntary Fasting Encouraged',
        'description': 'Practice of voluntary fasting beyond Ramadan was highly encouraged in Shawwal.'
      },
      {
        'category': 'Religious Obligation',
        'title': 'Making Up Missed Ramadan Fasts',
        'description': 'Muslims who missed fasting days in Ramadan were required to make up in Shawwal.'
      },
      {
        'category': 'Scholarly Development',
        'title': 'Formalization of Early Schools of Thought',
        'description': 'Several early Islamic schools of thought were formalized around Shawwal.'
      },
    ],
    11: const [
      {
        'category': 'Religious Observance',
        'title': 'Sacred Month (Dhul Qa’dah)',
        'description': 'One of four sacred months, warfare forbidden in pre-islamic Arabia and Islam.'
      },
      {
        'category': 'Prophetic Practice',
        'title': 'Prophet’s Umrah Journeys',
        'description': 'Most of Prophet’s (SAW) Umrah journeys took place in Dhul Qa’dah.'
      },
      {
        'category': 'Historical Diplomacy',
        'title': 'Treaty of Hudaybiyyah Signed',
        'description': 'Treaty of Hudaybiyyah, allowed Muslims to enter Mecca for pilgrimage, was signed.'
      },
      {
        'category': 'Military Planning',
        'title': 'Preparation for Battle of Khandaq',
        'description': 'Battle of Khandaq (Battle of the Trench), defense of Medina, prepared for in Dhul Qa’dah.'
      },
      {
        'category': 'Military History',
        'title': 'Salahuddin’s Campaigns Against Crusaders',
        'description': 'Salahuddin Ayyubi launched major campaigns against Crusaders in Dhul Qa’dah.'
      },
      {
        'category': 'Religious Practice',
        'title': 'First Official Call for Hajj',
        'description': 'First official call for Hajj after Islam was made in Dhul Qa’dah.'
      },
      {
        'category': 'Prophetic Practice',
        'title': 'Prophet’s Last Umrah',
        'description': 'Prophet (SAW) performed his last Umrah during Dhul Qa’dah.'
      },
      {
        'category': 'Historical Persecution',
        'title': 'Persecution of Scholars',
        'description': 'Many scholars, including Imam Ahmad ibn Hanbal, persecuted under Abbasid rule.'
      },
      {
        'category': 'Historical Consolidation',
        'title': 'Umayyad Dynasty Solidifies Rule',
        'description': 'Umayyad dynasty solidified rule during Dhul Qa’dah after internal conflicts.'
      },
      {
        'category': 'Military History',
        'title': 'Mongol Defeat Against Mamluks',
        'description': 'Mongols suffered rare defeat against Mamluks during Dhul Qa’dah.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Hajj Travel Preparations',
        'description': 'Muslims intending Hajj in Dhul Hijjah start travel preparations in Dhul Qa’dah.'
      },
      {
        'category': 'Architectural History',
        'title': 'Kaaba Repairs',
        'description': 'Kaaba was repaired multiple times in history during Dhul Qa’dah.'
      },
      {
        'category': 'Cultural Practice',
        'title': 'Avoidance of Warfare by Rulers',
        'description': 'Islamic rulers, including Ottomans, avoided warfare in Dhul Qa’dah due to sacredness.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Increase Worship Before Dhul Hijjah',
        'description': 'Prophet (SAW) emphasized increasing worship as Dhul Hijjah approached.'
      },
      {
        'category': 'Prophetic Mission',
        'title': 'Letters to World Leaders',
        'description': 'Prophet (SAW) sent letters to world leaders inviting them to Islam during Dhul Qa’dah.'
      },
    ],
    12: const [
      {
        'category': 'Religious Obligation',
        'title': 'Hajj Pilgrimage',
        'description': 'Hajj, fifth pillar of Islam, takes place in Dhul Hijjah, sacred month.'
      },
      {
        'category': 'Religious Observance',
        'title': 'Eid al-Adha',
        'description': 'Eid al-Adha, "Festival of Sacrifice," commemorates Ibrahim’s willingness to sacrifice son.'
      },
      {
        'category': 'Religious Significance',
        'title': 'First Ten Days Blessed',
        'description': 'First ten days of Dhul Hijjah are considered among most blessed days in Islam.'
      },
      {
        'category': 'Religious Observance',
        'title': 'Day of Arafah',
        'description': 'Day of Arafah, millions gather for prayer, pinnacle of Hajj in Dhul Hijjah.'
      },
      {
        'category': 'Prophetic Event',
        'title': 'Farewell Sermon',
        'description': 'Prophet Muhammad (SAW) gave Farewell Sermon during Hajj, laying down key Islamic principles.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Fasting on Arafah',
        'description': 'Muslims encouraged to fast on Day of Arafah, expiates sins of past and coming year.'
      },
      {
        'category': 'Historical Religious Item',
        'title': 'Repositioning of Black Stone',
        'description': 'Black Stone (Hajr al-Aswad) historically repositioned by Prophet (SAW) before prophethood.'
      },
      {
        'category': 'Cultural Tradition',
        'title': 'Eid al-Adha Announcements',
        'description': 'Islamic empires timed major announcements or celebrations around Eid al-Adha.'
      },
      {
        'category': 'Architectural History',
        'title': 'Kaaba Destruction and Rebuilding',
        'description': 'Kaaba destroyed and rebuilt multiple times throughout history, including in Dhul Hijjah.'
      },
      {
        'category': 'Historical Pilgrimage Support',
        'title': 'Abbasid Hajj Caravans',
        'description': 'Abbasid Caliphs hosted massive Hajj caravans, providing food and security for thousands.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Increase Dhikr',
        'description': 'Islamic scholars emphasized increasing Dhikr (remembrance of Allah) in first ten days.'
      },
      {
        'category': 'Prophetic Warning',
        'title': 'Warning Against Arrogance & Oppression',
        'description': 'Prophet (SAW) warned against arrogance and oppression in his Farewell Sermon.'
      },
      {
        'category': 'Prophetic Prediction',
        'title': 'Divisions After Prophet’s Passing',
        'description': 'Prophet (SAW) predicted after passing, divisions would emerge in Muslim Ummah.'
      },
      {
        'category': 'Military History',
        'title': 'Mongol Reluctance to Attack Mecca & Medina',
        'description': 'Mongols, after sacking Baghdad, showed reluctance in attacking Mecca and Medina.'
      },
      {
        'category': 'Biographical',
        'title': 'Death of Imam Bukhari',
        'description': 'Many famous Islamic scholars, including Imam Bukhari, passed away in Dhul Hijjah.'
      },
      {
        'category': 'Religious Practice',
        'title': 'Avoid Hair/Nail Cutting Before Sacrifice',
        'description': 'Prophet (SAW) advised against cutting hair/nails before sacrifice if intending to offer animal.'
      },
      {
        'category': 'Religious Ritual Symbolism',
        'title': 'Ramy al-Jamarat Symbolism',
        'description': 'Ritual of stoning the devil (Ramy al-Jamarat) symbolizes rejecting evil influences.'
      },
      {
        'category': 'Historical Practice',
        'title': 'Pardoning Political Prisoners',
        'description': 'Common for early Muslim leaders to pardon political prisoners during Dhul Hijjah.'
      },
      {
        'category': 'Prophetic Event',
        'title': 'Farewell Hajj (Only After Prophethood)',
        'description': 'Farewell Hajj was only Hajj performed by Prophet (SAW) after Prophethood.'
      },
      {
        'category': 'Historical Security',
        'title': 'Ottoman Hajj Security',
        'description': 'Many Islamic dynasties, including Ottomans, maintained strict security for Hajj travelers.'
      },
    ],
  };

  static const List<Map<String, String>> _generalFacts = [
    {
      'category': 'General Knowledge',
      'title': 'Meaning of Islam',
      'description': 'The word "Islam" comes from the Arabic root "Salaam," signifying peace and submission to God.'
    },
    {
      'category': 'Inventions',
      'title': 'Origin of Coffee',
      'description': 'Coffee was first discovered by an Ethiopian Muslim shepherd, with Muslims cultivating it.'
    },
    {
      'category': 'Education',
      'title': 'World’s Oldest University',
      'description': 'Al Quaraouiyine in Fez, founded by Fatima Al-Fihri in 859 CE, is the world\'s oldest existing university.'
    },
    {
      'category': 'Architecture',
      'title': 'Introduction of Pointed Arches',
      'description': 'Islamic architecture significantly introduced pointed arches to European architectural styles.'
    },
    {
      'category': 'Science',
      'title': 'Origins of Algebra',
      'description': 'Algebra originates from the Arabic term "al-jabr," developed during the Islamic Golden Age.'
    },
    {
      'category': 'Astronomy',
      'title': 'Arabic Origins of Star Names',
      'description': 'Many star names in astronomy have Arabic origins, reflecting Muslim astronomical advancements.'
    },
    {
      'category': 'Quran',
      'title': 'Unique Memorization of the Quran',
      'description': 'The Quran is distinguished as the only religious text memorized in its entirety by millions throughout history.'
    },
    {
      'category': 'Medicine',
      'title': 'Pioneering Medieval Islamic Hospitals',
      'description': 'Medieval Islamic hospitals were pioneers in implementing medical licensing and specialized wards for patients.'
    },
    {
      'category': 'Calendar',
      'title': 'Continuous Islamic Lunar Calendar',
      'description': 'The Islamic lunar calendar has been in continuous religious use for over 1400 years by Muslims globally.'
    },
    {
      'category': 'Libraries',
      'title': 'Beginnings of Public Libraries',
      'description': 'The concept of public libraries first began in the Islamic world, notably with Baghdad’s House of Wisdom.'
    },
    {
      'category': 'Medicine',
      'title': 'First Use of Catgut Sutures in Surgery',
      'description': 'The first surgeon to employ catgut sutures in surgical procedures was the Muslim physician Al-Zahrawi.'
    },
    {
      'category': 'Mathematics',
      'title': 'Development of Zero and Decimal Fractions',
      'description': 'The mathematical concepts of zero and decimal fractions were significantly developed by Muslim mathematicians.'
    },
    {
      'category': 'Inventions',
      'title': 'Invention of the Mechanical Clock',
      'description': 'The first known mechanical clock was ingeniously invented by the Muslim engineer Al-Jazari.'
    },
    {
      'category': 'Games',
      'title': 'Global Spread of Chess',
      'description': 'Chess spread across the globe largely through the Islamic world, evolving from the Indian game Chaturanga.'
    },
    {
      'category': 'Inventions',
      'title': 'Early Attempt at Human Flight',
      'description': 'The first recorded person to attempt human flight was Abbas Ibn Firnas, a notable Muslim inventor.'
    },
    {
      'category': 'Chemistry',
      'title': 'Development of Modern Soap-Making',
      'description': 'Soap-making in its current form was developed in the Middle East during the Islamic Golden Age, advancing chemistry.'
    },
    {
      'category': 'Medicine',
      'title': 'Early Description of Blood Circulation',
      'description': 'The first known description of blood circulation was written by Ibn Al-Nafis, centuries before William Harvey’s more famous work.'
    },
    {
      'category': 'Gardens',
      'title': 'Influence of Islamic Gardens on European Design',
      'description': 'Islamic gardens significantly influenced European garden design, particularly symmetrical layouts and fountains.'
    },
    {
      'category': 'Education',
      'title': 'World’s First Degree-Granting Institution',
      'description': 'The world\'s first institution recognized as degree-granting was founded by Muslim princess Noor Jahan in India.'
    },
    {
      'category': 'Art',
      'title': 'Popularization of Carpets in Interior Design',
      'description': 'The use of carpets in interior design was widely popularized through rich Islamic artistic and cultural traditions.'
    },
  ];

  static const List<Map<String, String>> _locationBasedFacts = [
    // Middle East
    {
      'category': 'Middle East',
      'region': 'middle_east',
      'title': 'Local Islamic Heritage',
      'description': 'The region is home to the two holiest cities in Islam: Mecca and Medina.'
    },
    {
      'category': 'Middle East',
      'region': 'middle_east',
      'title': 'Baghdad’s House of Wisdom',
      'description': 'During the Islamic Golden Age, Baghdad housed the "House of Wisdom," a leading center of learning.'
    },
    {
      'category': 'Middle East',
      'region': 'middle_east',
      'title': 'Al-Azhar University',
      'description': 'Cairo’s Al-Azhar, founded in 972 CE, is one of the world’s oldest universities and a center for Islamic scholarship.'
    },

    // North Africa
    {
      'category': 'North Africa',
      'region': 'north_africa',
      'title': 'The Great Mosque of Kairouan',
      'description': 'Located in Tunisia, this mosque was a major center of Islamic learning in the early centuries of Islam.'
    },
    {
      'category': 'North Africa',
      'region': 'north_africa',
      'title': 'Al-Qarawiyyin University',
      'description': 'Founded in 859 CE in Fez, Morocco, by Fatima al-Fihri, it is the oldest continuously operating university in the world.'
    },

    // South Asia
    {
      'category': 'South Asia',
      'region': 'south_asia',
      'title': 'Taj Mahal',
      'description': 'Built by Mughal Emperor Shah Jahan in memory of his wife, Mumtaz Mahal, this mausoleum is an architectural masterpiece.'
    },
    {
      'category': 'South Asia',
      'region': 'south_asia',
      'title': 'Islamic Influence in Bengal',
      'description': 'Sufi saints played a major role in the spread of Islam in Bengal, with Khan Jahan Ali being one of the prominent figures.'
    },

    // Southeast Asia
    {
      'category': 'Southeast Asia',
      'region': 'southeast_asia',
      'title': 'Islam in Indonesia',
      'description': 'Indonesia has the largest Muslim population in the world, with Islam introduced through trade and Sufism.'
    },
    {
      'category': 'Southeast Asia',
      'region': 'southeast_asia',
      'title': 'The Sultanate of Malacca',
      'description': 'Malacca was an important Islamic trading hub in the 15th century and played a key role in spreading Islam in the region.'
    },

    // Sub-Saharan Africa
    {
      'category': 'Sub-Saharan Africa',
      'region': 'sub_saharan_africa',
      'title': 'Timbuktu’s Islamic Scholarship',
      'description': 'Timbuktu in Mali was home to Islamic scholars and had thousands of handwritten manuscripts in its libraries.'
    },
    {
      'category': 'Sub-Saharan Africa',
      'region': 'sub_saharan_africa',
      'title': 'Great Mosque of Djenné',
      'description': 'The world’s largest mud-brick building, this Malian mosque is a UNESCO World Heritage site.'
    },

    // Europe
    {
      'category': 'Europe',
      'region': 'europe',
      'title': 'Islamic Spain',
      'description': 'Al-Andalus was a major center of Islamic civilization, known for advancements in science, art, and philosophy.'
    },
    {
      'category': 'Europe',
      'region': 'europe',
      'title': 'Ottoman Influence in the Balkans',
      'description': 'The Ottoman Empire ruled parts of Southeast Europe for centuries, leaving behind significant Islamic architecture.'
    },

    // Central Asia
    {
      'category': 'Central Asia',
      'region': 'central_asia',
      'title': 'Samarkand’s Islamic Architecture',
      'description': 'Samarkand, Uzbekistan, was a key center for Islamic scholarship and home to stunning mosques and madrasas.'
    },
    {
      'category': 'Central Asia',
      'region': 'central_asia',
      'title': 'Bukhara’s Role in Hadith Preservation',
      'description': 'Imam Bukhari, the famous Hadith compiler, was born in Bukhara, now in modern-day Uzbekistan.'
    },

    // North America
    {
      'category': 'North America',
      'region': 'north_america',
      'title': 'First U.S. Mosque',
      'description': 'The first purpose-built mosque in the U.S. was established in Cedar Rapids, Iowa, in 1934.'
    },
    {
      'category': 'North America',
      'region': 'north_america',
      'title': 'Islam in the Caribbean',
      'description': 'Many early Muslims in the Caribbean were indentured laborers from India, helping establish mosques in places like Trinidad and Guyana.'
    },
  ];

  // Define Region Boundaries
  static final List<RegionBoundary> _regions = [
    RegionBoundary(
      name: 'middle_east',
      polygons: const [
        [
          LatLng(35.0, 25.0), LatLng(35.0, 65.0),
          LatLng(12.0, 65.0), LatLng(12.0, 25.0),
        ]
      ],
      bufferZoneKm: 200, // Example buffer zone of 200km
    ),
    RegionBoundary(
      name: 'north_africa',
      polygons: const [
        [
          LatLng(37.0, -17.0), LatLng(37.0, 25.0),
          LatLng(10.0, 25.0), LatLng(10.0, -17.0),
        ]
      ],
      bufferZoneKm: 200,
    ),
    RegionBoundary(
      name: 'south_asia',
      polygons: const [
        [
          LatLng(36.0, 60.0), LatLng(36.0, 90.0),
          LatLng(5.0, 90.0), LatLng(5.0, 60.0),
        ]
      ],
      bufferZoneKm: 200,
    ),
    RegionBoundary(
      name: 'southeast_asia',
      polygons: const [
        [
          LatLng(15.0, 90.0), LatLng(15.0, 140.0),
          LatLng(-10.0, 140.0), LatLng(-10.0, 90.0),
        ]
      ],
      bufferZoneKm: 200,
    ),
    RegionBoundary(
      name: 'sub_saharan_africa',
      polygons: const [
        [
          LatLng(10.0, -17.0), LatLng(10.0, 55.0),
          LatLng(-35.0, 55.0), LatLng(-35.0, -17.0),
        ]
      ],
      bufferZoneKm: 200,
    ),
    RegionBoundary(
      name: 'europe',
      polygons: const [
        [
          LatLng(70.0, -10.0), LatLng(70.0, 40.0),
          LatLng(35.0, 40.0), LatLng(35.0, -10.0),
        ]
      ],
      bufferZoneKm: 200,
    ),
    RegionBoundary(
      name: 'central_asia',
      polygons: const [
        [
          LatLng(55.0, 40.0), LatLng(55.0, 85.0),
          LatLng(35.0, 85.0), LatLng(35.0, 40.0),
        ]
      ],
      bufferZoneKm: 200,
    ),
    RegionBoundary(
      name: 'north_america',
      polygons: const [
        [
          LatLng(50.0, -130.0), LatLng(50.0, -60.0),
          LatLng(25.0, -60.0), LatLng(25.0, -130.0),
        ]
      ],
      bufferZoneKm: 200,
    ),
  ];

  // Get facts based on location, user interactions, and search history
  static List<IslamicFact> getPersonalizedFacts({
    required LatLng? userLocation,
    required List<String> recentInteractions,
    required List<String> recentSearches,
  }) {
    // Start with all available facts
    List<IslamicFact> candidateFacts = [];

    // Add interaction-based facts
    if (recentInteractions.isNotEmpty) {
      for (var interaction in recentInteractions) {
        candidateFacts.addAll(getFactsByInteraction(interaction));
      }
    }

    // Add location-based facts if location is available
    if (userLocation != null) {
      String userRegion = _determineUserRegion(userLocation);
      var locationFacts = _locationBasedFacts
          .where((fact) => fact['region'] == userRegion)
          .map((map) => IslamicFact.fromMap(map))
          .toList();
      candidateFacts.addAll(locationFacts);
    }

    // If we don't have enough personalized facts, add some general ones
    if (candidateFacts.length < 5) {
      candidateFacts.addAll(generalFacts);
    }

    // Shuffle to randomize while maintaining personalization
    candidateFacts.shuffle();

    // Return a subset of facts
    return candidateFacts.take(5).toList();
  }

  static String _determineUserRegion(LatLng location) {
    for (var region in _regions) {
      for (var polygon in region.polygons) {
        if (_isPointInPolygon(location, polygon, region.bufferZoneKm)) {
          return region.name;
        }
      }
    }
    return 'general';  // Default region
  }

  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon, double bufferKm) {
    // Check if point is within buffer zone of any polygon edge
    for (int i = 0; i < polygon.length; i++) {
      var j = (i + 1) % polygon.length;

      // Convert LatLng to Position for Geolocator
      Position pointPosition = Position(
        latitude: point.latitude,
        longitude: point.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      Position edgeStartPosition = Position(
        latitude: polygon[i].latitude,
        longitude: polygon[i].longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      // Use Geolocator's distanceBetween method
      double distance = Geolocator.distanceBetween(
        pointPosition.latitude,
        pointPosition.longitude,
        edgeStartPosition.latitude,
        edgeStartPosition.longitude,
      );

      // Convert distance to kilometers
      if (distance / 1000 <= bufferKm) {
        return true;
      }
    }

    // Ray casting algorithm for point-in-polygon check
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if ((polygon[i].latitude > point.latitude) !=
          (polygon[j].latitude > point.latitude) &&
          point.longitude < (polygon[j].longitude - polygon[i].longitude) *
              (point.latitude - polygon[i].latitude) /
              (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude) {
        inside = !inside;
      }
    }

    return inside;
  }
}