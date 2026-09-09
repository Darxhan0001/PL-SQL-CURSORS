------------------------------------------------------------
-- SECTION 2 | SIMPLE (EXPLICIT) CURSORS - SOLUTIONS --

-- Q1. Explicit cursor on BOOK, OPEN/FETCH/CLOSE with simple LOOP + %NOTFOUND --

SET SERVEROUTPUT ON;
DECLARE
    CURSOR c_book IS
        SELECT book_id, title, price FROM book;
    v_book_id book.book_id%TYPE;
    v_title   book.title%TYPE;
    v_price   book.price%TYPE;
BEGIN
    OPEN c_book;
    LOOP
        FETCH c_book INTO v_book_id, v_title, v_price;
        EXIT WHEN c_book%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_book_id || ' - ' || v_title || ' - Rs.' || v_price);
    END LOOP;
    CLOSE c_book;
END;
/
    
-- Q2. Same program rewritten as a cursor FOR loop --

DECLARE
    CURSOR c_book IS
        SELECT book_id, title, price FROM book;
BEGIN

    FOR r IN c_book LOOP
        DBMS_OUTPUT.PUT_LINE(r.book_id || ' - ' || r.title || ' - Rs.' || r.price);
    END LOOP;
END;
/

-- Q3. Publisher name/city/country using cursor_name%ROWTYPE --

DECLARE
    CURSOR c_pub IS
        SELECT pub_name, city, country FROM publisher;
    r_pub c_pub%ROWTYPE;
BEGIN
    OPEN c_pub;
    LOOP
        FETCH c_pub INTO r_pub;
        EXIT WHEN c_pub%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(r_pub.pub_name || ' - ' || r_pub.city || ' - ' || r_pub.country);
    END LOOP;
    CLOSE c_pub;
END;
/

-- Q4. Books priced > 500, serial number via %ROWCOUNT --

DECLARE
    CURSOR c_book IS
        SELECT title, price FROM book WHERE price > 500;
BEGIN
    FOR r IN c_book LOOP
        DBMS_OUTPUT.PUT_LINE(c_book%ROWCOUNT || '. ' || r.title || ' - Rs.' || r.price);
    END LOOP;
END;
/

-- Q5. Member names formatted "1. RIYA SHAH (MSc IT - Sem 1)" --

DECLARE
    CURSOR c_mem IS
        SELECT member_name, course, semester FROM lib_member;
    v_sno NUMBER := 0;
BEGIN
    FOR r IN c_mem LOOP
        v_sno := v_sno + 1;
        DBMS_OUTPUT.PUT_LINE(v_sno || '. ' || UPPER(r.member_name) ||
            ' (' || r.course || ' - Sem ' || r.semester || ')');
    END LOOP;
END;
/

    -- Q6. Total stock value (price * stock), row values + grand total --

DECLARE
    CURSOR c_book IS
        SELECT title, price, stock FROM book;
    v_value NUMBER;
    v_total NUMBER := 0;
BEGIN
    FOR r IN c_book LOOP
        v_value := r.price * r.stock;
        v_total := v_total + v_value;
        DBMS_OUTPUT.PUT_LINE(r.title || ' - Value: Rs.' || v_value);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Grand Total Stock Value = Rs.' || v_total);
END;
/
    
-- Q7. %ISOPEN check before opening; verify FALSE after closing --

DECLARE
    CURSOR c_book IS SELECT book_id FROM book;
BEGIN
    IF c_book%ISOPEN THEN
        DBMS_OUTPUT.PUT_LINE('Cursor already open');
    ELSE
        OPEN c_book;
        DBMS_OUTPUT.PUT_LINE('Cursor opened successfully');
    END IF;

    CLOSE c_book;

    IF c_book%ISOPEN THEN
        DBMS_OUTPUT.PUT_LINE('%ISOPEN = TRUE');
    ELSE
        DBMS_OUTPUT.PUT_LINE('%ISOPEN = FALSE (cursor closed)');
    END IF;
END;
/

    
-- Q8. Books not returned (return_date IS NULL) --

DECLARE
    CURSOR c_issue IS
        SELECT issue_id, book_id, issue_date
        FROM book_issue
        WHERE return_date IS NULL;
    v_found BOOLEAN := FALSE;
BEGIN
    FOR r IN c_issue LOOP
        v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE('Issue ' || r.issue_id || ' - Book ' || r.book_id ||
            ' - Issued on ' || TO_CHAR(r.issue_date, 'DD-MON-YYYY'));
    END LOOP;

    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE('All books returned');
    END IF;
END;
/


-- Q9. Join of BOOK and PUBLISHER --

DECLARE
    CURSOR c_join IS
        SELECT b.title, p.pub_name, p.country
        FROM book b
        JOIN publisher p ON b.pub_id = p.pub_id;
BEGIN
    FOR r IN c_join LOOP
        DBMS_OUTPUT.PUT_LINE(r.title || ' - ' || r.pub_name || ' (' || r.country || ')');
    END LOOP;
END;
/


-- Q10. Books with stock < 5, tagged REORDER, count afterwards --

DECLARE
    CURSOR c_low IS
        SELECT book_id, title, stock FROM book WHERE stock < 5;
    v_count NUMBER := 0;
BEGIN
    FOR r IN c_low LOOP
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(r.book_id || ' - ' || r.title || ' - Stock: ' || r.stock || ' - REORDER');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Total books to reorder: ' || v_count);
END;
/

    
-- Q11. Top 5 priciest books, EXIT WHEN cursor%ROWCOUNT = 5 --

DECLARE
    CURSOR c_book IS
        SELECT title, price FROM book ORDER BY price DESC;
    v_title book.title%TYPE;
    v_price book.price%TYPE;
BEGIN
    OPEN c_book;
    LOOP
        FETCH c_book INTO v_title, v_price;
        EXIT WHEN c_book%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(c_book%ROWCOUNT || '. ' || v_title || ' - Rs.' || v_price);
        EXIT WHEN c_book%ROWCOUNT = 5;
    END LOOP;
    CLOSE c_book;
END;
/
    
-- Q12. SELECT ... FOR UPDATE / WHERE CURRENT OF: +10 stock for 'Database' --

DECLARE
    CURSOR c_book IS
        SELECT book_id, title, stock
        FROM book
        WHERE category = 'Database'
        FOR UPDATE OF stock;
    v_old_stock book.stock%TYPE;
BEGIN
    FOR r IN c_book LOOP
        v_old_stock := r.stock;
        UPDATE book
           SET stock = stock + 10
         WHERE CURRENT OF c_book;
        DBMS_OUTPUT.PUT_LINE(r.title || ' - Old Stock: ' || v_old_stock ||
            ' - New Stock: ' || (v_old_stock + 10));
    END LOOP;
    COMMIT;
END;
/
