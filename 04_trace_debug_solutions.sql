------------------------------------------------------------
-- SECTION 4 | TRACE, DEBUG AND SHORT ANSWER - SOLUTIONS

-- Q1. Original block (fails at runtime with ORA-01001):
--
   SET SERVEROUTPUT ON;
-- DECLARE
--     CURSOR c_book (p_cat VARCHAR2) IS
--         SELECT book_id, title FROM book WHERE category = p_cat;
-- BEGIN
--     FOR r IN c_book('Database') LOOP
--         DBMS_OUTPUT.PUT_LINE(r.book_id || ' - ' || r.title);
--     END LOOP;
--
--     IF c_book%ROWCOUNT = 0 THEN
--         DBMS_OUTPUT.PUT_LINE('No books found');
--     END IF;
--     CLOSE c_book;
-- END;
-- /
--
-- CAUSE: A cursor FOR loop implicitly OPENs the cursor, FETCHes every row,
-- and implicitly CLOSEs the cursor the instant the loop body finishes.
-- By the time control reaches "IF c_book%ROWCOUNT = 0 THEN", c_book is
-- already closed, so referencing %ROWCOUNT on it raises
-- ORA-01001: cursor number is invalid or does not exist.
-- (The later CLOSE c_book; line would raise the same error for the same
-- reason, but the IF line fails first since it executes earlier.)
--
-- CORRECTED BLOCK:
------------------------------------------------------------
DECLARE
    CURSOR c_book (p_cat VARCHAR2) IS
        SELECT book_id, title FROM book WHERE category = p_cat;
    v_count NUMBER := 0;
BEGIN
    FOR r IN c_book('Database') LOOP
        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(r.book_id || ' - ' || r.title);
    END LOOP;

    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No books found');
    END IF;
    -- No explicit CLOSE needed - the cursor FOR loop already closed c_book.
END;
/


------------------------------------------------------------
-- Q2. Original block (compilation error):
--
-- DECLARE
--     CURSOR c_mem (p_course VARCHAR2(20)) IS
--         SELECT member_name FROM lib_member WHERE course = p_course;
-- BEGIN
--     FOR r IN c_mem('MCA') LOOP
--         DBMS_OUTPUT.PUT_LINE(r.member_name);
--     END LOOP;
-- END;
-- /
--
-- ERROR: PLS-00103 (illegal declaration) - a cursor parameter can only be
-- given a datatype, never a size/length/precision constraint. VARCHAR2(20)
-- is not allowed in a cursor parameter list (only plain VARCHAR2 is legal).
--
-- ONE-LINE FIX: change
--     CURSOR c_mem (p_course VARCHAR2(20)) IS
-- to
--     CURSOR c_mem (p_course VARCHAR2) IS
------------------------------------------------------------
DECLARE
    CURSOR c_mem (p_course VARCHAR2) IS
        SELECT member_name FROM lib_member WHERE course = p_course;
BEGIN
    FOR r IN c_mem('MCA') LOOP
        DBMS_OUTPUT.PUT_LINE(r.member_name);
    END LOOP;
END;
/


------------------------------------------------------------
-- Q3. IMPORTANT: the photo cuts off partway through this block's
-- DECLARE section (only "...OM book WHERE price > 600;" and the loop body
-- were visible). Based on the visible fragments (a cursor c over book
-- filtered by price > 600, a v_title variable, and
-- DBMS_OUTPUT.PUT_LINE(c%ROWCOUNT || ' : ' || v_title) inside the loop,
-- followed by a 'Final ROWCOUNT' line after the loop and CLOSE c), the
-- most likely original block is reconstructed below. Please verify this
-- against your printed copy before submitting.
--
-- DECLARE
--     CURSOR c IS SELECT title FROM book WHERE price > 600;
--     v_title book.title%TYPE;
-- BEGIN
--     OPEN c;
--     LOOP
--         FETCH c INTO v_title;
--         EXIT WHEN c%NOTFOUND;
--         DBMS_OUTPUT.PUT_LINE(c%ROWCOUNT || ' : ' || v_title);
--     END LOOP;
--     DBMS_OUTPUT.PUT_LINE('Final ROWCOUNT = ' || c%ROWCOUNT);
--     CLOSE c;
-- END;
-- /
--
-- PREDICTED OUTPUT / EXPLANATION:
-- Each successful FETCH increments %ROWCOUNT by 1, so the loop prints
-- "1 : <title>", "2 : <title>", and so on for every book priced above 600
-- (books 101, 103, 104, 106, 108, 111, 112 in the sample data - 7 rows).
-- The final FETCH that triggers EXIT WHEN c%NOTFOUND does NOT return a
-- row, so it does NOT increment %ROWCOUNT. That means the 'Final
-- ROWCOUNT' line prints the SAME number as the last line inside the loop
-- (7), not a higher one - the count only ever increases on a successful
-- fetch, never on the failed fetch that ends the loop.
-- If your printed question instead compares the very FIRST number shown
-- in the loop (1, after the first row) against the FINAL ROWCOUNT (7),
-- then yes they differ - simply because %ROWCOUNT is a running total that
-- grows by one with every row fetched, so the number naturally increases
-- as the loop progresses from the first row to the last.
------------------------------------------------------------
DECLARE
    CURSOR c IS SELECT title FROM book WHERE price > 600;
    v_title book.title%TYPE;
