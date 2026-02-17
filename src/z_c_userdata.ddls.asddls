@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection view of Z_I_USERDATA'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity Z_C_USERDATA
  provider contract transactional_query as projection on Z_I_USERDATA
{
    key EmpId,
    key DepId,
    DepDescription,
    @Semantics.largeObject: {
    mimeType: 'Mimetype',
    fileName: 'Filename',
    acceptableMimeTypes: [ 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ],
    contentDispositionPreference: #ATTACHMENT 
    }
    Attachment,
    @Semantics.mimeType: true
    Mimetype,
    Filename,
    FileStatus,
    TemplateStatus,
    Criticality,
    TemplateCrticality,
    Createdby,
    Createdat,
    Lastchangedby,
    Lastchangesat,
    /* Associations */
    _userdept: redirected to composition child z_c_userdept
}
