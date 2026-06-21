import 'package:flutter/material.dart';

class InfoSectionData {
  const InfoSectionData({
    required this.title,
    required this.body,
    required this.icon,
    this.bullets = const [],
  });

  final String title;
  final String body;
  final IconData icon;
  final List<String> bullets;
}

class InfoContent {
  InfoContent._();

  static const footer = 'Harvest & Hearth by Samsung Electronics Co. ltd';

  static List<InfoSectionData> securitySections(String language) =>
      language == 'ENG' ? _securityEng : _securityVie;

  static List<InfoSectionData> helpSections(String language) =>
      language == 'ENG' ? _helpEng : _helpVie;

  // ── Security Info ───────────────────────────────────────────────────────────

  static const _securityVie = [
    InfoSectionData(
      icon: Icons.verified_user_outlined,
      title: 'Tổng quan bảo mật',
      body:
          'Harvest & Hearth được thiết kế để quản lý kho thực phẩm, công thức và kế hoạch bữa ăn cá nhân. '
          'Chúng tôi ưu tiên bảo vệ tài khoản, dữ liệu đồng bộ và giảm thiểu dữ liệu không cần thiết.',
    ),
    InfoSectionData(
      icon: Icons.business_outlined,
      title: 'Đăng ký & phát triển',
      body:
          'Sản phẩm được đăng ký công nghệ và phát triển bởi Samsung Electronics Co., Ltd. '
          'Harvest & Hearth là giải pháp quản lý bếp thông minh trong hệ sinh thái công nghệ tiêu dùng, '
          'tuân thủ các tiêu chuẩn bảo mật và quy trình phát triển phần mềm của Samsung.',
    ),
    InfoSectionData(
      icon: Icons.lock_person_outlined,
      title: 'Xác thực tài khoản',
      body:
          'Đăng nhập qua Clerk (email hoặc Google). Phiên làm việc được bảo vệ bằng token JWT; '
          'app không lưu mật khẩu thô trên thiết bị.',
      bullets: [
        'Mỗi yêu cầu API gửi kèm Bearer token từ phiên Clerk hiện tại.',
        'Đăng xuất sẽ xóa phiên cục bộ và ngắt kết nối backend.',
        'Không chia sẻ tài khoản với người khác.',
      ],
    ),
    InfoSectionData(
      icon: Icons.cloud_sync_outlined,
      title: 'Dữ liệu lưu trữ & đồng bộ',
      body:
          'Dữ liệu chính (kho thực phẩm, công thức đã lưu, công thức tự tạo, nhật ký thông báo, hồ sơ) '
          'được lưu trên server MongoDB qua API Node.js. Một số tùy chọn (ngôn ngữ, giao diện, meal plan, '
          'shopping list) được lưu cục bộ bằng SharedPreferences trên thiết bị.',
      bullets: [
        'Kho đồ & công thức: đồng bộ theo user_id trên server.',
        'Meal plan & shopping list: lưu cục bộ, không gửi lên server trừ khi bạn thêm vào kho.',
        'Không lưu API key Groq/Gemini hay Clerk secret trong mã nguồn client công khai.',
      ],
    ),
    InfoSectionData(
      icon: Icons.smart_toy_outlined,
      title: 'AI & dịch vụ bên thứ ba',
      body:
          'Hearthie (chat, gợi ý công thức) và tìm kiếm công thức có thể gửi tên nguyên liệu, '
          'mô tả món và ngôn ngữ tới Groq Cloud hoặc Google Gemini khi bạn chủ động sử dụng. '
          'Dịch vụ tìm kiếm (TheMealDB, DummyJSON, web) chỉ nhận từ khóa bạn nhập.',
      bullets: [
        'Không gửi mật khẩu hay token Clerk cho nhà cung cấp AI.',
        'Nội dung chat có thể được cache cục bộ ngắn hạn để phản hồi nhanh hơn.',
        'Bạn có thể xóa lịch sử chat trong màn Hearthie.',
      ],
    ),
    InfoSectionData(
      icon: Icons.notifications_outlined,
      title: 'Thông báo & quyền thiết bị',
      body:
          'Nhắc hạn sử dụng thông báo cục bộ (Android/iOS) và widget màn hình chính (Android). '
          'App chỉ lên lịch thông báo dựa trên dữ liệu hạn sử dụng trong kho của bạn.',
      bullets: [
        'Cần cấp quyền thông báo để nhận nhắc hạn.',
        'Tắt nhắc hạn trong Cài đặt sẽ hủy lịch thông báo.',
        'Nhật ký thông báo có thể đồng bộ lên server để xem lại trong Trung tâm thông báo.',
      ],
    ),
    InfoSectionData(
      icon: Icons.shield_outlined,
      title: 'Quyền riêng tư của bạn',
      body:
          'Bạn có thể xem, cập nhật hoặc xóa dữ liệu kho và công thức trong app. '
          'Đăng xuất không xóa dữ liệu trên server — dữ liệu gắn với tài khoản Clerk của bạn.',
      bullets: [
        'Không bán dữ liệu cá nhân cho bên thứ ba.',
        'Chỉ gửi dữ liệu cần thiết cho chức năng bạn đang dùng.',
        'Kiểm tra dị ứng và an toàn thực phẩm trước khi nấu — AI chỉ mang tính gợi ý.',
      ],
    ),
  ];

