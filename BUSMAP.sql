USE BUSMAP;
-- =========================================================================
-- 0. XÓA BẢNG (DROP TABLES)
-- Đảm bảo thứ tự để xóa Khóa Ngoại an toàn
-- =========================================================================

-- Xóa các Bảng Trung Gian trước
DROP TABLE IF EXISTS ThongBao_PhuHuynh;
DROP TABLE IF EXISTS TaiXe_ThongBao;
DROP TABLE IF EXISTS LichTrinh_TaiXe;
DROP TABLE IF EXISTS XeBus_LichTrinh;
DROP TABLE IF EXISTS TuyenDuong_LichTrinh;

-- Xóa các bảng có Khóa Ngoại (bảng con)
DROP TABLE IF EXISTS BaoCao;
DROP TABLE IF EXISTS CanhBao;
DROP TABLE IF EXISTS ThongBao;
DROP TABLE IF EXISTS HocSinh;
DROP TABLE IF EXISTS HanhTrinh;
DROP TABLE IF EXISTS LichTrinh;
DROP TABLE IF EXISTS XeBus;
DROP TABLE IF EXISTS TuyenDuong;
DROP TABLE IF EXISTS TaiXe;
DROP TABLE IF EXISTS PhuHuynh;

-- Xóa các bảng gốc (bảng cha)
DROP TABLE IF EXISTS Admin;

-- =========================================================================
-- 1. TẠO CÁC BẢNG (CREATE TABLES)
-- Đã thêm MaNV (FK từ Admin) vào 8 bảng phụ thuộc
-- =========================================================================

-- Bảng ADMIN (Bảng cha)
CREATE TABLE Admin (
    MaNV NVARCHAR(20) PRIMARY KEY,
    Ten NVARCHAR(50) NOT NULL,
    SoDienThoai VARCHAR(10) NOT NULL,
    DiaChi NVARCHAR(100) NOT NULL
);

-- Bảng TUYEN_DUONG (1-N với Admin)
CREATE TABLE TuyenDuong (
    MaTD NVARCHAR(20) PRIMARY KEY,
    Ten NVARCHAR(50) NOT NULL,
    DiemBatDau NVARCHAR(50) NOT NULL,
    DiemKetThuc NVARCHAR(50),

    MaNV NVARCHAR(20), 
    FOREIGN KEY (MaNV) REFERENCES Admin(MaNV)
);

-- Bảng TAI_XE (1-N với Admin)
CREATE TABLE TaiXe (
    MaTX NVARCHAR(20) PRIMARY KEY,
    TenTX NVARCHAR(50),
    SoDienThoai VARCHAR(15),
    DiaChi NVARCHAR(100),
    
    MaNV NVARCHAR(20), 
    FOREIGN KEY (MaNV) REFERENCES Admin(MaNV)
);

-- Bảng LICH_TRINH (1-N với Admin, KHÔNG CÓ MaTD)
CREATE TABLE LichTrinh (
    MaLT NVARCHAR(20) PRIMARY KEY,
	MaTX NVARCHAR(20) NOT NULL,
    CaLamViec NVARCHAR(20),
    GioXuatPhat DATETIME,
    GioKetThuc DATETIME,
    
    FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX)
);

-- Bảng XE_BUS (1-1 với TaiXe, 1-N với Admin)
CREATE TABLE XeBus (
    MaXE NVARCHAR(20) PRIMARY KEY,
    BienSo VARCHAR(20) UNIQUE,
    SoCho INT,
    TrangThai NVARCHAR(50),
    
    MaTX NVARCHAR(20) UNIQUE, -- FK 1-1
    FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX),

    MaNV NVARCHAR(20), -- FK 1-N từ Admin
    FOREIGN KEY (MaNV) REFERENCES Admin(MaNV)
);

-- Bảng PHU_HUYNH (1-N với Admin)
CREATE TABLE PhuHuynh (
    MaPH NVARCHAR(20) PRIMARY KEY,
    Ten NVARCHAR(50),
    CCCD VARCHAR(20) UNIQUE,
    SoDienThoai VARCHAR(15),
    DiaChi NVARCHAR(100),

    MaNV NVARCHAR(20), 
    FOREIGN KEY (MaNV) REFERENCES Admin(MaNV)
);

