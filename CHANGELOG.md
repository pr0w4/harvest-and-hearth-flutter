# CHANGELOG

Tất cả thay đổi đáng chú ý của dự án **Harvest & Hearth Flutter** sẽ được ghi nhận tại đây.

Định dạng theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/).

---

## [b0.4.17] — 2026-06-22

### Custom Recipes (Công thức của tôi)

- Merge tính năng **công thức tự tạo** từ nhánh `recipe-hong`: tab **Của tôi** trong Công thức với CRUD đầy đủ.
- Liên kết nguyên liệu với **kho đồ** (autocomplete, kiểm tra đủ/thiếu, badge tồn kho trên danh sách).
- API backend **`/api/v1/custom-recipes`** (MongoDB collection `custom_recipes`) + client Flutter đồng bộ khi đăng nhập.
- **Nấu món**: trừ nguyên liệu đã liên kết khỏi kho (dialog xác nhận, rollback khi API lỗi).

### Meal Planner + Custom Recipes

- **Lịch thực đơn** hiển thị section **Công thức của tôi** khi thêm bữa ăn.
- Món custom trên lịch có nút **Nấu món** trừ kho trực tiếp.
- Nguyên liệu meal plan lấy từ `customIngredients` để shopping list chính xác hơn.

### Profile, Security & Help

- **About Hearthie**: cập nhật Creator thành `pr0w4 - pr0w4.dev`.
- **Security Info** và **Help Center** thay placeholder — nội dung đầy đủ theo app (Clerk, MongoDB, AI, thông báo, FAQ).
- Ghi nhận sản phẩm **đăng ký công nghệ và phát triển bởi Samsung Electronics Co., Ltd.**
- Footer cả hai màn: **Harvest & Hearth by Samsung Electronics Co. ltd**.

### Build

- Bump version Android: **`1.0.28+29`** (`versionName` **1.0.28**, `versionCode` **29**).
- APK release: `harvestnhearth-b0.4.17.apk`.

---

## [b0.4.16] — 2026-05-11

### Inventory Badges + Planner Traceability

- Thêm **2 lớp badge trong Inventory** cho nguyên liệu đến từ shopping plan:
  - badge nguồn: **Kế hoạch mua sắm**;
  - badge tên món: hiển thị các món liên quan để biết nguyên liệu dùng làm món nào.
- Hỗ trợ trường hợp **1 nguyên liệu dùng cho nhiều món** bằng nhiều badge món trên cùng item.
- Dữ liệu badge được lưu xuyên suốt từ planner -> add vào kho -> backend -> load lại inventory.

### Smart Classification + Vietnamese Support

- Khi thêm nguyên liệu đã mua vào kho, Hearthie hỗ trợ phân loại category/storage (fridge/freezer/pantry), có fallback rule-based an toàn.
- Cải thiện hiển thị tiếng Việt cho tên nguyên liệu: ưu tiên dữ liệu Việt, fallback dịch tự động khi cần cho user VIE.

### Build

- Bump version Android: **`1.0.26+27`** (`versionName` **1.0.26**, `versionCode` **27**).

---

## [b0.4.15] — 2026-05-11

### Planner Flow Fixes (Recipe Preview + Save CTA)

- Sửa luồng planner để người dùng **xem preview công thức đầy đủ** trước khi chọn bữa/ngày.
- Khi bấm món từ thanh search, app sẽ tải chi tiết công thức từ nguồn API phù hợp rồi mới hiển thị popup preview.
- Bổ sung **nút lưu kế hoạch cố định, nổi bật** ở cuối màn để người dùng dễ hoàn tất flow.
- Sau khi lưu, danh sách mua sắm được tạo theo kế hoạch đã chọn để tiếp tục luồng xác nhận đã mua.

### Build

- Bump version Android: **`1.0.25+26`** (`versionName` **1.0.25**, `versionCode` **26**).

---

## [b0.4.14] — 2026-05-11

### Planner Production-Ready Completion

- Hoàn thiện luồng **lưu kế hoạch** với nút lưu rõ ràng sau khi chọn món và slot bữa/ngày.
- Thêm danh sách **thực đơn kế hoạch đã lưu** theo period, có trạng thái theo dõi và thao tác tiếp theo.
- Bổ sung hành động **đã mua nguyên liệu** theo kế hoạch với flow thực tế:
  - cho phép sửa trực tiếp số lượng đã mua ngay trong list;
  - trước khi nhập kho sẽ hiện popup xác nhận lại toàn bộ danh sách + số lượng mới nhất;
  - xác nhận xong mới ghi vào Inventory để tránh lệch tồn kho.

### Planner Search + Recipe Preview UX

- Cập nhật thanh search ở planner để người dùng có thể **xem nhanh công thức** trước khi chọn vào kế hoạch.
- Tối ưu UI/UX tổng thể cho các bước: tìm món -> xem công thức -> chọn slot bữa -> lưu kế hoạch.

### Build

- Bump version Android: **`1.0.24+25`** (`versionName` **1.0.24**, `versionCode` **25**).

---

## [b0.4.13] — 2026-05-11

