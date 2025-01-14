-- Przejœcie do bazy master, aby umo¿liwiæ operacje na innej bazie danych
USE master;

-- Wymuszenie zamkniêcia wszystkich po³¹czeñ i usuniêcie bazy danych
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BikeStores_Analytics')
BEGIN
    ALTER DATABASE BikeStores_Analytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BikeStores_Analytics;
END;

-- Tworzenie nowej bazy danych
CREATE DATABASE BikeStores_Analytics;

-- Ustawienie nowej bazy danych jako aktywnej
USE BikeStores_Analytics;

-- Potwierdzenie, ¿e nowa baza danych jest aktywna
SELECT DB_NAME() AS ActiveDatabase;




--PROCES ETL
--PROCES ETL
--PROCES ETL


-- 1. Tworzenie tabel wymiarów-- 
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

-- Tworzenie tabeli faktów
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





DELETE FROM BikeStores_Analytics.dbo.Dim_Staffs;
DELETE FROM BikeStores_Analytics.dbo.Dim_Customers;
DELETE FROM BikeStores_Analytics.dbo.Dim_Products;
DELETE FROM BikeStores_Analytics.dbo.Dim_Categories;
DELETE FROM BikeStores_Analytics.dbo.Dim_Time;
DELETE FROM BikeStores_Analytics.dbo.Dim_Stores;



-- LOAD
-- LOAD

-- 1. Zasilanie Dim_Stores

INSERT INTO BikeStores_Analytics.dbo.Dim_Stores (
    store_id, store_name, store_phone, store_email, store_street, store_city, store_state, store_zipcode
)
SELECT 
    store_id, store_name, phone, email, street, city, state, zip_code
FROM BikeStores.sales.stores;

-- 2. Zasilanie Dim_Products

INSERT INTO BikeStores_Analytics.dbo.Dim_Products (
    product_id, product_name, brand_id, category_id, list_price
)
SELECT 
    product_id, product_name, brand_id, category_id, list_price
FROM BikeStores.production.products;

-- 3. Zasilanie Dim_Categories

INSERT INTO BikeStores_Analytics.dbo.Dim_Categories (
    category_id, category_name
)
SELECT 
    category_id, category_name
FROM BikeStores.production.categories;

-- 4. Zasilanie Dim_Staffs

INSERT INTO BikeStores_Analytics.dbo.Dim_Staffs (
    staff_id, first_name, last_name, email, phone, active, store_id
)
SELECT 
    staff_id, first_name, last_name, email, phone, active, store_id
FROM BikeStores.sales.staffs;

-- 5. Zasilanie Dim_Customers

INSERT INTO BikeStores_Analytics.dbo.Dim_Customers (
    customer_id, first_name, last_name, email, phone, street, city, state, zip_code
)
SELECT 
    customer_id, first_name, last_name, email, phone, street, city, state, zip_code
FROM BikeStores.sales.customers;

-- 6. Zasilanie Dim_Time

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







-- Zasilanie tabeli faktów Fact_Sales
--Tabela faktów ³¹czy dane z kilku Ÿróde³, takich jak zamówienia, produkty, kategorie, pracownicy, klienci i czas.

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



-- sprawdzenie zawartoœci baz Analityzcnej

USE BikeStores_Analytics;

SELECT * FROM Dim_Stores;
SELECT * FROM Dim_Products;
SELECT * FROM Dim_Categories;
SELECT * FROM Dim_Staffs;
SELECT * FROM Dim_Customers;






--- OPTYMALIZACJA BAZY ANALITYCZNEJ
--- OPTYMALIZACJA BAZY ANALITYCZNEJ

CREATE INDEX idx_fact_sales_product_id ON Fact_Sales (product_id);
CREATE INDEX idx_fact_sales_date_id ON Fact_Sales (date_id);



USE BikeStores_Analytics;

-- TEST PORÓWNAWCZY WYNIKÓW Z BAZY RELACYJNEJ I ANALITYCZNEJ
-- TEST PORÓWNAWCZY WYNIKÓW Z BAZY RELACYJNEJ I ANALITYCZNEJ


/* 1.BazaAnalityczna*/

