# 📋 Danh sách Windows Services  

Đây là **tài liệu mở rộng** của bài viết gốc tại 👉 [Windows thực sự đang chạy những gì?](https://bachdinh.com/article/windows-thuc-su-dang-chay-nhung-gi).  

Trong hệ điều hành **Windows**, **Services (dịch vụ)** là các chương trình chạy ngầm (_background processes_)  
chịu trách nhiệm cho nhiều tính năng hệ thống như:  

- 🌐 Mạng (Network)  
- 🔒 Bảo mật (Security)  
- 🔄 Cập nhật (Update)  
- 🖨️ In ấn (Printing)  
- ☁️ Đồng bộ dữ liệu (Data synchronization)  
- ⚙️ Và nhiều chức năng khác  

---

## 📑 Danh sách dịch vụ theo nhóm

```text
🔹 Nhóm                🛠️ Service                          📂 Tiến trình/DLL                                📝 Vai trò chính
System & Logging       Event Log • EventLog                 svchost.exe -k LocalServiceNetworkRestricted      Ghi log hệ thống/ứng dụng/bảo mật → nền tảng cho Event Viewer.
                       Task Scheduler • Schedule            svchost.exe -k netsvcs                            Chạy tác vụ định kỳ/trigger (Windows Update, backup…).
                       COM+ Event System • EventSystem      svchost.exe -k LocalService                       Hỗ trợ sự kiện COM+, nền cho SENS và nhiều dịch vụ phụ thuộc.
