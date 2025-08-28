# 🛡️ BachDinhRM Aggressive Privacy Script (ShutUp10++ Clone)

## 📖 Giới thiệu
Script PowerShell này là một **bản clone mang tính “aggressive” của O&O ShutUp10++**.  
Mục tiêu chính:
- Giảm thiểu tối đa **telemetry, quảng cáo, tracking và bloatware** trong Windows 10/11.
- Tự động **backup & restore** (registry, firewall, hosts, dịch vụ, scheduled tasks).
- Cho phép **Apply** (áp dụng) hoặc **Revert** (hoàn tác) toàn bộ thay đổi.  
- Có thể chạy ở chế độ **DryRun** để xem trước thay đổi mà không áp dụng thật.  

⚠️ **CẢNH BÁO**  
Script này **can thiệp sâu vào hệ thống** (registry, services, firewall, appx).  
👉 Bạn nên **backup hệ thống** hoặc tạo **Restore Point** trước khi chạy.  
👉 Script dành cho người dùng nâng cao, **tự chịu trách nhiệm khi sử dụng**.  

---

## ✨ Tính năng chính
- **Backup trước khi Apply**
  - Registry (`.reg`)
  - Hosts (`hosts.bak`)
  - Firewall rules (`.wfw`)
  - Services (`.json`)
  - Tasks (`.xml`)
- **Apply**
  - Thiết lập nhiều registry policies để chặn telemetry, quảng cáo, Cortana, SmartScreen…
  - Vô hiệu hóa các dịch vụ không cần thiết và nhiều scheduled tasks.
  - Gỡ bỏ bloatware Appx (Xbox, BingWeather, FeedbackHub, …).
  - Thêm entry `hosts` để chặn domain telemetry.
  - Tạo firewall rules để chặn IP telemetry (theo DNS resolve hiện tại).
- **Revert**
  - Khôi phục registry từ backup.
  - Khôi phục hosts file.
  - Import lại firewall rules, đồng thời xóa các rule do script thêm.
  - Khôi phục lại trạng thái dịch vụ.
  - Xuất task backup `.xml` để bạn có thể tạo lại thủ công (nếu cần).

---

## ⚙️ Yêu cầu
- Windows 10 hoặc Windows 11  
- Quyền **Administrator** khi chạy PowerShell  
- Cho phép thực thi script bằng cách:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope Process

🚀 Cách sử dụng

Clone repo

git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>


Các tham số chính

-Action : Apply hoặc Revert

-DryRun : Chạy thử, chỉ in log thay vì áp dụng thật

Ví dụ chạy

Chạy thử (xem trước thay đổi):

.\BachDinhRM_Aggressive_v1.ps1 -Action Apply -DryRun


Áp dụng thay đổi:

.\BachDinhRM_Aggressive_v1.ps1 -Action Apply


Hoàn tác thay đổi:

.\BachDinhRM_Aggressive_v1.ps1 -Action Revert

📂 Cấu trúc thư mục backup

Mỗi lần chạy, script sẽ tạo một thư mục backup riêng trong:

C:\ProgramData\BachDinhRM_Backup_YYYYMMDD-HHMMSS\


Bên trong có thể gồm:

│── hosts.bak                   (backup file hosts)
│── firewall_backup.wfw          (backup firewall rules)
│── Registry\*.reg               (backup registry keys)
│── Services\service_*.json      (backup thông tin service)
│── Tasks\task_*.xml             (backup scheduled tasks)
│── appx_*.json                  (backup appx package info)
│── BachDinhRM_log_*.txt         (file log chi tiết)

📋 Log

Mọi hành động đều được ghi lại trong file log, ví dụ:

BachDinhRM_log_20250828-112300.txt


Trong log sẽ hiển thị:

Các bước backup

Registry keys được chỉnh

Services / Tasks bị vô hiệu hóa

Appx bị gỡ bỏ

Firewall rules được thêm

Thông tin khi revert

📌 Ghi chú sử dụng

Danh sách services, tasks, appx, registry và telemetry hosts được chọn ở mức aggressive.

Bạn có thể tự chỉnh sửa trong script:

$servicesToDisable

$tasksToDisable

$appxToRemove

$regTargets

$telemetryHosts

Việc Restore Tasks hiện chỉ export .xml, cần khôi phục thủ công bằng:

schtasks /Create /TN "<TaskName>" /XML "task_backup.xml"
