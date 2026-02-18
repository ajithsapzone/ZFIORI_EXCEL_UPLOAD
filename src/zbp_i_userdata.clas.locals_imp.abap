CLASS lhc_user DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR user RESULT result.

*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      IMPORTING REQUEST requested_authorizations FOR user RESULT result.

    METHODS downloadexcel FOR MODIFY
      IMPORTING keys FOR ACTION user~downloadexcel RESULT result.
    METHODS uploadexceldata FOR MODIFY
      IMPORTING keys FOR ACTION user~uploadexceldata RESULT result.
    METHODS fillfilestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR user~fillfilestatus.
    METHODS fillselectedstatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR user~fillselectedstatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR user RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR user RESULT result.


ENDCLASS.

CLASS lhc_user IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

*  METHOD get_global_authorizations.
*  ENDMETHOD.


  METHOD DownloadExcel.


    DATA: lt_template TYPE STANDARD TABLE OF zbp_i_userdata=>gty_exl_file.

    DATA(lo_write_access) = xco_cp_xlsx=>document->empty(  )->write_access(  ).
    DATA(lo_worksheet) = lo_write_access->get_workbook(  )->worksheet->at_position( 1 ).

    DATA(lo_select_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
                            )->from_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'A' )
                            )->to_column( xco_cp_xlsx=>coordinate->for_alphabetic_value( 'G' )
                            )->from_row( xco_cp_xlsx=>coordinate->for_numeric_value( 1 )
                            )->get_pattern(  ).

    lt_template = VALUE #( (
                              emp_id   = 'Employee Id'
                              dep_id   = 'Department Id'
                              dep_desc = 'Department Description'
                              obj_type = 'Object Type'
                              obj_name = 'Object Name'
                              salary   = 'Salary'
                              joiningdate = 'Joining Date' ) ).

    lo_worksheet->select( lo_select_pattern
                         )->row_stream(
                         )->operation->write_from( REF #( lt_template )
                         )->execute(  ).

    DATA(lv_file_content) = lo_write_access->get_file_content(  ).

    MODIFY ENTITIES OF z_i_userdata
    IN LOCAL MODE
    ENTITY user
    UPDATE FROM VALUE #( FOR ls_key IN keys
                        ( empid = ls_key-EmpId
                          DepId = ls_key-DepId
                          Attachment = lv_file_content
                          Filename = 'template.xlsx'
                          Mimetype = 'application/vnd.ms-excel'
                          %control-Attachment = if_abap_behv=>mk-on
                          %control-Filename   = if_abap_behv=>mk-on
                          %control-Mimetype   = if_abap_behv=>mk-on ) )
      MAPPED DATA(ls_mapped_update)
      FAILED DATA(ls_reported_update)
      REPORTED DATA(ls_failed_update).


    READ ENTITIES OF z_i_userdata
    IN LOCAL MODE
    ENTITY user
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_user).


    LOOP AT lt_user INTO DATA(ls_user).

      MODIFY ENTITIES OF z_i_userdata
      IN LOCAL MODE
      ENTITY user
      UPDATE FIELDS ( FileStatus TemplateStatus )
      WITH VALUE #( (
                      %tky = ls_user-%tky
                      %data-FileStatus = 'File Not Selected'
                      %data-TemplateStatus = 'Present'
                      %control-FileStatus = if_abap_behv=>mk-on
                      %control-TemplateStatus = if_abap_behv=>mk-on ) )
       MAPPED DATA(ls_mapped_status)
       REPORTED DATA(ls_reported_status)
       FAILED DATA(ls_failed_stayus).

    ENDLOOP.

    result = VALUE #( FOR ls_upd_user IN lt_user
                    ( %tky   = ls_upd_user-%tky
                      %param = ls_upd_user ) ).

    IF ls_failed_update IS INITIAL.
      reported = VALUE #( BASE reported user = VALUE #( ( %tky = keys[ 1 ]-%tky
                                                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                                                       text = 'Template Available' ) ) ) ).

    ENDIF.
  ENDMETHOD.

  METHOD UploadExcelData.


    DATA lo_table_descr  TYPE REF TO cl_abap_tabledescr.
    DATA lo_struct_descr TYPE REF TO cl_abap_structdescr.
    DATA lt_excel        TYPE STANDARD TABLE OF zbp_i_userdata=>gty_exl_file.
    DATA lt_excel_temp   TYPE STANDARD TABLE OF zbp_i_userdata=>gty_exl_file.
    DATA lt_excel_filter TYPE SORTED TABLE OF zbp_i_userdata=>gty_exl_file WITH UNIQUE KEY emp_id dep_id.
    DATA lt_data         TYPE TABLE FOR CREATE z_i_userdata\_userdept.
    DATA lv_index        TYPE sy-index.

    FIELD-SYMBOLS <lfs_col_header> TYPE string.

    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(ls_user) = cl_abap_context_info=>get_user_technical_name( ).

    READ ENTITIES OF z_i_userdata
         IN LOCAL MODE
         ENTITY user
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_file_entity).

    DATA(lv_attachment) = lt_file_entity[ 1 ]-attachment.

    IF lv_attachment IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lo_xlsx) = xco_cp_xlsx=>document->for_file_content( iv_file_content = lv_attachment )->read_access( ).
    DATA(lo_worksheet) = lo_xlsx->get_workbook( )->worksheet->at_position( 1 ).
    DATA(lo_selection_pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to( )->get_pattern( ).
    DATA(lo_execute) = lo_worksheet->select( lo_selection_pattern )->row_stream( )->operation->write_to(
                                                                      REF #( lt_excel_temp ) ).

    lo_execute->set_value_transformation( xco_cp_xlsx_read_access=>value_transformation->string_value )->if_xco_xlsx_ra_operation~execute( ).

    TRY.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( p_data = lt_excel_temp ).
        lo_struct_descr ?= lo_table_descr->get_table_line_type( ).
        DATA(lo_no_of_cols) = lines( lo_struct_descr->components ).
      CATCH cx_sy_move_cast_error.
        " Need to implement Error Handing...
    ENDTRY.

    DATA(ls_excel) = VALUE #( lt_excel_temp[ 1 ] OPTIONAL ).
    IF ls_excel IS NOT INITIAL.
      DO lo_no_of_cols TIMES.
        lv_index = sy-index.
        ASSIGN COMPONENT lv_index OF STRUCTURE ls_excel TO <lfs_col_header>.
        IF <lfs_col_header> IS NOT ASSIGNED OR <lfs_col_header> IS INITIAL.
          CONTINUE.
        ENDIF.
        DATA(lv_value) = to_upper( <lfs_col_header> ).
        DATA(lv_has_error) = abap_false.
        CASE lv_index.
          WHEN 1.
            lv_has_error = COND #( WHEN lv_value <> 'EMPLOYEE ID' THEN abap_true ELSE lv_has_error ).
          WHEN 2.
            lv_has_error = COND #( WHEN lv_value <> 'DEPARTMENT ID' THEN abap_true ELSE lv_has_error ).
          WHEN 3.
            lv_has_error = COND #( WHEN lv_value <> 'DEPARTMENT DESCRIPTION' THEN abap_true ELSE lv_has_error ).
          WHEN 4.
            lv_has_error = COND #( WHEN lv_value <> 'OBJECT TYPE' THEN abap_true ELSE lv_has_error ).
          WHEN 5.
            lv_has_error = COND #( WHEN lv_value <> 'OBJECT NAME' THEN abap_true ELSE lv_has_error ).
          WHEN 6.
            lv_has_error = COND #( WHEN lv_value <> 'SALARY' THEN abap_true ELSE lv_has_error ).
          WHEN 7.
            lv_has_error = COND #( WHEN lv_value <> 'JOINING DATE' THEN abap_true ELSE lv_has_error ).
          WHEN OTHERS.
            lv_has_error = abap_true.
        ENDCASE.

        IF lv_has_error = abap_true.
          APPEND VALUE #( %tky = lt_file_entity[ 1 ]-%tky ) TO failed-user.
          APPEND VALUE #( %tky = lt_file_entity[ 1 ]-%tky
                          %msg = new_message_with_text(
                                     severity = if_abap_behv_message=>severity-error
                                     text     = 'One or More Heading is incorrect, Please Check !!!' ) )
                 TO reported-user.
          UNASSIGN <lfs_col_header>.
          EXIT.
        ENDIF.
        UNASSIGN <lfs_col_header>.
      ENDDO.
    ENDIF.
    IF lv_has_error = abap_true.
      RETURN.
    ENDIF.

    DELETE lt_excel_temp INDEX 1.
    DELETE lt_excel_temp WHERE emp_id IS INITIAL AND dep_id IS INITIAL.


    DATA: lv_empid TYPE string.

    lv_empid = replace(
      val   = keys[ 1 ]-EmpId
      regex = '^0+'
      with  = '' ).

    lt_excel_filter = VALUE #( ( emp_id = lv_empid dep_id = keys[ 1 ]-DepId ) ).

    lt_excel = FILTER #( lt_excel_temp IN lt_excel_filter WHERE emp_id = emp_id AND dep_id = dep_id ).

    IF lt_excel IS INITIAL.

      reported = VALUE #( BASE reported
                          user = VALUE #( ( %tky = keys[ 1 ]-%tky
                                            %msg = new_message_with_text(
                                                       severity = if_abap_behv_message=>severity-error
                                                       text     = 'Trying to Insert Invalid/Blank Values' )     ) ) ).

    ELSE.

      " Serial Number
      LOOP AT lt_excel ASSIGNING FIELD-SYMBOL(<lfs_excel>).
        <lfs_excel>-serial_no = sy-tabix.
      ENDLOOP.

      ""Prepare Data for Child Entity(UserDep)

      lt_data = VALUE #( ( %cid_ref = keys[ 1 ]-%cid_ref
                           EmpId    = keys[ 1 ]-EmpId
                           DepId    = keys[ 1 ]-DepId
                           %target  = VALUE #( FOR lwa_excel IN lt_excel
                                               ( %cid     = keys[ 1 ]-%cid_ref
                                                 %data    = VALUE #( EmpId      = keys[ 1 ]-EmpId
                                                                     DepId      = keys[ 1 ]-DepId
                                                                     SerialNo   = lwa_excel-serial_no
                                                                     ObjectType = lwa_excel-obj_type
                                                                     ObjectName = lwa_excel-obj_name    )

                                                 %control = VALUE #( EmpId      = if_abap_behv=>mk-on
                                                                     DepId      = if_abap_behv=>mk-on
                                                                     SerialNo   = if_abap_behv=>mk-on
                                                                     ObjectType = if_abap_behv=>mk-on
                                                                     ObjectName = if_abap_behv=>mk-on ) ) ) ) ).

      READ ENTITIES OF z_i_userdata
           IN LOCAL MODE
           ENTITY user BY \_userdept
           ALL FIELDS WITH CORRESPONDING #( keys )
           RESULT DATA(lt_existing_UserDev).

      IF lt_existing_UserDev IS NOT INITIAL.
        MODIFY ENTITIES OF z_i_userdata
               IN LOCAL MODE
               ENTITY userdept DELETE FROM VALUE #( FOR lwa_data IN lt_existing_UserDev
                                                    ( %key = lwa_data-%key ) )

               " TODO: variable is assigned but never used (ABAP cleaner)
               MAPPED DATA(lt_del_mapped)
               " TODO: variable is assigned but never used (ABAP cleaner)
               REPORTED DATA(lt_del_reported)
               " TODO: variable is assigned but never used (ABAP cleaner)
               FAILED DATA(lt_del_failed).
      ENDIF.

      ""adding new entry for XLData (association)
      MODIFY ENTITIES OF z_i_userdata
             IN LOCAL MODE
             ENTITY user CREATE BY \_userdept
             AUTO FILL CID WITH lt_data.

      MODIFY ENTITIES OF z_i_userdata
             IN LOCAL MODE
             ENTITY user
             UPDATE FROM VALUE #( ( %tky                = lt_file_entity[ 1 ]-%tky
                                    FileStatus          = 'Excel Uploaded'
                                    %control-FileStatus = if_abap_behv=>mk-on ) )
             " TODO: variable is assigned but never used (ABAP cleaner)
             MAPPED DATA(lt_upd_mapped)
             FAILED DATA(lt_upd_failed)
             " TODO: variable is assigned but never used (ABAP cleaner)
             REPORTED DATA(lt_upd_reported).

      READ ENTITIES OF z_i_userdata
           IN LOCAL MODE
           ENTITY user
           ALL FIELDS WITH CORRESPONDING #( keys )
           RESULT DATA(lt_updated_User).

      result = VALUE #( FOR lwa_upd_head IN lt_updated_user
                        ( %tky   = lwa_upd_head-%tky
                          %param = lwa_upd_head ) ).

      IF lt_upd_failed IS INITIAL.
        reported = VALUE #(
            BASE reported
            user = VALUE #( ( %tky = keys[ 1 ]-%tky
                              %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                            text     = 'Excel Upoloaded Successfully.' ) ) ) ).

      ENDIF.

    ENDIF.
  ENDMETHOD.

  METHOD FillFileStatus.

    READ ENTITIES OF z_i_userdata
    IN LOCAL MODE
    ENTITY user
    FIELDS ( Empid DepId FileStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_user).

    LOOP AT lt_user INTO DATA(ls_user).

      MODIFY ENTITIES OF z_i_userdata
      IN LOCAL MODE
      ENTITY user
      UPDATE FIELDS ( FileStatus TemplateStatus )
      WITH VALUE #( (
                      %tky = ls_user-%tky
                      %data-FileStatus = 'File Not Selected'
                      %data-TemplateStatus = 'Absent'
                      %control-FileStatus = if_abap_behv=>mk-on
                      %control-TemplateStatus = if_abap_behv=>mk-on ) ).


    ENDLOOP.

  ENDMETHOD.

  METHOD FillSelectedStatus.

    READ ENTITIES OF z_i_userdata
    IN LOCAL MODE
    ENTITY user
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_user).


    LOOP AT lt_user INTO DATA(ls_user).
      MODIFY ENTITIES OF z_i_userdata
      IN LOCAL MODE
      ENTITY user
      UPDATE FIELDS ( FileStatus TemplateStatus )
      WITH VALUE #( (
                      %tky    = ls_user-%tky
                      %data-FileStatus = COND #(
                      WHEN ls_user-Attachment IS INITIAL
                      THEN 'File Not Selected'
                      ELSE 'File Selected' )
                      %control-FileStatus = if_abap_behv=>mk-on ) ).

    ENDLOOP.

    READ ENTITIES OF z_i_userdata
    IN LOCAL MODE
    ENTITY user
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_User_updated).

    LOOP AT lt_User_updated INTO DATA(ls_User_updated).
      MODIFY ENTITIES OF Z_I_userdata
      IN LOCAL MODE
      ENTITY user
      UPDATE FIELDS ( TemplateStatus )
      WITH VALUE #( (
                      %tky    = ls_user-%tky
                      %data-TemplateStatus = COND #(
                      WHEN ls_user-Attachment IS NOT INITIAL
                      THEN COND #( WHEN ls_User-FileStatus = 'File Selected' THEN ' ' )
                      ELSE 'Absent' )
                      %control-TemplateStatus = if_abap_behv=>mk-on
                       ) ).



    ENDLOOP.

  ENDMETHOD.