-- Bảng HOC_SINH (Tham chiếu PhuHuynh, XeBus, Admin)
CREATE TABLE HocSinh (
    MaHS NVARCHAR(20) PRIMARY KEY,
    Ten NVARCHAR(50),
    Lop NVARCHAR(20),
    SoDienThoai VARCHAR(15),
    DiaChi NVARCHAR(100),
    
    MaPH NVARCHAR(20), 
    FOREIGN KEY (MaPH) REFERENCES PhuHuynh(MaPH),
    
    MaXE NVARCHAR(20),
    FOREIGN KEY (MaXE) REFERENCES XeBus(MaXE),

    MaNV NVARCHAR(20), 
    FOREIGN KEY (MaNV) REFERENCES Admin(MaNV),

	MaTX NVARCHAR(20),
    FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX)
);

-- Bảng HANH_TRINH (1-N với Admin)
CREATE TABLE HanhTrinh (
    MaHT NVARCHAR(20) PRIMARY KEY,
    ThoiGianCapNhat DATETIME,
    ViTri NVARCHAR(100),
    
    MaXE NVARCHAR(20),
    FOREIGN KEY (MaXE) REFERENCES XeBus(MaXE),

    MaNV NVARCHAR(20), 
    FOREIGN KEY (MaNV) REFERENCES Admin(MaNV)
);

-- Bảng THONG_BAO (1-N với Admin)
CREATE TABLE ThongBao (
    MaTB NVARCHAR(20) PRIMARY KEY,
    NoiDung NVARCHAR(255),
    ThoiGianGui DATETIME,
    
    MaNV NVARCHAR(20), 
    FOREIGN KEY (MaNV) REFERENCES Admin(MaNV)
);

-- =========================================================================
-- 2. TẠO BẢNG BÁO CÁO TÌNH TRẠNG và CẢNH BÁO SỰ CỐ để lưu dữ liệu
-- =========================================================================
CREATE TABLE BaoCao (
    MaBC INT IDENTITY(1,1) PRIMARY KEY,
    NoiDung NVARCHAR(255),
    ThoiGian DATETIME DEFAULT GETDATE(),

    MaTX NVARCHAR(20), -- Người gửi là tài xế
    FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX)
);

CREATE TABLE CanhBao (
    MaCB INT IDENTITY(1,1) PRIMARY KEY,
    NoiDung NVARCHAR(255),
    ThoiGian DATETIME DEFAULT GETDATE(),

    MaTX NVARCHAR(20), -- Người gửi là tài xế
    FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX)
);

-- =========================================================================
-- 3. TẠO CÁC BẢNG TRUNG GIAN (CHO QUAN HỆ N-N)
-- =========================================================================

-- N-N: TUYEN_DUONG và LICH_TRINH
CREATE TABLE TuyenDuong_LichTrinh (
    MaTD NVARCHAR(20),
    MaLT NVARCHAR(20),
    PRIMARY KEY (MaTD, MaLT), 
    FOREIGN KEY (MaTD) REFERENCES TuyenDuong(MaTD),
    FOREIGN KEY (MaLT) REFERENCES LichTrinh(MaLT)
);

-- N-N: XeBus và Lịch Trình
CREATE TABLE XeBus_LichTrinh (
    MaXE NVARCHAR(20),
    MaLT NVARCHAR(20),
    PRIMARY KEY (MaXE, MaLT), 
    FOREIGN KEY (MaXE) REFERENCES XeBus(MaXE),
    FOREIGN KEY (MaLT) REFERENCES LichTrinh(MaLT)
);

-- N-N: Lịch Trình và Tài Xế
CREATE TABLE LichTrinh_TaiXe (
    MaLT NVARCHAR(20),
    MaTX NVARCHAR(20),
    PRIMARY KEY (MaLT, MaTX),
    FOREIGN KEY (MaLT) REFERENCES LichTrinh(MaLT),
    FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX)
);

