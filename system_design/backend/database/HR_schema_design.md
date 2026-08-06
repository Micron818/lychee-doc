# HR (Human Resources) 模組資料庫設計文件

## 1. 模組概述
HR 模組負責管理企業的人力資源，包含員工資料 (Personnel)、考勤 (Time & Attendance)、請假 (Leave Management) 以及薪資計算 (Payroll)。

## 2. 實體關係圖 (ERD) 概念

核心為 **員工 (Employees)**，連結至其他子系統：

*   **員工主檔**: `employees` 連結至 `users` (系統帳號) 與 `departments` (部門)。
*   **組織管理**: `job_titles` 定義職務與職級。
*   **考勤管理**: `attendance_records` 記錄每日打卡與出勤狀態 (遲到/早退/正常)。
*   **請假管理**: `leave_requests` 處理請假申請與簽核流程，並連結至假別選項。
*   **薪資管理**: 
    *   `payroll_periods`: 定義計薪週期。
    *   `payslips`: 員工個人的薪資單 (Header)。
    *   `payslip_items`: 薪資單明細，記錄各項加項 (Allowances) 與扣項 (Deductions)。

## 3. 資料表清單與設計備忘

### 3.1 職稱 (job_titles)
*   **用途**: 定義企業內部的職務名稱與職級。
*   **關鍵欄位**:
    *   `code`: 職務代碼。
    *   `name`: 職務名稱 (e.g., 工程師, 經理)。

### 3.2 員工 (employees)
*   **用途**: 員工基本資料主檔。
*   **關鍵欄位**:
    *   `code`: 員工編號 (Employee ID)。
    *   `department_id`: 所屬部門 (Link to ADM module)。
    *   `manager_id`: 直屬主管 (Self-referencing FK)。
    *   `user_id`: 關聯系統登入帳號 (Link to BASIS module)。
    *   `hire_date` / `termination_date`: 在職期間。

### 3.3 請假申請 (leave_requests)
*   **用途**: 員工請假單。
*   **關鍵欄位**:
    *   `leave_type_option_id`: 假別 (事假、病假、特休)。
    *   `status_option_id`: 簽核狀態 (待簽核、已核准、退回)。
    *   `approver_id`: 實際簽核人。

### 3.4 考勤記錄 (attendance_records)
*   **用途**: 每日出勤打卡記錄。
*   **關鍵欄位**:
    *   `check_in_time` / `check_out_time`: 實際打卡時間。
    *   `status_option_id`: 系統判定的出勤狀態 (正常、遲到、曠職)。

### 3.5 薪資週期 (payroll_periods)
*   **用途**: 管理每月的計薪區間。
*   **關鍵欄位**:
    *   `is_closed`: 是否已結算並鎖定。
    *   `payment_date`: 預計發放日。

### 3.6 薪資單 (payslips)
*   **用途**: 員工個人的月薪彙總。
*   **關鍵欄位**:
    *   `total_earnings`: 應發總額。
    *   `total_deductions`: 應扣總額。
    *   `net_salary`: 實發金額 (Take-home pay)。

### 3.7 薪資明細 (payslip_items)
*   **用途**: 薪資單的詳細組成項目。
*   **關鍵欄位**:
    *   `salary_component_option_id`: 薪資項目 (本薪、伙食津貼、勞健保、所得稅)。
    *   `is_deduction`: 標記此項目是否為扣款。

## 4. 關鍵選項值建議 (Reference Data)

以下為 HR 模組中常用 `option_values` 的建議值：

### 4.1 員工狀態 (Employment Status)
*   **Category Code**: `EMPLOYMENT_STATUS`
*   **Values**: `ACTIVE` (在職), `RESIGNED` (離職), `ON_LEAVE` (留職停薪), `PROBATION` (試用期)

### 4.2 假別 (Leave Type)
*   **Category Code**: `LEAVE_TYPE`
*   **Values**: `ANNUAL` (特休), `SICK` (病假), `PERSONAL` (事假), `MATERNITY` (產假), `UNPAID` (無薪假)

### 4.3 考勤狀態 (Attendance Status)
*   **Category Code**: `ATTENDANCE_STATUS`
*   **Values**: `PRESENT` (正常), `LATE` (遲到), `EARLY_LEAVE` (早退), `ABSENT` (缺勤/曠職)

### 4.4 薪資項目 (Salary Component)
*   **Category Code**: `SALARY_COMPONENT`
*   **Values**: 
    *   `BASIC_SALARY` (本薪)
    *   `MEAL_ALLOWANCE` (伙食津貼)
    *   `OVERTIME_PAY` (加班費)
    *   `TRANSPORT_ALLOWANCE` (交通津貼)
    *   `INCOME_TAX` (所得稅)
    *   `INSURANCE` (勞/健保)

### 4.5 薪資單狀態 (Payslip Status)
*   **Category Code**: `PAYSLIP_STATUS`
*   **Values**: `DRAFT` (草稿), `CALCULATED` (已計算), `APPROVED` (已核准), `PAID` (已發放)

## 5. 檔案路徑對照

| 資料表 | SQL 檔案路徑 |
| :--- | :--- |
| job_titles | `docs/database/sql/schema_tables/HR/job_titles.sql` |
| employees | `docs/database/sql/schema_tables/HR/employees.sql` |
| leave_requests | `docs/database/sql/schema_tables/HR/leave_requests.sql` |
| attendance_records | `docs/database/sql/schema_tables/HR/attendance_records.sql` |
| payroll_periods | `docs/database/sql/schema_tables/HR/payroll_periods.sql` |
| payslips | `docs/database/sql/schema_tables/HR/payslips.sql` |
| payslip_items | `docs/database/sql/schema_tables/HR/payslip_items.sql` |

