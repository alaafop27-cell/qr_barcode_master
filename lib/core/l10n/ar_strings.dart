/// Arabic translations. The key is the exact English text used in the code;
/// anything missing here simply shows in English.
///
/// Placeholders such as {n} are replaced by the code, keep them unchanged.
const Map<String, String> arStrings = {
  // ---- navigation / general
  'Home': 'الرئيسية',
  'Scan': 'مسح',
  'Create': 'إنشاء',
  'History': 'السجل',
  'Settings': 'الإعدادات',
  'QR & Barcode Master': 'ماسح QR والباركود',
  'Scan • Create • Manage': 'مسح • إنشاء • إدارة',
  'Scan, create and manage codes': 'امسح الأكواد وأنشئها وأدرها',
  'Cancel': 'إلغاء',
  'Clear': 'مسح',
  'Undo': 'تراجع',
  'Copied': 'تم النسخ',
  'Copy': 'نسخ',
  'Share': 'مشاركة',
  'Required': 'مطلوب',
  'Yes': 'نعم',
  'None': 'بدون',

  // ---- home
  'Scan now': 'امسح الآن',
  'From image': 'من صورة',
  'Create a code': 'إنشاء كود',
  'Create a barcode': 'إنشاء باركود',
  'Reads everything': 'يقرأ كل الأنواع',
  'Works offline': 'يعمل بدون إنترنت',
  'Private': 'خصوصية تامة',
  'Instant scan': 'مسح فوري',
  'Recent': 'الأحدث',
  'See all': 'عرض الكل',
  'Your scanned and created codes will appear here.':
      'ستظهر هنا الأكواد التي تمسحها أو تنشئها.',
  'Created': 'منشأ',
  'Generated': 'منشأ',
  'Scanned': 'ممسوح',

  // ---- scanner
  'Flashlight': 'كشاف الضوء',
  'Scan from image': 'مسح من صورة',
  'Switch camera': 'تبديل الكاميرا',
  'No QR code or barcode found in that image':
      'لم يتم العثور على رمز QR أو باركود في هذه الصورة',
  'Camera permission is required to scan. Enable it in the phone Settings under Apps > Permissions.':
      'إذن الكاميرا مطلوب للمسح. فعّله من إعدادات الهاتف ← التطبيقات ← الأذونات.',
  'The camera is not available.': 'الكاميرا غير متاحة.',

  // ---- result
  'No app found to open this': 'لا يوجد تطبيق لفتح هذا',
  'Raw content': 'المحتوى الخام',
  'Cannot render QR': 'تعذر عرض رمز QR',

  // ---- code types
  'Website': 'الموقع الإلكتروني',
  'Wi-Fi': 'واي فاي',
  'Contact': 'جهة اتصال',
  'Email': 'البريد الإلكتروني',
  'Phone': 'الهاتف',
  'SMS': 'رسالة SMS',
  'Location': 'الموقع',
  'Calendar event': 'حدث تقويم',
  'Product': 'منتج',
  'Text': 'نص',
  'QR Code': 'رمز QR',

  // ---- parsed field names
  'URL': 'الرابط',
  'Format': 'النوع',
  'Network': 'الشبكة',
  'Wi-Fi network': 'شبكة واي فاي',
  'Security': 'الحماية',
  'Open network': 'مفتوحة',
  'Password': 'كلمة المرور',
  'Hidden': 'مخفية',
  'To': 'إلى',
  'Subject': 'الموضوع',
  'Message': 'الرسالة',
  'Number': 'الرقم',
  'Latitude': 'خط العرض',
  'Longitude': 'خط الطول',
  'Name': 'الاسم',
  'Organization': 'المؤسسة',
  'Address': 'العنوان',
  'Note': 'ملاحظة',
  'Job title': 'المسمى الوظيفي',
  'Title': 'اسم الحدث',
  'Starts': 'يبدأ',
  'Ends': 'ينتهي',
  'Description': 'الوصف',

  // ---- actions
  'Open': 'فتح',
  'Copy link': 'نسخ الرابط',
  'Search web': 'بحث في الويب',
  'Search product': 'بحث عن المنتج',
  'Copy number': 'نسخ الرقم',
  'Copy password': 'نسخ كلمة المرور',
  'Copy name': 'نسخ الاسم',
  'Send email': 'إرسال بريد',
  'Copy address': 'نسخ العنوان',
  'Call': 'اتصال',
  'Send SMS': 'إرسال رسالة',
  'Open in Maps': 'فتح في الخرائط',
  'Copy coordinates': 'نسخ الإحداثيات',
  'Copy details': 'نسخ التفاصيل',
  'Open location': 'فتح الموقع',

  // ---- generator
  'Create code': 'إنشاء كود',
  'QR code': 'رمز QR',
  'Barcode': 'باركود',
  'Website address (e.g. example.com)': 'عنوان الموقع (مثال: example.com)',
  'Phone number': 'رقم الهاتف',
  'Network name (SSID)': 'اسم الشبكة (SSID)',
  'Hidden network': 'شبكة مخفية',
  'Full name': 'الاسم الكامل',
  'Email address': 'عنوان البريد الإلكتروني',
  'Latitude (e.g. 30.0444)': 'خط العرض (مثال: 30.0444)',
  'Longitude (e.g. 31.2357)': 'خط الطول (مثال: 31.2357)',
  'QR color': 'لون الرمز',
  'Generate': 'إنشاء',
  'Content is too long': 'المحتوى طويل جدًا',
  'Copy content': 'نسخ المحتوى',
  'Share image': 'مشاركة الصورة',
  'Invalid email': 'بريد إلكتروني غير صالح',
  'Number between -{n} and {n}': 'رقم بين -{n} و{n}',

  // ---- barcode generator
  'Barcode content': 'محتوى الباركود',
  'Generate barcode': 'إنشاء الباركود',
  'Number with check digit': 'الرقم مع رقم التحقق',
  'Letters, digits and symbols (English), up to 20 characters':
      'حروف إنجليزية وأرقام ورموز، حتى 20 حرفًا',
  '12 digits - the 13th (check) digit is added automatically':
      '12 رقمًا - يُضاف الرقم الثالث عشر (رقم التحقق) تلقائيًا',
  '7 digits - the 8th (check) digit is added automatically':
      '7 أرقام - يُضاف الرقم الثامن (رقم التحقق) تلقائيًا',
  'Digits only': 'أرقام فقط',
  'Enter 12 digits (or all 13 including the check digit)':
      'أدخل 12 رقمًا (أو 13 رقمًا شاملة رقم التحقق)',
  'Enter 7 digits (or all 8 including the check digit)':
      'أدخل 7 أرقام (أو 8 أرقام شاملة رقم التحقق)',
  'Wrong check digit (it should be {n})': 'رقم التحقق خاطئ (الصحيح {n})',
  'Enter some text': 'أدخل نصًا',
  'Maximum 20 characters': 'الحد الأقصى 20 حرفًا',
  'Only English letters, digits and symbols are supported':
      'المدعوم فقط: الحروف الإنجليزية والأرقام والرموز',

  // ---- history
  'Search': 'بحث',
  'All': 'الكل',
  'Favorites': 'المفضلة',
  'Nothing here yet': 'لا يوجد شيء هنا بعد',
  'Deleted': 'تم الحذف',
  'Clear all': 'مسح الكل',
  'Clear history?': 'مسح السجل؟',
  'All saved scans and generated codes will be deleted.':
      'سيتم حذف كل الأكواد الممسوحة والمنشأة المحفوظة.',

  // ---- settings
  'Appearance': 'المظهر',
  'System': 'النظام',
  'Light': 'فاتح',
  'Dark': 'داكن',
  'Scanning': 'المسح',
  'Beep on scan': 'صوت عند المسح',
  'Vibrate on scan': 'اهتزاز عند المسح',
  'Data': 'البيانات',
  'Save history': 'حفظ السجل',
  'Scanned and generated codes stay on this device':
      'تبقى الأكواد الممسوحة والمنشأة على هذا الجهاز فقط',
  'Clear history': 'مسح السجل',
  'This cannot be undone.': 'لا يمكن التراجع عن هذا.',
  'History cleared': 'تم مسح السجل',
  'Version 1.3.0 - works fully offline':
      'الإصدار 1.3.0 - يعمل بالكامل بدون إنترنت',

  // ---- privacy / onboarding
  'Privacy policy': 'سياسة الخصوصية',
  'Skip': 'تخطي',
  'Next': 'التالي',
  'Get started': 'ابدأ الآن',
  'Scan anything': 'امسح أي شيء',
  'QR codes and all common barcodes, live from the camera or from a photo in your gallery.':
      'أكواد QR وكل أنواع الباركود الشائعة مباشرة من الكاميرا أو من صورة في المعرض.',
  'Create your own codes': 'أنشئ أكوادك بنفسك',
  'Make QR codes for links, Wi-Fi, contacts and more, plus Code 128 and EAN barcodes. Save or share them.':
      'أنشئ أكواد QR للروابط والواي فاي وجهات الاتصال وغيرها، بالإضافة إلى باركود Code 128 وEAN. احفظها أو شاركها.',
  'Private and offline': 'خاص ويعمل بدون إنترنت',
  'Everything stays on your device. No account, no tracking, and your history is yours to clear.':
      'كل شيء يبقى على جهازك. بدون حساب وبدون تتبع، وسجلك تمسحه وقتما تشاء.',
};