SELECT 
    c.customer_id,                                 -- ID klienta
    c.full_name AS customer_name,                 -- Pe³ne imiê i nazwisko klienta
    COALESCE(cat.category_name, 'No Category') AS category_name, -- Nazwa kategorii lub 'No Category' dla NULL
    SUM(f.quantity) AS total_bikes_purchased      -- Suma iloœci kupionych rowerów
FROM Fact_Sales AS f
JOIN Dim_Customers AS c ON f.customer_id = c.customer_id    -- Po³¹czenie z wymiarem klientów
JOIN Dim_Products AS p ON f.product_id = p.product_id       -- Po³¹czenie z wymiarem produktów
LEFT JOIN Dim_Categories AS cat ON p.category_id = cat.category_id -- Po³¹czenie z wymiarem kategorii
GROUP BY c.customer_id, c.full_name, cat.category_name      -- Grupowanie po kliencie i kategorii
ORDER BY c.customer_id, total_bikes_purchased DESC;         -- Sortowanie po ID klienta i liczbie kupionych rowerów malej¹co




/* 2.BazaAnalityczna*/
SELECT 
    s.staff_id,  -- ID pracownika
    s.full_name AS employee_name,  -- Pe³ne imiê i nazwisko pracownika
    CASE 
        WHEN p.brand_id IS NULL THEN 'No Brand'  -- Zamiana NULL na tekst
        ELSE CAST(p.brand_id AS NVARCHAR)       -- Konwersja ID marki na tekst
    END AS brand_name,  -- Tekstowa reprezentacja marki
    SUM(ISNULL(f.quantity, 0)) AS total_products_sold  -- Suma iloœci sprzedanych produktów
FROM Dim_Staffs AS s
LEFT JOIN Fact_Sales AS f ON s.staff_id = f.staff_id  -- Po³¹czenie z faktami sprzeda¿y
LEFT JOIN Dim_Products AS p ON f.product_id = p.product_id  -- Po³¹czenie z produktami
GROUP BY s.staff_id, s.full_name, p.brand_id  -- Grupowanie po pracowniku i marce
ORDER BY s.staff_id, total_products_sold DESC;  -- Sortowanie po ID pracownika i liczbie sprzedanych produktów malej¹co


/* 3.BazaAnalityczna*/

SELECT 
    s.staff_id,                                -- ID pracownika
    s.full_name AS employee_name,             -- Pe³ne imiê i nazwisko pracownika
    t.year AS sales_year,                     -- Rok sprzeda¿y
    SUM(f.quantity) AS total_products_sold,   -- £¹czna liczba sprzedanych produktów
    SUM(f.quantity * p.list_price * (1 - ISNULL(f.discount, 0))) AS total_sales_value -- Suma wartoœci sprzeda¿y z rabatem
FROM Fact_Sales AS f
JOIN Dim_Staffs AS s ON f.staff_id = s.staff_id      -- Po³¹czenie z wymiarem pracowników
JOIN Dim_Time AS t ON f.date_id = t.date_id         -- Po³¹czenie z wymiarem czasu
JOIN Dim_Products AS p ON f.product_id = p.product_id -- Po³¹czenie z wymiarem produktów
WHERE t.year IS NOT NULL                            -- Pominiêcie brakuj¹cych lat
GROUP BY s.staff_id, s.full_name, t.year            -- Grupowanie po pracowniku i roku
ORDER BY total_sales_value DESC;                   -- Sortowanie po wartoœci sprzeda¿y malej¹co





/* 4.BazaAnalityczna*/
WITH ProductSales AS (
    SELECT 
        s.store_id, 
        s.store_name,                       -- Nazwa sklepu
        p.product_id, 
        p.product_name,                     -- Nazwa produktu
        SUM(f.quantity) AS total_sold,      -- £¹czna liczba sprzedanych sztuk
        RANK() OVER (PARTITION BY s.store_id ORDER BY SUM(f.quantity) DESC) AS rank
        -- Funkcja RANK() klasyfikuje produkty w ka¿dym sklepie po liczbie sprzedanych sztuk
    FROM Dim_Stores AS s
    JOIN Fact_Sales AS f ON s.store_id = f.store_id          -- Po³¹czenie faktów sprzeda¿y ze sklepami
    JOIN Dim_Products AS p ON f.product_id = p.product_id   -- Po³¹czenie faktów sprzeda¿y z produktami
    GROUP BY s.store_id, s.store_name, p.product_id, p.product_name
)
SELECT 
    store_id,
    store_name,
    product_name,
    total_sold