-- N-N: Tài Xế và Thông Báo
CREATE TABLE TaiXe_ThongBao (
    MaTX NVARCHAR(20),
    MaTB NVARCHAR(20),
    PRIMARY KEY (MaTX, MaTB),
    FOREIGN KEY (MaTX) REFERENCES TaiXe(MaTX),
    FOREIGN KEY (MaTB) REFERENCES ThongBao(MaTB)
);

-- N-N: Thông Báo và Phụ Huynh
CREATE TABLE ThongBao_PhuHuynh (
    MaTB NVARCHAR(20),
    MaPH NVARCHAR(20),
    PRIMARY KEY (MaTB, MaPH),
    FOREIGN KEY (MaTB) REFERENCES ThongBao(MaTB),
    FOREIGN KEY (MaPH) REFERENCES PhuHuynh(MaPH)
);


-- =========================================================================
-- 4. CHÈN DỮ LIỆU MẪU (Đã sửa lỗi GETDATE() -> NOW())
-- =========================================================================

-- 4.1. CHÈN ADMIN
INSERT INTO Admin (MaNV, Ten, SoDienThoai, DiaChi)
VALUES 
('AD01', N'Nguyễn Văn A', '0901234567', N'123 Đường ABC, Quận 1, TP.HCM'),
('AD02', N'Trần Thị B', '0919876543', N'456 Lê Lợi, Quận 3, TP.HCM'); 

-- 4.2. CHÈN TÀI XẾ (Gán MaNV)
INSERT INTO TaiXe (MaTX, TenTX, SoDienThoai, DiaChi, MaNV)
VALUES 
('TX01', N'Phạm Văn Tài', '0912000100', N'1A An Dương Vương, Q5', 'AD01'),
('TX02', N'Hoàng Thị Xế', '0912000101', N'2B CMT8, Q3', 'AD02'),
('TX03', N'Trần Minh Lái', '0912000102', N'3C Lê Lợi, Q1', 'AD01');

-- 4.3. CHÈN TUYẾN ĐƯỜNG (Gán MaNV)
INSERT INTO TuyenDuong (MaTD, Ten, DiemBatDau, DiemKetThuc, MaNV)
VALUES 
('TD01', N'Tuyến Bắc', N'Trường THPT X', N'Khu dân cư A', 'AD01'),
('TD02', N'Tuyến Nam', N'Trường THPT X', N'Khu dân cư B', 'AD02');

-- 4.4. CHÈN LỊCH TRÌNH (Gán MaNV) 
INSERT INTO LichTrinh (MaLT, MaTX, CaLamViec, GioXuatPhat, GioKetThuc )
VALUES
('LT01', 'TX01', N'Sáng', '2025-10-10 06:30:00', '2025-10-10 07:15:00'),
('LT02', 'TX02', N'Chiều', '2025-10-10 17:45:00', '2025-10-10 07:30:00'),
('LT03', 'TX03', N'Sáng', '2025-10-11 06:30:00', '2025-10-11 07:15:00');

-- 4.5. CHÈN N-N: TUYEN_DUONG_LICHTRINH
INSERT INTO TuyenDuong_LichTrinh (MaTD, MaLT)
VALUES
('TD01', 'LT01'), 
('TD01', 'LT02'), 
('TD02', 'LT01'); 

-- 4.6. CHÈN XE BUS (1-1 với Tài Xế, Gán MaNV)
INSERT INTO XeBus (MaXE, BienSo, SoCho, TrangThai, MaTX, MaNV)
VALUES 
('XEBUS01', '51B-100.01', 45, N'Đang hoạt động', 'TX01', 'AD01'), 
('XEBUS02', '51B-100.02', 45, N'Đang hoạt động', 'TX02', 'AD02'),
('XEBUS03', '51B-100.03', 45, N'Đang hoạt động', 'TX03', 'AD01');

