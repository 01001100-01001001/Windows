# 📋 Services mặc định khi cài mới Windows 10 22H2 2025  

Đây là **tài liệu mở rộng** của bài viết gốc tại 👉 [Windows thực sự đang chạy những gì?](https://bachdinh.com/article/windows-thuc-su-dang-chay-nhung-gi).  

---

## 📑 Danh sách dịch vụ theo nhóm

| 🔹 Nhóm               | 🛠️ Service                                    | 📂 Tiến trình/DLL                                | 📝 Vai trò chính                                                                 |
|-----------------------|-----------------------------------------------|--------------------------------------------------|---------------------------------------------------------------------------------|
| **System & Logging**  | Event Log • EventLog                          | `svchost.exe -k LocalServiceNetworkRestricted`   | Ghi log hệ thống/ứng dụng/bảo mật → nền tảng cho **Event Viewer**.              |
|                       | Task Scheduler • Schedule                     | `svchost.exe -k netsvcs`                         | Chạy tác vụ định kỳ/trigger (Windows Update, backup…).                         |
|                       | COM+ Event System • EventSystem               | `svchost.exe -k LocalService`                    | Hỗ trợ sự kiện COM+, nền cho **SENS** và nhiều dịch vụ phụ thuộc.              |
| **Network**           | DHCP Client • Dhcp                            | `svchost.exe -k LocalServiceNetworkRestricted`   | Nhận IP động từ DHCP server cho LAN/Wi-Fi.                                      |
|                       | DNS Client • Dnscache                         | `svchost.exe -k NetworkService`                  | Phân giải tên miền ↔ IP, cache DNS.                                             |
|                       | Network Store Interface Service • nsi         | `svchost.exe -k LocalServiceNetworkRestricted`   | Cung cấp thông tin trạng thái mạng cho stack/network clients.                   |
|                       | Network Location Awareness • NlaSvc           | `svchost.exe -k NetworkService`                  | Xác định profile mạng (Domain/Private/Public), ảnh hưởng firewall/policy.       |
|                       | IP Helper • iphlpsvc                          | `svchost.exe -k NetSvcs`                         | Hỗ trợ IPv6, tunnel, transition (Teredo/ISATAP…), API netsh.                   |
|                       | Workstation • LanmanWorkstation               | `svchost.exe -k NetworkService`                  | Kết nối đến shares/máy khác trong mạng (client SMB).                           |
|                       | Server • LanmanServer                         | `svchost.exe -k netsvcs`                         | Chia sẻ file/máy in (server SMB).                                               |
|                       | Background Intelligent Transfer Service • BITS| `svchost.exe -k netsvcs`                         | Truyền tải nền tiết kiệm băng thông (WU, Defender, Store…).                     |
|                       | Windows Update • wuauserv                     | `svchost.exe -k netsvcs`                         | Tải/cài cập nhật Windows, driver, bản vá bảo mật.                               |
| **Bảo mật & Tài khoản**| Remote Procedure Call • RPCSS                 | `svchost.exe -k rpcss`                           | Nền tảng RPC cho inter-process/distributed, rất nhiều dịch vụ phụ thuộc.        |
|                       | RPC Endpoint Mapper • RpcEptMapper            | `svchost.exe -k RPCSS`                           | Ánh xạ endpoint RPC, bắt buộc cho RPC hoạt động.                                |
|                       | Security Accounts Manager • SamSs             | `lsass.exe`                                      | Quản lý CSDL tài khoản cục bộ, tham gia quá trình xác thực.                     |
|                       | Windows Time • W32Time                        | `svchost.exe -k LocalService`                    | Đồng bộ thời gian (quan trọng cho Kerberos, chứng chỉ, TLS).                   |
|                       | Cryptographic Services • CryptSvc             | `svchost.exe -k NetworkService`                  | Catalog/chữ ký số, cập nhật chứng chỉ gốc, xác minh integrity.                  |
| **Tường lửa & Lọc gói**| Base Filtering Engine • BFE                   | `svchost.exe -k LocalServiceNoNetwork`           | Nền tảng lọc gói/Policy cho Firewall & IPsec.                                   |
|                       | Windows Defender Firewall • MpsSvc            | `svchost.exe -k LocalServiceNoNetworkFirewall`   | Tường lửa Windows dựa trên BFE.                                                 |
| **Quản lý phần cứng** | Plug and Play • PlugPlay                      | `svchost.exe -k DcomLaunch`                      | Phát hiện/cấu hình thiết bị (USB, PCIe…).                                      |
|                       | DCOM Server Process Launcher • DcomLaunch     | `svchost.exe -k DcomLaunch`                      | Khởi chạy tiến trình COM/DCOM, nền tảng cho nhiều services.                     |
| **Thông báo hệ thống**| System Event Notification Service • SENS       | `svchost.exe -k netsvcs`                         | Theo dõi logon/network/power events, thông báo cho subscribers.                 |
| **On-Demand/Hỗ trợ** | Windows Installer • msiserver                  | `msiexec.exe` (khi cần)                          | Cài đặt/repair MSI, thường là **Manual (Demand start)**.                        |
