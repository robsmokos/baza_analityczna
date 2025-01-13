use BikeStores;
SELECT *  FROM sales.customers;
SELECT *  FROM sales.orders;
SELECT *  FROM sales.order_items;
SELECT *  FROM sales.staffs;
SELECT *  FROM sales.stores;
SELECT *  FROM production.categories;
SELECT *  FROM production.products;
SELECT *  FROM production.brands;



-- Aby wy�wietli� wszystkie tabele w bazie danych w Microsoft SQL Server

SELECT TABLE_SCHEMA AS SchemaName,
       TABLE_NAME AS TableName,
       TABLE_TYPE AS TableType
FROM INFORMATION_SCHEMA.TABLES
ORDER BY SchemaName, TableName;



-- TEST POR�WNAWCZY WYNIK�W Z BAZY RELACYJNEJ I ANALITYCZNEJ
-- TEST POR�WNAWCZY WYNIK�W Z BAZY RELACYJNEJ I ANALITYCZNEJ


/* 1.
Zapytanie SQL: Wy�wietlenie wszystkich klient�w i liczby rower�w zakupionych w podziale na kategorie.

Cel:
- Dla ka�dego klienta wy�wietlamy jego imi� i nazwisko oraz sumaryczn� liczb� zakupionych rower�w.
- Dane s� grupowane wed�ug klient�w i kategorii produkt�w.
- Uwzgl�dniono r�wnie� klient�w, kt�rzy nie dokonali zakupu.

Szczeg�y dzia�ania:
1. ��czymy tabele: customers, orders, order_items, products i categories.
3. Zast�powanie warto�ci NULL:
   - Je�li kategoria nie istnieje, wy�wietlamy 'No Category'.
   - Je�li ilo�� zakupionych rower�w jest NULL, zast�pujemy j� zerem (0).
4. Grupowanie wynik�w:
   - Grupujemy dane po kliencie i kategorii produkt�w.
5. Sortowanie wynik�w:
   - Klienci s� sortowani wed�ug ID, a liczba zakupionych rower�w malej�co.
*/
SELECT 
    c.customer_id,  -- ID klienta
    c.first_name + ' ' + c.last_name AS customer_name,  -- Po��czone imi� i nazwisko klienta
    COALESCE(cat.category_name, 'No Category') AS category_name, -- Nazwa kategorii lub 'No Category' dla warto�ci NULL
    SUM(ISNULL(oi.quantity, 0)) AS total_bikes_purchased -- Suma ilo�ci kupionych rower�w (NULL zast�pione 0)
FROM sales.customers AS c
LEFT JOIN sales.orders AS o ON c.customer_id = o.customer_id 
LEFT JOIN sales.order_items AS oi ON o.order_id = oi.order_id
LEFT JOIN production.products AS p ON oi.product_id = p.product_id
LEFT JOIN production.categories AS cat ON p.category_id = cat.category_id
GROUP BY c.customer_id, c.first_name, c.last_name, cat.category_name -- Grupowanie po kliencie i kategorii
ORDER BY c.customer_id, total_bikes_purchased DESC; -- Sortowanie po ID klienta i liczbie zakupionych rower�w malej�co



/* 2.
Zapytanie SQL: Wy�wietlenie pracownik�w sklepu oraz liczby produkt�w sprzedanych w podziale na marki.

Co robi to zapytanie:
1. Pobiera dane o pracownikach, kt�rzy realizowali sprzeda� (zam�wienia).
2. ��czy dane z informacjami o produktach i ich markach, aby okre�li�, ile produkt�w ka�dej marki sprzeda� ka�dy pracownik.
3. Uwzgl�dnia wszystkich pracownik�w, nawet je�li nie sprzedali �adnych produkt�w.
4. Suma sprzedanych produkt�w jest obliczana na podstawie ilo�ci z tabeli `order_items`.
5. Obs�ugiwane s� przypadki, gdzie marka produktu jest nieznana (`NULL`), zamieniaj�c je na "No Brand".
6. Wyniki s� grupowane wed�ug pracownik�w i marek produkt�w.
7. Na ko�cu wyniki s� posortowane:
   - Po ID pracownika rosn�co,
   - Po liczbie sprzedanych produkt�w malej�co.
*/
use BikeStores;
SELECT 
    s.staff_id,  -- ID pracownika
    s.first_name + ' ' + s.last_name AS employee_name,  -- Po��czone imi� i nazwisko pracownika
    COALESCE(b.brand_name, 'No Brand') AS brand_name,   -- Nazwa marki lub 'No Brand', je�li NULL
    SUM(ISNULL(oi.quantity, 0)) AS total_products_sold  -- Suma ilo�ci sprzedanych produkt�w
