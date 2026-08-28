#Include "totvs.ch"
#Include "fwmvcdef.ch"

/*/{Protheus.doc} CADCC
Cadastro de Centros de Custos.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
User Function CADCC()

Local oBrowse
Private cAliasMas := "SZ5"
Private cAliasDet := "SZB"

oBrowse := FWMBrowse():New()
oBrowse:SetAlias(cAliasMas)
oBrowse:SetDescription("Cadastro de Centros de Custos")

oBrowse:SetFilterDefault(U_MBLocxUsr(1, cAliasMas))

oBrowse:Activate()

Return

/*/{Protheus.doc} MENUDEF
Menu de opções do Cadastro

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function MenuDef()

Local aRotina := FWMVCMenu("CADCC")

Return(aRotina)

/*/{Protheus.doc} MODELDEF
Modelo de Dados do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ModelDef()

Local oModel
Local oStruSZ5 := FWFormStruct(1, "SZ5")
Local oStruSZB := FWFormStruct(1, "SZB")

oModel := MPFormModel():New("CADCCM", /*bPreValidacao*/, /*bPosValidacao*/, { |oMdl| AtuaDescri( oMdl ) }, /*bCancel*/ )

oModel:AddFields("SZ5MASTER",, oStruSZ5)

oModel:AddGrid("SZBDETAIL", "SZ5MASTER", oStruSZB)

oModel:SetRelation("SZBDETAIL", {{"ZB_FILIAL", "xFilial('SZB')"}, {"ZB_CODPOST", "Z5_CODPOST"}, {"ZB_LOCALID", "Z5_LOCALID"},;
                                 {"ZB_CC", "Z5_CC"}}, SZB->(IndexKey(1)))

oModel:SetPrimaryKey({"Z5_FILIAL","Z5_CODPOST","Z5_CC"})

oModel:SetDescription("Centros de Custos")
oModel:GetModel("SZ5MASTER"):SetDescription("Dados do C.C.")
oModel:GetModel("SZBDETAIL"):SetDescription("Dados das Gerências do C.C.")

Return(oModel)

/*/{Protheus.doc} VIEWDEF
View do MVC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function ViewDef()

Local oView
Local oStruSZ5   := FWFormStruct(2, "SZ5") 
Local oStruSZB   := FWFormStruct(2, "SZB", {|campo| !AllTrim(campo)+"|" $ "ZB_CODPOST|ZB_LOCALID|ZB_CC|"})
Local oModel     := FWLoadModel("CADCC")

oView := FWFormView():New()

oView:SetModel(oModel)

oView:AddField("VIEW_SZ5", oStruSZ5, "SZ5MASTER")
oView:AddGrid("VIEW_SZB", oStruSZB, "SZBDETAIL")

oView:SetCloseOnOk({|| .T.})

oView:CreateHorizontalBox("CABEC", 30)
oView:CreateHorizontalBox("GRID", 70)

oView:SetOwnerView("VIEW_SZ5", "CABEC")
oView:SetOwnerView("VIEW_SZB", "GRID")

Return(oview)

/*/{Protheus.doc} VIEWDEF
Atualiza o campo da descriçao do CC.

@author Ewerton Alex Vicentin
@since 20/10/2025
@version P12
/*/
Static Function AtuaDescri(oModel)

Local nI         := 0
Local cDescri    := ""
Local nOperation := oModel:GetOperation()
Local oModelSZB  := oModel:GetModel("SZBDETAIL")
Local lRetorno   := .T.

If nOperation == MODEL_OPERATION_INSERT .or. nOperation == MODEL_OPERATION_UPDATE
	For nI := 1 To oModelSZB:Length()
		oModelSZB:GoLine(nI)
		
		If !oModelSZB:IsDeleted()
			cDescri += AllTrim(oModelSZB:GetValue("ZB_DESCRI", nI, oModel)) + ","
		EndIf
	Next nI

	oModel:SetValue("SZ5MASTER", "Z5_DESCRI", SubStr(cDescri, 1, Len(cDescri)-1))
EndIf

Begin Sequence
    If !(lRetorno := FWFormCommit(oModel))
        cLogMdl := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
        cLogMdl += cValToChar(oModel:GetErrorMessage()[6])
        Help( ,,"U_CADCC",,cLogMdl, 1, 0 )
        Break
    EndIf
End Sequence

Return(lRetorno)