FROM ProductSales
WHERE rank = 1 -- Wyœwietlamy tylko produkty z rankiem 1 (najlepiej sprzedaj¹cy siê produkt)
ORDER BY store_id;



/* 5.BazaAnalityczna*/
SELECT TOP 10
    p.product_id,                                  -- ID produktu
    p.product_name,                                -- Nazwa produktu
    SUM(f.quantity * p.list_price * (1 - ISNULL(f.discount, 0))) AS total_revenue
    -- Obliczenie dochodu: iloœæ * cena jednostkowa * (1 - rabat); rabat traktujemy jako 0 jeœli NULL
FROM Fact_Sales AS f
JOIN Dim_Products AS p ON f.product_id = p.product_id -- Po³¹czenie z tabel¹ produktów
GROUP BY p.product_id, p.product_name       -- Grupowanie wyników po ID i nazwie produktu
ORDER BY total_revenue DESC;                -- Sortowanie malej¹co wed³ug dochodu


/* 6.BazaAnalityczna*/
SELECT TOP 10
    p.product_id,                    -- ID produktu
    p.product_name,                  -- Nazwa produktu
    SUM(f.quantity) AS total_sold    -- £¹czna liczba sprzedanych sztuk
FROM Fact_Sales AS f
JOIN Dim_Products AS p ON f.product_id = p.product_id -- Po³¹czenie z tabel¹ wymiaru produktów
GROUP BY p.product_id, p.product_name -- Grupowanie po ID i nazwie produktu
ORDER BY total_sold DESC;            -- Sortowanie malej¹co po liczbie sprzedanych sztuk



/* 7.BazaAnalityczna*/
WITH CategorySales AS (
    SELECT 
        s.store_id, 
        s.store_name,                         -- Nazwa sklepu
        c.category_id, 
        c.category_name,                      -- Nazwa kategorii
        SUM(f.quantity) AS total_sold,        -- £¹czna liczba sprzedanych sztuk
        RANK() OVER (PARTITION BY s.store_id 
                     ORDER BY SUM(f.quantity) ASC) AS rank -- Klasyfikacja kategorii w sklepie
    FROM Dim_Stores AS s
    JOIN Fact_Sales AS f ON s.store_id = f.store_id         -- Po³¹czenie tabeli faktów z wymiarem sklepów
    JOIN Dim_Products AS p ON f.product_id = p.product_id   -- Po³¹czenie tabeli faktów z wymiarem produktów
    JOIN Dim_Categories AS c ON p.category_id = c.category_id -- Po³¹czenie wymiaru produktów z wymiarem kategorii
    GROUP BY s.store_id, s.store_name, c.category_id, c.category_name
)
SELECT 
    store_id, 
    store_name, 
    category_name, 
    total_sold
FROM CategorySales
WHERE rank = 1 -- Wyœwietlenie tylko najlepiej sprzedaj¹cych siê kategorii w ka¿dym sklepie
ORDER BY store_id;

SELECT TOP 10
    p.product_id,                    -- ID produktu
    p.product_name,                  -- Nazwa produktu
    SUM(f.quantity) AS total_sold    -- £¹czna liczba sprzedanych sztuk
FROM Fact_Sales AS f
JOIN Dim_Products AS p ON f.product_id = p.product_id -- Po³¹czenie z tabel¹ wymiaru produktów
GROUP BY p.product_id, p.product_name -- Grupowanie po ID i nazwie produktu
ORDER BY total_sold DESC;            -- Sortowanie malej¹co po liczbie sprzedanych sztuk




SELECT TABLE_SCHEMA AS SchemaName,
       TABLE_NAME AS TableName,
       TABLE_TYPE AS TableType
FROM INFORMATION_SCHEMA.TABLES
ORDER BY SchemaName, TableName;






--BACKUP--
BACKUP DATABASE [BikeStores_Analytics]
TO DISK = 'C:\DATA\ROB\baza_analityczna\BikeStores_Analytics.bak'
WITH FORMAT, INIT,
     NAME = 'BikeStores_Analytics_New-Full Database Backup',
     SKIP, REWIND, NOUNLOAD, STATS = 10;
GO