FROM sales.staffs AS s
LEFT JOIN sales.orders AS o ON s.staff_id = o.staff_id  -- Po��czenie z zam�wieniami
LEFT JOIN sales.order_items AS oi ON o.order_id = oi.order_id  -- Po��czenie z pozycjami zam�wie�
LEFT JOIN production.products AS p ON oi.product_id = p.product_id  -- Po��czenie z produktami
LEFT JOIN production.brands AS b ON p.brand_id = b.brand_id  -- Po��czenie z markami produkt�w
GROUP BY s.staff_id, s.first_name, s.last_name, b.brand_name  -- Grupowanie po pracowniku i marce
ORDER BY s.staff_id, total_products_sold DESC;  -- Sortowanie po pracowniku i liczbie sprzedanych produkt�w malej�co





/* 3.
Zapytanie SQL: Wyliczenie sumy rocznej sprzeda�y dla pracownik�w z uwzgl�dnieniem rabatu na produkty.

Co robi to zapytanie:
1. Pobiera dane o pracownikach, ilo�ci sprzedanych produkt�w oraz warto�� sprzeda�y uwzgl�dniaj�c rabat.
2. Wylicza warto�� sprzeda�y dla ka�dego zam�wienia wed�ug wzoru:
   - Warto�� sprzeda�y = ilo�� * cena jednostkowa * (1 - rabat).
3. Sumuje sprzeda� i ilo�� sprzedanych produkt�w dla ka�dego pracownika i roku.
4. Grupuje dane po pracowniku i roku sprzeda�y.
5. Sortuje wyniki wed�ug ��cznej warto�ci sprzeda�y malej�co.
*/


SELECT 
    s.staff_id, 
    s.first_name + ' ' + s.last_name AS employee_name,  -- Po��czone imi� i nazwisko pracownika
    YEAR(o.order_date) AS sales_year,                  -- Rok sprzeda�y
    SUM(oi.quantity) AS total_products_sold,           -- ��czna liczba sprzedanych produkt�w
    SUM(oi.quantity * oi.list_price * (1 - ISNULL(oi.discount, 0))) AS total_sales_value -- Suma warto�ci sprzeda�y z rabatem
FROM sales.staffs AS s
JOIN sales.orders AS o ON s.staff_id = o.staff_id       -- Po��czenie z zam�wieniami
JOIN sales.order_items AS oi ON o.order_id = oi.order_id -- Po��czenie z pozycjami zam�wie�
WHERE o.order_date IS NOT NULL -- Pomini�cie brakuj�cych dat zam�wie�
GROUP BY s.staff_id, s.first_name, s.last_name, YEAR(o.order_date) -- Grupowanie po pracowniku i roku
ORDER BY total_sales_value DESC; -- Sortowanie po warto�ci sprzeda�y malej�co





/* 4.
Zapytanie SQL: Wy�wietlenie wszystkich sklep�w oraz najlepiej sprzedaj�cego si� produktu w ka�dym z nich.

Co robi to zapytanie:
1. Dla ka�dego sklepu oblicza sumaryczn� liczb� sprzedanych sztuk dla ka�dego produktu.
2. U�ywa funkcji okna `RANK()` do uszeregowania produkt�w w ka�dym sklepie wed�ug liczby sprzedanych sztuk (malej�co).
3. Wy�wietla tylko te produkty, kt�re maj� najwy�sz� liczb� sprzedanych sztuk w danym sklepie (RANK = 1).
4. Zwraca nazw� sklepu, nazw� produktu oraz liczb� sprzedanych sztuk.
*/
WITH ProductSales AS (
    SELECT 
        s.store_id, 
        s.store_name,                       -- Nazwa sklepu
        p.product_id, 
        p.product_name,                     -- Nazwa produktu
        SUM(oi.quantity) AS total_sold,     -- ��czna liczba sprzedanych sztuk
        RANK() OVER (PARTITION BY s.store_id ORDER BY SUM(oi.quantity) DESC) AS rank
        -- Funkcja RANK() klasyfikuje produkty w ka�dym sklepie po liczbie sprzedanych sztuk
    FROM sales.stores AS s
    JOIN sales.orders AS o ON s.store_id = o.store_id         -- Po��czenie zam�wie� ze sklepami
    JOIN sales.order_items AS oi ON o.order_id = oi.order_id  -- Po��czenie szczeg��w zam�wie�
    JOIN production.products AS p ON oi.product_id = p.product_id -- Po��czenie z produktami
    GROUP BY s.store_id, s.store_name, p.product_id, p.product_name
)
SELECT 
    store_id,
    store_name,
    product_name,
    total_sold
