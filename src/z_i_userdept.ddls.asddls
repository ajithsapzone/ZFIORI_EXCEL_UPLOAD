@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view for User Department'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z_I_USERDEPT as select from zuserdep_db
association to parent Z_I_USERDATA as _user on $projection.EmpId = _user.EmpId and $projection.DepId = _user.DepId 
{
    key emp_id as EmpId,
    key dep_id as DepId,
    key serial_no as SerialNo,
    object_type as ObjectType,
    object_name as ObjectName,
   _user   
}
