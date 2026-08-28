#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} CADLOCA
Cadastro de Localidades.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function CADLOCA()

Local oBrowse

oBrowse := FWMBrowse():New()
oBrowse:SetAlias("SZ2")
oBrowse:SetDescription("Localidades")

oBrowse:SetFilterDefault(U_MBLocxUsr(1, "SZ2"))

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opções do Cadastro

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MenuDef()

Local aRotina := FWMVCMenu("CADLOCA")

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruSZ2 := FWFormStruct(1, "SZ2")
Local oStruSZG := FWFormStruct(1, "SZG")

oModel := MPFormModel():New("CADLOCAM", /*bPreValidacao*/, {|oModel| TudoOk(oModel)}, /*bConfirm*/, /*bCancel*/ )

oModel:AddFields("SZ2MASTER",, oStruSZ2)

oModel:AddGrid("SZGDETAIL", "SZ2MASTER", oStruSZG)

oModel:SetRelation("SZGDETAIL", {{"ZG_FILIAL", "xFilial('SZG')"}, {"ZG_LOCALID", "Z2_LOCALID"}}, SZG->(IndexKey(1)))

oModel:SetPrimaryKey({"Z2_FILIAL","Z2_LOCALID"})

oModel:SetDescription("Localidades")
oModel:GetModel("SZ2MASTER"):SetDescription("Dados da Localidade")
oModel:GetModel("SZGDETAIL"):SetDescription("Dados dos Clientes")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZ2   := FWFormStruct(2, "SZ2")
Local oStruSZG   := FWFormStruct(2, "SZG", {|x| !AllTrim(x) $ "ZG_LOCALID"})
Local oModel     := FWLoadModel("CADLOCA")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZ2", oStruSZ2, "SZ2MASTER")
oView:AddGrid("VIEW_SZG", oStruSZG, "SZGDETAIL")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("GRID", 70)

oView:SetOwnerView("VIEW_SZ2", "CABEC")
oView:SetOwnerView("VIEW_SZG", "GRID")

Return(oview)

/*/{Protheus.doc} TudoOk
Validação antes de salvar o formulário.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function TudoOk(oModel)

Local nOperation := oModel:GetOperation()
Local oModelSZ2  := oModel:GetModel("SZ2MASTER")
Local cCodPost   := oModelSZ2:GetValue("Z2_CODPOST")
Local cLocalid   := oModelSZ2:GetValue("Z2_LOCALID")
Local lRet       := .T.

If nOperation == MODEL_OPERATION_INSERT
	If Empty(cCodPost)
		Help( ,,"CADLOCA1",,"Digite o código do posto.", 1, 0)
		lRet := .F.
	EndIf

	If Empty(cLocalid)
		Help( ,,"CADLOCA2",,"Digite a localidade.", 1, 0)
		lRet := .F.
	EndIf
EndIf

Return(lRet)
