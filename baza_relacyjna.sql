use BikeStores;
SELECT *  FROM sales.customers;
SELECT *  FROM sales.orders;
SELECT *  FROM sales.order_items;
SELECT *  FROM sales.staffs;
SELECT *  FROM sales.stores;
SELECT *  FROM production.categories;
SELECT *  FROM production.products;
SELECT *  FROM production.brands;



-- Aby wyœwietliæ wszystkie tabele w bazie danych w Microsoft SQL Server

SELECT TABLE_SCHEMA AS SchemaName,
       TABLE_NAME AS TableName,
       TABLE_TYPE AS TableType
FROM INFORMATION_SCHEMA.TABLES
ORDER BY SchemaName, TableName;



-- TEST PORÓWNAWCZY WYNIKÓW Z BAZY RELACYJNEJ I ANALITYCZNEJ
-- TEST PORÓWNAWCZY WYNIKÓW Z BAZY RELACYJNEJ I ANALITYCZNEJ


/* 1.
Zapytanie SQL: Wyœwietlenie wszystkich klientów i liczby rowerów zakupionych w podziale na kategorie.

Cel:
- Dla ka¿dego klienta wyœwietlamy jego imiê i nazwisko oraz sumaryczn¹ liczbê zakupionych rowerów.
- Dane s¹ grupowane wed³ug klientów i kategorii produktów.
- Uwzglêdniono równie¿ klientów, którzy nie dokonali zakupu.

Szczegó³y dzia³ania:
1. £¹czymy tabele: customers, orders, order_items, products i categories.
3. Zastêpowanie wartoœci NULL:
   - Jeœli kategoria nie istnieje, wyœwietlamy 'No Category'.
   - Jeœli iloœæ zakupionych rowerów jest NULL, zastêpujemy j¹ zerem (0).
4. Grupowanie wyników:
   - Grupujemy dane po kliencie i kategorii produktów.
5. Sortowanie wyników:
   - Klienci s¹ sortowani wed³ug ID, a liczba zakupionych rowerów malej¹co.
*/
SELECT 
    c.customer_id,  -- ID klienta
    c.first_name + ' ' + c.last_name AS customer_name,  -- Po³¹czone imiê i nazwisko klienta
    COALESCE(cat.category_name, 'No Category') AS category_name, -- Nazwa kategorii lub 'No Category' dla wartoœci NULL
    SUM(ISNULL(oi.quantity, 0)) AS total_bikes_purchased -- Suma iloœci kupionych rowerów (NULL zast¹pione 0)
FROM sales.customers AS c
LEFT JOIN sales.orders AS o ON c.customer_id = o.customer_id 
LEFT JOIN sales.order_items AS oi ON o.order_id = oi.order_id
LEFT JOIN production.products AS p ON oi.product_id = p.product_id
LEFT JOIN production.categories AS cat ON p.category_id = cat.category_id
GROUP BY c.customer_id, c.first_name, c.last_name, cat.category_name -- Grupowanie po kliencie i kategorii
ORDER BY c.customer_id, total_bikes_purchased DESC; -- Sortowanie po ID klienta i liczbie zakupionych rowerów malej¹co



/* 2.
Zapytanie SQL: Wyœwietlenie pracowników sklepu oraz liczby produktów sprzedanych w podziale na marki.

Co robi to zapytanie:
1. Pobiera dane o pracownikach, którzy realizowali sprzeda¿ (zamówienia).
2. £¹czy dane z informacjami o produktach i ich markach, aby okreœliæ, ile produktów ka¿dej marki sprzeda³ ka¿dy pracownik.
3. Uwzglêdnia wszystkich pracowników, nawet jeœli nie sprzedali ¿adnych produktów.
4. Suma sprzedanych produktów jest obliczana na podstawie iloœci z tabeli `order_items`.
5. Obs³ugiwane s¹ przypadki, gdzie marka produktu jest nieznana (`NULL`), zamieniaj¹c je na "No Brand".
6. Wyniki s¹ grupowane wed³ug pracowników i marek produktów.
7. Na koñcu wyniki s¹ posortowane:
   - Po ID pracownika rosn¹co,
   - Po liczbie sprzedanych produktów malej¹co.
*/
use BikeStores;
SELECT 
    s.staff_id,  -- ID pracownika
    s.first_name + ' ' + s.last_name AS employee_name,  -- Po³¹czone imiê i nazwisko pracownika
    COALESCE(b.brand_name, 'No Brand') AS brand_name,   -- Nazwa marki lub 'No Brand', jeœli NULL
    SUM(ISNULL(oi.quantity, 0)) AS total_products_sold  -- Suma iloœci sprzedanych produktów