### Meal Planning Upgrade (Search + Slot Assignment + Draft Recovery)

- Nâng cấp màn **Kế hoạch** với thanh tìm món từ **2 nguồn API**:
  - `TheMealDB`
  - `DummyJSON`
- Khi chọn món từ kết quả tìm kiếm:
  - mở popup chọn **bữa trong ngày** (sáng / trưa / chiều / tối);
  - với chế độ **1 tuần**, chọn thêm **ngày trong tuần** (Thứ Hai → Chủ Nhật).
- Thêm vùng hiển thị **món đã chọn theo kế hoạch** theo period đang active (day/week), hỗ trợ xoá từng món và xoá toàn bộ lịch món của period.
- Bổ sung cơ chế **mid-save draft** cho kế hoạch:
  - tự động lưu từng thao tác thêm/xoá món kế hoạch;
  - khôi phục lại khi người dùng thoát giữa chừng hoặc app bị kill đa nhiệm.

### Recipes & Hearthie Planning UX

- Explore tab hỗ trợ kết quả tìm kiếm công thức từ cả `TheMealDB` và `DummyJSON` theo section riêng.
- Thêm filter nhanh cho ngữ cảnh gymer:
  - `High protein`
  - `Low fat`
- Thêm shortcut budget từ Explore vào Hearthie:
  - `Budget tiết kiệm`
  - `Budget tiêu chuẩn`
- Trong Hearthie Chat, thêm CTA **đẩy danh sách sang shopping planner** từ câu trả lời dạng meal plan / shopping list.

### Translation Fix

- Sửa lỗi dịch công thức chỉ dịch tiêu đề:
  - nay dịch đầy đủ **title + description + ingredients + steps** trong luồng detail công thức.

### Build

- Bump version Android: **`1.0.23+24`** (`versionName` **1.0.23**, `versionCode` **24**).

---

## [b0.4.12] — 2026-05-11

### Shopping Planner Flow (Day/Week)

- Thêm màn **Kế hoạch ngày/tuần**:
  - sinh danh sách mua sắm tự động từ tồn kho hiện tại cho chế độ **1 ngày** hoặc **1 tuần**;
  - hỗ trợ chỉnh trực tiếp số lượng mua ngay trên từng dòng trong danh sách;
  - đánh dấu món đã chọn mua theo từng item.
- Thêm luồng **Thêm nhanh vào kho**:
  - khi bấm nút thêm nhanh, app mở popup xác nhận toàn bộ danh sách đã chọn kèm số lượng mới nhất;
  - xác nhận xong mới thêm vào Inventory.

### Dashboard Quick Actions

- Thay shortcut **Notifications Center** bằng shortcut **Kế hoạch mua sắm** trong Quick Actions.
- Không thêm nút mới ở navbar, giữ điều hướng theo yêu cầu UX.

### Navigation CTA Polish

- Nút `+` (Add Food) hiển thị global ở mọi screen, đặt giữa thanh dưới và nổi bật hơn.
- Áp dụng `BottomAppBar` có notch giữa để tách biệt CTA và tăng nhận diện thao tác chính.

### UX/UI Polish (Shopping Planner)

- Nâng cấp giao diện planner với thẻ header nổi bật, progress bar trực quan và card item rõ trạng thái.
- Tinh chỉnh layout controls tăng/giảm số lượng để thao tác nhanh hơn trên mobile.

### Build

- Bump version Android: **`1.0.22+23`** (`versionName` **1.0.22**, `versionCode` **23**).

---

---

## [b0.4.11] — 2026-05-03

### Hearthie Branding Upgrade

- Chuẩn hoá branding Hearthie theo 3 hướng:
  - **Brand color system**: thêm token màu `Hearthie Gold / Hearthie Sky / Hearthie Night`.
  - **Microcopy consistency**: đồng bộ cách gọi `Harvest & Hearth` (app) và `Hearthie` (AI) trên Dashboard/Chat/Recipes.
  - **Persona card**: thêm thẻ **About Hearthie** trong Profile (mission, capabilities, limits, AI infra, creator).
- Bổ sung chữ ký thương hiệu ở AI Chat và Dashboard preview:
  - `by Mật vụ P (Pr0why) · Cafetoolbox Developer`.
- Cập nhật quick prompts của Hearthie:
  - Meal plan 7 ngày theo ngân sách
  - Gợi ý món từ leftovers
  - Tạo shopping list từ nguyên liệu còn thiếu.

### Creator & Origin Rules

- Khi hỏi ai tạo app/Hearthie, Hearthie trả lời nhất quán:
  - `Mật vụ P (Pr0why) · Cafetoolbox Developer`.
- Khi hỏi Hearthie được tạo ra như thế nào:
  - phản hồi theo hướng “bí mật”
  - bật mí được hỗ trợ kỹ thuật/phần cứng bởi **Groq Cloud**
  - giới thiệu ngắn về ưu điểm low-latency inference của Groq cho realtime chat.

### Notification Stability

