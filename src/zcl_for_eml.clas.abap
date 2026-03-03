CLASS zcl_for_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_FOR_EML IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA: lt_date TYPE STANDARD TABLE OF zuserdep_db.


    lt_date = VALUE #( ( client = sy-mandt emp_id = '00000123' dep_id = '321' serial_no = '1' salary = '120.88' joiningdate = '20250101' )
                       ( client = sy-mandt emp_id = '00000123' dep_id = '321' serial_no = '2' salary = '560.20' joiningdate = '20220924' )
                       ( client = sy-mandt emp_id = '00000123' dep_id = '321' serial_no = '3' salary = '780.90' joiningdate = '20140218' ) ).



    MODIFY zuserdep_db FROM TABLE @lt_date.
*    COMMIT WORK.

    IF lt_date IS NOT INITIAL.
      out->write( 'DATA LOADED SUCCESSFULLY !!!!' ).
     ELSE.
      out->write( 'INSERT IS FAILED !!!!' ).

    ENDIF.
  ENDMETHOD.
ENDCLASS.