FROM sales.staffs AS s
LEFT JOIN sales.orders AS o ON s.staff_id = o.staff_id  -- Po³¹czenie z zamówieniami
LEFT JOIN sales.order_items AS oi ON o.order_id = oi.order_id  -- Po³¹czenie z pozycjami zamówieñ
LEFT JOIN production.products AS p ON oi.product_id = p.product_id  -- Po³¹czenie z produktami
LEFT JOIN production.brands AS b ON p.brand_id = b.brand_id  -- Po³¹czenie z markami produktów
GROUP BY s.staff_id, s.first_name, s.last_name, b.brand_name  -- Grupowanie po pracowniku i marce
ORDER BY s.staff_id, total_products_sold DESC;  -- Sortowanie po pracowniku i liczbie sprzedanych produktów malej¹co





/* 3.
Zapytanie SQL: Wyliczenie sumy rocznej sprzeda¿y dla pracowników z uwzglêdnieniem rabatu na produkty.

Co robi to zapytanie:
1. Pobiera dane o pracownikach, iloœci sprzedanych produktów oraz wartoœæ sprzeda¿y uwzglêdniaj¹c rabat.
2. Wylicza wartoœæ sprzeda¿y dla ka¿dego zamówienia wed³ug wzoru:
   - Wartoœæ sprzeda¿y = iloœæ * cena jednostkowa * (1 - rabat).
3. Sumuje sprzeda¿ i iloœæ sprzedanych produktów dla ka¿dego pracownika i roku.
4. Grupuje dane po pracowniku i roku sprzeda¿y.
5. Sortuje wyniki wed³ug ³¹cznej wartoœci sprzeda¿y malej¹co.
*/


SELECT 
    s.staff_id, 
    s.first_name + ' ' + s.last_name AS employee_name,  -- Po³¹czone imiê i nazwisko pracownika
    YEAR(o.order_date) AS sales_year,                  -- Rok sprzeda¿y
    SUM(oi.quantity) AS total_products_sold,           -- £¹czna liczba sprzedanych produktów
    SUM(oi.quantity * oi.list_price * (1 - ISNULL(oi.discount, 0))) AS total_sales_value -- Suma wartoœci sprzeda¿y z rabatem
FROM sales.staffs AS s
JOIN sales.orders AS o ON s.staff_id = o.staff_id       -- Po³¹czenie z zamówieniami
JOIN sales.order_items AS oi ON o.order_id = oi.order_id -- Po³¹czenie z pozycjami zamówieñ
WHERE o.order_date IS NOT NULL -- Pominiêcie brakuj¹cych dat zamówieñ
GROUP BY s.staff_id, s.first_name, s.last_name, YEAR(o.order_date) -- Grupowanie po pracowniku i roku
ORDER BY total_sales_value DESC; -- Sortowanie po wartoœci sprzeda¿y malej¹co





