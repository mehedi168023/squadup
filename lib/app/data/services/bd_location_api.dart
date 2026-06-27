/// A Bangladesh division (e.g. Dhaka, Khulna). [id] is needed to look up the
/// division's districts.
///
/// This module previously fetched data live from a free public geo API
/// (`bdapi.vercel.app`). It now ships a bundled local snapshot of all
/// divisions and their districts so the app runs fully offline with mock data
/// — the public API is no longer contacted.
class BdDivision {
  final String id;
  final String name; // English name
  final String bnName; // Bangla name
  const BdDivision(
      {required this.id, required this.name, required this.bnName});

  // Dropdown value equality by id so a rebuilt list still matches the selection.
  @override
  bool operator ==(Object other) => other is BdDivision && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// A district that belongs to a [BdDivision].
class BdDistrict {
  final String id;
  final String name;
  final String bnName;
  const BdDistrict(
      {required this.id, required this.name, required this.bnName});

  @override
  bool operator ==(Object other) => other is BdDistrict && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Local (offline) snapshot of Bangladesh's administrative divisions and their
/// districts. Replaces the former live HTTP geo client so the app needs no
/// network connection.
class BdLocationApi {
  BdLocationApi._();

  static const List<BdDivision> _divisions = [
    BdDivision(id: '1', name: 'Barishal', bnName: 'বরিশাল'),
    BdDivision(id: '2', name: 'Chattogram', bnName: 'চট্টগ্রাম'),
    BdDivision(id: '3', name: 'Dhaka', bnName: 'ঢাকা'),
    BdDivision(id: '4', name: 'Khulna', bnName: 'খুলনা'),
    BdDivision(id: '5', name: 'Mymensingh', bnName: 'ময়মনসিংহ'),
    BdDivision(id: '6', name: 'Rajshahi', bnName: 'রাজশাহী'),
    BdDivision(id: '7', name: 'Rangpur', bnName: 'রংপুর'),
    BdDivision(id: '8', name: 'Sylhet', bnName: 'সিলেট'),
  ];

