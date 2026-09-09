------------------------------------------------------------
-- SECTION 3 | PARAMETERISED CURSORS - SOLUTIONS


-- Q1. Parameterised cursor by category, tested with Database / Programming

SET SERVEROUTPUT ON;
ACCEPT p_category PROMPT 'Enter category: ';
DECLARE
    CURSOR c_book (p_cat VARCHAR2) IS
        SELECT book_id, title, price FROM book WHERE category = p_cat;
BEGIN
    FOR r IN c_book('&p_category') LOOP
        DBMS_OUTPUT.PUT_LINE(r.book_id || ' - ' || r.title || ' - Rs.' || r.price);
    END LOOP;
END;
/


-- Q2. Parameterised cursor by publisher name (case-insensitive via UPPER()) --

DECLARE
    CURSOR c_book (p_pub VARCHAR2) IS
        SELECT b.title, b.price
        FROM book b
        JOIN publisher p ON b.pub_id = p.pub_id
        WHERE UPPER(p.pub_name) = UPPER(p_pub);
BEGIN
    FOR r IN c_book('oxford press') LOOP
        DBMS_OUTPUT.PUT_LINE(r.title || ' - Rs.' || r.price);
    END LOOP;
END;
/


-- Q3. Two-parameter cursor: min/max price, tested with 300 and 700 --

DECLARE
    CURSOR c_book (p_min NUMBER, p_max NUMBER) IS
        SELECT title, price FROM book WHERE price BETWEEN p_min AND p_max;
BEGIN
    FOR r IN c_book(300, 700) LOOP
        DBMS_OUTPUT.PUT_LINE(r.title || ' - Rs.' || r.price);
    END LOOP;
END;
/

    
-- Q4. Cursor by course and semester, join date formatted DD-MON-YYYY --

DECLARE
    CURSOR c_mem (p_course VARCHAR2, p_sem NUMBER) IS
        SELECT member_name, join_date
        FROM lib_member
        WHERE course = p_course AND semester = p_sem;
BEGIN
    FOR r IN c_mem('MSc IT', 1) LOOP
        DBMS_OUTPUT.PUT_LINE(r.member_name || ' - Joined: ' ||
            TO_CHAR(r.join_date, 'DD-MON-YYYY'));
    END LOOP;
END;
/


-- Q5. Parameterised cursor with a DEFAULT value --

DECLARE
    CURSOR c_book (p_cat VARCHAR2 DEFAULT 'Database') IS
        SELECT title FROM book WHERE category = p_cat;
BEGIN
    DBMS_OUTPUT.PUT_LINE('-- Opened WITHOUT an argument (defaults to Database) --');
    FOR r IN c_book LOOP
        DBMS_OUTPUT.PUT_LINE(r.title);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('-- Opened WITH argument Networking --');
    FOR r IN c_book('Networking') LOOP
        DBMS_OUTPUT.PUT_LINE(r.title);
    END LOOP;
END;
/


-- Q6. Cursor by member id, three-table join (book_issue -> book, lib_member) --

DECLARE
    CURSOR c_hist (p_mem NUMBER) IS
        SELECT b.title, bi.issue_date
        FROM book_issue bi
        JOIN book b       ON bi.book_id   = b.book_id
        JOIN lib_member m ON bi.member_id = m.member_id
        WHERE m.member_id = p_mem;
BEGIN
    FOR r IN c_hist(1) LOOP
        DBMS_OUTPUT.PUT_LINE(r.title || ' - Issued on ' ||
            TO_CHAR(r.issue_date, 'DD-MON-YYYY'));
    END LOOP;
END;
/


-- Q7. Two cursors: simple cursor over PUBLISHER + parameterised inner cursor --

DECLARE
    CURSOR c_pub IS SELECT pub_id, pub_name FROM publisher;
    CURSOR c_book (p_pub NUMBER) IS
        SELECT title FROM book WHERE pub_id = p_pub;
BEGIN
    FOR rp IN c_pub LOOP
        DBMS_OUTPUT.PUT_LINE(rp.pub_name);
        FOR rb IN c_book(rp.pub_id) LOOP
            DBMS_OUTPUT.PUT_LINE('    - ' || rb.title);
        END LOOP;
    END LOOP;
END;
/


-- Q8. Cursor by country + BOOLEAN flag (see comment for why %ROWCOUNT
 --   cannot be used after a cursor FOR loop has ended) --

DECLARE
    CURSOR c_pub (p_country VARCHAR2) IS
        SELECT pub_name FROM publisher WHERE country = p_country;
    v_found BOOLEAN := FALSE;
BEGIN
  
    FOR r IN c_pub('India') LOOP
        v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE(r.pub_name);
    END LOOP;

    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE('No publisher found in India');
    END IF;
END;
/

    
-- Q9. Cursor by month number, books issued in that month of 2026 --

DECLARE
    CURSOR c_issue (p_month NUMBER) IS
        SELECT issue_id, book_id, issue_date
        FROM book_issue
        WHERE EXTRACT(MONTH FROM issue_date) = p_month
          AND EXTRACT(YEAR  FROM issue_date) = 2026;
BEGIN
    FOR r IN c_issue(6) LOOP
        DBMS_OUTPUT.PUT_LINE(r.issue_id || ' - Book ' || r.book_id ||
            ' - ' || TO_CHAR(r.issue_date, 'DD-MON-YYYY'));
    END LOOP;
END;
/

    
-- Q10. Cursor by number of overdue days, fine at Rs.2/day, running total --

DECLARE
    CURSOR c_overdue (p_days NUMBER) IS
        SELECT issue_id, book_id, issue_date
        FROM book_issue
        WHERE return_date IS NULL
          AND (SYSDATE - issue_date) > p_days;
    v_fine  NUMBER;
    v_total NUMBER := 0;
BEGIN
    FOR r IN c_overdue(30) LOOP
        v_fine  := TRUNC(SYSDATE - r.issue_date) * 2;
        v_total := v_total + v_fine;
        DBMS_OUTPUT.PUT_LINE('Issue ' || r.issue_id || ' - Book ' || r.book_id ||
            ' - Fine: Rs.' || v_fine);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Total fine payable = Rs.' || v_total);
END;
/


-- Q11. Parameterised FOR UPDATE cursor: +10% price by category --

DECLARE
    CURSOR c_book (p_cat VARCHAR2) IS
        SELECT book_id, title, price
        FROM book
        WHERE category = p_cat
        FOR UPDATE OF price;
    v_old_price book.price%TYPE;
    v_new_price book.price%TYPE;
BEGIN
    FOR r IN c_book('Database') LOOP
        v_old_price := r.price;
        v_new_price := r.price * 1.10;
        UPDATE book
           SET price = v_new_price
         WHERE CURRENT OF c_book;
        DBMS_OUTPUT.PUT_LINE(r.title || ' - Old: Rs.' || v_old_price ||
            ' - New: Rs.' || v_new_price);
    END LOOP;
    COMMIT;
END;
/


-- Q12. Parameterised cursor by starting letter, case-insensitive --

ACCEPT p_letter PROMPT 'Enter starting letter: ';
DECLARE
    CURSOR c_mem (p_letter VARCHAR2) IS
        SELECT member_name
        FROM lib_member
        WHERE UPPER(SUBSTR(member_name, 1, 1)) = UPPER(p_letter);
BEGIN
    FOR r IN c_mem('&p_letter') LOOP
        DBMS_OUTPUT.PUT_LINE(r.member_name);
    END LOOP;
END;
/