*  METHOD get_instance_features.


*    READ ENTITIES OF z_i_userdata IN LOCAL MODE
*    ENTITY user
*    FIELDS ( EmpId DepId FileStatus TemplateStatus )
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_users)
*    FAILED failed.
*
*    result = VALUE #( FOR user IN lt_users
*                     LET uploadbtn   =  COND #( WHEN user-FileStatus = 'File Selected'
*                                                THEN if_abap_behv=>fc-o-enabled
*                                                ELSE if_abap_behv=>fc-o-disabled )
*                    DownloadTemplate = COND #( WHEN  user-FileStatus = 'Absent'
*                                                THEN if_abap_behv=>fc-o-enabled
*                                                ELSE if_abap_behv=>fc-o-disabled )
*                                        IN (
*                                             %tky      = user-%tky
*                                             %assoc-_userdept = if_abap_behv=>fc-o-disabled
*                                             %action-UploadExcelData = uploadbtn
*                                             %action-DownloadExcel = downloadtemplate
*                                         ) ).
*
*
*  ENDMETHOD.



  METHOD get_instance_features.

    READ ENTITIES OF z_i_userdata IN LOCAL MODE
      ENTITY user
      FIELDS ( EmpId DepId FileStatus TemplateStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_users)
      FAILED failed.

    result = VALUE #(
      FOR user IN lt_users

      LET uploadbtn = COND #(
                          WHEN user-FileStatus = 'File Selected'
                          THEN if_abap_behv=>fc-o-enabled
                          ELSE if_abap_behv=>fc-o-disabled )

          downloadbtn = COND #(
                          WHEN user-TemplateStatus = 'Absent'
                          THEN if_abap_behv=>fc-o-enabled
                          ELSE if_abap_behv=>fc-o-disabled )

      IN
        (
          %tky                     = user-%tky
          %assoc-_userdept          = if_abap_behv=>fc-o-disabled
          %action-UploadExcelData   = uploadbtn
          %action-DownloadExcel     = downloadbtn
        )
    ).

  ENDMETHOD.


  METHOD get_global_authorizations.
  ENDMETHOD.

ENDCLASS.