  static const _securityEng = [
    InfoSectionData(
      icon: Icons.verified_user_outlined,
      title: 'Security overview',
      body:
          'Harvest & Hearth is designed to manage your personal food inventory, recipes, and meal plans. '
          'We prioritize account protection, synced data security, and minimizing unnecessary data collection.',
    ),
    InfoSectionData(
      icon: Icons.business_outlined,
      title: 'Registration & development',
      body:
          'This product is registered for technology and developed by Samsung Electronics Co., Ltd. '
          'Harvest & Hearth is a smart kitchen management solution within Samsung\'s consumer technology ecosystem, '
          'following Samsung software development and security standards.',
    ),
    InfoSectionData(
      icon: Icons.lock_person_outlined,
      title: 'Account authentication',
      body:
          'Sign-in is handled by Clerk (email or Google). Sessions are protected with JWT tokens; '
          'the app does not store raw passwords on device.',
      bullets: [
        'Each API request includes a Bearer token from your active Clerk session.',
        'Sign-out clears the local session and disconnects from the backend.',
        'Do not share your account with others.',
      ],
    ),
    InfoSectionData(
      icon: Icons.cloud_sync_outlined,
      title: 'Data storage & sync',
      body:
          'Core data (inventory, saved recipes, custom recipes, notification logs, profile) is stored on '
          'MongoDB via a Node.js API. Some preferences (language, theme, meal plans, shopping lists) are '
          'stored locally with SharedPreferences.',
      bullets: [
        'Inventory & recipes: synced per user_id on the server.',
        'Meal plans & shopping lists: stored locally unless you add items to inventory.',
        'Groq/Gemini and Clerk secrets are not embedded in the public client.',
      ],
    ),
    InfoSectionData(
      icon: Icons.smart_toy_outlined,
      title: 'AI & third-party services',
      body:
          'Hearthie (chat, recipe suggestions) and recipe search may send ingredient names, dish descriptions, '
          'and language to Groq Cloud or Google Gemini when you actively use those features. '
          'Search providers (TheMealDB, DummyJSON, web) only receive keywords you enter.',
      bullets: [
        'Passwords and Clerk tokens are never sent to AI providers.',
        'Chat content may be cached locally for a short time to improve response speed.',
        'You can clear chat history in the Hearthie screen.',
      ],
    ),
    InfoSectionData(
      icon: Icons.notifications_outlined,
      title: 'Notifications & device permissions',
      body:
          'Expiry reminders use local notifications (Android/iOS) and home screen widgets (Android). '
          'The app schedules alerts based on expiry data in your inventory only.',
      bullets: [
        'Notification permission is required to receive expiry reminders.',
        'Disabling reminders in Settings cancels scheduled notifications.',
        'Notification logs may sync to the server for the Notifications center.',
      ],
    ),
    InfoSectionData(
      icon: Icons.shield_outlined,
      title: 'Your privacy',
      body:
          'You can view, update, or delete inventory and recipe data in the app. '
          'Signing out does not delete server data — it remains linked to your Clerk account.',
      bullets: [
        'We do not sell personal data to third parties.',
        'Only data required for the feature you use is transmitted.',
        'Verify allergies and food safety before cooking — AI output is advisory only.',
      ],
    ),
  ];

  // ── Help Center ───────────────────────────────────────────────────────────

