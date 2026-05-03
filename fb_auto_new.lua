-- ================================================================
--  FACEBOOK AUTOMATION SCRIPT + GUI MENU + NẠP NICK
--  ✅ GUI bật/tắt chức năng bằng dialogChoice
--  ✅ Nhập thông số qua dialogInput
--  ✅ Lưu/Tải cấu hình tự động
--  ✅ Nạp Nick (đăng nhập + 2FA) chạy riêng biệt
--  ✅ Thêm nick qua GUI (từng cái / dán nhiều)
--  ⚠️ Logic gốc KHÔNG THAY ĐỔI
-- ================================================================

-- Tương thích Lua 5.1 / 5.3+
local unpack = unpack or table.unpack

-- ========== CẤU HÌNH AUTO-UPDATE ==========
VERSION_HIEN_TAI = 1.1  -- Phiên bản hiện tại trên máy khách
URL_CHECK_VERSION = "https://raw.githubusercontent.com/mokhoafb930-lang/fb-tool/refs/heads/main/version.txt"  -- Link check version mới nhất
URL_DOWNLOAD_CODE = "https://raw.githubusercontent.com/mokhoafb930-lang/fb-tool/refs/heads/main/fb_auto_new.lua"  -- Link tải code mới nhất

function kiemTraCapNhat()
    if not httpGet then return end
    
    local success, content = pcall(function()
        return httpGet(URL_CHECK_VERSION .. "?t=" .. os.time())
    end)
    
    if success and content then
        local versionMoi = tonumber(content:match("^%s*(.-)%s*$"))
        if versionMoi and versionMoi > VERSION_HIEN_TAI then
            toast("🆕 Phát hiện bản mới: " .. versionMoi .. "! Đang tải...", 3)
            
            local dl_success, newCode = pcall(function()
                return httpGet(URL_DOWNLOAD_CODE .. "?t=" .. os.time())
            end)
            
            if dl_success and newCode and #newCode > 100 then
                toast("💾 Đang ghi file mới vào máy...")
                local pathFile = "/var/mobile/Documents/fb_auto_new.lua"
                local f = io.open(pathFile, "w")
                if f then
                    f:write(newCode)
                    f:close()
                    toast("✅ Đã cập nhật lên bản " .. versionMoi .. "! Đang tải lại tool...")
                    sleep(2)
                    if stop then stop() elseif luaExit then luaExit() end
                end
            else
                toast("❌ Tải file thất bại hoặc file quá nhỏ!", 3)
                log("❌ Tải file thất bại hoặc file quá nhỏ! Độ dài: " .. tostring(newCode and #newCode or 0))
            end
        end
    end
end

-- Chạy kiểm tra cập nhật ngầm ngay khi mở file
kiemTraCapNhat()

-- ========== CÀI ĐẶT MẶC ĐỊNH (FARM) ==========
local SO_LAN_LAP = 2
local THOI_GIAN_NGHI = 10
local NICK_BAT_DAU = 1 -- Số thứ tự nick bắt đầu

-- ========== CẤU HÌNH CRANE (TỰ ĐỘNG) ==========
local function getCranePath()
    local paths = {"/usr/bin/cranectl", "/var/jb/usr/bin/cranectl", "/usr/local/bin/cranectl"}
    for _, p in ipairs(paths) do
        local f = io.open(p, "r")
        if f then f:close() return p end
    end
    return "cranectl"
end
local CRANE_PATH = getCranePath()

local function layDanhSachCrane()
    local tmpFile = "/var/mobile/Documents/crane_list_auto.txt"
    os.execute(string.format("%s --list com.facebook.Facebook > %s 2>&1", CRANE_PATH, tmpFile))
    local list = {}
    local f = io.open(tmpFile, "r")
    if f then
        for line in f:lines() do
            local name = line:match("^%s*%*?%s*(.-)%s*%(") or line:match("^%s*%*?%s*(.-)%s*$")
            if name and name ~= "" and not name:find("Container") and not name:find(":") and not name:find("Active") then
                table.insert(list, (name:gsub("^%s*(.-)%s*$", "%1")))
            end
        end
        f:close()
    end
    return list
end

-- ========== ĐƯỜNG DẪN FILE NỘI DUNG (CHO KHÁCH TỰ CHỈNH) ==========
local CMT_FILE_PATH    = "/var/mobile/Documents/cmt_content.txt"
local POST_FILE_PATH   = "/var/mobile/Documents/post_content.txt"
local BIO_FILE_PATH    = "/var/mobile/Documents/bio_content.txt"
local CITY_FILE_PATH   = "/var/mobile/Documents/city_content.txt"
local WORK_FILE_PATH   = "/var/mobile/Documents/work_content.txt"
local SCHOOL_FILE_PATH = "/var/mobile/Documents/school_content.txt"
local RELA_FILE_PATH   = "/var/mobile/Documents/rela_content.txt"

-- ========== ĐƯỜNG DẪN FILE HỆ THỐNG ==========
local ACCOUNT_FILE     = "/var/mobile/Documents/nick.txt"
local THONG_KE_FILE    = "/var/mobile/Documents/thongke.txt"
local UID_FRIEND_FILE  = "/var/mobile/Documents/uid_friend.txt"
local UID_LOG_FILE     = "/var/mobile/Documents/uid_ket_ban_log.txt"
local CONFIG_PATH      = "/var/mobile/Documents/fb_auto_config.txt"
local FILE_LOG_LL      = "/var/mobile/Documents/schedule_log.txt"
local CONFIG_FILE_LL   = "/var/mobile/Documents/schedule_config.txt"
local TERMS_FILE      = "/var/mobile/Documents/terms_accepted.txt"

-- ========== HÀM ĐỌC NỘI DUNG TỪ FILE TXT ==========
local function readLinesFromFile(path, defaultTable)
    local f = io.open(path, "r")
    if not f then
        -- Nếu không có file, tự tạo file mẫu từ table mặc định
        local fw = io.open(path, "w")
        if fw then
            for _, line in ipairs(defaultTable) do
                fw:write(line .. "\n")
            end
            fw:close()
        end
        return defaultTable
    end
    
    local lines = {}
    for line in f:lines() do
        local s = line:match("^%s*(.-)%s*$")
        if s and s ~= "" then
            table.insert(lines, s)
        end
    end
    f:close()
    
    if #lines == 0 then return defaultTable end
    return lines
end

-- ========== HÀM TẠO TẤT CẢ FILE NỘI DUNG MẪU ==========
local function taoTatCaFileNoiDung()
    -- 1. Tạo các file nội dung có dữ liệu mẫu (dùng hàm readLinesFromFile)
    readLinesFromFile(CMT_FILE_PATH, CMT_LIST)
    readLinesFromFile(POST_FILE_PATH, NOI_DUNG_BAI_VIET)
    readLinesFromFile(BIO_FILE_PATH, TIEU_SU_RANDOM)
    readLinesFromFile(CITY_FILE_PATH, DANH_SACH_THANH_PHO)
    readLinesFromFile(WORK_FILE_PATH, DANH_SACH_CONG_VIEC)
    readLinesFromFile(SCHOOL_FILE_PATH, DANH_SACH_TRUONG)
    readLinesFromFile(RELA_FILE_PATH, DANH_SACH_RELATIONSHIP)
    
    -- 2. Tạo các file hệ thống khác (file trống hoặc file config) nếu chưa có
    local systemFiles = {
        ACCOUNT_FILE, 
        UID_FRIEND_FILE, 
        THONG_KE_FILE, 
        UID_LOG_FILE, 
        FILE_LOG_LL,
        CONFIG_PATH,
        CONFIG_FILE_LL
    }
    
    for _, path in ipairs(systemFiles) do
        local f = io.open(path, "r")
        if not f then
            local fw = io.open(path, "w")
            if fw then 
                -- Nếu là file config, ta gọi hàm lưu có sẵn để tạo nội dung mặc định chuẩn
                fw:close()
                if path == CONFIG_PATH then luuCauHinh() end
                if path == CONFIG_FILE_LL then luuCauHinhLapLich() end
            end
        else
            f:close()
        end
    end
    
    toast("✅ Đã tạo TOÀN BỘ file hệ thống & nội dung!")
    dialogChoice("✅ Đã tạo TOÀN BỘ file cần thiết!\n\nToàn bộ file .txt đã được tạo tại thư mục Documents. Khách có thể vào đó để dán Nick, UID hoặc chỉnh sửa nội dung bài đăng.", "Xong ✅")
end

-- ========== HÀM XÓA TẤT CẢ FILE ==========
local function xoaTatCaFile()
    local confirm = dialogChoice("⚠️ CẢNH BÁO XÓA FILE\n\nHành động này sẽ xóa sạch các file .txt trong Documents để bạn thiết lập lại từ đầu. Bạn có chắc không?", "🔥 Có, xóa hết!", "◀️ Quay lại")
    if confirm and confirm:find("xóa hết") then
        local allFiles = {
            {CMT_FILE_PATH, "Nội dung CMT"},
            {POST_FILE_PATH, "Nội dung bài đăng"},
            {BIO_FILE_PATH, "Tiểu sử"},
            {CITY_FILE_PATH, "Thành phố"},
            {WORK_FILE_PATH, "Công việc"},
            {SCHOOL_FILE_PATH, "Trường học"},
            {RELA_FILE_PATH, "Hôn nhân"},
            {ACCOUNT_FILE, "File Nick"},
            {UID_FRIEND_FILE, "File UID"},
            {THONG_KE_FILE, "Thống kê nạp nick"},
            {UID_LOG_FILE, "Log kết bạn UID"},
            {FILE_LOG_LL, "Log lập lịch"},
            {CONFIG_PATH, "Cấu hình chính"},
            {CONFIG_FILE_LL, "Cấu hình lập lịch"}
        }
        
        local count = 0
        for _, item in ipairs(allFiles) do
            local path = item[1]
            local name = item[2]
            local success, err = os.remove(path)
            if success then
                logScreen("🗑️ Đã xóa: " .. name, true)
                count = count + 1
                sleep(0.1)
            else
                log("⚠️ Không thể xóa (hoặc file không tồn tại): " .. name)
            end
        end
        
        toast("🗑️ Đã xóa sạch " .. count .. " file!")
        dialogChoice("🗑️ Đã xóa sạch " .. count .. " file hệ thống!\nBạn có thể ấn nút 'Tạo file' để kiểm tra lại.", "OK ✅")
    end
end

-- ========== KIỂM TRA ĐIỀU KHOẢN SỬ DỤNG ==========
local function kiemTraDieuKhoan()
    local f = io.open(TERMS_FILE, "r")
    if f then
        f:close()
        return true 
    end
    
    local msg = "📜 CHÍNH SÁCH & QUY ĐỊNH SỬ DỤNG\n"
        .. "──────────────────────\n"
        .. "1. TRÁCH NHIỆM NGƯỜI DÙNG:\n"
        .. "· Người dùng chịu hoàn toàn trách nhiệm pháp lý về mọi hành vi, nội dung, thao tác khi sử dụng.\n"
        .. "· Script chỉ chạy theo LỆNH từ nội dung và thông số do người dùng nhập.\n\n"
        .. "2. MỤC ĐÍCH SỬ DỤNG:\n"
        .. "· Chỉ sử dụng cho mục đích: SEO, PR, MKT, kiểm thử ứng dụng... hợp pháp.\n"
        .. "· NGHIÊM CẤM: Phát tán mã độc, gian lận, lừa đảo, tấn công mạng, seeding vi phạm pháp luật.\n\n"
        .. "3. PHÁP LÝ & HỖ TRỢ:\n"
        .. "· Người dùng tự chịu trách nhiệm trước pháp luật khi cơ quan chức năng yêu cầu.\n"
        .. "· ADMIN có quyền TỐ GIÁC, hỗ trợ truy vết cùng cơ quan chức năng nếu người dùng PHẠM PHÁP.\n\n"
        .. "⚠️ Bằng cách ấn 'ĐỒNG Ý', bạn xác nhận đã đọc và chấp nhận toàn bộ điều khoản trên để vào Tool."
    
    local choice = dialogChoice(msg, "ĐỒNG Ý & VÀO TOOL ✅", "THOÁT ❌")
    if choice == "ĐỒNG Ý & VÀO TOOL ✅" then
        local fw = io.open(TERMS_FILE, "w")
        if fw then
            fw:write("accepted_at=" .. os.date("%Y-%m-%d %H:%M:%S"))
            fw:close()
        end
        return true
    else
        toast("Bạn cần chấp nhận điều khoản để sử dụng!")
        stop()
    end
end

local BAT_AVATAR = 0
local BAT_ANH_BIA = 0
local BAT_DANG_BAI = 1
local BAT_DANG_STORY = 0
local BAT_LUOT_NEWSFEED = 0
local BAT_EDIT_PROFILE = 1

local SO_LAN_LUOT = 10
local THOI_GIAN_LUOT = 2

-- ========== LOG MÀN HÌNH (QUAN TRỌNG) ==========
local function logScreen(msg, quanTrong)
    if quanTrong then
        toast(msg, 2, 0, 0, 14)
        log("📢 [Screen] " .. msg)
    else
        log("🔹 " .. msg)
    end
end

-- ========== HÀM NGHỈ CÓ THÔNG BÁO (ĐẾM NGƯỢC) ==========
local function nghi(giay, tinNhan)
    log("⏳ " .. tinNhan .. " (" .. giay .. "s)")
    if giay <= 3 then
        logScreen("⏳ " .. tinNhan .. " (" .. giay .. "s)", true)
        sleep(giay)
    else
        for i = giay, 1, -1 do
            -- Chỉ hiện log màn hình mỗi 5 giây hoặc khi còn 3 giây cuối để tránh "log liên tục"
            if i == giay or i % 5 == 0 or i <= 3 then
                logScreen("⏳ " .. tinNhan .. " (" .. i .. "s)", true)
            end
            sleep(1)
        end
    end
end

-- ========== HÀM LẤY IP HIỆN TẠI ==========
local function getIP()
    local success, content = pcall(function()
        return httpGet("http://api.ipify.org")
    end)
    if success and content then
        -- Loại bỏ khoảng trắng hoặc ký tự xuống dòng
        return content:match("^%s*(.-)%s*$")
    end
    return "Không xác định"
end

-- ================================================================

-- ========== RESET MẠNG ==========
local function resetMang()
    while true do
        log("📡 Đang thực hiện Reset mạng (Cú pháp: true, 3)...")
        -- Dùng cú pháp bạn cung cấp: Bật 3 giây rồi tự tắt
        setAirplaneMode(true, 3)
        
        nghi(12, "ĐANG ĐỢI MẠNG HỒI PHỤC")
        
        local newIP = "Không xác định"
        -- Thử lấy IP tối đa 6 lần (mỗi lần cách nhau 5s)
        for retry = 1, 6 do
            newIP = getIP()
            if newIP ~= "Không xác định" then break end
            logScreen("⏳ Đang chờ lấy IP mới (" .. (retry*5) .. "s)...", true)
            sleep(5)
        end
        
        if newIP ~= "Không xác định" then
            logScreen("✅ ĐỔI IP THÀNH CÔNG\n📡 IP Mới: " .. newIP, true)
            log("✅ IP mới: " .. newIP)
            sleep(2)
            break
        else
            logScreen("❌ KHÔNG LẤY ĐƯỢC IP, ĐANG RESET LẠI...", true)
            log("❌ Khong lay duoc IP, tien hanh reset mang lai tu dau...")
            sleep(2)
        end
    end
end

-- File lưu vị trí hiện tại của Crane
local CRANE_IDX_FILE = "/var/mobile/Documents/fb_current_idx.txt"

-- ========== CHUYỂN NICK (SMART CRANE) ==========
local function chuyenNick(tenPhanVung)
    local danhSach = layDanhSachCrane()
    if #danhSach == 0 then
        logScreen("❌ KHÔNG CÓ PHÂN VÙNG CRANE!", true)
        return false
    end

    local target = tenPhanVung
    if not target then
        -- Nếu không truyền tên, tự động lấy theo số thứ tự lưu trong file
        local f = io.open(CRANE_IDX_FILE, "r")
        local idx = 1
        if f then
            idx = tonumber(f:read("*all")) or 1
            f:close()
        end
        
        target = danhSach[((idx - 1) % #danhSach) + 1]
        
        -- Lưu lại vị trí tiếp theo
        local f2 = io.open(CRANE_IDX_FILE, "w")
        if f2 then
            f2:write(tostring(idx + 1))
            f2:close()
        end
    end

    logScreen("🔄 Crane: " .. target, true)
    local cmd = string.format("%s --switch com.facebook.Facebook name:\"%s\"", CRANE_PATH, target)
    os.execute(cmd)
    sleep(2)
    return true
end

-- ========== ĐÓNG FACEBOOK ==========
local function dongFacebook()
    appKill("com.facebook.Facebook")
    sleep(3)
end

-- ========== MỞ FACEBOOK ==========
local function moFacebook()
    logScreen("📱 Đang mở Facebook...", true)
    appRun("com.facebook.Facebook")
    nghi(10, "Đang đợi Facebook khởi động")
    
    -- Tap OK nếu có
    if findText("OK", 3) then
        tapText("OK", 5)
        sleep(2)
    end
    
    -- ========== REFRESH ĐỂ LOAD LẠI TRANG ==========
    swipe(200, 200, 200, 600, 0.5)
    sleep(3)
    
    -- ========== KIỂM TRA LỖI (QUÉT LẦN LƯỢT - DỪNG NGAY KHI TÌM THẤY) ==========
    sleep(2)
    
    local errorKeywords = {
        "Something Went Wrong",
        "Stories couldn't load",
        "Try Again",
    }
    
    for i, keyword in ipairs(errorKeywords) do
        if findText(keyword, 2) then
            logScreen("❌ LỖI FACEBOOK: " .. keyword, true)
            
            -- GỌI HÀM ĐÓNG FACEBOOK CÓ SẴN
            dongFacebook()
            
            return false
        end
    end
    
    logScreen("✅ FACEBOOK ĐÃ SẴN SÀNG", true)
    return true
end

-- ========== CÀI ĐẶT MẶC ĐỊNH (NẠP NICK) ==========
local SO_NICK_CAN_DANG_NHAP = 10

-- ========== CÀI ĐẶT MẶC ĐỊNH (KẾT BẠN UID) ==========
local THOI_GIAN_NGHI_UID = 15
local SO_NICK_UID = 2
local SO_UID_MOI_NICK = 5
local BAT_XOA_UID = 1

-- ========== CÀI ĐẶT MẶC ĐỊNH (KẾT BẠN GỢI Ý) ==========
local SO_LUONG_KB_GY = 20
local DELAY_KB_GY = 15
local MAX_LUOT_KB_GY = 5
local SO_NICK_KB_GY = 2

-- ========== CÀI ĐẶT MẶC ĐỊNH (CHẤP NHẬN KẾT BẠN) ==========
local SO_NICK_CNKB = 2
local DELAY_CNKB = 2
local MAX_LUOT_CNKB = 3

-- ========== CÀI ĐẶT MẶC ĐỊNH (TƯƠNG TÁC BÀI VIẾT) ==========
local INTERACT_URL = "https://www.facebook.com/permalink.php?story_fbid=122103504357267365&id=61588020967607&substory_index=1456270582960349"
local INTERACT_NICKS = 1
local INTERACT_RANDOM = 0
local INTERACT_LIKE = 0
local INTERACT_TYM = 0
local INTERACT_THUONG = 0
local INTERACT_HAHA = 0
local INTERACT_BUON = 1
local INTERACT_MAX_ATTEMPTS = 10
local INTERACT_SCROLL_DELAY = 2

-- ========== CÀI ĐẶT MẶC ĐỊNH (CMT BÀI VIẾT CHỈ ĐỊNH) ==========
local CMT_URL = ""
local CMT_SO_NICK = 1
local CMT_MODE = "random"        -- "random" hoặc "sequential"
local CMT_MAX_ATTEMPTS = 10
local CMT_MAX_RETRY_POST = 3
local CMT_SCROLL_DELAY = 2
local CMT_TAP_DELAY = 5
local CMT_CURRENT_INDEX = 1
local CMT_LIST = readLinesFromFile(CMT_FILE_PATH, {
    "Bài viết hay quá! ❤️",
    "Cảm ơn bạn đã chia sẻ! 🙏",
    "Tuyệt vời! 👍",
    "Mình rất thích bài này! 😍",
    "Ủng hộ bạn nè! 🚀",
    "Hay lắm ạ! 💯",
    "Có ích quá, cảm ơn! 📝",
    "Đọc xong thấy thú vị! ✨",
    "Chia sẻ hay quá! 🌟",
    "Mong bạn ra nhiều bài hơn nữa! 💪",
    "Nội dung chất lượng quá! 🔥",
    "Bài viết rất ý nghĩa! 💖",
    "Hữu ích thật sự luôn! 🙌",
    "Like mạnh cho bài này! 👍",
    "Quá tuyệt vời luôn! 🌈",
    "Bài viết đáng để đọc! 📚",
    "Xin cảm ơn vì thông tin hay! 🙏",
    "Đọc mà cuốn quá! 😍",
    "Bạn chia sẻ có tâm quá! ❤️",
    "Hay xuất sắc luôn! 💯",
    "Đúng cái mình đang cần! ✨",
    "Rất đáng tham khảo nha! 📌",
    "Thật sự quá hay luôn! 🔥",
    "Cảm ơn vì bài viết bổ ích! 🌟",
    "Chúc bạn luôn thành công! 🚀",
    "Mình học được nhiều điều! 📖",
    "Bài này đỉnh thật sự! 😎",
    "Nội dung rõ ràng dễ hiểu! 👍",
    "Quá xịn luôn bạn ơi! 💪",
    "Xem xong thấy thích quá! 😍",
    "Đã đọc và rất thích! ❤️",
    "Bạn đầu tư nội dung ghê! 🔥",
    "Quá hay quá chất lượng! 💯",
    "Mong chờ bài tiếp theo nha! 🌟",
    "Bài viết quá tuyệt hảo! ✨",
    "Ủng hộ dài dài luôn! 🚀",
    "Chia sẻ đúng lúc quá! 🙏",
    "Hay và ý nghĩa lắm ạ! 💖",
    "Nội dung đỉnh cao luôn! 😎",
    "Đọc xong mở mang nhiều! 📚",
    "Bài đăng quá chuyên nghiệp! 👍",
    "Thật lòng rất thích bài này! 😍",
    "Quá giá trị luôn nha! 💯",
    "Cảm ơn bạn nhiều lắm! ❤️",
    "Đọc phát là mê luôn! 🔥",
    "Bài viết quá chỉn chu! 🌟",
    "Like mạnh không cần nghĩ! 👍",
    "Quá cuốn hút luôn nha! ✨",
    "Đúng gu mình luôn! 😍",
    "Nội dung hay miễn bàn! 🚀",
    "Hay thật sự luôn đó! 💖",
    "Chất lượng khỏi bàn! 💯",
    "Mong bạn đăng thêm nhiều nhé! 📌",
    "Rất đáng để lan toả! 🌈",
    "Đọc xong thấy vui ghê! 😊",
    "Bài viết truyền cảm hứng quá! 🔥",
    "Quá tốt quá hay luôn! ❤️",
    "Ủng hộ hết mình nha! 💪",
    "Đỉnh của chóp luôn! 😎",
    "Bài đăng quá xuất sắc! 🌟",
    "Nội dung siêu hay luôn! ✨",
    "Cảm ơn bạn đã dành thời gian chia sẻ! 🙏",
    "Mình lưu lại để đọc thêm! 📚",
    "Rất thích cách bạn trình bày! 👍",
    "Hay quá đi mất! 😍",
    "Bài viết đáng đồng tiền bát gạo! 💯",
    "Thật sự quá có tâm! ❤️",
    "Mỗi lần đọc là học thêm được điều mới! 📖",
    "Nội dung cực kỳ giá trị! 🚀",
    "Xứng đáng 1 like lớn! 👍",
    "Bài viết tuyệt đỉnh luôn! 🔥"
})

-- ========== CÀI ĐẶT MẶC ĐỊNH (CHIA SẺ BÀI VIẾT CHỈ ĐỊNH) ==========
local SHARE_URL = ""
local SHARE_SO_NICK = 1
local SHARE_MAX_ATTEMPTS = 10
local SHARE_SCROLL_DELAY = 2
local SHARE_TAP_DELAY = 5
local SHARE_MAX_CHECK = 5

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  GUI MENU - BẬT/TẮT & LƯU CẤU HÌNH                        ║
-- ╚══════════════════════════════════════════════════════════════╝

local GUI_FEATURES = {
    {"🖼️ Avatar",         "BAT_AVATAR"},
    {"🖼️ Ảnh bìa",        "BAT_ANH_BIA"},
    {"📝 Đăng bài",        "BAT_DANG_BAI"},
    {"📸 Đăng Story",      "BAT_DANG_STORY"},
    {"📜 Lướt Newsfeed",   "BAT_LUOT_NEWSFEED"},
    {"✏️ Edit Profile",    "BAT_EDIT_PROFILE"},
}

local GUI_SETTINGS = {
    {"Số lần lặp",         "SO_LAN_LAP",     "lần"},
    {"Thời gian nghỉ",     "THOI_GIAN_NGHI", "giây"},
    {"Số lần lướt NF",     "SO_LAN_LUOT",    "lần"},
    {"TG giữa lần lướt",   "THOI_GIAN_LUOT", "giây"},
    {"Nick bắt đầu từ",    "NICK_BAT_DAU",   "STT"},
}

-- ========== HÀM ĐỌC/GHI GIÁ TRỊ BIẾN ==========
local function layGiaTri(ten)
    if ten == "BAT_AVATAR" then return BAT_AVATAR
    elseif ten == "BAT_ANH_BIA" then return BAT_ANH_BIA
    elseif ten == "BAT_DANG_BAI" then return BAT_DANG_BAI
    elseif ten == "BAT_DANG_STORY" then return BAT_DANG_STORY
    elseif ten == "BAT_LUOT_NEWSFEED" then return BAT_LUOT_NEWSFEED
    elseif ten == "BAT_EDIT_PROFILE" then return BAT_EDIT_PROFILE
    elseif ten == "SO_LAN_LAP" then return SO_LAN_LAP
    elseif ten == "THOI_GIAN_NGHI" then return THOI_GIAN_NGHI
    elseif ten == "SO_LAN_LUOT" then return SO_LAN_LUOT
    elseif ten == "THOI_GIAN_LUOT" then return THOI_GIAN_LUOT
    elseif ten == "SO_NICK_CAN_DANG_NHAP" then return SO_NICK_CAN_DANG_NHAP
    elseif ten == "SO_NICK_UID" then return SO_NICK_UID
    elseif ten == "SO_UID_MOI_NICK" then return SO_UID_MOI_NICK
    elseif ten == "BAT_XOA_UID" then return BAT_XOA_UID
    elseif ten == "SO_LUONG_KB_GY" then return SO_LUONG_KB_GY
    elseif ten == "DELAY_KB_GY" then return DELAY_KB_GY
    elseif ten == "MAX_LUOT_KB_GY" then return MAX_LUOT_KB_GY
    elseif ten == "SO_NICK_KB_GY" then return SO_NICK_KB_GY
    elseif ten == "SO_NICK_CNKB" then return SO_NICK_CNKB
    elseif ten == "DELAY_CNKB" then return DELAY_CNKB
    elseif ten == "MAX_LUOT_CNKB" then return MAX_LUOT_CNKB
    elseif ten == "INTERACT_NICKS" then return INTERACT_NICKS
    elseif ten == "INTERACT_RANDOM" then return INTERACT_RANDOM
    elseif ten == "INTERACT_LIKE" then return INTERACT_LIKE
    elseif ten == "INTERACT_TYM" then return INTERACT_TYM
    elseif ten == "INTERACT_THUONG" then return INTERACT_THUONG
    elseif ten == "INTERACT_HAHA" then return INTERACT_HAHA
    elseif ten == "INTERACT_BUON" then return INTERACT_BUON
    elseif ten == "INTERACT_MAX_ATTEMPTS" then return INTERACT_MAX_ATTEMPTS
    elseif ten == "INTERACT_SCROLL_DELAY" then return INTERACT_SCROLL_DELAY
    elseif ten == "CMT_SO_NICK" then return CMT_SO_NICK
    elseif ten == "CMT_MAX_ATTEMPTS" then return CMT_MAX_ATTEMPTS
    elseif ten == "CMT_SCROLL_DELAY" then return CMT_SCROLL_DELAY
    elseif ten == "SHARE_SO_NICK" then return SHARE_SO_NICK
    elseif ten == "SHARE_MAX_ATTEMPTS" then return SHARE_MAX_ATTEMPTS
    elseif ten == "SHARE_SCROLL_DELAY" then return SHARE_SCROLL_DELAY
    elseif ten == "SHARE_TAP_DELAY" then return SHARE_TAP_DELAY
    elseif ten == "SHARE_MAX_CHECK" then return SHARE_MAX_CHECK
    elseif ten == "NICK_BAT_DAU" then return NICK_BAT_DAU
    end
    return 0
end

local function ganGiaTri(ten, giaTri)
    if ten == "BAT_AVATAR" then BAT_AVATAR = giaTri
    elseif ten == "BAT_ANH_BIA" then BAT_ANH_BIA = giaTri
    elseif ten == "BAT_DANG_BAI" then BAT_DANG_BAI = giaTri
    elseif ten == "BAT_DANG_STORY" then BAT_DANG_STORY = giaTri
    elseif ten == "BAT_LUOT_NEWSFEED" then BAT_LUOT_NEWSFEED = giaTri
    elseif ten == "BAT_EDIT_PROFILE" then BAT_EDIT_PROFILE = giaTri
    elseif ten == "SO_LAN_LAP" then SO_LAN_LAP = giaTri
    elseif ten == "THOI_GIAN_NGHI" then THOI_GIAN_NGHI = giaTri
    elseif ten == "SO_LAN_LUOT" then SO_LAN_LUOT = giaTri
    elseif ten == "THOI_GIAN_LUOT" then THOI_GIAN_LUOT = giaTri
    elseif ten == "SO_NICK_CAN_DANG_NHAP" then SO_NICK_CAN_DANG_NHAP = giaTri
    elseif ten == "SO_NICK_UID" then SO_NICK_UID = giaTri
    elseif ten == "SO_UID_MOI_NICK" then SO_UID_MOI_NICK = giaTri
    elseif ten == "BAT_XOA_UID" then BAT_XOA_UID = giaTri
    elseif ten == "SO_LUONG_KB_GY" then SO_LUONG_KB_GY = giaTri
    elseif ten == "DELAY_KB_GY" then DELAY_KB_GY = giaTri
    elseif ten == "MAX_LUOT_KB_GY" then MAX_LUOT_KB_GY = giaTri
    elseif ten == "SO_NICK_KB_GY" then SO_NICK_KB_GY = giaTri
    elseif ten == "SO_NICK_CNKB" then SO_NICK_CNKB = giaTri
    elseif ten == "DELAY_CNKB" then DELAY_CNKB = giaTri
    elseif ten == "MAX_LUOT_CNKB" then MAX_LUOT_CNKB = giaTri
    elseif ten == "INTERACT_NICKS" then INTERACT_NICKS = giaTri
    elseif ten == "INTERACT_RANDOM" then INTERACT_RANDOM = giaTri
    elseif ten == "INTERACT_LIKE" then INTERACT_LIKE = giaTri
    elseif ten == "INTERACT_TYM" then INTERACT_TYM = giaTri
    elseif ten == "INTERACT_THUONG" then INTERACT_THUONG = giaTri
    elseif ten == "INTERACT_HAHA" then INTERACT_HAHA = giaTri
    elseif ten == "INTERACT_BUON" then INTERACT_BUON = giaTri
    elseif ten == "INTERACT_MAX_ATTEMPTS" then INTERACT_MAX_ATTEMPTS = giaTri
    elseif ten == "INTERACT_SCROLL_DELAY" then INTERACT_SCROLL_DELAY = giaTri
    elseif ten == "CMT_SO_NICK" then CMT_SO_NICK = giaTri
    elseif ten == "CMT_MAX_ATTEMPTS" then CMT_MAX_ATTEMPTS = giaTri
    elseif ten == "CMT_SCROLL_DELAY" then CMT_SCROLL_DELAY = giaTri
    elseif ten == "SHARE_SO_NICK" then SHARE_SO_NICK = giaTri
    elseif ten == "SHARE_MAX_ATTEMPTS" then SHARE_MAX_ATTEMPTS = giaTri
    elseif ten == "SHARE_SCROLL_DELAY" then SHARE_SCROLL_DELAY = giaTri
    elseif ten == "SHARE_TAP_DELAY" then SHARE_TAP_DELAY = giaTri
    elseif ten == "SHARE_MAX_CHECK" then SHARE_MAX_CHECK = giaTri
    elseif ten == "NICK_BAT_DAU" then NICK_BAT_DAU = giaTri
    end
end

-- ========== LƯƯ CẤU HÌNH RA FILE ==========
local function luuCauHinh()
    local f = io.open(CONFIG_PATH, "w")
    if not f then
        toast("❌ Không thể lưu file!")
        return false
    end
    for _, feat in ipairs(GUI_FEATURES) do
        f:write(feat[2] .. "=" .. tostring(layGiaTri(feat[2])) .. "\n")
    end
    for _, setting in ipairs(GUI_SETTINGS) do
        f:write(setting[2] .. "=" .. tostring(layGiaTri(setting[2])) .. "\n")
    end
    f:write("SO_NICK_CAN_DANG_NHAP=" .. tostring(SO_NICK_CAN_DANG_NHAP) .. "\n")
    f:write("SO_NICK_UID=" .. tostring(SO_NICK_UID) .. "\n")
    f:write("SO_UID_MOI_NICK=" .. tostring(SO_UID_MOI_NICK) .. "\n")
    f:write("BAT_XOA_UID=" .. tostring(BAT_XOA_UID) .. "\n")
    f:write("SO_LUONG_KB_GY=" .. tostring(SO_LUONG_KB_GY) .. "\n")
    f:write("DELAY_KB_GY=" .. tostring(DELAY_KB_GY) .. "\n")
    f:write("MAX_LUOT_KB_GY=" .. tostring(MAX_LUOT_KB_GY) .. "\n")
    f:write("SO_NICK_KB_GY=" .. tostring(SO_NICK_KB_GY) .. "\n")
    f:write("SO_NICK_CNKB=" .. tostring(SO_NICK_CNKB) .. "\n")
    f:write("DELAY_CNKB=" .. tostring(DELAY_CNKB) .. "\n")
    f:write("MAX_LUOT_CNKB=" .. tostring(MAX_LUOT_CNKB) .. "\n")
    f:write("INTERACT_URL=" .. INTERACT_URL .. "\n")
    f:write("INTERACT_NICKS=" .. tostring(INTERACT_NICKS) .. "\n")
    f:write("INTERACT_RANDOM=" .. tostring(INTERACT_RANDOM) .. "\n")
    f:write("INTERACT_LIKE=" .. tostring(INTERACT_LIKE) .. "\n")
    f:write("INTERACT_TYM=" .. tostring(INTERACT_TYM) .. "\n")
    f:write("INTERACT_THUONG=" .. tostring(INTERACT_THUONG) .. "\n")
    f:write("INTERACT_HAHA=" .. tostring(INTERACT_HAHA) .. "\n")
    f:write("INTERACT_BUON=" .. tostring(INTERACT_BUON) .. "\n")
    f:write("INTERACT_MAX_ATTEMPTS=" .. tostring(INTERACT_MAX_ATTEMPTS) .. "\n")
    f:write("INTERACT_SCROLL_DELAY=" .. tostring(INTERACT_SCROLL_DELAY) .. "\n")
    f:write("CMT_URL=" .. CMT_URL .. "\n")
    f:write("CMT_SO_NICK=" .. tostring(CMT_SO_NICK) .. "\n")
    f:write("CMT_MODE=" .. CMT_MODE .. "\n")
    f:write("CMT_MAX_ATTEMPTS=" .. tostring(CMT_MAX_ATTEMPTS) .. "\n")
    f:write("CMT_SCROLL_DELAY=" .. tostring(CMT_SCROLL_DELAY) .. "\n")
    f:write("SHARE_URL=" .. SHARE_URL .. "\n")
    f:write("SHARE_SO_NICK=" .. tostring(SHARE_SO_NICK) .. "\n")
    f:write("SHARE_MAX_ATTEMPTS=" .. tostring(SHARE_MAX_ATTEMPTS) .. "\n")
    f:write("SHARE_SCROLL_DELAY=" .. tostring(SHARE_SCROLL_DELAY) .. "\n")
    f:write("SHARE_TAP_DELAY=" .. tostring(SHARE_TAP_DELAY) .. "\n")
    f:write("SHARE_MAX_CHECK=" .. tostring(SHARE_MAX_CHECK) .. "\n")
    f:write("ACCOUNT_FILE=" .. ACCOUNT_FILE .. "\n")
    f:write("UID_FRIEND_FILE=" .. UID_FRIEND_FILE .. "\n")
    f:close()
    toast("✅ Đã lưu cấu hình!")
    log("💾 Da luu config vao: " .. CONFIG_PATH)
    return true
end

-- ========== TẢI CẤU HÌNH TỪ FILE ==========
local function taiCauHinh()
    local f = io.open(CONFIG_PATH, "r")
    if not f then
        toast("⚠️ Chưa có cấu hình đã lưu!")
        return false
    end
    for line in f:lines() do
        local key, value = line:match("^([^=]+)=(.+)$")
        if key and value then
            key = key:match("^%s*(.-)%s*$")
            value = value:match("^%s*(.-)%s*$")
            if key == "ACCOUNT_FILE" then
                ACCOUNT_FILE = value
            elseif key == "UID_FRIEND_FILE" then
                UID_FRIEND_FILE = value
            elseif key == "CMT_URL" then
                CMT_URL = value
            elseif key == "SHARE_URL" then
                SHARE_URL = value
            elseif key == "INTERACT_URL" then
                INTERACT_URL = value
            elseif key == "CMT_MODE" then
                CMT_MODE = value
            else
                local num = tonumber(value)
                if num then ganGiaTri(key, num) end
            end
        end
    end
    f:close()
    toast("✅ Đã tải cấu hình!")
    log("📂 Da tai config tu: " .. CONFIG_PATH)
    return true
end

-- ========== TẠO CHUỖI TÓM TẮT CẤU HÌNH ==========
local function tomTatCauHinh()
    local lines = {}
    table.insert(lines, "── CHỨC NĂNG FARM ──")
    for _, feat in ipairs(GUI_FEATURES) do
        local val = layGiaTri(feat[2])
        local status = (val == 1) and "✅ BẬT" or "❌ TẮT"
        table.insert(lines, feat[1] .. ": " .. status)
    end
    table.insert(lines, "")
    table.insert(lines, "── THÔNG SỐ FARM ──")
    for _, setting in ipairs(GUI_SETTINGS) do
        table.insert(lines, "🔢 " .. setting[1] .. ": " .. layGiaTri(setting[2]) .. " " .. setting[3])
    end
    table.insert(lines, "")
    table.insert(lines, "── NẠP NICK ──")
    table.insert(lines, "📂 File: " .. ACCOUNT_FILE)
    table.insert(lines, "🔢 Số nick: " .. SO_NICK_CAN_DANG_NHAP)
    table.insert(lines, "")
    table.insert(lines, "── KẾT BẠN GỢI Ý ──")
    table.insert(lines, "👥 Nick chạy: " .. SO_NICK_KB_GY)
    table.insert(lines, "🔢 SL/Nick: " .. SO_LUONG_KB_GY)
    table.insert(lines, "")
    table.insert(lines, "── CHẤP NHẬN KẾT BẠN ──")
    table.insert(lines, "👥 Nick chạy: " .. SO_NICK_CNKB)
    table.insert(lines, "⏳ Delay: " .. DELAY_CNKB .. "s")
    return table.concat(lines, "\n")
end

-- ========== MENU BẬT/TẮT CHỨC NĂNG ==========
local function menuToggle()
    while true do
        local items = {}
        for _, feat in ipairs(GUI_FEATURES) do
            local val = layGiaTri(feat[2])
            local icon = (val == 1) and "✅" or "❌"
            table.insert(items, icon .. " " .. feat[1])
        end
        table.insert(items, "──────────────")
        table.insert(items, "🟢 Bật tất cả")
        table.insert(items, "🔴 Tắt tất cả")
        table.insert(items, "◀️ Quay lại")
        local choice = dialogChoice("⚙️ BẬT/TẮT CHỨC NĂNG", unpack(items))
        if not choice or choice:find("Quay lại") then
            return
        elseif choice:find("Bật tất cả") then
            for _, feat in ipairs(GUI_FEATURES) do ganGiaTri(feat[2], 1) end
            toast("✅ Đã bật tất cả!")
        elseif choice:find("Tắt tất cả") then
            for _, feat in ipairs(GUI_FEATURES) do ganGiaTri(feat[2], 0) end
            toast("❌ Đã tắt tất cả!")
        elseif not choice:find("────") then
            for _, feat in ipairs(GUI_FEATURES) do
                if choice:find(feat[1]) then
                    local val = layGiaTri(feat[2])
                    ganGiaTri(feat[2], (val == 1) and 0 or 1)
                    local status = (layGiaTri(feat[2]) == 1) and "BẬT ✅" or "TẮT ❌"
                    toast(feat[1] .. ": " .. status)
                    break
                end
            end
        end
    end
end

-- ========== MENU CÀI ĐẶT THÔNG SỐ ==========
local function menuSettings()
    while true do
        local items = {}
        for _, setting in ipairs(GUI_SETTINGS) do
            table.insert(items, "🔢 " .. setting[1] .. ": " .. layGiaTri(setting[2]) .. " " .. setting[3])
        end
        table.insert(items, "◀️ Quay lại")
        local choice = dialogChoice("🔢 CÀI ĐẶT THÔNG SỐ", unpack(items))
        if not choice or choice:find("Quay lại") then return end
        for _, setting in ipairs(GUI_SETTINGS) do
            if choice:find(setting[1]) then
                local curVal = layGiaTri(setting[2])
                local input = dialogInput(
                    setting[1],
                    "Nhập giá trị mới (" .. setting[3] .. ")\nHiện tại: " .. curVal
                )
                if input then
                    local num = tonumber(input)
                    if num and num >= 0 then
                        ganGiaTri(setting[2], math.floor(num))
                        toast(setting[1] .. " = " .. layGiaTri(setting[2]))
                    else
                        toast("⚠️ Giá trị không hợp lệ!")
                    end
                end
                break
            end
        end
    end
end

-- ========== HÀM ĐẾM NICK TRONG FILE ==========
local function demNickTrongFile()
    local soNick = 0
    local f = io.open(ACCOUNT_FILE, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content then
            for line in string.gmatch(content, "[^\r\n]+") do
                if line ~= "" then soNick = soNick + 1 end
            end
        end
    end
    return soNick
end

-- ========== HÀM THÊM NICK VÀO FILE ==========
local function ghiNickVaoFile(nickLine)
    local f = io.open(ACCOUNT_FILE, "a")
    if not f then
        f = io.open(ACCOUNT_FILE, "w")
    end
    if not f then
        toast("❌ Không thể ghi file!")
        return false
    end
    f:write(nickLine .. "\n")
    f:close()
    return true
end

-- ========== HÀM GHI LOG KẾT BẠN UID ==========
local function ghiLogUID(msg)
    local f = io.open(UID_LOG_FILE, "a")
    if not f then f = io.open(UID_LOG_FILE, "w") end
    if f then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        f:write("[" .. timestamp .. "] " .. msg .. "\n")
        f:close()
    end
end

-- ============================================
-- CHECK LIVE UID BẰNG FACEBOOK GRAPH API
-- ============================================

-- ========== KIỂM TRA LIVE UID (CHUẨN URL) ==========
local function kiemTraLiveUID(uid)
    if not uid or uid == "" then
        return false, "Không có UID"
    end
    
    local ok, r = pcall(function()
        return httpGet("https://graph.facebook.com/" .. uid .. "/picture?redirect=false")
    end)
    
    if not ok then
        return false, "Lỗi kết nối: " .. tostring(r)
    end
    
    local body = ""
    if type(r) == "table" then
        body = r.body or r.data or r[1] or ""
    elseif type(r) == "string" then
        body = r
    end
    
    local url = string.match(body, '"url"%s*:%s*"([^"]+)"')
    
    if url then
        local doDai = #url
        
        local dieUrls = {
            "https://static.xx.fbcdn.net/rsrc.php/v4/yo/r/UlIqmHJn-SK.gif",
            "https://static.xx.fbcdn.net/rsrc.php/v4/yL/r/HsTZSDw4avx.gif",
            "https://static.xx.fbcdn.net/rsrc.php/v4/y-/r/IOC9bCk9Hhd.gif"
        }
        
        for _, dieUrl in ipairs(dieUrls) do
            if url == dieUrl then
                return false, "URL ảnh mặc định (die)"
            end
        end
        
        if doDai > 150 then
            return true, "URL dài (" .. doDai .. " ký tự)"
        else
            return false, "URL quá ngắn (" .. doDai .. " ký tự)"
        end
    end
    
    if string.find(body, '"error"') then
        return false, "API trả về error"
    end
    
    return false, "Không xác định được"
end

-- ========== LƯU THỐNG KÊ VÀO FILE ==========
local function luuThongKe(ngayGio, tongNick, liveNick, dieNick, tyLeLive, tyLeDie, chiTiet)
    local f = io.open(THONG_KE_FILE, "a")
    if f then
        f:write("========================================\n")
        f:write("📅 THỜI GIAN: " .. ngayGio .. "\n")
        f:write("📊 TỔNG NICK: " .. tongNick .. "\n")
        f:write("✅ LIVE: " .. liveNick .. " (" .. string.format("%.2f", tyLeLive) .. "%)\n")
        f:write("❌ DIE: " .. dieNick .. " (" .. string.format("%.2f", tyLeDie) .. "%)\n")
        f:write("📋 CHI TIẾT:\n")
        for _, item in ipairs(chiTiet) do
            f:write("   " .. item .. "\n")
        end
        f:write("========================================\n\n")
        f:close()
        return true
    end
    return false
end

-- ========== ĐỌC NICK TỪ FILE (GIỮ NGUYÊN ĐỊNH DẠNG) ==========
local function docNickTuFile()
    local file = io.open(ACCOUNT_FILE, "r")
    if not file then
        return {}
    end
    
    local lines = {}
    for line in file:lines() do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    file:close()
    return lines
end

-- ========== LẤY UID TỪ DÒNG NICK ==========
local function layUIDTuDong(line)
    local uid = line:match("^([^|]+)")
    if uid then
        uid = uid:match("^%s*(.-)%s*$")
    end
    return uid
end

-- ========== LẤY THỜI GIAN HIỆN TẠI ==========
local function layThoiGian()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- ========== HIỂN THỊ THỐNG KÊ CHI TIẾT ==========
local function hienThiThongKe(tong, live, die, tyLeLive, tyLeDie)
    log("")
    log("╔══════════════════════════════════════════════════════════╗")
    log("║                    📊 THỐNG KÊ CHI TIẾT                   ║")
    log("╠══════════════════════════════════════════════════════════╣")
    log(string.format("║  📝 TỔNG SỐ NICK:     %-40s║", tong))
    log(string.format("║  ✅ LIVE:            %-40s║", live .. " (" .. string.format("%.2f", tyLeLive) .. "%)"))
    log(string.format("║  ❌ DIE:             %-40s║", die .. " (" .. string.format("%.2f", tyLeDie) .. "%)"))
    log("╠══════════════════════════════════════════════════════════╣")
    log(string.format("║  📈 TỶ LỆ LIVE/DEATH: %-40s║", string.format("%.1f", tyLeLive) .. "% / " .. string.format("%.1f", tyLeDie) .. "%"))
    
    -- Đánh giá chất lượng
    local danhGia = ""
    if tyLeLive >= 80 then
        danhGia = "★★★★★ TỐT"
    elseif tyLeLive >= 60 then
        danhGia = "★★★★☆ KHÁ"
    elseif tyLeLive >= 40 then
        danhGia = "★★★☆☆ TRUNG BÌNH"
    elseif tyLeLive >= 20 then
        danhGia = "★★☆☆☆ YẾU"
    else
        danhGia = "★☆☆☆☆ RẤT YẾU"
    end
    log(string.format("║  🏆 ĐÁNH GIÁ:        %-40s║", danhGia))
    log("╚══════════════════════════════════════════════════════════╝")
    log("")
end

-- ========== KIỂM TRA VÀ XÓA NICK DIE (GIỮ NGUYÊN ĐỊNH DẠNG) ==========
local function kiemTraVaXoaNickDie()
    log("")
    log("==========================================")
    log("🔍 BẮT ĐẦU KIỂM TRA VÀ XÓA NICK DIE")
    log("==========================================")
    
    local allLines = docNickTuFile()
    
    if #allLines == 0 then
        log("📭 File nick rỗng!")
        toast("📭 File nick rỗng!", 2)
        return 0
    end
    
    log("📊 Tổng số nick trong file: " .. #allLines)
    toast("📊 Tổng số nick: " .. #allLines, 2)
    sleep(1)
    
    local liveLines = {}
    local dieLines = {}
    local ketQua = {}
    local chiTietThongKe = {}
    
    local startTime = os.time()
    
    for i, line in ipairs(allLines) do
        local percent = math.floor((i / #allLines) * 100)
        toast("🔍 Đang kiểm tra: " .. i .. "/" .. #allLines .. " (" .. percent .. "%)", 1)
        
        local uid = layUIDTuDong(line)
        
        if not uid or uid == "" then
            log("⚠️ Không thể lấy UID từ dòng: " .. line)
            table.insert(liveLines, line)
            table.insert(ketQua, {line = line, uid = "???", status = "UNKNOWN", reason = "Không lấy được UID"})
            table.insert(chiTietThongKe, "⚠️ ??? | UNKNOWN")
        else
            log("")
            log("👉 Kiểm tra nick " .. i .. "/" .. #allLines .. ": " .. uid)
            
            local isLive, lyDo = kiemTraLiveUID(uid)
            
            if isLive then
                table.insert(liveLines, line)
                table.insert(ketQua, {line = line, uid = uid, status = "LIVE", reason = lyDo})
                table.insert(chiTietThongKe, "✅ " .. uid .. " | LIVE")
                log("✅ GIỮ LẠI: " .. uid .. " | " .. lyDo)
            else
                table.insert(dieLines, line)
                table.insert(ketQua, {line = line, uid = uid, status = "DIE", reason = lyDo})
                table.insert(chiTietThongKe, "❌ " .. uid .. " | DIE | " .. lyDo)
                log("❌ XÓA: " .. uid .. " | " .. lyDo)
            end
        end
        
        if i < #allLines then
            sleep(1)
        end
    end
    
    local endTime = os.time()
    local thoiGianChay = endTime - startTime
    
    -- Ghi lại file chỉ còn nick live
    if #dieLines > 0 then
        toast("💾 Đang xóa " .. #dieLines .. " nick die và ghi lại file...", 2)
        
        local fw = io.open(ACCOUNT_FILE, "w")
        if fw then
            for _, line in ipairs(liveLines) do
                fw:write(line .. "\n")
            end
            fw:close()
            log("")
            log("✅ Đã xóa " .. #dieLines .. " nick DIE khỏi file!")
            log("✅ Còn lại " .. #liveLines .. " nick LIVE trong file!")
        else
            log("❌ Không thể ghi file!")
            toast("❌ Không thể ghi file!", 2)
        end
    else
        log("")
        log("✅ Tất cả nick đều LIVE! Không có nick nào bị xóa!")
    end
    
    -- Tính toán thống kê
    local liveCount = #liveLines
    local dieCount = #dieLines
    local tongNick = #allLines
    local percentLive = (liveCount / tongNick) * 100
    local percentDie = (dieCount / tongNick) * 100
    
    -- Hiển thị thống kê đẹp
    hienThiThongKe(tongNick, liveCount, dieCount, percentLive, percentDie)
    
    -- Thông báo thời gian chạy
    log("⏱️ THỜI GIAN CHẠY: " .. thoiGianChay .. " giây")
    
    -- Lưu thống kê vào file
    local thoiGian = layThoiGian()
    luuThongKe(thoiGian, tongNick, liveCount, dieCount, percentLive, percentDie, chiTietThongKe)
    log("💾 Đã lưu thống kê vào file: " .. THONG_KE_FILE)
    
    log("")
    log("📋 CHI TIẾT TỪNG NICK:")
    for _, item in ipairs(ketQua) do
        if item.status == "LIVE" then
            log("✅ " .. item.uid .. " | " .. item.status .. " | " .. item.reason)
        else
            log("❌ " .. item.uid .. " | " .. item.status .. " | " .. item.reason)
        end
    end
    log("==========================================")
    
    toast("✅ Xong! LIVE: " .. liveCount .. " (" .. string.format("%.1f", percentLive) .. "%) | DIE: " .. dieCount .. " | TG: " .. thoiGianChay .. "s", 3)
    
    return dieCount
end

-- ========== XEM THỐNG KÊ ĐÃ LƯU ==========
local function xemThongKeLuu()
    local file = io.open(THONG_KE_FILE, "r")
    if not file then
        dialogChoice("📊 THỐNG KÊ\n\n📭 Chưa có dữ liệu thống kê!", "OK ✅")
        return
    end
    
    local content = file:read("*a")
    file:close()
    
    if content == "" then
        dialogChoice("📊 THỐNG KÊ\n\n📭 Chưa có dữ liệu thống kê!", "OK ✅")
    else
        dialogChoice("📊 LỊCH SỬ THỐNG KÊ\n\n" .. content, "OK ✅")
    end
end

-- ========== XÓA TOÀN BỘ THỐNG KÊ ==========
local function xoaThongKe()
    local confirm = dialogChoice(
        "⚠️ XÓA TOÀN BỘ THỐNG KÊ\n\n"
        .. "Bạn có chắc chắn muốn xóa tất cả lịch sử thống kê?",
        "✅ Xóa ngay!",
        "◀️ Hủy"
    )
    
    if confirm and confirm:find("Xóa ngay") then
        local f = io.open(THONG_KE_FILE, "w")
        if f then
            f:write("")
            f:close()
            toast("🗑️ Đã xóa toàn bộ lịch sử thống kê!", 2)
        else
            toast("❌ Không thể xóa file thống kê!", 2)
        end
    end
end

-- ========== MENU CHECK LIVE UID ==========
local function menuCheckUID()
    while true do
        local soNick = demNickTrongFile()
        
        local filename = ACCOUNT_FILE:match("([^/]+)$") or ACCOUNT_FILE
        local title = "🔍 Check live UID\n"
            .. "· File: " .. filename .. "\n"
            .. "· Tổng nick: " .. soNick
        
        local choice = dialogChoice(title,
            "🗑️ Kiểm tra và xóa nick DIE",
            "📊 Xem lịch sử thống kê",
            "🗑️ Xóa toàn bộ thống kê",
            "◀️ Quay lại"
        )
        
        if not choice or choice:find("Quay lại") then
            return
        elseif choice:find("Kiểm tra và xóa nick DIE") then
            if soNick == 0 then
                toast("⚠️ File nick rỗng! Thêm nick trước!", 2)
            else
                local confirm = dialogChoice(
                    "🚀 XÁC NHẬN KIỂM TRA VÀ XÓA NICK DIE\n\n"
                    .. "📊 Tổng số nick: " .. soNick .. "\n"
                    .. "⚠️ Nick DIE sẽ tự động bị xóa khỏi file!\n"
                    .. "💾 Kết quả thống kê sẽ được lưu lại!",
                    "✅ Chạy ngay!",
                    "◀️ Quay lại"
                )
                if confirm and confirm:find("Chạy ngay") then
                    kiemTraVaXoaNickDie()
                end
            end
        elseif choice:find("Xem lịch sử thống kê") then
            xemThongKeLuu()
        elseif choice:find("Xóa toàn bộ thống kê") then
            xoaThongKe()
        end
    end
end

-- ========== HÀM ĐẾM UID TRONG FILE ==========
local function demUIDTrongFile()
    local soUID = 0
    local f = io.open(UID_FRIEND_FILE, "r")
    if f then
        local content = f:read("*all")
        f:close()
        if content then
            for line in string.gmatch(content, "[^\r\n]+") do
                if line ~= "" then soUID = soUID + 1 end
            end
        end
    end
    return soUID
end

-- ========== HÀM THÊM UID VÀO FILE ==========
local function ghiUIDVaoFile(uidLine)
    local f = io.open(UID_FRIEND_FILE, "a")
    if not f then
        f = io.open(UID_FRIEND_FILE, "w")
    end
    if not f then
        toast("❌ Không thể ghi file!")
        return false
    end
    f:write(uidLine .. "\n")
    f:close()
    return true
end

-- ========== MENU KẾT BẠN UID ==========
local function menuKetBanUID()
    while true do
        local soUIDCon = demUIDTrongFile()
        
        local filename = UID_FRIEND_FILE:match("([^/]+)$") or UID_FRIEND_FILE
        local title = "👤 Kết bạn theo UID\n"
            .. "· Nick: " .. SO_NICK_UID .. "  · UID/nick: " .. SO_UID_MOI_NICK .. "\n"
            .. "· Nghỉ: " .. THOI_GIAN_NGHI_UID .. "s  · Xóa UID: " .. (BAT_XOA_UID == 1 and "bật" or "tắt") .. "\n"
            .. "· Danh sách: " .. soUIDCon .. " UID  · File: " .. filename
        
        local choice = dialogChoice(title,
            "📋 Dán list UID kết bạn",
            "👁️ Xem danh sách UID",
            "🗑️ Xóa tất cả UID",
            "──────────────",
            "🗑️ Bật/Tắt xóa UID khi chạy",
            "🚩 Nick bắt đầu: " .. NICK_BAT_DAU,
            "👥 Đổi số nick cần chạy",
            "🔢 Đổi số UID mỗi nick",
            "⏳ Đổi thời gian nghỉ",
            "📂 Đổi đường dẫn file",
            "──────────────",
            "📜 Xem Log kết bạn",
            "🧹 Xóa Log kết bạn",
            "──────────────",
            "🚀 BẮT ĐẦU KẾT BẠN",
            "◀️ Quay lại"
        )
        
        if not choice or choice:find("Quay lại") then
            return "back"
        elseif choice:find("Dán list UID") then
            local bulk = dialogInput(
                "📋 NHẬP DANH SÁCH UID",
                "Nhập mỗi UID một dòng\nHoặc dán cả list vào đây:"
            )
            if bulk and bulk ~= "" then
                local lines = {}
                for line in string.gmatch(bulk, "[^\r\n]+") do
                    local uid = line:match("^%s*(.-)%s*$")
                    if uid ~= "" then
                        table.insert(lines, uid)
                    end
                end
                
                if #lines > 0 then
                    for _, uid in ipairs(lines) do
                        ghiUIDVaoFile(uid)
                    end
                    local newCount = demUIDTrongFile()
                    toast("✅ Đã thêm " .. #lines .. " UID! Tổng: " .. newCount)
                    log("👤 Da them " .. #lines .. " UID | Tong: " .. newCount)
                else
                    toast("⚠️ Không tìm thấy UID hợp lệ!")
                end
            end
        
        elseif choice:find("Xem danh sách") then
            local allLines = {}
            local f = io.open(UID_FRIEND_FILE, "r")
            if f then
                for line in f:lines() do
                    if line ~= "" then 
                        local uid = line:match("^%s*(.-)%s*$")
                        if uid and uid ~= "" then table.insert(allLines, uid) end
                    end
                end
                f:close()
            end
            
            if #allLines == 0 then
                dialogChoice("📂 FILE UID\n\n📭 File rỗng!", "OK ✅")
            else
                local page = 1
                local pageSize = 50
                while true do
                    local startIdx = (page - 1) * pageSize + 1
                    local endIdx = math.min(page * pageSize, #allLines)
                    local displayLines = {}
                    for i = startIdx, endIdx do
                        table.insert(displayLines, i .. ". " .. allLines[i])
                    end
                    local preview = table.concat(displayLines, "\n")
                    local totalPage = math.ceil(#allLines / pageSize)
                    
                    local buttons = {"OK ✅"}
                    if page < totalPage then table.insert(buttons, "Trang tiếp ➡️") end
                    if page > 1 then table.insert(buttons, "⬅️ Trang trước") end
                    
                    local msg = "📂 DANH SÁCH UID\n"
                        .. "📄 Trang: " .. page .. "/" .. totalPage .. "\n"
                        .. "📊 Tổng: " .. #allLines .. " UID\n"
                        .. "────────────────\n"
                        .. preview
                    
                    local c = dialogChoice(msg, unpack(buttons))
                    if not c or c:find("OK") then break
                    elseif c:find("Trang tiếp") then page = page + 1
                    elseif c:find("Trang trước") then page = page - 1
                    end
                end
            end
        
        elseif choice:find("Xóa tất cả UID") then
            if soUIDCon == 0 then
                toast("📭 File đã rỗng!")
            else
                local confirm = dialogChoice(
                    "🗑️ XÓA TẤT CẢ UID?\n\nSẽ xóa " .. soUIDCon .. " UID trong file.",
                    "🗑️ Xóa hết!",
                    "◀️ Hủy"
                )
                if confirm and confirm:find("Xóa hết") then
                    local f = io.open(UID_FRIEND_FILE, "w")
                    if f then
                        f:write("")
                        f:close()
                        toast("✅ Đã xóa tất cả UID!")
                        log("🗑️ Da xoa tat ca UID trong file friend")
                    end
                end
            end
            
        elseif choice:find("Bật/Tắt xóa UID") then
            BAT_XOA_UID = (BAT_XOA_UID == 1) and 0 or 1
            local status = (BAT_XOA_UID == 1) and "BẬT ✅" or "TẮT ❌"
            toast("Xóa UID sau khi chạy: " .. status)

        elseif choice:find("Nick bắt đầu") then
            local input = dialogInput("Nick bắt đầu", "STT nick bắt đầu chạy:", tostring(NICK_BAT_DAU))
            if input then
                local num = tonumber(input)
                if num and num >= 0 then
                    NICK_BAT_DAU = math.floor(num)
                    toast("🚩 Nick bắt đầu: " .. NICK_BAT_DAU)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end

        elseif choice:find("Đổi số nick") then
            local input = dialogInput("Số nick cần chạy", "Hiện tại: " .. SO_NICK_UID)
            if input then
                local num = tonumber(input)
                if num and num > 0 then
                    SO_NICK_UID = math.floor(num)
                    toast("👥 Số nick: " .. SO_NICK_UID)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end

        elseif choice:find("Đổi số UID") then
            local input = dialogInput("Số UID mỗi nick", "Hiện tại: " .. SO_UID_MOI_NICK)
            if input then
                local num = tonumber(input)
                if num and num > 0 then
                    SO_UID_MOI_NICK = math.floor(num)
                    toast("🔢 Số UID/nick: " .. SO_UID_MOI_NICK)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end
            
        elseif choice:find("Đổi thời gian nghỉ") then
            local input = dialogInput("Thời gian nghỉ (giây)", "Hiện tại: " .. THOI_GIAN_NGHI_UID)
            if input then
                local num = tonumber(input)
                if num and num > 0 then
                    THOI_GIAN_NGHI_UID = math.floor(num)
                    toast("⏳ Nghỉ: " .. THOI_GIAN_NGHI_UID .. "s")
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end

        elseif choice:find("Đổi đường dẫn") then
            local input = dialogInput("Đường dẫn file UID", "Hiện tại: " .. UID_FRIEND_FILE)
            if input and input ~= "" then
                UID_FRIEND_FILE = input
                toast("📂 File: " .. UID_FRIEND_FILE)
            end

        elseif choice:find("Xem Log") then
            local f = io.open(UID_LOG_FILE, "r")
            if not f then
                dialogChoice("📜 LOG KẾT BẠN\n\n❌ Chưa có log!", "OK ✅")
            else
                local lines = {}
                for line in f:lines() do
                    table.insert(lines, line)
                    if #lines > 100 then table.remove(lines, 1) end
                end
                f:close()
                if #lines == 0 then
                    dialogChoice("📜 LOG KẾT BẠN\n\n📭 Log rỗng!", "OK ✅")
                else
                    local preview = table.concat(lines, "\n")
                    dialogChoice("📜 LOG KẾT BẠN (100 dòng mới nhất)\n\n" .. preview, "OK ✅")
                end
            end

        elseif choice:find("Xóa Log") then
            local confirm = dialogChoice("🧹 XÓA LOG KẾT BẠN?", "🗑️ Xóa hết!", "◀️ Hủy")
            if confirm and confirm:find("Xóa hết") then
                local f = io.open(UID_LOG_FILE, "w")
                if f then f:close() end
                toast("✅ Đã xóa log!")
            end
            
        elseif choice:find("BẮT ĐẦU KẾT BẠN") then
            if soUIDCon == 0 then
                toast("⚠️ Danh sách rỗng! Thêm UID trước!")
            else
                local confirm = dialogChoice(
                    "🚀 XÁC NHẬN KẾT BẠN\n\n"
                    .. "👥 Chạy: " .. SO_NICK_UID .. " nick\n"
                    .. "🔢 Mỗi nick: " .. SO_UID_MOI_NICK .. " UID\n"
                    .. "⏳ Nghỉ: " .. THOI_GIAN_NGHI_UID .. " giây",
                    "✅ Chạy ngay!",
                    "◀️ Quay lại"
                )
                if confirm and confirm:find("Chạy ngay") then
                    luuCauHinh()
                    return "ket_ban_uid"
                end
            end
        end
    end
end

-- ========== MENU NẠP NICK ==========
local function menuNapNick()
    while true do
        local soNickCon = demNickTrongFile()
        
        local filename = ACCOUNT_FILE:match("([^/]+)$") or ACCOUNT_FILE
        local title = "🔑 Nạp nick\n"
            .. "· Nạp: " .. SO_NICK_CAN_DANG_NHAP .. " nick  · Còn: " .. soNickCon .. "\n"
            .. "· File: " .. filename
        
        local choice = dialogChoice(title,
            "➕ Thêm nick (nhập tay)",
            "📋 Dán nhiều nick",
            "👁️ Xem danh sách nick",
            "🗑️ Xóa tất cả nick",
            "🔍 Check Live UID",
            "──────────────",
            "📂 Đổi đường dẫn file",
            "🔢 Đổi số nick cần nạp",
            "──────────────",
            "🚀 BẮT ĐẦU NẠP NICK",
            "◀️ Quay lại"
        )
        
        if not choice or choice:find("Quay lại") then
            return "back"
        elseif choice:find("Thêm nick") then
            local soThem = 0
            while true do
                local currentCount = demNickTrongFile()
                local uid = dialogInput(
                    "👤 THÊM NICK (#" .. (soThem + 1) .. ")",
                    "Đã thêm: " .. soThem .. " | Trong file: " .. currentCount
                    .. "\n\nNhập UID / email / SĐT\n(Bỏ trống để dừng)"
                )
                if not uid or uid == "" then
                    if soThem > 0 then
                        toast("✅ Đã thêm " .. soThem .. " nick!")
                    end
                    break
                end
                
                local pass = dialogInput("🔐 Mật khẩu", "Nhập mật khẩu cho: " .. uid)
                if not pass or pass == "" then
                    toast("⚠️ Bỏ qua nick này (chưa nhập pass)")
                else
                    local twofa = dialogInput(
                        "🔑 Secret 2FA",
                        "Nick: " .. uid .. "\n\nNhập secret 2FA\n(Bỏ trống nếu không có)"
                    )
                    if not twofa then twofa = "" end
                    
                    local nickLine
                    if twofa ~= "" then
                        nickLine = uid .. "|" .. pass .. "|" .. twofa
                    else
                        nickLine = uid .. "|" .. pass
                    end
                    
                    if ghiNickVaoFile(nickLine) then
                        soThem = soThem + 1
                        local newCount = demNickTrongFile()
                        toast("✅ Nick #" .. soThem .. " đã thêm! Tổng: " .. newCount)
                        log("➕ Them nick: " .. uid .. " (#" .. soThem .. ") | Tong: " .. newCount)
                    end
                end
            end
        
        -- ===== DÁN NHIỀU NICK =====
        elseif choice:find("Dán nhiều") then
            local bulk = dialogInput(
                "📋 DÁN NHIỀU NICK",
                "Định dạng: uid|pass  hoặc  uid|pass|2fa"
                .. "\n\nCách nhau bằng: xuống dòng, dấu ; hoặc dấu ,"
                .. "\n\nVí dụ:"
                .. "\nuid1|pass1|2fa1;uid2|pass2;uid3|pass3"
                .. "\n\nDán vào đây:"
            )
            if bulk and bulk ~= "" then
                local rawItems = {}
                for line in string.gmatch(bulk, "[^\r\n]+") do
                    for item in string.gmatch(line, "[^;,]+") do
                        item = item:match("^%s*(.-)%s*$")
                        if item ~= "" then
                            table.insert(rawItems, item)
                        end
                    end
                end
                
                local nicksMoi = {}
                local nicksLoi = 0
                for _, item in ipairs(rawItems) do
                    local parts = {}
                    for part in string.gmatch(item, "[^|]+") do
                        local trimmed = part:match("^%s*(.-)%s*$")
                        table.insert(parts, trimmed)
                    end
                    if #parts >= 2 and parts[1] ~= "" and parts[2] ~= "" then
                        local nickLine
                        if #parts >= 3 and parts[3] ~= "" then
                            nickLine = parts[1] .. "|" .. parts[2] .. "|" .. parts[3]
                        else
                            nickLine = parts[1] .. "|" .. parts[2]
                        end
                        table.insert(nicksMoi, {uid = parts[1], line = nickLine, has2fa = (#parts >= 3 and parts[3] ~= "")})
                    else
                        nicksLoi = nicksLoi + 1
                    end
                end
                
                if #nicksMoi == 0 then
                    toast("⚠️ Không có nick hợp lệ! (cần uid|pass)")
                else
                    local preview = {}
                    for i, nick in ipairs(nicksMoi) do
                        local icon2fa = nick.has2fa and "🔑" or "🔓"
                        table.insert(preview, i .. ". " .. icon2fa .. " " .. nick.uid)
                    end
                    local previewText = table.concat(preview, "\n")
                    if nicksLoi > 0 then
                        previewText = previewText .. "\n\n⚠️ " .. nicksLoi .. " dòng lỗi (bỏ qua)"
                    end
                    
                    local confirm = dialogChoice(
                        "📋 XÁC NHẬN THÊM " .. #nicksMoi .. " NICK\n\n" .. previewText,
                        "✅ Thêm tất cả!",
                        "◀️ Hủy"
                    )
                    
                    if confirm and confirm:find("Thêm tất cả") then
                        for _, nick in ipairs(nicksMoi) do
                            ghiNickVaoFile(nick.line)
                        end
                        local newCount = demNickTrongFile()
                        toast("✅ Đã thêm " .. #nicksMoi .. " nick! Tổng: " .. newCount)
                        log("📋 Dan " .. #nicksMoi .. " nick | Tổng: " .. newCount)
                    end
                end
            end
        
        -- ===== XEM DANH SÁCH NICK =====
        elseif choice:find("Xem danh sách") then
            local allLines = {}
            local f = io.open(ACCOUNT_FILE, "r")
            if f then
                for line in f:lines() do
                    if line ~= "" then table.insert(allLines, line) end
                end
                f:close()
            end
            
            if #allLines == 0 then
                dialogChoice("📂 FILE NICK\n\n📭 File rỗng!", "OK ✅")
            else
                local page = 1
                local pageSize = 50
                while true do
                    local startIdx = (page - 1) * pageSize + 1
                    local endIdx = math.min(page * pageSize, #allLines)
                    local displayLines = {}
                    for i = startIdx, endIdx do
                        local line = allLines[i]
                        local parts = {}
                        for part in string.gmatch(line, "[^|]+") do table.insert(parts, part) end
                        local uid = parts[1] or "?"
                        local has2fa = (#parts >= 3) and "🔑" or "🔓"
                        table.insert(displayLines, i .. ". " .. has2fa .. " " .. uid)
                    end
                    local preview = table.concat(displayLines, "\n")
                    local totalPage = math.ceil(#allLines / pageSize)
                    
                    local buttons = {"OK ✅"}
                    if page < totalPage then table.insert(buttons, "Trang tiếp ➡️") end
                    if page > 1 then table.insert(buttons, "⬅️ Trang trước") end
                    
                    local msg = "📂 DANH SÁCH NICK\n"
                        .. "📄 Trang: " .. page .. "/" .. totalPage .. "\n"
                        .. "📊 Tổng: " .. #allLines .. " nick\n"
                        .. "────────────────\n"
                        .. preview
                    
                    local c = dialogChoice(msg, unpack(buttons))
                    if not c or c:find("OK") then break
                    elseif c:find("Trang tiếp") then page = page + 1
                    elseif c:find("Trang trước") then page = page - 1
                    end
                end
            end
        
        -- ===== XÓA TẤT CẢ NICK =====
        elseif choice:find("Xóa tất cả") then
            if soNickCon == 0 then
                toast("📭 File đã rỗng!")
            else
                local confirm = dialogChoice(
                    "🗑️ XÓA TẤT CẢ NICK?\n\nSẽ xóa " .. soNickCon .. " nick trong file.\nKhông thể hoàn tác!",
                    "🗑️ Xóa hết!",
                    "◀️ Hủy"
                )
                if confirm and confirm:find("Xóa hết") then
                    local f = io.open(ACCOUNT_FILE, "w")
                    if f then
                        f:write("")
                        f:close()
                        toast("✅ Đã xóa tất cả nick!")
                        log("🗑️ Da xoa tat ca nick trong file")
                    end
                end
            end
            
        elseif choice:find("Đổi đường dẫn") then
            local input = dialogInput("Đường dẫn file nick", "Hiện tại: " .. ACCOUNT_FILE)
            if input and input ~= "" then
                ACCOUNT_FILE = input
                toast("📂 File: " .. ACCOUNT_FILE)
            end
            
        elseif choice:find("Đổi số nick") then
            local input = dialogInput("Số nick cần nạp", "Hiện tại: " .. SO_NICK_CAN_DANG_NHAP)
            if input then
                local num = tonumber(input)
                if num and num > 0 then
                    SO_NICK_CAN_DANG_NHAP = math.floor(num)
                    toast("🔢 Số nick: " .. SO_NICK_CAN_DANG_NHAP)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end
            
        elseif choice:find("Check Live UID") then
            menuCheckUID()
            
        elseif choice:find("BẮT ĐẦU NẠP") then
            if soNickCon == 0 then
                toast("⚠️ File nick rỗng! Thêm nick trước!")
            else
                local confirm = dialogChoice(
                    "🚀 XÁC NHẬN NẠP NICK\n\n"
                    .. "📂 File: " .. ACCOUNT_FILE .. "\n"
                    .. "🔢 Nạp: " .. SO_NICK_CAN_DANG_NHAP .. " nick\n"
                    .. "📊 Còn: " .. soNickCon .. " nick",
                    "✅ Nạp ngay!",
                    "◀️ Quay lại"
                )
                if confirm and confirm:find("Nạp ngay") then
                    luuCauHinh()
                    return "nap_nick"
                end
            end
        end
    end
end

-- ========== MENU KẾT BẠN GỢI Ý ==========
local function menuKetBanGoiY()
    while true do
        local title = "👥 Kết bạn gợi ý\n"
            .. "· Nick: " .. SO_NICK_KB_GY .. "  · SL/nick: " .. SO_LUONG_KB_GY .. "\n"
            .. "· Nghỉ: " .. DELAY_KB_GY .. "s  · Lướt tối đa: " .. MAX_LUOT_KB_GY .. " lần"
            
        local choice = dialogChoice(title,
            "👥 Đổi số nick cần chạy",
            "🚩 Nick bắt đầu: " .. NICK_BAT_DAU,
            "🔢 Đổi số lượng KB/nick",
            "⏳ Đổi thời gian nghỉ",
            "📜 Đổi số lần lướt tối đa",
            "──────────────",
            "🚀 BẮT ĐẦU CHẠY",
            "◀️ Quay lại"
        )
        
        if not choice or choice:find("Quay lại") then
            return "back"
            
        elseif choice:find("Đổi số nick") then
            local input = dialogInput("Số nick cần chạy", "Hiện tại: " .. SO_NICK_KB_GY)
            if input and tonumber(input) then SO_NICK_KB_GY = math.floor(tonumber(input)) end
            
        elseif choice:find("Nick bắt đầu") then
            local input = dialogInput("Nick bắt đầu", "STT nick bắt đầu chạy:", tostring(NICK_BAT_DAU))
            if input then
                local num = tonumber(input)
                if num and num >= 0 then
                    NICK_BAT_DAU = math.floor(num)
                    toast("🚩 Nick bắt đầu: " .. NICK_BAT_DAU)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end
            
        elseif choice:find("Đổi số lượng") then
            local input = dialogInput("Số lượng kết bạn mỗi nick", "Hiện tại: " .. SO_LUONG_KB_GY)
            if input and tonumber(input) then SO_LUONG_KB_GY = math.floor(tonumber(input)) end
            
        elseif choice:find("Đổi thời gian") then
            local input = dialogInput("Thời gian nghỉ (giây)", "Hiện tại: " .. DELAY_KB_GY)
            if input and tonumber(input) then DELAY_KB_GY = math.floor(tonumber(input)) end
            
        elseif choice:find("Đổi số lần lướt") then
            local input = dialogInput("Lướt tối đa không thấy nút", "Hiện tại: " .. MAX_LUOT_KB_GY)
            if input and tonumber(input) then MAX_LUOT_KB_GY = math.floor(tonumber(input)) end
            
        elseif choice:find("BẮT ĐẦU CHẠY") then
            local confirm = dialogChoice(
                "🚀 XÁC NHẬN CHẠY GỢI Ý\n\n"
                .. "👥 Chạy: " .. SO_NICK_KB_GY .. " nick\n"
                .. "🔢 SL: " .. SO_LUONG_KB_GY .. " người/nick",
                "✅ Chạy ngay!",
                "◀️ Quay lại"
            )
            if confirm and confirm:find("Chạy ngay") then
                luuCauHinh()
                return "ket_ban_goi_y"
            end
        end
    end
end

-- ========== MENU CHẤP NHẬN KẾT BẠN ==========
local function menuChapNhanKetBan()
    while true do
        local title = "🤝 Chấp nhận kết bạn\n"
            .. "· Nick: " .. SO_NICK_CNKB .. "  · Nghỉ: " .. DELAY_CNKB .. "s\n"
            .. "· Lướt tối đa: " .. MAX_LUOT_CNKB .. " lần"
            
        local choice = dialogChoice(title,
            "👥 Đổi số nick cần chạy",
            "🚩 Nick bắt đầu: " .. NICK_BAT_DAU,
            "⏳ Đổi thời gian nghỉ",
            "📜 Đổi số lần lướt tối đa",
            "──────────────",
            "🚀 BẮT ĐẦU CHẠY",
            "◀️ Quay lại"
        )
        
        if not choice or choice:find("Quay lại") then
            return "back"
            
        elseif choice:find("Đổi số nick") then
            local input = dialogInput("Số nick cần chạy", "Hiện tại: " .. SO_NICK_CNKB)
            if input and tonumber(input) then SO_NICK_CNKB = math.floor(tonumber(input)) end
            
        elseif choice:find("Nick bắt đầu") then
            local input = dialogInput("Nick bắt đầu", "STT nick bắt đầu chạy:", tostring(NICK_BAT_DAU))
            if input then
                local num = tonumber(input)
                if num and num >= 0 then
                    NICK_BAT_DAU = math.floor(num)
                    toast("🚩 Nick bắt đầu: " .. NICK_BAT_DAU)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end
            
        elseif choice:find("Đổi thời gian") then
            local input = dialogInput("Thời gian nghỉ (giây)", "Hiện tại: " .. DELAY_CNKB)
            if input and tonumber(input) then DELAY_CNKB = math.floor(tonumber(input)) end
            
        elseif choice:find("Đổi số lần lướt") then
            local input = dialogInput("Lướt tối đa không thấy nút", "Hiện tại: " .. MAX_LUOT_CNKB)
            if input and tonumber(input) then MAX_LUOT_CNKB = math.floor(tonumber(input)) end
            
        elseif choice:find("BẮT ĐẦU CHẠY") then
            local confirm = dialogChoice(
                "🚀 XÁC NHẬN CHẠY CHẤP NHẬN\n\n"
                .. "👥 Chạy: " .. SO_NICK_CNKB .. " nick\n"
                .. "⏳ Nghỉ: " .. DELAY_CNKB .. "s",
                "✅ Chạy ngay!",
                "◀️ Quay lại"
            )
            if confirm and confirm:find("Chạy ngay") then
                luuCauHinh()
                return "chap_nhan_kb"
            end
        end
    end
end

-- ============================================
-- CHẤP NHẬN KẾT BẠN (CONFIRM FRIEND)
-- TÌM FRIENDS -> NẾU KHÔNG CÓ THÌ VÀO MENU
-- OCR TÌM CONFIRM VÀ TAP ĐẾN KHI HẾT
-- ============================================

-- ========== TÌM VÀ TAP FRIENDS (QUA MENU NẾU CẦN) ==========
local function timVaTapFriends()
    log("🔍 Tim Friends...")
    
    -- Cách 1: Tìm trực tiếp Friends trên thanh điều hướng
    if findText("Friends", 3) then
        tapText("Friends", 5, 1)
        log("✅ Da tap Friends truc tiep")
        sleep(2)
        return true
    end
    
    -- Cách 2: Tìm qua Menu
    log("⚠️ Khong tim thay Friends, tim Menu...")
    if findText("Menu", 3) then
        tapText("Menu", 5, 1)
        log("✅ Da tap Menu")
        sleep(2)
        
        -- Tìm Friends trong Menu
        if findText("Friends", 3) then
            tapText("Friends", 5, 1)
            log("✅ Da tap Friends qua Menu")
            sleep(2)
            return true
        end
    end
    
    logScreen("❌ KHÔNG TÌM THẤY MỤC BẠN BÈ", true)
    log("❌ Khong tim thay Friends")
    return false
end

-- ========== TÌM NÚT CONFIRM BẰNG OCR ==========
local function timTatCaConfirm()
    local danhSach = {}
    local results = ocr({
        region = {0, 0, 430, 800},
        languages = {"en-US"}
    })
    for _, r in ipairs(results) do
        if string.find(r.text, "Confirm") or string.find(r.text, "confirm") then
            table.insert(danhSach, {x = r.x, y = r.y, text = r.text})
        end
    end
    return danhSach
end

-- ========== LƯỚT MÀN HÌNH ==========
local function luotManHinhCNKB()
    log("📜 Khong tim thay Confirm -> Luot man hinh")
    swipe(296, 599, 215, 300, 1)
    sleep(2)
end

-- ========== CHẠY CHẤP NHẬN KẾT BẠN ==========
local function thucHienChapNhanKetBan()
    local instanceId = math.random(1000, 9999)
    logScreen("────────────────────\n🚀 BẮT ĐẦU CHẤP NHẬN KB\n────────────────────", true)
    logScreen("📂 CHẠY TỪ NICK " .. NICK_BAT_DAU .. " ĐẾN NICK " .. (NICK_BAT_DAU + SO_NICK_CNKB), true)
    log("👥 Nick sẽ chạy: " .. SO_NICK_CNKB)
    logScreen("🚀 BẮT ĐẦU CHẤP NHẬN KẾT BẠN", true)
    log("⏳ Delay giữa các lần: " .. DELAY_CNKB .. " giây")
    log("📜 Lượt tối đa: " .. MAX_LUOT_CNKB .. " lần")
    
    local tongChapNhan = 0
    
    local danhSachNick = layDanhSachCrane()
    local offset = NICK_BAT_DAU -- 0 = Default (1), 1 = Nick 1 (2), ...
    for nickIndex = 1, SO_NICK_CNKB do
        local idx = ((nickIndex - 1 + offset) % #danhSachNick) + 1
        local tenPhanVung = (#danhSachNick > 0) and danhSachNick[idx] or "Default"

        log("")
        logScreen("👤 NICK " .. nickIndex .. "/" .. SO_NICK_CNKB .. " | 📂 " .. tenPhanVung, true)
        
        -- Reset mạng và chuyển nick
        resetMang()
        sleep(1)
        
        chuyenNick(tenPhanVung)
        nghi(1, "Chuẩn bị vào Facebook")
        
        if not moFacebook() then
            log("⚠️ Loi mo Facebook, bo qua nick nay")
        else
            sleep(1)
            
            -- Tìm và tap vào Friends (qua Menu nếu cần)
        if not timVaTapFriends() then
            log("⏭️ Nick " .. nickIndex .. " khong vao duoc Friends, bo qua")
        else
            sleep(2)
            
            -- Liên tục tìm Confirm và tap đến khi hết
            local daChapNhan = 0
            local luotKhongCo = 0
            
            while true do
                logScreen("🔍 Đang tìm lời mời kết bạn...", true)
                local cacNutConfirm = timTatCaConfirm()
                
                if #cacNutConfirm > 0 then
                    luotKhongCo = 0
                    for i = 1, #cacNutConfirm do
                        daChapNhan = daChapNhan + 1
                        logScreen("🤝 Đã chấp nhận: " .. daChapNhan .. " lời mời", true)
                        tap(cacNutConfirm[i].x, cacNutConfirm[i].y)
                        sleep(DELAY_CNKB)
                    end
                else
                    luotKhongCo = luotKhongCo + 1
                    log("⚠️ Khong tim thay Confirm (" .. luotKhongCo .. "/" .. MAX_LUOT_CNKB .. ")")
                    
                    if luotKhongCo >= MAX_LUOT_CNKB then
                        logScreen("⏭️ Không thấy thêm lời mời nào", true)
                        log("💀 Da dat gioi han luot khong thay nut Confirm (" .. MAX_LUOT_CNKB .. "/" .. MAX_LUOT_CNKB .. ")")
                        break
                    end
                    logScreen("📜 Đang lướt tìm thêm...", true)
                    luotManHinhCNKB()
                end
                sleep(1)
            end
            
            tongChapNhan = tongChapNhan + daChapNhan
            log("📊 Nick " .. nickIndex .. " da CHAP NHAN: " .. daChapNhan .. " loi moi")
        end
        end
        
        -- Đóng Facebook
        dongFacebook()
        sleep(1)
        
        if nickIndex < SO_NICK_CNKB then
            nghi(5, "Nghỉ giải lao giữa các nick")
        end
    end
    
    logScreen("✅ HOÀN TẤT CHẤP NHẬN KẾT BẠN", true)
    log("📊 TỔNG CHẤP NHẬN: " .. tongChapNhan .. " lời mời")
    log("==========================================")
    logScreen("Hoàn tất! Đã chấp nhận: " .. tongChapNhan .. " lời mời", true)
end


-- ============================================
-- HỆ THỐNG QUẢN LÝ KEY ONLINE (SERVER API)
-- ============================================
-- [QUAN TRỌNG] THAY ĐỔI ĐƯỜNG LINK GOOGLE APPS SCRIPT CỦA BẠN VÀO ĐÂY:
local API_URL = "https://script.google.com/macros/s/AKfycbwPxSXMEwL5MnuIxi1y_INFNtBcfGb_QI69nzucAgh5gNxTeTruQxeWNy0UFfRQ4S9dsw/exec"

-- Kiểm tra Mã Máy của bản thân
local function kiemTraMaMayOnline()
    local deviceID = "UNKNOWN"
    if getSN then deviceID = getSN() end
    
    local url = API_URL .. "?action=check&device_id=" .. deviceID
    
    local ok, r = pcall(function() return httpGet(url) end)
    if not ok or not r then return false, "Lỗi kết nối máy chủ quản lý Key!" end
    
    local response = ""
    if type(r) == "table" then response = r.body or r.data or r[1] or ""
    elseif type(r) == "string" then response = r end
    
    local status, message = response:match("^([^|]+)|(.*)$")
    if status == "OK" then
        return true, tonumber(message)
    else
        return false, message or "Lỗi từ máy chủ không xác định!"
    end
end

-- Hết phần quản lý key cũ. Quản lý bản quyền hiện tại qua Google Sheets.

local function xacThucKey()
    local deviceID = "UNKNOWN"
    if getSN then deviceID = getSN() end

    toast("🔄 Đang kiểm tra bản quyền...")
    local ok, msgOrTime = kiemTraMaMayOnline()

    -- TRƯỜNG HỢP 1: ĐÃ KÍCH HOẠT THÀNH CÔNG
    if ok then
        local expDateStr = os.date("%d/%m/%Y %H:%M:%S", msgOrTime)
        _G.EXP_TIMESTAMP = msgOrTime
        
        -- Hiện thông báo chào mừng và HSD (3 giây tự mất)
        toast("✅ BẢN QUYỀN HỢP LỆ\n⏳ HSD: " .. expDateStr, 3)
        return true
    end

    -- TRƯỜNG HỢP 2: CHƯA KÍCH HOẠT (Hoặc lỗi)
    log("------------------------------------------")
    log("❌ LỖI BẢN QUYỀN: " .. tostring(msgOrTime))
    log("🆔 MÃ MÁY: " .. deviceID)
    log("------------------------------------------")

    local msg = "MÁY CHƯA ĐƯỢC KÍCH HOẠT!\n\n" ..
                "Mã máy: " .. deviceID .. "\n" ..
                "Lý do: " .. tostring(msgOrTime) .. "\n\n" ..
                "Hãy gửi mã trên cho Admin để kích hoạt."
    
    dialogInput("❌ CHƯA KÍCH HOẠT", msg, deviceID)
    
    if clipText then clipText(deviceID) elseif copyText then copyText(deviceID) end
    toast("📋 Đã copy Mã Máy vào bộ nhớ tạm!")
    return false
end

-- ============================================
-- TƯƠNG TÁC BÀI VIẾT CHỈ ĐỊNH
-- ============================================

-- ========== HÀM LƯỚT TÌM ẢNH (DÀNH CHO TƯƠNG TÁC POST) ==========
local function findImageWithScroll_Post(imagePath, maxScroll)
    for attempt = 1, maxScroll do
        local x, y = findImage(imagePath, 1)
        if x and y then
            return x, y, attempt
        else
            if attempt < maxScroll then
                swipe(200, 500, 200, 300, 1)
                sleep(INTERACT_SCROLL_DELAY)
            end
        end
    end
    return nil, nil, maxScroll
end

-- ========== HÀM TÌM MENU VỚI THỬ LẠI (DÀNH CHO TƯƠNG TÁC POST) ==========
local function findMenuWithRetry_Post(tenCamXuc, menuPath)
    local MAX_RETRY_MENU = 3
    local RETRY_DELAY = 3
    for retry = 1, MAX_RETRY_MENU do
        logScreen("🔍 Đang tìm cảm xúc: " .. tenCamXuc, true)
        log("🔍 Tim cam xuc: " .. tenCamXuc .. " (LAN " .. retry .. "/" .. MAX_RETRY_MENU .. ")")
        local x, y = findImage(menuPath, 1)
        
        if x and y then
            log("✅ TIM THAY MENU " .. tenCamXuc .. " TAI: (" .. x .. ", " .. y .. ")")
            return x, y
        else
            if retry < MAX_RETRY_MENU then
                log("⚠️ KHONG THAY MENU " .. tenCamXuc .. ", THU LAI SAU " .. RETRY_DELAY .. "s...")
                sleep(RETRY_DELAY)
            end
        end
    end
    logScreen("❌ KHÔNG TÌM THẤY MENU " .. tenCamXuc, true)
    log("❌ KHONG TIM THAY MENU " .. tenCamXuc .. " SAU " .. MAX_RETRY_MENU .. " LAN THU")
    return nil, nil
end

-- ========== HÀM XỬ LÝ CẢM XÚC (LONG PRESS + CHỌN MENU) ==========
local function xuLyCamXuc_Post(tenCamXuc, menuPath, imagePathPost)
    local x, y, attempts = findImageWithScroll_Post(imagePathPost, INTERACT_MAX_ATTEMPTS)
    
    if x and y then
        longPress(x, y, 1.5)
        sleep(2)
        
        local x2, y2 = findMenuWithRetry_Post(tenCamXuc, menuPath)
        if x2 and y2 then
            tap(x2, y2)
            sleep(1)
            logScreen("❤️ ĐÃ " .. tenCamXuc .. " THÀNH CÔNG!", true)
        else
            logScreen("❌ KHÔNG CHỌN ĐƯỢC CẢM XÚC", true)
        end
    else
        logScreen("❌ KHÔNG TÌM THẤY NÚT LIKE/POST", true)
    end
end

-- ========== CHẠY TƯƠNG TÁC BÀI VIẾT ==========
local function thucHienInteractPost()
    logScreen("🚀 TƯƠNG TÁC BÀI VIẾT", true)
    logScreen("📂 CHẠY TỪ NICK " .. NICK_BAT_DAU .. " ĐẾN NICK " .. (NICK_BAT_DAU + INTERACT_NICKS), true)
    log("🔗 URL: " .. INTERACT_URL)
    log("👥 Số nick: " .. INTERACT_NICKS)
    
    local imagePathPost = "crop_1777213229157.png"
    local menuTYM = "crop_1777188485023.png"
    local menuTHUONG = "crop_1777213812741.png"
    local menuHAHA = "crop_1777213949549.png"
    local menuBUON = "crop_1777214041805.png"

    local danhSachNick = layDanhSachCrane()
    local offset = NICK_BAT_DAU
    for nickIndex = 1, INTERACT_NICKS do
        local idx = ((nickIndex - 1 + offset) % #danhSachNick) + 1
        local tenPhanVung = (#danhSachNick > 0) and danhSachNick[idx] or "Default"

        log("")
        logScreen("👤 NICK " .. nickIndex .. "/" .. INTERACT_NICKS .. " | 📂 " .. tenPhanVung, true)
        
        resetMang()
        chuyenNick(tenPhanVung)
        if not moFacebook() then
            log("⚠️ Loi mo Facebook, bo qua nick nay")
        else
            log("📱 Dang mo bai viet...")
            openURL(INTERACT_URL)
            sleep(5)
            log("✅ Da mo bai viet")
            sleep(2)

            -- Xử lý Random
            local listEnabled = {}
            if INTERACT_LIKE == 1 then table.insert(listEnabled, "LIKE") end
            if INTERACT_TYM == 1 then table.insert(listEnabled, "TYM") end
            if INTERACT_THUONG == 1 then table.insert(listEnabled, "THUONG") end
            if INTERACT_HAHA == 1 then table.insert(listEnabled, "HAHA") end
            if INTERACT_BUON == 1 then table.insert(listEnabled, "BUON") end

            if #listEnabled == 0 then
                log("⚠️ Khong co cam xuc nao duoc bat!")
            else
                if INTERACT_RANDOM == 1 then
                    local randomChoice = listEnabled[math.random(1, #listEnabled)]
                    log("🎲 Random chon: " .. randomChoice)
                    if randomChoice == "LIKE" then
                        local x, y, attempts = findImageWithScroll_Post(imagePathPost, INTERACT_MAX_ATTEMPTS)
                        if x and y then
                            tap(x, y)
                            sleep(1)
                            logScreen("❤️ ĐÃ LIKE THÀNH CÔNG!", true)
                        end
                    elseif randomChoice == "TYM" then xuLyCamXuc_Post("TYM", menuTYM, imagePathPost)
                    elseif randomChoice == "THUONG" then xuLyCamXuc_Post("THUONG THUONG", menuTHUONG, imagePathPost)
                    elseif randomChoice == "HAHA" then xuLyCamXuc_Post("HAHA", menuHAHA, imagePathPost)
                    elseif randomChoice == "BUON" then xuLyCamXuc_Post("BUON", menuBUON, imagePathPost)
                    end
                else
                    -- Chạy tuần tự như logic gốc
                    if INTERACT_LIKE == 1 then
                        local x, y, attempts = findImageWithScroll_Post(imagePathPost, INTERACT_MAX_ATTEMPTS)
                        if x and y then
                            tap(x, y)
                            sleep(1)
                            logScreen("❤️ ĐÃ LIKE THÀNH CÔNG!", true)
                        end
                    end
                    if INTERACT_TYM == 1 then xuLyCamXuc_Post("TYM", menuTYM, imagePathPost) end
                    if INTERACT_THUONG == 1 then xuLyCamXuc_Post("THUONG THUONG", menuTHUONG, imagePathPost) end
                    if INTERACT_HAHA == 1 then xuLyCamXuc_Post("HAHA", menuHAHA, imagePathPost) end
                    if INTERACT_BUON == 1 then xuLyCamXuc_Post("BUON", menuBUON, imagePathPost) end
                end
            end
        end
        dongFacebook()
        if nickIndex < INTERACT_NICKS then
            nghi(5, "Nghỉ đổi nick")
        end
    end
    logScreen("✅ HOÀN TẤT TƯƠNG TÁC BÀI VIẾT", true)
    logScreen("Hoàn tất tương tác bài viết!", true)
end

-- ========== MENU TƯƠNG TÁC BÀI VIẾT ==========
local function menuInteractPost()
    while true do
        -- Icon cảm xúc đang bật
        local camXucBat = ""
        if INTERACT_LIKE == 1 then camXucBat = camXucBat .. "👍" end
        if INTERACT_TYM == 1 then camXucBat = camXucBat .. "❤️" end
        if INTERACT_THUONG == 1 then camXucBat = camXucBat .. "🥰" end
        if INTERACT_HAHA == 1 then camXucBat = camXucBat .. "😆" end
        if INTERACT_BUON == 1 then camXucBat = camXucBat .. "😢" end
        if camXucBat == "" then camXucBat = "chưa chọn" end

        -- URL rút gọn còn 20 ký tự
        local urlHien = INTERACT_URL
        if string.len(urlHien) > 20 then
            urlHien = string.sub(urlHien, 1, 20) .. "…"
        end

        local title = "🎯 Tương tác bài viết\n"
            .. "· Nick: " .. INTERACT_NICKS .. "  · Random: " .. (INTERACT_RANDOM == 1 and "bật" or "tắt") .. "\n"
            .. "· Link: " .. urlHien .. "\n"
            .. "· Cảm xúc: " .. camXucBat

        local choice = dialogChoice(title,
            "🔗 Nhập link bài viết",
            "👥 Số nick cần chạy: " .. INTERACT_NICKS,
            "🚩 Nick bắt đầu: " .. NICK_BAT_DAU,
            "🎲 Random cảm xúc: " .. (INTERACT_RANDOM == 1 and "BẬT ✅" or "TẮT ❌"),
            "👍 LIKE: " .. (INTERACT_LIKE == 1 and "BẬT ✅" or "TẮT ❌"),
            "❤️ TYM: " .. (INTERACT_TYM == 1 and "BẬT ✅" or "TẮT ❌"),
            "🥰 THƯƠNG THƯƠNG: " .. (INTERACT_THUONG == 1 and "BẬT ✅" or "TẮT ❌"),
            "😆 HAHA: " .. (INTERACT_HAHA == 1 and "BẬT ✅" or "TẮT ❌"),
            "😢 BUỒN: " .. (INTERACT_BUON == 1 and "BẬT ✅" or "TẮT ❌"),
            "🔢 Số lần lướt tìm: " .. INTERACT_MAX_ATTEMPTS,
            "⏳ Delay giữa các lần: " .. INTERACT_SCROLL_DELAY .. "s",
            "──────────────",
            "🚀 BẮT ĐẦU CHẠY",
            "◀️ Quay lại"
        )
        
        if not choice or choice:find("Quay lại") then return "back"
        elseif choice:find("Nhập link") then
            local urlInput = dialogInput("Link bài viết", "Dán link bài viết vào đây:", INTERACT_URL)
            if urlInput and urlInput ~= "" then INTERACT_URL = urlInput end
        elseif choice:find("Số nick") then
            local n = dialogInput("Số nick cần chạy", "Nhập số lượng:", tostring(INTERACT_NICKS))
            if n and tonumber(n) then INTERACT_NICKS = tonumber(n) end
        elseif choice:find("Nick bắt đầu") then
            local input = dialogInput("Nick bắt đầu", "STT nick bắt đầu chạy:", tostring(NICK_BAT_DAU))
            if input then
                local num = tonumber(input)
                if num and num >= 0 then
                    NICK_BAT_DAU = math.floor(num)
                    toast("🚩 Nick bắt đầu: " .. NICK_BAT_DAU)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end
        elseif choice:find("Random") then INTERACT_RANDOM = (INTERACT_RANDOM == 1) and 0 or 1
        elseif choice:find("LIKE") then INTERACT_LIKE = (INTERACT_LIKE == 1) and 0 or 1
        elseif choice:find("TYM") then INTERACT_TYM = (INTERACT_TYM == 1) and 0 or 1
        elseif choice:find("THƯƠNG THƯƠNG") then INTERACT_THUONG = (INTERACT_THUONG == 1) and 0 or 1
        elseif choice:find("HAHA") then INTERACT_HAHA = (INTERACT_HAHA == 1) and 0 or 1
        elseif choice:find("BUỒN") then INTERACT_BUON = (INTERACT_BUON == 1) and 0 or 1
        elseif choice:find("Số lần lướt tìm") then
            local n = dialogInput("Số lần lướt tối đa", "Nhập số lần:", tostring(INTERACT_MAX_ATTEMPTS))
            if n and tonumber(n) then INTERACT_MAX_ATTEMPTS = math.floor(tonumber(n)) end
        elseif choice:find("Delay giữa các lần") then
            local n = dialogInput("Delay cuộn (giây)", "Nhập số giây:", tostring(INTERACT_SCROLL_DELAY))
            if n and tonumber(n) then INTERACT_SCROLL_DELAY = math.floor(tonumber(n)) end
        elseif choice:find("BẮT ĐẦU CHẠY") then
            if INTERACT_URL == "" then
                toast("⚠️ Vui lòng nhập link bài viết!")
            else
                local confirm = dialogChoice(
                    "🚀 XÁC NHẬN CHẠY\n\n"
                    .. "👥 Chạy: " .. INTERACT_NICKS .. " nick\n"
                    .. "🎯 Random: " .. (INTERACT_RANDOM == 1 and "BẬT" or "TẮT"),
                    "✅ Chạy ngay!",
                    "◀️ Quay lại"
                )
                if confirm and confirm:find("Chạy ngay") then
                    luuCauHinh()
                    return "interact_post"
                end
            end
        end
    end
end

-- ================================================================
-- ║  PHẦN CMT BÀI VIẾT CHỈ ĐỊNH                                ║
-- ================================================================

-- ========== HÀM LẤY NỘI DUNG COMMENT ==========
local function getNoiDungCMT()
    if #CMT_LIST == 0 then return "Hay quá!" end
    if CMT_MODE == "random" then
        local idx = math.random(1, #CMT_LIST)
        log("🎲 Random (" .. idx .. "/" .. #CMT_LIST .. "): " .. CMT_LIST[idx])
        return CMT_LIST[idx]
    else
        local noiDung = CMT_LIST[CMT_CURRENT_INDEX]
        log("🔄 Tuần tự (" .. CMT_CURRENT_INDEX .. "/" .. #CMT_LIST .. "): " .. noiDung)
        CMT_CURRENT_INDEX = CMT_CURRENT_INDEX + 1
        if CMT_CURRENT_INDEX > #CMT_LIST then
            CMT_CURRENT_INDEX = 1
            log("🔄 Hết list, quay lại từ đầu")
        end
        return noiDung
    end
end

-- ========== THỰC HIỆN CMT BÀI VIẾT CHỈ ĐỊNH ==========
local function thucHienCMTBaiViet()
    -- Load lại nội dung từ file trước khi chạy
    CMT_LIST = readLinesFromFile(CMT_FILE_PATH, CMT_LIST)
    
    local commentBoxImage = "crop_1777343201954.png"
    local postButtonImage = "crop_1777343840162.png"

    logScreen("💬 BẮT ĐẦU CMT BÀI VIẾT", true)
    logScreen("📂 CHẠY TỪ NICK " .. NICK_BAT_DAU .. " ĐẾN NICK " .. (NICK_BAT_DAU + CMT_SO_NICK), true)
    log("👥 Số nick: " .. CMT_SO_NICK)
    log("🔗 URL: " .. CMT_URL)
    log("🎲 Mode: " .. CMT_MODE)
    log("📝 Số nội dung: " .. #CMT_LIST)

    CMT_CURRENT_INDEX = 1  -- Reset index sequential mỗi lần chạy

    local danhSachNick = layDanhSachCrane()
    local offset = NICK_BAT_DAU
    for nickIndex = 1, CMT_SO_NICK do
        local idx = ((nickIndex - 1 + offset) % #danhSachNick) + 1
        local tenPhanVung = (#danhSachNick > 0) and danhSachNick[idx] or "Default"

        log("")
        logScreen("👤 NICK " .. nickIndex .. "/" .. CMT_SO_NICK .. " | 📂 " .. tenPhanVung, true)

        resetMang()
        sleep(1)
        chuyenNick(tenPhanVung)
        sleep(1)

        if not moFacebook() then
            log("⚠️ Lỗi mở Facebook, bỏ qua nick này")
        else
            log("📱 Đang mở bài viết...")
            openURL(CMT_URL)
            sleep(5)
            log("✅ Đã mở bài viết")
            sleep(2)

            log("🔍 Tìm ô nhập comment (tối đa " .. CMT_MAX_ATTEMPTS .. " lần)...")
            local found = false

            for attempt = 1, CMT_MAX_ATTEMPTS do
                logScreen("🔍 Tìm ô comment (" .. attempt .. "/" .. CMT_MAX_ATTEMPTS .. ")", true)
                log("🔄 Lần thử " .. attempt .. "/" .. CMT_MAX_ATTEMPTS)

                local x, y = findImage(commentBoxImage, 1)

                if x and y then
                    log("✅ Tìm thấy ô comment tại: (" .. x .. ", " .. y .. ")")
                    sleep(CMT_TAP_DELAY)

                    log("👉 Đang tap vào ô comment...")
                    tap(x, y)
                    sleep(1)
                    sleep(2)

                    local noiDung = getNoiDungCMT()
                    log("📝 Đang nhập nội dung comment...")
                    inputText(noiDung)
                    sleep(1)
                    log("✅ Đã nhập: " .. noiDung)
                    sleep(3)

                    log("🔍 Tìm nút Đăng bình luận...")
                    local foundPost = false

                    for retry = 1, CMT_MAX_RETRY_POST do
                        local x2, y2 = findImage(postButtonImage, 1)
                        if x2 and y2 then
                            log("✅ Tìm thấy nút Đăng tại: (" .. x2 .. ", " .. y2 .. ")")
                            tap(x2, y2)
                            sleep(1)
                            sleep(5)
                            logScreen("✅ ĐÃ ĐĂNG BÌNH LUẬN! (" .. nickIndex .. "/" .. CMT_SO_NICK .. ")", true)
                            foundPost = true
                            break
                        else
                            if retry < CMT_MAX_RETRY_POST then
                                log("⚠️ Chưa thấy nút Đăng, thử lại " .. retry .. "/" .. CMT_MAX_RETRY_POST)
                                sleep(2)
                            end
                        end
                    end

                    if not foundPost then
                        logScreen("❌ Không tìm thấy nút Đăng!", true)
                        log("❌ Không tìm thấy nút Đăng sau " .. CMT_MAX_RETRY_POST .. " lần thử")
                    end

                    found = true
                    break
                else
                    if attempt < CMT_MAX_ATTEMPTS then
                        log("⚠️ Chưa thấy ô comment, đang cuộn...")
                        swipe(200, 500, 200, 200, 1)
                        sleep(CMT_SCROLL_DELAY)
                    end
                end
            end

            if not found then
                logScreen("❌ Không tìm thấy ô comment!", true)
                log("❌ Không tìm thấy ô comment sau " .. CMT_MAX_ATTEMPTS .. " lần thử")
            end
        end

        dongFacebook()
        if nickIndex < CMT_SO_NICK then
            nghi(5, "Nghỉ đổi nick")
        end
    end

    logScreen("✅ HOÀN TẤT CMT BÀI VIẾT", true)
    log("==========================================")
end

-- ========== MENU CMT BÀI VIẾT CHỈ ĐỊNH ==========
local function menuCMTBaiViet()
    while true do
        -- Load lại nội dung từ file để hiển thị số lượng chính xác
        CMT_LIST = readLinesFromFile(CMT_FILE_PATH, CMT_LIST)
        local urlHien = CMT_URL
        if string.len(urlHien) > 20 then
            urlHien = string.sub(urlHien, 1, 20) .. "…"
        end
        if urlHien == "" then urlHien = "chưa nhập" end

        local title = "💬 CMT bài viết chỉ định\n"
            .. "· Nick: " .. CMT_SO_NICK .. "  · Mode: " .. (CMT_MODE == "random" and "ngẫu nhiên" or "tuần tự") .. "\n"
            .. "· Link: " .. urlHien .. "\n"
            .. "· Nội dung: " .. #CMT_LIST .. " câu"

        local choice = dialogChoice(title,
            "🔗 Nhập link bài viết",
            "👥 Số nick cần chạy: " .. CMT_SO_NICK,
            "🚩 Nick bắt đầu: " .. NICK_BAT_DAU,
            "🎲 Chế độ: " .. (CMT_MODE == "random" and "Ngẫu nhiên 🎲" or "Tuần tự 🔄"),
            "📝 Xem/Sửa danh sách nội dung",
            "🔢 Số lần lướt tìm: " .. CMT_MAX_ATTEMPTS,
            "⏳ Delay giữa các lần: " .. CMT_SCROLL_DELAY .. "s",
            "──────────────",
            "🚀 BẮT ĐẦU CHẠY",
            "◀️ Quay lại"
        )

        if not choice or choice:find("Quay lại") then
            return "back"
        elseif choice:find("Nhập link") then
            local urlInput = dialogInput("Link bài viết", "Dán link bài viết vào đây:", CMT_URL)
            if urlInput and urlInput ~= "" then CMT_URL = urlInput end
        elseif choice:find("Số nick") then
            local n = dialogInput("Số nick cần chạy", "Nhập số lượng:", tostring(CMT_SO_NICK))
            if n and tonumber(n) then CMT_SO_NICK = math.floor(tonumber(n)) end
        elseif choice:find("Nick bắt đầu") then
            local input = dialogInput("Nick bắt đầu", "STT nick bắt đầu chạy:", tostring(NICK_BAT_DAU))
            if input then
                local num = tonumber(input)
                if num and num >= 0 then
                    NICK_BAT_DAU = math.floor(num)
                    toast("🚩 Nick bắt đầu: " .. NICK_BAT_DAU)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end
        elseif choice:find("Chế độ") then
            CMT_MODE = (CMT_MODE == "random") and "sequential" or "random"
            toast("Mode: " .. (CMT_MODE == "random" and "Ngẫu nhiên 🎲" or "Tuần tự 🔄"))
        elseif choice:find("Xem/Sửa") then
            local page = 1
            local pageSize = 20
            while true do
                local startIdx = (page - 1) * pageSize + 1
                local endIdx = math.min(page * pageSize, #CMT_LIST)
                local displayLines = {}
                for i = startIdx, endIdx do
                    local content = CMT_LIST[i]
                    table.insert(displayLines, i .. ". " .. content)
                end
                local preview = table.concat(displayLines, "\n")
                local totalPage = math.ceil(#CMT_LIST / pageSize)
                
                local msg = "📝 DANH SÁCH NỘI DUNG CMT\n"
                    .. "📄 Trang: " .. page .. "/" .. totalPage .. "\n"
                    .. "📊 Tổng: " .. #CMT_LIST .. " câu\n"
                    .. "────────────────\n"
                    .. preview .. "\n"
                    .. "────────────────\n"
                    .. "⚠️ Vui lòng vào file cmt.txt để sửa nội dung!"
                
                local buttons = {"OK ✅"}
                if page < totalPage then table.insert(buttons, "Trang tiếp ➡️") end
                if page > 1 then table.insert(buttons, "⬅️ Trang trước") end
                
                local res = dialogChoice(msg, unpack(buttons))
                if not res or res == "OK ✅" then
                    break
                elseif res == "Trang tiếp ➡️" then
                    page = page + 1
                elseif res == "⬅️ Trang trước" then
                    page = page - 1
                end
            end
        elseif choice:find("Số lần lướt tìm") then
            local n = dialogInput("Số lần lướt tối đa", "Nhập số lần:", tostring(CMT_MAX_ATTEMPTS))
            if n and tonumber(n) then CMT_MAX_ATTEMPTS = math.floor(tonumber(n)) end
        elseif choice:find("Delay giữa các lần") then
            local n = dialogInput("Delay cuộn (giây)", "Nhập số giây:", tostring(CMT_SCROLL_DELAY))
            if n and tonumber(n) then CMT_SCROLL_DELAY = math.floor(tonumber(n)) end
        elseif choice:find("BẮT ĐẦU CHẠY") then
            if CMT_URL == "" then
                toast("⚠️ Vui lòng nhập link bài viết!")
            elseif #CMT_LIST == 0 then
                toast("⚠️ Danh sách comment trống!")
            else
                local confirm = dialogChoice(
                    "🚀 XÁC NHẬN CMT\n\n"
                    .. "👥 Chạy: " .. CMT_SO_NICK .. " nick\n"
                    .. "🎲 Mode: " .. CMT_MODE .. "\n"
                    .. "📝 " .. #CMT_LIST .. " câu comment",
                    "✅ Chạy ngay!",
                    "◀️ Quay lại"
                )
                if confirm and confirm:find("Chạy ngay") then
                    return "cmt_bai_viet"
                end
            end
        end
    end
end

-- ================================================================
-- ║  PHẦN CHIA SẺ BÀI VIẾT CHỈ ĐỊNH                            ║
-- ================================================================

-- ========== THỰC HIỆN CHIA SẺ BÀI VIẾT ==========
local function thucHienShareBaiViet()
    local shareButtonImage = "crop_1777348725692.png"

    logScreen("────────────────────\n🚀 BẮT ĐẦU CHIA SẺ BÀI VIẾT\n────────────────────", true)
    logScreen("📂 CHẠY TỪ NICK " .. NICK_BAT_DAU .. " ĐẾN NICK " .. (NICK_BAT_DAU + SHARE_SO_NICK), true)
    log("👥 Số nick: " .. SHARE_SO_NICK)
    log("🔗 URL: " .. SHARE_URL)

    local danhSachNick = layDanhSachCrane()
    local offset = NICK_BAT_DAU
    for nickIndex = 1, SHARE_SO_NICK do
        local idx = ((nickIndex - 1 + offset) % #danhSachNick) + 1
        local tenPhanVung = (#danhSachNick > 0) and danhSachNick[idx] or "Default"

        log("")
        logScreen("👤 NICK " .. nickIndex .. "/" .. SHARE_SO_NICK .. " | 📂 " .. tenPhanVung, true)

        resetMang()
        sleep(1)
        chuyenNick(tenPhanVung)
        sleep(1)

        if not moFacebook() then
            log("⚠️ Lỗi mở Facebook, bỏ qua nick này")
        else
            log("📱 Đang mở bài viết...")
            openURL(SHARE_URL)
            sleep(5)
            log("✅ Đã mở bài viết")
            sleep(2)

            log("🔍 Tìm nút Chia sẻ...")
            local tapSuccess = false

            for attempt = 1, SHARE_MAX_ATTEMPTS do
                logScreen("🔍 Tìm nút Chia sẻ (" .. attempt .. "/" .. SHARE_MAX_ATTEMPTS .. ")", true)
                local x, y = findImage(shareButtonImage, 1)
                if x and y then
                    log("✅ Tìm thấy nút Chia sẻ tại: (" .. x .. ", " .. y .. ")")
                    sleep(SHARE_TAP_DELAY)
                    
                    local result = tapImage(shareButtonImage, 3, 1)
                    if result then
                        log("✅ Đã tap nút Chia sẻ")
                        for check = 1, SHARE_MAX_CHECK do
                            sleep(2)
                            if findText("Say something about this", 1) or findText("say something about this", 1) then
                                log("✅ Thấy menu chia sẻ!")
                                tapSuccess = true
                                break
                            else
                                if check < SHARE_MAX_CHECK then
                                    log("⚠️ Chưa thấy menu, tap lại tọa độ...")
                                    tap(x, y)
                                end
                            end
                        end
                        break
                    else
                        log("⚠️ Không tap được, lướt nhẹ lên...")
                        swipe(200, 400, 200, 300, 0.5)
                        sleep(1)
                        log("👉 Thử tap lại...")
                        result = tapImage(shareButtonImage, 3, 1)
                        if result then
                            log("✅ Tap thành công sau khi lướt")
                            tapSuccess = true
                            break
                        end
                    end
                else
                    if attempt < SHARE_MAX_ATTEMPTS then
                        log("⚠️ Không thấy nút Share, đang cuộn...")
                        swipe(200, 500, 200, 200, 1)
                        sleep(SHARE_SCROLL_DELAY)
                    end
                end
            end

            if tapSuccess then
                sleep(2)
                log("🔍 Kiểm tra quyền chia sẻ...")
                if findText("Friends", 1) then
                    log("⚠️ Đang ở chế độ FRIENDS, chuyển sang PUBLIC...")
                    tapText("Friends", 5, 1)
                    sleep(2)
                    tapText("Public", 5, 1)
                    sleep(1)
                    tapText("Done", 5, 1)
                    sleep(2)
                end
                
                log("🚀 Đang tap Share Now...")
                tapText("Share Now", 5, 1)
                sleep(7)
                logScreen("✅ ĐÃ CHIA SẺ THÀNH CÔNG! (" .. nickIndex .. "/" .. SHARE_SO_NICK .. ")", true)
            else
                logScreen("❌ Không thể chia sẻ bài viết!", true)
            end
        end

        dongFacebook()
        if nickIndex < SHARE_SO_NICK then
            nghi(5, "Nghỉ đổi nick")
        end
    end
    logScreen("✅ HOÀN TẤT CHIA SẺ BÀI VIẾT", true)
end

-- ========== MENU CHIA SẺ BÀI VIẾT ==========
local function menuShareBaiViet()
    while true do
        local urlHien = SHARE_URL
        if string.len(urlHien) > 20 then
            urlHien = string.sub(urlHien, 1, 20) .. "…"
        end
        if urlHien == "" then urlHien = "chưa nhập" end

        local title = "🚀 Chia sẻ bài viết chỉ định\n"
            .. "· Nick: " .. SHARE_SO_NICK .. "\n"
            .. "· Cuộn tối đa: " .. SHARE_MAX_ATTEMPTS .. " lần\n"
            .. "· Link: " .. urlHien

        local choice = dialogChoice(title,
            "🔗 Nhập link bài viết",
            "👥 Số nick cần chạy: " .. SHARE_SO_NICK,
            "🚩 Nick bắt đầu: " .. NICK_BAT_DAU,
            "🔢 Số lần lướt tìm: " .. SHARE_MAX_ATTEMPTS,
            "⏳ Delay giữa các lần: " .. SHARE_SCROLL_DELAY .. "s",
            "──────────────",
            "🚀 BẮT ĐẦU CHẠY",
            "◀️ Quay lại"
        )

        if not choice or choice:find("Quay lại") then
            return "back"
        elseif choice:find("Nhập link") then
            local urlInput = dialogInput("Link bài viết", "Dán link bài viết vào đây:", SHARE_URL)
            if urlInput and urlInput ~= "" then SHARE_URL = urlInput end
        elseif choice:find("Số nick") then
            local n = dialogInput("Số nick cần chạy", "Nhập số lượng:", tostring(SHARE_SO_NICK))
            if n and tonumber(n) then SHARE_SO_NICK = math.floor(tonumber(n)) end
        elseif choice:find("Nick bắt đầu") then
            local input = dialogInput("Nick bắt đầu", "STT nick bắt đầu chạy:", tostring(NICK_BAT_DAU))
            if input then
                local num = tonumber(input)
                if num and num >= 0 then
                    NICK_BAT_DAU = math.floor(num)
                    toast("🚩 Nick bắt đầu: " .. NICK_BAT_DAU)
                else
                    toast("⚠️ Giá trị không hợp lệ!")
                end
            end
        elseif choice:find("Số lần lướt tìm") then
            local n = dialogInput("Số lần lướt tối đa", "Nhập số lần:", tostring(SHARE_MAX_ATTEMPTS))
            if n and tonumber(n) then SHARE_MAX_ATTEMPTS = math.floor(tonumber(n)) end
        elseif choice:find("Delay giữa các lần") then
            local n = dialogInput("Delay cuộn (giây)", "Nhập số giây:", tostring(SHARE_SCROLL_DELAY))
            if n and tonumber(n) then SHARE_SCROLL_DELAY = math.floor(tonumber(n)) end
        elseif choice:find("BẮT ĐẦU CHẠY") then
            if SHARE_URL == "" then
                toast("⚠️ Vui lòng nhập link bài viết!")
            else
                local confirm = dialogChoice(
                    "🚀 XÁC NHẬN CHIA SẺ\n\n"
                    .. "👥 Chạy: " .. SHARE_SO_NICK .. " nick\n"
                    .. "🔗 " .. urlHien,
                    "✅ Chạy ngay!",
                    "◀️ Quay lại"
                )
                if confirm and confirm:find("Chạy ngay") then
                    return "share_bai_viet"
                end
            end
        end
    end
end

-- ================================================================
-- ║  PHẦN NẠP NICK (chạy nếu chọn "Nạp Nick")                  ║
-- ║  Logic gốc KHÔNG THAY ĐỔI                                   ║
-- ================================================================

local function thucHienNapNick()

-- ========== HÀM RESET MẠNG (NẠP NICK) ==========
local function resetMangNN()
    while true do
        local success, err = pcall(function()
            setAirplaneMode(true)
            nghi(3, "BẬT CHẾ ĐỘ MÁY BAY")
            setAirplaneMode(false)
            nghi(8, "ĐANG ĐỢI MẠNG")
        end)
        
        local newIP = "Không xác định"
        -- Thử lấy IP tối đa 6 lần
        for retry = 1, 6 do
            newIP = getIP()
            if newIP ~= "Không xác định" then break end
            logScreen("⏳ Đang chờ lấy IP mới (" .. (retry*5) .. "s)...", true)
            sleep(5)
        end
        
        if newIP ~= "Không xác định" then
            log("✅ IP mới: " .. newIP)
            logScreen("✅ ĐỔI IP THÀNH CÔNG\n📡 IP Mới: " .. newIP, true)
            sleep(2)
            return true
        else
            logScreen("❌ KHÔNG LẤY ĐƯỢC IP, ĐANG THỬ LẠI...", true)
            log("❌ Khong lay duoc IP trong Nap Nick, dang thu lai...")
            sleep(2)
        end
    end
end

-- ========== CHUYỂN NICK (NẠP NICK) ==========
local function chuyenNickNN()
    return chuyenNick() -- Dùng chung logic Crane
end

-- ========== MỞ FACEBOOK (NẠP NICK) ==========
local function moFacebookNN()
    log("📱 Dang mo Facebook...")
    local success, err = pcall(function()
        appRun("com.facebook.Facebook")
        sleep(10)
        log("✅ Da mo Facebook")
        sleep(8)
    end)
    
    if success then
        log("✅ Mo Facebook thanh cong")
        return true
    else
        log("❌ Mo Facebook that bai: " .. tostring(err))
        log("⚠️ Kiem tra lai Facebook da duoc cai dat chua?")
        return false
    end
end

-- ========== ĐÓNG FACEBOOK (NẠP NICK) ==========
local function dongFacebookNN()
    pcall(function()
        appKill("com.facebook.Facebook")
        sleep(3)
        log("✅ Da dong Facebook")
    end)
end

-- ========== HÀM LẤY MÃ 2FA TỪ SECRET ==========
local function get2faFromSecret(secret)
    if not secret or secret == "" then
        log("❌ Khong co secret 2FA")
        return nil
    end
    
    log("🔄 Dang lay ma 2FA tu API...")
    log("📝 Secret: " .. secret)
    
    local ok, r = pcall(function()
        return httpGet("https://2fa.live/tok/" .. secret)
    end)
    
    if not ok then
        log("❌ Loi ket noi API lay 2FA: " .. tostring(r))
        return nil
    end
    
    local body = nil
    if type(r) == "table" then
        body = r.body or r.data or r[1]
    elseif type(r) == "string" then
        body = r
    end
    
    if not body then
        log("❌ API tra ve rong")
        return nil
    end
    
    log("📦 Response: " .. tostring(body))
    
    local code = tostring(body):match('"token"%s*:%s*"(.-)"')
    
    if code and code ~= "" then
        log("✅ Lay duoc ma 2FA: " .. code)
        return code
    else
        log("❌ Khong parse duoc ma 2FA tu response")
        return nil
    end
end

-- ========== KIỂM TRA CẢNH BÁO AUTOMATED BEHAVIOR ==========
local function checkCanhBaoAutomated()
    if findText("We suspect automated behavior", 2) then 
        log("⚠️ PHAT HIEN CANH BAO: We suspect automated behavior on your account")
        if findText("Dismiss", 2) then
            tapText("Dismiss", 3)
            log("✅ DA NHAN DISMISS")
            sleep(2)
        end
    else
        log("✅ KHONG CO CANH BAO, TIEP TUC")
    end
end

-- ========== KIỂM TRA MÀN HÌNH 2FA ==========
local function kiemTra2FA()
    log("🔍 Kiem tra man hinh 2FA...")

    -- Kiểm tra bằng hình ảnh trước
    if findImage("crop_1776579755130.png", 1, 0.85) then
        log("👉 PHAT HIEN 2FA (bang hinh)")
        sleep(1)
        if findText("OK", 3) then
            tapText("OK", 5)
            log("✅ Da an nut OK popup 2FA")
            sleep(2)
        end
        return true
    end

    -- Chỉ kiểm tra text nếu KHÔNG tìm thấy hình
    if findText("Login Code Required", 3) then
        log("👉 PHAT HIEN 2FA (bang text 'Login Code Required')")
        sleep(1)
        if findText("OK", 3) then
            tapText("OK", 5)
            log("✅ Da an nut OK popup 2FA")
            sleep(2)
        end
        return true
    end

    log("✅ Khong phat hien man hinh 2FA")
    return false
end

-- ========== XỬ LÝ NHẬP MÃ 2FA ==========
local function xuLy2FA(secret)
    log("⚠️ Bat dau xu ly 2FA...")
    log("📝 Secret: " .. tostring(secret))
    
    sleep(1)

    if findText("Login code", 5) then
        tapText("Login code", 10)
        sleep(1)
    elseif findText("Mã đăng nhập", 5) then
        tapText("Mã đăng nhập", 10)
        sleep(1)
    else
        log("⚠️ Khong tim thay o nhap 2FA, thu tap toa do mac dinh")
        tap(200, 300)
        sleep(1)
    end

    logScreen("🔑 Đang lấy mã 2FA từ hệ thống...", true)
    local code = get2faFromSecret(secret)
    
    if not code then
        logScreen("❌ KHÔNG LẤY ĐƯỢC MÃ 2FA", true)
        log("🚫 Khong lay duoc ma 2FA")
        return false
    end
    logScreen("🎯 Đã lấy mã 2FA: " .. code, true)
    
    inputText(code)
    sleep(1)
    logScreen("🎯 Đã nhập mã 2FA: " .. code, true)
    sleep(1)
    
    if findText("Continue", 3) then
        tapText("Continue", 5)
        log("✅ Da bam nut Continue")
    elseif findText("Log in", 3) then
        tapText("Log in", 5)
        log("✅ Da bam nut Log in")
    elseif findText("Tiếp tục", 3) then
        tapText("Tiếp tục", 5)
        log("✅ Da bam nut Tiep tuc")
    elseif findText("OK", 3) then
        tapText("OK", 5)
        log("✅ Da bam nut OK")
    else
        log("⚠️ Khong tim thay nut tiep tuc")
    end
    
    sleep(10)
    checkCanhBaoAutomated()
    return true
end

-- ========== XỬ LÝ NHẬP TÀI KHOẢN + 2FA ==========
local function xuLyNhapTaiKhoan(uid, pass, twofa)
    logScreen("📝 ĐANG NHẬP TÀI KHOẢN: " .. uid, true)
    log("🔐 2FA secret: " .. (twofa ~= "" and "CO" or "KHONG CO"))
    
    -- BƯỚC 1: Nhập Email/SDT
    if findText("Phone number or email", 5) then
        log("✅ Tim thay o nhap Email/SDT")
        tapText("Phone number or email", 10)
        sleep(2)
    elseif findText("Email or Phone Number", 5) then
        log("✅ Tim thay o nhap Email/SDT (EN)")
        tapText("Email or Phone Number", 10)
        sleep(2)
    elseif findText("Số điện thoại hoặc email", 5) then
        log("✅ Tim thay o nhap SDT/Email (VN)")
        tapText("Số điện thoại hoặc email", 10)
        sleep(2)
    else
        log("⚠️ Khong tim thay o nhap, thu tap toa do mac dinh")
        tap(224, 268)
        sleep(2)
    end
    
    logScreen("👉 Đang nhập tài khoản...", true)
    inputText(uid)
    sleep(2)
    log("✅ Da nhap UID: " .. uid)
    sleep(3)
    
    -- BƯỚC 2: Tap nút Next
    if tapImage("crop_1776574976548.png", 10, 0.85) then
        log("✅ Da tap nut Next (image)")
    elseif findText("Next", 3) then
        tapText("Next", 5)
        log("✅ Da tap nut Next (text)")
    elseif findText("Tiếp theo", 3) then
        tapText("Tiếp theo", 5)
        log("✅ Da tap nut Tiep theo")
    elseif findText("Tiếp tục", 3) then
        tapText("Tiếp tục", 5)
        log("✅ Da tap nut Tiep tuc")
    else
        log("⚠️ Khong tim thay nut Next")
    end
    sleep(3)
    
    -- BƯỚC 3: Nhập Password
    if findText("Password", 5) then
        log("✅ Tim thay o nhap Password")
        tapText("Password", 10)
        sleep(3)
    elseif findText("Mật khẩu", 5) then
        log("✅ Tim thay o nhap Mat khau")
        tapText("Mật khẩu", 10)
        sleep(3)
    else
        log("⚠️ Khong tim thay o nhap Password, thu tap toa do")
        tap(232, 343)
        sleep(3)
    end
    
    logScreen("👉 Đang nhập mật khẩu...", true)
    inputText(pass)
    sleep(3)
    log("✅ Da nhap PASS")
    sleep(3)
    
    -- BƯỚC 4: Tap nút Log in
    if findText("Log In", 3) then
        tapText("Log In", 10)
        log("✅ Da tap nut Log In")
    elseif findText("log in", 3) then
        tapText("log in", 10)
        log("✅ Da tap nut log in")
    elseif findText("Đăng nhập", 3) then
        tapText("Đăng nhập", 10)
        log("✅ Da tap nut Dang nhap")
    else
        logScreen("⚠️ Không tìm thấy nút Đăng nhập, thử tọa độ", true)
        log("⚠️ Khong tim thay nut Dang nhap, thu tap toa do")
        tap(200, 500)
    end
    
    sleep(15)
    log("✅ Khong phat hien loi dang nhap")
    
    -- KIỂM TRA SAI PASS / LỖI TRƯỚC
    if findImage("crop_1776575852885.png", 1, 1) then
        logScreen("❌ LỖI: Checkpoint/Sai pass/Khoá", true)
        return false, "nick bị sai pass hoặc checkpoint"
    end
    
    -- KIỂM TRA CẢNH BÁO DISMISS
    checkCanhBaoAutomated()
    
    -- BƯỚC 6: Kiểm tra 2FA
    if kiemTra2FA() then
        logScreen("🔐 PHÁT HIỆN MÀN HÌNH 2FA", true)
        log("⚠️ Man hinh 2FA xuat hien")
        
        if twofa and twofa ~= "" then
            local ok2fa = xuLy2FA(twofa)
            if not ok2fa then
                logScreen("❌ XỬ LÝ 2FA THẤT BẠI", true)
                log("❌ Xu ly 2FA that bai")
                return false, "lỗi xử lý 2FA"
            end
            log("✅ Xu ly 2FA thanh cong")
            nghi(20, "Đang đợi load sau 2FA")
            findText("ok", 3) 
            tapText("ok", 5)
            sleep(5)
            
            if findImage("crop_1776575852885.png", 1, 1) then
                log("❌ Tai khoan bi loi sau khi nhap 2FA")
                return false, "lỗi sau khi nhập 2FA"
            end
        else
            log("❌ Can 2FA nhung KHONG co secret, bo qua nick")
            return false, "thiếu mã 2FA"
        end
    else
        sleep(7)
        if findText("OK", 3) then
            tapText("OK", 5)
            sleep(2)
        end
        if findText("ok", 3) then
            tapText("ok", 5)
            sleep(7)
        end
    end
    
    logScreen("✅ ĐĂNG NHẬP THÀNH CÔNG: " .. uid, true)
    return true, "đăng nhập thành công"
end

-- ========== ĐỌC NICK ĐẦU TIÊN VÀ XÓA KHỎI FILE ==========
-- ========== TÌM NICK CHƯA XỬ LÝ ==========
local function timNickChuaXuLy()
    local file = io.open(ACCOUNT_FILE, "r")
    if not file then return nil end
    
    local unprocessedLine = nil
    for line in file:lines() do
        if line ~= "" then
            -- Kiểm tra xem dòng đã có trạng thái chưa
            if not line:find("thành công") and not line:find("sai pass") and 
               not line:find("lỗi 2FA") and not line:find("thiếu mã 2FA") and
               not line:find("checkpoint") then
                unprocessedLine = line
                break
            end
        end
    end
    file:close()
    
    if not unprocessedLine then return nil end
    
    local parts = {}
    for part in string.gmatch(unprocessedLine, "[^|]+") do
        table.insert(parts, part)
    end
    
    local uid = parts[1]
    local pass = parts[2]
    local twofa = parts[3] or ""
    
    if not uid or not pass then return nil end
    
    uid = uid:match("^%s*(.-)%s*$")
    pass = pass:match("^%s*(.-)%s*$")
    twofa = twofa:match("^%s*(.-)%s*$")
    
    return uid, pass, twofa, unprocessedLine
end

-- ========== CẬP NHẬT TRẠNG THÁI NICK VÀO FILE ==========
local function capNhatTrangThaiNick(oldLine, statusMessage)
    local file = io.open(ACCOUNT_FILE, "r")
    if not file then return false end
    
    local allLines = {}
    for line in file:lines() do
        table.insert(allLines, line)
    end
    file:close()
    
    local updated = false
    local newLines = {}
    for _, line in ipairs(allLines) do
        if line == oldLine and not updated then
            table.insert(newLines, line .. "|" .. statusMessage)
            updated = true
        else
            table.insert(newLines, line)
        end
    end
    
    local fw = io.open(ACCOUNT_FILE, "w")
    if fw then
        fw:write(table.concat(newLines, "\n") .. "\n")
        fw:close()
        return true
    end
    return false
end

-- ========== KIỂM TRA CÒN NICK CHƯA CHẠY ==========
local function conNick()
    local uid = timNickChuaXuLy()
    return uid ~= nil
end

-- ========== CHẠY NẠP NICK ==========
    logScreen("🚀 BẮT ĐẦU NẠP NICK", true)
    log("📂 File nick: " .. ACCOUNT_FILE)
log("🔢 Số nick cần đăng nhập: " .. SO_NICK_CAN_DANG_NHAP)

local thanhCong = 0
local thatBai = 0

for lan = 1, SO_NICK_CAN_DANG_NHAP do
    log("")
    logScreen("🚀 NICK " .. lan .. "/" .. SO_NICK_CAN_DANG_NHAP, true)
    
    if not conNick() then
        log("❌ HET NICK TRONG FILE!")
        break
    end
    
    local uid, pass, twofa, oldLine = timNickChuaXuLy()
    
    if not uid or not pass then
        log("❌ Khong lay duoc nick, hoac tat ca nick da xu ly xong")
        break
    else
        log("📝 UID: " .. uid)
        log("🔐 2FA: " .. (twofa ~= "" and "CO SECRET" or "KHONG"))
        
        resetMangNN()
        sleep(1)
        
        chuyenNickNN()
        sleep(1)
        
        if not moFacebookNN() then
            log("❌ Khong mo duoc Facebook, bo qua nick: " .. uid)
            capNhatTrangThaiNick(oldLine, "lỗi không mở được ứng dụng")
            thatBai = thatBai + 1
        else
            local thanhCongNick, thongBao = xuLyNhapTaiKhoan(uid, pass, twofa)
            
            if thanhCongNick then
                thanhCong = thanhCong + 1
                logScreen("✅ THÀNH CÔNG: " .. uid, true)
                capNhatTrangThaiNick(oldLine, thongBao)
            else
                thatBai = thatBai + 1
                logScreen("❌ THẤT BẠI: " .. uid, true)
                capNhatTrangThaiNick(oldLine, thongBao or "thất bại")
            end
            
            dongFacebookNN()
        end
    end
    
    if lan < SO_NICK_CAN_DANG_NHAP and conNick() then
        nghi(10, "Nghỉ đợi nạp nick tiếp theo")
    end
end

log("")
log("==========================================")
logScreen("✅ HOÀN TẤT NẠP NICK", true)
log("📊 Thành công: " .. thanhCong)
log("📊 Thất bại: " .. thatBai)
log("📊 Tổng: " .. (thanhCong + thatBai))
log("==========================================")
logScreen("Nạp nick xong! TC:" .. thanhCong .. " TB:" .. thatBai, true)

return

end -- Kết thúc hàm thucHienNapNick

-- ================================================================
-- ║  PHẦN KẾT BẠN UID (chạy nếu chọn "Kết bạn theo UID")       ║
-- ================================================================

-- ========== ĐỌC UID ĐẦU TIÊN VÀ XÓA KHỎI FILE ==========
local function layUIDVaXoa()
    log("📂 Đang cập nhật tệp UID...")
    local file = io.open(UID_FRIEND_FILE, "r")
    if not file then return nil end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then return nil end
    
    local allLines = {}
    for line in string.gmatch(content, "[^\r\n]+") do
        if line ~= "" then table.insert(allLines, line) end
    end
    
    if #allLines == 0 then return nil end
    
    local firstLine = allLines[1]:match("^%s*(.-)%s*$")
    
    local remaining = {}
    for i = 2, #allLines do
        table.insert(remaining, allLines[i])
    end
    
    local newContent = table.concat(remaining, "\n")
    if newContent ~= "" then newContent = newContent .. "\n" end
    
    local fileWrite = io.open(UID_FRIEND_FILE, "w")
    if fileWrite then
        fileWrite:write(newContent)
        fileWrite:close()
    end
    
    return firstLine
end

-- ========== KIỂM TRA CÒN UID ==========
local function conUID()
    local file = io.open(UID_FRIEND_FILE, "r")
    if not file then return false end
    local content = file:read("*all")
    file:close()
    if not content or content == "" then return false end
    for line in string.gmatch(content, "[^\r\n]+") do
        if line ~= "" then return true end
    end
    return false
end

-- ========== HÀM THỰC HIỆN KẾT BẠN UID ==========
local function thucHienKetBanUID()
    logScreen("🚀 BẮT ĐẦU KẾT BẠN UID", true)
    logScreen("📂 CHẠY TỪ NICK " .. NICK_BAT_DAU .. " ĐẾN NICK " .. (NICK_BAT_DAU + SO_NICK_UID), true)
    log("📂 File: " .. UID_FRIEND_FILE)
    log("👥 Chạy: " .. SO_NICK_UID .. " nick | " .. SO_UID_MOI_NICK .. " UID/nick")

    local ALL_UIDS_F = {}
    local f_uid = io.open(UID_FRIEND_FILE, "r")
    if f_uid then
        for line in f_uid:lines() do
            local u = line:match("^%s*(.-)%s*$")
            if u and u ~= "" then table.insert(ALL_UIDS_F, u) end
        end
        f_uid:close()
    end

    local uidCurrentIdx = 1
    local tongTC = 0
    local tongTB = 0
    local tongLoi = 0

    local danhSachNick = layDanhSachCrane()
    local offset = NICK_BAT_DAU
    for nickIndex = 1, SO_NICK_UID do
        local idx = ((nickIndex - 1 + offset) % #danhSachNick) + 1
        local tenPhanVung = (#danhSachNick > 0) and danhSachNick[idx] or "Default"

        log("")
        logScreen("👤 NICK " .. nickIndex .. "/" .. SO_NICK_UID .. " | 📂 " .. tenPhanVung, true)
        
        if uidCurrentIdx > #ALL_UIDS_F then
            log("⚠️ Da het UID trong danh sach!")
            break
        end

        resetMang()
        chuyenNick(tenPhanVung)
        if not moFacebook() then
            log("⚠️ Loi mo Facebook, bo qua nick nay")
        else
            nghi(10, "Đợi Facebook ổn định")

            local tcNick = 0
            local tbNick = 0
            local loiNick = 0

            for uidIndex = 1, SO_UID_MOI_NICK do
                if uidCurrentIdx > #ALL_UIDS_F then break end

                local uid = ALL_UIDS_F[uidCurrentIdx]
                uidCurrentIdx = uidCurrentIdx + 1
                
                if BAT_XOA_UID == 1 then layUIDVaXoa() end

                log("")
                log("👉 Nick " .. nickIndex .. " | UID " .. uidIndex .. "/" .. SO_UID_MOI_NICK .. ": " .. uid)
                -- Hiện tiến độ lên màn hình (gọn để không che nút bấm)
                logScreen("📊 Nick " .. nickIndex .. "/" .. SO_NICK_UID .. " | UID " .. uidIndex .. "/" .. SO_UID_MOI_NICK, true)
                sleep(0.5)
                openURL("fb://profile/" .. uid)
                sleep(3)
                
                if findText("Add Friend") then
                    logScreen("👆 Đang nhấn Add Friend...", true)
                    tapText("Add Friend", 10, 1)
                    sleep(3)
                    
                    if findImage("crop_1776840175322.png", 1, 1) then
                        logScreen("❌ Bị chặn! (" .. uidIndex .. "/" .. SO_UID_MOI_NICK .. ")", true)
                        log("❌ LỖI BLOCK/ERROR")
                        loiNick = loiNick + 1
                        ghiLogUID("Nick " .. nickIndex .. " | UID " .. uid .. " | Loi: Blocks")
                        if findText("OK") then tapText("OK", 10, 1) sleep(2) end
                    else
                        logScreen("✅ TC: " .. (tcNick+1) .. " | UID " .. uidIndex .. "/" .. SO_UID_MOI_NICK, true)
                        tcNick = tcNick + 1
                        ghiLogUID("Nick " .. nickIndex .. " | UID " .. uid .. " | Thanh Cong")
                    end
                    
                    -- KHÔI PHỤC: Kiểm tra nút Back to Profile để thoát màn hình thông báo
                    local hasBack = findImage("crop_1776839126664.png", 1, 0.9)
                    if hasBack or findText("Back to Profile") then
                        log("🔄 Tìm thấy nút Back, đang quay lại...")
                        tapText("Back to Profile", 10, 1)
                        sleep(2)
                    end
                else
                    logScreen("⚠️ Không thấy Add Friend (" .. uidIndex .. "/" .. SO_UID_MOI_NICK .. ")", true)
                    tbNick = tbNick + 1
                    ghiLogUID("Nick " .. nickIndex .. " | UID " .. uid .. " | That Bai (No Add Friend)")
                end
                
                if uidIndex < SO_UID_MOI_NICK and conUID() then
                    nghi(THOI_GIAN_NGHI_UID, "Nghỉ đợi mở UID tiếp theo")
                end
            end

            log("")
            logScreen("📊 Kết quả Nick " .. nickIndex .. ": TC " .. tcNick .. " | Lỗi " .. loiNick, true)
            tongTC = tongTC + tcNick
            tongTB = tongTB + tbNick
            tongLoi = tongLoi + loiNick
        end

        dongFacebook()
        if nickIndex < SO_NICK_UID and conUID() then
            nghi(5, "Nghỉ đổi nick")
        end
    end

    log("")
    log("==========================================")
    logScreen("✅ HOÀN TẤT KẾT BẠN UID\n📊 Tổng TC: " .. tongTC .. " | Lỗi: " .. tongLoi, true)
    log("==========================================")
end

-- ================================================================
-- ║  PHẦN KẾT BẠN GỢI Ý (chạy riêng biệt)                     ║
-- ================================================================

-- ========== TÌM VÀ TAP FRIENDS (GỢI Ý) ==========
local function timVaTapFriendsGY()
    log("🔍 Tim Friends...")
    if findText("Friends") then
        tapText("Friends", 10, 1)
        log("✅ Da tap Friends")
        sleep(2)
        return true
    end
    log("⚠️ Khong tim thay Friends, thu Menu...")
    if findText("Menu") then
        tapText("Menu", 10, 1)
        log("✅ Da tap Menu")
        sleep(2)
        if findText("Friends") then
            tapText("Friends", 10, 1)
            log("✅ Da tap Friends qua Menu")
            sleep(2)
            return true
        end
    end
    log("❌ Khong tim thay Friends")
    return false
end

-- ========== KIỂM TRA GỢI Ý KẾT BẠN (GỢI Ý) ==========
local function kiemTraGoiYGY()
    logScreen("🔍 Đang kiểm tra gợi ý kết bạn...", true)
    log("")
    log("========== KIEM TRA GOI Y KET BAN ==========")
    if not timVaTapFriendsGY() then
        log("❌ Khong the vao Friends de kiem tra")
        return false
    end
    sleep(3)
    if findText("No New Requests") then
        logScreen("⏭️ Không có gợi ý mới", true)
        log("❌ KHONG CO GOI Y KET BAN")
        return false
    else
        logScreen("✅ Đã thấy danh sách gợi ý", true)
        log("✅ CO GOI Y KET BAN")
        return true
    end
end

-- ========== TÌM ADD FRIEND BANG OCR (GỢI Ý) ==========
local function timTatCaAddFriendOCRGY()
    local danhSach = {}
    local results = ocr({
        region = {0, 0, 430, 800},
        languages = {"en-US"}
    })
    for _, r in ipairs(results) do
        if string.find(r.text, "Add Friend") or string.find(r.text, "add friend") then
            table.insert(danhSach, {x = r.x, y = r.y, text = r.text})
        end
    end
    return danhSach
end

-- ========== LƯỚT MÀN HÌNH (GỢI Ý) ==========
local function luotManHinhGY()
    log("📜 Khong tim thay Add Friend -> Luot man hinh")
    swipe(296, 599, 215, 300, 1)
    sleep(2)
end

local function thucHienKetBanGoiY()
    log("")
    logScreen("────────────────────\n🚀 BẮT ĐẦU KẾT BẠN GỢI Ý\n────────────────────", true)
    logScreen("📂 CHẠY TỪ NICK " .. NICK_BAT_DAU .. " ĐẾN NICK " .. (NICK_BAT_DAU + SO_NICK_KB_GY), true)
    log("👥 Chạy: " .. SO_NICK_KB_GY .. " nick")
    log("🔢 SL/nick: " .. SO_LUONG_KB_GY .. " người")
    log("⏳ Nghỉ: " .. DELAY_KB_GY .. "s")

local tongTC_GY = 0

    local danhSachNick = layDanhSachCrane()
    local offset = NICK_BAT_DAU
    for nickIndex = 1, SO_NICK_KB_GY do
        local idx = ((nickIndex - 1 + offset) % #danhSachNick) + 1
        local tenPhanVung = (#danhSachNick > 0) and danhSachNick[idx] or "Default"

        log("")
        logScreen("👤 NICK " .. nickIndex .. "/" .. SO_NICK_KB_GY .. " | 📂 " .. tenPhanVung, true)
        
        resetMang()
        sleep(1)
        chuyenNick(tenPhanVung)
    sleep(1)
    if not moFacebook() then
        log("⚠️ Loi mo Facebook, bo qua nick nay")
    else
        sleep(10)

        if not kiemTraGoiYGY() then
        log("⏭️ Nick nay khong co goi y, bo qua")
    else
        local daKetBan = 0
        local lanLienTiepKhongCo = 0
        
        while daKetBan < SO_LUONG_KB_GY do
            -- logScreen("📊 Tiến độ: " .. daKetBan .. "/" .. SO_LUONG_KB_GY, true) -- Tạm tắt để tránh che nút Add ở dưới
            log("📊 Tien do: " .. daKetBan .. "/" .. SO_LUONG_KB_GY)
            local cacNut = timTatCaAddFriendOCRGY()
            
            if #cacNut > 0 then
                lanLienTiepKhongCo = 0
                for i = 1, #cacNut do
                    if daKetBan >= SO_LUONG_KB_GY then break end
                    
                    daKetBan = daKetBan + 1
                    logScreen("🤝 Đã nhấn Add (" .. daKetBan .. "/" .. SO_LUONG_KB_GY .. ")", true) -- Hiện log SAU khi đã xác định tọa độ
                    tap(cacNut[i].x, cacNut[i].y)
                    sleep(1)
                    
                    -- KIỂM TRA TEXT "message" XEM CÓ VÀO NHẦM TRANG CÁ NHÂN KHÔNG
                    if findText("message", 1) or findText("Message", 1) then
                        log("⚠️ Phat hien text 'message' (da vao trang ca nhan), quay lai...")
                        tapImage("crop_1776705682700.png", 10, 1)
                        sleep(1)
                        daKetBan = daKetBan - 1
                        log("🔄 Da giam dem do tap nham")
                    else
                        log("✅ Khong phat hien 'message', tap chinh xac")
                    end
                    
                    if daKetBan < SO_LUONG_KB_GY then
                        nghi(DELAY_KB_GY, "Nghỉ đợi kết bạn gợi ý tiếp")
                    end
                end
            else
                lanLienTiepKhongCo = lanLienTiepKhongCo + 1
                log("⚠️ Khong tim thay Add Friend (" .. lanLienTiepKhongCo .. "/" .. MAX_LUOT_KB_GY .. ")")
                if lanLienTiepKhongCo >= MAX_LUOT_KB_GY then
                    logScreen("💀 HẾT GỢI Ý KẾT BẠN!", true)
                    log("💀 Het goi y ket ban!")
                    break
                end
                luotManHinhGY()
            end
            sleep(1)
        end
        tongTC_GY = tongTC_GY + daKetBan
        logScreen("📊 Nick " .. nickIndex .. " xong! Đã kết bạn: " .. daKetBan, true)
    end
    end

    dongFacebook()
    if nickIndex < SO_NICK_KB_GY then
        nghi(5, "Nghỉ đổi nick")
    end
end

log("==========================================")
logScreen("✅ HOÀN TẤT KẾT BẠN GỢI Ý", true)
log("📊 Tổng cộng: " .. tongTC_GY .. " người")
log("==========================================")
logScreen("Hoàn tất kết bạn gợi ý! TC: " .. tongTC_GY, true)

return

end -- Kết thúc hàm thucHienKetBanGoiY

-- ================================================================
-- ║  PHẦN FARM (chạy nếu chọn "Bắt đầu Farm")                  ║
-- ║  Logic gốc KHÔNG THAY ĐỔI                                   ║
-- ================================================================

-- ========== NỘI DUNG ĐĂNG BÀI (RẤT NHIỀU) ==========
local NOI_DUNG_BAI_VIET = readLinesFromFile(POST_FILE_PATH, {
    -- Chủ đề buổi sáng
    "Sáng nay thức dậy sớm hơn thường lệ một chút, pha ly cà phê rồi ngồi nhìn trời sáng dần. Những phút đầu ngày yên tĩnh như vậy luôn khiến đầu óc dễ chịu hơn nhiều.",
    "Một ngày mới lại bắt đầu, hy vọng mọi việc sẽ suôn sẻ. Chúc mọi người một ngày tốt lành! ☀️",
    "Thức dậy lúc 5h sáng, tập thể dục 30 phút, tắm nước ấm và bắt đầu ngày mới với năng lượng tràn đầy. 🔋",
    "Bình minh đẹp quá, tranh thủ chụp vài tấm ảnh lưu lại khoảnh khắc. Nắng sớm thật dễ chịu.",
    "Sáng nay không vội vàng, ngồi thư giãn nghe nhạc một lúc rồi mới bắt đầu công việc. Cảm giác thoải mái hơn hẳn.",
    "Thức dậy thấy trời đẹp, lòng cũng thấy vui vui. Một ngày mới tốt lành nhé mọi người!",
    "Ly cà phê sáng và bản nhạc yêu thích - khởi đầu hoàn hảo cho ngày mới. ☕🎵",
    "Sáng nay ra ban công hít thở không khí trong lành, thấy yêu đời hơn hẳn.",
    "Hôm nay dậy sớm hơn 15 phút, có thời gian làm mọi thứ chậm rãi hơn, cảm giác thật tuyệt.",
    
    -- Chủ đề công việc
    "Hôm nay công việc không quá nhiều nhưng vẫn đủ để bận rộn cả ngày. Dù hơi mệt nhưng cảm giác hoàn thành xong từng việc nhỏ cũng khiến tâm trạng khá tốt.",
    "Làm xong project đúng hạn, cảm giác nhẹ nhõm vô cùng. Tối nay được nghỉ ngơi rồi! 🎉",
    "Gặp đối tác mới, buổi làm việc khá hiệu quả. Hy vọng sẽ có nhiều cơ hội hợp tác trong tương lai.",
    "Học thêm được kỹ năng mới hôm nay, thấy bản thân tiến bộ từng ngày. Cố gắng không ngừng! 📚",
    "Làm việc nhóm hôm nay rất vui, mọi người phối hợp ăn ý, công việc tiến triển nhanh hơn dự kiến.",
    "Hôm nay giải quyết xong một đống việc tồn đọng, nhẹ cả người. Cuối tuần sẽ được nghỉ ngơi thật thoải mái.",
    "Công việc áp lực nhưng mình vẫn ổn. Cố lên nào!",
    "Nhận được lời khen từ sếp, vui quá! Cố gắng của mình đã được ghi nhận.",
    "Hôm nay dọn dẹp bàn làm việc, sắp xếp lại mọi thứ gọn gàng, làm việc thấy hứng khởi hơn hẳn.",
    "Mệt nhưng vui vì đã hoàn thành những việc quan trọng. Tạm biệt công việc, về nhà thư giãn thôi.",
    
    -- Chủ đề cảm xúc
    "Có những ngày chẳng cần điều gì đặc biệt xảy ra, chỉ cần mọi thứ diễn ra bình thường, không áp lực và không phiền lòng là đã đủ vui rồi.",
    "Hôm nay tâm trạng khá ổn định, không quá vui nhưng cũng chẳng có gì buồn. Giữ được trạng thái cân bằng như vậy là tốt rồi.",
    "Buồn một chút, nhưng rồi cũng sẽ qua. Mai lại là một ngày mới tốt đẹp hơn. 💪",
    "Vui vì nhận được tin vui từ người thân. Gia đình là trên hết! ❤️",
    "Hôm nay hơi mệt mỏi, chắc do thiếu ngủ. Tối nay phải ngủ sớm mới được.",
    "Cảm thấy biết ơn vì những điều nhỏ nhặt quanh ta. Hạnh phúc đôi khi đến từ những thứ giản đơn nhất.",
    "Bỗng nhiên thấy nhớ nhà, nhớ mẹ. Chắc cuối tuần này phải về thăm mọi người thôi.",
    "Hôm nay có chút căng thẳng nhưng mọi thứ rồi sẽ ổn. Hít một hơi thật sâu và tiếp tục bước tiếp.",
    "Thấy lòng nhẹ nhàng khi hoàng hôn buông xuống. Một ngày nữa lại qua đi bình yên.",
    "Hạnh phúc là đây! Được ở bên cạnh những người mình yêu thương.",
    
    -- Chủ đề thói quen & phát triển bản thân
    "Dạo này đang cố gắng thay đổi lại giờ giấc sinh hoạt, ngủ sớm hơn để sáng dậy không còn cảm giác mệt như trước nữa.",
    "Đang học cách không suy nghĩ quá nhiều về những chuyện chưa xảy ra. Tập trung vào việc hiện tại thấy nhẹ đầu hơn rất nhiều.",
    "Mỗi ngày đọc 10 trang sách, học 5 từ mới tiếng Anh. Những thói quen nhỏ nhưng lâu dài sẽ tạo nên sự khác biệt.",
    "Tập thiền 15 phút mỗi tối, tâm trí thư thái và ngủ ngon hơn hẳn. Rất đáng để duy trì! 🧘",
    "Tập thể dục được 1 tháng rồi, thấy cơ thể khỏe khoắn hơn nhiều. Sẽ cố gắng duy trì thói quen này.",
    "Học được cách nói 'không' với những việc không cần thiết. Thời gian của mình cũng quý giá lắm chứ.",
    "Mỗi ngày một chút tiến bộ, không cần vội vàng. Chậm mà chắc.",
    "Bắt đầu học nấu ăn, tuy lóng ngóng nhưng vui lắm. Tự tay làm món mình thích thật tuyệt.",
    "Tập viết nhật ký mỗi tối, nhìn lại một ngày đã qua để biết mình đã sống thế nào.",
    "Đang học cách lắng nghe nhiều hơn, nói ít hơn. Cảm thấy các mối quan hệ cũng tốt lên.",
    
    -- Chủ đề thời tiết
    "Thời tiết hôm nay khá dễ chịu, có nắng nhẹ và chút gió mát nên làm gì cũng thấy có động lực hơn.",
    "Trời mưa cả ngày, ở nhà làm ly trà nóng nghe nhạc thư giãn. Cũng có cái thú vui riêng. ☕🎵",
    "Nắng đẹp quá, tranh thủ đi dạo công viên hóng gió. Thành phố hôm nay thật bình yên.",
    "Trời se se lạnh, mặc áo ấm đi dạo phố thấy dễ chịu vô cùng. Mùa đông đến rồi.",
    "Nóng quá, chỉ muốn ở nhà bật điều hòa thôi. Trời ơi đừng nóng nữa!",
    "Mưa rồi, thích nhất là mưa nhẹ nhàng, ngồi bên cửa sổ nhìn mưa rơi thật thư giãn.",
    "Hôm nay trời đẹp quá, không khí trong lành, thích hợp để đi chơi xa.",
    "Gió mùa về rồi, trời trở lạnh. Nhớ quàng thêm khăn ấm nhé mọi người.",
    
    -- Chủ đề cuối ngày
    "Một ngày trôi qua nhanh thật, mới đó mà đã gần tối. Vẫn còn vài việc chưa xong nhưng thôi cứ để mai tiếp tục.",
    "Tối nay nấu món mới, tuy chưa ngon lắm nhưng vui vì được tự tay làm. Dần dần sẽ cải thiện thôi.",
    "Cảm ơn một ngày dài đã trôi qua bình an. Chúc mọi người ngủ ngon! 🌙",
    "Hôm nay cũng đã cố gắng hết khả năng của mình rồi nên không cần tạo thêm áp lực nữa.",
    "Mọi thứ không phải lúc nào cũng đúng kế hoạch nhưng đôi khi như vậy lại tốt, giúp mình học cách linh hoạt hơn.",
    "Buổi sáng bắt đầu bằng ly cà phê nóng và chút nắng ngoài hiên thật sự khiến tâm trạng tốt hơn nhiều.",
    "Hôm nay tuy hơi bận nhưng mọi việc đều đang dần tiến triển tốt. Chậm một chút cũng không sao.",
    "Đang tập thói quen sống chậm lại để cảm nhận mọi thứ rõ hơn.",
    "Một ngày bình thường nhưng không hề vô nghĩa. Chỉ cần còn sức khỏe là đã đáng quý rồi.",
    "Tối rồi, tắt điện thoại thư giãn. Cảm giác không bị làm phiền thật tuyệt.",
    "Vừa xem xong một bộ phim hay, tâm trạng thật tốt. Chúc mọi người ngủ ngon.",
    "Ngày hôm nay đã kết thúc, mai lại bắt đầu một ngày mới. Hẹn gặp lại!",
    
    -- Chủ đề du lịch & giải trí
    "Đang lên kế hoạch cho chuyến đi cuối tuần tới. Phượt cùng bạn bè thì còn gì bằng! 🏍️",
    "Nhìn lại ảnh chuyến đi Đà Lạt tháng trước, nhớ quá. Chắc phải sắp xếp đi tiếp thôi.",
    "Biển ơi! Sắp được nghỉ dưỡng ở biển rồi, háo hức quá! 🏖️",
    "Cuối tuần này đi cắm trại cùng bạn bè, chuẩn bị đồ đạc thật đầy đủ nào.",
    "Khám phá một quán cà phê mới, không gian đẹp, đồ uống ngon, điểm đến lý tưởng cho ngày cuối tuần.",
    "Đi bộ dọc bờ biển lúc chiều tối, gió mát quá, thấy lòng thư thái.",
    "Leo núi mệt thật nhưng lên đến đỉnh ngắm cảnh thì xứng đáng quá!",
    "Đi chợ đêm ăn vặt thỏa thích, ẩm thực đường phố Việt Nam tuyệt vời quá!",
    
    -- Chủ đề ẩm thực
    "Hôm nay được ăn món ngon, tâm trạng lên liền. Ăn uống là liều thuốc tinh thần tuyệt vời! 🍜",
    "Phát hiện quán cà phê mới vừa ngon vừa đẹp, điểm đến mới cho những buổi chiều thư giãn.",
    "Tập làm bánh, tuy hơi xấu nhưng vị cũng ổn. Chắc sẽ cố gắng hơn lần sau. 🍰",
    "Hôm nay ăn lẩu cùng gia đình, ấm cúng và vui vẻ. Món gì ăn cùng nhau cũng ngon hơn.",
    "Tự tay làm sinh tố uống, vừa ngon vừa tốt cho sức khỏe. Mỗi ngày một ly thôi cũng đủ.",
    "Đi ăn buffet thả ga, no quá trời. Hôm nay tạm gác chế độ ăn kiêng sang một bên.",
    "Phở bò sáng nay ngon quá, ngày mới bắt đầu thật tuyệt vời.",
    "Tìm được quán bánh mì ngon ở Sài Gòn, từ nay có địa điểm ăn sáng mới rồi.",
    
    -- Chủ đề gia đình & bạn bè
    "Cuối tuần về thăm ông bà, thấy lòng ấm áp. Gia đình là nơi bình yên nhất.",
    "Họp mặt bạn bè sau bao ngày xa cách, vui quá trời. Những người bạn thân thiết thật đáng quý.",
    "Mẹ nấu món gì cũng ngon, nhất là món canh chua cá lóc. Nhớ nhà quá!",
    "Cả nhà cùng đi chơi cuối tuần, thấy hạnh phúc đơn giản lắm.",
    "Tối nay cả nhà quây quản bên mâm cơm, ấm cúng quá. Hạnh phúc là đây!",
    "Nhận được quà từ bạn thân, cảm động quá. Tình bạn đẹp thật sự rất đáng trân trọng.",
    
    -- Chủ đề động lực & cuộc sống
    "Đừng bỏ cuộc, thành công đang ở phía trước. Hãy cứ bước tiếp dù có khó khăn.",
    "Mỗi ngày là một cơ hội mới để trở thành phiên bản tốt hơn của chính mình.",
    "Thất bại không phải là kết thúc, mà là bài học để mình trưởng thành hơn.",
    "Hãy sống là chính mình, đừng sống theo kỳ vọng của người khác.",
    "Ngày hôm qua là lịch sử, ngày mai là bí ẩn, hôm nay là món quà. Hãy trân trọng hiện tại.",
    "Đừng so sánh mình với người khác. Mỗi người có một hành trình riêng.",
    "Thành công không đến từ may mắn, mà đến từ sự nỗ lực không ngừng nghỉ.",
    "Hãy tin vào bản thân, bạn làm được mà!",
    "Cuộc sống không phải lúc nào cũng dễ dàng, nhưng mình có thể chọn cách đối diện với nó.",
    "Mỉm cười lên nào, ngày mới lại bắt đầu với bao điều tốt đẹp đang chờ đón.",
})

-- ========== TIỂU SỬ (RẤT NHIỀU) ==========
local TIEU_SU_RANDOM = readLinesFromFile(BIO_FILE_PATH, {
    "Yêu thương và bình an! ❤️",
    "Sống là để trải nghiệm 🌟",
    "Hạnh phúc là ở hiện tại 🥰",
    "Cảm ơn cuộc sống! 🙏",
    "Mỗi ngày là một món quà 🎁",
    "Sống tích cực mỗi ngày ✨",
    "Làm điều mình thích, yêu điều mình làm 💯",
    "Cuộc đời ngắn, đừng sống nhạt nhòa 🎨",
    "Thành công không phải đích đến, mà là hành trình 🚀",
    "Hãy là bản thể tốt nhất của chính mình 💪",
    "Tận hưởng từng khoảnh khắc 🕰️",
    "Sống đơn giản, nghĩ tích cực 😊",
    "Cho đi là còn mãi 🤝",
    "Mỉm cười vì mình đang sống 😄",
    "Bình yên trong tâm hồn 🕊️",
    "Đủ là hạnh phúc 🍀",
    "Học hôm nay để sống ngày mai 📖",
    "Sống chậm, yêu thương nhiều 💕",
    "Mỗi người một con đường, hãy đi con đường của mình 🛤️",
    "Thành công là khi bạn dám bắt đầu 🌈",
    "Cố gắng hôm nay, thành công ngày mai",
    "Yêu đời, yêu người, yêu bản thân",
    "Sống không hối tiếc",
    "Mỗi ngày đều là một khởi đầu mới",
    "Hạnh phúc không phải đích đến, mà là cách ta đi",
    "Đơn giản là đẹp",
    "Sống thật, yêu thật",
    "Tâm an, lòng vui",
    "Buông bỏ để nhẹ lòng",
    "Học cách tha thứ cho chính mình",
    "Trân trọng những gì mình đang có",
    "Biết ơn mỗi ngày bình an",
    "Hãy cứ là chính bạn, phần còn lại hãy để thời gian",
    "Sống không phải để hơn ai, mà để hơn chính mình ngày hôm qua",
    "Im lặng đôi khi là câu trả lời tốt nhất",
    "Chậm lại một chút, cuộc sống vẫn đẹp",
    "Tập trung vào điều quan trọng",
    "Đừng để những điều nhỏ nhặt làm hỏng ngày của bạn",
    "Hãy để nỗi buồn ngủ yên, và để niềm vui thức dậy",
    "Sống cho hiện tại, vì quá khứ đã qua, tương lai chưa tới",
    "Yêu thương bắt đầu từ chính mình",
    "Cho đi yêu thương, nhận lại bình an",
    "Sống có mục tiêu, có đam mê",
    "Học cách buông bỏ những điều không cần thiết",
    "Mỗi người đều có giá trị riêng",
    "Hãy sống như ngày mai không bao giờ đến",
    "Đừng để nỗi sợ ngăn cản bạn",
    "Bạn mạnh mẽ hơn bạn nghĩ",
    "Hãy tin vào phép màu của sự cố gắng",
})

-- ========== CÔNG VIỆC (RẤT NHIỀU) ==========
local DANH_SACH_CONG_VIEC = readLinesFromFile(WORK_FILE_PATH, {
    -- IT & Công nghệ
    "Kỹ sư phần mềm",
    "Developer",
    "Lập trình viên",
    "Kỹ thuật viên",
    "Quản lý dự án",
    "Trưởng phòng kỹ thuật",
    "Giám đốc công nghệ",
    "Chuyên viên phân tích dữ liệu",
    "Kỹ sư AI",
    "Chuyên gia bảo mật",
    "Kỹ sư DevOps",
    "Thiết kế UI/UX",
    "Quản trị hệ thống",
    "Lập trình viên Frontend",
    "Lập trình viên Backend",
    "Lập trình viên Fullstack",
    "Kỹ sư cầu nối",
    "Chuyên viên kiểm thử",
    "Quản trị cơ sở dữ liệu",
    "Kỹ sư mạng",
    "Chuyên gia điện toán đám mây",
    "Kỹ sư Blockchain",
    "Lập trình viên Game",
    "Kỹ sư nhúng",
    "Chuyên gia IoT",
    
    -- Kinh doanh & Marketing
    "Kinh doanh",
    "Marketing",
    "Nhân viên kinh doanh",
    "Trưởng phòng kinh doanh",
    "Giám đốc kinh doanh",
    "Chuyên viên Marketing online",
    "Chuyên viên SEO",
    "Chuyên viên truyền thông",
    "Content Creator",
    "Quản lý thương hiệu",
    "Chuyên viên quảng cáo",
    "Trưởng nhóm sales",
    "Chăm sóc khách hàng",
    "Phát triển thị trường",
    "Chuyên viên xuất nhập khẩu",
    
    -- Hành chính - Văn phòng
    "Nhân viên văn phòng",
    "Hành chính nhân sự",
    "Lễ tân",
    "Thư ký",
    "Trợ lý giám đốc",
    "Quản lý văn phòng",
    "Chuyên viên tuyển dụng",
    "Chuyên viên đào tạo",
    "Chuyên viên lương thưởng",
    "Chuyên viên pháp chế",
    
    -- Giáo dục
    "Giáo viên",
    "Giảng viên đại học",
    "Gia sư",
    "Trợ giảng",
    "Hiệu trưởng",
    "Chuyên viên giáo dục",
    "Tư vấn giáo dục",
    
    -- Y tế
    "Bác sĩ",
    "Y tá",
    "Dược sĩ",
    "Kỹ thuật viên xét nghiệm",
    "Bác sĩ đa khoa",
    "Bác sĩ răng hàm mặt",
    "Chuyên viên vật lý trị liệu",
    "Điều dưỡng",
    
    -- Tài chính - Kế toán
    "Kế toán",
    "Tư vấn tài chính",
    "Kiểm toán",
    "Chuyên viên tín dụng",
    "Giao dịch viên ngân hàng",
    "Quản lý tài chính",
    "Chuyên viên đầu tư",
    "Môi giới chứng khoán",
    "Tư vấn bảo hiểm",
    
    -- Bất động sản - Xây dựng
    "Bất động sản",
    "Kỹ sư xây dựng",
    "Kiến trúc sư",
    "Thiết kế nội thất",
    "Giám sát công trình",
    "Thầu xây dựng",
    "Chuyên viên định giá",
    "Quản lý dự án xây dựng",
    
    -- Nghệ thuật - Sáng tạo
    "Nhiếp ảnh gia",
    "Nhà văn",
    "Họa sĩ",
    "Nhạc sĩ",
    "Ca sĩ",
    "Diễn viên",
    "Đạo diễn",
    "Biên kịch",
    "MC",
    "Biên tập viên",
    "Nhà báo",
    "Designer đồ họa",
    "Thiết kế thời trang",
    "Makeup artist",
    "Stylist",
    
    -- Dịch vụ - Khác
    "Freelancer",
    "Doanh nhân",
    "Startup Founder",
    "Chủ doanh nghiệp",
    "Quản lý nhà hàng",
    "Pha chế",
    "Đầu bếp",
    "Lái xe",
    "Hướng dẫn viên du lịch",
    "Phiên dịch viên",
    "Thông dịch viên",
    "Chuyên viên logistics",
    "Nhân viên bán hàng",
    "Chăm sóc khách hàng",
    "Tư vấn viên",
})

-- ========== TRƯỜNG HỌC (RẤT NHIỀU) ==========
local DANH_SACH_TRUONG = readLinesFromFile(SCHOOL_FILE_PATH, {
    -- THPT TP.HCM
    "THPT Chuyên Lê Hồng Phong",
    "THPT Nguyễn Thượng Hiền",
    "THPT Bùi Thị Xuân",
    "THPT Trần Phú",
    "THPT Phan Đăng Lưu",
    "THPT Lê Quý Đôn",
    "THPT Marie Curie",
    "THPT Nguyễn Du",
    "THPT Gia Định",
    "THPT Ernst Thälmann",
    "THPT Lê Thánh Tôn",
    "THPT Nguyễn Hữu Cầu",
    "THPT Hùng Vương",
    "THPT Võ Thị Sáu",
    "THPT Trưng Vương",
    "THPT Nguyễn Thị Minh Khai",
    "THPT Phú Nhuận",
    "THPT Trần Khai Nguyên",
    "THPT Nguyễn Công Trứ",
    "THPT Mạc Đĩnh Chi",
    
    -- THPT Hà Nội
    "THPT Chuyên Hà Nội - Amsterdam",
    "THPT Chu Văn An",
    "THPT Kim Liên",
    "THPT Việt Đức",
    "THPT Trần Phú - Hà Nội",
    "THPT Phan Đình Phùng",
    "THPT Nguyễn Huệ",
    "THPT Thăng Long",
    "THPT Lê Quý Đôn - Hà Nội",
    "THPT Quang Trung",
    
    -- THPT Đà Nẵng
    "THPT Chuyên Lê Quý Đôn Đà Nẵng",
    "THPT Phan Châu Trinh",
    "THPT Trần Phú Đà Nẵng",
    "THPT Liên Chiểu",
    "THPT Hòa Vang",
    
    -- Đại học TP.HCM
    "Đại học Bách Khoa TP.HCM",
    "Đại học Khoa học Tự nhiên",
    "Đại học Kinh tế TP.HCM",
    "Đại học Sư phạm TP.HCM",
    "Đại học Y Dược TP.HCM",
    "Đại học Ngoại thương cơ sở 2",
    "Đại học Quốc gia TP.HCM",
    "Đại học Công nghệ Thông tin",
    "Đại học Ngân hàng TP.HCM",
    "Đại học Tôn Đức Thắng",
    "Đại học RMIT Việt Nam",
    "Đại học FPT TP.HCM",
    "Đại học Hoa Sen",
    "Đại học Văn Lang",
    "Đại học Công nghiệp TP.HCM",
    "Đại học Giao thông Vận tải TP.HCM",
    "Đại học Luật TP.HCM",
    "Đại học Mở TP.HCM",
    "Đại học Tài chính Marketing",
    "Đại học Sài Gòn",
    "Đại học Văn Hiến",
    "Đại học Nông Lâm TP.HCM",
    
    -- Đại học Hà Nội
    "Đại học Bách Khoa Hà Nội",
    "Đại học Quốc gia Hà Nội",
    "Đại học Kinh tế Quốc dân",
    "Đại học Ngoại thương",
    "Đại học Y Hà Nội",
    "Học viện Công nghệ Bưu chính Viễn thông",
    "Đại học Xây dựng",
    "Đại học Dược Hà Nội",
    "Đại học Luật Hà Nội",
    "Học viện Tài chính",
    "Đại học Thương mại",
    "Đại học Khoa học Xã hội và Nhân văn",
    "Đại học Công đoàn",
    
    -- Đại học Đà Nẵng
    "Đại học Bách Khoa Đà Nẵng",
    "Đại học Kinh tế Đà Nẵng",
    "Đại học Sư phạm Đà Nẵng",
    "Đại học Ngoại ngữ Đà Nẵng",
    "Đại học Duy Tân",
    "Đại học Đông Á",
    
    -- Đại học các tỉnh khác
    "Đại học Cần Thơ",
    "Đại học Nha Trang",
    "Đại học Huế",
    "Đại học Đà Lạt",
    "Đại học Vinh",
    "Đại học Quy Nhơn",
    "Đại học Tây Nguyên",
    "Đại học Hải Phòng",
    
    -- Cao đẳng
    "Cao đẳng Kỹ thuật Cao Thắng",
    "Cao đẳng Kinh tế Đối ngoại",
    "Cao đẳng Công thương TP.HCM",
    "Cao đẳng Sư phạm TP.HCM",
    "Cao đẳng Nghề TP.HCM",
    "Cao đẳng Viễn Đông",
    "Cao đẳng Văn hóa Nghệ thuật",
    
    -- Trường nghề
    "Trung cấp Nghề TP.HCM",
    "Trung cấp Kỹ thuật Nguyễn Hữu Cảnh",
    "Trung cấp Kinh tế Kỹ thuật",
    "Trung cấp Du lịch",
    "Trung cấp Y tế",
})

-- ========== THÀNH PHỐ (RẤT NHIỀU - CHỈ VIỆT NAM) ==========
local DANH_SACH_THANH_PHO = readLinesFromFile(CITY_FILE_PATH, {
    -- Thành phố trực thuộc trung ương
    "Thành phố Hồ Chí Minh",
    "Hà Nội",
    "Đà Nẵng",
    "Hải Phòng",
    "Cần Thơ",
    
    -- Tỉnh miền Bắc
    "Hạ Long, Quảng Ninh",
    "Nam Định",
    "Thái Bình",
    "Hưng Yên",
    "Hải Dương",
    "Bắc Ninh",
    "Bắc Giang",
    "Vĩnh Yên, Vĩnh Phúc",
    "Việt Trì, Phú Thọ",
    "Hòa Bình",
    "Sơn La",
    "Điện Biên Phủ, Điện Biên",
    "Lai Châu",
    "Lào Cai",
    "Yên Bái",
    "Tuyên Quang",
    "Hà Giang",
    "Cao Bằng",
    "Lạng Sơn",
    "Thái Nguyên",
    "Phủ Lý, Hà Nam",
    "Ninh Bình",
    "Thanh Hóa",
    
    -- Tỉnh miền Trung
    "Vinh, Nghệ An",
    "Hà Tĩnh",
    "Đồng Hới, Quảng Bình",
    "Đông Hà, Quảng Trị",
    "Huế, Thừa Thiên Huế",
    "Hội An, Quảng Nam",
    "Tam Kỳ, Quảng Nam",
    "Quảng Ngãi",
    "Pleiku, Gia Lai",
    "Kon Tum",
    "Quy Nhơn, Bình Định",
    "Tuy Hòa, Phú Yên",
    "Nha Trang, Khánh Hòa",
    "Cam Ranh, Khánh Hòa",
    "Phan Rang - Tháp Chàm, Ninh Thuận",
    "Phan Thiết, Bình Thuận",
    "Buôn Ma Thuột, Đắk Lắk",
    "Gia Nghĩa, Đắk Nông",
    "Đà Lạt, Lâm Đồng",
    "Bảo Lộc, Lâm Đồng",
    
    -- Tỉnh miền Tây Nam Bộ
    "Long Xuyên, An Giang",
    "Châu Đốc, An Giang",
    "Rạch Giá, Kiên Giang",
    "Hà Tiên, Kiên Giang",
    "Phú Quốc, Kiên Giang",
    "Mỹ Tho, Tiền Giang",
    "Bến Tre",
    "Trà Vinh",
    "Vĩnh Long",
    "Sa Đéc, Đồng Tháp",
    "Cao Lãnh, Đồng Tháp",
    "Tân An, Long An",
    "Bạc Liêu",
    "Cà Mau",
    "Sóc Trăng",
    "Hậu Giang",
    "Ngã Bảy, Hậu Giang",
    "Thủ Dầu Một, Bình Dương",
    "Biên Hòa, Đồng Nai",
    "Bà Rịa, Bà Rịa - Vũng Tàu",
    "Vũng Tàu",
    "Tây Ninh",
    "Đồng Xoài, Bình Phước",
    "Phan Rang - Tháp Chàm, Ninh Thuận",
    "Bảo Lộc, Lâm Đồng",
})

-- ========== QUÊ QUÁN (RIÊNG - RẤT NHIỀU) ==========
local DANH_SACH_QUE_QUAN = {
    -- Miền Bắc
    "Hà Nội",
    "Hải Phòng",
    "Nam Định",
    "Thái Bình",
    "Hưng Yên",
    "Hải Dương",
    "Bắc Ninh",
    "Bắc Giang",
    "Vĩnh Phúc",
    "Phú Thọ",
    "Hòa Bình",
    "Sơn La",
    "Điện Biên",
    "Lai Châu",
    "Lào Cai",
    "Yên Bái",
    "Tuyên Quang",
    "Hà Giang",
    "Cao Bằng",
    "Lạng Sơn",
    "Thái Nguyên",
    "Hà Nam",
    "Ninh Bình",
    "Thanh Hóa",
    "Quảng Ninh",
    
    -- Miền Trung
    "Nghệ An",
    "Hà Tĩnh",
    "Quảng Bình",
    "Quảng Trị",
    "Thừa Thiên Huế",
    "Quảng Nam",
    "Đà Nẵng",
    "Quảng Ngãi",
    "Gia Lai",
    "Kon Tum",
    "Bình Định",
    "Phú Yên",
    "Khánh Hòa",
    "Ninh Thuận",
    "Bình Thuận",
    "Đắk Lắk",
    "Đắk Nông",
    "Lâm Đồng",
    
    -- Miền Nam
    "Thành phố Hồ Chí Minh",
    "Cần Thơ",
    "An Giang",
    "Kiên Giang",
    "Tiền Giang",
    "Bến Tre",
    "Trà Vinh",
    "Vĩnh Long",
    "Đồng Tháp",
    "Long An",
    "Bạc Liêu",
    "Cà Mau",
    "Sóc Trăng",
    "Hậu Giang",
    "Bình Dương",
    "Đồng Nai",
    "Bà Rịa - Vũng Tàu",
    "Tây Ninh",
    "Bình Phước",
}

-- ========== DANH SÁCH RELATIONSHIP STATUS ==========
local DANH_SACH_RELATIONSHIP = readLinesFromFile(RELA_FILE_PATH, {
    "Single",
    "In a relationship",
    "Engaged",
    "Married",
    "In a civil union",
    "In a domestic partnership",
    "In an open relationship",
    "It's complicated",
    "Separated"
})

-- ========== QUAY VỀ HOME ĐƠN GIẢN ==========
local function veHomeDonGian()
    logScreen("🏠 Đang quay về Home...", true)
    log("🏠 Quay ve Home (don gian)...")
    tapText("Home", 5)
    sleep(2)
    logScreen("✅ Đã về Home", true)
    log("✅ Da quay ve Home")
end

-- ========== QUAY VỀ HOME NÂNG CAO ==========
local function veHomeNangCao()
    logScreen("🏠 Đang quay về Home (xử lý Popup)...", true)
    log("🏠 Quay ve Home (nang cao - xu ly popup)...")
    
    local daThay = false
    while not daThay do
        if findImage("crop_1776734384932.png", 1, 1) then
            log("👉 PHAT HIEN HINH 932, xu ly...")
            tapImage("crop_1776734384932.png", 10, 1)
            sleep(1)
            
            local allFound = true
            local r1 = findColor(1603570, 1, {9, 621, 40, 40})
            if not r1 or #r1 == 0 then allFound = false end
            local r2 = findColor(1603570, 1, {14, 620, 40, 40})
            if not r2 or #r2 == 0 then allFound = false end
            local r3 = findColor(16777215, 1, {11, 627, 40, 40})
            if not r3 or #r3 == 0 then allFound = false end
            
            if allFound then
                log("👉 PHAT HIEN MULTI-COLOR, dang tap...")
                tap(29, 641)
                sleep(0.5)
                tap(29, 641)
                log("✅ Da tap 2 lan vao (29, 641)")
            end
            daThay = true
            
        elseif findImage("crop_1776735855245.png", 1, 1) then
            log("👉 DANG O HOME, phat hien crop_1776735855245.png")
            daThay = true
            
        else
            log("👉 KHONG CO HINH, tap back...")
            if findImage("crop_1776705682700.png", 1, 1) then
                tapImage("crop_1776705682700.png", 10, 1)
                log("✅ Da tap back")
                sleep(2)
            else
                log("⚠️ Khong tim thay nut back")
                break
            end
        end
        sleep(1)
    end
    
    tapText("Home", 5)
    sleep(2)
    log("✅ Da quay ve Home")
end

-- ========== LƯỚT NEWSFEED ==========
local function luotNewsfeed()
    logScreen("📜 BẮT ĐẦU LƯỚT NEWSFEED", true)
    log("👉 So lan luot: " .. SO_LAN_LUOT)
    
    for i = 1, SO_LAN_LUOT do
        logScreen("📜 Đang lướt Newsfeed (" .. i .. "/" .. SO_LAN_LUOT .. ")", true)
        swipe(200, 600, 200, 200, 0.8)
        log("   ✅ Da luot lan " .. i .. "/" .. SO_LAN_LUOT)
        
        if i < SO_LAN_LUOT then
            local nghi_nf = math.random(3, 8)
            nghi(nghi_nf, "Đang xem bài viết Newsfeed")
        end
    end
    
    logScreen("✅ ĐÃ LƯỚT XONG NEWSFEED", true)
end

-- ========== HÀM KIỂM TRA MÀU VÀ ẤN MORE ==========
local function anMore()
    logScreen("📂 Đang mở thư viện ảnh...", true)
    log("🔍 Kiem tra mau de an More...")
    local r1 = findColor(3832790, 1, {302, 130, 40, 40})
    local r2 = findColor(1532879, 1, {312, 129, 40, 40})
    local r3 = findColor(1532879, 1, {325, 133, 40, 40})
    
    if r1 and #r1 > 0 and r2 and #r2 > 0 and r3 and #r3 > 0 then
        tap(322, 150)
        log("✅ Da an More, vao duoc thu vien anh")
        return true
    else
        log("⚠️ Khong tim thay mau, van tiep tuc...")
        return false
    end
end

-- ========== VUỐT CHỌN ẢNH RANDOM ==========
local function vuotChonAnh(loaiAnh)
    local soLanVuot = math.random(5, 20)
    log("👉 Vuot " .. soLanVuot .. " lan de chon " .. loaiAnh)
    
    for i = 1, soLanVuot do
        logScreen("📜 Đang lướt chọn " .. loaiAnh .. " (" .. i .. "/" .. soLanVuot .. ")", true)
        swipe(200, 600, 200, 200, 0.6)
        sleep(1.5)
    end
    
    sleep(5)
    
    -- Thêm vòng lặp kiểm tra
    local daTapDuoc = false
    local soLanThu = 0
    
    while not daTapDuoc do
        soLanThu = soLanThu + 1
        
        local x = math.random(50, 350)
        local y = math.random(100, 700)
        log("👉 Lan thu " .. soLanThu .. ": Tap chon anh tai (" .. x .. ", " .. y .. ")")
        tap(x, y)
        sleep(5) -- Đợi 5s sau khi tap
        
        -- Kiểm tra nếu còn "Camera Roll" là chưa được
        if findText("Camera Roll", 2) then
            logScreen("⚠️ Chưa chọn được ảnh, đang thử lại...", true)
            log("⚠️ Van con 'Camera Roll' -> tap chua trung, tap lai...")
        else
            daTapDuoc = true
            log("✅ Da tap duoc " .. loaiAnh .. " thanh cong!")
        end
    end
    
    sleep(2)
end

-- ========== VUỐT CHỌN ẢNH CHO STORY ==========
local function vuotChonAnhChoStory(loaiAnh)
    local soLanVuot = math.random(5, 20)
    log("👉 Vuot " .. soLanVuot .. " lan de chon " .. loaiAnh)
    
    for i = 1, soLanVuot do
        logScreen("📜 Đang lướt chọn " .. loaiAnh .. " (" .. i .. "/" .. soLanVuot .. ")", true)
        swipe(188, 516, 188, 200, 0.6)
        sleep(1.5)
    end
    
    sleep(5)
    
    -- Thêm vòng lặp kiểm tra
    local daTapDuoc = false
    local soLanThu = 0
    
    while not daTapDuoc do
        soLanThu = soLanThu + 1
        
        local x = math.random(50, 350)
        local y = math.random(100, 700)
        log("👉 Lan thu " .. soLanThu .. ": Tap chon anh tai (" .. x .. ", " .. y .. ")")
        tap(x, y)
        sleep(5) -- Đợi 5s sau khi tap
        
        -- Kiểm tra nếu còn "Create story" là chưa tap được
        if findText("Create story", 2) then
            logScreen("⚠️ Chưa chọn được ảnh Story, đang thử lại...", true)
            log("⚠️ Van con 'Create story' -> tap chua trung, tap lai...")
        else
            daTapDuoc = true
            log("✅ Da tap duoc " .. loaiAnh .. " thanh cong!")
        end
    end
    
    sleep(5)
end

-- ========== VUỐT RANDOM CHO ĐĂNG BÀI ==========
local function vuotChoDangBai()
    log("🎯 Vuot va tap Done cho dang bai...")
    
    local soLanVuot = math.random(5, 20)
    log("👉 Se vuot " .. soLanVuot .. " lan")
    
    for i = 1, soLanVuot do
        logScreen("📜 Đang lướt tìm ảnh (" .. i .. "/" .. soLanVuot .. ")", true)
        swipe(200, 600, 200, 200, 0.6)
        sleep(1.5)
    end
    
    sleep(5)
    
    -- Thêm vòng lặp kiểm tra
    local daTapDuoc = false
    local soLanThu = 0
    
    while not daTapDuoc do
        soLanThu = soLanThu + 1
        
        local x = math.random(50, 350)
        local y = math.random(100, 700)
        log("👉 Lan thu " .. soLanThu .. ": Tap random tai (" .. x .. ", " .. y .. ")")
        tap(x, y)
        sleep(2)
        
        -- Kiểm tra nếu thấy "Done" là đã tap được ảnh
        if findText("Done", 2) then
            daTapDuoc = true
            log("✅ Da tap duoc anh thanh cong!")
        else
            logScreen("⚠️ Chưa chọn được ảnh đăng bài, đang thử lại...", true)
            log("⚠️ Chua thay 'Done' -> tap chua trung, tap lai...")
        end
    end
    
    log("👉 Tim nut Done...")
    tapText("Done", 30)
    log("✅ Da tap Done")
    sleep(10)
end
-- ========== HÀM VUỐT TÌM TEXT ==========
local function vuotTimText(text, soLanVuotToiDa)
    soLanVuotToiDa = soLanVuotToiDa or 5
    for i = 1, soLanVuotToiDa do
        if findText(text, 2) then
            log("✅ Tim thay '" .. text .. "' o lan vuot thu " .. i)
            return true
        end
        log("👉 Lan " .. i .. ": chua thay '" .. text .. "', dang vuot len...")
        swipe(200, 600, 200, 300, 0.5)
        sleep(1)
    end
    log("❌ Khong tim thay '" .. text .. "' sau " .. soLanVuotToiDa .. " lan vuot")
    return false
end

-- ========== THÊM AVATAR ==========
local function themAvatar()
    logScreen("🖼️ BẮT ĐẦU THÊM AVATAR", true)
    
    local timThayMenu = tapText("Menu", 5)
    sleep(3)
    
    if timThayMenu == true then
        log("✅ Tim thay Menu bang text")
    else
        log("⚠️ Khong tim thay Menu, tim hinh...")
        tapImage("crop_1776651363816.png", 10, 0.9)
    end
    
    sleep(4)
    
    log("🔍 Kiem tra mau de vao trang ca nhan...")
    local allFound = true
    local r1 = findColor(16777215, 1, {210, 102, 40, 40})
    if not r1 or #r1 == 0 then allFound = false end
    local r2 = findColor(16777215, 1, {222, 101, 40, 40})
    if not r2 or #r2 == 0 then allFound = false end
    local r3 = findColor(16777215, 1, {202, 92, 40, 40})
    if not r3 or #r3 == 0 then allFound = false end
    local r4 = findColor(16777215, 1, {215, 104, 40, 40})
    if not r4 or #r4 == 0 then allFound = false end
    
    if allFound then
        logScreen("👤 Đang vào trang cá nhân...", true)
        tap(230, 122)
        log("✅ Tim thay mau -> da tap vao (230,122)")
    else
        log("⚠️ Khong tim thay mau -> bo qua tap")
    end
    sleep(3)
    
    if findImage("crop_1776589445092.png", 1, 0.85) then
        log("⚠️ PHAT HIEN LOI trang ca nhan")
        tapText("Go Back", 10)
        sleep(2)
    end
    
    logScreen("🔍 Đang tìm nút Camera...", true)
    log("👉 Tim nut camera bang mau...")
    local allFound2 = true
    local r1_2 = findColor(2368806, 1, {236, 328, 40, 40})
    if not r1_2 or #r1_2 == 0 then allFound2 = false end
    local r2_2 = findColor(2368806, 1, {245, 330, 40, 40})
    if not r2_2 or #r2_2 == 0 then allFound2 = false end
    local r3_2 = findColor(2368806, 1, {238, 334, 40, 40})
    if not r3_2 or #r3_2 == 0 then allFound2 = false end
    local r4_2 = findColor(15001323, 1, {240, 323, 40, 40})
    if not r4_2 or #r4_2 == 0 then allFound2 = false end
    local r5_2 = findColor(2368806, 1, {241, 332, 40, 40})
    if not r5_2 or #r5_2 == 0 then allFound2 = false end
    
    if allFound2 then
        tap(256, 348)
        log("✅ Da tap vao nut camera bang mau")
    else
        logScreen("⚠️ Không thấy nút Camera, thử hình dự phòng...", true)
        log("⚠️ Khong tim thay mau camera, dung hinh du phong...")
        tapImage("crop_1776589777588.png", 10, 0.85)
    end
    sleep(3)
    
    tapText("Select", 10)
    sleep(2)
    
    anMore()
    sleep(4)
    
    logScreen("🖼️ Đang chọn ảnh đại diện...", true)
    vuotChonAnh("anh avatar")
    
    tapText("Save", 10)
    sleep(20)
    
    log("✅ Hoan tat them avatar")
end

-- ========== THÊM ẢNH BÌA ==========
local function themAnhBia()
    logScreen("🖼️ BẮT ĐẦU THÊM ẢNH BÌA", true)
    
    if not findText("Cover Photo", 5) then
        log("⚠️ KHONG tim thay 'Cover Photo' -> da co anh bia roi, bo qua")
        return false
    end
    
    log("✅ TIM thay 'Cover Photo' -> chua co anh bia, tien hanh them")
    tapText("Cover Photo", 10)
    sleep(3)
    
    tapText("Upload Photo", 10)
    sleep(4)
    
    anMore()
    sleep(4)
    
    logScreen("🖼️ Đang chọn ảnh bìa...", true)
    vuotChonAnh("anh bia")
    
    tapText("Save", 20)
    sleep(10)
    
    logScreen("✅ ĐÃ THÊM ẢNH BÌA THÀNH CÔNG", true)
    return true
end

-- ========== ĐĂNG BÀI ==========
local function dangBai()
    logScreen("📝 BẮT ĐẦU ĐĂNG BÀI", true)
    
    -- Thêm kiểm tra ấn vào "What's on your mind?"
    local daTapDuoc = false
    local soLanThu = 0
    local maxLanThu = 3
    
    while not daTapDuoc and soLanThu < maxLanThu do
        soLanThu = soLanThu + 1
        logScreen("🔍 Đang tìm ô soạn bài (Lần " .. soLanThu .. ")...", true)
        
        if tapText("What's on your mind?", 10) then
            log("✅ Đã bấm vào What's on your mind?")
            sleep(4)
            
            -- Kiểm tra xem đã mở được ô soạn bài chưa (tìm "Create post")
            if findText("Create post", 5) or findText("Post", 5) then
                daTapDuoc = true
                log("✅ Đã mở ô soạn bài thành công!")
            else
                log("⚠️ Chưa thấy ô soạn bài, thử lại...")
            end
        else
            log("⚠️ Không thấy chữ 'What's on your mind?', đang thử lại...")
            swipe(200, 400, 200, 600, 0.5) -- Vuốt nhẹ để làm mới giao diện
            sleep(2)
        end
    end
    
    if not daTapDuoc then
        logScreen("❌ KHÔNG THỂ BẮT ĐẦU ĐĂNG BÀI!", true)
        log("❌ Khong the tap vao 'What's on your mind?' sau 3 lan thu")
        return false
    end
    
    local timThayFriends = tapText("Friends", 5)
    sleep(1)
    
    if timThayFriends == true then
        log("⚠️ Dang o che do Ban be, chuyen sang Cong khai...")
        tapText("Friends", 10)
        sleep(2)
        
        local allFound = true
        local r1 = findColor(13553359, 1, {326, 271, 40, 40})
        if not r1 or #r1 == 0 then allFound = false end
        local r2 = findColor(16777215, 1, {330, 278, 40, 40})
        if not r2 or #r2 == 0 then allFound = false end
        local r3 = findColor(16777215, 1, {326, 277, 40, 40})
        if not r3 or #r3 == 0 then allFound = false end
        local r4 = findColor(16777215, 1, {334, 280, 40, 40})
        if not r4 or #r4 == 0 then allFound = false end
        local r5 = findColor(16777215, 1, {330, 282, 40, 40})
        if not r5 or #r5 == 0 then allFound = false end
        
        if allFound then
            tap(346, 291)
            log("✅ Da chon Cong khai")
        else
            tapText("Public", 10)
        end
        sleep(2)
        
        tapText("Done", 10)
        sleep(3)
        tapText("What's on your mind?", 10)
        sleep(3)
    else
        log("✅ Dang o che do Cong khai")
        tapText("What's on your mind?", 10)
        sleep(3)
    end
    
    local soThuTu = math.random(1, #NOI_DUNG_BAI_VIET)
    local noiDung = NOI_DUNG_BAI_VIET[soThuTu]
    logScreen("📝 Đang nhập nội dung bài viết...", true)
    log("👉 Nhap noi dung: " .. noiDung)
    inputText(noiDung)
    sleep(2)
    
    -- Kiểm tra trường hợp có "Add to your post" hay không
    if findText("Add to your post", 3) then
        log("👉 TH2: Co 'Add to your post' -> tap vao Add to your post")
        tapText("Add to your post", 10)
        sleep(3)
        
        -- Sau đó tìm và tap "Photo/video"
        daTapDuoc = false
        soLanThu = 0
        while not daTapDuoc and soLanThu < maxLanThu do
            soLanThu = soLanThu + 1
            if tapText("Photo/video", 10) then
                sleep(3)
                daTapDuoc = true
                log("✅ Da tap duoc 'Photo/video'!")
            else
                log("⚠️ Khong tim thay 'Photo/video', thu lai...")
            end
        end
    else
        log("👉 TH1: Khong co 'Add to your post' -> tap vao crop_1776655087982.png")
        tapImage("crop_1776655087982.png", 10, 1)
        sleep(3)
    end
    
    vuotChoDangBai()
    
    logScreen("📤 Đang tải bài viết lên...", true)
    tapImage("crop_1776655431621.png", 10, 1)
    nghi(15, "Đang tải bài viết lên")
    
    logScreen("✅ ĐÃ ĐĂNG BÀI THÀNH CÔNG", true)
end

-- ========== CHUYỂN CHẾ ĐỘ CÔNG KHAI CHO STORY ==========
local function chuyenCheDoCongKhaiChoStory()
    log("--- CHUYEN CHE DO CONG KHAI CHO STORY ---")
    
    if findText("Privacy") then
        log("✅ Tim thay chu Privacy!")
        tap(35, 617)
    else
        logScreen("❌ KHÔNG TÌM THẤY CÀI ĐẶT QUYỀN RIÊNG TƯ", true)
        log("❌ Khong tim thay chu Privacy!")
        return false
    end
    sleep(2)
    
    local allFound1 = true
    local r1 = findColor(16777215, 1, {326, 160, 40, 40})
    if not r1 or #r1 == 0 then allFound1 = false end
    local r2 = findColor(14211289, 1, {321, 166, 40, 40})
    if not r2 or #r2 == 0 then allFound1 = false end
    local r3 = findColor(16777215, 1, {328, 166, 40, 40})
    if not r3 or #r3 == 0 then allFound1 = false end
    local r4 = findColor(16777215, 1, {333, 168, 40, 40})
    if not r4 or #r4 == 0 then allFound1 = false end
    local r5 = findColor(16777215, 1, {330, 170, 40, 40})
    if not r5 or #r5 == 0 then allFound1 = false end
    
    if allFound1 then
        tap(346, 180)
        log("✅ Da chon Cong khai")
    else
        tapText("Public", 10)
    end
    sleep(2)
    
    tapText("Save", 10)
    sleep(3)
    
    local allFound2 = true
    local r1_2 = findColor(1603570, 1, {220, 380, 40, 40})
    if not r1_2 or #r1_2 == 0 then allFound2 = false end
    local r2_2 = findColor(1603570, 1, {233, 380, 40, 40})
    if not r2_2 or #r2_2 == 0 then allFound2 = false end
    local r3_2 = findColor(16777215, 1, {210, 380, 40, 40})
    if not r3_2 or #r3_2 == 0 then allFound2 = false end
    local r4_2 = findColor(2523123, 1, {215, 384, 40, 40})
    if not r4_2 or #r4_2 == 0 then allFound2 = false end
    
    if allFound2 then
        tap(240, 400)
        log("✅ Da tap kiem tra")
    end
    
    tapText("Share", 10)
    nghi(15, "Đang tải Story lên")
    log("✅ Da tap Share")
    sleep(2)
    return true
end

-- ========== ĐĂNG STORY ==========
local function dangStory()
    logScreen("🎬 BẮT ĐẦU ĐĂNG STORY", true)
    
    local maxRefresh = 3
    local found = false
    
    for refreshCount = 1, maxRefresh do
        log("👉 LAN REFRESH " .. refreshCount .. "/" .. maxRefresh)
        swipe(200, 200, 200, 600, 0.5)
        sleep(3)
        swipe(148, 231, 400, 231, 0.5)
        sleep(7)
        
        if findImage("crop_1776662877397.png", 1, 1) then
            logScreen("✅ Đã thấy nút tạo Story", true)
            log("✅ Tim thay nut tao Story!")
            tapImage("crop_1776662877397.png", 10, 1)
            found = true
            break
        end
    end
    
    if not found then
        logScreen("❌ KHÔNG TÌM THẤY NÚT TẠO STORY", true)
        log("❌ Khong tim thay nut tao Story")
        return false
    end
    
    sleep(3)
    sleep(2)
    
    logScreen("🖼️ Đang chọn ảnh Story...", true)
    vuotChonAnhChoStory("anh story")
    
    tapText("Next", 5)
    sleep(3)
    
    chuyenCheDoCongKhaiChoStory()
    
    logScreen("✅ ĐÃ ĐĂNG STORY THÀNH CÔNG", true)
    return true
end

-- ========== HÀM THÊM TIỂU SỬ ==========
local function themTieuSu()
    logScreen("📝 Bắt đầu thêm tiểu sử...", true)
    log("📝 Bắt đầu thêm tiểu sử...")
    
    if findText("Describe yourself...") then
        log("✅ Tim thay khung tieu su (chua co tieu su)!")
        tapText("Describe yourself...", 10)
        sleep(2)
        
        local soThuTu = math.random(1, #TIEU_SU_RANDOM)
        local noiDung = TIEU_SU_RANDOM[soThuTu]
        log("👉 Nhap tieu su: " .. noiDung)
        inputText(noiDung)
        sleep(2)
        
        if findText("Save") then
            tapText("Save", 10)
        else
            tapText("Done", 10)
        end
        sleep(3)
        
        logScreen("✅ Hoàn tất thêm tiểu sử!", true)
        log("✅ Hoàn tất thêm tiểu sử!")
        return true
    else
        log("⚠️ KHONG tim thay 'Describe yourself...'! Da co tieu su roi!")
        return false
    end
end

-- ========== HÀM THÊM WORK ==========
local function themWork()
    logScreen("💼 Bắt đầu thêm công việc...", true)
    log("💼 Bắt đầu thêm công việc...")
    
    local ok = false
    log("🔍 Đang vuốt nhẹ để tìm Details...")
    for i = 1, 10 do
        if findText("Details", 3) then
            ok = true
            break
        else
            swipe(200, 550, 200, 450, 1.5) -- Vuốt nhẹ nhàng
            sleep(1)
        end
    end

    if not ok then
        log("⚠️ Khong tim thay Details")
        return false
    end
    log("✅ Tim thay Details!")
    
    local allFound = false
    
    -- Bước 1: KIỂM TRA MÀU TẠI VỊ TRÍ CỐ ĐỊNH (Cho nick bio ngắn)
    local r_quick = findColor(1532879, 1, {315, 635, 45, 45})
    if r_quick and #r_quick > 0 then
        allFound = true
        tap(335, 659) -- Tap vào tọa độ nút Add chuẩn
        log("✅ Thấy nút Add (TH1), tap luôn!")
    else
        -- Bước 2: VUỐT NHẸ VÀ TÌM CHỮ ADD (Thử 5 lần)
        log("⚠️ Không thấy màu, đang vuốt nhẹ tìm chữ 'Add'...")
        for attempt = 1, 5 do
            swipe(200, 550, 200, 450, 1.5) -- Vuốt nhẹ nhàng
            sleep(1.5)
            
            if findText("Add", 3) then
                tapText("Add", 10)
                log("✅ Đã tìm thấy và tap vào chữ 'Add'!")
                allFound = true
                break
            end
        end
    end
    
    if allFound then
        log("✅ Chuyen sang buoc tiep theo...")
        sleep(2)
        
        if findText("Add work") then
            tapText("Add work", 10)
            log("✅ Da tap vao Add work")
        else
            log("⚠️ Khong tim thay 'Add work' -> da co work roi")
            return false
        end
        sleep(2)
        
        if findText("Workplace Name") then
            tapText("Workplace Name", 10)
            log("✅ Da tap vao Workplace Name")
            sleep(2)
            tap(81, 88)
            log("✅ Da tap vao (81, 88)")
            sleep(2)
        else
            log("⚠️ Khong tim thay 'Workplace Name'")
            return false
        end
        sleep(2)
        
        local soThuTu = math.random(1, #DANH_SACH_CONG_VIEC)
        local congViec = DANH_SACH_CONG_VIEC[soThuTu]
        log("👉 Nhap cong viec: " .. congViec)
        inputText(congViec)
        sleep(2)
        
        tap(175, 134)
        log("✅ Da tap vao (175, 134) de chon cong viec")
        sleep(2)
        
        if findText("Add work") then
            log("✅ Tap thanh cong! Da quay ve Add work")
        elseif findText("Select workplace") then
            log("⚠️ Van dang o Select workplace, tap lai...")
            tap(175, 134)
            sleep(2)
        end
        sleep(2)
        
        if findText("Save") then
            tapText("Save", 10)
        else
            tapText("Done", 10)
        end
        
        -- ĐỢI HÌNH XÁC NHẬN TRONG 20 GIÂY
        log("⏳ Đang chờ bảng xác nhận xuất hiện (tối đa 20s)...")
        for i = 1, 20 do
            if findImage("crop_1776696576554.png", 1, 1) then
                tapImage("crop_1776696576554.png", 1, 1)
                log("✅ Đã tìm thấy và tap vào hình xác nhận!")
                break
            end
            sleep(1)
        end
        
        logScreen("✅ Hoàn tất thêm công việc!", true)
        log("✅ Hoàn tất thêm công việc!")
        return true
    end
    return false
end

-- ========== HÀM THÊM HIGH SCHOOL ==========
local function themHighSchool()
    logScreen("🏫 Bắt đầu thêm trường học...", true)
    log("🏫 Bắt đầu thêm trường học...")
    
    -- Tìm "Add high school" với vòng lặp
    local timThay = false
    for i = 1, 5 do
        if findText("Add high school", 3) then
            tapText("Add high school", 10)
            log("✅ Da tap vao Add high school")
            timThay = true
            break
        else
            log("⚠️ Lan " .. i .. ": Chua thay 'Add high school', vuot len...")
            swipe(200, 500, 200, 300, 0.5)
            sleep(1)
        end
    end
    
    if not timThay then
        log("⚠️ Khong tim thay 'Add high school' -> da co high school roi")
        return false
    end
    sleep(2)

    if findText("High School Name") then
        tapText("High School Name", 10)
        log("✅ Da tap vao High School Name")
        sleep(2)
        tap(81, 88)
        log("✅ Da tap vao (81, 88)")
        sleep(1)
    else
        log("⚠️ Khong tim thay 'High School Name'")
        return false
    end
    sleep(2)
    
    -- THÊM VÒNG LẶP XỬ LÝ NO RESULTS
    local maxRetry = 5
    for lanThu = 1, maxRetry do
        local soThuTu = math.random(1, #DANH_SACH_TRUONG)
        local tenTruong = DANH_SACH_TRUONG[soThuTu]
        log("👉 Nhap truong: " .. tenTruong)
        
        -- Xóa nội dung cũ nếu lần thử thứ 2 trở đi
        if lanThu > 1 then
            tap(360, 89)
            sleep(1)
        end
        
        inputText(tenTruong)
        sleep(2)
        
        tap(175, 134)
        log("✅ Da tap vao (175, 134) de chon truong")
        sleep(2)
        
        -- Kiểm tra no results
        if findText("no results found", 2) or findText("No results found", 2) then
            log("⚠️ Khong tim thay ket qua, thu lai voi truong khac...")
        else
            log("✅ Tim thay ket qua")
            break
        end
    end
    -- KẾT THÚC THÊM
    
    if findText("Add high school") then
        log("✅ Tap thanh cong! Da quay ve Add high school")
    elseif findText("Select school") then
        log("⚠️ Van dang o Select school, tap lai...")
        tap(175, 134)
        sleep(2)
    end
    sleep(2)
    
    if findText("Save") then
        tapText("Save", 10)
    else
        tapText("Done", 10)
    end
    
    -- ĐỢI HÌNH XÁC NHẬN TRONG 20 GIÂY
    log("⏳ Đang chờ bảng xác nhận xuất hiện (tối đa 20s)...")
    for i = 1, 20 do
        if findImage("crop_1776696576554.png", 1, 1) then
            tapImage("crop_1776696576554.png", 1, 1)
            log("✅ Đã tìm thấy và tap vào hình xác nhận!")
            break
        end
        sleep(1)
    end
    
    logScreen("✅ Hoàn tất thêm trường học!", true)
    log("✅ Hoàn tất thêm trường học!")
    return true
end
-- ========== HÀM THÊM CURRENT CITY ==========
local function themCurrentCity()
    logScreen("📍 Bắt đầu thêm thành phố hiện tại...", true)
    log("📍 Bắt đầu thêm thành phố hiện tại...")
    
    local found = false
    local maxScroll = 10
    
    if findText("Add current city") then
        tapText("Add current city", 10)
        log("✅ Da tap vao Add current city")
        found = true
    else
        for i = 1, maxScroll do
            swipe(200, 500, 200, 300, 0.3)
            sleep(1)
            if findText("Add current city") then
                tapText("Add current city", 10)
                log("✅ Da tap vao Add current city sau " .. i .. " lan luot")
                found = true
                break
            end
        end
    end

    if not found then
        log("⚠️ Khong tim thay Add current city! Da co Current City roi!")
        return false
    end
    sleep(2)

    if findText("Add Current City (Required)") then
        tapText("Add Current City (Required)", 10)
        log("✅ Da tap vao Add Current City (Required)")
        sleep(2)
        tap(81, 88)
        log("✅ Da tap vao (81, 88)")
        sleep(1)
    end
    sleep(2)
    
    -- THÊM VÒNG LẶP XỬ LÝ NO RESULTS
    local maxRetry = 5
    for lanThu = 1, maxRetry do
        local soThuTu = math.random(1, #DANH_SACH_THANH_PHO)
        local thanhPho = DANH_SACH_THANH_PHO[soThuTu]
        log("👉 Nhap thanh pho: " .. thanhPho)
        
        -- Xóa nội dung cũ nếu lần thử thứ 2 trở đi
        if lanThu > 1 then
            tap(360, 89)
            sleep(1)
        end
        
        inputText(thanhPho)
        sleep(2)
        
        tap(175, 134)
        log("✅ Da tap vao (175, 134) de chon thanh pho")
        sleep(2)
        
        -- Kiểm tra no results
        if findText("no results found", 2) or findText("No results found", 2) then
            log("⚠️ Khong tim thay ket qua, thu lai voi thanh pho khac...")
        else
            log("✅ Tim thay ket qua")
            break
        end
    end
    -- KẾT THÚC THÊM
    
    if findText("Add current city") then
        log("✅ Tap thanh cong! Da quay ve Add current city")
    elseif findText("Select current city") then
        log("⚠️ Van dang o Select current city, tap lai...")
        tap(175, 134)
        sleep(2)
    end
    sleep(2)
    
    if findText("Save") then
        tapText("Save", 10)
    else
        tapText("Done", 10)
    end
    
    -- ĐỢI HÌNH XÁC NHẬN TRONG 20 GIÂY
    log("⏳ Đang chờ bảng xác nhận xuất hiện (tối đa 20s)...")
    for i = 1, 20 do
        if findImage("crop_1776696576554.png", 1, 1) then
            tapImage("crop_1776696576554.png", 1, 1)
            log("✅ Đã tìm thấy và tap vào hình xác nhận!")
            break
        end
        sleep(1)
    end
    
    logScreen("✅ Hoàn tất thêm thành phố hiện tại!", true)
    log("✅ Hoàn tất thêm thành phố hiện tại!")
    return true
end
-- ========== HÀM THÊM HOMETOWN ==========
local function themHometown()
    logScreen("🏠 Bắt đầu thêm quê quán...", true)
    log("🏠 Bắt đầu thêm quê quán...")
    
    local found = false
    local maxScroll = 10
    
    if findText("Add hometown") then
        tapText("Add hometown", 10)
        log("✅ Da tap vao Add hometown")
        found = true
    else
        for i = 1, maxScroll do
            swipe(200, 500, 200, 300, 0.3)
            sleep(1)
            if findText("Add hometown") then
                tapText("Add hometown", 10)
                log("✅ Da tap vao Add hometown sau " .. i .. " lan luot")
                found = true
                break
            end
        end
    end

    if not found then
        log("⚠️ Khong tim thay Add hometown! Da co Hometown roi!")
        return false
    end
    sleep(2)

    if findText("Hometown Name (Required)") then
        tapText("Hometown Name (Required)", 10)
        log("✅ Da tap vao Hometown Name (Required)")
        sleep(2)
        tap(81, 88)
        log("✅ Da tap vao (81, 88)")
        sleep(1)
    end
    sleep(2)
    
    -- THÊM VÒNG LẶP XỬ LÝ NO RESULTS
    local maxRetry = 5
    for lanThu = 1, maxRetry do
        local soThuTu = math.random(1, #DANH_SACH_THANH_PHO)
        local thanhPho = DANH_SACH_THANH_PHO[soThuTu]
        log("👉 Nhap que quan: " .. thanhPho)
        
        -- Xóa nội dung cũ nếu lần thử thứ 2 trở đi
        if lanThu > 1 then
            tap(360, 89)
            sleep(1)
        end
        
        inputText(thanhPho)
        sleep(2)
        
        tap(175, 134)
        log("✅ Da tap vao (175, 134) de chon que quan")
        sleep(2)
        
        -- Kiểm tra no results
        if findText("no results found", 2) or findText("No results found", 2) then
            log("⚠️ Khong tim thay ket qua, thu lai voi que quan khac...")
        else
            log("✅ Tim thay ket qua")
            break
        end
    end
    -- KẾT THÚC THÊM
    
    if findText("Add hometown") then
        log("✅ Tap thanh cong! Da quay ve Add hometown")
    elseif findText("Select hometown") then
        log("⚠️ Van dang o Select hometown, tap lai...")
        tap(175, 134)
        sleep(2)
    end
    sleep(2)
    
    if findText("Save") then
        tapText("Save", 10)
    else
        tapText("Done", 10)
    end
    
    -- ĐỢI HÌNH XÁC NHẬN TRONG 20 GIÂY
    log("⏳ Đang chờ bảng xác nhận xuất hiện (tối đa 20s)...")
    for i = 1, 20 do
        if findImage("crop_1776696576554.png", 1, 1) then
            tapImage("crop_1776696576554.png", 1, 1)
            log("✅ Đã tìm thấy và tap vào hình xác nhận!")
            break
        end
        sleep(1)
    end
    
    logScreen("✅ Hoàn tất thêm quê quán!", true)
    log("✅ Hoàn tất thêm quê quán!")
    return true
end
-- ========== THÊM RELATIONSHIP STATUS ==========
local function themRelationship()
    logScreen("💑 Bắt đầu thêm tình trạng hôn nhân...", true)
    log("💑 Bắt đầu thêm tình trạng hôn nhân...")
    
    -- Bước 1: Tìm và tap "Add a relationship status" (thử lại 3 lần)
    for lanThu = 1, 3 do
        log("👉 LAN THU " .. lanThu .. "/3 - Tim 'Add a relationship status'")
        
        if vuotTimText("Add a relationship status", 5) then
            tapText("Add a relationship status", 10)
            log("✅ Da tap vao 'Add a relationship status'")
            break
        else
            log("⚠️ Lan " .. lanThu .. " chua tim thay")
            if lanThu == 3 then
                log("❌ Khong tim thay 'Add a relationship status' sau 3 lan")
                return false
            end
            sleep(2)
        end
    end
    sleep(2)
    
    -- Bước 2: Tìm và tap "relationship status" (thử lại 3 lần)
    for lanThu = 1, 3 do
        log("👉 LAN THU " .. lanThu .. "/3 - Tim 'relationship status'")
        
        if vuotTimText("relationship status", 5) then
            tapText("relationship status", 10)
            log("✅ Da tap vao 'relationship status'")
            break
        else
            log("⚠️ Lan " .. lanThu .. " chua tim thay")
            if lanThu == 3 then
                log("❌ Khong tim thay 'relationship status' sau 3 lan")
                return false
            end
            sleep(2)
        end
    end
    sleep(2)
    
    -- Bước 3: Random chọn status
    local soThuTu = math.random(1, #DANH_SACH_RELATIONSHIP)
    local statusChon = DANH_SACH_RELATIONSHIP[soThuTu]
    log("👉 Random chon: " .. statusChon)
    
    -- Bước 4: Tìm và tap vào status đã chọn (thử lại 3 lần)
    for lanThu = 1, 3 do
        log("👉 LAN THU " .. lanThu .. "/3 - Tim va tap vao: " .. statusChon)
        
        if vuotTimText(statusChon, 5) then
            tapText(statusChon, 10)
            log("✅ Da chon: " .. statusChon)
            break
        else
            log("⚠️ Lan " .. lanThu .. " chua tim thay status: " .. statusChon)
            if lanThu == 3 then
                log("❌ Khong tim thay status: " .. statusChon)
                return false
            end
            sleep(2)
        end
    end
    sleep(2)
    
    -- Bước 5: Lưu lại (chỉ Save)
    if findText("Save", 3) then
        tapText("Save", 10)
        log("✅ Da luu relationship")
    else
        log("⚠️ Khong tim thay nut Save")
    end
    
    -- ĐỢI HÌNH XÁC NHẬN TRONG 20 GIÂY
    log("⏳ Đang chờ bảng xác nhận xuất hiện (tối đa 20s)...")
    for i = 1, 20 do
        if findImage("crop_1776696576554.png", 1, 1) then
            tapImage("crop_1776696576554.png", 1, 1)
            log("✅ Đã tìm thấy và tap vào hình xác nhận!")
            break
        end
        sleep(1)
    end
    log("✅ Hoàn tất thêm tình trạng hôn nhân!")
    return true
end

-- ========== CHỈNH SỬA HỒ SƠ ==========
local function editProfile()
    logScreen("✏️ BẮT ĐẦU CHỈNH SỬA HỒ SƠ", true)
    
    log("🏠 Quay ve Home truoc khi chinh sua ho so...")
    veHomeNangCao()
    sleep(2)
    
    local timThayMenu = tapText("Menu", 5)
    sleep(1)
    
    if timThayMenu == true then
        log("✅ Tim thay Menu bang text")
    else
        log("⚠️ Khong tim thay Menu, tim hinh...")
        tapImage("crop_1776651363816.png", 10, 0.9)
    end
    
    sleep(2)
    
    log("🔍 Kiem tra mau trang ca nhan...")
    local allFound = true
    local r1 = findColor(16777215, 1, {187, 97, 40, 40})
    if not r1 or #r1 == 0 then allFound = false end
    local r2 = findColor(16777215, 1, {187, 103, 40, 40})
    if not r2 or #r2 == 0 then allFound = false end
    local r3 = findColor(16777215, 1, {197, 97, 40, 40})
    if not r3 or #r3 == 0 then allFound = false end
    local r4 = findColor(16777215, 1, {195, 102, 40, 40})
    if not r4 or #r4 == 0 then allFound = false end
    
    -- Multi-color check (4 points)
    local allFound = true
    local r1 = findColor(16777215, 1, {210, 102, 40, 40})
    if not r1 or #r1 == 0 then allFound = false end
    local r2 = findColor(16777215, 1, {222, 101, 40, 40})
    if not r2 or #r2 == 0 then allFound = false end
    local r3 = findColor(16777215, 1, {202, 92, 40, 40})
    if not r3 or #r3 == 0 then allFound = false end
    local r4 = findColor(16777215, 1, {215, 104, 40, 40})
    if not r4 or #r4 == 0 then allFound = false end
    if allFound then
      tap(230, 122)
    end
    
    if allFound then
        log("✅ Tim thay mau -> da o trang ca nhan, tap vao (207,117)")
        tap(207, 117)
    else
        log("⚠️ Khong tim thay mau -> chua o trang ca nhan, bo qua tap")
    end
    sleep(3)
    
    if findImage("crop_1776589445092.png", 1, 0.85) then
        log("⚠️ PHAT HIEN LOI trang ca nhan")
        tapText("Go Back", 10)
        sleep(2)
    end
    
    if findText("Edit profile", 5) then
        log("✅ Tim thay 'Edit profile'!")
        tapText("Edit profile", 10)
    else
        log("❌ Khong tim thay 'Edit profile'!")
        return false
    end
    sleep(3)
    
    themTieuSu()
    themWork()
    themHighSchool()
    themCurrentCity()
    themHometown()
    themRelationship()
    
    logScreen("✅ HOÀN TẤT CHỈNH SỬA HỒ SƠ", true)
    return true
end

-- ========== CHẠY TOÀN BỘ FARM ==========
local function thucHienFarm()
    -- Load lại nội dung từ file trước khi chạy
    NOI_DUNG_BAI_VIET = readLinesFromFile(POST_FILE_PATH, NOI_DUNG_BAI_VIET)
    TIEU_SU_RANDOM = readLinesFromFile(BIO_FILE_PATH, TIEU_SU_RANDOM)
    DANH_SACH_CONG_VIEC = readLinesFromFile(WORK_FILE_PATH, DANH_SACH_CONG_VIEC)
    DANH_SACH_TRUONG = readLinesFromFile(SCHOOL_FILE_PATH, DANH_SACH_TRUONG)
    DANH_SACH_THANH_PHO = readLinesFromFile(CITY_FILE_PATH, DANH_SACH_THANH_PHO)
    DANH_SACH_RELATIONSHIP = readLinesFromFile(RELA_FILE_PATH, DANH_SACH_RELATIONSHIP)
    
    logScreen("🚀 BẮT ĐẦU FARM", true)
    logScreen("📂 CHẠY TỪ NICK " .. NICK_BAT_DAU .. " ĐẾN NICK " .. (NICK_BAT_DAU + SO_LAN_LAP), true)
    log("=== SO LAN LAP: " .. SO_LAN_LAP .. " ===")
    log("=== BAT AVATAR: " .. (BAT_AVATAR == 1 and "BAT" or "TAT") .. " ===")
    log("=== BAT ANH BIA: " .. (BAT_ANH_BIA == 1 and "BAT" or "TAT") .. " ===")
    log("=== BAT DANG BAI: " .. (BAT_DANG_BAI == 1 and "BAT" or "TAT") .. " ===")
    log("=== BAT DANG STORY: " .. (BAT_DANG_STORY == 1 and "BAT" or "TAT") .. " ===")
    log("=== BAT LUOT NEWSFEED: " .. (BAT_LUOT_NEWSFEED == 1 and "BAT" or "TAT") .. " ===")
    log("=== BAT EDIT PROFILE: " .. (BAT_EDIT_PROFILE == 1 and "BAT" or "TAT") .. " ===")
    log("========================================")

    local danhSachNick = layDanhSachCrane()
    if #danhSachNick == 0 then
        logScreen("❌ KHÔNG LẤY ĐƯỢC DANH SÁCH CRANE!", true)
        return
    end

    local offset = NICK_BAT_DAU
    for lan = 1, SO_LAN_LAP do
        -- Lấy tên phân vùng theo số thứ tự (vòng lặp nếu hết list)
        local idx = ((lan - 1 + offset) % #danhSachNick) + 1
        local tenPhanVung = danhSachNick[idx]

        log("")
        logScreen("🚀 LẦN " .. lan .. "/" .. SO_LAN_LAP .. " | 📂 " .. tenPhanVung, true)
        
        resetMang()
        chuyenNick(tenPhanVung)
        if not moFacebook() then
            log("⚠️ Loi mo Facebook, bo qua nick nay")
        else
            local canVeHome = (BAT_AVATAR == 1 or BAT_ANH_BIA == 1 or BAT_EDIT_PROFILE == 1)
            
            if BAT_AVATAR == 1 then
                themAvatar()
            end
            
            if BAT_ANH_BIA == 1 then
                themAnhBia()
            end
            
            if BAT_EDIT_PROFILE == 1 then
                editProfile()
            end
            
            if canVeHome then
                if BAT_EDIT_PROFILE == 1 then
                    veHomeNangCao()
                else
                    veHomeDonGian()
                end
            end
            
            if BAT_DANG_BAI == 1 then dangBai() end
            if BAT_DANG_STORY == 1 then dangStory() end
            if BAT_LUOT_NEWSFEED == 1 then luotNewsfeed() end
            
            dongFacebook()
        end
        
        logScreen("✅ HOÀN THÀNH LẦN " .. lan .. "/" .. SO_LAN_LAP, true)
        
        if lan < SO_LAN_LAP then
            nghi(THOI_GIAN_NGHI, "Nghỉ giải lao giữa các hiệp Farm")
        end
    end

    logScreen("🎉 HOÀN THÀNH TOÀN BỘ " .. SO_LAN_LAP .. " LẦN", true)
end

-- ================================================================
-- ║  BỘ LẬP LỊCH TỰ ĐỘNG                                       ║
-- ================================================================

local BAT_LAP_LICH = 0
local THOI_GIAN_CHAY = "15:30"

local SO_NICK_LL = 2
local NICK_BAT_DAU_LL = 1
local SO_NGAY_LL = 10
local LAN_DA_CHAY_LL = 0
local NGAY_BAT_DAU_LL = ""
local CHUC_NANG_LL = "farm"

local FARM_AVATAR = 1
local FARM_COVER = 1
local FARM_POST = 1
local FARM_STORY = 0
local FARM_NEWSFEED = 0
local FARM_EDIT = 1

local function luuCauHinhLapLich()
    local f = io.open(CONFIG_FILE_LL, "w")
    if f then
        f:write("BAT_LAP_LICH=" .. BAT_LAP_LICH .. "\n")
        f:write("THOI_GIAN_CHAY=" .. THOI_GIAN_CHAY .. "\n")
        f:write("SO_NICK_LL=" .. SO_NICK_LL .. "\n")
        f:write("NICK_BAT_DAU_LL=" .. NICK_BAT_DAU_LL .. "\n")
        f:write("SO_NGAY_LL=" .. SO_NGAY_LL .. "\n")
        f:write("LAN_DA_CHAY_LL=" .. LAN_DA_CHAY_LL .. "\n")
        f:write("NGAY_BAT_DAU_LL=" .. NGAY_BAT_DAU_LL .. "\n")
        f:write("CHUC_NANG_LL=" .. CHUC_NANG_LL .. "\n")
        f:write("FARM_AVATAR=" .. FARM_AVATAR .. "\n")
        f:write("FARM_COVER=" .. FARM_COVER .. "\n")
        f:write("FARM_POST=" .. FARM_POST .. "\n")
        f:write("FARM_STORY=" .. FARM_STORY .. "\n")
        f:write("FARM_NEWSFEED=" .. FARM_NEWSFEED .. "\n")
        f:write("FARM_EDIT=" .. FARM_EDIT .. "\n")
        f:close()
        return true
    end
    return false
end

local function taiCauHinhLapLich()
    local f = io.open(CONFIG_FILE_LL, "r")
    if not f then return false end
    for line in f:lines() do
        local key, val = line:match("([^=]+)=(.*)")
        if key and val then
            if key == "BAT_LAP_LICH" then BAT_LAP_LICH = tonumber(val) or 0
            elseif key == "THOI_GIAN_CHAY" then THOI_GIAN_CHAY = val
            elseif key == "SO_NICK_LL" then SO_NICK_LL = tonumber(val) or 2
            elseif key == "NICK_BAT_DAU_LL" then NICK_BAT_DAU_LL = tonumber(val) or 1
            elseif key == "SO_NGAY_LL" then SO_NGAY_LL = tonumber(val) or 10
            elseif key == "LAN_DA_CHAY_LL" then LAN_DA_CHAY_LL = tonumber(val) or 0
            elseif key == "NGAY_BAT_DAU_LL" then NGAY_BAT_DAU_LL = val
            elseif key == "CHUC_NANG_LL" then CHUC_NANG_LL = val
            elseif key == "FARM_AVATAR" then FARM_AVATAR = tonumber(val) or 1
            elseif key == "FARM_COVER" then FARM_COVER = tonumber(val) or 1
            elseif key == "FARM_POST" then FARM_POST = tonumber(val) or 1
            elseif key == "FARM_STORY" then FARM_STORY = tonumber(val) or 0
            elseif key == "FARM_NEWSFEED" then FARM_NEWSFEED = tonumber(val) or 0
            elseif key == "FARM_EDIT" then FARM_EDIT = tonumber(val) or 1
            end
        end
    end
    f:close()
    return true
end

local function ghiLogLich(noiDung)
    local f = io.open(FILE_LOG_LL, "a")
    if not f then f = io.open(FILE_LOG_LL, "w") end
    if f then
        local thoiGian = os.date("%Y-%m-%d %H:%M:%S")
        f:write("[" .. thoiGian .. "] " .. noiDung .. "\n")
        f:close()
    end
    log("📝 " .. noiDung)
end

local function tenChucNangLL()
    local ten = {
        farm = "🌾 FARM",
        ketban_uid = "👤 KẾT BẠN UID",
        ketban_gy = "👥 KẾT BẠN GỢI Ý",
        chapnhan = "🤝 CHẤP NHẬN KB",
        nap = "🔑 NẠP NICK",
        interact_post = "🎯 TƯƠNG TÁC POST",
        cmt_bai_viet = "💬 CMT BÀI VIẾT",
        share_bai_viet = "🚀 CHIA SẺ POST"
    }
    return ten[CHUC_NANG_LL] or CHUC_NANG_LL
end

local function chonGio()
    local items = {}
    for i = 0, 23 do table.insert(items, string.format("%02d", i)) end
    local chon = dialogChoice("CHỌN GIỜ", unpack(items))
    if chon then return chon end
    return string.sub(THOI_GIAN_CHAY, 1, 2)
end

local function chonPhut()
    local items1, items2, items3 = {}, {}, {}
    for i = 0, 19 do table.insert(items1, string.format("%02d", i)) end
    for i = 20, 39 do table.insert(items2, string.format("%02d", i)) end
    for i = 40, 59 do table.insert(items3, string.format("%02d", i)) end
    
    local chon = dialogChoice("PHÚT (0-19)", unpack(items1))
    if chon then return chon end
    
    chon = dialogChoice("PHÚT (20-39)", unpack(items2))
    if chon then return chon end
    
    chon = dialogChoice("PHÚT (40-59)", unpack(items3))
    if chon then return chon end
    
    return string.sub(THOI_GIAN_CHAY, 4, 5)
end

local function trangThaiFarmLL()
    local s = {}
    s.avatar = (FARM_AVATAR == 1) and "✅" or "❌"
    s.cover = (FARM_COVER == 1) and "✅" or "❌"
    s.post = (FARM_POST == 1) and "✅" or "❌"
    s.story = (FARM_STORY == 1) and "✅" or "❌"
    s.newsfeed = (FARM_NEWSFEED == 1) and "✅" or "❌"
    s.edit = (FARM_EDIT == 1) and "✅" or "❌"
    return s
end

local function menuCaiFarmLL()
    while true do
        local st = trangThaiFarmLL()
        local title = "🌾 Cài farm (chế độ lịch)\n"
            .. "· " .. st.avatar .. " Avatar  · " .. st.cover .. " Ảnh bìa  · " .. st.post .. " Đăng bài\n"
            .. "· " .. st.story .. " Story  · " .. st.newsfeed .. " Newsfeed  · " .. st.edit .. " Hồ sơ"
        
        local chon = dialogChoice(title,
            "🖼️ Ảnh đại diện",
            "🖼️ Ảnh bìa",
            "📝 Đăng bài",
            "📸 Đăng Story",
            "📜 Lướt Newsfeed",
            "✏️ Sửa hồ sơ",
            "────────",
            "🟢 Bật tất cả",
            "🔴 Tắt tất cả",
            "◀️ Quay lại"
        )
        if not chon or chon:find("Quay lại") then
            luuCauHinhLapLich()
            return
        elseif chon:find("Ảnh đại diện") then
            FARM_AVATAR = (FARM_AVATAR == 1) and 0 or 1
        elseif chon:find("Ảnh bìa") then
            FARM_COVER = (FARM_COVER == 1) and 0 or 1
        elseif chon:find("Đăng bài") then
            FARM_POST = (FARM_POST == 1) and 0 or 1
        elseif chon:find("Đăng Story") then
            FARM_STORY = (FARM_STORY == 1) and 0 or 1
        elseif chon:find("Lướt Newsfeed") then
            FARM_NEWSFEED = (FARM_NEWSFEED == 1) and 0 or 1
        elseif chon:find("Sửa hồ sơ") then
            FARM_EDIT = (FARM_EDIT == 1) and 0 or 1
        elseif chon:find("Bật tất cả") then
            FARM_AVATAR = 1; FARM_COVER = 1; FARM_POST = 1
            FARM_STORY = 1; FARM_NEWSFEED = 1; FARM_EDIT = 1
        elseif chon:find("Tắt tất cả") then
            FARM_AVATAR = 0; FARM_COVER = 0; FARM_POST = 0
            FARM_STORY = 0; FARM_NEWSFEED = 0; FARM_EDIT = 0
        end
    end
end

local function chayChucNang()
    local oldNickBatDau = NICK_BAT_DAU
    NICK_BAT_DAU = NICK_BAT_DAU_LL

    logScreen("────────────────────\n🚀 ĐANG CHẠY LỊCH: " .. tenChucNangLL() .. "\n────────────────────", true)
    ghiLogLich("BAT DAU chay: " .. tenChucNangLL())
    
    if CHUC_NANG_LL == "farm" then
        local oldAvatar = BAT_AVATAR
        local oldCover = BAT_ANH_BIA
        local oldPost = BAT_DANG_BAI
        local oldStory = BAT_DANG_STORY
        local oldNewsfeed = BAT_LUOT_NEWSFEED
        local oldEdit = BAT_EDIT_PROFILE
        
        BAT_AVATAR = FARM_AVATAR
        BAT_ANH_BIA = FARM_COVER
        BAT_DANG_BAI = FARM_POST
        BAT_DANG_STORY = FARM_STORY
        BAT_LUOT_NEWSFEED = FARM_NEWSFEED
        BAT_EDIT_PROFILE = FARM_EDIT
        
        thucHienFarm()
        
        BAT_AVATAR = oldAvatar
        BAT_ANH_BIA = oldCover
        BAT_DANG_BAI = oldPost
        BAT_DANG_STORY = oldStory
        BAT_LUOT_NEWSFEED = oldNewsfeed
        BAT_EDIT_PROFILE = oldEdit
        
    elseif CHUC_NANG_LL == "ketban_uid" then
        thucHienKetBanUID()
    elseif CHUC_NANG_LL == "ketban_gy" then
        thucHienKetBanGoiY()
    elseif CHUC_NANG_LL == "chapnhan" then
        thucHienChapNhanKetBan()
    elseif CHUC_NANG_LL == "nap" then
        thucHienNapNick()
    elseif CHUC_NANG_LL == "interact_post" then
        thucHienInteractPost()
    elseif CHUC_NANG_LL == "cmt_bai_viet" then
        thucHienCMTBaiViet()
    elseif CHUC_NANG_LL == "share_bai_viet" then
        thucHienShareBaiViet()
    end
    
    log("✅ HOAN THANH: " .. tenChucNangLL())
    ghiLogLich("HOAN THANH: " .. tenChucNangLL())

    NICK_BAT_DAU = oldNickBatDau
end

local function kiemTraLich()
    log("")
    log("═══════════════════════════════════════════════════════")
    log("⏰ BAT DAU CHE DO LAP LICH")
    log("═══════════════════════════════════════════════════════")
    
    taiCauHinhLapLich()
    if NGAY_BAT_DAU_LL == "" then
        NGAY_BAT_DAU_LL = os.date("%Y-%m-%d")
        luuCauHinhLapLich()
    end
    
    log("📋 THONG TIN LICH:")
    log("├─ " .. tenChucNangLL())
    log("├─ 📅 " .. SO_NGAY_LL .. " ngay")
    log("├─ ⏰ " .. THOI_GIAN_CHAY)
    log("├─ 📊 Da chay: " .. LAN_DA_CHAY_LL .. "/" .. SO_NGAY_LL)
    log("└─ 🔘 Trang thai: " .. (BAT_LAP_LICH == 1 and "ĐANG BẬT" or "ĐANG TẮT"))
    log("")
    
    if BAT_LAP_LICH == 0 then
        logScreen("⚠️ LỊCH ĐANG TẮT! VÀO MENU BẬT LÊN!", true)
        return
    end
    
    ghiLogLich("KHOI DONG LICH - " .. SO_NGAY_LL .. " ngay luc " .. THOI_GIAN_CHAY)
    local daChayHomNay = false
    local ngayDaChay = ""
    
    while BAT_LAP_LICH == 1 and LAN_DA_CHAY_LL < SO_NGAY_LL do
        local now = os.date("*t")
        local gioHienTai = string.format("%02d:%02d", now.hour, now.min)
        local ngayHomNay = string.format("%d-%02d-%02d", now.year, now.month, now.day)
        
        if ngayHomNay ~= ngayDaChay then daChayHomNay = false end
        
        if gioHienTai == THOI_GIAN_CHAY and not daChayHomNay then
            logScreen("📅 CHẠY LỊCH: " .. tenChucNangLL(), true)
            chayChucNang()
            
            LAN_DA_CHAY_LL = LAN_DA_CHAY_LL + 1
            luuCauHinhLapLich()
            daChayHomNay = true
            ngayDaChay = ngayHomNay
            
            logScreen("✅ ĐÃ CHẠY XONG HÔM NAY! TIẾN ĐỘ: " .. LAN_DA_CHAY_LL .. "/" .. SO_NGAY_LL, true)
            nghi(120, "Nghỉ giải lao sau khi chạy xong lịch hôm nay")
            
            if LAN_DA_CHAY_LL >= SO_NGAY_LL then
                log("🎉 HOAN THANH " .. SO_NGAY_LL .. " NGAY LAP LICH!")
                BAT_LAP_LICH = 0
                luuCauHinhLapLich()
                break
            end
        else
            local giay = now.sec
            if giay < 5 then
                logScreen("📅 TIẾN ĐỘ: " .. LAN_DA_CHAY_LL .. "/" .. SO_NGAY_LL .. " NGÀY\n💓 Chờ đến: " .. THOI_GIAN_CHAY .. " (Bây giờ: " .. gioHienTai .. ")", true)
            end
        end
        sleep(5)
    end
    log("⏹️ Da ket thuc che do lap lich!")
end

local function testChayMotLan()
    log("🚀 TEST: Chay mot lan ngay lap tuc")
    chayChucNang()
end

local function menuLapLich()
    taiCauHinhLapLich()
    while true do
        local trangThaiBanner = (BAT_LAP_LICH == 1) and "✅ BẬT" or "❌ TẮT"
        local title = "⏰ Lập lịch [" .. trangThaiBanner .. "]\n"
            .. "· " .. tenChucNangLL() .. "  · " .. THOI_GIAN_CHAY .. "  · Nick BĐ: " .. NICK_BAT_DAU_LL .. "\n"
            .. "· " .. LAN_DA_CHAY_LL .. "/" .. SO_NGAY_LL .. " ngày  · còn " .. (SO_NGAY_LL - LAN_DA_CHAY_LL) .. " ngày"
        
        local choice = dialogChoice(title,
            "🔘 Bật/Tắt lịch",
            "🎯 Chọn chức năng",
            "🌾 Cài đặt Farm",
            "📅 Cài số ngày",
            "⏰ Cài giờ chạy",
            "🚩 Nick bắt đầu",
            "──────────────",
            "🧪 TEST (chạy 1 lần)",
            "🗑️ Reset tiến độ",
            "──────────────",
            "🚀 BẮT ĐẦU CHỜ LỊCH",
            "◀️ Quay lại"
        )
        
        if not choice or choice:find("Quay lại") then
            return
        elseif choice:find("Bật/Tắt lịch") then
            BAT_LAP_LICH = (BAT_LAP_LICH == 1) and 0 or 1
            luuCauHinhLapLich()
            toast((BAT_LAP_LICH == 1) and "✅ Đã bật lịch" or "❌ Đã tắt lịch")
        elseif choice:find("Chọn chức năng") then
            local cn = dialogChoice("CHỌN CHỨC NĂNG SẼ CHẠY KHI ĐẾN GIỜ",
                "🌾 FARM", "👤 KẾT BẠN UID", "👥 KẾT BẠN GỢI Ý", "🤝 CHẤP NHẬN KB", "🔑 NẠP NICK", "🎯 TƯƠNG TÁC POST", "💬 CMT BÀI VIẾT", "🚀 CHIA SẺ POST"
            )
            if cn then
                if cn:find("FARM") then CHUC_NANG_LL = "farm"
                elseif cn:find("KẾT BẠN UID") then CHUC_NANG_LL = "ketban_uid"
                elseif cn:find("KẾT BẠN GỢI Ý") then CHUC_NANG_LL = "ketban_gy"
                elseif cn:find("CHẤP NHẬN") then CHUC_NANG_LL = "chapnhan"
                elseif cn:find("NẠP NICK") then CHUC_NANG_LL = "nap"
                elseif cn:find("TƯƠNG TÁC POST") then CHUC_NANG_LL = "interact_post"
                elseif cn:find("CMT BÀI VIẾT") then CHUC_NANG_LL = "cmt_bai_viet"
                elseif cn:find("CHIA SẺ POST") then CHUC_NANG_LL = "share_bai_viet"
                end
                luuCauHinhLapLich()
                toast("✅ Đã chọn: " .. tenChucNangLL())
            end
        elseif choice:find("Cài đặt Farm") then
            if CHUC_NANG_LL == "farm" then
                menuCaiFarmLL()
            else
                toast("⚠️ Vui lòng chọn chức năng FARM trước!")
            end
        elseif choice:find("Cài số ngày") then
            local nhap = dialogInput("SỐ NGÀY CHẠY LIÊN TỤC", "Hiện tại: " .. SO_NGAY_LL)
            if nhap and tonumber(nhap) then
                SO_NGAY_LL = tonumber(nhap)
                luuCauHinhLapLich()
                toast("✅ Số ngày: " .. SO_NGAY_LL)
            end
        elseif choice:find("Cài giờ chạy") then
            local gio = chonGio()
            local phut = chonPhut()
            THOI_GIAN_CHAY = gio .. ":" .. phut
            luuCauHinhLapLich()
            toast("⏰ Giờ chạy: " .. THOI_GIAN_CHAY)
        elseif choice:find("Nick bắt đầu") then
            local nhap = dialogInput("Nick bắt đầu", "STT nick bắt đầu chạy:", tostring(NICK_BAT_DAU_LL))
            if nhap and tonumber(nhap) then
                NICK_BAT_DAU_LL = math.floor(tonumber(nhap))
                luuCauHinhLapLich()
                toast("✅ Nick bắt đầu: " .. NICK_BAT_DAU_LL)
            end
        elseif choice:find("TEST") then
            testChayMotLan()
        elseif choice:find("Reset tiến độ") then
            LAN_DA_CHAY_LL = 0
            NGAY_BAT_DAU_LL = os.date("%Y-%m-%d")
            luuCauHinhLapLich()
            toast("✅ Đã reset tiến độ!")
        elseif choice:find("BẮT ĐẦU CHỜ LỊCH") then
            if BAT_LAP_LICH == 0 then
                toast("⚠️ Vui lòng BẬT lịch trước!")
            else
                kiemTraLich()
                return
            end
        end
    end
end

-- ========== QUẢN LÝ PHÂN VÙNG CRANE (DÀNH CHO FACEBOOK) ==========
local APP_FB_CRANE = "com.facebook.Facebook"

-- ========== HÀM THÔNG BÁO GỌN ==========
local function notifyCrane(msg)
    if msg == nil or msg == "" then return end
    toast(msg)
    log(msg)
end

-- ========== SẮP XẾP TỰ NHIÊN (1, 2, 10...) ==========
local function naturalSortCrane(a, b)
    local function padDigits(s)
        return s:gsub("(%d+)", function(n) return string.format("%010d", tonumber(n)) end)
    end
    return padDigits(a:lower()) < padDigits(b:lower())
end

-- 1. LIỆT KÊ PHÂN VÙNG (CÓ PHÂN TRANG)
local function listContainersCrane(page)
    page = page or 1
    local pageSize = 100 -- Số lượng hiển thị mỗi trang
    
    local tmpFile = "/var/mobile/Documents/crane_list_tmp.txt"
    os.execute(string.format("cranectl --list %s > %s", APP_FB_CRANE, tmpFile))
    
    local data = {}
    local f = io.open(tmpFile, "r")
    if f then
        for line in f:lines() do
            local active = line:match("^%*")
            local name = line:match("^%s*%*?%s*(.-)%s*%(") or line:match("^%s*%*?%s*(.-)%s*$")
            if name and name ~= "" and not name:find("Container") and not name:find(":") then
                table.insert(data, {name = name, active = active})
            end
        end
        f:close()
        
        if #data == 0 then
            dialogChoice("📂 DANH SÁCH\n\n⚠️ Chưa có phân vùng nào!", "Đóng")
            return
        end
        
        local total = #data
        local totalPages = math.ceil(total / pageSize)
        local startIdx = (page - 1) * pageSize + 1
        local endIdx = math.min(page * pageSize, total)
        
        -- Tạo danh sách các nút bấm từ tên phân vùng
        local buttons = {}
        for i = startIdx, endIdx do
            local item = data[i]
            local label = item.name
            if item.active then
                label = "✓ " .. label .. " (Đang dùng)"
            else
                label = "  " .. label
            end
            table.insert(buttons, label)
        end
        
        -- Thêm các nút điều hướng
        if endIdx < total then table.insert(buttons, "Trang sau ▶️") end
        if page > 1 then table.insert(buttons, "◀️ Trang trước") end
        table.insert(buttons, "Đóng ❌")
        
        local title = string.format("📂 DANH SÁCH PHÂN VÙNG\n(Trang %d/%d - Tổng %d)", page, totalPages, total)
        local choice = dialogChoice(title, unpack(buttons))
        
        if choice == "Trang sau ▶️" then
            listContainersCrane(page + 1)
        elseif choice == "◀️ Trang trước" then
            listContainersCrane(page - 1)
        elseif choice and choice ~= "Đóng ❌" then
            -- Nếu bấm vào một phân vùng, hiện thông báo nhỏ rồi hiện lại danh sách
            toast("Bạn vừa chọn xem: " .. choice)
            listContainersCrane(page) 
        end
    else
        notifyCrane("❌ Lỗi: Không thể truy cập dữ liệu!")
    end
end

-- 2. TẠO HÀNG LOẠT (Ví dụ: fb1 -> fb10)
local function createBatchCrane()
    local prefix = dialogInput("➕ Tên Phân Vùng", "Nhập tên gợi nhớ (ví dụ: fb)", "fb")
    if not prefix or prefix == "" then return end
    
    local quantity_str = dialogInput("🔢 Số lượng", "Nhập số lượng cần tạo mới", "10")
    local quantity = tonumber(quantity_str)
    
    if not quantity or quantity <= 0 then
        notifyCrane("⚠️ Số lượng không hợp lệ!")
        return
    end
    
    local confirm = dialogChoice(string.format("🏗️ XÁC NHẬN TẠO\nTạo %d phân vùng từ '%s1' đến '%s%d'?", quantity, prefix, prefix, quantity), "✅ Bắt đầu", "Hủy bỏ ❌")
    
    if confirm == "✅ Bắt đầu" then
        for i = 1, quantity do
            local name = prefix .. i
            logScreen(string.format("⏳ Đang tạo (%d/%d): %s", i, quantity, name), true)
            os.execute(string.format("cranectl --create %s \"%s\"", APP_FB_CRANE, name))
            sleep(0.3)
        end
        dialogChoice("✅ Thành công: Đã tạo " .. quantity .. " phân vùng!", "Tuyệt vời")
    end
end

-- 3. XÓA DỮ LIỆU PHÂN VÙNG (Wipe)
local function wipeContainerCrane()
    local mode = dialogChoice("🧹 XÓA DỮ LIỆU", "🔥 XÓA TẤT CẢ DỮ LIỆU", "👆 Chọn xóa dữ liệu lẻ", "◀️ Quay lại")
    if not mode or mode:find("Quay lại") then return end
    
    -- Lấy danh sách phân vùng hiện tại
    local tmpFile = "/var/mobile/Documents/crane_list_tmp.txt"
    os.execute(string.format("cranectl --list %s > %s", APP_FB_CRANE, tmpFile))
    local names = {}
    local f = io.open(tmpFile, "r")
    if f then
        for line in f:lines() do
            local name = line:match("^%s*%*?%s*(.-)%s*%(") or line:match("^%s*%*?%s*(.-)%s*$")
            if name and name ~= "" and not name:find("Container") and not name:find(":") then
                table.insert(names, name)
            end
        end
        f:close()
    end

    if mode:find("XÓA TẤT CẢ DỮ LIỆU") then
        if #names == 0 then
            dialogChoice("⚠️ Không có phân vùng nào!", "Đóng")
            return
        end
        
        local confirm = dialogChoice("⚠️ XÁC NHẬN\nXóa sạch dữ liệu của TOÀN BỘ " .. #names .. " phân vùng Facebook?", "🔥 Đúng, xóa hết dữ liệu!", "Hủy bỏ")
        if confirm == "🔥 Đúng, xóa hết dữ liệu!" then
            for i, name in ipairs(names) do
                logScreen(string.format("🧹 Đang xóa dữ liệu (%d/%d): %s", i, #names, name), true)
                os.execute(string.format('cranectl --wipe %s name:"%s"', APP_FB_CRANE, name))
                sleep(0.2)
            end
            dialogChoice("✅ Đã làm sạch toàn bộ dữ liệu phân vùng!", "Xong")
        end
        
    elseif mode:find("Chọn xóa dữ liệu lẻ") then
        if #names == 0 then
            toast("⚠️ Danh sách trống!")
            return
        end
        
        table.insert(names, "◀️ Quay lại")
        local choice = dialogChoice("🧹 CHỌN PHÂN VÙNG CẦN XÓA DATA", unpack(names))
        if choice and choice ~= "◀️ Quay lại" then
            os.execute(string.format('cranectl --wipe %s name:"%s"', APP_FB_CRANE, choice))
            notifyCrane("🧹 Đã xóa dữ liệu: " .. choice)
            wipeContainerCrane() -- Hiện lại menu để xóa tiếp
        end
    end
end

-- 5. XÓA PHÂN VÙNG
local function deleteContainerCrane()
    local mode = dialogChoice("🗑️ TÙY CHỌN XÓA", "🔥 XÓA TẤT CẢ (Về mặc định)", "👆 Chọn xóa từng cái", "◀️ Quay lại")
    if not mode or mode:find("Quay lại") then return end
    
    -- Lấy danh sách phân vùng hiện tại
    local tmpFile = "/var/mobile/Documents/crane_list_tmp.txt"
    os.execute(string.format("cranectl --list %s > %s", APP_FB_CRANE, tmpFile))
    local names = {}
    local f = io.open(tmpFile, "r")
    if f then
        for line in f:lines() do
            local name = line:match("^%s*(.-)%s*%(") or line:match("^%s*(.-)%s*$")
            if name and name ~= "" and not name:find("Container") and not name:find(":") then
                if name ~= "Default" then
                    table.insert(names, name)
                end
            end
        end
        f:close()
    end
    
    if mode:find("XÓA TẤT CẢ") then
        if #names == 0 then
            dialogChoice("⚠️ Không có phân vùng nào để xóa!", "Đóng")
            return
        end
        
        local confirm = dialogChoice("⚠️ CẢNH BÁO\nBạn muốn xóa sạch TOÀN BỘ " .. #names .. " phân vùng Facebook?", "🔥 Đồng ý, xóa hết!", "Hủy bỏ")
        if confirm == "🔥 Đồng ý, xóa hết!" then
            for i, name in ipairs(names) do
                logScreen(string.format("🗑️ Đang xóa phân vùng (%d/%d): %s", i, #names, name), true)
                os.execute(string.format('cranectl --delete %s name:"%s"', APP_FB_CRANE, name))
                sleep(0.2)
            end
            dialogChoice("✅ Đã xóa sạch toàn bộ phân vùng!", "Xong")
        end
        
    elseif mode:find("Chọn xóa từng cái") then
        if #names == 0 then
            toast("⚠️ Danh sách trống!")
            return
        end
        
        table.insert(names, "◀️ Quay lại")
        
        local choice = dialogChoice("🗑️ CHỌN PHÂN VÙNG CẦN XÓA", unpack(names))
        if choice and choice ~= "◀️ Quay lại" then
            local confirm = dialogChoice("Xác nhận xóa vĩnh viễn:\n👉 " .. choice .. " ?", "🔥 Xóa ngay", "Hủy")
            if confirm == "🔥 Xóa ngay" then
                os.execute(string.format('cranectl --delete %s name:"%s"', APP_FB_CRANE, choice))
                notifyCrane("🗑️ Đã xóa: " .. choice)
                deleteContainerCrane() 
            end
        end
    end
end

-- ========== MENU QUẢN LÝ CRANE ==========
local function menuCrane()
    while true do
        local choice = dialogChoice("🛠️ QUẢN LÝ PHÂN\nVÙNG CRANE", 
            "📂 Danh sách phân vùng",
            "➕ Tạo phân vùng hàng loạt",
            "🧹 Xóa dữ liệu phân vùng",
            "🗑️ Xóa bỏ phân vùng",
            "❌ Thoát công cụ"
        )
        
        if not choice or choice == "❌ Thoát công cụ" then 
            break 
        end
        
        if choice:find("Danh sách") then
            listContainersCrane()
        elseif choice:find("Tạo phân vùng") then
            createBatchCrane()
        elseif choice:find("Xóa dữ liệu") then
            wipeContainerCrane()
        elseif choice:find("Xóa bỏ") then
            deleteContainerCrane()
        end
    end
end

local function menuChinh()
    local f = io.open(CONFIG_PATH, "r")
    if f then
        f:close()
        taiCauHinh()
        log("📂 Tu dong tai config da luu")
    end
    
    while true do
        local soBat = 0
        for _, feat in ipairs(GUI_FEATURES) do
            if layGiaTri(feat[2]) == 1 then soBat = soBat + 1 end
        end
        
        local title = "📱 Facebook Auto\n"
            .. "· Farm bật: " .. soBat .. "/" .. #GUI_FEATURES .. "  · Lặp: " .. SO_LAN_LAP .. " lần"
        
        local choice = dialogChoice(title,
            "⚙️ Bật/Tắt chức năng",
            "🔢 Cài đặt thông số",
            "📋 Xem cấu hình",
            "💾 Lưu cấu hình",
            "📂 Tải cấu hình",
            "🚀 BẮT ĐẦU FARM",
            "──────────────",
            "⏰ LẬP LỊCH TỰ ĐỘNG",
            "👤 KẾT BẠN THEO UID",
            "👥 KẾT BẠN GỢI Ý",
            "🤝 CHẤP NHẬN KẾT BẠN",
            "🔑 NẠP NICK",
            "🎯 TƯƠNG TÁC BÀI VIẾT THEO CHỈ ĐỊNH",
            "💬 CMT BÀI VIẾT CHỈ ĐỊNH",
            "🚀 CHIA SẺ BÀI VIẾT CHỈ ĐỊNH",
            "🛠️ QUẢN LÝ CRANE",
            "📂 TẠO FILE NỘI DUNG (MẪU)",
            "🗑️ XÓA TOÀN BỘ FILE",
            "🛡️ XEM HẠN SỬ DỤNG",
            "❌ Thoát"
        )
        
        if not choice or choice:find("Thoát") then
            toast("Đã thoát!")
            stop()
            return "exit"
        elseif choice:find("Bật/Tắt") then
            menuToggle()
        elseif choice:find("Cài đặt thông số") then
            menuSettings()
        elseif choice:find("Xem cấu hình") then
            dialogChoice("📋 CẤU HÌNH HIỆN TẠI\n\n" .. tomTatCauHinh(), "OK ✅")
        elseif choice:find("Lưu cấu hình") then
            luuCauHinh()
        elseif choice:find("Tải cấu hình") then
            taiCauHinh()
        elseif choice:find("LẬP LỊCH TỰ ĐỘNG") then
            menuLapLich()
        elseif choice:find("BẮT ĐẦU FARM") then
            if soBat == 0 then
                toast("⚠️ Chưa bật chức năng nào!")
            else
                local confirm = dialogChoice(
                    "🚀 XÁC NHẬN FARM\n\n" .. tomTatCauHinh(),
                    "✅ Chạy ngay!",
                    "◀️ Quay lại"
                )
                if confirm and confirm:find("Chạy ngay") then
                    luuCauHinh()
                    return "farm"
                end
            end
        elseif choice:find("KẾT BẠN THEO UID") then
            local result = menuKetBanUID()
            if result == "ket_ban_uid" then
                return "ket_ban_uid"
            end
        elseif choice:find("KẾT BẠN GỢI Ý") then
            local result = menuKetBanGoiY()
            if result == "ket_ban_goi_y" then
                return "ket_ban_goi_y"
            end
        elseif choice:find("CHẤP NHẬN KẾT BẠN") then
            local result = menuChapNhanKetBan()
            if result == "chap_nhan_kb" then
                return "chap_nhan_kb"
            end
        elseif choice:find("NẠP NICK") then
            local result = menuNapNick()
            if result == "nap_nick" then
                return "nap_nick"
            end
        elseif choice:find("TƯƠNG TÁC BÀI VIẾT") then
            local result = menuInteractPost()
            if result == "interact_post" then
                return "interact_post"
            end
        elseif choice:find("CMT BÀI VIẾT") then
            local result = menuCMTBaiViet()
            if result == "cmt_bai_viet" then
                return "cmt_bai_viet"
            end
        elseif choice:find("CHIA SẺ BÀI VIẾT") then
            local result = menuShareBaiViet()
            if result == "share_bai_viet" then
                return "share_bai_viet"
            end
        elseif choice:find("QUẢN LÝ CRANE") then
            menuCrane()
        elseif choice:find("TẠO FILE NỘI DUNG") then
            taoTatCaFileNoiDung()
        elseif choice:find("XÓA TOÀN BỘ FILE") then
            xoaTatCaFile()
        elseif choice:find("XEM HẠN SỬ DỤNG") then
            local now = os.time()
            local exp = _G.EXP_TIMESTAMP or 0
            if exp > now then
                local diff = exp - now
                local days = math.floor(diff / (24 * 60 * 60))
                local msg = string.format("Mã máy: %s\nHSD: %s\nCòn lại: %d ngày", 
                    getSN(), os.date("%d/%m/%Y %H:%M:%S", exp), days)
                dialogInput("🛡️ THÔNG TIN BẢN QUYỀN", msg, getSN())
            else
                dialogChoice("❌ Bản quyền đã hết hạn hoặc chưa kích hoạt!", "OK")
            end
        end
    end
end


-- ================================================================
-- ║  ENTRY POINT (ĐIỂM VÀO KHI MỞ SCRIPT)                      ║
-- ================================================================

-- 1. Xác thực bản quyền
if not xacThucKey() then
    log("❌ Chua xac thuc Key hoac Key het han. Dong script.")
    return
end

-- 2. Kiểm tra điều khoản sử dụng
kiemTraDieuKhoan()

local cheDo = menuChinh()

if cheDo == "exit" then
    return
elseif cheDo == "farm" then
    thucHienFarm()
elseif cheDo == "ket_ban_uid" then
    thucHienKetBanUID()
elseif cheDo == "ket_ban_goi_y" then
    thucHienKetBanGoiY()
elseif cheDo == "chap_nhan_kb" then
    thucHienChapNhanKetBan()
elseif cheDo == "nap_nick" then
    thucHienNapNick()
elseif cheDo == "interact_post" then
    thucHienInteractPost()
elseif cheDo == "cmt_bai_viet" then
    thucHienCMTBaiViet()
elseif cheDo == "share_bai_viet" then
    thucHienShareBaiViet()
end
