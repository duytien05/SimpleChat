# 📱 SimpleChat - Realtime Chat & Educational Hub Application

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Agora-099DFD?style=for-the-badge&logo=agora&logoColor=white" alt="Agora RTC" />
  <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-brightgreen?style=for-the-badge" alt="Platforms" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="License" />
</p>

**SimpleChat** là một ứng dụng nhắn tin, gọi thoại/video thời gian thực và chia sẻ tài nguyên học tập đa nền tảng (Android, iOS, Web Browser) được phát triển bằng **Flutter Framework**, kết hợp với mô hình kiến trúc **Realtime Hybrid Backend** từ **Google Firebase (BaaS)** và **Agora RTC Engine**. 

Ứng dụng không chỉ mang đến trải nghiệm giao tiếp tức thì mượt mà với độ trễ siêu thấp mà còn tích hợp phân hệ **Hub Học Tập** cộng đồng, giải quyết triệt để các thách thức kỹ thuật về mã hóa nhị phân và xuất file cross-browser.

---

## ✨ Tính năng cốt lõi (Key Features)

### 🔐 1. Quản lý tài khoản (Authentication & Security)
- **Đăng ký / Đăng nhập:** Xác thực người dùng an toàn thông qua *Firebase Auth*.
- **Rào chắn dữ liệu (Validation):** Kiểm tra định dạng đầu vào bằng biểu thức chính quy (Regex) nghiêm ngặt cho Email, Số điện thoại và Họ tên.
- **Hồ sơ cá nhân (`ProfileScreen`):** Quản lý hồ sơ, cập nhật tên hiển thị, ảnh đại diện và Đổi mật khẩu phiên làm việc trực tiếp.

### 💬 2. Nhắn tin thời gian thực & Đa phương tiện (Realtime Chatting & Media)
- **Chat đơn (1-1) & Chat nhóm (Group Chat):** Đồng bộ hóa tin nhắn tức thời nhờ luồng `StreamBuilder` kết nối trực tiếp với *Cloud Firestore* (độ trễ < 100ms).
- **Tin nhắn đa phương tiện:** Hỗ trợ gửi Hình ảnh (`image_picker`), Tin nhắn thoại (`audio_recorder`, `audioplayers`) và Tài liệu tệp tin. 
- **Quản trị phòng chat:** Thu hồi tin nhắn (`Recall Message`), Ghim tin nhắn (`Pin Message`), Xóa lịch sử trò chuyện và Chặn liên lạc (`Block`).

### 📞 3. Cuộc gọi Thoại & Video thời gian thực (VoIP Audio/Video Call)
- **Tích hợp Agora RTC SDK:** Cung cấp trải nghiệm đàm thoại voice và video call với độ trễ siêu thấp và chất lượng truyền tải cao qua hạ tầng Agora SD-RTN™.
- **Cơ chế Signaling qua Firebase:** Tự động phát tín hiệu chuông báo cuộc gọi đến thời gian thực (`IncomingCallScreen`) và chuyển tiếp kết nối vào phòng đàm thoại (`ActiveCallScreen`).

### 🎓 4. Hub Học Tập & Chia sẻ Tài Liệu Cộng Đồng (Learning Hub)
- **Đẩy tài liệu từ Khung Chat lên Hub:** Cho phép người dùng chia sẻ nhanh các tài liệu từ đoạn hội thoại lên thư viện chung kèm theo Tiêu đề, Mô tả và Phân loại danh mục (CNTT, Kinh tế, Ngoại ngữ, Kỹ thuật...).
- **Lọc & Tìm kiếm thông minh:** Phân loại tài liệu theo danh mục môn học/ngành học linh hoạt thông qua hệ thống `FilterChip`.
- **Giải mã Nhị phân & Cross-Browser Download:** Xử lý chuẩn hóa MIME-Type và giải mã chuỗi Base64 Data URL sang mảng byte nhị phân (`Uint8List`) kết hợp đối tượng `html.Blob`. Tải xuống chính xác, không bị hỏng cấu trúc (corrupted) đối với tất cả các định dạng tài liệu Office (`.docx`, `.xlsx`, `.pptx`) và PDF trên trình duyệt Web.

### 👥 5. Danh bạ & Khoảnh khắc (Contacts & Stories)
- **Tương tác danh bạ:** Tìm kiếm người dùng qua Email/SĐT, gửi lời mời kết bạn, hủy kết bạn (`Unfriend`) an toàn bằng các giao dịch nguyên tử `WriteBatch` trên Firestore.
- **Khoảnh khắc (Discovery Stories):** Đăng tải hình ảnh kèm trạng thái (`Caption`) tự động hết hạn và ẩn sau 24 giờ.

