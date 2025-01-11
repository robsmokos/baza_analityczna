use BikeStores_Analytics; 


-- Tabela Fact_Sales
CREATE TABLE Fact_Sales (
    sale_id INT PRIMARY KEY IDENTITY(1,1),
    store_id INT,
    product_id INT,
    category_id INT,
    staff_id INT,
    customer_id INT,
    date_id INT,
    quantity INT,
    total_revenue DECIMAL(12,2),
    discount DECIMAL(10,2),
    FOREIGN KEY (store_id) REFERENCES Dim_Stores(store_id),
    FOREIGN KEY (product_id) REFERENCES Dim_Products(product_id),
    FOREIGN KEY (category_id) REFERENCES Dim_Categories(category_id),
    FOREIGN KEY (staff_id) REFERENCES Dim_Staffs(staff_id),
    FOREIGN KEY (customer_id) REFERENCES Dim_Customers(customer_id),
    FOREIGN KEY (date_id) REFERENCES Dim_Time(date_id)
);




1. Tworzenie tabel wymiarów

-- Tabela Dim_Stores
CREATE TABLE Dim_Stores (
    store_id INT PRIMARY KEY,
    store_name NVARCHAR(100),
    store_phone NVARCHAR(20),
    store_email NVARCHAR(100),
    store_street NVARCHAR(200),
    store_city NVARCHAR(100),
    store_state NVARCHAR(100),
    store_zipcode NVARCHAR(10)
);

-- Tabela Dim_Products
CREATE TABLE Dim_Products (
    product_id INT PRIMARY KEY,
    product_name NVARCHAR(100),
    brand_id INT,
    category_id INT,
    list_price DECIMAL(10,2)
);

-- Tabela Dim_Categories
CREATE TABLE Dim_Categories (
    category_id INT PRIMARY KEY,
    category_name NVARCHAR(100)
);

-- Tabela Dim_Staffs
CREATE TABLE Dim_Staffs (
    staff_id INT PRIMARY KEY,
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    full_name AS (first_name + ' ' + last_name), -- Dodanie kolumny obliczeniowej
    email NVARCHAR(100),
    phone NVARCHAR(20),
    active BIT,
    store_id INT,
    FOREIGN KEY (store_id) REFERENCES Dim_Stores(store_id)
);

-- Tabela Dim_Customers
CREATE TABLE Dim_Customers (
    customer_id INT PRIMARY KEY,
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    full_name AS (first_name + ' ' + last_name), -- Kolumna obliczeniowa
    email NVARCHAR(100),
    phone NVARCHAR(20),
    street NVARCHAR(100),
    city NVARCHAR(50),
    state NVARCHAR(50),
    zip_code NVARCHAR(10)
);

-- Tabela Dim_Time
CREATE TABLE Dim_Time (
    date_id INT PRIMARY KEY IDENTITY(1,1),
    order_date DATE,
    year INT,
    quarter INT,
    month INT,
    day INT
);









2. Tworzenie tabeli faktów


Zasilanie tabel wymiarów




DELETE FROM BikeStores_Analytics.dbo.Dim_Staffs;
DELETE FROM BikeStores_Analytics.dbo.Dim_Customers;
DELETE FROM BikeStores_Analytics.dbo.Dim_Products;
DELETE FROM BikeStores_Analytics.dbo.Dim_Categories;
DELETE FROM BikeStores_Analytics.dbo.Dim_Time;
DELETE FROM BikeStores_Analytics.dbo.Dim_Stores;




1. Zasilanie Dim_Stores


INSERT INTO BikeStores_Analytics.dbo.Dim_Stores (
    store_id, store_name, store_phone, store_email, store_street, store_city, store_state, store_zipcode
)
SELECT 
    store_id, store_name, phone, email, street, city, state, zip_code
FROM BikeStores.sales.stores;

2. Zasilanie Dim_Products

INSERT INTO BikeStores_Analytics.dbo.Dim_Products (
    product_id, product_name, brand_id, category_id, list_price
)
SELECT 
    product_id, product_name, brand_id, category_id, list_price
FROM BikeStores.production.products;

3. Zasilanie Dim_Categories

INSERT INTO BikeStores_Analytics.dbo.Dim_Categories (
    category_id, category_name
)
SELECT 
    category_id, category_name
FROM BikeStores.production.categories;

4. Zasilanie Dim_Staffs

INSERT INTO BikeStores_Analytics.dbo.Dim_Staffs (
    staff_id, first_name, last_name, email, phone, active, store_id
)
SELECT 
    staff_id, first_name, last_name, email, phone, active, store_id
FROM BikeStores.sales.staffs;

5. Zasilanie Dim_Customers

INSERT INTO BikeStores_Analytics.dbo.Dim_Customers (
    customer_id, first_name, last_name, email, phone, street, city, state, zip_code
)
SELECT 
    customer_id, first_name, last_name, email, phone, street, city, state, zip_code
FROM BikeStores.sales.customers;

6. Zasilanie Dim_Time

INSERT INTO BikeStores_Analytics.dbo.Dim_Time (
    order_date, year, quarter, month, day
)
SELECT DISTINCT 
    o.order_date, 
    YEAR(o.order_date) AS year,
    DATEPART(QUARTER, o.order_date) AS quarter,
    MONTH(o.order_date) AS month,
    DAY(o.order_date) AS day
FROM BikeStores.sales.orders AS o;

Zasilanie tabeli faktów Fact_Sales

Tabela faktów ³¹czy dane z kilku Ÿróde³, takich jak zamówienia, produkty, kategorie, pracownicy, klienci i czas.

INSERT INTO BikeStores_Analytics.dbo.Fact_Sales (
    store_id, product_id, category_id, staff_id, customer_id, date_id, quantity, total_revenue, discount
)
SELECT 
    o.store_id,
    oi.product_id,
    p.category_id,
    o.staff_id,
    o.customer_id,
    t.date_id,
    SUM(oi.quantity) AS quantity,
    SUM(oi.quantity * oi.list_price * (1 - ISNULL(oi.discount, 0))) AS total_revenue,
    SUM(ISNULL(oi.discount, 0)) AS discount
FROM BikeStores.sales.orders AS o
JOIN BikeStores.sales.order_items AS oi ON o.order_id = oi.order_id
JOIN BikeStores.production.products AS p ON oi.product_id = p.product_id
JOIN BikeStores_Analytics.dbo.Dim_Time AS t ON o.order_date = t.order_date
GROUP BY 
    o.store_id, oi.product_id, p.category_id, o.staff_id, o.customer_id, t.date_id;