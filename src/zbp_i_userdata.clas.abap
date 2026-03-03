CLASS zbp_i_userdata DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF z_i_userdata.
  TYPES: BEGIN OF gty_exl_file,
           emp_id      TYPE  string,
           dep_id      TYPE  string,
           dep_desc    TYPE  string,
           obj_type    TYPE  string,
           obj_name    TYPE  string,
           salary      TYPE  string,
           Joiningdate TYPE  string,
           serial_no   TYPE  string,
         END OF gty_exl_file.
protected section.
private section.
ENDCLASS.



CLASS ZBP_I_USERDATA IMPLEMENTATION.
ENDCLASS.