- Tăng độ ổn định gửi **test notification**:
  - nếu lần gửi đầu lỗi hệ thống trên Android, tự fallback gửi lại bằng cấu hình tối giản.
  - giảm false-fail “lỗi hệ thống” trên một số launcher/OEM.

### Banner Weather UX Polish

- Tối ưu cụm thời tiết trên Welcome Banner:
  - bỏ mây bay gây rối
  - cố định icon thời tiết trong cụm nhiệt độ
  - dời nhiệt độ sang trái phía trên tên thành phố
  - chuẩn hoá icon theo sáng/trưa/chiều/tối/mưa.

### Build

- Bump version Android: **`1.0.21+22`** (`versionName` **1.0.21**, `versionCode` **22**).

---

## [b0.4.10] — 2026-05-03

### Inventory Update (Merge beforemerge, giữ UI hiện tại)

- Kế thừa đầy đủ chức năng khu `Đồ khô / Pantry` trong Inventory (3 khu: Tủ lạnh / Ngăn đông / Đồ khô).
- Bổ sung `pantry` trong `StorageType`, `pantryItems` trong `AppProvider`, và lựa chọn pantry trong `AddFoodModal`.
- Thêm cấu hình **hạn dùng mặc định theo loại nguyên liệu** (lưu `SharedPreferences`) và màn chỉnh trong Profile.
- Thêm **category 2 tầng** trong Add Food (nhóm cấp 1 + danh mục chi tiết cấp 2).
- Thêm **nhập nhiều nguyên liệu** (bulk input) và **gợi ý nguyên liệu thường mua**.
- Đồng bộ key dịch VIE/ENG cho các phần inventory mới.

### Dashboard Enhancement (Weather + Location)

- Thêm card **thời tiết theo khu vực người dùng** ngay trên Dashboard.
- Định vị theo **GPS** (có xin quyền), nếu không khả dụng sẽ fallback sang **IP location**.
- Tích hợp API **Open-Meteo** để lấy nhiệt độ hiện tại + trạng thái thời tiết theo thành phố.
- Thêm trạng thái nguồn định vị (GPS/IP), nút refresh thủ công và thông báo lỗi retry nhanh.
- Bổ sung permission location cho Android/iOS và key dịch VIE/ENG cho phần weather.
- Nâng cấp khối **Welcome Banner**: đưa thời tiết vào bên phải lời chào (nhiệt độ + thành phố), bỏ card thời tiết rời để UI gọn hơn.
- Thêm animation nền theo ngữ cảnh thời tiết và thời gian trong ngày:
  - Sáng nắng: tông trời xanh + mây
  - Mưa: mây đen + hiệu ứng mưa
  - Buổi trưa: chuyển tông sáng phù hợp
  - Buổi tối: xanh đậm/đen + trăng sao
- Chỉnh lại vị trí icon trời/mây để không che text nhiệt độ và tên thành phố trong banner.
- Khôi phục ô **Notification Center** trong Quick Actions cho mọi mode demo/non-demo.
- Notification Center tự refresh khi mở màn, ưu tiên đọc log mới từ backend.
- Nâng cấp log notification lên MongoDB theo `userId` với dữ liệu phong phú hơn:
  - Hỗ trợ truy vấn `limit/skip` (tối đa 1000 bản ghi/lần)
  - Log cảnh báo có kèm tên món hết hạn/sắp hết hạn
  - Tách loại log rõ hơn (`expiry_summary`, `expiry_urgent`, `expiry_test`)
- Tích hợp logo mới của **Hearthie** từ `public/hearthie` vào các điểm nhận diện AI chính:
  - Header AI Chat
  - Avatar bot trong hội thoại + typing indicator
  - Card preview AI trên Dashboard
  - Nút mở Hearthie trong gợi ý công thức
- Áp dụng `ColorFiltered` (tint theo theme sáng/tối) để logo hiển thị đồng bộ màu giao diện.
- Tinh chỉnh lại **Welcome Banner Weather UX**:
  - Bỏ hiệu ứng mây trôi để tránh rối bố cục và che text.
  - Cố định icon thời tiết trong cụm nhiệt độ, dời nhiệt độ sang trái phía trên tên thành phố.
  - Chuẩn hóa bộ icon theo ngữ cảnh: sáng / trưa / chiều / tối / mưa.

### Xác nhận kỹ thuật

- `flutter analyze` (các file inventory liên quan): **PASS**.
- `flutter build apk --release`: **PASS**.

---

## [b0.4.9] — 2026-05-03

### Demo mode + AI Chat polish (Hearthie)

- Đổi brand AI đồng bộ sang `Hearthie`.
- Tách model theo mục đích qua env:
  - `GROQ_CHAT_MODEL` mặc định `openai/gpt-oss-120b`
  - `GROQ_RECIPE_MODEL` mặc định `meta-llama/llama-4-scout-17b-16e-instruct`
- Thêm `DEMO_MODE=true` để làm gọn Dashboard, tập trung luồng AI khi demo.
- Tài khoản thử chuyển sang đăng nhập 1 chạm (password strategy) với fallback khi cần xác thực bổ sung.
- AI Chat nâng cấp UX: badge `Preview`, cache prompt gần giống, loading mượt hơn, nút `Regenerate`.

