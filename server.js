import express from "express";
import sql from "mssql";
import cors from "cors";

const app = express();
const port = 5000;

app.use(express.json());
app.use(cors());

// ⚙️ Cấu hình kết nối SQL Server
const config = {
  user: "sa",          // tài khoản SQL
  password: "123456",  // mật khẩu
  server: "DESKTOP-BDHLATA",  // tên máy chủ SQL Server
  database: "BUSMAP",  // tên database
  options: { trustServerCertificate: true }, // cho phép SQL local
  port: 1433,
};

// 🧩 Kết nối SQL Server
async function connectDB() {
  try {
    const pool = await sql.connect(config);
    console.log("✅ Kết nối SQL Server thành công!");
    return pool;
  } catch (err) {
    console.error("❌ Lỗi kết nối SQL Server:", err);
    throw err;
  }
}

// 🧠 Hàm truy vấn chung
const queryDB = async (query, res) => {
  try {
    const pool = await connectDB();
    const result = await pool.request().query(query);
    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Lỗi truy vấn:", err);
    res.status(500).json({ message: err.message });
  }
};

// 📋 API: Lấy danh sách tất cả bảng
app.get("/api/tables", (req, res) => {
  const query = `
    SELECT TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE'
  `;
  queryDB(query, res);
});

// 📚 Các bảng tạo API động
const tables = [
  "Admin", "TuyenDuong", "LichTrinh", "TaiXe", "XeBus",
  "PhuHuynh", "HocSinh", "HanhTrinh",
  "TuyenDuong_LichTrinh", "XeBus_LichTrinh", "LichTrinh_TaiXe",
  "TaiXe_ThongBao", "ThongBao_PhuHuynh"
];

tables.forEach((table) => {
  const route = `/api/${table.toLowerCase()}`;
  app.get(route, (req, res) => queryDB(`SELECT * FROM ${table}`, res));
});

// ✅ API riêng cho bảng Admin
app.get("/api/admin", (req, res) => {
  const query = `
    SELECT MaNV, Ten, SoDienThoai, DiaChi
    FROM Admin
  `;
  queryDB(query, res);
});

// ====== CRUD cho bảng ThongBao ======

// 🟢 Lấy toàn bộ thông báo
app.get("/api/thongbao", (req, res) => {
  const query = "SELECT * FROM ThongBao ORDER BY ThoiGianGui DESC";
  queryDB(query, res);
});

// 🟢 Thêm mới thông báo
app.post("/api/thongbao", async (req, res) => {
  const { MaTB, NoiDung, ThoiGianGui, MaNV } = req.body;
  if (!MaTB || !NoiDung || !ThoiGianGui || !MaNV) {
    return res.status(400).json({ message: "Thiếu dữ liệu bắt buộc." });
  }

  try {
    const pool = await connectDB();

    // Kiểm tra trùng mã
    const check = await pool.request()
      .input("MaTB", sql.VarChar, MaTB)
      .query("SELECT MaTB FROM ThongBao WHERE MaTB = @MaTB");

    if (check.recordset.length > 0) {
      return res.status(400).json({ message: "Mã thông báo đã tồn tại." });
    }

    await pool.request()
      .input("MaTB", sql.VarChar, MaTB)
      .input("NoiDung", sql.NVarChar, NoiDung)
      .input("ThoiGianGui", sql.DateTime, ThoiGianGui)
      .input("MaNV", sql.VarChar, MaNV)
      .query(
        "INSERT INTO ThongBao (MaTB, NoiDung, ThoiGianGui, MaNV) VALUES (@MaTB, @NoiDung, @ThoiGianGui, @MaNV)"
      );

    res.status(201).json({ message: "Thêm thông báo thành công." });
  } catch (err) {
    console.error("❌ Lỗi thêm thông báo:", err);
    res.status(500).json({ message: err.message });
  }
});