BEGIN
    OPEN c;
    LOOP
        FETCH c INTO v_title;
        EXIT WHEN c%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(c%ROWCOUNT || ' : ' || v_title);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Final ROWCOUNT = ' || c%ROWCOUNT);
    CLOSE c;
END;
/


------------------------------------------------------------
-- Q4. THEORY: Opening a parameterised cursor without the argument
--
-- QUESTION:
-- A student opens a parameterised cursor as OPEN c_book; without
-- supplying the argument. What error appears, and at which stage -
-- compilation or execution? How does a DEFAULT value in the parameter
-- change this behaviour?
--
-- ANSWER:
-- Stage: COMPILATION (PLS-00306)
--
-- A parameterised cursor REQUIRES an argument for each parameter when
-- OPEN is called. If you declare CURSOR c_book (p_cat VARCHAR2) and
-- then write OPEN c_book; without an argument, the compiler reports
-- PLS-00306: wrong number or types of arguments in call to 'C_BOOK'.
-- The compilation fails before any runtime occurs.
--
-- DEFAULT VALUE CHANGE:
-- If the cursor is declared with a DEFAULT, e.g.
--     CURSOR c_book (p_cat VARCHAR2 DEFAULT 'Database') IS ...
-- then OPEN c_book; becomes legal. The DEFAULT value is used
-- automatically. The block now compiles and runs successfully.
--
-- EXAMPLE - Without DEFAULT (compilation error):
-- DECLARE
--     CURSOR c_book (p_cat VARCHAR2) IS
--         SELECT title FROM book WHERE category = p_cat;
-- BEGIN
--     OPEN c_book;         -- PLS-00306: missing required argument
-- END;
-- /
--
-- EXAMPLE - With DEFAULT (compiles and runs):
-- DECLARE
--     CURSOR c_book (p_cat VARCHAR2 DEFAULT 'Database') IS
--         SELECT title FROM book WHERE category = p_cat;
-- BEGIN
--     OPEN c_book;         -- Legal - uses 'Database' as p_cat
--     FOR r IN c_book LOOP
--         DBMS_OUTPUT.PUT_LINE(r.title);
--     END LOOP;
-- END;
-- /
------------------------------------------------------------