-- 4.7. CHÈN PHỤ HUYNH (Gán MaNV)
INSERT INTO PhuHuynh (MaPH, Ten, CCCD, SoDienThoai, DiaChi, MaNV)
VALUES
('PH01', N'Nguyễn Thị Lành', '123456789010', '0901111001', N'Tổ 01, Phường A', 'AD01'),
('PH02', N'Trần Văn Đức', '123456789011', '0901111002', N'Tổ 02, Phường B', 'AD01'),
('PH03', N'Lê Thị Hương', '123456789012', '0901111003', N'Tổ 03, Phường C', 'AD01'),
('PH04', N'Phạm Văn Cường', '123456789013', '0901111004', N'Tổ 04, Phường D', 'AD01'),
('PH05', N'Võ Thị Mai', '123456789014', '0901111005', N'Tổ 05, Phường E', 'AD01'),
('PH06', N'Đỗ Văn Quyết', '123456789015', '0901111006', N'Tổ 06, Phường A', 'AD01'),
('PH07', N'Hoàng Thị Thơm', '123456789016', '0901111007', N'Tổ 07, Phường B', 'AD01'),
('PH08', N'Bùi Văn Tùng', '123456789017', '0901111008', N'Tổ 08, Phường C', 'AD01'),
('PH09', N'Nguyễn Thị Hồng', '123456789018', '0901111009', N'Tổ 09, Phường D', 'AD01'),
('PH10', N'Trần Văn Phát', '123456789019', '0901111010', N'Tổ 10, Phường E', 'AD01'),
('PH11', N'Lê Văn Sang', '123456789020', '0901111011', N'Tổ 11, Phường A', 'AD02'),
('PH12', N'Phạm Thị Yến', '123456789021', '0901111012', N'Tổ 12, Phường B', 'AD02'),
('PH13', N'Võ Văn Hùng', '123456789022', '0901111013', N'Tổ 13, Phường C', 'AD02'),
('PH14', N'Đỗ Thị Thúy', '123456789023', '0901111014', N'Tổ 14, Phường D', 'AD02'),
('PH15', N'Hoàng Văn Nam', '123456789024', '0901111015', N'Tổ 15, Phường E', 'AD02'),
('PH16', N'Bùi Thị Liễu', '123456789025', '0901111016', N'Tổ 16, Phường A', 'AD02'),
('PH17', N'Nguyễn Văn Trọng', '123456789026', '0901111017', N'Tổ 17, Phường B', 'AD02'),
('PH18', N'Trần Thị Nga', '123456789027', '0901111018', N'Tổ 18, Phường C', 'AD02'),
('PH19', N'Lê Văn Phúc', '123456789028', '0901111019', N'Tổ 19, Phường D', 'AD02'),
('PH20', N'Phạm Thị Duyên', '123456789029', '0901111020', N'Tổ 20, Phường E', 'AD02');

-- 4.8. CHÈN HỌC SINH (30 bản ghi - Gán MaNV) 
INSERT INTO HocSinh (MaHS, Ten, Lop, SoDienThoai, DiaChi, MaPH, MaXE, MaNV, MaTX) 
VALUES 
-- Xe Bus 01 (AD01 quản lý)
('HS001', N'Nguyễn Tùng Lâm', N'10A1', '0900000001', N'ĐC HS 01', 'PH01', 'XEBUS01', 'AD01', 'TX01'), ('HS002', N'Nguyễn Gia Khánh', N'10A1', '0900000002', 'ĐC HS 02', 'PH01', 'XEBUS01', 'AD01', 'TX01'),
('HS003', N'Trần Mai Trang', N'10A1', '0900000003', 'ĐC HS 03', 'PH02', 'XEBUS01', 'AD01', 'TX01'), ('HS004', N'Trần Nhật Minh', N'10A1', '0900000004', 'ĐC HS 04', 'PH02', 'XEBUS01', 'AD01', 'TX01'),
('HS005', N'Lê Thu Hà', N'10A2', '0900000005', 'ĐC HS 05', 'PH03', 'XEBUS01', 'AD01', 'TX01'), ('HS006', N'Lê Bảo Nam', N'10A2', '0900000006', 'ĐC HS 06', 'PH03', 'XEBUS01', 'AD01', 'TX01'),
('HS007', N'Phạm Thị Kim', N'10A2', '0900000007', 'ĐC HS 07', 'PH04', 'XEBUS01', 'AD01', 'TX01'), ('HS008', N'Phạm Khánh Bùi', N'10A2', '0900000008', 'ĐC HS 08', 'PH04', 'XEBUS01', 'AD01', 'TX01'),
('HS009', N'Võ Ngọc Trân', N'11B1', '0900000009', 'ĐC HS 09', 'PH05', 'XEBUS01', 'AD01', 'TX01'), ('HS010', N'Võ Đình Phú', N'11B1', '0900000010', 'ĐC HS 10', 'PH05', 'XEBUS01', 'AD01', 'TX01'),

