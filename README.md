# 📱 SimpleChat - Realtime Chat Application

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-brightgreen?style=for-the-badge" alt="Platforms" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="License" />
</p>

**SimpleChat** là một ứng dụng nhắn tin thời gian thực đa nền tảng được phát triển bằng **Flutter Framework** và ngôn ngữ **Dart**, kết hợp với giải pháp hạ tầng Serverless mạnh mẽ từ **Google Firebase (BaaS)**. Ứng dụng cung cấp trải nghiệm giao tiếp tức thời mượt mà, bảo mật với khả năng truyền tải dữ liệu truyền thông đa phương tiện tối ưu.

---

## ✨ Tính năng cốt lõi (Key Features)

### 🔐 1. Quản lý tài khoản (Authentication)
* **Đăng ký / Đăng nhập:** Xác thực người dùng an toàn thông qua *Firebase Auth*.
* **Rào chắn dữ liệu (Validation):** Kiểm tra định dạng đầu vào bằng biểu thức chính quy (Regex) nghiêm ngặt cho Email, Số điện thoại và Họ tên.
* **Hồ sơ cá nhân:** Xem, cập nhật thông tin cá nhân (Họ tên, Ngày sinh) và Đổi mật khẩu phiên làm việc trực tiếp.

### 💬 2. Nghiệp vụ Nhắn tin thời gian thực (Realtime Chatting)
* **Chat đơn (1-1) & Chat nhóm (Group Chat):** Đồng bộ hóa dữ liệu tin nhắn tức thời nhờ cơ chế `StreamBuilder` kết nối trực tiếp với *Cloud Firestore* (độ trễ < 100ms).
* **Tin nhắn đa phương tiện (Multimedia):** Hỗ trợ gửi Hình ảnh (`image_picker`) và Tin nhắn thoại (`record`). Hệ thống sử dụng giải pháp **Mã hóa chuỗi Base64** để tối ưu hóa lưu trữ tốc độ cao trên nền tảng Serverless NoSQL.
* **Tính năng nâng cao phòng chat:** * Thu hồi tin nhắn (`Recall Message`).
  * Ghim tin nhắn (`Pin Message`) lên đầu khung chat kèm cơ chế tự động cuộn mượt mà.

### 👥 3. Danh bạ và Quan hệ bạn bè (Contacts Management)
* **Tìm kiếm thông minh:** Tìm người dùng lạ toàn hệ thống thông qua Email hoặc Số điện thoại.
* **Tương tác danh bạ:** Gửi lời mời kết bạn, phản hồi chấp nhận/từ chối, Hủy kết bạn song phương (`Unfriend`) và Chặn người dùng (`Block`) an toàn nhờ kỹ thuật xử lý lệnh nguyên tử `WriteBatch` của Firestore.

### 🕒 4. Khoảnh khắc & Bản tin (Discovery Stories)
* **Tạo Story:** Đăng tải hình ảnh ngắn kèm trạng thái (`Caption`) tự động hết hạn và ẩn sau 24 giờ.
* **Bản tin:** Lắng nghe và hiển thị vòng tròn danh sách các story thời gian thực từ danh bạ bạn bè.

---

## 🛠️ Hệ sinh thái công nghệ (Technology Stack)

* **Frontend:** Flutter SDK (v3.19.0+), Ngôn ngữ Dart (v3.3.0+).
* **Backend Cloud (Firebase BaaS):** * `firebase_core`: Khởi tạo và cấu hình ứng dụng liên kết đám mây.
  * `firebase_auth`: Định danh, quản lý phiên và mã hóa mật khẩu người dùng.
  * `cloud_firestore`: Cơ sở dữ liệu NoSQL (Document-Collection) đồng bộ Realtime qua WebSocket.
* **Multimedia Hardware Plugins:** `audioplayers` (Phát nhạc thoại), `record` (Ghi âm từ Micro), `image_picker` (Truy cập thư viện ảnh/Camera).
* **Utilities:** `intl` (Định dạng thời gian, ngày sinh), `crypto` (Mã hóa SHA-256/MD5).

---

## 📂 Cấu trúc thư mục mã nguồn (`/lib`)

Mã nguồn được tổ chức chặt chẽ theo mô hình **Component-Based Architecture** kết hợp lớp dịch vụ tĩnh cô lập (**Service Layer Pattern**):

```text
lib/
├── main.dart                  # Điểm khởi chạy ứng dụng (Main Entry Point)
├── firebase_options.dart      # Khóa API cấu hình môi trường liên kết Firebase
├── services/                  # TẦNG DỊCH VỤ (Service Layer - Xử lý logic & Database)
│   ├── chat_interaction_service.dart  # Xử lý tĩnh gửi/đọc tin nhắn, Base64 audio/image
│   └── voice_message_bubble.dart       # Custom State Widget điều khiển phần cứng trình phát nhạc thoại
└── [screens]/                 # TẦNG GIAO DIỆN (Presentation Layer - UI Widgets)
    ├── auth_screen.dart       # Đăng ký, đăng nhập, kiểm thử dữ liệu đầu vào
    ├── main_navigation.dart   # Thanh điều hướng Tab-Based chính của hệ thống
    ├── chat_list_screen.dart  # Danh sách phòng chat đơn/nhóm (Hộp thư đến)
    ├── chat_screen.dart       # Phòng hội thoại 1-1 thời gian thực
    ├── chat_options_screen.dart # Tùy chọn nâng cao chat đơn (Xóa lịch sử, Block)
    ├── group_chat_screen.dart # Phòng hội thoại nhóm tích hợp bộ ghi âm
    ├── group_info_screen.dart # Quản trị nhóm (Thêm/Mời thành viên, Rời nhóm, Giải tán)
    ├── create_group_screen.dart # Giao diện khởi tạo phòng chat nhóm mới
    ├── contacts_screen.dart   # Màn hình chứa phân tách Tab Danh bạ
    ├── friends_tab.dart       # Quản lý danh sách bạn bè và lời mời kết bạn
    ├── groups_tab.dart        # Hiển thị danh sách các nhóm đã tham gia
    ├── discovery_screen.dart  # Đăng và xem Stories 24h từ danh bạ
    └── profile_screen.dart    # Xem hồ sơ cá nhân, đổi mật khẩu và đăng xuất
