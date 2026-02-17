@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view for User Info'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z_I_USERDATA as select from zuserdata_db
composition [0..*] of Z_I_USERDEPT as _userdept
{
    key emp_id as EmpId,
    key dep_id as DepId,
    dep_description as DepDescription,
    attachment as Attachment,
    mimetype as Mimetype,
    filename as Filename,
    file_status as FileStatus,
    template_staus as TemplateStatus,   
    case file_status
    when 'File Selected' then 2
    when 'Excel Uploaded' then 3
    when 'File Not Selected' then 1
    else 0
    end         as  Criticality,
    case template_staus
    when 'Present' then 3
    when 'Absent' then 1
    else 0
    end         as TemplateCrticality,
    @Semantics.user.createdBy: true
    createdby as Createdby,
    @Semantics.systemDateTime.createdAt: true
    createdat as Createdat,
    @Semantics.user.lastChangedBy: true
    lastchangedby as Lastchangedby,
    @Semantics.systemDateTime.lastChangedAt: true
    lastchangesat as Lastchangesat,
    _userdept
}