FROM ProductSales
WHERE rank = 1 -- Wy�wietlamy tylko produkty z rankiem 1 (najlepiej sprzedaj�cy si� produkt)
ORDER BY store_id;







/* 5.
Zapytanie SQL: Wy�wietlenie 10 produkt�w, kt�rych sprzeda� przynios�a najwy�szy doch�d.

Co robi to zapytanie:
1. Oblicza doch�d dla ka�dego produktu na podstawie wzoru:
   - Doch�d = ilo�� * cena jednostkowa * (1 - rabat).
2. Grupuje wyniki po ID i nazwie produktu.
3. Sumuje doch�d dla ka�dego produktu.
4. Sortuje produkty wed�ug ��cznego dochodu malej�co.
5. Ogranicza wyniki do 10 najlepszych produkt�w.
*/


SELECT TOP 10
    p.product_id,                                  -- ID produktu
    p.product_name,                                -- Nazwa produktu
    SUM(oi.quantity * oi.list_price * (1 - ISNULL(oi.discount, 0))) AS total_revenue
    -- Obliczenie dochodu: ilo�� * cena jednostkowa * (1 - rabat); rabat traktujemy jako 0 je�li NULL
FROM sales.order_items AS oi
JOIN production.products AS p ON oi.product_id = p.product_id -- Po��czenie z tabel� produkt�w
GROUP BY p.product_id, p.product_name       -- Grupowanie wynik�w po ID i nazwie produktu
ORDER BY total_revenue DESC;                -- Sortowanie malej�co wed�ug dochodu







/* 6. 
najcz�sciej sprzedawany produkt
*/
SELECT TOP 10
    p.product_id,                    -- ID produktu
    p.product_name,                  -- Nazwa produktu
    SUM(oi.quantity) AS total_sold   -- ��czna liczba sprzedanych sztuk
FROM sales.order_items AS oi
JOIN production.products AS p ON oi.product_id = p.product_id -- Po��czenie z tabel� produkt�w
GROUP BY p.product_id, p.product_name -- Grupowanie po ID i nazwie produktu
ORDER BY total_sold DESC;            -- Sortowanie malej�co po liczbie sprzedanych sztuk




/* 7.
Zapytanie SQL: Wy�wietlenie najlepiej sprzedaj�cych si� kategorii w ka�dym sklepie.

Co robi to zapytanie:
1. ��czy informacje o zam�wieniach, szczeg�ach zam�wie�, produktach, kategoriach i sklepach.
2. Sumuje liczb� sprzedanych sztuk dla ka�dej kategorii w ka�dym sklepie.
3. U�ywa funkcji RANK(), aby uszeregowa� kategorie w ka�dym sklepie wed�ug liczby sprzedanych sztuk.
4. Filtruje wyniki, aby wy�wietli� tylko najlepiej sprzedaj�ce si� kategorie (RANK = 1) w ka�dym sklepie.
5. Sortuje wyniki po ID sklepu dla czytelno�ci.
*/

WITH CategorySales AS (
    SELECT 
        s.store_id, 
        s.store_name,                         -- Nazwa sklepu
        c.category_id, 
        c.category_name,                      -- Nazwa kategorii
        SUM(oi.quantity) AS total_sold,       -- ��czna liczba sprzedanych sztuk
        RANK() OVER (PARTITION BY s.store_id 
                     ORDER BY SUM(oi.quantity) ASC) AS rank
					--ORDER BY SUM(oi.quantity) DESC) AS rank
					-- RANK() klasyfikuje kategorie w ka�dym sklepie po liczbie sprzedanych sztuk
    FROM sales.stores AS s
    JOIN sales.orders AS o ON s.store_id = o.store_id         -- Po��czenie z zam�wieniami
    JOIN sales.order_items AS oi ON o.order_id = oi.order_id  -- Po��czenie z pozycjami zam�wie�
    JOIN production.products AS p ON oi.product_id = p.product_id -- Po��czenie z produktami
    JOIN production.categories AS c ON p.category_id = c.category_id -- Po��czenie z kategoriami
    GROUP BY s.store_id, s.store_name, c.category_id, c.category_name
)
SELECT 
    store_id, 
    store_name, 
    category_name, 
    total_sold
FROM CategorySales
WHERE rank = 1 -- Wy�wietlenie tylko najlepiej sprzedaj�cych si� kategorii w ka�dym sklepie
ORDER BY store_id;