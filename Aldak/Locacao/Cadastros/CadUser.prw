#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} CADUSER
Cadastro de Usuários x Localidades.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function CADUSER()

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("SZ3")
oBrowse:SetDescription("Cadastro de Usuários x Localidades")

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opções do Cadastro

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MenuDef()

Local aRotina := FWMVCMenu("CADUSER")

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruSZ3 := FWFormStruct(1, "SZ3")
Local oStruSZ4 := FWFormStruct(1, "SZ4")

oModel := MPFormModel():New("CADUSERM")

oModel:AddFields("SZ3MASTER",, oStruSZ3)

oModel:AddGrid("SZ4DETAIL", "SZ3MASTER", oStruSZ4)

oModel:SetRelation("SZ4DETAIL", {{"Z4_FILIAL", "xFilial('SZ4')"}, {"Z4_CODPOST", "Z3_CODPOST"},{"Z4_USER", "Z3_USER"}}, SZ4->(IndexKey(1)))

oModel:SetPrimaryKey({"Z3_FILIAL","Z3_CODPOST","Z3_USER"})

oModel:SetDescription("Usuários x Localidades")
oModel:GetModel("SZ3MASTER"):SetDescription("Dados do Usuário")
oModel:GetModel("SZ4DETAIL"):SetDescription("Dados das Localidades do Usuário")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZ3   := FWFormStruct(2, "SZ3")
Local oStruSZ4   := FWFormStruct(2, "SZ4", {|x| !AllTrim(x) $ "Z4_CODPOST,Z4_USER"})
Local oModel     := FWLoadModel("CADUSER")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZ3", oStruSZ3, "SZ3MASTER")
oView:AddGrid("VIEW_SZ4", oStruSZ4, "SZ4DETAIL")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("GRID", 70)

oView:SetOwnerView("VIEW_SZ3", "CABEC")
oView:SetOwnerView("VIEW_SZ4", "GRID")

Return(oview)