---

## [b0.4.8] — 2026-05-02

### Sửa lỗi notification + widget + UX chi tiết

- Chuẩn hoá kết quả gửi test notification (`sent` / `permissionDenied` / `failed`) để tránh false-negative quyền Android.
- Nâng cấp Notifications Center với rule gửi, case hiển thị và xử lý lỗi hệ thống/quyền.
- Sửa widget Android lỗi “Can’t load widget” theo hướng fallback an toàn.
- Dashboard Quick Actions thay mục trùng bằng shortcut Notifications Center.
- Tăng chất lượng AI Chat prompt theo ngữ cảnh kho và quy tắc an toàn thực phẩm.

---

## [b0.4.7] — 2026-05-02

### Cải tiến UX/UI (toàn app)

- Thiết kế lại giao diện đồng bộ sáng/tối.
- Chuẩn hoá theme system (`app_theme.dart`) và token dùng chung.
- Refactor UI trên Dashboard, Inventory, Recipes, AI Chat, Profile, Auth, Scanner, AddFoodModal.
- Bổ sung Notifications Center và hoàn thiện route flow.

---

## [b0.4.6] — 2026-04-20

### Sửa lỗi

- Sửa backend nhầm database `test` → dùng DB chỉ định.
- Sửa lỗi mất inventory sau khi thoát/mở lại app khi một số API phụ lỗi.
- Sửa widget Android fail-safe để tránh host crash.

---

## [b0.4.5] — 2026-04-20

### Thêm mới

- **Nhật ký thông báo theo user (MongoDB):** thêm API backend `notifications` với các route đọc danh sách, tạo log, đánh dấu đã đọc; lưu theo `userId`, `title`, `message`, `type`, `isRead`, `createdAt`.
- **Thông báo trong app nâng cấp:** tách rõ 3 loại thông báo (daily summary, urgent expiry, test immediate), thêm payload khi bấm thông báo, thêm icon status bar Android (`ic_stat_harvest`).
- **Home widget Android nâng cấp lớn:**
  - thêm trạng thái tổng quát (safe / warning / danger), thời điểm cập nhật, tap widget mở app;
  - thêm chế độ compact / ultra-compact cho launcher grid nhỏ;
  - thêm nền widget đổi theo mức cảnh báo.
- **Dashboard bổ sung luồng quét barcode từ màn chính:** nút quét trên Home mở scanner trực tiếp và tự điền kết quả vào modal thêm thực phẩm.
- **Dashboard mới phần gợi ý công thức thời gian thực:** sinh gợi ý theo thời điểm trong ngày + trạng thái nguyên liệu, chạm vào từng gợi ý để mở AI Chef với prompt soạn sẵn.
- **Khám phá công thức mở rộng nguồn dữ liệu món Việt:** kết hợp TheMealDB + DummyJSON, gộp và loại trùng danh sách.

### Cải tiến

- **Dịch công thức EN → VI mạnh hơn:**
  - tự dịch tên/mô tả món trong Explore khi app ở tiếng Việt;
  - trong màn chi tiết công thức dịch đầy đủ cả nguyên liệu và các bước nấu;
  - giữ khả năng chuyển qua lại bản gốc / bản dịch.
- **Thẻ công thức hiển thị nguồn dữ liệu:** thêm nhãn nguồn (`TheMealDB`, `DummyJSON`, `AI Chef`) để minh bạch dữ liệu khi demo.
- **Màu cảnh báo trên Home được làm dịu:** giảm độ chói các badge/thanh cảnh báo hết hạn-sắp hết hạn theo feedback.

### Sửa lỗi

- **Nút quét barcode ở Dashboard:** sửa lỗi điều hướng route chưa khai báo, chuyển sang mở scanner trực tiếp bằng `BarcodeScannerScreen`.
- **Ghi log thông báo tránh trùng lặp:** thêm cơ chế dedupe theo ngày cho một số loại thông báo tóm tắt / khẩn.

### Build

- **`1.0.17+18`** (`versionName` **1.0.17**, `versionCode` **18**); APK `harvestnhearth-b0.4.5.apk`.

---

## Sắp ra mắt (Backlog)

- [x] Quét mã vạch và mã QR thực sự bằng camera.
- [x] Thông báo nhắc nhở khi thực phẩm sắp hết hạn.
- [ ] Danh sách mua sắm tự động từ kho thiếu.
- [x] Đồng bộ dữ liệu qua backend (trước đây Supabase; nay MongoDB + API). ✓
- [ ] Ảnh thực phẩm tùy chỉnh từ camera.
- [x] Widget màn hình chính (Android home screen widget) hiển thị cảnh báo.
- [ ] **Clerk — Account locked:** bật trên Dashboard + áp dụng [account-locked.html](clerk/email-templates/account-locked.html).
- [ ] **Clerk — Password changed:** bật thông báo đổi mật khẩu + [password-changed.html](clerk/email-templates/password-changed.html).
- [ ] **Clerk — Primary email address changed:** [primary-email-changed.html](clerk/email-templates/primary-email-changed.html) (bổ sung biến email nếu Clerk cung cấp).
- [ ] **Clerk — Reset password code:** luồng quên mật khẩu bằng mã + [reset-password-code.html](clerk/email-templates/reset-password-code.html).
- [ ] **Clerk — Sign in from new device:** cảnh báo thiết bị lạ + [sign-in-from-new-device.html](clerk/email-templates/sign-in-from-new-device.html) (chi tiết thiết bị/IP qua biến Dashboard).

