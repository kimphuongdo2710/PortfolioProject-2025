-- Check which database is connected
SELECT DB_NAME() AS CURRENTDATABASE
-- Change into the relevant database
USE hotel_revenue_tracking_10Mar25
GO

--Analysis started from here
SELECT *
FROM dbo.rooms_senior

SELECT *
FROM dbo.hotel_revenue_tracking_10Mar25.bookings_senior

-- 1. **Hiệu suất đặt phòng**:
	-- Phòng nào có tỷ lệ lấp đầy thấp nhất? total_booked_room by types/total_booked_all_types

WITH booking_count AS (
		SELECT  rooms.room_type, COUNT(*) AS booked_count
		FROM dbo.bookings_senior bks
		LEFT JOIN dbo.rooms_senior rooms
			ON bks.room_id = rooms.room_id
		WHERE bks.status = 'Confirmed'
		GROUP BY rooms.room_type), 

	total_booking_count AS (
		SELECT SUM(booked_count) AS total_booked
		FROM booking_count)

SELECT TOP 1 room_type, CAST(ROUND(booked_count*100.0/total_booked, 2) AS DECIMAL(10,1)) AS occupancy_rate
FROM booking_count
CROSS JOIN total_booking_count
ORDER BY occupancy_rate ASC

	-- Khách hàng thường đặt phòng theo mùa hay có xu hướng cụ thể?
-- Segment season by date on data of bookings

SELECT *
FROM dbo.bookings_senior

SELECT 
	CASE 
		WHEN MONTH(check_in) IN (1,2,3) THEN 'Winter'
		WHEN MONTH(check_in) IN (4,5,6) THEN 'Spring'
		WHEN MONTH(check_in) IN (7,8,9) THEN 'Summer'
		WHEN MONTH(check_in) IN (10,11,12) THEN 'Autumn'
	END AS season,
	COUNT(*) AS booking_count
FROM dbo.bookings_senior
WHERE status = 'Confirmed'
GROUP BY 
	CASE 
		WHEN month(check_in) IN (1,2,3) THEN 'Winter'
		WHEN month(check_in) IN (4,5,6) THEN 'Spring'
		WHEN month(check_in) IN (7,8,9) THEN 'Summer'
		WHEN month(check_in) IN (10,11,12) THEN 'Autumn'
	END
ORDER BY booking_count DESC

	-- Tỷ lệ lấp đầy phòng theo tháng là bao nhiêu?
 
WITH booked_count AS (
	SELECT MONTH(check_in) AS month, YEAR(check_in) AS year, COUNT(*) AS booked_count
	FROM bookings_senior bk
	LEFT JOIN rooms_senior rm
		ON bk.room_id = rm.room_id
	WHERE bk.status = 'Confirmed'
	GROUP BY MONTH(check_in), YEAR(check_in)),

	total_booked_count AS (
	SELECT year, SUM(booked_count) AS total_booked_count
	FROM booked_count
	GROUP BY year)

SELECT month, booked_count.year, CAST(ROUND(booked_count*100.0/total_booked_count,2) AS DECIMAL (10,2)) AS occupancy_rate
FROM booked_count
CROSS JOIN total_booked_count
ORDER BY 2, 1

	-- Tỷ lệ lấp đầy phòng theo mùa là bao nhiêu?

WITH booked_count AS (
	SELECT season, COUNT(*) AS booked_count
	FROM (SELECT CASE
			WHEN MONTH(check_in) IN (1,2,3) THEN 'Winter'
			WHEN MONTH(check_in) IN (4,5,6) THEN 'Spring'
			WHEN MONTH(check_in) IN (7,8,9) THEN 'Summer'
			WHEN MONTH(check_in) IN (10,11,12) THEN 'Autumn'
			END AS season
	FROM bookings_senior
	WHERE status = 'Confirmed') AS subquery
	GROUP BY season),

	total_booked_count AS (
	SELECT SUM(booked_count) AS total_booked_count
	FROM booked_count)

