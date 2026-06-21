# Báo cáo Thiết kế Hệ thống - Harvest & Hearth

> **Báo cáo đồ án đầy đủ (DOCX):** xem thư mục [`docs/bao-cao-dong-an/`](docs/bao-cao-dong-an/) — file `Harvest-Hearth-Bao-Cao-Dong-An.docx` (12 chương, 15 diagram, khối *Giải thích* in nhỏ). Tái tạo: `powershell -File docs/bao-cao-dong-an/build-report.ps1`.

Tài liệu này chứa các sơ đồ thiết kế chi tiết dưới dạng mã **Mermaid.js**. Bạn có thể xem trực tiếp các sơ đồ được render trên hệ thống hỗ trợ Markdown hoặc sao chép mã Mermaid để sử dụng trong các công cụ vẽ sơ đồ trực tuyến như [Mermaid Live Editor (mermaid.live)](https://mermaid.live).

---

## 1. Sơ đồ Use Case (UML Use Case Diagram)
Mô tả các Actor (Người dùng, Hệ thống xác thực Clerk, AI Engine, Weather API) và các chức năng cốt lõi của ứng dụng **Harvest & Hearth**.

```mermaid
flowchart LR
    %% Actors
    User([Người dùng / User])
    ClerkAuth[Clerk Auth Provider]
    AIEngine[AI Engine - Groq/Gemini]
    WeatherApi[Open-Meteo API]

    subgraph AppSystem ["Hệ thống Harvest & Hearth"]
        direction TB
        UC1(Đăng nhập / Đăng xuất)
        UC2(Quản lý kho thực phẩm)
        UC3(Quét mã vạch/QR nhập kho)
        UC4(Xem cảnh báo hạn sử dụng)
        UC5(Lên lịch thực đơn - Meal Calendar)
        UC6(Tạo list nguyên liệu tự động)
        UC7(Trừ nguyên liệu đã có sẵn)
        UC8(Trò chuyện với Hearthie AI)
        UC9(Xem thời tiết - Weather Banner)
    end

    %% Interactions
    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    User --> UC5
    User --> UC6
    User --> UC8
    User --> UC9

    UC1 <--> ClerkAuth
    UC6 -.-> |include| UC7
    UC8 <--> AIEngine
    UC9 <--> WeatherApi
```

### Mô tả chức năng:
*   **Quản lý kho thực phẩm**: Theo dõi các mặt hàng thực phẩm được phân chia theo khu vực (Ngăn đông, Ngăn mát, Tủ khô).
*   **Lên lịch thực đơn**: Lên kế hoạch ăn uống theo các bữa (Sáng, Trưa, Tối) trên giao diện lịch tháng.
*   **Tạo danh sách mua sắm tự động (Trừ nguyên liệu sẵn có)**: Hệ thống tự động thu thập nguyên liệu từ thực đơn Ngày hoặc Tuần lịch biểu (Thứ Hai đến Chủ Nhật), đối chiếu với lượng thực phẩm đang có trong tủ lạnh (bao gồm quy đổi đơn vị đo lường tương thích) và chỉ đề xuất mua những phần còn thiếu.
*   **Trò chuyện với Hearthie AI**: Trợ lý AI hỗ trợ gợi ý công thức dựa trên thực phẩm sắp hết hạn trong tủ, đưa ra mẹo bảo quản và trả lời các câu hỏi về bếp núc.

---

## 2. Sơ đồ Kiến trúc Hệ thống (System Architecture)
Mô tả kiến trúc phân tầng của ứng dụng từ tầng Giao diện di động, tầng Dịch vụ xử lý logic đến tầng Máy chủ và các dịch vụ bên thứ ba.

```mermaid
graph TD
    %% Layers
    subgraph ClientLayer [Tầng Giao Diện - Frontend]
        UI[Flutter Mobile App - Material 3]
        Provider[AppProvider - State Management]
        LocalDB[(SharedPreferences - Local Cache)]
    end

    subgraph ServiceLayer [Tầng Dịch Vụ - Integrations]
        API_Service[BackendApiService]
        AI_Service[GroqChatService / GeminiService]
        Weather_Service[WeatherService]
        Notif_Service[ExpiryReminderService]
    end

    subgraph CloudLayer [Tầng Máy Chủ & Đám Mây - Cloud Backend]
        Server[Express JS Server - Render/Pterodactyl]
        MongoDB[(MongoDB Atlas Database)]
        Clerk[Clerk Auth JWT Service]
        Groq[Groq API - LLM Llama/GPT]
        Gemini[Gemini API - LLM Flash]
        Meteo[Open-Meteo API]
    end

    %% Relationships
    UI <--> Provider
    Provider <--> LocalDB
    Provider --> API_Service
    Provider --> AI_Service
    Provider --> Weather_Service
    Provider --> Notif_Service

    API_Service <--> |HTTPS + JWT Auth| Server
    Server <--> MongoDB
    Server <--> |Verify Token| Clerk
    
    AI_Service <--> |HTTPS Key| Groq
    AI_Service <--> |HTTPS Key| Gemini
    Weather_Service <--> |HTTPS| Meteo
```

### Thành phần kiến trúc:
*   **Frontend**: Ứng dụng Flutter sử dụng kiến trúc State Management bằng **Provider**. Cache cục bộ qua **SharedPreferences** để đảm bảo tốc độ phản hồi nhanh và khả năng hoạt động offline tạm thời.
*   **Backend Server**: Viết bằng **Node.js/Express**, deploy linh hoạt trên **Render** hoặc **Pterodactyl**. Hệ quản trị cơ sở dữ liệu phi quan hệ **MongoDB Atlas** dùng để lưu trữ lâu dài kho thực phẩm và thực đơn của người dùng.
*   **Xác thực và Bảo mật**: Token JWT được tạo từ **Clerk Auth** ở client và được xác thực qua middleware của backend để bảo vệ các API endpoint.

---

## 3. Sơ đồ Tuần tự (Sequence Diagram) - Luồng Danh sách mua sắm thông minh
Minh họa luồng hoạt động chi tiết khi người dùng yêu cầu tạo danh sách nguyên liệu từ thực đơn lịch và tự động đồng bộ ngược lại vào kho sau khi mua.

```mermaid
sequenceDiagram
    autonumber
    actor U as Người dùng (User)
    participant UI as Màn hình Meal Calendar
    participant Provider as AppProvider
    participant LocalDB as SharedPreferences (Cache)
    participant AI as Hearthie AI / Rules

    U->>UI: Chọn Ngày/Tuần & bật "Trừ nguyên liệu" -> Click "Tạo danh sách mua"
    UI->>Provider: generateShoppingFromDailyMealPlans(anchorDate, weekly, deductInventory: true)
    
    Note over Provider: 1. Tính toán khoảng thời gian:<br/>- Ngày: chính ngày đã chọn<br/>- Tuần: Thứ Hai -> Chủ Nhật của tuần chứa ngày đó
    
    Provider->>Provider: 2. Lấy danh sách thực đơn trong khoảng thời gian (dailyPlansInRange)
    Provider->>Provider: 3. Tổng hợp nguyên liệu cần dùng từ các công thức (ingredientsNeeded)
    
    alt deductInventory == true
        Provider->>Provider: 4. Lấy danh sách thực phẩm trong kho (chưa hết hạn)
        Provider->>Provider: 5. So khớp tên & Quy đổi đơn vị (g <-> kg, ml <-> l)
        Provider->>Provider: 6. Trừ đi số lượng có sẵn trong tủ
    end
    
    Provider->>LocalDB: 7. Lưu danh sách mua sắm nháp (shopping_plan_items)
    Provider->>UI: 8. Cập nhật State (notifyListeners)
    UI->>U: Hiển thị Bottom Sheet chứa Danh sách mua sắm đã tối ưu

    U->>UI: Đánh dấu đã mua (isPurchased = true)
    UI->>Provider: setShoppingPurchased(id, true)
    
    alt Tự động nhập kho (Auto add to inventory) == true
        Provider->>AI: Gọi AI Hearthie để phân loại Danh mục (Category) & Vị trí (Storage)
        AI-->>Provider: Trả về: Category (Rau, Thịt...) & Storage (Ngăn đông, mát...)
        Provider->>Provider: Tạo FoodItem mới & thêm vào đầu danh sách Kho
        Provider->>LocalDB: Đồng bộ với Cache SharedPreferences
        Provider->>UI: notifyListeners()
        UI->>U: Hiển thị Snackbar "Đã nhập X món vào kho"
    end
```

---

## 4. Sơ đồ Quản lý Trạng thái & Luồng Dữ liệu (State Management & Data Flow)
Biểu diễn cách dữ liệu luân chuyển giữa các màn hình UI, lớp quản lý trạng thái tập trung (`AppProvider`), cơ sở dữ liệu cục bộ và cơ sở dữ liệu đám mây.

```mermaid
flowchart TD
    %% Entities
    UI[UI Screens: Dashboard, Inventory, Calendar, Profile]
    Provider[AppProvider: Central State Container]
    LocalCache[(SharedPreferences)]
    API[BackendApiService]
    Express[Express.js Node Backend]
    DB[(MongoDB Database)]

    %% Initialization Flow
    UI -- 1. Trình bày UI --> Provider
    Provider -- 2. Đọc Cache lúc khởi động --> LocalCache
    LocalCache -- Trả về danh sách lưu tạm --> Provider

    %% Read Operations
    Provider -- 3. Yêu cầu tải dữ liệu mới --> API
    API -- 4. Gọi API (HTTP GET + Bearer Token) --> Express
    Express -- 5. Lọc dữ liệu theo Clerk User ID --> DB
    DB -- Trả về dữ liệu gốc --> Express
    Express -- Trả về JSON Rows --> API
    API -- Phân tích dữ liệu gốc thành Models --> Provider
    Provider -- 6. Cập nhật UI (notifyListeners) --> UI

    %% Write Operations
    UI -- A. Người dùng thao tác (Thêm món, Sửa lịch...) --> Provider
    Provider -- B. Lưu tức thời vào Cache --> LocalCache
    Provider -- C. Gửi yêu cầu cập nhật (HTTP POST/PUT/DELETE) --> API
    API -- D. Lưu trữ dữ liệu đám mây --> Express
    Express -- E. Ghi nhận thay đổi lâu dài --> DB
```