  static const _helpVie = [
    InfoSectionData(
      icon: Icons.rocket_launch_outlined,
      title: 'Bắt đầu',
      body:
          'Đăng nhập bằng email hoặc Google, sau đó thêm thực phẩm vào kho (tủ lạnh, đông lạnh, kệ). '
          'Dashboard hiển thị tổng quan, thời tiết và lối tắt tới các tính năng chính.',
      bullets: [
        'Quét mã vạch hoặc nhập tay khi thêm thực phẩm.',
        'Đặt ngày hết hạn để nhận nhắc đúng lúc.',
        'Chuyển VIE/ENG và dark mode trong Hồ sơ.',
      ],
    ),
    InfoSectionData(
      icon: Icons.kitchen_outlined,
      title: 'Quản lý kho',
      body:
          'Tab Kho đồ liệt kê thực phẩm theo vị trí bảo quản. Bạn có thể sửa số lượng, hạn dùng, '
          'xóa món hoặc cấu hình số ngày cảnh báo mặc định theo danh mục trong Cài đặt.',
    ),
    InfoSectionData(
      icon: Icons.menu_book_outlined,
      title: 'Công thức',
      body: 'Tab Công thức gồm bốn khu vực:',
      bullets: [
        'Tất cả — Hearthie gợi ý món từ nguyên liệu trong kho.',
        'Đã lưu — công thức bạn bookmark.',
        'Khám phá — tìm từ TheMealDB, DummyJSON hoặc web.',
        'Của tôi — tạo công thức riêng, liên kết nguyên liệu kho và trừ kho khi nấu.',
      ],
    ),
    InfoSectionData(
      icon: Icons.calendar_month_outlined,
      title: 'Lịch thực đơn',
      body:
          'Lên kế hoạch bữa sáng/trưa/tối theo ngày. Thêm món từ công thức AI, đã lưu, khám phá hoặc công thức của bạn. '
          'Tạo danh sách mua nguyên liệu cho một ngày hoặc cả tuần, có tùy chọn trừ những gì đã có trong kho.',
    ),
    InfoSectionData(
      icon: Icons.shopping_cart_outlined,
      title: 'Danh sách mua sắm',
      body:
          'Sinh từ lịch thực đơn hoặc từ gợi ý Hearthie. Đánh dấu đã mua và thêm vào kho — '
          'Hearthie có thể gợi ý danh mục và vị trí bảo quản.',
    ),
    InfoSectionData(
      icon: Icons.auto_awesome_outlined,
      title: 'Hearthie (AI Chat)',
      body:
          'Trò chuyện với Hearthie để nhận gợi ý meal plan, xử lý đồ thừa, hoặc danh sách mua. '
          'Dùng quick prompts hoặc nhập câu hỏi tự do. Có thể đẩy gợi ý sang shopping planner.',
    ),
    InfoSectionData(
      icon: Icons.notifications_active_outlined,
      title: 'Thông báo nhắc hạn',
      body:
          'Bật/tắt trong Hồ sơ. App gửi tóm tắt buổi sáng và cảnh báo khẩn khi có món hết hạn. '
          'Xem lịch sử và quy tắc trong Trung tâm thông báo.',
    ),
    InfoSectionData(
      icon: Icons.help_outline_rounded,
      title: 'Câu hỏi thường gặp',
      body: '',
      bullets: [
        'Không thấy công thức custom trên lịch? Mở tab Công thức → Của tôi để tải lại.',
        'API lỗi khi lưu? Kiểm tra mạng và đảm bảo server backend đang chạy.',
        'Thông báo không hiện? Cấp quyền thông báo trong cài đặt hệ điều hành.',
        'Dữ liệu mất sau cài lại? Đăng nhập lại cùng tài khoản để khôi phục dữ liệu server.',
      ],
    ),
  ];

  static const _helpEng = [
    InfoSectionData(
      icon: Icons.rocket_launch_outlined,
      title: 'Getting started',
      body:
          'Sign in with email or Google, then add food to inventory (fridge, freezer, pantry). '
          'The dashboard shows an overview, weather, and shortcuts to main features.',
      bullets: [
        'Scan a barcode or enter items manually.',
        'Set expiry dates to receive timely reminders.',
        'Switch VIE/ENG and dark mode in Profile.',
      ],
    ),
    InfoSectionData(
      icon: Icons.kitchen_outlined,
      title: 'Inventory',
      body:
          'The Inventory tab lists items by storage location. Edit quantity, expiry, delete items, '
          'or configure default warning days per category in Settings.',
    ),
    InfoSectionData(
      icon: Icons.menu_book_outlined,
      title: 'Recipes',
      body: 'The Recipes tab has four areas:',
      bullets: [
        'All — Hearthie suggests dishes from ingredients in stock.',
        'Saved — bookmarked recipes.',
        'Explore — search TheMealDB, DummyJSON, or the web.',
        'My recipes — create custom recipes, link inventory, and deduct stock when cooking.',
      ],
    ),
    InfoSectionData(
      icon: Icons.calendar_month_outlined,
      title: 'Meal calendar',
      body:
          'Plan breakfast, lunch, and dinner by day. Add dishes from AI, saved, explore, or custom recipes. '
          'Generate shopping lists for one day or a full week, optionally deducting what you already have.',
    ),
    InfoSectionData(
      icon: Icons.shopping_cart_outlined,
      title: 'Shopping list',
      body:
          'Generated from the meal calendar or Hearthie suggestions. Mark items purchased and add to inventory — '
          'Hearthie can suggest category and storage location.',
    ),
    InfoSectionData(
      icon: Icons.auto_awesome_outlined,
      title: 'Hearthie (AI Chat)',
      body:
          'Chat with Hearthie for meal plans, leftover ideas, or shopping lists. '
          'Use quick prompts or free-form questions. Push suggestions to the shopping planner when available.',
    ),
    InfoSectionData(
      icon: Icons.notifications_active_outlined,
      title: 'Expiry notifications',
      body:
          'Toggle in Profile. The app sends a morning summary and urgent alerts when items expire. '
          'View history and rules in the Notifications center.',
    ),
    InfoSectionData(
      icon: Icons.help_outline_rounded,
      title: 'FAQ',
      body: '',
      bullets: [
        'Custom recipe missing on calendar? Open Recipes → My recipes to refresh.',
        'Save API error? Check network and ensure the backend server is running.',
        'No notifications? Grant notification permission in OS settings.',
        'Data lost after reinstall? Sign in with the same account to restore server data.',
      ],
    ),
  ];
}
