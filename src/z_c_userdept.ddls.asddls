@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection view of Z_I_USERDEPT'
@Metadata.ignorePropagatedAnnotations: true
define view entity z_c_userdept as projection on Z_I_USERDEPT
{
    key EmpId,
    key DepId,
    key SerialNo,
    ObjectType,
    ObjectName,
    /* Associations */
    _user: redirected to parent Z_C_USERDATA
    
}