-- Xe Bus 02 (AD02 quản lý)
('HS011', N'Đỗ Thanh Hải', N'11B1', '0900000011', N'ĐC HS 11', 'PH06', 'XEBUS02', 'AD02', 'TX02'), ('HS012', N'Đỗ Nguyệt Ánh', N'11B1', '0900000012', 'ĐC HS 12', 'PH06', 'XEBUS02', 'AD02', 'TX02'),
('HS013', N'Hoàng Tuấn Kiệt', N'11B2', '0900000013', 'ĐC HS 13', 'PH07', 'XEBUS02', 'AD02', 'TX02'), ('HS014', N'Hoàng Trọng Nhân', N'11B2', '0900000014', 'ĐC HS 14', 'PH07', 'XEBUS02', 'AD02', 'TX02'),
('HS015', N'Bùi Đông Xuân', N'11B2', '0900000015', 'ĐC HS 15', 'PH08', 'XEBUS02', 'AD02', 'TX02'), ('HS016', N'Bùi Sơn Tùng', N'11B2', '0900000016', 'ĐC HS 16', 'PH08', 'XEBUS02', 'AD02', 'TX02'),
('HS017', N'Nguyễn Yến Nhi', N'12C1', '0900000017', 'ĐC HS 17', 'PH09', 'XEBUS02', 'AD02', 'TX02'), ('HS018', N'Nguyễn Thị Hạnh', N'12C1', '0900000018', 'ĐC HS 18', 'PH09', 'XEBUS02', 'AD02', 'TX02'),
('HS019', N'Trần Ngọc Mỹ', N'12C1', '0900000019', 'ĐC HS 19', 'PH10', 'XEBUS02', 'AD02', 'TX02'), ('HS020', N'Trần Anh Khoa', N'12C1', '0900000020', 'ĐC HS 20', 'PH10', 'XEBUS02', 'AD02', 'TX02'),
-- Xe Bus 03 (AD01 quản lý)
('HS021', N'Lê Quang Long', N'12C2', '0900000021', N'ĐC HS 21', 'PH11', 'XEBUS03', 'AD01', 'TX03'), ('HS022', N'Phạm Hạnh Mai', N'12C2', '0900000022', 'ĐC HS 22', 'PH12', 'XEBUS03', 'AD01', 'TX03'),
('HS023', N'Võ Tùng Sơn', N'10A1', '0900000023', 'ĐC HS 23', 'PH13', 'XEBUS03', 'AD01', 'TX03'), ('HS024', N'Đỗ Minh Nguyệt', N'10A2', '0900000024', 'ĐC HS 24', 'PH14', 'XEBUS03', 'AD01', 'TX03'),
('HS025', N'Hoàng Văn Tín', N'11B1', '0900000025', 'ĐC HS 25', 'PH15', 'XEBUS03', 'AD01', 'TX03'), ('HS026', N'Bùi Thị Liên', N'11B2', '0900000026', 'ĐC HS 26', 'PH16', 'XEBUS03', 'AD01', 'TX03'),
('HS027', N'Nguyễn Trọng Phát', N'12C1', '0900000027', 'ĐC HS 27', 'PH17', 'XEBUS03', 'AD01', 'TX03'), ('HS028', N'Trần Văn Tiệp', N'12C2', '0900000028', 'ĐC HS 28', 'PH18', 'XEBUS03', 'AD01', 'TX03'),
('HS029', N'Lê Tùng Anh', N'10A1', '0900000029', 'ĐC HS 29', 'PH19', 'XEBUS03', 'AD01', 'TX03'), ('HS030', N'Phạm Thị Ngọc', N'10A2', '0900000030', 'ĐC HS 30', 'PH20', 'XEBUS03', 'AD01', 'TX03');