/* 4.
Zapytanie SQL: Wyœwietlenie wszystkich sklepów oraz najlepiej sprzedaj¹cego siê produktu w ka¿dym z nich.

Co robi to zapytanie:
1. Dla ka¿dego sklepu oblicza sumaryczn¹ liczbê sprzedanych sztuk dla ka¿dego produktu.
2. U¿ywa funkcji okna `RANK()` do uszeregowania produktów w ka¿dym sklepie wed³ug liczby sprzedanych sztuk (malej¹co).
3. Wyœwietla tylko te produkty, które maj¹ najwy¿sz¹ liczbê sprzedanych sztuk w danym sklepie (RANK = 1).
4. Zwraca nazwê sklepu, nazwê produktu oraz liczbê sprzedanych sztuk.
*/
WITH ProductSales AS (
    SELECT 
        s.store_id, 
        s.store_name,                       -- Nazwa sklepu
        p.product_id, 
        p.product_name,                     -- Nazwa produktu
        SUM(oi.quantity) AS total_sold,     -- £¹czna liczba sprzedanych sztuk
        RANK() OVER (PARTITION BY s.store_id ORDER BY SUM(oi.quantity) DESC) AS rank
        -- Funkcja RANK() klasyfikuje produkty w ka¿dym sklepie po liczbie sprzedanych sztuk
    FROM sales.stores AS s
    JOIN sales.orders AS o ON s.store_id = o.store_id         -- Po³¹czenie zamówieñ ze sklepami
    JOIN sales.order_items AS oi ON o.order_id = oi.order_id  -- Po³¹czenie szczegó³ów zamówieñ
    JOIN production.products AS p ON oi.product_id = p.product_id -- Po³¹czenie z produktami
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







/* 5.
Zapytanie SQL: Wyœwietlenie 10 produktów, których sprzeda¿ przynios³a najwy¿szy dochód.

Co robi to zapytanie:
1. Oblicza dochód dla ka¿dego produktu na podstawie wzoru:
   - Dochód = iloœæ * cena jednostkowa * (1 - rabat).
2. Grupuje wyniki po ID i nazwie produktu.
3. Sumuje dochód dla ka¿dego produktu.
4. Sortuje produkty wed³ug ³¹cznego dochodu malej¹co.
5. Ogranicza wyniki do 10 najlepszych produktów.
*/


SELECT TOP 10
    p.product_id,                                  -- ID produktu
    p.product_name,                                -- Nazwa produktu
    SUM(oi.quantity * oi.list_price * (1 - ISNULL(oi.discount, 0))) AS total_revenue
    -- Obliczenie dochodu: iloœæ * cena jednostkowa * (1 - rabat); rabat traktujemy jako 0 jeœli NULL
FROM sales.order_items AS oi
JOIN production.products AS p ON oi.product_id = p.product_id -- Po³¹czenie z tabel¹ produktów
GROUP BY p.product_id, p.product_name       -- Grupowanie wyników po ID i nazwie produktu
ORDER BY total_revenue DESC;                -- Sortowanie malej¹co wed³ug dochodu







/* 6. 
najczêsciej sprzedawany produkt
*/
SELECT TOP 10
    p.product_id,                    -- ID produktu
    p.product_name,                  -- Nazwa produktu
    SUM(oi.quantity) AS total_sold   -- £¹czna liczba sprzedanych sztuk
FROM sales.order_items AS oi
JOIN production.products AS p ON oi.product_id = p.product_id -- Po³¹czenie z tabel¹ produktów
GROUP BY p.product_id, p.product_name -- Grupowanie po ID i nazwie produktu
ORDER BY total_sold DESC;            -- Sortowanie malej¹co po liczbie sprzedanych sztuk




/* 7.
Zapytanie SQL: Wyœwietlenie najlepiej sprzedaj¹cych siê kategorii w ka¿dym sklepie.

Co robi to zapytanie:
1. £¹czy informacje o zamówieniach, szczegó³ach zamówieñ, produktach, kategoriach i sklepach.
2. Sumuje liczbê sprzedanych sztuk dla ka¿dej kategorii w ka¿dym sklepie.
3. U¿ywa funkcji RANK(), aby uszeregowaæ kategorie w ka¿dym sklepie wed³ug liczby sprzedanych sztuk.
4. Filtruje wyniki, aby wyœwietliæ tylko najlepiej sprzedaj¹ce siê kategorie (RANK = 1) w ka¿dym sklepie.
5. Sortuje wyniki po ID sklepu dla czytelnoœci.
*/

WITH CategorySales AS (
    SELECT 
        s.store_id, 
        s.store_name,                         -- Nazwa sklepu
        c.category_id, 
        c.category_name,                      -- Nazwa kategorii
        SUM(oi.quantity) AS total_sold,       -- £¹czna liczba sprzedanych sztuk
        RANK() OVER (PARTITION BY s.store_id 
                     ORDER BY SUM(oi.quantity) ASC) AS rank
					--ORDER BY SUM(oi.quantity) DESC) AS rank
					-- RANK() klasyfikuje kategorie w ka¿dym sklepie po liczbie sprzedanych sztuk
    FROM sales.stores AS s
    JOIN sales.orders AS o ON s.store_id = o.store_id         -- Po³¹czenie z zamówieniami
    JOIN sales.order_items AS oi ON o.order_id = oi.order_id  -- Po³¹czenie z pozycjami zamówieñ
    JOIN production.products AS p ON oi.product_id = p.product_id -- Po³¹czenie z produktami
    JOIN production.categories AS c ON p.category_id = c.category_id -- Po³¹czenie z kategoriami
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