---

## [b0.4.4] — 2026-04-13

### Thêm mới

- **Trang chủ (Dashboard) thiết kế mới**: Lời chào cá nhân theo thời gian trong ngày (sáng/chiều/tối). Ba thẻ thống kê màu sắc (Tốt / Cần chú ý / Hết hạn). Lưới 4 nút hành động nhanh đến các tính năng chính. Xem trước AI Chat ngay từ trang chủ.
- **AI Chat công thức**: Trò chuyện nhiều lượt với AI Chef. AI hiểu nguyên liệu đang có trong tủ, ưu tiên món sắp hết hạn. Gợi ý nhanh bằng các prompt sẵn. Giao diện đầy đủ: bong bóng chat, trạng thái đang gõ, cuộn tự động, xoá toàn bộ hội thoại.
- **Kho thực phẩm phiên bản mới**: Giao diện viết lại hoàn toàn — tab Tủ lạnh / Ngăn đông, thanh tìm kiếm, sắp xếp theo tên / hạn / ngày thêm, danh sách tối ưu rebuild.

### Sửa lỗi

- **Widget Android không tải được:** Lỗi do hai file `build.gradle` và `build.gradle.kts` có `applicationId` khác nhau (`com.harvestandhearth.app` vs `com.harvestandhearth.harvest_and_hearth`) khiến hệ thống không tìm thấy class widget provider. Đồng bộ `build.gradle.kts` và dùng tên lớp đầy đủ trong Manifest.

### Build

- **`1.0.16+17`** (`versionName` **1.0.16**, `versionCode` **17**); APK `harvestnhearth-b0.4.4.apk`.

---

---

## [b0.4.3] — 2026-04-06

### Cải tiến

- **Widget Android:** giao diện thẻ bo góc, icon app, phụ đề, hai ô thống kê (sắp hết / hết hạn) có màu tách biệt; dữ liệu đa ngôn ngữ qua `HomeWidgetService`.
- **Thông báo thử (console thời gian):** xin quyền **POST_NOTIFICATIONS** (Android 13+) / iOS trước khi gửi; kênh **`harvest_expiry_immediate`** mức ưu tiên cao; SnackBar khi người dùng từ chối quyền.

### Build

- **`1.0.15+16`** (`versionName` **1.0.15**, `versionCode` **16**); APK `harvestnhearth-b0.4.3.apk`.

---

---

## [b0.4.2] — 2026-04-06

### Hotfix

- **Email Clerk:** toàn bộ `clerk/email-templates/` chuyển sang định dạng **Revolvapp** (`<re-html>` / `<re-*>`), đồng bộ với editor Dashboard.
- **Nút mô phỏng thời gian:** trên bản **release** mặc định **hiện** FAB (trừ khi `.env` có `ENABLE_TIME_SIMULATOR=false` / `0` / `no`); debug luôn bật.
- **Widget Android:** `receiver` có `label` + `icon` để dễ tìm trong danh sách widget; gợi ý thêm widget trong **Hồ sơ** và **README**.

### Build

- **`1.0.14+15`** (`versionName` **1.0.14**, `versionCode` **15**); APK `harvestnhearth-b0.4.2.apk`.

---

---

## [b0.4.1] — 2026-04-05

### QA / kiểm thử thông báo hạn

- **Đồng hồ mô phỏng (`SimulatedClock`):** “Hôm nay” dùng cho tính hết hạn / sắp hết có thể lệch so với đồng hồ thật — **không sửa ngày đã lưu** trong kho.
- **Console thời gian (FAB góc trái):** preset **+1 / +3 / +7 ngày** (cộng dồn), **Về giờ thực**, **Gửi thông báo thử ngay** (cùng nội dung với bản tóm tắt hằng ngày).
- **Hiển thị:** mặc định trong **debug**; bản release có thể bật bằng `ENABLE_TIME_SIMULATOR=true` trong `.env` (xem `.env.example`).

### Build

- **`1.0.13+14`** (`versionName` **1.0.13**, `versionCode` **14**); APK `harvestnhearth-b0.4.1.apk`.

---

---

## [b0.4.0] — 2026-04-05

### Thông báo & widget (Android)

- **Nhắc hạn:** `ExpiryReminderService` — thông báo tóm tắt mỗi ngày **9:00** (giờ địa phương) khi có mặt hàng **sắp hết hạn** hoặc **đã hết hạn** (theo `FoodItem.isExpiringSoon` / `isExpired`). Kênh Android `harvest_expiry`; bật/tắt trong **Hồ sơ**; xin quyền `POST_NOTIFICATIONS` (Android 13+).
- **Widget màn hình chính:** `home_widget` + `HarvestWidgetProvider` — hai dòng: số lượng sắp hết / hết hạn + tên mặt hàng (rút gọn). Thêm widget từ launcher → widget Harvest & Hearth.
- **Gradle:** `coreLibraryDesugaring` (yêu cầu của `flutter_local_notifications`).