-- 4.9. CHÈN THÔNG BÁO (Gán MaNV)
INSERT INTO ThongBao (MaTB, NoiDung, ThoiGianGui, MaNV)
VALUES
('TB01', N'Xe Bus 01 đến trễ 15 phút do kẹt xe. Phụ huynh vui lòng chuẩn bị cho học sinh sau 07:45.', '2025-10-10 07:30:00', 'AD01'),
('TB02', N'Tài xế Xe Bus 03 (Trần Minh Lái) bị ốm. Xe sẽ được thay bằng tài xế dự phòng. Xin lỗi vì sự bất tiện.', '2025-10-10 06:00:00', 'AD02'),
('TB03', N'Xe Bus 02 đã đón học sinh và đang di chuyển về trường. Vui lòng kiểm tra ứng dụng để cập nhật vị trí.', '2025-10-10 07:05:00', 'AD02'),
('TB04', N'Thông báo lịch học bù ngày 15/10. Lịch trình đón và trả học sinh sẽ được điều chỉnh.', '2025-10-09 18:00:00', 'AD01');

-- 4.10. CHÈN HÀNH TRÌNH (Đã sửa lỗi GETDATE()(dùng trong SQL Sever) -> NOW()(My SQL)) 
INSERT INTO HanhTrinh (MaHT, ThoiGianCapNhat, ViTri, MaXE, MaNV)
VALUES
('HT001', GETDATE(), N'Gần ngã tư X, cách trường 2km', 'XEBUS01', 'AD01'),
('HT002', DATEADD(MINUTE, -5, GETDATE()), N'Đang đón học sinh tại tổ 8', 'XEBUS02', 'AD02'),
('HT003', GETDATE(), N'Đang trên đường đến trường THPT X', 'XEBUS03', 'AD01');

-- 4.11. CHÈN CÁC BẢNG TRUNG GIAN N-N

-- N-N: XeBus và Lịch Trình
INSERT INTO XeBus_LichTrinh (MaXE, MaLT)
VALUES
('XEBUS01', 'LT01'), 
('XEBUS03', 'LT01'), 
('XEBUS02', 'LT02');

-- N-N: Lịch Trình và Tài Xế
INSERT INTO LichTrinh_TaiXe (MaLT, MaTX)
VALUES
('LT01', 'TX01'), 
('LT02', 'TX02'), 
('LT01', 'TX03');

-- N-N: Tài Xế gửi Thông Báo
INSERT INTO TaiXe_ThongBao (MaTX, MaTB)
VALUES
('TX01', 'TB01'), 
('TX03', 'TB02'), 
('TX02', 'TB03'), 
('TX01', 'TB04'); 

-- N-N: Thông Báo và Phụ Huynh
INSERT INTO ThongBao_PhuHuynh (MaTB, MaPH)
VALUES
('TB01', 'PH01'), ('TB01', 'PH02'), ('TB01', 'PH03'), ('TB01', 'PH04'), ('TB01', 'PH05');

INSERT INTO ThongBao_PhuHuynh (MaTB, MaPH)
SELECT 'TB04', MaPH FROM PhuHuynh; 

INSERT INTO ThongBao_PhuHuynh (MaTB, MaPH)
SELECT 'TB02', MaPH FROM PhuHuynh WHERE MaPH BETWEEN 'PH11' AND 'PH20'; 

INSERT INTO ThongBao_PhuHuynh (MaTB, MaPH)
VALUES
('TB03', 'PH06'), ('TB03', 'PH07'), ('TB03', 'PH08'), ('TB03', 'PH09'), ('TB03', 'PH10');

-- 4.12. CÁC LỆNH SELECT ĐỂ KIỂM TRA DỮ LIỆU
SELECT * FROM Admin;
SELECT * FROM TaiXe;
SELECT * FROM XeBus;
SELECT * FROM PhuHuynh;
SELECT * FROM HocSinh;
SELECT * FROM ThongBao;
SELECT * FROM TuyenDuong;
SELECT * FROM LichTrinh;
SELECT * FROM HanhTrinh;
SELECT * FROM TuyenDuong_LichTrinh; 
SELECT * FROM XeBus_LichTrinh;
SELECT * FROM LichTrinh_TaiXe;
SELECT * FROM TaiXe_ThongBao;
SELECT * FROM ThongBao_PhuHuynh;