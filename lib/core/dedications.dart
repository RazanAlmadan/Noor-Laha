// Short duas shown on the home screen dedication card.
// To add a new dua, just add a new string to the list below.
const List<String> kDedications = [
  'اللهم ارحمها برحمتك الواسعة، واغفر لها، واجعل قبرها روضةً من رياض الجنة.',
  'اللهم اجعل القرآن نورًا في قبرها، وأنيسًا لوحشتها، وسببًا لرفعة درجاتها.',
  'اللهم صلِّ على محمد وآل محمد، واغفر لها وارحمها، وأسكنها فسيح جناتك.',
  'اللهم آنس وحشتها، ونوّر مرقدها، واجعلها في أمنٍ وسلامٍ وطمأنينة.',
  'اللهم احشرها مع محمد وآله الطاهرين، وارزقها شفاعتهم برحمتك يا أرحم الراحمين.',
  'يا واسع المغفرة، تجاوز عن سيئاتها، وضاعف حسناتها، وأكرم نُزُلها.',
  'اللهم ارفع مقامها في عليّين، واجعلها من المنعّمين برحمتك ورضوانك.',
  'اللهم اجعل كل آيةٍ تُتلى سببًا في نزول رحمتك عليها، ورفعة منزلتها عندك.',
  'اللهم أبدل وحشتها أُنسًا، وظلمة قبرها نورًا، واجعل رحمتك تحيط بها.',
  'اللهم افتح لها أبواب رحمتك، وأسكنها جنات النعيم، وأكرمها بعفوك ورضاك.',
  'اللهم بحق محمد وآل محمد، ارحمها واغفر لها، واجعلها من أهل جنتك.',
  'اللهم اجزها عن إحسانها إحسانًا، وعن تقصيرها عفوًا وغفرانًا، يا أكرم الأكرمين.',
  'اللهم اجمعها بمن تحب من عبادك الصالحين، في دار كرامتك ورحمتك.',
  'اللهم تقبّل ما نُهديه من ثواب أعمال الخير، واجعله نورًا ورحمةً لها في قبرها.',
  'اللهم لا تحرمها سعة رحمتك، ولا عظيم مغفرتك، واجعلها في جوار رحمتك أبدًا.',
];

// Name of the deceased. We will use it on the opening page and the about page.
const String kDeceasedName = 'ريم مرتضى الشبر';
// Full wording of the name on the opening page.
const String kDedicationName = 'السيدة ريم مرتضى آل شبر';

// Index of today's dua. It changes at midnight (phone's local date) and walks
// through the whole list before repeating.
int todaysDedicationIndex() {
  final DateTime now = DateTime.now();
  // DateTime.utc on the local Y/M/D counts calendar days only, so a daylight
  // saving change can never shift the result.
  final int days = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(2026, 1, 1))
      .inDays;
  return days % kDedications.length;
}