### Build

- **`1.0.12+13`** (`versionName` **1.0.12**, `versionCode` **13**); APK `harvestnhearth-b0.4.0.apk`.

---

---

## [b0.3.3] — 2026-04-05

### Clerk & tài liệu

- **Email (Revolvapp):** [invitation.html](clerk/email-templates/invitation.html), [verification-code.html](clerk/email-templates/verification-code.html) — thẻ `<re-*>`; [README](clerk/email-templates/README.md) (`{{> app_logo}}`, `inviter_name`).
- **Đăng nhập thử:** nút *Dùng tài khoản thử* khi có `TEST_ACCOUNT_EMAIL` + `TEST_ACCOUNT_PASSWORD` trong `.env`; mật khẩu test đề xuất `!testPassword123!` (đủ điều kiện Clerk).
- **README:** checklist vận hành; bảng phiên bản cập nhật build này.

### Build

- **`1.0.10+11`** (`versionName` **1.0.10**, `versionCode` **11**); APK đặt tên `harvestnhearth-b0.3.3.apk`.

---

---

## [b0.3.2] — 2026-04-05

### Clerk — email templates

- Thư mục **`clerk/email-templates/`**: HTML Handlebars (branding Harvest & Hearth) để dán vào Clerk Dashboard → Emails.
- **Dùng ngay:** [invitation.html](clerk/email-templates/invitation.html), [verification-code.html](clerk/email-templates/verification-code.html) (`{{otp_code}}`). Hướng dẫn: [clerk/email-templates/README.md](clerk/email-templates/README.md).
- **`AuthScreen`:** ghi chú trong dartdoc — bật *Email verification code* trên Clerk để luồng đăng nhập/đăng ký gửi mã; không đổi widget nếu chiến lược đã bật.
- **Chuẩn bị / backlog (template HTML có sẵn, chờ bật tính năng Clerk + phiên bản sau):** Account locked, Password changed, Primary email changed, Reset password code, Sign in from new device — xem mục Backlog trong [CHANGELOG.md](CHANGELOG.md) và [README.md](README.md).

---

---

## [b0.3.1] — 2026-04-05

### Hiệu năng

- **`BackendApiService`**: Dùng một `http.Client` tái sử dụng cho mọi request (connection reuse); đóng client khi `detach` sau đăng xuất.
- **`_ClerkBootstrap`**: `Selector` chỉ theo `isLoadingUser` và `user` — tránh rebuild splash/main khi kho hoặc công thức thay đổi trong lúc đang ở luồng bootstrap.

### Tài liệu & build

- **README** / **GITHUB_RELEASE**: Khớp semver `1.0.9+10` và nhãn **b0.3.1**; APK release đặt tên `harvestnhearth-b0.3.1.apk`.
- **`android/app/build.gradle`**: `versionCode` / `versionName` lấy từ Flutter (`pubspec.yaml`) để khớp bản build.

---

---

## [b0.3.0] — 2026-04-05

### Tổng quan (big update)

- **Phiên bản ứng dụng:** `1.0.8+9` (Android `versionName` `1.0.8`, `versionCode` `9`).
- **API Node (`server/`):** nén phản hồi gzip (`compression`), tắt header `X-Powered-By`, `trust proxy` phù hợp reverse proxy (Render); giữ CORS + JSON body.
- **Flutter `BackendApiService`:** timeout HTTP **45s** (phù hợp cold start Render free + Atlas); gom decode JSON list; giữ nguyên hợp đồng REST.
- **Deploy Render:** `render.yaml` (Blueprint) ở root repo — Docker context `server/`, health check `/health`, secrets `MONGODB_URI` / `CLERK_SECRET_KEY`; `server/README.md` hướng dẫn Web Service thủ công + Blueprint.
- **Tài liệu:** `README.md` bảng phiên bản; `GITHUB_RELEASE.md` khớp b0.3.0; `.env.example` nhất quán.

---

---

## [b0.2.0] — 2026-04-05

### Breaking / Kiến trúc

