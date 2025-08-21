# 📋 Services mặc định khi cài mới Windows 10 22H2 2025  

Đây là **tài liệu mở rộng** của bài viết gốc tại 👉 [Windows thực sự đang chạy những gì?](https://bachdinh.com/article/windows-thuc-su-dang-chay-nhung-gi).  

---

## 📑 Danh sách dịch vụ theo nhóm

| 🔹 Nhóm            | 🛠️ Service                    | 📂 Tiến trình/DLL                              | 📝 Vai trò chính                                                                 |
|--------------------|-------------------------------|------------------------------------------------|---------------------------------------------------------------------------------|
| **System & Logging** | Event Log • EventLog          | `svchost.exe -k LocalServiceNetworkRestricted` | Ghi log hệ thống/ứng dụng/bảo mật → nền tảng cho **Event Viewer**.              |
|                    | Task Scheduler • Schedule      | `svchost.exe -k netsvcs`                       | Chạy tác vụ định kỳ/trigger (Windows Update, backup…).                         |
|                    | COM+ Event System • EventSystem| `svchost.exe -k LocalService`                  | Hỗ trợ sự kiện COM+, nền cho **SENS** và nhiều dịch vụ phụ thuộc.              |