// 🟡 Cập nhật thông báo
app.put("/api/thongbao/:MaTB", async (req, res) => {
  const { MaTB } = req.params;
  const { NoiDung, ThoiGianGui, MaNV } = req.body;

  if (!NoiDung || !ThoiGianGui || !MaNV) {
    return res.status(400).json({ message: "Thiếu dữ liệu bắt buộc." });
  }

  try {
    const pool = await connectDB();
    const result = await pool.request()
      .input("MaTB", sql.VarChar, MaTB)
      .input("NoiDung", sql.NVarChar, NoiDung)
      .input("ThoiGianGui", sql.DateTime, ThoiGianGui)
      .input("MaNV", sql.VarChar, MaNV)
      .query(
        "UPDATE ThongBao SET NoiDung=@NoiDung, ThoiGianGui=@ThoiGianGui, MaNV=@MaNV WHERE MaTB=@MaTB"
      );

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ message: "Không tìm thấy thông báo." });
    }

    res.json({ message: "Cập nhật thông báo thành công." });
  } catch (err) {
    console.error("❌ Lỗi cập nhật thông báo:", err);
    res.status(500).json({ message: err.message });
  }
});

// 🔴 Xóa thông báo
app.delete("/api/thongbao/:MaTB", async (req, res) => {
  const { MaTB } = req.params;

  try {
    const pool = await connectDB();
    const result = await pool.request()
      .input("MaTB", sql.VarChar, MaTB)
      .query("DELETE FROM ThongBao WHERE MaTB = @MaTB");

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ message: "Không tìm thấy thông báo." });
    }

    res.json({ message: "Xóa thông báo thành công." });
  } catch (err) {
    console.error("❌ Lỗi xóa thông báo:", err);
    res.status(500).json({ message: err.message });
  }
});

// ====== BÁO CÁO & CẢNH BÁO ======

// 🟢 Lấy tất cả báo cáo tình trạng
app.get("/api/baocao", async (req, res) => {
  try {
    const pool = await connectDB();
    const result = await pool.request().query("SELECT * FROM BaoCao ORDER BY ThoiGian DESC");
    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Lỗi lấy báo cáo:", err);
    res.status(500).json({ message: err.message });
  }
});

// 🟢 Thêm báo cáo tình trạng
app.post("/api/baocao", async (req, res) => {
  const { NoiDung, MaTX } = req.body;
  if (!NoiDung || !MaTX) return res.status(400).json({ message: "Thiếu dữ liệu." });

  try {
    const pool = await connectDB();
    await pool.request()
      .input("NoiDung", sql.NVarChar, NoiDung)
      .input("MaTX", sql.VarChar, MaTX)
      .query("INSERT INTO BaoCao (NoiDung, MaTX) VALUES (@NoiDung, @MaTX)");
    res.json({ message: "🟩 Gửi báo cáo thành công!" });
  } catch (err) {
    console.error("❌ Lỗi thêm báo cáo:", err);
    res.status(500).json({ message: err.message });
  }
});

// 🟢 Lấy tất cả cảnh báo
app.get("/api/canhbao", async (req, res) => {
  try {
    const pool = await connectDB();
    const result = await pool.request().query("SELECT * FROM CanhBao ORDER BY ThoiGian DESC");
    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Lỗi lấy cảnh báo:", err);
    res.status(500).json({ message: err.message });
  }
});

// 🟢 Thêm cảnh báo
app.post("/api/canhbao", async (req, res) => {
  const { NoiDung, MaTX } = req.body;
  if (!NoiDung || !MaTX) return res.status(400).json({ message: "Thiếu dữ liệu." });

  try {
    const pool = await connectDB();
    await pool.request()
      .input("NoiDung", sql.NVarChar, NoiDung)
      .input("MaTX", sql.VarChar, MaTX)
      .query("INSERT INTO CanhBao (NoiDung, MaTX) VALUES (@NoiDung, @MaTX)");
    res.json({ message: "🟨 Gửi cảnh báo thành công!" });
  } catch (err) {
    console.error("❌ Lỗi thêm cảnh báo:", err);
    res.status(500).json({ message: err.message });
  }
});

// 🚀 Khởi động server
connectDB().then(() => {
  app.listen(port, () => console.log(`🚀 Server chạy tại http://localhost:${port}`));
});