---

## 🛠️ Hệ sinh thái công nghệ (Technology Stack)

- **Frontend & Cross-Platform UI:** Flutter SDK (v3.19.0+), Ngôn ngữ Dart (v3.3.0+).
- **Backend Serverless (Firebase BaaS):** 
  * `firebase_core`: Khởi tạo và cấu hình liên kết đám mây.
  * `firebase_auth`: Định danh, quản lý phiên và mã hóa mật khẩu.
  * `cloud_firestore`: Cơ sở dữ liệu NoSQL (Realtime Stream Data).
- **Real-Time Communication (RTC):**
  * `agora_rtc_engine`: Hạ tầng truyền phát Audio/Video Call thời gian thực.
  * `permission_handler`: Cấp quyền thiết bị (Camera, Microphone) linh hoạt.
- **Multimedia & File Handling:**
  * `file_picker`: Bộ chọn tài liệu hệ thống chuẩn.
  * `audioplayers` & `record`: Thu âm ghi âm và trình phát tin nhắn thoại.
  * `image_picker`: Truy cập thư viện ảnh/Camera.
  * `url_launcher`: Kích hoạt trình xuất và liên kết ngoài.
- **Utilities & Cryptography:** `intl` (Định dạng thời gian), `crypto` (Mã hóa băm SHA-256/MD5).

---

## 📂 Cấu trúc thư mục mã nguồn (`/lib`)

Mã nguồn được tổ chức chặt chẽ theo mô hình **Component-Based Architecture** kết hợp tầng dịch vụ độc lập (**Service Layer Pattern**):

```text
lib/
├── main.dart                   # Điểm khởi chạy ứng dụng (Main Entry Point)
├── firebase_options.dart       # Khóa API cấu hình môi trường liên kết Firebase
├── services/                   # TẦNG DỊCH VỤ (Service Layer - Logic & Database)
│   ├── chat_interaction_service.dart # Xử lý gửi/đọc tin nhắn, Base64 & Đẩy lên Hub
│   ├── document_service.dart         # Truy vấn & quản lý tài liệu công khai trên Hub
│   ├── document_picker_service.dart  # Bắt file hệ thống & mã hóa Base64 Data URL
│   └── call_service.dart             # Điều phối signaling cuộc gọi & Agora Engine
├── widgets/                    # TẦNG TÁI SỬ DỤNG (Custom Widgets)
│   ├── document_message_bubble.dart  # Bong bóng chat hiển thị & tải file tài liệu
│   └── voice_message_bubble.dart     # Trình phát âm thanh tin nhắn thoại
└── screen/                     # TẦNG GIAO DIỆN CHÍNH (Presentation Layer - UI Screens)
    ├── auth_screen.dart        # Đăng ký, đăng nhập, kiểm thử dữ liệu đầu vào
    ├── main_navigation.dart    # Thanh điều hướng Tab-Based chính
    ├── chat_list_screen.dart   # Hộp thư đến (Danh sách phòng chat 1v1 & nhóm)
    ├── chat_screen.dart        # Phòng hội thoại 1-1 thời gian thực & Gọi điện
    ├── chat_options_screen.dart# Tùy chọn nâng cao chat đơn (Xóa lịch sử, Block)
    ├── group_chat_screen.dart  # Phòng chat nhóm tích hợp bộ ghi âm & gửi file
    ├── group_info_screen.dart  # Quản trị nhóm (Thêm/Mời thành viên, Rời nhóm, Giải tán)
    ├── create_group_screen.dart# Khởi tạo phòng chat nhóm mới
    ├── learning_hub_screen.dart# HUB HỌC TẬP: Lọc danh mục & Tải tài liệu về máy
    ├── active_call_screen.dart # Giao diện màn hình cuộc gọi đang diễn ra (Agora)
    ├── incoming_call_screen.dart# Chuông báo cuộc gọi đến thời gian thực
    ├── contacts_screen.dart    # Màn hình Tab Danh bạ (Bạn bè & Nhóm)
    ├── friends_tab.dart        # Quản lý danh sách bạn bè & Lời mời kết bạn
    ├── groups_tab.dart         # Hiển thị danh sách các nhóm đã tham gia
    ├── discovery_screen.dart   # Đăng và xem Stories 24h
    └── profile_screen.dart     # Hồ sơ cá nhân, đổi mật khẩu và đăng xuất