------------------------------------------------------------
-- Q5. THEORY: Comparison table - Implicit vs Explicit vs Parameterised
--
-- ┌─────────────────────────────────────────────────────────────────┐
-- │ IMPLICIT CURSOR (auto-created for any SQL statement)            │
-- ├─────────────────────────────────────────────────────────────────┤
-- │ Who declares it?                                                │
-- │   Oracle implicitly (you do not declare it yourself)            │
-- │                                                                 │
-- │ Who opens and closes it?                                        │
-- │   Oracle opens it, executes the SQL, then closes it             │
-- │   (automatic, you have no control)                              │
-- │                                                                 │
-- │ Can it be reused with different values?                         │
-- │   No. Each new SQL statement creates a new implicit cursor.    │
-- │                                                                 │
-- │ Best situation / example:                                       │
-- │   Single DML operations like INSERT, UPDATE, DELETE, or single  │
-- │   SELECT that fetches one row (no loop). Check SQL%ROWCOUNT to  │
-- │   verify how many rows were affected.                           │
-- │                                                                 │
-- │   BEGIN                                                          │
-- │       UPDATE book SET price = price + 10 WHERE book_id = 101;   │
-- │       DBMS_OUTPUT.PUT_LINE('Rows updated: ' || SQL%ROWCOUNT);   │
-- │   END;                                                           │
-- └─────────────────────────────────────────────────────────────────┘
--
-- ┌─────────────────────────────────────────────────────────────────┐
-- │ EXPLICIT SIMPLE CURSOR (declared by you, fixed query)           │
-- ├─────────────────────────────────────────────────────────────────┤
-- │ Who declares it?                                                │
-- │   You (the programmer) in the DECLARE section                   │
-- │                                                                 │
-- │ Who opens and closes it?                                        │
-- │   You open it with OPEN, fetch rows in a loop, close it with   │
-- │   CLOSE. (You have full control.)                               │
-- │   OR: cursor FOR loop opens/closes automatically.               │
-- │                                                                 │
-- │ Can it be reused with different values?                         │
-- │   No. The query is fixed (no parameters).                       │
-- │   You would need to declare a new cursor for a different query. │
-- │                                                                 │
-- │ Best situation / example:                                       │
-- │   Fetching multiple rows from a fixed query in a loop. Need     │
-- │   fine-grained control over fetch/close timing, or need to use  │
-- │   %ISOPEN, %ROWCOUNT etc. for advanced logic.                   │
-- │                                                                 │
-- │   DECLARE                                                        │
-- │       CURSOR c_book IS SELECT title, price FROM book;           │
-- │   BEGIN                                                          │
-- │       FOR r IN c_book LOOP                                       │
-- │           DBMS_OUTPUT.PUT_LINE(r.title || ' - ' || r.price);    │
-- │       END LOOP;                                                  │
-- │   END;                                                           │
-- └─────────────────────────────────────────────────────────────────┘
--
-- ┌─────────────────────────────────────────────────────────────────┐
-- │ PARAMETERISED CURSOR (declared by you, reusable with arguments)  │
-- ├─────────────────────────────────────────────────────────────────┤
-- │ Who declares it?                                                │
-- │   You (the programmer) in the DECLARE section                   │
-- │                                                                 │
-- │ Who opens and closes it?                                        │
-- │   You open it with OPEN, supplying argument values. You fetch   │
-- │   and close with the same control as simple cursors.            │
-- │   (Full control, you supply fresh arguments each time.)         │
-- │                                                                 │
-- │ Can it be reused with different values?                         │
-- │   YES. This is the key advantage. Declare once, OPEN multiple   │
-- │   times with different argument values.                         │
-- │                                                                 │
-- │ Best situation / example:                                       │
-- │   Repeatedly fetching rows from the same logical query but with │
-- │   different filter values (e.g., fetch books by different       │
-- │   categories, or members by different courses). Saves code.     │
-- │                                                                 │
-- │   DECLARE                                                        │
-- │       CURSOR c_by_cat (p_cat VARCHAR2) IS                        │
-- │           SELECT title FROM book WHERE category = p_cat;        │
-- │   BEGIN                                                          │
-- │       -- Use once for 'Database'                                 │
-- │       FOR r IN c_by_cat('Database') LOOP                         │
-- │           DBMS_OUTPUT.PUT_LINE(r.title);                         │
-- │       END LOOP;                                                  │
-- │       -- Reuse for 'Programming' without declaring again         │
-- │       FOR r IN c_by_cat('Programming') LOOP                      │
-- │           DBMS_OUTPUT.PUT_LINE(r.title);                         │
-- │       END LOOP;                                                  │
-- │   END;                                                           │
-- └─────────────────────────────────────────────────────────────────┘
------------------------------------------------------------


------------------------------------------------------------
-- Q6. THEORY: Cursor attributes on unopened cursors
--
-- QUESTION:
-- Explain with one example each why %FOUND, %NOTFOUND, %ROWCOUNT and
-- %ISOPEN all raise ORA-01001 when used on a cursor that has not been
-- opened - except one of them. Which one, and what does it return
-- instead?
--
-- ANSWER:
-- %FOUND, %NOTFOUND, %ROWCOUNT all raise ORA-01001 on an unopened
-- cursor because they depend on fetch history (whether a row was
-- fetched, whether no row was found, how many rows have been fetched).
-- An unopened cursor has no fetch history, so these attributes cannot
-- give a meaningful value and raise an error.
--
-- %ISOPEN is the EXCEPTION. It does NOT raise ORA-01001.
-- Instead, it simply returns FALSE (boolean), because %ISOPEN is a
-- state check, not a history check. A cursor is either open or not;
-- if it has never been opened, it is in the closed state, so %ISOPEN
-- returns FALSE.
--
-- EXAMPLES:
------------------------------------------------------------

-- Example 1: %ROWCOUNT on unopened cursor (raises ORA-01001)
DECLARE
    CURSOR c IS SELECT title FROM book;
    v_count NUMBER;
BEGIN
    v_count := c%ROWCOUNT;  -- Error: ORA-01001
END;
/

-- Example 2: %FOUND on unopened cursor (raises ORA-01001)
DECLARE
    CURSOR c IS SELECT title FROM book;
BEGIN
    IF c%FOUND THEN  -- Error: ORA-01001
        DBMS_OUTPUT.PUT_LINE('A row was fetched');
    END IF;
END;
/

-- Example 3: %NOTFOUND on unopened cursor (raises ORA-01001)
DECLARE
    CURSOR c IS SELECT title FROM book;
BEGIN
    IF c%NOTFOUND THEN  -- Error: ORA-01001
        DBMS_OUTPUT.PUT_LINE('No row to fetch');
    END IF;
END;
/

-- Example 4: %ISOPEN on unopened cursor (returns FALSE - no error)
DECLARE
    CURSOR c IS SELECT title FROM book;
BEGIN
    IF c%ISOPEN THEN
        DBMS_OUTPUT.PUT_LINE('Cursor is open');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Cursor is closed');  -- This prints
    END IF;
END;
/