SELECT season, CAST(ROUND(booked_count*100.0/total_booked_count,2) AS DECIMAL(10,2)) AS occupancy_rate
FROM booked_count
CROSS JOIN total_booked_count
ORDER BY 2


-- 1A. Hướng Phát Hiện Bất Thường (Anomaly Detection) --> Một báo cáo phát hiện gian lận trong đặt phòng & thanh toán
	-- Có giao dịch thanh toán nào bất thường không?
	-- bất thường 1: Thanh toán sau khi hủy (Refund Fraud)

SELECT b.booking_id, p.payment_id, b.check_in, p.payment_date, b.status
FROM dbo.payments_senior p
JOIN bookings_senior b
	ON p.booking_id = b.booking_id
WHERE check_in < payment_date
 AND status IN ('Cancelled', 'Pending')

	-- bất thường 2: Đặt phòng trùng lặp (Duplicate Bookings) - Result: NO
SELECT c.customer_id, COUNT(*) AS booking_count
FROM bookings_senior b
JOIN customers_senior c
	ON b.customer_id = c.customer_id
GROUP BY c.customer_id, check_in, check_out
HAVING COUNT(*) > 1

	-- bất thường 3: Kiểm tra thanh toán nhiều lần từ cùng một thẻ (Multiple Payments) - Result: ...
	
SELECT *
FROM dbo.payments_senior p
JOIN bookings_senior b
	ON p.booking_id = b.booking_id

	-- bất thường 4: Tìm những khách đặt phòng nhưng không đến (No-Show Fraud) - Result: 106 rows

SELECT c.customer_id, SUM(p.amount) AS total_paid, MIN(b.check_in) AS first_check_in, MAX(b.check_out) AS last_check_out 
		, COUNT(*) AS cancelled_count
FROM bookings_senior b
JOIN customers_senior c
	ON b.customer_id = c.customer_id
JOIN payments_senior p
	ON b.booking_id = p.booking_id
WHERE status = 'Cancelled'
GROUP BY c.customer_id
HAVING COUNT(*) > 3


-----------
	-- Có ai đặt phòng liên tục nhưng hủy nhiều lần không?
	-- Có nhóm khách nào lợi dụng chính sách đặt phòng để gian lận không?

-- 2. **Doanh thu & Dịch vụ** - Kết quả mong đợi: Một bảng phân tích tổng quan về hiệu suất đặt phòng, doanh thu, khách hàng và dịch vụ
    -- Những dịch vụ nào được sử dụng nhiều nhất?
	-- Dịch vụ nào mang lại doanh thu cao nhất?
    -- Khách sạn có phụ thuộc quá nhiều vào một nhóm khách hàng cụ thể không?
	-- Phòng nào có doanh thu cao nhất?

--3. **Tối ưu hóa giá phòng** - Kết quả mong đợi: Một mô hình đề xuất giá phòng theo thời gian để tối đa hóa doanh thu
    -- Giá phòng hiện tại có ảnh hưởng đến lượng đặt phòng không?
    -- Nên điều chỉnh giá theo mùa hay không?
	-- Mức giá tối ưu để tối đa hóa lợi nhuận là bao nhiêu?

--4. **Tỷ lệ hủy phòng**:
    -- Bao nhiêu % đặt phòng bị hủy? Tỷ lệ hủy đặt phòng trung bình là bao nhiêu?
    -- Có lý do nào phổ biến dẫn đến việc hủy phòng không?

--5. Hướng Dự Đoán & Phân Loại Khách Hàng (Customer Segmentation & Churn Prediction) 
	--> Một bảng phân tích nhóm khách hàng kèm theo chiến lược cá nhân hóa ưu đãi
	-- Ai là khách hàng VIP?
	-- Có bao nhiêu khách hàng có nguy cơ rời bỏ khách sạn?
	-- Nhóm khách nào sử dụng dịch vụ nhiều nhất?
	-- Có bao nhiêu % khách quay lại đặt phòng?