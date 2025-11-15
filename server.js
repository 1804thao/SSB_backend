import express from "express"; // framework tạo API server
import sql from "mssql";       // thư viện giúp kết nối và truy vấn SQL Server từ Node
import cors from "cors";       // bật Cross-Origin Resource Sharing, cho phép frontend (React) gọi API backend từ domain khác

const app = express();
const port = 5000;

app.use(express.json());
app.use(cors());

// ⚙️ Cấu hình SQL Server
const config = {
  user: "sa",
  password: "123456",
  server: "DESKTOP-BDHLATA",
  database: "BUSMAP",
  options: { trustServerCertificate: true },
  port: 1433,
};

// 🔗 Tạo pool kết nối toàn cục (tái sử dụng)
let poolPromise;
async function getPool() {
  if (!poolPromise) {
    poolPromise = sql.connect(config);
    console.log("✅ Kết nối SQL Server thành công!");
  }
  return poolPromise;
}

// 🧠 Hàm truy vấn chung
const queryDB = async (query, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(query);  // Dùng pool.request().query(query) để chạy SQL
    res.json(result.recordset);                        // result.recordset chứa dữ liệu dạng mảng
  } catch (err) {
    console.error("❌ Lỗi truy vấn:", err);
    res.status(500).json({ message: err.message });
  }
};

// 📋 API: Danh sách bảng
app.get("/api/tables", (req, res) => {
  queryDB(
    `SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE'`,
    res
  );
});

// 📚 API động cho các bảng chính
const tables = [
  "Admin", "TuyenDuong", "LichTrinh", "TaiXe", "XeBus",
  "PhuHuynh", "HocSinh", "HanhTrinh",
  "TuyenDuong_LichTrinh", "XeBus_LichTrinh", "LichTrinh_TaiXe",
  "TaiXe_ThongBao", "ThongBao_PhuHuynh"
];
tables.forEach((table) => {
  app.get(`/api/${table.toLowerCase()}`, (req, res) => queryDB(`SELECT * FROM ${table}`, res));
});

// ====== CRUD Thông báo ======
app.get("/api/thongbao", async (req, res) => {
  queryDB("SELECT * FROM ThongBao ORDER BY ThoiGianGui DESC", res);   // Trả về toàn bộ thông báo, sắp xếp theo thời gian mới nhất
});

app.post("/api/thongbao", async (req, res) => {
  const { MaTB, NoiDung, ThoiGianGui, MaNV } = req.body;
  if (!MaTB || !NoiDung || !ThoiGianGui || !MaNV)
    return res.status(400).json({ message: "Thiếu dữ liệu bắt buộc." });  // Kiểm tra dữ liệu bắt buộc

  try {
    const pool = await getPool();
    await pool.request()
      .input("MaTB", sql.NVarChar, MaTB)
      .input("NoiDung", sql.NVarChar, NoiDung)
      .input("ThoiGianGui", sql.DateTime, ThoiGianGui)
      .input("MaNV", sql.VarChar, MaNV)
      .query(`INSERT INTO ThongBao (MaTB, NoiDung, ThoiGianGui, MaNV)
              VALUES (@MaTB, @NoiDung, @ThoiGianGui, @MaNV)`);

    res.status(201).json({ MaTB, NoiDung, ThoiGianGui, MaNV });
  } catch (err) {
    console.error("❌ Lỗi thêm thông báo:", err);
    res.status(500).json({ message: err.message });
  }
});

// ====== BÁO CÁO ======
app.get("/api/baocao", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query("SELECT * FROM BaoCao ORDER BY ThoiGian DESC"); // Lấy danh sách báo cáo, sắp xếp theo thời gian
    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Lỗi lấy báo cáo:", err);
    res.status(500).json({ message: err.message });
  }
});