  static const Map<String, List<BdDistrict>> _districtsByDivision = {
    '1': [
      BdDistrict(id: '1', name: 'Barguna', bnName: 'বরগুনা'),
      BdDistrict(id: '2', name: 'Barishal', bnName: 'বরিশাল'),
      BdDistrict(id: '3', name: 'Bhola', bnName: 'ভোলা'),
      BdDistrict(id: '4', name: 'Jhalokati', bnName: 'ঝালকাঠি'),
      BdDistrict(id: '5', name: 'Patuakhali', bnName: 'পটুয়াখালী'),
      BdDistrict(id: '6', name: 'Pirojpur', bnName: 'পিরোজপুর'),
    ],
    '2': [
      BdDistrict(id: '7', name: 'Bandarban', bnName: 'বান্দরবান'),
      BdDistrict(id: '8', name: 'Brahmanbaria', bnName: 'ব্রাহ্মণবাড়িয়া'),
      BdDistrict(id: '9', name: 'Chandpur', bnName: 'চাঁদপুর'),
      BdDistrict(id: '10', name: 'Chattogram', bnName: 'চট্টগ্রাম'),
      BdDistrict(id: '11', name: "Cox's Bazar", bnName: "কক্সবাজার"),
      BdDistrict(id: '12', name: 'Cumilla', bnName: 'কুমিল্লা'),
      BdDistrict(id: '13', name: "Feni", bnName: 'ফেনী'),
      BdDistrict(id: '14', name: 'Khagrachhari', bnName: 'খাগড়াছড়ি'),
      BdDistrict(id: '15', name: 'Lakshmipur', bnName: 'লক্ষ্মীপুর'),
      BdDistrict(id: '16', name: 'Noakhali', bnName: 'নোয়াখালী'),
      BdDistrict(id: '17', name: 'Rangamati', bnName: 'রাঙ্গামাটি'),
    ],
    '3': [
      BdDistrict(id: '18', name: 'Dhaka', bnName: 'ঢাকা'),
      BdDistrict(id: '19', name: 'Faridpur', bnName: 'ফরিদপুর'),
      BdDistrict(id: '20', name: 'Gazipur', bnName: 'গাজীপুর'),
      BdDistrict(id: '21', name: 'Gopalganj', bnName: 'গোপালগঞ্জ'),
      BdDistrict(id: '22', name: 'Kishoreganj', bnName: 'কিশোরগঞ্জ'),
      BdDistrict(id: '23', name: 'Madaripur', bnName: 'মাদারীপুর'),
      BdDistrict(id: '24', name: 'Manikganj', bnName: 'মানিকগঞ্জ'),
      BdDistrict(id: '25', name: 'Munshiganj', bnName: 'মুন্সিগঞ্জ'),
      BdDistrict(id: '26', name: 'Narayanganj', bnName: 'নারায়ণগঞ্জ'),
      BdDistrict(id: '27', name: 'Narsingdi', bnName: 'নরসিংদী'),
      BdDistrict(id: '28', name: 'Rajbari', bnName: 'রাজবাড়ী'),
      BdDistrict(id: '29', name: 'Shariatpur', bnName: 'শরীয়তপুর'),
      BdDistrict(id: '30', name: 'Tangail', bnName: 'টাঙ্গাইল'),
    ],
    '4': [
      BdDistrict(id: '31', name: 'Bagerhat', bnName: 'বাগেরহাট'),
      BdDistrict(id: '32', name: 'Chuadanga', bnName: 'চুয়াডাঙ্গা'),
      BdDistrict(id: '33', name: 'Jashore', bnName: 'যশোর'),
      BdDistrict(id: '34', name: 'Jhenaidah', bnName: 'ঝিনাইদহ'),
      BdDistrict(id: '35', name: 'Khulna', bnName: 'খুলনা'),
      BdDistrict(id: '36', name: 'Kushtia', bnName: 'কুষ্টিয়া'),
      BdDistrict(id: '37', name: 'Magura', bnName: 'মাগুরা'),
      BdDistrict(id: '38', name: 'Meherpur', bnName: 'মেহেরপুর'),
      BdDistrict(id: '39', name: 'Narail', bnName: 'নড়াইল'),
      BdDistrict(id: '40', name: 'Satkhira', bnName: 'সাতক্ষীরা'),
    ],
    '5': [
      BdDistrict(id: '41', name: 'Jamalpur', bnName: 'জামালপুর'),
      BdDistrict(id: '42', name: 'Mymensingh', bnName: 'ময়মনসিংহ'),
      BdDistrict(id: '43', name: 'Netrokona', bnName: 'নেত্রকোণা'),
      BdDistrict(id: '44', name: 'Sherpur', bnName: 'শেরপুর'),
    ],
    '6': [
      BdDistrict(id: '45', name: 'Bogura', bnName: 'বগুড়া'),
      BdDistrict(id: '46', name: 'Chapainawabganj', bnName: 'চাঁপাইনবাবগঞ্জ'),
      BdDistrict(id: '47', name: 'Joypurhat', bnName: 'জয়পুরহাট'),
      BdDistrict(id: '48', name: 'Naogaon', bnName: 'নওগাঁ'),
      BdDistrict(id: '49', name: 'Natore', bnName: 'নাটোর'),
      BdDistrict(id: '50', name: "Chapai", bnName: 'নবাবগঞ্জ'),
      BdDistrict(id: '51', name: 'Pabna', bnName: 'পাবনা'),
      BdDistrict(id: '52', name: 'Rajshahi', bnName: 'রাজশাহী'),
      BdDistrict(id: '53', name: 'Sirajganj', bnName: 'সিরাজগঞ্জ'),
    ],
    '7': [
      BdDistrict(id: '54', name: 'Dinajpur', bnName: 'দিনাজপুর'),
      BdDistrict(id: '55', name: 'Gaibandha', bnName: 'গাইবান্ধা'),
      BdDistrict(id: '56', name: 'Kurigram', bnName: 'কুড়িগ্রাম'),
      BdDistrict(id: '57', name: 'Lalmonirhat', bnName: 'লালমনিরহাট'),
      BdDistrict(id: '58', name: 'Nilphamari', bnName: 'নীলফামারী'),
      BdDistrict(id: '59', name: 'Panchagarh', bnName: 'পঞ্চগড়'),
      BdDistrict(id: '60', name: 'Rangpur', bnName: 'রংপুর'),
      BdDistrict(id: '61', name: 'Thakurgaon', bnName: 'ঠাকুরগাঁ'),
    ],
    '8': [
      BdDistrict(id: '62', name: 'Habiganj', bnName: 'হবিগঞ্জ'),
      BdDistrict(id: '63', name: "Moulvibazar", bnName: 'মৌলভীবাজার'),
      BdDistrict(id: '64', name: 'Sunamganj', bnName: 'সুনামগঞ্জ'),
      BdDistrict(id: '65', name: 'Sylhet', bnName: 'সিলেট'),
    ],
  };

  /// Returns all divisions. Resolves after a short delay to mirror the previous
  /// async HTTP signature (keeps the loading spinner UI working unchanged).
  static Future<List<BdDivision>> divisions() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<BdDivision>.unmodifiable(_divisions);
  }

  /// Returns the districts for [divisionId]. Resolves after a short delay to
  /// mirror the previous async HTTP signature.
  static Future<List<BdDistrict>> districts(String divisionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final list = _districtsByDivision[divisionId] ?? const <BdDistrict>[];
    return List<BdDistrict>.unmodifiable(list);
  }
}