- **Thay Supabase bằng MongoDB + API riêng + Clerk**: Ứng dụng không kết nối trực tiếp MongoDB; dùng REST API trong thư mục `server/` (Node.js, driver MongoDB, xác thực JWT Clerk).
- **Đăng nhập**: [Clerk](https://clerk.com) với SDK `clerk_flutter` — màn hình đăng nhập/đăng ký do Clerk cung cấp (`ClerkAuthentication`).
- **Biến môi trường app**: `CLERK_PUBLISHABLE_KEY`, `API_BASE_URL` (thay `SUPABASE_*`).
- **Schema SQL cũ** (`supabase/supabase.sql`) đánh dấu deprecated; giữ để tham chiếu hoặc migrate thủ công.

---

---

## [b0.1.10] — 2026-04-05

- **Bản build đồ án / GitHub Release**: APK release (`app-release.apk` và `harvestnhearth-b0.1.10.apk`) dùng để nộp báo cáo và đính kèm release; không phát hành lên store.

---

---

## [b0.1.9] — 2026-04-05

- **Icon ứng dụng**: Logo nguồn tại `code/app_icon.png`; tạo icon Android (adaptive) và iOS bằng `flutter_launcher_icons`. Thay file PNG trong `code/` rồi chạy `dart run flutter_launcher_icons` để cập nhật.
- **Tên file APK release**: Sau `flutter build apk --release`, thêm bản sao `harvestnhearth-<nhãn_CHANGELOG>.apk` trong cùng thư mục với `app-release.apk` (nhãn = mục `## [b0.x.x]` **cuối cùng** trong `CHANGELOG.md`).

---

---

## [b0.1.8] — 2026-04-05

### Hiệu năng

- **MaterialApp & theme**: Chỉ rebuild khi đổi theme / splash / auth / shell (không rebuild khi chỉ cập nhật kho hoặc công thức). Theme sáng/tối dùng instance tĩnh, tránh tạo lại `ThemeData` không cần thiết.
- **Thanh điều hướng**: `MainShell` chỉ rebuild nhãn tab khi đổi ngôn ngữ, không khi dữ liệu kho hay cache công thức thay đổi.
- **Ảnh công thức (TheMealDB)**: `Image.network` dùng `cacheWidth` / `cacheHeight` để giảm bộ nhớ decode khi cuộn danh sách và xem chi tiết.

### Tài liệu

- **README**: Bố cục lại cho dễ đọc (badge, mục lục, bảng phiên bản, hướng dẫn build release).
- **GitHub Release**: Thêm file `GITHUB_RELEASE.md` — nội dung gợi ý để dán khi tạo release.

### Build (Android)

- **`android/gradle.properties`**: `kotlin.incremental=false` để tránh lỗi biên dịch Kotlin khi thư mục project và pub-cache nằm khác ổ đĩa (Windows).

---

---

## [b0.1.7] — 2026-04-05

- **Quét mã vạch & QR bằng camera**: Khi thêm thực phẩm, mở màn hình quét thật (hỗ trợ nhiều định dạng mã vạch và QR). Giá trị quét được điền vào ô tên; có nút đèn flash và hướng dẫn trên màn hình. Thay thế hoàn toàn chế độ giả lập trước đây.

---

---

## [b0.1.6] — 2026-04-05

- **Độ khó công thức theo ngôn ngữ**: Nhãn Dễ / Trung bình / Khó (hoặc Easy / Medium / Hard) trên chip độ khó và đơn vị năng lượng hiển thị đúng bản dịch đang chọn.
- **Kiểm thử & phân tích**: Bộ test mặc định kiểm tra bản dịch thay cho màn hình counter mẫu; `flutter analyze` sạch lỗi/cảnh báo liên quan các thay đổi này.
- **Tài liệu quy ước**: Cập nhật `RULES.md` cho khớp thực tế codebase (đã hoàn thành trước bản này).

---

---

## [b0.1.5] — 2026-04-05

- **Chi tiết và chỉnh sửa thực phẩm**: Nhấn vào bất kỳ mặt hàng nào trong kho để xem đầy đủ thông tin (danh mục, số lượng, ngày hết hạn) và chỉnh sửa trực tiếp. Không cần xoá rồi thêm lại.
- **Card thực phẩm cải tiến**: Mỗi card nay hiển thị nhãn danh mục màu sắc, ngày hết hạn cụ thể (dd/mm/yyyy) kèm nhãn tương đối ("5 ngày còn lại"), và nút chỉnh sửa riêng.
- **Xoá ngày hết hạn**: Khi chỉnh sửa, có thể xoá ngày hết hạn nếu không cần theo dõi.
- **Tối ưu hiệu năng**: Màn hình Khám phá không tải lại danh sách món Việt Nam mỗi lần chuyển tab. Kho thực phẩm chỉ rebuild khi dữ liệu kho thay đổi, không bị ảnh hưởng bởi cập nhật công thức.

---

---

## [b0.1.4] — 2026-04-05

- **Màn hình đăng nhập hiện nhanh hơn**: Splash screen không còn đứng yên chờ tải dữ liệu. Nếu chưa đăng nhập, app vào màn hình đăng nhập ngay lập tức. Nếu đã đăng nhập, splash giữ trong lúc tải dữ liệu ngầm rồi vào thẳng app — không còn màn hình trắng hay loading lâu.

---

---

## [b0.1.3] — 2026-04-05

- **Link xác nhận email mở đúng app**: Trước đây nhấn link trong email xác nhận tài khoản sẽ trỏ về localhost. Nay link tự động mở thẳng vào ứng dụng.
- **Đăng nhập Google tải nhanh hơn**: Sau khi xác thực Google, app không còn loading lâu. Dữ liệu người dùng được tải song song thay vì tuần tự.
- **Hồ sơ Google được lưu đúng cách**: Người dùng đăng nhập lần đầu bằng Google nay có hồ sơ được tạo tự động trên hệ thống.
- **Email xác nhận tài khoản**: Giao diện email đẹp với logo và màu sắc của app, gửi khi đăng ký bằng email/mật khẩu.
- **Email xác thực lại (OTP)**: Giao diện email hiển thị mã OTP nổi bật, kèm hướng dẫn bảo mật.

---

---

## [b0.1.2] — 2026-04-05

- **Đăng nhập bằng Google**: Nút "Đăng nhập với Google" trên màn hình xác thực. Ứng dụng mở trình duyệt, người dùng chọn tài khoản Google, rồi tự động quay lại app — không cần nhớ mật khẩu.
- **Lưu trữ đám mây (Supabase)**: Dữ liệu thực phẩm và công thức đã lưu nay được lưu trên cloud thay vì chỉ trong bộ nhớ thiết bị. Đăng nhập trên thiết bị khác vẫn thấy đầy đủ dữ liệu.
- **Tab "Khám phá" trong màn hình Công thức**:
  - Mặc định hiển thị danh sách **món ăn Việt Nam** từ TheMealDB (có ảnh, nhấn để xem chi tiết nguyên liệu và các bước nấu).
  - Thanh tìm kiếm để tra cứu bất kỳ tên món nào — kết quả đến từ TheMealDB và DuckDuckGo cùng lúc.
  - Có thể lưu công thức tìm được vào danh sách yêu thích giống công thức AI.
- **Dịch thuật tức thì**: Mỗi công thức tìm được từ API hoặc DuckDuckGo đều có nút "Dịch" — ứng dụng tự động dịch tên và mô tả sang ngôn ngữ đang dùng (Việt hoặc Anh). Nhấn lại để xem bản gốc.
- **Mở trang web nguồn**: Kết quả tìm từ DuckDuckGo hoặc TheMealDB đều có nút "Mở trang web" để xem bài viết gốc đầy đủ trong trình duyệt.

---

---

## [b0.1.1] — 2026-04-05

### Sửa lỗi

- **Ứng dụng không khởi động được trên Android**: Lỗi build Gradle ngăn ứng dụng cài lên thiết bị. Đã được vá hoàn toàn, ứng dụng cài và chạy bình thường.

### Cải tiến

- **AI thông minh hơn với hệ thống dự phòng**: Tích hợp thêm Groq AI (Llama 3.3) làm nguồn chính để tạo công thức nhanh hơn. Nếu Groq không phản hồi, ứng dụng tự động chuyển sang Gemini mà người dùng không cần làm gì.
- **Hỗ trợ Android mới nhất (SDK 36)**: Đảm bảo tương thích với các thiết bị Android mới nhất.

---

---

## [b0.1.0] — 2026-04-05

### Thêm mới
- **Xác thực người dùng**: Màn hình đăng nhập / đăng ký với validation. Hỗ trợ tài khoản thử cho phép bỏ qua form để kiểm tra nhanh.
- **Trang chủ (Dashboard)**: Hiển thị lời chào cá nhân hoá, thống kê số lượng thực phẩm, cảnh báo các mặt hàng hết hạn hoặc sắp hết hạn, danh sách 3 mặt hàng vừa thêm gần nhất, và mẹo hàng ngày.
- **Kho thực phẩm (Inventory)**: Quản lý thực phẩm theo hai ngăn — Tủ lạnh và Ngăn đông. Hỗ trợ tìm kiếm theo tên và sắp xếp theo tên / ngày hết hạn / ngày thêm. Xoá mặt hàng với hộp thoại xác nhận.
- **Thêm thực phẩm**: Form nhập liệu đầy đủ gồm tên, danh mục (8 loại), vị trí lưu trữ, số lượng, đơn vị, ngày hết hạn, và số ngày cảnh báo trước. Có nút quét mã vạch giả lập.
- **Công thức nấu ăn (Recipes)**:
  - AI Chef tự động gợi ý 3 công thức dựa trên nguyên liệu hiện có trong tủ, ưu tiên nguyên liệu sắp hết hạn.
  - Xem chi tiết công thức: thành phần, các bước nấu, thời gian, calo, khẩu phần, độ khó.
  - Lưu và bỏ lưu công thức yêu thích.
- **Hồ sơ (Profile)**: Chuyển đổi ngôn ngữ Việt – Anh. Bật/tắt chế độ tối. Xem thống kê cá nhân (số mặt hàng, công thức đã lưu, số hàng hết hạn). Đăng xuất.
- **Hỗ trợ đa ngôn ngữ**: Toàn bộ giao diện hỗ trợ tiếng Việt và tiếng Anh, chuyển đổi tức thời không cần khởi động lại.
- **Chế độ tối**: Chủ đề sáng/tối theo Material 3, lưu lại lựa chọn sau khi tắt app.
- **Lưu trữ cục bộ**: Toàn bộ dữ liệu (thực phẩm, công thức đã lưu, cài đặt) được lưu trên thiết bị qua SharedPreferences và không cần kết nối mạng (trừ tính năng AI).

---