app.post("/api/baocao", async (req, res) => {
  const { NoiDung, MaTX } = req.body; 
  if (!NoiDung || !MaTX)
    return res.status(400).json({ message: "Thiếu dữ liệu." });

  try {
    const pool = await getPool();
    const timeNow = new Date();     // Thêm báo cáo mới, lưu thời gian hiện tại

    const result = await pool.request()
      .input("NoiDung", sql.NVarChar, NoiDung)
      .input("MaTX", sql.NVarChar, MaTX)
      .input("ThoiGian", sql.DateTime, timeNow)
      .query(`INSERT INTO BaoCao (NoiDung, MaTX, ThoiGian)
              OUTPUT INSERTED.* VALUES (@NoiDung, @MaTX, @ThoiGian)`);  // OUTPUT INSERTED.* giúp trả lại dòng vừa thêm

    res.status(201).json(result.recordset[0]); // ✅ trả lại record mới
  } catch (err) {
    console.error("❌ Lỗi thêm báo cáo:", err);
    res.status(500).json({ message: err.message });
  }
});

// ====== CẢNH BÁO ======
app.get("/api/canhbao", async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query("SELECT * FROM CanhBao ORDER BY ThoiGian DESC");
    res.json(result.recordset);
  } catch (err) {
    console.error("❌ Lỗi lấy cảnh báo:", err);
    res.status(500).json({ message: err.message });
  }
});

app.post("/api/canhbao", async (req, res) => {
  const { NoiDung, MaTX } = req.body; 
  if (!NoiDung || !MaTX)
    return res.status(400).json({ message: "Thiếu dữ liệu." });

  try {
    const pool = await getPool();
    const timeNow = new Date();

    const result = await pool.request()
      .input("NoiDung", sql.NVarChar, NoiDung)
      .input("MaTX", sql.NVarChar, MaTX)
      .input("ThoiGian", sql.DateTime, timeNow)
      .query(`INSERT INTO CanhBao (NoiDung, MaTX, ThoiGian)
              OUTPUT INSERTED.* VALUES (@NoiDung, @MaTX, @ThoiGian)`);

    res.status(201).json(result.recordset[0]); // ✅ trả lại record mới
  } catch (err) {
    console.error("❌ Lỗi thêm cảnh báo:", err);
    res.status(500).json({ message: err.message });
  }
});

// 🗑️ XÓA BÁO CÁO THEO MaBC (SQL Server chuẩn)
app.delete("/api/baocao/:MaBC", async (req, res) => {
  const { MaBC } = req.params;

  try {
    const pool = await getPool(); // Lấy pool kết nối
    const result = await pool.request()
      .input("MaBC", sql.NVarChar, MaBC)
      .query("DELETE FROM BaoCao WHERE MaBC = @MaBC");

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ message: "Không tìm thấy báo cáo để xóa!" });
    }

    res.json({ message: "✅ Xóa báo cáo thành công!" });
  } catch (error) {
    console.error("❌ Lỗi khi xóa báo cáo:", error);
    res.status(500).json({ error: "Lỗi khi xóa báo cáo!" });
  }
});

// 🗑️ XÓA CẢNH BÁO THEO MaCB (SQL Server chuẩn)
app.delete("/api/canhbao/:MaCB", async (req, res) => {
  const { MaCB } = req.params;

  try {
    const pool = await getPool();
    const result = await pool.request()
      .input("MaCB", sql.NVarChar, MaCB)
      .query("DELETE FROM CanhBao WHERE MaCB = @MaCB");

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ message: "Không tìm thấy cảnh báo để xóa!" });
    }

    res.json({ message: "✅ Xóa cảnh báo thành công!" });
  } catch (error) {
    console.error("❌ Lỗi khi xóa cảnh báo:", error);
    res.status(500).json({ error: "Lỗi khi xóa cảnh báo!" });
  }
});

// 🚀 Khởi động server
getPool().then(() => {          // Gọi getPool() để đảm bảo SQL đã kết nối xong
  app.listen(port, () => console.log(`🚀 Server chạy tại http://localhost:${port}`));
});
