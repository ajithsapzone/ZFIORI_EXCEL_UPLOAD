@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection view of Z_I_USERDEPT'
@Metadata.ignorePropagatedAnnotations: true
define view entity z_c_userdept
  as projection on Z_I_USERDEPT
{

      @UI: {lineItem:[{ position: 10, importance: #HIGH, label: 'Employee Id' }]}
  key EmpId,
      @UI: {lineItem:[{ position: 20, importance: #HIGH, label: 'Department Id' }]}
  key DepId,
      @UI: {lineItem:[{ position: 30, importance: #HIGH, label: 'Serial No' }]}
  key SerialNo,
      @UI: {lineItem:[{ position: 40, importance: #HIGH, label: 'Object Type' }]}
      ObjectType,
      @UI: {lineItem:[{ position: 50, importance: #HIGH, label: 'Object Name' }]}
      ObjectName,
      @UI: {lineItem:[{ position: 60, importance: #HIGH, label: 'Salary' }]}
      Salary,
      @UI: {lineItem:[{ position: 70, importance: #HIGH, label: 'Joining Date' }]}
      JoiningDate,
      /* Associations */
      _user : redirected to parent Z_C_USERDATA

}
